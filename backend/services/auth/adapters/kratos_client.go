package adapters

import (
	"context"

	authmodels "github.com/gogotchuri/readintent/backend/services/auth/models"
	kratos "github.com/ory/kratos-client-go/v25"
)

type KratosClient struct {
	client *kratos.APIClient
}

func NewKratosClient(baseURL string) *KratosClient {
	cfg := kratos.NewConfiguration()
	cfg.Servers = kratos.ServerConfigurations{
		{
			// We currently support a single Kratos API server instance
			URL:         baseURL,
			Description: "Kratos API Server",
		},
	}
	client := kratos.NewAPIClient(cfg)
	return &KratosClient{
		client: client,
	}
}

// Health checks the health of the Kratos instance.
// If the instance is up and running return nil, otherwise an appropriate error
func (kc *KratosClient) Health(ctx context.Context) error {
	//TODO implement me
	panic("implement me")
}

// PasswordRegistration registers a new user - registration flow with email/password.
func (kc *KratosClient) PasswordRegistration(ctx context.Context, r authmodels.PasswordRegistrationRequest) (*authmodels.PasswordRegistrationResponse, error) {
	//TODO implement me
	panic("implement me")
}

// PasswordLogin authenticates a user via the self-service login flow with email/password.
func (kc *KratosClient) PasswordLogin(ctx context.Context, r authmodels.PasswordLoginRequest) (*authmodels.LoginResponse, error) {
	//TODO implement me
	panic("implement me")
}

// GetSession retrieves the current session using a session token.
func (kc *KratosClient) GetSession(ctx context.Context, sessionToken string) (*authmodels.Session, error) {
	//TODO implement me
	panic("implement me")

}

// Logout invalidates the session associated with the given session token.
func (kc *KratosClient) Logout(ctx context.Context, sessionToken string) error {
	//TODO implement me
	panic("implement me")

}

// TODO EmailVerification
// TODO ExtendSession - We can either have a separate endpoint for this or Extend every time the call is made. Having it on app startup makes a lot of sense too
