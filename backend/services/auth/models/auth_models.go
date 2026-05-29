package authmodels

import "time"

const MethodPassword = "password"
const MethodOIDC = "oidc"

type Identity struct {
	ID        string `json:"id"`
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Email     string `json:"email"`
}

type Session struct {
	Identity     Identity   `json:"identity"`
	ExpiresAt    *time.Time `json:"expires_at"`
	SessionToken string     `json:"session_token"`
	//TODO: Use Verifiable addresses from Kratos Identity
	VerifiedAt *time.Time `json:"verified_at"`
}
