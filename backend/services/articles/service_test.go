package articles

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/gogotchuri/readintent/backend/database/models"
	iomodels "github.com/gogotchuri/readintent/backend/services/articles/models"
)

func TestService_ParseArticle_NewArticle(t *testing.T) {
	const userID = "user-123"
	const articleURL = "https://example.com/article"
	createdArticle := &models.Article{Id: 1, Url: articleURL}

	repo := &mockRepository{
		GetArticleForUserWithURLFn: func(_ context.Context, uid, u string) (*models.Article, error) {
			if uid != userID || u != articleURL {
				t.Fatalf("unexpected args: uid=%s url=%s", uid, u)
			}
			return nil, ErrArticleNotFound
		},
		GetArticleWithURLFn: func(_ context.Context, u string) (*models.Article, error) {
			if u != articleURL {
				t.Fatalf("unexpected url: %s", u)
			}
			return nil, ErrArticleNotFound
		},
		CreateInitialArticleFn: func(_ context.Context, uid, u string) (*models.Article, error) {
			if uid != userID || u != articleURL {
				t.Fatalf("unexpected args: uid=%s url=%s", uid, u)
			}
			return createdArticle, nil
		},
	}

	var submittedID int64
	var submittedURL string
	submitter := &mockSubmitter{
		SubmitArticleFn: func(_ context.Context, articleID int64, url, html string) error {
			submittedID = articleID
			submittedURL = url
			return nil
		},
	}

	svc := NewService(repo, submitter, nil)
	err := svc.ParseArticle(context.Background(), userID, articleURL, "")
	if err != nil {
		t.Fatalf("ParseArticle returned error: %v", err)
	}

	if submittedID != createdArticle.Id {
		t.Errorf("expected submitted article ID %d, got %d", createdArticle.Id, submittedID)
	}
	if submittedURL != articleURL {
		t.Errorf("expected submitted URL %s, got %s", articleURL, submittedURL)
	}
}

func TestService_ParseArticle_WithExistingArticle(t *testing.T) {
	const userID = "user-123"
	const articleURL = "https://example.com/article"
	createdArticle := &models.Article{Id: 1, Url: articleURL}
	repo := &mockRepository{
		GetArticleForUserWithURLFn: func(_ context.Context, uid, u string) (*models.Article, error) {
			return nil, ErrArticleNotFound
		},
		GetArticleWithURLFn: func(_ context.Context, u string) (*models.Article, error) {
			if u != articleURL {
				t.Fatalf("unexpected url: %s", u)
			}
			return createdArticle, nil
		},
		AddArticleForUserFn: func(_ context.Context, uid string, articleID int64) error {
			if uid != userID {
				t.Fatalf("unexpected userID: %s", uid)
			}
			if articleID != createdArticle.Id {
				t.Fatalf("unexpected articleID: %d", articleID)
			}
			return nil
		},
	}

	submitter := &mockSubmitter{
		SubmitArticleFn: func(_ context.Context, articleID int64, url, html string) error {
			t.Fatalf("SubmitArticle should not be called for existing article")
			return nil
		},
	}
	svc := NewService(repo, submitter, nil)
	err := svc.ParseArticle(context.Background(), userID, articleURL, "")
	if err != nil {
		t.Fatalf("ParseArticle returned error: %v", err)
	}
}

func TestService_GetArticles(t *testing.T) {
	const userID = "user-123"
	req := iomodels.GetArticlesRequest{PageSize: 10}
	expected := &iomodels.GetArticlesResponse{
		Articles:      []models.ArticlePreview{{Id: 1}, {Id: 2}},
		NextPageToken: "123:2",
		TotalCount:    2,
	}

	repo := &mockRepository{
		GetArticlesFn: func(_ context.Context, uid string, q iomodels.GetArticlesRequest) (*iomodels.GetArticlesResponse, error) {
			if uid != userID {
				t.Fatalf("unexpected userID: %s", uid)
			}
			if q.PageSize != req.PageSize {
				t.Fatalf("unexpected page size: %d", q.PageSize)
			}
			return expected, nil
		},
	}

	svc := NewService(repo, nil, nil)
	resp, err := svc.GetArticles(context.Background(), userID, req)
	if err != nil {
		t.Fatalf("GetArticles returned error: %v", err)
	}
	if resp.TotalCount != expected.TotalCount {
		t.Errorf("expected total count %d, got %d", expected.TotalCount, resp.TotalCount)
	}
	if len(resp.Articles) != len(expected.Articles) {
		t.Errorf("expected %d articles, got %d", len(expected.Articles), len(resp.Articles))
	}
}

