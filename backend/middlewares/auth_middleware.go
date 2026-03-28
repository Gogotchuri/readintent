package middlewares

import (
	"context"
	"errors"
	"fmt"

	"connectrpc.com/connect"

	"github.com/gogotchuri/readintent/backend/proto/auth/v1/authv1connect"
	"github.com/gogotchuri/readintent/backend/services/auth"
	authmodels "github.com/gogotchuri/readintent/backend/services/auth/models"
)

const tokenHeader = "X-Session-Token"
const sessionKey = "X-Session"

// AuthInterceptor struct is used to make the interceptor stateful and retain the auth.Service instance
type AuthInterceptor struct {
	service          *auth.Service
	publicProcedures map[string]bool
}

// SessionFromCtx returns authenticated session object from context or returns nil if the session if unavailable
func SessionFromCtx(ctx context.Context) *authmodels.Session {
	session := ctx.Value(sessionKey)
	return session.(*authmodels.Session)
}

// NewAuthInterceptor Creates a new state for AuthInterceptor with the auth service.
// This interceptor is used to validate the session token and inject the Session model into the context for downstream usage
func NewAuthInterceptor(service *auth.Service) *AuthInterceptor {
	return &AuthInterceptor{
		service: service,
		publicProcedures: map[string]bool{
			authv1connect.AuthServicePasswordLoginProcedure:        true,
			authv1connect.AuthServicePasswordRegistrationProcedure: true,
			authv1connect.AuthServiceHealthProcedure:               true,
		},
	}
}

func (a *AuthInterceptor) NewUnaryInterceptor() connect.UnaryInterceptorFunc {
	return func(next connect.UnaryFunc) connect.UnaryFunc {
		return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
			// No need to apply the interceptor on a public procedure
			if a.publicProcedures[req.Spec().Procedure] {
				return next(ctx, req)
			}

			sessionToken := req.Header().Get(tokenHeader)
			if sessionToken == "" {
				return nil, connect.NewError(connect.CodeUnauthenticated, errors.New("please provide the X-Session-Token header for authenticated routes"))
			}

			session, err := a.service.GetSession(ctx, sessionToken)
			if err != nil {
				return nil, connect.NewError(connect.CodeUnauthenticated, fmt.Errorf("unauthenticated: %w", err))
			}

			ctx = context.WithValue(ctx, sessionKey, session)
			return next(ctx, req)
		}
	}
}
