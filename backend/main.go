package main

import (
	"context"
	"fmt"
	"net/http"
	"sync"

	"github.com/gogotchuri/readintent/backend/config"
	"github.com/gogotchuri/readintent/backend/database"
	"github.com/gogotchuri/readintent/backend/services/auth"
	"github.com/gogotchuri/readintent/backend/services/auth/adapters"
	authconnectrpc "github.com/gogotchuri/readintent/backend/services/auth/ports/connectrpc"
	"github.com/gogotchuri/readintent/backend/services/auth/repositories"
	"github.com/jmoiron/sqlx"
)

// TODO: This is hardcoded and will be replaced with env config reader package
const (
	kratosPublicURL = "http://localhost:4433"
	rpcURL          = "localhost:8000"
)

// TODO logging
func main() {
	var wg sync.WaitGroup
	wg.Add(1)
	go initializeAuthConnectRPCServer(&wg)
	fmt.Printf("Started ConnectRPC auth server on: %s", rpcURL)
	wg.Wait()
}

func initializeAuthConnectRPCServer(wg *sync.WaitGroup) {
	defer wg.Done()
	mux := http.NewServeMux()
	kratosClient := adapters.NewKratosClient(kratosPublicURL)
	//TODO setup db here
	var db *sqlx.DB
	userRepo := repositories.NewUserRepository(db)
	service := auth.NewService(kratosClient, userRepo)
	//TODO grantClaimer
	connectRPC := authconnectrpc.NewAuthServer(service, nil)
	connectRPC.BindAuthServerToMux(mux)
	protoc := new(http.Protocols)
	//TODO currently setting insecure and HTTP1, but we will need to make this dev only option with config
	protoc.SetHTTP1(true)
	protoc.SetUnencryptedHTTP2(true)
	server := http.Server{
		Addr:      rpcURL,
		Handler:   mux,
		Protocols: protoc,
	}
	// TODO graceful shutdown
	if err := server.ListenAndServe(); err != nil {
		fmt.Printf("Server shutdown; reason: %w", err)
	}
}

func loadConfig() config.Config {
	if err := config.SetEnvFromFile(".env"); err != nil {
		// We try to load the config from .env file, if it doesn't exist that is also fine
		// By default we will parse config from the ENV
		//TODO proper logging
		fmt.Printf("No .env file found, loading config from environment variables: %v", err)
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
	return db
}
