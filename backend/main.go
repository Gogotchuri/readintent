package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gogotchuri/readintent/backend/config"
	"github.com/gogotchuri/readintent/backend/database"
	"github.com/gogotchuri/readintent/backend/services/articles"
	articlesadapters "github.com/gogotchuri/readintent/backend/services/articles/adapters"
	"github.com/gogotchuri/readintent/backend/services/articles/broker"
	articlesconnectrpc "github.com/gogotchuri/readintent/backend/services/articles/ports/connectrpc"
	articlesrepo "github.com/gogotchuri/readintent/backend/services/articles/repositories"
	"github.com/gogotchuri/readintent/backend/services/auth"
	"github.com/gogotchuri/readintent/backend/services/auth/adapters"
	authconnectrpc "github.com/gogotchuri/readintent/backend/services/auth/ports/connectrpc"
	"github.com/gogotchuri/readintent/backend/services/auth/repositories"
	"github.com/gogotchuri/readintent/backend/services/extension"
	exthttp "github.com/gogotchuri/readintent/backend/services/extension/ports/http"
	extrepo "github.com/gogotchuri/readintent/backend/services/extension/repositories"
	"github.com/gogotchuri/readintent/backend/services/extension/tokens"
	"github.com/jmoiron/sqlx"
	"github.com/redis/go-redis/v9"
)

func main() {
	// Initialize supporting infrasturcture
	initializeLogger()
	cfg := loadConfig()
	db := setupDB(cfg)
	defer db.Close()
	redisClient := initializeRedisClient(cfg)
	defer redisClient.Close()

	// Signals for graceful shutdown
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	articlesHub := articlesadapters.NewArticlesHub(redisClient, cfg.RedisStreams)

	// In-memory broker fans out article updates to open streams (single replica).
	articleBroker := broker.NewMemoryBroker()

	// Articles service
	articleRepo := articlesrepo.NewPgArticlesRepository(db)
	articleService := articles.NewService(articleRepo, articlesHub, articleBroker)
	articlesHub.AddListener(articlesadapters.ScrapeResultStream, articleService.HandleScrapeResult)
	articlesHub.AddListener(articlesadapters.PhonemizerResultStream, articleService.HandlePhonemizerResult)

	extService, extServer := initializeExtensionServiceAndServer(db, articleService)

	// Auth service
	kratosClient := adapters.NewKratosClient(cfg.KratosPublicURL)
	userRepo := repositories.NewUserRepository(db)
	authService := auth.NewService(kratosClient, userRepo)

	mux := http.NewServeMux()

	// Health check endpoint (DB + Redis + Kratos readiness)
	registerHealthRoutes(mux, db, redisClient, kratosClient)

	// Auth ConnectRPC server
	authServer := authconnectrpc.NewAuthServer(authService, extService)
	authServer.BindAuthServerToMux(mux)

	// Articles ConnectRPC server
	articlesServer := articlesconnectrpc.NewArticlesServer(ctx, articleService, authService, articleBroker)
	articlesServer.BindArticlesServerToMux(mux)

	// Extension HTTP server
	extServer.RegisterRoutes(mux)

	addr := fmt.Sprintf(":%d", cfg.Port)
	server := http.Server{
		Addr:    addr,
		Handler: mux,
	}
	if cfg.IsDev() {
		protoc := new(http.Protocols)
		protoc.SetHTTP1(true)
		protoc.SetUnencryptedHTTP2(true)
		server.Protocols = protoc
	}

	// Start hub listener in background
	go func() {
		if err := articlesHub.Listen(ctx); err != nil {
			slog.Error("articles hub listener error", "error", err)
		}
	}()

	go func() {
		slog.Info("Starting server", "addr", addr)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			slog.Error("server error", "error", err)
		}
	}()

	<-ctx.Done()
	slog.Info("shutting down server")

	// Give 5 second cooldown, should be plenty
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		slog.Error("server shutdown error", "error", err)
	}
}

func initializeLogger() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)
}

func initializeRedisClient(cfg config.Config) *redis.Client {
	return database.NewRedisClient(cfg.RedisStreams)
}

func initializeExtensionServiceAndServer(db *sqlx.DB, articleService *articles.Service) (*extension.Service, *exthttp.ExtensionServer) {
	grantCodesRepo := extrepo.NewPgGrantCodesRepository(db)
	//TODO for dev re-generating keys every time is fine
	jwtIssuer := tokens.NewIssuer(nil, "1", "readintent", "extension", 24*time.Hour) // TODO: load key from config
	service := extension.NewService(grantCodesRepo, jwtIssuer, articleService)
	extServer := exthttp.NewExtensionServer(service, jwtIssuer)
	return service, extServer
}

func loadConfig() config.Config {
	if err := config.SetEnvFromFile("config/.env"); err != nil {
		slog.Info("no .env file found, loading config from environment variables", "error", err)
	}
	cfg, err := config.LoadConfigFromEnv()
	if err != nil {
		panic(fmt.Sprintf("failed to load config from env: %v", err))
	}
	return *cfg
}

func setupDB(cfg config.Config) *sqlx.DB {
	db, err := database.NewDatabaseConnection(context.Background(), cfg.DatabaseConfig)
	if err != nil {
		panic(fmt.Sprintf("failed to connect to database: %v", err))
	}
	//Run migrations at the start
	if err := database.MigrationUp(context.Background(), db); err != nil {
		slog.Error("migration error", "error", err)
		panic(err)
	}
	return db
}
