package adapters

import (
	"context"
	"fmt"

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
	isReadyReq := kc.client.MetadataAPI.IsReady(ctx)
	// No need to check the retuned status, this always returns either error or status "ok"
	_, _, err := kc.client.MetadataAPI.IsReadyExecute(isReadyReq)
	if err != nil {
		return err
	}
	return nil
}

// PasswordRegistration registers a new user - registration flow with email/password.
func (kc *KratosClient) PasswordRegistration(ctx context.Context, r authmodels.PasswordRegistrationRequest) (*authmodels.PasswordRegistrationResponse, error) {
	flow, _, err := kc.client.FrontendAPI.CreateNativeRegistrationFlow(ctx).Execute()
	if err != nil {
		return nil, fmt.Errorf("create registration flow: %w", err)
	}

	registration, _, err := kc.client.FrontendAPI.UpdateRegistrationFlow(ctx).
		Flow(flow.Id).
		UpdateRegistrationFlowBody(getRegisterFlowBody(r)).
		Execute()
	if err != nil {
		return nil, authmodels.ParseAuthUIErrorsFromKratos(err)
	}
	if registration.SessionToken == nil {
		return nil, fmt.Errorf("registration response missing session token")
	}
	var VerificationFlow *authmodels.VerificationFlow
	if registration.ContinueWith != nil {
		for _, cw := range registration.ContinueWith {
			if cw.ContinueWithVerificationUi != nil {
				VerificationFlow = &authmodels.VerificationFlow{
					FlowId:            cw.ContinueWithVerificationUi.Flow.GetId(),
					VerifiableAddress: cw.ContinueWithVerificationUi.Flow.GetVerifiableAddress(),
				}
			}
		}
	}
	return &authmodels.PasswordRegistrationResponse{
		Session:          *sessionFromKratosSession(registration.Session, *registration.SessionToken),
		VerificationFlow: VerificationFlow,
	}, nil
}

// PasswordLogin authenticates a user via the self-service login flow with email/password.
func (kc *KratosClient) PasswordLogin(ctx context.Context, r authmodels.PasswordLoginRequest) (*authmodels.LoginResponse, error) {
	flow, _, err := kc.client.FrontendAPI.CreateNativeLoginFlow(ctx).Execute()
	if err != nil {
		return nil, fmt.Errorf("create login flow: %w", err)
	}

	login, _, err := kc.client.FrontendAPI.UpdateLoginFlow(ctx).
		Flow(flow.Id).
		UpdateLoginFlowBody(getLoginFlowBody(r)).
		Execute()
	if err != nil {
		return nil, authmodels.ParseAuthUIErrorsFromKratos(err)
	}
	if login.SessionToken == nil {
		return nil, fmt.Errorf("login response missing session token")
	}
	return &authmodels.LoginResponse{
		Session: *sessionFromKratosSession(&login.Session, *login.SessionToken),
	}, nil
}

// GetSession retrieves the current session using a session token.
func (kc *KratosClient) GetSession(ctx context.Context, sessionToken string) (*authmodels.Session, error) {
	session, _, err := kc.client.FrontendAPI.ToSession(ctx).
		XSessionToken(sessionToken).
		Execute()
	if err != nil {
		return nil, authmodels.ParseAuthUIErrorsFromKratos(err)
	}
	if session.Active == nil || !*session.Active {
		return nil, &authmodels.SessionInactiveError{
			Message: "Session is inactive or expired",
		}
	}
	return sessionFromKratosSession(session, sessionToken), nil
}

// Logout invalidates the session associated with the given session token.
func (kc *KratosClient) Logout(ctx context.Context, sessionToken string) error {
	resp, err := kc.client.FrontendAPI.PerformNativeLogout(ctx).
		PerformNativeLogoutBody(*kratos.NewPerformNativeLogoutBody(sessionToken)).
		Execute()
	if err != nil {
		return authmodels.ParseAuthUIErrorsFromKratos(err)
	}
	if resp.StatusCode != 204 {
		return fmt.Errorf("logout: unexpected status code %d", resp.StatusCode)
	}
	return nil
}

// TODO EmailVerification
// TODO ExtendSession - We can either have a separate endpoint for this or Extend every time the call is made. Having it on app startup makes a lot of sense too

// ----- HELPERS -----

func getLoginFlowBody(r authmodels.PasswordLoginRequest) kratos.UpdateLoginFlowBody {
	return kratos.UpdateLoginFlowWithPasswordMethodAsUpdateLoginFlowBody(kratos.NewUpdateLoginFlowWithPasswordMethod(r.Email, "password", r.Password))
}
func getRegisterFlowBody(r authmodels.PasswordRegistrationRequest) kratos.UpdateRegistrationFlowBody {
	return kratos.UpdateRegistrationFlowWithPasswordMethodAsUpdateRegistrationFlowBody(
		kratos.NewUpdateRegistrationFlowWithPasswordMethod(
			authmodels.MethodPassword,
			r.Password,
			map[string]interface{}{
				"email": r.Email,
				"name": map[string]interface{}{
					"first": r.FirstName,
					"last":  r.LastName,
				},
			},
		),
	)
}

func sessionFromKratosSession(kratosSession *kratos.Session, sessionToken string) *authmodels.Session {
	return &authmodels.Session{
		Identity:     identityFromKratosIdentity(kratosSession.Identity),
		ExpiresAt:    kratosSession.ExpiresAt,
		SessionToken: sessionToken,
	}
}

func identityFromKratosIdentity(kratosIdentity *kratos.Identity) authmodels.Identity {
	traits, ok := kratosIdentity.Traits.(map[string]interface{})
	if !ok {
		return authmodels.Identity{
			ID: kratosIdentity.Id,
		}
	}
	email, _ := traits["email"].(string)
	firstName, _ := traits["name"].(map[string]interface{})["first"].(string)
	lastName, _ := traits["name"].(map[string]interface{})["last"].(string)

	return authmodels.Identity{
		ID:        kratosIdentity.Id,
		Email:     email,
		FirstName: firstName,
		LastName:  lastName,
	}
}
