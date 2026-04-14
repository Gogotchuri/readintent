package articles

import (
	"context"
	"fmt"

	models "github.com/gogotchuri/readintent/backend/services/articles/models"
)

type Service struct {
	articleRepo Repository
	eventHub    EventHub
}

func (s Service) ParseArticle(ctx context.Context, userID, url string) error {
	// Check if the article already exists for the user
	_, err := s.articleRepo.GetArticleForUser(ctx, userID, url)
	if err == nil {
		return fmt.Errorf("article already exists for user %s and url %s", userID, url)
	}
	// TODO distinguish the not found error her
	// We can proceeed, and check if the article is in the database, which can be directly reused without parsing it additonal time
	article, err := s.articleRepo.GetArticleWithURL(ctx, url)
	if err == nil {
		// Article exists, we can just create the user-article relation and return
		_, err := s.articleRepo.CreateFullArticle(ctx, userID, *article)
		return err
	}
	// Otherwise we will create an initial article and submit it for parsing down the line
	if _, err = s.articleRepo.CreateInitialArticle(ctx, userID, url); err != nil {
		return fmt.Errorf("creating initial article: %w", err)
	}
	if err := s.eventHub.SubmitArticle(ctx, url); err != nil {
		return err
	}
	return nil
}

func (s Service) GetArticles(ctx context.Context, userID string, searchQ models.GetArticlesRequest) (*models.GetArticlesResponse, error) {
	return s.articleRepo.GetArticles(ctx, userID, searchQ)
}

func (s Service) GetArticle(ctx context.Context, userID, id string) (*models.Article, error) {
	return s.articleRepo.GetArticleForUser(ctx, userID, id)
}

func (s Service) DeleteArticle(ctx context.Context, userID, id string) error {
	return s.articleRepo.DeleteArticle(ctx, userID, id)
}
