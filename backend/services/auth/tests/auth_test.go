package tests

import (
	"strings"
	"testing"

	"connectrpc.com/connect"
	authv1 "github.com/gogotchuri/readintent/backend/proto/auth/v1"
	"github.com/gogotchuri/readintent/backend/proto/auth/v1/authv1connect"
)

func TestKratosHealth(t *testing.T) {
	_, err := startComposeStackForKratos(t)
	if err != nil {
		t.Fatal(err)
	}

	startConnectRPCAuthServer(t)
	client := newAuthClient(t)
	_, err = client.Health(t.Context(), connect.NewRequest(&authv1.HealthRequest{}))
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("Kratos health check passed successfully")
}

func TestAuthenticationFlows(t *testing.T) {
	_, err := startComposeStackForKratos(t)
	if err != nil {
		t.Fatal(err)
	}
	startConnectRPCAuthServer(t)
	client := newAuthClient(t)

	t.Run("Password Registration", func(t *testing.T) {
		t.Run("Basic Registration", func(t *testing.T) {
			email, password := generateTestCredentials()
			r, err := client.PasswordRegistration(t.Context(), connect.NewRequest(&authv1.PasswordRegistrationRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatal(err)
			}
			checkResponseSession(t, r.Msg, email)
		})
		// Kratos doesn't support customizable password policies and applied general guidelines provided by MIT to every password
		// Kratos also support leaked data password detection and warns against it
		t.Run("Registration with weak password", func(t *testing.T) {
			email, password := generateTestCredentials()
			password = "123"
			_, err := client.PasswordRegistration(t.Context(), connect.NewRequest(&authv1.PasswordRegistrationRequest{
				Email:    email,
				Password: password,
			}))
			if err == nil {
				t.Fatalf("Expected error for weak password, got nil")
			}
			mustContainFieldErrorWithKeyword(t, err, "password", "password must be")
			password = "password123" // This password must appear in the leaked database
			_, err = client.PasswordRegistration(t.Context(), connect.NewRequest(&authv1.PasswordRegistrationRequest{
				Email:    email,
				Password: password,
			}))
			if err == nil {
				t.Fatalf("Expected error for leaked password, got nil")
			}
			mustContainFieldErrorWithKeyword(t, err, "password", "found in data breaches")
		})
		t.Run("Registration with invalid email", func(t *testing.T) {
			email, password := generateTestCredentials()
			email = "abcdef"
			_, err := client.PasswordRegistration(t.Context(), connect.NewRequest(&authv1.PasswordRegistrationRequest{
				Email:    email,
				Password: password,
			}))
			if err == nil {
				t.Fatalf("Expected error for invalid email, got nil")
			}
			mustContainFieldErrorWithKeyword(t, err, "traits.email", "valid")
		})
		// Registration attempt with the same credentials twice must fail and return a general error
		t.Run("Registration with already used email", func(t *testing.T) {
			email, password := generateTestCredentials()
			_, err := client.PasswordRegistration(t.Context(), connect.NewRequest(&authv1.PasswordRegistrationRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatal(err)
			}
			_, err = client.PasswordRegistration(t.Context(), connect.NewRequest(&authv1.PasswordRegistrationRequest{
				Email:    email,
				Password: password,
			}))
			if err == nil {
				t.Fatalf("Expected error for using the same email, got nil")
			}
			mustContainFieldErrorWithKeyword(t, err, "general", "exists already")
		})
	})
	t.Run("Password Login", func(t *testing.T) {
		t.Run("Basic Login", func(t *testing.T) {
			email, password := generateTestCredentials()
			// First, register the user; since we have tested the registration in the tests above, this should still be a fairly isolated login test
			_, err := client.PasswordRegistration(t.Context(), connect.NewRequest(&authv1.PasswordRegistrationRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatalf("Expected no error during registration, got %v", err)
			}
			r, err := client.PasswordLogin(t.Context(), connect.NewRequest(&authv1.PasswordLoginRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatal(err)
			}
			checkResponseSession(t, r.Msg, email)
		})
		t.Run("Login with wrong password", func(t *testing.T) {
			email, password := generateTestCredentials()
			_, err = client.PasswordRegistration(t.Context(), connect.NewRequest(&authv1.PasswordRegistrationRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatalf("Expected no error during registration, got %v", err)
			}
			_, err = client.PasswordLogin(t.Context(), connect.NewRequest(&authv1.PasswordLoginRequest{
				Email:    email,
				Password: "wrong",
			}))
			if err == nil {
				t.Fatalf("Expected error for invalid email, got nil")
			}
			// This will return general error not a password-specific one. We should not let the login endpoint be used for indexing attacks.
			mustContainFieldErrorWithKeyword(t, err, "general", "credentials are invalid")
		})
		t.Run("Login with wrong email", func(t *testing.T) {
			email, password := generateTestCredentials()

			_, err := client.PasswordLogin(t.Context(), connect.NewRequest(&authv1.PasswordLoginRequest{
				Email:    email,
				Password: password,
			}))
			if err == nil {
				t.Fatalf("Expected error for invalid email, got nil")
			}
			mustContainFieldErrorWithKeyword(t, err, "general", "credentials are invalid")
		})
		t.Run("Login with invalid email", func(t *testing.T) {
			email, password := generateTestCredentials()

			_, err := client.PasswordLogin(t.Context(), connect.NewRequest(&authv1.PasswordLoginRequest{
				Email:    email + "@@",
				Password: password,
			}))
			if err == nil {
				t.Fatalf("Expected error for invalid email, got nil")
			}
			mustContainFieldErrorWithKeyword(t, err, "general", "credentials are invalid")
		})
		t.Run("Login email case insensitive", func(t *testing.T) {
			email, password := generateTestCredentials()
			_, err := client.PasswordRegistration(t.Context(), connect.NewRequest(&authv1.PasswordRegistrationRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatalf("Expected no error during registration, got %v", err)
			}
			// Basic login case should work
			_, err = client.PasswordLogin(t.Context(), connect.NewRequest(&authv1.PasswordLoginRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatalf("Expected no error during basic login, got %v", err)
			}
			_, err = client.PasswordLogin(t.Context(), connect.NewRequest(&authv1.PasswordLoginRequest{
				Email:    strings.ToUpper(email),
				Password: password,
			}))
			if err != nil {
				t.Fatalf("Expected email addresses to be case insensitive for login, got %v", err)
			}
		})
	})
	t.Run("Get Session", func(t *testing.T) {
		t.Run("with token from registration", func(t *testing.T) {
			email, password := generateTestCredentials()
			r, err := client.PasswordRegistration(t.Context(), connect.NewRequest(&authv1.PasswordRegistrationRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatalf("Expected no error during registration, got %v", err)
			}
			getSessionWithTokenFromResponse(t, client, r.Msg, email, true)
		})

		t.Run("with token from login", func(t *testing.T) {
			email, password := generateTestCredentials()
			_, err := client.PasswordRegistration(t.Context(), connect.NewRequest(&authv1.PasswordRegistrationRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatalf("Expected no error during registration, got %v", err)
			}
			r, err := client.PasswordLogin(t.Context(), connect.NewRequest(&authv1.PasswordLoginRequest{
				Email:    email,
				Password: password,
			}))
			getSessionWithTokenFromResponse(t, client, r.Msg, email, true)
		})
		t.Run("with invalid token", func(t *testing.T) {
			ctx, callInfo := connect.NewClientContext(t.Context())
			callInfo.RequestHeader().Set("X-Session-Token", "invalid-session-token")
			_, err := client.GetSession(ctx, connect.NewRequest(&authv1.GetSessionRequest{}))
			if err == nil {
				t.Fatalf("Expected error during GetSession with invalid token, got nil")
			}
		})
		t.Run("without token", func(t *testing.T) {
			_, err := client.GetSession(t.Context(), connect.NewRequest(&authv1.GetSessionRequest{}))
			if err == nil {
				t.Fatalf("Expected error during GetSession without token, got nil")
			}
		})
		t.Run("login - logout - get session", func(t *testing.T) {
			email, password := generateTestCredentials()
			_, err := client.PasswordRegistration(t.Context(), connect.NewRequest(&authv1.PasswordRegistrationRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatalf("Expected no error during registration, got %v", err)
			}
			r, err := client.PasswordLogin(t.Context(), connect.NewRequest(&authv1.PasswordLoginRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatalf("Expected no error during login, got %v", err)
			}
			getSessionWithTokenFromResponse(t, client, r.Msg, email, true)
			logoutWithTokenFromResponse(t, client, r.Msg, true)
			getSessionWithTokenFromResponse(t, client, r.Msg, email, false)
		})

		t.Run("multiple sessions", func(t *testing.T) {
			email, password := generateTestCredentials()
			regResp, err := client.PasswordRegistration(t.Context(), connect.NewRequest(&authv1.PasswordRegistrationRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatalf("Expected no error during registration, got %v", err)
			}
			loginResp, err := client.PasswordLogin(t.Context(), connect.NewRequest(&authv1.PasswordLoginRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatalf("Expected no error during login, got %v", err)
			}
			getSessionWithTokenFromResponse(t, client, regResp.Msg, email, true)
			getSessionWithTokenFromResponse(t, client, loginResp.Msg, email, true)
		})
	})
	t.Run("Logout", func(t *testing.T) {
		t.Run("with token from registration", func(t *testing.T) {
			email, password := generateTestCredentials()
			regResp, err := client.PasswordRegistration(t.Context(), connect.NewRequest(&authv1.PasswordRegistrationRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatalf("Expected no error during registration, got %v", err)
			}
			logoutWithTokenFromResponse(t, client, regResp.Msg, true)
		})
		t.Run("with token from login", func(t *testing.T) {
			email, password := generateTestCredentials()
			_, err := client.PasswordRegistration(t.Context(), connect.NewRequest(&authv1.PasswordRegistrationRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatalf("Expected no error during registration, got %v", err)
			}
			loginResp, err := client.PasswordLogin(t.Context(), connect.NewRequest(&authv1.PasswordLoginRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatalf("Expected no error during login, got %v", err)
			}
			logoutWithTokenFromResponse(t, client, loginResp.Msg, true)
			// We have logged out, the session should not return with success
			getSessionWithTokenFromResponse(t, client, loginResp.Msg, email, false)
		})
		t.Run("multiple sessions", func(t *testing.T) {
			email, password := generateTestCredentials()
			regResp, err := client.PasswordRegistration(t.Context(), connect.NewRequest(&authv1.PasswordRegistrationRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatalf("Expected no error during registration, got %v", err)
			}
			loginResp, err := client.PasswordLogin(t.Context(), connect.NewRequest(&authv1.PasswordLoginRequest{
				Email:    email,
				Password: password,
			}))
			if err != nil {
				t.Fatalf("Expected no error during login, got %v", err)
			}
			// We have two tokens, one from registration, another one from login, two different sessions
			getSessionWithTokenFromResponse(t, client, regResp.Msg, email, true)
			getSessionWithTokenFromResponse(t, client, loginResp.Msg, email, true)

			// Logout from one should only invalidate that session, not another one
			logoutWithTokenFromResponse(t, client, loginResp.Msg, true)
			getSessionWithTokenFromResponse(t, client, loginResp.Msg, email, false)
			getSessionWithTokenFromResponse(t, client, regResp.Msg, email, true)

			// Logout from the second session should still work
			logoutWithTokenFromResponse(t, client, regResp.Msg, true)
			getSessionWithTokenFromResponse(t, client, loginResp.Msg, email, false)
		})
	})
}

// Local helpers
func getSessionWithTokenFromResponse[T responseWithSession](t *testing.T, client authv1connect.AuthServiceClient, msg T, email string, expectSuccess bool) {
	sessionToken := msg.GetSession().GetSessionToken()
	ctx, callInfo := connect.NewClientContext(t.Context())
	callInfo.RequestHeader().Set("X-Session-Token", sessionToken)
	getSessionRes, err := client.GetSession(ctx, connect.NewRequest(&authv1.GetSessionRequest{}))
	if !expectSuccess {
		if err == nil {
			t.Fatalf("Expected error during GetSession with invalid token, got nil")
		}
		return
	}
	if err != nil {
		t.Fatalf("Expected no error during GetSession, got %v", err)
	}
	checkResponseSession(t, getSessionRes.Msg, email)
}

func logoutWithTokenFromResponse[T responseWithSession](t *testing.T, client authv1connect.AuthServiceClient, msg T, expectSuccess bool) {
	sessionToken := msg.GetSession().GetSessionToken()
	ctx, callInfo := connect.NewClientContext(t.Context())
	callInfo.RequestHeader().Set("X-Session-Token", sessionToken)
	_, err := client.Logout(ctx, connect.NewRequest(&authv1.LogoutRequest{}))
	if !expectSuccess {
		if err == nil {
			t.Fatalf("Expected error during Logout, got nil")
		}
	}
	if err != nil {
		t.Fatalf("Expected no error during Logout, got %v", err)
	}
}
