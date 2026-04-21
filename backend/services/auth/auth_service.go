package auth

import (
	"context"
	"fmt"

	authmodels "github.com/gogotchuri/readintent/backend/services/auth/models"
)

// Service is an authentication service, exposing methods for authentication
// It is currently just wrapping authClient but will evolve as the product progresses and different authentication modes are introduced
// Or if we want to change the underlying authClient only the new implementation would be required, even a custom one
type Service struct {
	authClient authClient
	userRepo   UserRepository
}

func NewService(authClient authClient, userRepo UserRepository) *Service {
	return &Service{
		authClient: authClient,
		userRepo:   userRepo,
	}
}

func (s *Service) Health(ctx context.Context) error {
	err := s.authClient.Health(ctx)
	if err != nil {
		return fmt.Errorf("authentication client health check failed: %w", err)
	}
	return nil
}

func (s *Service) PasswordRegistration(ctx context.Context, r authmodels.PasswordRegistrationRequest) (*authmodels.PasswordRegistrationResponse, error) {
	resp, err := s.authClient.PasswordRegistration(ctx, r)
	if err != nil {
		return nil, err
	}
	// Create the user in the database as well, so that we can link it to articles and other data down the line
	if err := s.userRepo.CreateUser(ctx, resp.Session.Identity.ID); err != nil {
		return nil, fmt.Errorf("creating user in database: %w", err)
	}
	return resp, nil
}

func (s *Service) PasswordLogin(ctx context.Context, r authmodels.PasswordLoginRequest) (*authmodels.LoginResponse, error) {
	return s.authClient.PasswordLogin(ctx, r)
}

func (s *Service) GetSession(ctx context.Context, sessionToken string) (*authmodels.Session, error) {
	return s.authClient.GetSession(ctx, sessionToken)
}

func (s *Service) Logout(ctx context.Context, sessionToken string) error {
	return s.authClient.Logout(ctx, sessionToken)
}
