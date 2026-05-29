package middlewares

import (
	"context"
	"errors"
	"fmt"
	"log/slog"

	"connectrpc.com/connect"

	"github.com/gogotchuri/readintent/backend/proto/auth/v1/authv1connect"
	authmodels "github.com/gogotchuri/readintent/backend/services/auth/models"
)

const tokenHeader = "X-Session-Token"
const sessionKey = "X-Session"

type SessionGetter interface {
	GetSession(ctx context.Context, token string) (*authmodels.Session, error)
}

// SessionInterceptor struct is used to make the interceptor stateful and retain the auth.Service instance
type SessionInterceptor struct {
	sg               SessionGetter
	publicProcedures map[string]bool
}

// SessionFromCtx returns authenticated session object from context or returns nil if the session if unavailable
func SessionFromCtx(ctx context.Context) *authmodels.Session {
	session := ctx.Value(sessionKey)
	sess, ok := session.(*authmodels.Session)
	if !ok {
		slog.Error(fmt.Sprintf("error retrieving session from context, expected type %T but got %T", &authmodels.Session{}, session))
		return nil
	}
	return sess
}

// NewSessionInterceptor Creates a new state for SessionInterceptor with the auth service.
// This interceptor is used to validate the session token and inject the Session model into the context for downstream usage
func NewSessionInterceptor(service SessionGetter) *SessionInterceptor {
	return &SessionInterceptor{
		sg: service,
		publicProcedures: map[string]bool{
			authv1connect.AuthServicePasswordLoginProcedure:        true,
			authv1connect.AuthServicePasswordRegistrationProcedure: true,
			authv1connect.AuthServiceHealthProcedure:               true,
			authv1connect.AuthServiceOIDCLoginProcedure:            true,
		},
	}
}

func (a *SessionInterceptor) NewUnaryInterceptor() connect.UnaryInterceptorFunc {
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

			session, err := a.sg.GetSession(ctx, sessionToken)
			if err != nil {
				return nil, connect.NewError(connect.CodeUnauthenticated, fmt.Errorf("unauthenticated: %w", err))
			}

			ctx = context.WithValue(ctx, sessionKey, session)
			return next(ctx, req)
		}
	}
}