func TestService_GetArticle(t *testing.T) {
	const userID = "user-123"
	const articleID int64 = 1
	expected := &models.Article{Id: articleID, Url: "https://example.com/article"}

	repo := &mockRepository{
		GetArticleForUserFn: func(_ context.Context, uid string, id int64) (*models.Article, error) {
			if uid != userID {
				t.Fatalf("unexpected userID: %s", uid)
			}
			if id != articleID {
				t.Fatalf("unexpected articleID: %d", id)
			}
			return expected, nil
		},
	}

	svc := NewService(repo, nil, nil)
	article, err := svc.GetArticle(context.Background(), userID, articleID)
	if err != nil {
		t.Fatalf("GetArticle returned error: %v", err)
	}
	if article.Id != expected.Id {
		t.Errorf("expected article ID %d, got %d", expected.Id, article.Id)
	}
}

func TestService_DeleteArticle(t *testing.T) {
	const userID = "user-123"
	const articleID int64 = 1
	var deleteCalled bool

	repo := &mockRepository{
		DeleteArticleFn: func(_ context.Context, uid string, id int64) error {
			if uid != userID {
				t.Fatalf("unexpected userID: %s", uid)
			}
			if id != articleID {
				t.Fatalf("unexpected articleID: %d", id)
			}
			deleteCalled = true
			return nil
		},
	}

	svc := NewService(repo, nil, nil)
	err := svc.DeleteArticle(context.Background(), userID, articleID)
	if err != nil {
		t.Fatalf("DeleteArticle returned error: %v", err)
	}
	if !deleteCalled {
		t.Error("expected DeleteArticle to be called on repository")
	}
}

func TestService_HandleScrapeResult(t *testing.T) {
	const articleID int64 = 1
	resultJSON := `{"url":"https://example.com/article","title":"Test Title"}`

	// The final status is derived in SQL (see repository ApplyScrapeResult tests);
	// here we only assert the handler forwards the parsed scrape data unchanged.
	var applied models.Article
	repo := &mockRepository{
		ApplyScrapeResultFn: func(_ context.Context, article models.Article) error {
			applied = article
			return nil
		},
	}

	svc := NewService(repo, nil, nil)
	msg := map[string]any{
		"article_id": "1",
		"result":     resultJSON,
	}
	err := svc.HandleScrapeResult(context.Background(), msg)
	if err != nil {
		t.Fatalf("HandleScrapeResult returned error: %v", err)
	}
	if applied.Id != articleID {
		t.Errorf("expected article ID %d, got %d", articleID, applied.Id)
	}
	if applied.Url != "https://example.com/article" {
		t.Errorf("unexpected url: %s", applied.Url)
	}
	if applied.Title.String() != "Test Title" {
		t.Errorf("expected title 'Test Title', got %s", applied.Title.String())
	}
}

func TestService_HandleScrapeResult_Err(t *testing.T) {
	const articleID int64 = 1
	//Articles can't exist without an URL
	resultJSON := `{"title":"Test Title"}`

	var updatedArticle models.Article
	repo := &mockRepository{
		UpdateArticleFn: func(_ context.Context, article models.Article) error {
			updatedArticle = article
			return nil
		},
		GetArticleByIDFn: func(_ context.Context, id int64) (*models.Article, error) {
			if id != articleID {
				t.Fatalf("unexpected articleID: %d", id)
			}
			return &updatedArticle, nil
		},
	}

	svc := NewService(repo, nil, nil)
	msg := map[string]any{
		"article_id": "1",
		"result":     resultJSON,
	}
	err := svc.HandleScrapeResult(context.Background(), msg)
	if err == nil {
		t.Fatal("expected HandleScrapeResult to return error for invalid scrape result")
	}
	if !strings.Contains(err.Error(), "invalid article url") {
		t.Fatal("expected HandleScrapeResult to return error for invalid article url")
	}

}

func TestService_HandleScrapeError(t *testing.T) {
	const articleID int64 = 1
	existingArticle := &models.Article{Url: "https://example.com/article"}

	var updatedArticle models.Article
	repo := &mockRepository{
		GetArticleByIDFn: func(_ context.Context, id int64) (*models.Article, error) {
			if id != articleID {
				t.Fatalf("unexpected articleID: %d", id)
			}
			return existingArticle, nil
		},
		UpdateArticleFn: func(_ context.Context, article models.Article) error {
			updatedArticle = article
			return nil
		},
	}

	svc := NewService(repo, nil, nil)
	msg := map[string]any{
		"article_id": "1",
		"error":      `{"msg":"scrape failed"}`,
	}
	err := svc.HandleScrapeResult(context.Background(), msg)
	if err != nil {
		t.Fatalf("HandleScrapeResult with error returned error: %v", err)
	}
	if updatedArticle.Status != models.ArticleStatusFailed {
		t.Errorf("expected status %s, got %s", models.ArticleStatusFailed, updatedArticle.Status)
	}
}

