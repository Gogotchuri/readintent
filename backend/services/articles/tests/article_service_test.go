package tests

import (
	"testing"

	"connectrpc.com/connect"
	v1 "github.com/gogotchuri/readintent/backend/proto/articles/v1"
)

func TestParseAndGetArticle(t *testing.T) {
	const userID = "test-user-001"
	const articleURL = "https://example.com/test-article"

	startComposeStack(t)
	db := connectAndMigrate(t)
	insertTestUser(t, db, userID)
	baseURL := startArticlesServer(t, db, userID)
	client := newArticlesClient(t, baseURL)

	// ParseArticle
	_, err := client.ParseArticle(t.Context(), connect.NewRequest(&v1.ParseArticleRequest{
		Url: articleURL,
	}))
	if err != nil {
		t.Fatalf("ParseArticle failed: %v", err)
	}

	// GetArticles — verify the article shows up
	resp, err := client.GetArticles(t.Context(), connect.NewRequest(&v1.GetArticlesRequest{
		PageSize: 10,
	}))
	if err != nil {
		t.Fatalf("GetArticles failed: %v", err)
	}

	if resp.Msg.TotalCount != 1 {
		t.Fatalf("expected 1 article, got %d", resp.Msg.TotalCount)
	}
	article := resp.Msg.Articles[0]
	if article.Url != articleURL {
		t.Errorf("expected URL %s, got %s", articleURL, article.Url)
	}
	if article.Status != "processing" {
		t.Errorf("expected status 'processing', got %s", article.Status)
	}
}
