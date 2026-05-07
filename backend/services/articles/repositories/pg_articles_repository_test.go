package repositories

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/gogotchuri/readintent/backend/database"
	"github.com/gogotchuri/readintent/backend/database/models"
	"github.com/gogotchuri/readintent/backend/services/articles"
	iomodels "github.com/gogotchuri/readintent/backend/services/articles/models"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"
)

func startPostgres(t *testing.T) *sqlx.DB {
	t.Helper()
	ctx := t.Context()

	pgContainer, err := postgres.Run(ctx,
		"postgres:16-alpine",
		postgres.WithDatabase("articles_repo_test"),
		postgres.WithUsername("test"),
		postgres.WithPassword("test"),
		testcontainers.WithWaitStrategy(
			wait.ForLog("database system is ready to accept connections").
				WithOccurrence(2).
				WithStartupTimeout(30*time.Second),
		),
	)
	if err != nil {
		t.Fatalf("starting postgres container: %v", err)
	}
	t.Cleanup(func() {
		if err := pgContainer.Terminate(context.Background()); err != nil {
			t.Logf("terminating postgres container: %v", err)
		}
	})

	connStr, err := pgContainer.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		t.Fatalf("getting connection string: %v", err)
	}

	db, err := sqlx.Connect("postgres", connStr)
	if err != nil {
		t.Fatalf("connecting to postgres: %v", err)
	}
	t.Cleanup(func() { db.Close() })

	if err := database.MigrationUp(ctx, db); err != nil {
		t.Fatalf("running migrations: %v", err)
	}

	// Insert test user
	if _, err := db.Exec("INSERT INTO users (id) VALUES ('repo-test-user')"); err != nil {
		t.Fatalf("inserting test user: %v", err)
	}

	return db
}

func TestCreateAndGetArticle(t *testing.T) {
	db := startPostgres(t)
	repo := NewPgArticlesRepository(db)
	ctx := t.Context()

	const userID = "repo-test-user"
	const url = "https://example.com/repo-test"

	// CreateInitialArticle
	article, err := repo.CreateInitialArticle(ctx, userID, url)
	if err != nil {
		t.Fatalf("CreateInitialArticle failed: %v", err)
	}
	if article.Id == 0 {
		t.Fatal("expected non-zero article ID")
	}
	if article.Url != url {
		t.Errorf("expected URL %s, got %s", url, article.Url)
	}

	// GetArticleForUser
	fetched, err := repo.GetArticleForUser(ctx, userID, article.Id)
	if err != nil {
		t.Fatalf("GetArticleForUser failed: %v", err)
	}
	if fetched.Url != url {
		t.Errorf("expected URL %s, got %s", url, fetched.Url)
	}
	if fetched.Status != "processing" {
		t.Errorf("expected status 'processing', got %s", fetched.Status)
	}
}

func TestGetArticleByID(t *testing.T) {
	db := startPostgres(t)
	repo := NewPgArticlesRepository(db)
	ctx := t.Context()

	const userID = "repo-test-user"
	const url = "https://example.com/by-id-test"

	article, err := repo.CreateInitialArticle(ctx, userID, url)
	if err != nil {
		t.Fatalf("CreateInitialArticle failed: %v", err)
	}

	fetched, err := repo.GetArticleByID(ctx, article.Id)
	if err != nil {
		t.Fatalf("GetArticleByID failed: %v", err)
	}
	if fetched.Url != url {
		t.Errorf("expected URL %s, got %s", url, fetched.Url)
	}
	if fetched.Status != models.ArticleStatusProcessing {
		t.Errorf("expected status %s, got %s", models.ArticleStatusProcessing, fetched.Status)
	}

	_, err = repo.GetArticleByID(ctx, 99)
	if !errors.Is(err, articles.ErrArticleNotFound) {
		t.Errorf("expected ErrArticleNotFound, got %v", err)
	}
}

