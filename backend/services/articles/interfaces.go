package articles

import (
	"context"

	"github.com/gogotchuri/readintent/backend/database/models"
	iomodels "github.com/gogotchuri/readintent/backend/services/articles/models"
)

type Repository interface {
	GetArticles(ctx context.Context, userID string, searchQ iomodels.GetArticlesRequest) (*iomodels.GetArticlesResponse, error)
	GetArticleForUser(ctx context.Context, userID string, id int64) (*models.Article, error)
	GetArticleForUserWithURL(ctx context.Context, userID, url string) (*models.Article, error)
	GetArticleWithURL(ctx context.Context, url string) (*models.Article, error)

	CreateInitialArticle(ctx context.Context, userID, url string) (*models.Article, error)
	AddArticleForUser(ctx context.Context, userID string, articleID int64) error
	UpdateArticle(ctx context.Context, article models.Article) error

	DeleteArticle(ctx context.Context, userID string, id int64) error
}

type EventHub interface {
	SubmitArticle(ctx context.Context, url string) error
}
