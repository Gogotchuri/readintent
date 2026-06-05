package tests

import (
	"context"
	"errors"
	"fmt"
	"math/rand"
	"net/http"
	"strings"
	"testing"
	"time"

	"connectrpc.com/connect"
	authv1 "github.com/gogotchuri/readintent/backend/proto/auth/v1"
	"github.com/gogotchuri/readintent/backend/proto/auth/v1/authv1connect"
	"github.com/gogotchuri/readintent/backend/services/auth"
	"github.com/gogotchuri/readintent/backend/services/auth/adapters"
	authconnectrpc "github.com/gogotchuri/readintent/backend/services/auth/ports/connectrpc"
	"github.com/testcontainers/testcontainers-go/wait"
	"google.golang.org/genproto/googleapis/rpc/errdetails"
)

// Used for utility declarations for testing connectRPC server flow with actual Kratos and Postgres containers running
// in the background. I opted to make those tests heavier and use the actual images and containers instead of mocks
// because the mocks would check nothing in this case, since what auth service is doing in this case is basically just
// forwarding the requests to Kratos and returning the responses. With the main potential failure point being the field mapping.
// Due to this nature of the service, we are going to run actual containers, connect out "gateway" connect RPC server to them
// And use connect RPC client for writing E2E tests.

// Using an awesome package called https://golang.testcontainers.org. Which allows us to spin up actual container
// instances and clean them up during test runs. We are going to use compose module, since writing configuration there is simpler.
// We should also use tmpfs for Postgres data volume to make operations that much faster and easier to clean up.

// Using a single spin-up for multiple tests without a teardown will also be part of the strategy here, since spinning up
// containers and migrating databases every single time for a single check would be time-consuming.
// Hence, tests will be longer functions with multiple checks and assertions within each.

// I also don't want to use the actual infra setup by sym-linking it under the test. It might be suceptible to security issues
// So I will be creating a new testdata folder with simplified compose setup and we have to tolerate some code duplication.

import "github.com/testcontainers/testcontainers-go/modules/compose"

const kratosPublicPort = "4021"
const kratosAdminPort = "4022"
const rpcPort = "3922"

// startComposeStackForKratos is a test helper, used for setting up Kratos compose stack.
// Also registers stack teardown as a cleanup step,
// which will be called after the outermost test who called this helper finishes with all it's subtests
// Returns ComposeStack and error
func startComposeStackForKratos(t *testing.T) (*compose.DockerCompose, error) {
	t.Helper()
	t.Chdir("testdata/kratos_compose")
	stack, err := compose.NewDockerComposeWith(
		compose.WithStackFiles("./docker-compose.yml"),
		compose.StackIdentifier(fmt.Sprintf("auth_test-%s-stack", strings.ToLower(t.Name()))),
	)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(t.Context())
	t.Cleanup(cancel)

	err = stack.
		WithEnv(map[string]string{
			"KRATOS_PORT_ADMIN":  kratosAdminPort,
			"KRATOS_PORT_PUBLIC": kratosPublicPort,
		}).
		WaitForService("kratos", wait.ForHealthCheck()).
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

	return stack, nil
}

func startConnectRPCAuthServer(t *testing.T) {
	t.Helper()
	rpcURL := fmt.Sprintf("localhost:%s", rpcPort)
	kratosURL := fmt.Sprintf("http://127.0.0.1:%s", kratosPublicPort)
	mux := http.NewServeMux()
	kratosClient := adapters.NewKratosClient(kratosURL)
	service := auth.NewService(kratosClient, &stubUserRepository{})
	//TODO grantClaimer
	connectRPC := authconnectrpc.NewAuthServer(service, nil)
	connectRPC.BindAuthServerToMux(mux)
	protoc := new(http.Protocols)
	protoc.SetHTTP1(true)
	protoc.SetUnencryptedHTTP2(true)
	server := http.Server{
		Addr:      rpcURL,
		Handler:   mux,
		Protocols: protoc,
	}
	go func() {
		_ = server.ListenAndServe()
	}()
	// Register a cleanup function to close the server on test end
	t.Cleanup(func() {
		err := server.Shutdown(t.Context())
		if err != nil {
			t.Error(err)
			return
		}
	})
	// Artificial wait to let the server come online, reduces flakiness
	time.Sleep(2 * time.Second)
}

// stubUserRepository is a no-op auth.UserRepository for the connect RPC flow tests.
// These tests exercise the real Kratos integration and field mapping; persisting the
// linked user in Postgres is out of scope here, so CreateUser simply succeeds.
type stubUserRepository struct{}

func (stubUserRepository) CreateUser(_ context.Context, _ string) error { return nil }

func newAuthClient(t *testing.T) authv1connect.AuthServiceClient {
	t.Helper()
	return authv1connect.NewAuthServiceClient(
		http.DefaultClient,
		fmt.Sprintf("http://localhost:%s", rpcPort),
	)
}

const letterBytes = "abcdefghijklmnopqrstuvwxyz"
const symbolsBytes = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$%^"

func randStringBytes(n int, s string) string {
	b := make([]byte, n)
	for i := range b {
		b[i] = s[rand.Intn(len(s))]
	}
	return string(b)
}

func generateTestCredentials() (string, string) {
	email := fmt.Sprintf("testemail_%s@example.com", randStringBytes(7, letterBytes))
	password := "testpassword_" + randStringBytes(5, symbolsBytes)
	return email, password
}

func mustContainFieldErrorWithKeyword(t *testing.T, err error, field, keyword string) {
	t.Helper()
	br := connectRPCBadRequestError(t, err)
	fieldErrors := br.GetFieldViolations()
	for _, fieldError := range fieldErrors {
		if fieldError.GetField() == field && strings.Contains(fieldError.GetDescription(), keyword) {
			return
		}
	}
	t.Errorf("keyword %s wasn't found in field %s errors: %s", keyword, field, err)
}

func connectRPCBadRequestError(t *testing.T, err error) *errdetails.BadRequest {
	t.Helper()
	connectErr, ok := errors.AsType[*connect.Error](err)
	if !ok {
		t.Fatalf("Could not type cast connectRPC error: %v", err)
	}
	for _, detail := range connectErr.Details() {
		msg, valueErr := detail.Value()
		if valueErr != nil {
			continue
		}
		if br, ok := msg.(*errdetails.BadRequest); ok {
			return br
		}
	}
	t.Fatalf("Could not type cast connectRPC error details into BadRequest: %v", err)
	return nil
}

type responseWithSession interface {
	GetSession() *authv1.Session
}

func checkResponseSession[T responseWithSession](t *testing.T, msg T, email string) {
	t.Helper()
	session := msg.GetSession()
	if session == nil {
		t.Fatalf("Expected non-nil session and message, got nil")
	}
	if session.GetSessionToken() == "" {
		t.Error("Session token is empty")
	}
	if session.Identity.Email != email {
		t.Errorf("Email does not match")
	}
}
