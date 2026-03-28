package main

import (
	"fmt"
	"net/http"
	"sync"

	"github.com/gogotchuri/readintent/backend/services/auth"
	"github.com/gogotchuri/readintent/backend/services/auth/adapters"
	authconnectrpc "github.com/gogotchuri/readintent/backend/services/auth/ports/connectrpc"
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
	service := auth.NewService(kratosClient)
	connectRPC := authconnectrpc.NewAuthServer(service)
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
