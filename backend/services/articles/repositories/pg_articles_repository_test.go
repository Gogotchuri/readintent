package repositories

import (
	"context"
	"testing"
	"time"

	"github.com/gogotchuri/readintent/backend/database"
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
