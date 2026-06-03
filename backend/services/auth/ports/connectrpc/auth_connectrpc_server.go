package authconnectrpc

import (
	"context"
	"errors"
	"fmt"
	"net/http"

	"connectrpc.com/connect"
	"connectrpc.com/validate"
	"github.com/gogotchuri/readintent/backend/middlewares"
	authv1 "github.com/gogotchuri/readintent/backend/proto/auth/v1"
	"github.com/gogotchuri/readintent/backend/proto/auth/v1/authv1connect"
	"github.com/gogotchuri/readintent/backend/services/auth"
	authmodels "github.com/gogotchuri/readintent/backend/services/auth/models"
)

var _ authv1connect.AuthServiceHandler = &AuthServer{}

type AuthGrantClaimer interface {
	ClaimGrantCode(ctx context.Context, userCode, userID string) error
}

type AuthServer struct {
	service             *auth.Service
	grantClaimerService AuthGrantClaimer
}

func NewAuthServer(service *auth.Service, grantClaimer AuthGrantClaimer) *AuthServer {
	return &AuthServer{
		service:             service,
		grantClaimerService: grantClaimer,
	}
}

func (a *AuthServer) BindAuthServerToMux(mux *http.ServeMux) {
	interceptors := connect.WithInterceptors(
		middlewares.NewSessionInterceptor(a.service),
		validate.NewInterceptor(),
	)
	path, handler := authv1connect.NewAuthServiceHandler(a, interceptors)
	mux.Handle(path, handler)
}

// ClaimGrantCode allows an authenticated user to claim a grant code for extension pairing.
func (a *AuthServer) ClaimGrantCode(ctx context.Context, req *connect.Request[authv1.ClaimGrantCodeRequest]) (*connect.Response[authv1.ClaimGrantCodeResponse], error) {
	session := middlewares.SessionFromCtx(ctx)
	if session == nil {
		return nil, newConnectError(connect.CodeUnauthenticated, errors.New("no valid session"))
	}

	if a.grantClaimerService == nil {
		return nil, newConnectError(connect.CodeUnimplemented, errors.New("grant code claiming is not available"))
	}

	if err := a.grantClaimerService.ClaimGrantCode(ctx, req.Msg.GetUserCode(), session.Identity.ID); err != nil {
		return nil, newConnectError(connect.CodeInternal, fmt.Errorf("claiming grant code: %w", err))
	}

	return connect.NewResponse(&authv1.ClaimGrantCodeResponse{}), nil
}

// Health Returns health of the auth service
func (a *AuthServer) Health(ctx context.Context, _ *connect.Request[authv1.HealthRequest]) (*connect.Response[authv1.HealthResponse], error) {
	err := a.service.Health(ctx)
	if err != nil {
		return nil, newConnectError(connect.CodeInternal, fmt.Errorf("auth service health check failed: %w", err))
	}
	return &connect.Response[authv1.HealthResponse]{}, nil
}

// GetSession implements authv1connect.AuthServiceHandler.
func (a *AuthServer) GetSession(ctx context.Context, _ *connect.Request[authv1.GetSessionRequest]) (*connect.Response[authv1.GetSessionResponse], error) {
	session := middlewares.SessionFromCtx(ctx)
	if session == nil {
		return nil, newConnectError(connect.CodeUnauthenticated, errors.New("no valid session"))
	}
	return connect.NewResponse(&authv1.GetSessionResponse{
		Session: rpcSessionFromSession(session),
	}), nil
}

// Logout implements authv1connect.AuthServiceHandler.
func (a *AuthServer) Logout(ctx context.Context, req *connect.Request[authv1.LogoutRequest]) (*connect.Response[authv1.LogoutResponse], error) {
	session := middlewares.SessionFromCtx(ctx)
	if session == nil {
		return nil, newConnectError(connect.CodeUnauthenticated, errors.New("no valid session"))
	}

	err := a.service.Logout(ctx, session.SessionToken)
	if err != nil {
		return nil, newConnectError(connect.CodeInternal, err)
	}

	return connect.NewResponse(&authv1.LogoutResponse{}), nil
}

// OIDCLogin implements authv1connect.AuthServiceHandler.
func (a *AuthServer) OIDCLogin(ctx context.Context, req *connect.Request[authv1.OIDCLoginRequest]) (*connect.Response[authv1.OIDCLoginResponse], error) {
	loginRes, err := a.service.OIDCLogin(ctx, authmodels.OIDCLoginRequest{
		Provider: req.Msg.Provider,
		IDToken:  req.Msg.IdToken,
	})
	if err != nil {
		return nil, newConnectError(connect.CodeUnauthenticated, err)
	}
	return connect.NewResponse(&authv1.OIDCLoginResponse{
		Session: rpcSessionFromSession(&loginRes.Session),
	}), nil
}

// PasswordLogin implements authv1connect.AuthServiceHandler.
func (a *AuthServer) PasswordLogin(ctx context.Context, req *connect.Request[authv1.PasswordLoginRequest]) (*connect.Response[authv1.PasswordLoginResponse], error) {
	loginRes, err := a.service.PasswordLogin(ctx, authmodels.PasswordLoginRequest{
		Email:    req.Msg.Email,
		Password: req.Msg.Password,
	})
	if err != nil {
		return nil, newConnectError(connect.CodeUnauthenticated, err)
	}

	return connect.NewResponse(&authv1.PasswordLoginResponse{
		Session: rpcSessionFromSession(&loginRes.Session),
	}), nil
}

// PasswordRegistration implements authv1connect.AuthServiceHandler.
func (a *AuthServer) PasswordRegistration(ctx context.Context, req *connect.Request[authv1.PasswordRegistrationRequest]) (*connect.Response[authv1.PasswordRegistrationResponse], error) {
	res, err := a.service.PasswordRegistration(ctx, authmodels.PasswordRegistrationRequest{
		Email:     req.Msg.Email,
		Password:  req.Msg.Password,
		FirstName: req.Msg.GetFirstName(),
		LastName:  req.Msg.GetLastName(),
	})
	if err != nil {
		return nil, newConnectError(connect.CodeInvalidArgument, err)
	}
	return connect.NewResponse(&authv1.PasswordRegistrationResponse{
		Session: rpcSessionFromSession(&res.Session),
	}), nil
}

func rpcSessionFromSession(session *authmodels.Session) *authv1.Session {
	var expiredAt int64
	if session.ExpiresAt != nil {
		expiredAt = session.ExpiresAt.Unix()
	}
	var firstName, lastName *string
	if session.Identity.FirstName != "" {
		firstName = &session.Identity.FirstName
	}
	if session.Identity.LastName != "" {
		lastName = &session.Identity.LastName
	}

	return &authv1.Session{
		SessionToken:  session.SessionToken,
		ExpiredAtUnix: expiredAt,
		Identity: &authv1.Identity{
			Id:        session.Identity.ID,
			Email:     session.Identity.Email,
			FirstName: firstName,
			LastName:  lastName,
		},
	}
}