func TestService_HandlePhonemizerResult(t *testing.T) {
	const articleID int64 = 1
	phonemizerJSON := `[{"graphemes":"hello","phonemes":"hello","token_ids":[1,2],"token_meta":[]}]`

	// The final status is derived in SQL (see repository ApplyPhonemizerResult
	// tests); here we only assert the handler forwards the parsed phonemizer data.
	var appliedID int64
	var appliedData models.JSONB[[]models.PhonemizerData]
	repo := &mockRepository{
		ApplyPhonemizerResultFn: func(_ context.Context, id int64, data models.JSONB[[]models.PhonemizerData]) error {
			appliedID = id
			appliedData = data
			return nil
		},
	}

	svc := NewService(repo, nil, nil)
	msg := map[string]any{
		"article_id": "1",
		"result":     phonemizerJSON,
	}
	err := svc.HandlePhonemizerResult(context.Background(), msg)
	if err != nil {
		t.Fatalf("HandlePhonemizerResult returned error: %v", err)
	}
	if appliedID != articleID {
		t.Errorf("expected article ID %d, got %d", articleID, appliedID)
	}
	if !appliedData.Valid {
		t.Fatal("expected PhonemizerData to be valid")
	}
	if len(appliedData.Data) != 1 {
		t.Fatalf("expected 1 phonemizer entry, got %d", len(appliedData.Data))
	}
	if appliedData.Data[0].Graphemes != "hello" {
		t.Errorf("expected graphemes 'hello', got %s", appliedData.Data[0].Graphemes)
	}
}

func TestService_HandlePhonemizerResult_Error(t *testing.T) {
	const articleID int64 = 1
	existingArticle := &models.Article{Url: "https://example.com/article"}

	var updatedArticle models.Article
	repo := &mockRepository{
		GetArticleByIDFn: func(_ context.Context, id int64) (*models.Article, error) {
			if id != articleID {
				t.Fatalf("unexpected articleID: %d", id)
			}
			return existingArticle, nil
		},
		UpdateArticleFn: func(_ context.Context, article models.Article) error {
			updatedArticle = article
			return nil
		},
	}

	svc := NewService(repo, nil, nil)
	msg := map[string]any{
		"article_id": "1",
		"error":      `{"msg":"phonemizer failed"}`,
	}
	err := svc.HandlePhonemizerResult(context.Background(), msg)
	if err != nil {
		t.Fatalf("HandlePhonemizerResult with error returned error: %v", err)
	}
	if updatedArticle.Status != models.ArticleStatusFailed {
		t.Errorf("expected status %s, got %s", models.ArticleStatusFailed, updatedArticle.Status)
	}
}

func TestService_ParseArticle_InvalidURL(t *testing.T) {
	svc := NewService(&mockRepository{}, &mockSubmitter{}, nil)
	tests := []struct {
		name string
		url  string
	}{
		{"empty URL", ""},
		{"ftp scheme", "ftp://example.com/file"},
		{"no scheme", "example.com/article"},
		{"missing host", "https:///path"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := svc.ParseArticle(context.Background(), "user-123", tt.url, "")
			if err == nil {
				t.Fatal("expected error for invalid URL")
			}
		})
	}
}

func TestService_ParseArticle_URLNormalization(t *testing.T) {
	var repoReceivedURL string
	repo := &mockRepository{
		GetArticleForUserWithURLFn: func(_ context.Context, _, u string) (*models.Article, error) {
			repoReceivedURL = u
			return nil, ErrArticleNotFound
		},
		GetArticleWithURLFn: func(_ context.Context, u string) (*models.Article, error) {
			return nil, ErrArticleNotFound
		},
		CreateInitialArticleFn: func(_ context.Context, _, u string) (*models.Article, error) {
			return &models.Article{Id: 1, Url: u}, nil
		},
	}
	submitter := &mockSubmitter{
		SubmitArticleFn: func(_ context.Context, _ int64, _, _ string) error { return nil },
	}
	svc := NewService(repo, submitter, nil)

	err := svc.ParseArticle(context.Background(), "user-123",
		"HTTPS://EXAMPLE.COM/Article/?utm_source=twitter&fbclid=abc", "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if repoReceivedURL != "https://example.com/Article" {
		t.Errorf("expected normalized URL, got %q", repoReceivedURL)
	}
}

