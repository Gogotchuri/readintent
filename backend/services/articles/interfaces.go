package articles

import (
	"context"
	"time"

	"github.com/gogotchuri/readintent/backend/database/models"
	iomodels "github.com/gogotchuri/readintent/backend/services/articles/models"
)

type Repository interface {
	GetArticles(ctx context.Context, userID string, searchQ iomodels.GetArticlesRequest) (*iomodels.GetArticlesResponse, error)
	GetArticleByID(ctx context.Context, id int64) (*models.Article, error)
	GetArticleForUser(ctx context.Context, userID string, id int64) (*models.Article, error)
	GetArticleForUserWithURL(ctx context.Context, userID, url string) (*models.Article, error)
	GetArticleWithURL(ctx context.Context, url string) (*models.Article, error)

	CreateInitialArticle(ctx context.Context, userID, url string) (*models.Article, error)
	AddArticleForUser(ctx context.Context, userID string, articleID int64) error
	UpdateArticle(ctx context.Context, article models.Article) error

	DeleteArticle(ctx context.Context, userID string, id int64) error

	HasUpdatedArticles(ctx context.Context, userID string, since time.Time) (bool, error)
}

type ArticleSubmitter interface {
	SubmitArticle(ctx context.Context, articleID int64, url, html string) error
}
