package authconnectrpc

import (
	"context"
	"net/http"

	"connectrpc.com/connect"
	"connectrpc.com/validate"
	authv1 "github.com/gogotchuri/readintent/backend/proto/auth/v1"
	"github.com/gogotchuri/readintent/backend/proto/auth/v1/authv1connect"
	"github.com/gogotchuri/readintent/backend/services/auth"
)

var _ authv1connect.AuthServiceHandler = &AuthServer{}

type AuthServer struct {
	service *auth.Service
}

func NewAuthServer(service *auth.Service) *AuthServer {
	return &AuthServer{
		service: service,
	}
}

func (a *AuthServer) BindAuthServerToMux(mux *http.ServeMux) {
	interceptors := connect.WithInterceptors(
		validate.NewInterceptor(),
	)
	path, handler := authv1connect.NewAuthServiceHandler(a, interceptors)
	mux.Handle(path, handler)
}

// Health Returns health of the auth service
func (a *AuthServer) Health(ctx context.Context, _ *connect.Request[authv1.HealthRequest]) (*connect.Response[authv1.HealthResponse], error) {
	//TODO implement me
	panic("implement me")
}

// GetSession implements authv1connect.AuthServiceHandler.
func (a *AuthServer) GetSession(ctx context.Context, _ *connect.Request[authv1.GetSessionRequest]) (*connect.Response[authv1.GetSessionResponse], error) {
	//TODO implement me
	panic("implement me")
}

// Logout implements authv1connect.AuthServiceHandler.
func (a *AuthServer) Logout(ctx context.Context, req *connect.Request[authv1.LogoutRequest]) (*connect.Response[authv1.LogoutResponse], error) {
	//TODO implement me
	panic("implement me")
}

// PasswordLogin implements authv1connect.AuthServiceHandler.
func (a *AuthServer) PasswordLogin(ctx context.Context, req *connect.Request[authv1.PasswordLoginRequest]) (*connect.Response[authv1.PasswordLoginResponse], error) {
	//TODO implement me
	panic("implement me")
}

// PasswordRegistration implements authv1connect.AuthServiceHandler.
func (a *AuthServer) PasswordRegistration(ctx context.Context, req *connect.Request[authv1.PasswordRegistrationRequest]) (*connect.Response[authv1.PasswordRegistrationResponse], error) {
	//TODO implement me
	panic("implement me")
}
