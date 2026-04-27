package models

type GrantCodes struct {
	DeviceCode string `json:"device_code"`
	UserCode   string `json:"user_code"`
	ExpiresIn  int64  `json:"expires_in"`
	ExpiresAt  int64  `json:"expires_at"`
	Interval   int64  `json:"interval"`
	ClaimedBy  string `json:"claimed_by,omitempty"`
}

type PairingStatus string

const (
	StatusPaired  PairingStatus = "paired"
	StatusPending PairingStatus = "pending"
	StatusExpired PairingStatus = "expired"
)

type PairingState struct {
	Status       PairingStatus `json:"status"`
	SessionToken string        `json:"session_token,omitempty"`
}
