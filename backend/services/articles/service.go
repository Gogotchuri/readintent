package articles

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"strconv"
	"time"

	"github.com/gogotchuri/readintent/backend/database/models"
	iomodels "github.com/gogotchuri/readintent/backend/services/articles/models"
)

var ErrArticleNotFound = errors.New("article not found")

type Service struct {
	articleRepo Repository
	eventHub    ArticleSubmitter
}

func NewService(articleRepo Repository, eventHub ArticleSubmitter) *Service {
	return &Service{
		articleRepo: articleRepo,
		eventHub:    eventHub,
	}
}

func (s Service) ParseArticle(ctx context.Context, userID, url, html string) error {
	//TODO the URL must be processed and validated first at this stage

	// Check if the article already exists for the user
	_, err := s.articleRepo.GetArticleForUserWithURL(ctx, userID, url)
	if err == nil {
		return fmt.Errorf("article already exists for user %s and url %s", userID, url)
	}
	if !errors.Is(err, ErrArticleNotFound) {
		return fmt.Errorf("checking user article: %w", err)
	}
	// We can proceed, and check if the article is in the database, which can be directly reused without parsing it again
	article, err := s.articleRepo.GetArticleWithURL(ctx, url)
	if err == nil {
		// Article exists, we can just create the user-article relation and return
		return s.articleRepo.AddArticleForUser(ctx, userID, article.Id)
	}
	// Otherwise we will create an initial article and submit it for parsing down the line
	newArticle, err := s.articleRepo.CreateInitialArticle(ctx, userID, url)
	if err != nil {
		return fmt.Errorf("creating initial article: %w", err)
	}
	if err := s.eventHub.SubmitArticle(ctx, newArticle.Id, url, html); err != nil {
		return err
	}
	return nil
}

func (s Service) handleScrapeError(ctx context.Context, articleID int64, errMsg string) error {
	type errorMsg struct {
		Msg string `json:"msg"`
	}
	var em errorMsg
	if err := json.Unmarshal([]byte(errMsg), &em); err != nil {
		return fmt.Errorf("unmarshaling error message: %w", err)
	}
	article, err := s.articleRepo.GetArticleByID(ctx, articleID)
	if err != nil {
		return fmt.Errorf("getting article with id %d: %w", articleID, err)
	}
	article.Status = models.ArticleStatusFailed
	if err := s.articleRepo.UpdateArticle(ctx, *article); err != nil {
		return fmt.Errorf("updating article status to failed for id %d: %w", articleID, err)
	}
	return nil
}

func (s Service) HandleScrapeResult(ctx context.Context, msg map[string]any) error {
	articleID, err := parseArticleID(msg)
	if err != nil {
		return err
	}
	if errStr, hasErr := msg["error"]; hasErr {
		return s.handleScrapeError(ctx, articleID, errStr.(string))
	}
	resultStr, ok := msg["result"].(string)
	if !ok {
		return fmt.Errorf("missing result field for article %d", articleID)
	}
	article, err := s.articleRepo.GetArticleByID(ctx, articleID)
	if err != nil {
		return fmt.Errorf("getting article with id %d: %w", articleID, err)
	}
	art, err := models.ArticleFromScrape(resultStr)
	if err != nil {
		return fmt.Errorf("parsing article from scrape result for article %d: %w", articleID, err)
	}
	art.Id = article.Id
	// Just in case this has arrived first
	art.PhonemizerData = article.PhonemizerData
	if art.PhonemizerData.Valid {
		art.Status = models.ArticleStatusReady
	} else {
		art.Status = models.ArticleStatusTextReady
	}
	// Generate 300 len description if there is none
	art.GenerateDescriptionIfNone(300)

	slog.Info(fmt.Sprintf("Updating article %d with scrape result, status set to %s", articleID, art.Status))
	if err := s.articleRepo.UpdateArticle(ctx, art); err != nil {
		return fmt.Errorf("updating article with scrape result for id %d: %w", articleID, err)
	}
	return nil
}

func (s Service) HandlePhonemizerResult(ctx context.Context, msg map[string]any) error {
	articleID, err := parseArticleID(msg)
	if err != nil {
		return err
	}
	if errStr, hasErr := msg["error"]; hasErr {
		return s.handleScrapeError(ctx, articleID, errStr.(string))
	}
	resultStr, ok := msg["result"].(string)
	if !ok {
		return fmt.Errorf("missing result field for article %d", articleID)
	}
	var phonemizerData []models.PhonemizerData
	if err := json.Unmarshal([]byte(resultStr), &phonemizerData); err != nil {
		return fmt.Errorf("unmarshaling phonemizer data for article %d: %w", articleID, err)
	}
	article, err := s.articleRepo.GetArticleByID(ctx, articleID)
	if err != nil {
		return fmt.Errorf("getting article with id %d: %w", articleID, err)
	}
	article.PhonemizerData = models.NewJSONB(phonemizerData)
	article.Status = models.ArticleStatusPhonemesReady
	// Check if the article has already arrived, there is a chance it didn't
	// If we have successfully extracted html too we mark the article as ready
	if article.ExtractedHtml.Valid {
		article.Status = models.ArticleStatusReady
	}
	slog.Info(fmt.Sprintf("Updating article %d with phonemizer data, status set to %s", articleID, article.Status))
	if err := s.articleRepo.UpdateArticle(ctx, *article); err != nil {
		return fmt.Errorf("updating article with phonemizer data for id %d: %w", articleID, err)
	}
	return nil
}

func (s Service) GetArticles(ctx context.Context, userID string, searchQ iomodels.GetArticlesRequest) (*iomodels.GetArticlesResponse, error) {
	return s.articleRepo.GetArticles(ctx, userID, searchQ)
}

func (s Service) GetArticle(ctx context.Context, userID string, id int64) (*models.Article, error) {
	return s.articleRepo.GetArticleForUser(ctx, userID, id)
}

func (s Service) DeleteArticle(ctx context.Context, userID string, id int64) error {
	return s.articleRepo.DeleteArticle(ctx, userID, id)
}

func (s Service) CheckForUpdates(ctx context.Context, userID string, since time.Time) (bool, time.Time, error) {
	hasUpdates, err := s.articleRepo.HasUpdatedArticles(ctx, userID, since)
	if err != nil {
		return false, time.Time{}, err
	}
	return hasUpdates, time.Now(), nil
}

func parseArticleID(msg map[string]any) (int64, error) {
	idStr, ok := msg["article_id"].(string)
	if !ok || idStr == "" {
		return 0, fmt.Errorf("missing or empty article_id in message")
	}
	return strconv.ParseInt(idStr, 10, 64)
}
