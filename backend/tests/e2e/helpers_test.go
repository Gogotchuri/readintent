package e2e

import (
	"context"
	"fmt"
	"net/http"
	"testing"
	"time"

	"connectrpc.com/connect"
	"github.com/gogotchuri/readintent/backend/config"
	"github.com/gogotchuri/readintent/backend/database"
	"github.com/gogotchuri/readintent/backend/middlewares"
	v1 "github.com/gogotchuri/readintent/backend/proto/articles/v1"
	"github.com/gogotchuri/readintent/backend/proto/articles/v1/articlesv1connect"
	"github.com/gogotchuri/readintent/backend/services/articles"
	articlesadapters "github.com/gogotchuri/readintent/backend/services/articles/adapters"
	articlesconnectrpc "github.com/gogotchuri/readintent/backend/services/articles/ports/connectrpc"
	"github.com/gogotchuri/readintent/backend/services/articles/repositories"
	authmodels "github.com/gogotchuri/readintent/backend/services/auth/models"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
	"github.com/redis/go-redis/v9"
	"github.com/testcontainers/testcontainers-go"
	tcpostgres "github.com/testcontainers/testcontainers-go/modules/postgres"
	tcredis "github.com/testcontainers/testcontainers-go/modules/redis"
	"github.com/testcontainers/testcontainers-go/wait"
)

const testUserID = "e2e-test-user"
const rpcPort = "19922"

func startPostgresAndRedis(t *testing.T) (*sqlx.DB, *redis.Client) {
	t.Helper()
	ctx := t.Context()

	// Postgres
	pgContainer, err := tcpostgres.Run(ctx, "postgres:16-alpine",
		tcpostgres.WithDatabase("e2e_test"),
		tcpostgres.WithUsername("test"),
		tcpostgres.WithPassword("test"),
		testcontainers.WithWaitStrategy(
			wait.ForLog("database system is ready to accept connections").
				WithOccurrence(2).WithStartupTimeout(30*time.Second),
		),
	)
	if err != nil {
		t.Fatalf("starting postgres: %v", err)
	}
	t.Cleanup(func() { pgContainer.Terminate(context.Background()) })

	pgConn, err := pgContainer.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		t.Fatalf("getting postgres connection string: %v", err)
	}
	db, err := sqlx.Connect("postgres", pgConn)
	if err != nil {
		t.Fatalf("connecting to postgres: %v", err)
	}
	t.Cleanup(func() { db.Close() })

	if err := database.MigrationUp(ctx, db); err != nil {
		t.Fatalf("migrations: %v", err)
	}
	db.MustExec("INSERT INTO users (id) VALUES ($1)", testUserID)

	// Redis
	redisContainer, err := tcredis.Run(ctx, "redis:7-alpine")
	if err != nil {
		t.Fatalf("starting redis: %v", err)
	}
	t.Cleanup(func() { redisContainer.Terminate(context.Background()) })

	redisAddr, err := redisContainer.ConnectionString(ctx)
	if err != nil {
		t.Fatalf("getting redis connection string: %v", err)
	}
	opts, err := redis.ParseURL(redisAddr)
	if err != nil {
		t.Fatalf("parsing redis URL: %v", err)
	}
	redisClient := redis.NewClient(opts)
	t.Cleanup(func() { redisClient.Close() })

	return db, redisClient
}

func startBackend(t *testing.T, db *sqlx.DB, redisClient *redis.Client) string {
	t.Helper()

	hub := articlesadapters.NewArticlesHub(redisClient, config.RedisStreams{
		GroupName:    "backend-e2e-group",
		ConsumerName: "backend-e2e-consumer",
	})

	repo := repositories.NewPgArticlesRepository(db)
	svc := articles.NewService(repo, hub)

	hub.AddListener(articlesadapters.ScrapeResultStream, svc.HandleScrapeResult)
	hub.AddListener(articlesadapters.PhonemizerResultStream, svc.HandlePhonemizerResult)

	ctx, cancel := context.WithCancel(t.Context())
	t.Cleanup(cancel)
	go func() { hub.Listen(ctx) }()

	server := articlesconnectrpc.NewArticlesServer(svc, &mockSessionGetter{userID: testUserID})
	mux := http.NewServeMux()
	server.BindArticlesServerToMux(mux)

	addr := fmt.Sprintf("localhost:%s", rpcPort)
	httpServer := &http.Server{Addr: addr, Handler: mux}
	protoc := new(http.Protocols)
	protoc.SetHTTP1(true)
	protoc.SetUnencryptedHTTP2(true)
	httpServer.Protocols = protoc

	go func() { httpServer.ListenAndServe() }()
	t.Cleanup(func() { httpServer.Shutdown(context.Background()) })
	time.Sleep(500 * time.Millisecond)

	return fmt.Sprintf("http://%s", addr)
}

type mockSessionGetter struct{ userID string }

func (m *mockSessionGetter) GetSession(_ context.Context, _ string) (*authmodels.Session, error) {
	return &authmodels.Session{
		Identity:     authmodels.Identity{ID: m.userID},
		SessionToken: "e2e-token",
	}, nil
}

var _ middlewares.SessionGetter = &mockSessionGetter{}

func newArticlesClient(t *testing.T, baseURL string) articlesv1connect.ArticlesServiceClient {
	t.Helper()
	return articlesv1connect.NewArticlesServiceClient(
		http.DefaultClient,
		baseURL,
		connect.WithInterceptors(&tokenInterceptor{}),
	)
}

type tokenInterceptor struct{}

func (i *tokenInterceptor) WrapUnary(next connect.UnaryFunc) connect.UnaryFunc {
	return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
		req.Header().Set("X-Session-Token", "e2e-token")
		return next(ctx, req)
	}
}

func (i *tokenInterceptor) WrapStreamingClient(next connect.StreamingClientFunc) connect.StreamingClientFunc {
	return next
}

func (i *tokenInterceptor) WrapStreamingHandler(next connect.StreamingHandlerFunc) connect.StreamingHandlerFunc {
	return next
}

func pollArticleUntilReady(t *testing.T, client articlesv1connect.ArticlesServiceClient, timeout time.Duration) *v1.GetArticlesResponse {
	t.Helper()
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		resp, err := client.GetArticles(t.Context(), connect.NewRequest(&v1.GetArticlesRequest{PageSize: 10}))
		if err != nil {
			t.Fatalf("GetArticles: %v", err)
		}
		if resp.Msg.TotalCount > 0 && resp.Msg.Articles[0].Status == "ready" {
			return resp.Msg
		}
		time.Sleep(500 * time.Millisecond)
	}
	t.Fatal("timed out waiting for article to get ready status")
	return nil
}
