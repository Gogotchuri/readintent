package tests

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"testing"
	"time"

	"connectrpc.com/connect"
	"github.com/gogotchuri/readintent/backend/database"
	"github.com/gogotchuri/readintent/backend/middlewares"
	"github.com/gogotchuri/readintent/backend/proto/articles/v1/articlesv1connect"
	"github.com/gogotchuri/readintent/backend/services/articles"
	articlesconnectrpc "github.com/gogotchuri/readintent/backend/services/articles/ports/connectrpc"
	"github.com/gogotchuri/readintent/backend/services/articles/repositories"
	authmodels "github.com/gogotchuri/readintent/backend/services/auth/models"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
	"github.com/testcontainers/testcontainers-go/modules/compose"
	"github.com/testcontainers/testcontainers-go/wait"
)

const postgresPort = "15432"
const rpcPort = "13922"

func startComposeStack(t *testing.T) {
	t.Helper()
	t.Chdir("testdata")
	stack, err := compose.NewDockerComposeWith(
		compose.WithStackFiles("./docker-compose.yml"),
		compose.StackIdentifier(fmt.Sprintf("articles-test-%s-stack", strings.ToLower(t.Name()))),
	)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(t.Context())
	t.Cleanup(cancel)

	err = stack.
		WithEnv(map[string]string{"POSTGRES_PORT": postgresPort}).
		WaitForService("postgres", wait.ForHealthCheck()).
		Up(ctx, compose.Wait(true))
	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		err = stack.Down(
			context.Background(),
			compose.RemoveOrphans(true),
			compose.RemoveVolumes(true),
			compose.RemoveImagesLocal,
		)
		if err != nil {
			t.Log(err)
		}
	})
}

func connectAndMigrate(t *testing.T) *sqlx.DB {
	t.Helper()
	dsn := fmt.Sprintf("postgres://articles_test:articles_test_secret@localhost:%s/articles_test_db?sslmode=disable", postgresPort)
	db, err := sqlx.Connect("postgres", dsn)
	if err != nil {
		t.Fatalf("connecting to postgres: %v", err)
	}
	t.Cleanup(func() { db.Close() })

	if err := database.MigrationUp(t.Context(), db); err != nil {
		t.Fatalf("running migrations: %v", err)
	}
	return db
}

func insertTestUser(t *testing.T, db *sqlx.DB, userID string) {
	t.Helper()
	_, err := db.Exec("INSERT INTO users (id) VALUES ($1) ON CONFLICT DO NOTHING", userID)
	if err != nil {
		t.Fatalf("inserting test user: %v", err)
	}
}

// mockSessionGetter always returns a valid session for the configured userID.
type mockSessionGetter struct {
	userID string
}

func (m *mockSessionGetter) GetSession(_ context.Context, _ string) (*authmodels.Session, error) {
	return &authmodels.Session{
		Identity:     authmodels.Identity{ID: m.userID},
		SessionToken: "test-token",
	}, nil
}

var _ middlewares.SessionGetter = &mockSessionGetter{}

// mockSubmitter is a no-op submitter for E2E tests (we just verify DB state).
type mockSubmitter struct{}

func (m *mockSubmitter) SubmitArticle(_ context.Context, _ int64, _, _ string) error {
	return nil
}

var _ articles.ArticleSubmitter = &mockSubmitter{}

func startArticlesServer(t *testing.T, db *sqlx.DB, userID string) string {
	t.Helper()
	repo := repositories.NewPgArticlesRepository(db)
	svc := articles.NewService(repo, &mockSubmitter{})
	server := articlesconnectrpc.NewArticlesServer(svc, &mockSessionGetter{userID: userID})

	mux := http.NewServeMux()
	server.BindArticlesServerToMux(mux)

	addr := fmt.Sprintf("localhost:%s", rpcPort)
	protoc := new(http.Protocols)
	protoc.SetHTTP1(true)
	protoc.SetUnencryptedHTTP2(true)
	httpServer := &http.Server{
		Addr:      addr,
		Handler:   mux,
		Protocols: protoc,
	}
	go func() { _ = httpServer.ListenAndServe() }()
	t.Cleanup(func() { httpServer.Shutdown(context.Background()) })
	time.Sleep(500 * time.Millisecond)

	return fmt.Sprintf("http://%s", addr)
}

func newArticlesClient(t *testing.T, baseURL string) articlesv1connect.ArticlesServiceClient {
	t.Helper()
	return articlesv1connect.NewArticlesServiceClient(
		http.DefaultClient,
		baseURL,
		connect.WithInterceptors(&tokenInterceptor{}),
	)
}

// tokenInterceptor injects the X-Session-Token header into all requests.
type tokenInterceptor struct{}

func (i *tokenInterceptor) WrapUnary(next connect.UnaryFunc) connect.UnaryFunc {
	return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
		req.Header().Set("X-Session-Token", "test-token")
		return next(ctx, req)
	}
}

func (i *tokenInterceptor) WrapStreamingClient(next connect.StreamingClientFunc) connect.StreamingClientFunc {
	return next
}

func (i *tokenInterceptor) WrapStreamingHandler(next connect.StreamingHandlerFunc) connect.StreamingHandlerFunc {
	return next
}
