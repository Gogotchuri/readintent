package middlewares

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"

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

var _ connect.Interceptor = (*SessionInterceptor)(nil)

// authenticate validates the session token for a procedure and returns a
// context carrying the resolved session. Public procedures are passed through
// unchanged.
func (a *SessionInterceptor) authenticate(ctx context.Context, procedure string, header http.Header) (context.Context, error) {
	// No need to apply the interceptor on a public procedure
	if a.publicProcedures[procedure] {
		return ctx, nil
	}

	sessionToken := header.Get(tokenHeader)
	if sessionToken == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, errors.New("please provide the X-Session-Token header for authenticated routes"))
	}

	session, err := a.sg.GetSession(ctx, sessionToken)
	if err != nil {
		return nil, connect.NewError(connect.CodeUnauthenticated, fmt.Errorf("unauthenticated: %w", err))
	}

	return context.WithValue(ctx, sessionKey, session), nil
}

// WrapUnary authenticates unary RPCs.
func (a *SessionInterceptor) WrapUnary(next connect.UnaryFunc) connect.UnaryFunc {
	return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
		ctx, err := a.authenticate(ctx, req.Spec().Procedure, req.Header())
		if err != nil {
			return nil, err
		}
		return next(ctx, req)
	}
}

// WrapStreamingHandler authenticates streaming RPCs
func (a *SessionInterceptor) WrapStreamingHandler(next connect.StreamingHandlerFunc) connect.StreamingHandlerFunc {
	return func(ctx context.Context, conn connect.StreamingHandlerConn) error {
		ctx, err := a.authenticate(ctx, conn.Spec().Procedure, conn.RequestHeader())
		if err != nil {
			return err
		}
		return next(ctx, conn)
	}
}

// WrapStreamingClient is a pass-through; this interceptor is server-side only.
func (a *SessionInterceptor) WrapStreamingClient(next connect.StreamingClientFunc) connect.StreamingClientFunc {
	return next
}
