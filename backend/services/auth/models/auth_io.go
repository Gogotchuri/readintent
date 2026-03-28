package authmodels

type PasswordLoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type PasswordRegistrationRequest struct {
	Email     string `json:"email"`
	Password  string `json:"password"`
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
}
type PasswordRegistrationResponse struct {
	Session          Session           `json:"session"`
	VerificationFlow *VerificationFlow `json:"verification_flow"`
}

type LoginResponse struct {
	Session Session `json:"session"`
}

type SessionResponse struct {
	Session Session `json:"session"`
}

type VerificationFlow struct {
	// The ID of the verification flow
	FlowId string `json:"flow_id"`
	// The address that should be verified in this flow
	VerifiableAddress string `json:"verifiable_address"`
}