func TestGetArticleForUserWithURL(t *testing.T) {
	db := startPostgres(t)
	repo := NewPgArticlesRepository(db)
	ctx := t.Context()

	const userID = "repo-test-user"
	const url = "https://example.com/user-url-test"

	_, err := repo.CreateInitialArticle(ctx, userID, url)
	if err != nil {
		t.Fatalf("CreateInitialArticle failed: %v", err)
	}

	fetched, err := repo.GetArticleForUserWithURL(ctx, userID, url)
	if err != nil {
		t.Fatalf("GetArticleForUserWithURL failed: %v", err)
	}
	if fetched.Url != url {
		t.Errorf("expected URL %s, got %s", url, fetched.Url)
	}

	_, err = repo.GetArticleForUserWithURL(ctx, userID, "https://example.com/nonexistent")
	if !errors.Is(err, articles.ErrArticleNotFound) {
		t.Errorf("expected ErrArticleNotFound, got %v", err)
	}
}

func TestGetArticleWithURL(t *testing.T) {
	db := startPostgres(t)
	repo := NewPgArticlesRepository(db)
	ctx := t.Context()

	const userID = "repo-test-user"
	const url = "https://example.com/url-test"

	_, err := repo.CreateInitialArticle(ctx, userID, url)
	if err != nil {
		t.Fatalf("CreateInitialArticle failed: %v", err)
	}

	fetched, err := repo.GetArticleWithURL(ctx, url)
	if err != nil {
		t.Fatalf("GetArticleWithURL failed: %v", err)
	}
	if fetched.Url != url {
		t.Errorf("expected URL %s, got %s", url, fetched.Url)
	}

	_, err = repo.GetArticleWithURL(ctx, "https://example.com/nonexistent")
	if !errors.Is(err, articles.ErrArticleNotFound) {
		t.Errorf("expected ErrArticleNotFound, got %v", err)
	}
}

func TestAddArticleForUser(t *testing.T) {
	db := startPostgres(t)
	repo := NewPgArticlesRepository(db)
	ctx := t.Context()

	const user1 = "repo-test-user"
	const user2 = "repo-test-user-2"
	const url = "https://example.com/add-user-test"

	// The first user is already in the DB
	if _, err := db.Exec("INSERT INTO users (id) VALUES ($1)", user2); err != nil {
		t.Fatalf("inserting second test user: %v", err)
	}

	article, err := repo.CreateInitialArticle(ctx, user1, url)
	if err != nil {
		t.Fatalf("CreateInitialArticle failed: %v", err)
	}

	if err := repo.AddArticleForUser(ctx, user2, article.Id); err != nil {
		t.Fatalf("AddArticleForUser failed: %v", err)
	}

	fetched, err := repo.GetArticleForUser(ctx, user2, article.Id)
	if err != nil {
		t.Fatalf("GetArticleForUser for user2 failed: %v", err)
	}
	if fetched.Url != url {
		t.Errorf("expected URL %s, got %s", url, fetched.Url)
	}
}

func TestUpdateArticle(t *testing.T) {
	db := startPostgres(t)
	repo := NewPgArticlesRepository(db)
	ctx := t.Context()

	const userID = "repo-test-user"
	const url = "https://example.com/update-test"

	created, err := repo.CreateInitialArticle(ctx, userID, url)
	if err != nil {
		t.Fatalf("CreateInitialArticle failed: %v", err)
	}

	fetched, err := repo.GetArticleByID(ctx, created.Id)
	if err != nil {
		t.Fatalf("GetArticleByID failed: %v", err)
	}

	fetched.Title = models.NewNullString("Updated Title")
	fetched.Author = models.NewNullString("Updated Author")
	fetched.Status = models.ArticleStatusTextReady

	if err := repo.UpdateArticle(ctx, *fetched); err != nil {
		t.Fatalf("UpdateArticle failed: %v", err)
	}

	refetched, err := repo.GetArticleByID(ctx, created.Id)
	if err != nil {
		t.Fatalf("GetArticleByID after update failed: %v", err)
	}
	if refetched.Title.String() != "Updated Title" {
		t.Errorf("expected title 'Updated Title', got %s", refetched.Title.String())
	}
	if refetched.Author.String() != "Updated Author" {
		t.Errorf("expected author 'Updated Author', got %s", refetched.Author.String())
	}
	if refetched.Status != models.ArticleStatusTextReady {
		t.Errorf("expected status %s, got %s", models.ArticleStatusTextReady, refetched.Status)
	}
}