// mockRepository implements Repository using function fields.
type mockRepository struct {
	GetArticlesFn              func(ctx context.Context, userID string, searchQ iomodels.GetArticlesRequest) (*iomodels.GetArticlesResponse, error)
	GetArticleByIDFn           func(ctx context.Context, id int64) (*models.Article, error)
	GetArticleForUserFn        func(ctx context.Context, userID string, id int64) (*models.Article, error)
	GetArticleForUserWithURLFn func(ctx context.Context, userID, url string) (*models.Article, error)
	GetArticleWithURLFn        func(ctx context.Context, url string) (*models.Article, error)
	CreateInitialArticleFn     func(ctx context.Context, userID, url string) (*models.Article, error)
	AddArticleForUserFn        func(ctx context.Context, userID string, articleID int64) error
	UpdateArticleFn            func(ctx context.Context, article models.Article) error
	ApplyScrapeResultFn        func(ctx context.Context, article models.Article) error
	ApplyPhonemizerResultFn    func(ctx context.Context, articleID int64, data models.JSONB[[]models.PhonemizerData]) error
	DeleteArticleFn            func(ctx context.Context, userID string, id int64) error
	HasUpdatedArticlesFn       func(ctx context.Context, userID string, since time.Time) (bool, error)
	SaveArticleProgressFn      func(ctx context.Context, userID string, articleID int64, playerPositionMs int64, scrollPosition float64, playbackSpeed float64) error
	GetUserIDsForArticleFn     func(ctx context.Context, articleID int64) ([]string, error)
	GetArticlePreviewForUserFn func(ctx context.Context, userID string, articleID int64) (*models.ArticlePreview, error)
}

func (m *mockRepository) GetArticles(ctx context.Context, userID string, searchQ iomodels.GetArticlesRequest) (*iomodels.GetArticlesResponse, error) {
	return m.GetArticlesFn(ctx, userID, searchQ)
}
func (m *mockRepository) GetArticleByID(ctx context.Context, id int64) (*models.Article, error) {
	return m.GetArticleByIDFn(ctx, id)
}
func (m *mockRepository) GetArticleForUser(ctx context.Context, userID string, id int64) (*models.Article, error) {
	return m.GetArticleForUserFn(ctx, userID, id)
}
func (m *mockRepository) GetArticleForUserWithURL(ctx context.Context, userID, url string) (*models.Article, error) {
	return m.GetArticleForUserWithURLFn(ctx, userID, url)
}
func (m *mockRepository) GetArticleWithURL(ctx context.Context, url string) (*models.Article, error) {
	return m.GetArticleWithURLFn(ctx, url)
}
func (m *mockRepository) CreateInitialArticle(ctx context.Context, userID, url string) (*models.Article, error) {
	return m.CreateInitialArticleFn(ctx, userID, url)
}
func (m *mockRepository) AddArticleForUser(ctx context.Context, userID string, articleID int64) error {
	return m.AddArticleForUserFn(ctx, userID, articleID)
}
func (m *mockRepository) UpdateArticle(ctx context.Context, article models.Article) error {
	return m.UpdateArticleFn(ctx, article)
}
func (m *mockRepository) ApplyScrapeResult(ctx context.Context, article models.Article) error {
	return m.ApplyScrapeResultFn(ctx, article)
}
func (m *mockRepository) ApplyPhonemizerResult(ctx context.Context, articleID int64, data models.JSONB[[]models.PhonemizerData]) error {
	return m.ApplyPhonemizerResultFn(ctx, articleID, data)
}
func (m *mockRepository) DeleteArticle(ctx context.Context, userID string, id int64) error {
	return m.DeleteArticleFn(ctx, userID, id)
}
func (m *mockRepository) SaveArticleProgress(ctx context.Context, userID string, articleID int64, playerPositionMs int64, scrollPosition float64, playbackSpeed float64) error {
	if m.SaveArticleProgressFn != nil {
		return m.SaveArticleProgressFn(ctx, userID, articleID, playerPositionMs, scrollPosition, playbackSpeed)
	}
	return nil
}
func (m *mockRepository) HasUpdatedArticles(ctx context.Context, userID string, since time.Time) (bool, error) {
	if m.HasUpdatedArticlesFn != nil {
		return m.HasUpdatedArticlesFn(ctx, userID, since)
	}
	return false, nil
}
func (m *mockRepository) GetUserIDsForArticle(ctx context.Context, articleID int64) ([]string, error) {
	if m.GetUserIDsForArticleFn != nil {
		return m.GetUserIDsForArticleFn(ctx, articleID)
	}
	return nil, nil
}
func (m *mockRepository) GetArticlePreviewForUser(ctx context.Context, userID string, articleID int64) (*models.ArticlePreview, error) {
	if m.GetArticlePreviewForUserFn != nil {
		return m.GetArticlePreviewForUserFn(ctx, userID, articleID)
	}
	return nil, nil
}

// mockSubmitter implements ArticleSubmitter using function fields.
type mockSubmitter struct {
	SubmitArticleFn func(ctx context.Context, articleID int64, url, html string) error
}

func (m *mockSubmitter) SubmitArticle(ctx context.Context, articleID int64, url, html string) error {
	return m.SubmitArticleFn(ctx, articleID, url, html)
}
