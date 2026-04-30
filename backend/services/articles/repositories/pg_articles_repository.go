package repositories

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/gogotchuri/readintent/backend/database/models"
	"github.com/gogotchuri/readintent/backend/services/articles"
	iomodels "github.com/gogotchuri/readintent/backend/services/articles/models"
	"github.com/jmoiron/sqlx"
)

var _ articles.Repository = &PgArticlesRepository{}

type PgArticlesRepository struct {
	db *sqlx.DB
}

func NewPgArticlesRepository(db *sqlx.DB) *PgArticlesRepository {
	return &PgArticlesRepository{db: db}
}

func (p PgArticlesRepository) GetArticles(ctx context.Context, userID string, searchQ iomodels.GetArticlesRequest) (*iomodels.GetArticlesResponse, error) {
	afterUnixTime, fromID := iomodels.ParsePageToken(searchQ.PageToken)
	var totalCount int32
	var nextPageToken string
	var previews []models.ArticlePreview
	query := `
		SELECT a.id, a.url, a.status, a.title, a.author, a.published_date, a.categories, a.description, a.image_url, a.created_at
		FROM articles a
		JOIN user_articles ua ON ua.article_id = a.id
		WHERE ua.user_id = $1 AND ($2 = 0 OR a.created_at < to_timestamp($2) OR (a.created_at = to_timestamp($2) AND a.id < $3))
			AND COALESCE(a.author, '') LIKE '%' || $5 || '%'
			AND COALESCE(a.title, '') LIKE '%' || $6 || '%'
		ORDER BY a.created_at DESC, a.id DESC
		LIMIT $4
	`
	err := p.db.SelectContext(ctx, &previews, query, userID, afterUnixTime, fromID, searchQ.PageSize+1, searchQ.Author, searchQ.SearchQuery)
	if err != nil {
		return nil, fmt.Errorf("failed to get articles for user %s: %w", userID, err)
	}

	// We are only constructing the next page token when we have more articles remaining
	if len(previews) > int(searchQ.PageSize) {
		lastArticle := previews[len(previews)-1]
		nextPageToken = iomodels.EncodePageToken(lastArticle.CreatedAt.Unix(), lastArticle.Id)
		previews = previews[:len(previews)-1] // Remove the extra article used for pagination
	}

	// Counting articles satisfying the condition
	countQuery := `
		SELECT COUNT(*)
		FROM articles a
		JOIN user_articles ua ON ua.article_id = a.id
		WHERE ua.user_id = $1
			AND COALESCE(a.author, '') LIKE '%' || $2 || '%'
			AND COALESCE(a.title, '') LIKE '%' || $3 || '%'
	`
	err = p.db.GetContext(ctx, &totalCount, countQuery, userID, searchQ.Author, searchQ.SearchQuery)
	if err != nil {
		return nil, fmt.Errorf("failed to count articles for user %s: %w", userID, err)
	}

	return &iomodels.GetArticlesResponse{
		Articles:      previews,
		NextPageToken: nextPageToken,
		TotalCount:    totalCount,
	}, nil

}

func (p PgArticlesRepository) GetArticleForUser(ctx context.Context, userID string, id int64) (*models.Article, error) {
	var article models.Article
	if err := p.db.GetContext(ctx, &article, `
		SELECT a.id, a.url, a.status, a.title, a.author, a.published_date, a.extracted_html, a.pure_text,
			a.categories, a.description, a.image_url, a.phonemizer_data, a.created_at
		FROM articles a
		JOIN user_articles ua ON ua.article_id = a.id
		WHERE ua.user_id = $1 AND a.id = $2
	`, userID, id); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, articles.ErrArticleNotFound
		}
		return nil, err
	}
	return &article, nil
}

func (p PgArticlesRepository) GetArticleForUserWithURL(ctx context.Context, userID, url string) (*models.Article, error) {
	var article models.Article
	if err := p.db.GetContext(ctx, &article, `
		SELECT a.id, a.url, a.status, a.title, a.author, a.published_date, a.extracted_html, a.pure_text,
			a.categories, a.description, a.image_url, a.phonemizer_data, a.created_at
		FROM articles a
		JOIN user_articles ua ON ua.article_id = a.id
		WHERE ua.user_id = $1 AND a.url = $2
	`, userID, url); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, articles.ErrArticleNotFound
		}
		return nil, err
	}
	return &article, nil
}

func (p PgArticlesRepository) GetArticleWithURL(ctx context.Context, url string) (*models.Article, error) {
	var article models.Article
	if err := p.db.GetContext(ctx, &article, `
		SELECT id, url, status, title, author, published_date, extracted_html, pure_text,
			categories, description, image_url, phonemizer_data, created_at
		FROM articles
		WHERE url = $1
	`, url); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, articles.ErrArticleNotFound
		}
		return nil, err
	}
	return &article, nil
}

func (p PgArticlesRepository) CreateInitialArticle(ctx context.Context, userID, url string) (*models.Article, error) {
	_, err := p.GetArticleWithURL(ctx, url)
	if err == nil {
		return nil, fmt.Errorf("article with url %s already exists", url)
	}
	var articleID int64
	// Article doesn't exist, we need to create it first
	err = p.db.QueryRowxContext(ctx, `
		INSERT INTO articles (url, status) VALUES ($1, $2) RETURNING id
	`, url, models.ArticleStatusProcessing).Scan(&articleID)
	if err != nil {
		return nil, fmt.Errorf("failed to create article with url %s: %w", url, err)
	}
	// Then we need to create the user-article relation
	_, err = p.db.ExecContext(ctx, `
		INSERT INTO user_articles (user_id, article_id) VALUES ($1, $2)
	`, userID, articleID)
	if err != nil {
		return nil, fmt.Errorf("failed to create user-article relation for user %s and article %d: %w", userID, articleID, err)
	}
	return &models.Article{
		Id:  articleID,
		Url: url,
	}, nil
}

func (p PgArticlesRepository) AddArticleForUser(ctx context.Context, userID string, articleID int64) error {
	_, err := p.db.ExecContext(ctx, `
		INSERT INTO user_articles (user_id, article_id) VALUES ($1, $2)
	`, userID, articleID)
	if err != nil {
		return fmt.Errorf("failed to create user-article relation for user %s and article %d: %w", userID, articleID, err)
	}
	return nil
}

func (p PgArticlesRepository) UpdateArticle(ctx context.Context, article models.Article) error {
	_, err := p.db.NamedExecContext(ctx, `
		UPDATE articles SET status = :status, title = :title, author = :author, published_date = :published_date,
			extracted_html = :extracted_html, pure_text = :pure_text, url = :url, categories = :categories,
			description = :description, image_url = :image_url, phonemizer_data = :phonemizer_data, updated_at = NOW()
		WHERE id = :id
	`, &article)
	if err != nil {
		return fmt.Errorf("failed to update article with id %d: %w", article.Id, err)
	}
	return nil
}

func (p PgArticlesRepository) DeleteArticle(ctx context.Context, userID string, id int64) error {
	// We will just delete the user-article relation, and keep the article in the database, as it can be reused by other users
	_, err := p.db.ExecContext(ctx, `
		DELETE FROM user_articles WHERE user_id = $1 AND article_id = $2
	`, userID, id)
	if err != nil {
		return fmt.Errorf("failed to delete user-article relation for user %s and article %d: %w", userID, id, err)
	}
	return nil
}