func TestDeleteArticle(t *testing.T) {
	db := startPostgres(t)
	repo := NewPgArticlesRepository(db)
	ctx := t.Context()

	const userID = "repo-test-user"
	const url = "https://example.com/delete-test"

	article, err := repo.CreateInitialArticle(ctx, userID, url)
	if err != nil {
		t.Fatalf("CreateInitialArticle failed: %v", err)
	}

	if err := repo.DeleteArticle(ctx, userID, article.Id); err != nil {
		t.Fatalf("DeleteArticle failed: %v", err)
	}

	_, err = repo.GetArticleForUser(ctx, userID, article.Id)
	if !errors.Is(err, articles.ErrArticleNotFound) {
		t.Errorf("expected ErrArticleNotFound after delete, got %v", err)
	}

	// Article itself should still exist (only the user-article link is removed)
	fetched, err := repo.GetArticleByID(ctx, article.Id)
	if err != nil {
		t.Fatalf("GetArticleByID after delete should still find the article: %v", err)
	}
	if fetched.Url != url {
		t.Errorf("expected URL %s, got %s", url, fetched.Url)
	}
}

func TestGetArticles(t *testing.T) {
	db := startPostgres(t)
	repo := NewPgArticlesRepository(db)
	ctx := t.Context()

	const userID = "repo-test-user"

	urls := []string{
		"https://example.com/list-1",
		"https://example.com/list-2",
		"https://example.com/list-3",
	}
	titles := []string{"Alpha Article", "Beta Article", "Gamma Article"}
	authors := []string{"Alice", "Bob", "Alice"}

	for i, u := range urls {
		created, err := repo.CreateInitialArticle(ctx, userID, u)
		if err != nil {
			t.Fatalf("CreateInitialArticle[%d] failed: %v", i, err)
		}
		a, err := repo.GetArticleByID(ctx, created.Id)
		if err != nil {
			t.Fatalf("GetArticleByID[%d] failed: %v", i, err)
		}
		a.Title = models.NewNullString(titles[i])
		a.Author = models.NewNullString(authors[i])
		if err := repo.UpdateArticle(ctx, *a); err != nil {
			t.Fatalf("UpdateArticle[%d] failed: %v", i, err)
		}
	}

	// Default request — all 3 articles
	resp, err := repo.GetArticles(ctx, userID, iomodels.GetArticlesRequest{PageSize: 10})
	if err != nil {
		t.Fatalf("GetArticles failed: %v", err)
	}
	if len(resp.Articles) != 3 {
		t.Errorf("expected 3 articles, got %d", len(resp.Articles))
	}
	if resp.TotalCount != 3 {
		t.Errorf("expected TotalCount 3, got %d", resp.TotalCount)
	}

	// Search filter
	resp, err = repo.GetArticles(ctx, userID, iomodels.GetArticlesRequest{PageSize: 10, SearchQuery: "Beta"})
	if err != nil {
		t.Fatalf("GetArticles with search failed: %v", err)
	}
	if len(resp.Articles) != 1 {
		t.Errorf("expected 1 article for search 'Beta', got %d", len(resp.Articles))
	}

	// Author filter
	resp, err = repo.GetArticles(ctx, userID, iomodels.GetArticlesRequest{PageSize: 10, Author: "Alice"})
	if err != nil {
		t.Fatalf("GetArticles with author filter failed: %v", err)
	}
	if len(resp.Articles) != 2 {
		t.Errorf("expected 2 articles for author 'Alice', got %d", len(resp.Articles))
	}

	// Pagination: page 1
	resp, err = repo.GetArticles(ctx, userID, iomodels.GetArticlesRequest{PageSize: 2})
	if err != nil {
		t.Fatalf("GetArticles page 1 failed: %v", err)
	}
	if len(resp.Articles) != 2 {
		t.Errorf("expected 2 articles on page 1, got %d", len(resp.Articles))
	}
	if resp.NextPageToken == "" {
		t.Error("expected non-empty NextPageToken on page 1")
	}

	// Pagination: page 2
	resp, err = repo.GetArticles(ctx, userID, iomodels.GetArticlesRequest{PageSize: 2, PageToken: resp.NextPageToken})
	if err != nil {
		t.Fatalf("GetArticles page 2 failed: %v", err)
	}
	if len(resp.Articles) != 1 {
		t.Errorf("expected 1 article on page 2, got %d", len(resp.Articles))
	}
	if resp.NextPageToken != "" {
		t.Errorf("expected empty NextPageToken on last page, got %s", resp.NextPageToken)
	}
}

