package auth

import (
	"context"

	authmodels "github.com/gogotchuri/readintent/backend/services/auth/models"
)

type authClient interface {
	PasswordRegistration(ctx context.Context, r authmodels.PasswordRegistrationRequest) (*authmodels.PasswordRegistrationResponse, error)
	PasswordLogin(ctx context.Context, r authmodels.PasswordLoginRequest) (*authmodels.LoginResponse, error)
	GetSession(ctx context.Context, sessionToken string) (*authmodels.Session, error)
	Logout(ctx context.Context, sessionToken string) error
	Health(ctx context.Context) error
}
