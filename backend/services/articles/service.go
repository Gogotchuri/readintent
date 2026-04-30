package articles

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

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
	if _, err = s.articleRepo.CreateInitialArticle(ctx, userID, url); err != nil {
		return fmt.Errorf("creating initial article: %w", err)
	}
	if err := s.eventHub.SubmitArticle(ctx, url, html); err != nil {
		return err
	}
	return nil
}

func (s Service) HandleScrapeResult(ctx context.Context, msg map[string]any) error {
	err, hasErr := msg["error"]
	if hasErr {
		type errorMsg struct {
			URL string `json:"url"`
			Msg string `json:"msg"`
		}
		var em errorMsg
		err := json.Unmarshal([]byte(err.(string)), &em)
		if err != nil {
			return fmt.Errorf("unmarshaling error message: %w", err)
		}
		// We should update the article and set the failed status
		article, err := s.articleRepo.GetArticleWithURL(ctx, em.URL)
		if err != nil {
			return fmt.Errorf("getting article with url %s: %w", em.URL, err)
		}
		article.Status = models.ArticleStatusFailed
		if err := s.articleRepo.UpdateArticle(ctx, *article); err != nil {
			return fmt.Errorf("updating article status to failed for url %s: %w", em.URL, err)
		}
		return nil
	}
	//TODO
	return nil
}

func (s Service) HandlePhonemizerResult(ctx context.Context, msg map[string]any) error {
	//TODO
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

func (s Service) UpdateArticle(ctx context.Context, article models.Article) error {
	return s.articleRepo.UpdateArticle(ctx, article)
}