func TestGetArticlesPagination(t *testing.T) {
	db := startPostgres(t)
	repo := NewPgArticlesRepository(db)
	ctx := t.Context()

	const userID = "repo-test-user"

	// Create 5 articles with distinct titles/authors, all sharing the same created_at
	// so the ID tiebreaker is the only differentiator.
	fixedTime := time.Date(2025, 1, 1, 12, 0, 0, 0, time.UTC)
	articleValues := []struct {
		url, title, author string
	}{
		{"https://example.com/pag-0", "Art-A", "Alice"},
		{"https://example.com/pag-1", "Art-B", "Alice"},
		{"https://example.com/pag-2", "Art-C", "Alice"},
		{"https://example.com/pag-3", "Art-D", "Bob"},
		{"https://example.com/pag-4", "Art-E", "Bob"},
	}
	articleIDs := make([]int64, len(articleValues))
	for i, a := range articleValues {
		var id int64
		err := db.QueryRow(
			`INSERT INTO articles (url, status, title, author, created_at) VALUES ($1, $2, $3, $4, $5) RETURNING id`,
			a.url, "processing", a.title, a.author, fixedTime,
		).Scan(&id)
		if err != nil {
			t.Fatalf("inserting article[%d]: %v", i, err)
		}
		if _, err := db.Exec(`INSERT INTO user_articles (user_id, article_id) VALUES ($1, $2)`, userID, id); err != nil {
			t.Fatalf("inserting user_article[%d]: %v", i, err)
		}
		articleIDs[i] = id
	}

	// Helper: walk all pages collecting article IDs
	walkPages := func(t *testing.T, req iomodels.GetArticlesRequest) []int64 {
		t.Helper()
		var collected []int64
		for page := 0; ; page++ {
			resp, err := repo.GetArticles(ctx, userID, req)
			if err != nil {
				t.Fatalf("GetArticles page %d: %v", page, err)
			}
			for _, a := range resp.Articles {
				collected = append(collected, a.Id)
			}
			if resp.NextPageToken == "" {
				break
			}
			req.PageToken = resp.NextPageToken
		}
		return collected
	}

	t.Run("ExhaustiveWalk", func(t *testing.T) {
		ids := walkPages(t, iomodels.GetArticlesRequest{PageSize: 2})
		if len(ids) != 5 {
			t.Fatalf("expected 5 articles, got %d", len(ids))
		}
		// Check no duplicates and strictly descending order (ORDER BY id DESC when created_at is equal)
		seen := make(map[int64]bool)
		for i, id := range ids {
			if seen[id] {
				t.Errorf("duplicate article ID %d at position %d", id, i)
			}
			seen[id] = true
			if i > 0 && id >= ids[i-1] {
				t.Errorf("IDs not strictly descending: ids[%d]=%d >= ids[%d]=%d", i, id, i-1, ids[i-1])
			}
		}
	})

	t.Run("PageSize1", func(t *testing.T) {
		req := iomodels.GetArticlesRequest{PageSize: 1}
		var pages int
		var collected []int64
		for {
			resp, err := repo.GetArticles(ctx, userID, req)
			if err != nil {
				t.Fatalf("GetArticles page %d: %v", pages, err)
			}
			if len(resp.Articles) != 1 {
				t.Errorf("page %d: expected 1 article, got %d", pages, len(resp.Articles))
			}
			collected = append(collected, resp.Articles[0].Id)
			pages++
			if resp.NextPageToken == "" {
				break
			}
			req.PageToken = resp.NextPageToken
		}
		if pages != 5 {
			t.Errorf("expected 5 pages, got %d", pages)
		}
		if len(collected) != 5 {
			t.Errorf("expected 5 articles total, got %d", len(collected))
		}
	})

	t.Run("ExactFit", func(t *testing.T) {
		resp, err := repo.GetArticles(ctx, userID, iomodels.GetArticlesRequest{PageSize: 5})
		if err != nil {
			t.Fatalf("GetArticles: %v", err)
		}
		if len(resp.Articles) != 5 {
			t.Errorf("expected 5 articles, got %d", len(resp.Articles))
		}
		if resp.NextPageToken != "" {
			t.Errorf("expected empty NextPageToken, got %q", resp.NextPageToken)
		}
	})

	t.Run("LargerThanTotal", func(t *testing.T) {
		resp, err := repo.GetArticles(ctx, userID, iomodels.GetArticlesRequest{PageSize: 10})
		if err != nil {
			t.Fatalf("GetArticles: %v", err)
		}
		if len(resp.Articles) != 5 {
			t.Errorf("expected 5 articles, got %d", len(resp.Articles))
		}
		if resp.NextPageToken != "" {
			t.Errorf("expected empty NextPageToken, got %q", resp.NextPageToken)
		}
	})

	t.Run("PaginationWithFilter", func(t *testing.T) {
		// Alice has 3 articles (indices 0,1,2), Bob has 2 (indices 3,4)
		// Page 1: PageSize=2, Author="Alice"
		resp, err := repo.GetArticles(ctx, userID, iomodels.GetArticlesRequest{PageSize: 2, Author: "Alice"})
		if err != nil {
			t.Fatalf("GetArticles page 1: %v", err)
		}
		if len(resp.Articles) != 2 {
			t.Errorf("page 1: expected 2 articles, got %d", len(resp.Articles))
		}
		if resp.TotalCount != 3 {
			t.Errorf("page 1: expected TotalCount 3, got %d", resp.TotalCount)
		}
		if resp.NextPageToken == "" {
			t.Fatal("page 1: expected non-empty NextPageToken")
		}

		// Page 2
		resp, err = repo.GetArticles(ctx, userID, iomodels.GetArticlesRequest{PageSize: 2, Author: "Alice", PageToken: resp.NextPageToken})
		if err != nil {
			t.Fatalf("GetArticles page 2: %v", err)
		}
		if len(resp.Articles) != 1 {
			t.Errorf("page 2: expected 1 article, got %d", len(resp.Articles))
		}
		if resp.TotalCount != 3 {
			t.Errorf("page 2: expected TotalCount 3, got %d", resp.TotalCount)
		}
		if resp.NextPageToken != "" {
			t.Errorf("page 2: expected empty NextPageToken, got %q", resp.NextPageToken)
		}
	})
}

func TestCreateInitialArticle_DuplicateURL(t *testing.T) {
	db := startPostgres(t)
	repo := NewPgArticlesRepository(db)
	ctx := t.Context()

	const userID = "repo-test-user"
	const url = "https://example.com/duplicate-test"

	_, err := repo.CreateInitialArticle(ctx, userID, url)
	if err != nil {
		t.Fatalf("first CreateInitialArticle failed: %v", err)
	}

	_, err = repo.CreateInitialArticle(ctx, userID, url)
	if err == nil {
		t.Fatal("expected error for duplicate URL, got nil")
	}
}
