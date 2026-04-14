package articles

import (
	"context"

	models "github.com/gogotchuri/readintent/backend/services/articles/models"
)

type Repository interface {
	GetArticles(ctx context.Context, userID string, searchQ models.GetArticlesRequest) (*models.GetArticlesResponse, error)
	GetArticleForUser(ctx context.Context, userID, id string) (*models.Article, error)
	GetArticleForUserWithURL(ctx context.Context, userID, url string) (*models.Article, error)
	GetArticleWithURL(ctx context.Context, id string) (*models.Article, error)

	CreateInitialArticle(ctx context.Context, userID, url string) (*models.Article, error)
	CreateFullArticle(ctx context.Context, userID string, article models.Article) (*models.Article, error)
	UpdateArticle(ctx context.Context, userID, id string, article models.Article) (*models.Article, error)

	DeleteArticle(ctx context.Context, userID, id string) error
}

type EventHub interface {
	SubmitArticle(ctx context.Context, url string) error
}
