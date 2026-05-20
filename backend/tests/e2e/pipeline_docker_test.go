package e2e

import (
	"context"
	"fmt"
	"strings"
	"testing"
	"time"

	"connectrpc.com/connect"
	"github.com/gogotchuri/readintent/backend/database"
	v1 "github.com/gogotchuri/readintent/backend/proto/articles/v1"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
	"github.com/redis/go-redis/v9"
	"github.com/testcontainers/testcontainers-go/modules/compose"
	"github.com/testcontainers/testcontainers-go/wait"
)

type testLogger struct {
	*testing.T
}

func (l testLogger) Printf(format string, args ...any) {
	l.T.Logf(format, args...)
}
func TestFullPipeline_Docker(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping Docker E2E test in short mode")
	}

	t.Chdir("testdata")
	stack, err := compose.NewDockerComposeWith(
		compose.WithStackFiles("./docker-compose.yml"),
		compose.StackIdentifier("e2e-pipeline-stack"),
		compose.WithLogger(testLogger{T: t}),
	)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(t.Context())
	t.Cleanup(cancel)

	postgresPort := "25432"
	redisPort := "26379"

	err = stack.
		WithEnv(map[string]string{
			"POSTGRES_PORT": postgresPort,
			"REDIS_PORT":    redisPort,
		}).
		WaitForService("postgres", wait.ForHealthCheck()).
		WaitForService("redis", wait.ForHealthCheck()).
		WaitForService("scraper", wait.ForLog("event consumer started").WithStartupTimeout(360*time.Second)).
		WaitForService("phonemizer", wait.ForLog("event consumer started").WithStartupTimeout(360*time.Second)).
		Up(ctx, compose.Wait(true))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		stack.Down(context.Background(),
			compose.RemoveOrphans(true),
			compose.RemoveVolumes(true),
			compose.RemoveImagesLocal,
		)
	})

	// Connect to exposed Postgres
	dsn := fmt.Sprintf("postgres://e2e_test:e2e_test_secret@localhost:%s/e2e_test_db?sslmode=disable", postgresPort)
	db, err := sqlx.Connect("postgres", dsn)
	if err != nil {
		t.Fatalf("connecting to postgres: %v", err)
	}
	t.Cleanup(func() { db.Close() })

	if err := database.MigrationUp(ctx, db); err != nil {
		t.Fatalf("migrations: %v", err)
	}
	db.MustExec("INSERT INTO users (id) VALUES ($1)", testUserID)

	// Connect to exposed Redis
	redisClient := redis.NewClient(&redis.Options{Addr: fmt.Sprintf("localhost:%s", redisPort)})
	t.Cleanup(func() { redisClient.Close() })

	// Start Go backend in-process
	baseURL := startBackend(t, db, redisClient)
	client := newArticlesClient(t, baseURL)

	_, err = client.ParseArticle(t.Context(), connect.NewRequest(&v1.ParseArticleRequest{
		Url: "http://test-server/article.html",
	}))
	if err != nil {
		t.Fatalf("ParseArticle: %v", err)
	}

	// Poll until ready (longer timeout for Docker)
	resp := pollArticleUntilReady(t, client, 90*time.Second)

	if resp.TotalCount != 1 {
		t.Fatalf("expected 1 article, got %d", resp.TotalCount)
	}
	article := resp.Articles[0]
	if article.Status != "ready" {
		t.Errorf("expected status 'ready', got %q", article.Status)
	}
	if article.Title != "The Bitter Lesson" {
		t.Errorf("expected title 'The Bitter Lesson', got %q", article.Title)
	}
	if article.Author != "Richard Sutton" {
		t.Errorf("expected author 'Richard Sutton', got %q", article.Author)
	}
	if article.Description != nil && !strings.Contains(*article.Description, "The biggest lesson that can be read from 70 years of AI research") {
		t.Errorf("expected description to contain 'The biggest lesson that can be read from 70 years of AI research', got %q", *article.Description)
	}

	t.Logf("Passed! Article title: %s, author: %s, published date: %s", article.Title, article.Author, article.Date)
}
