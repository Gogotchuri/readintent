package tokens

import (
	"crypto/ecdsa"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type Issuer struct {
	key *ecdsa.PrivateKey
	// Used for key rotation
	keyID    string
	issuer   string
	audience string
	ttl      time.Duration
}

func NewIssuer(key *ecdsa.PrivateKey, keyID, issuer, audience string, ttl time.Duration) *Issuer {
	return &Issuer{
		key:      key,
		keyID:    keyID,
		issuer:   issuer,
		audience: audience,
		ttl:      ttl,
	}
}

func (i *Issuer) Generate(identityID string) (string, error) {
	now := time.Now()
	claims := jwt.RegisteredClaims{
		Issuer:    i.issuer,
		Subject:   identityID,
		Audience:  jwt.ClaimStrings{i.audience},
		IssuedAt:  jwt.NewNumericDate(now),
		ExpiresAt: jwt.NewNumericDate(now.Add(i.ttl)),
	}
	tok := jwt.NewWithClaims(jwt.SigningMethodES256, claims)
	tok.Header["kid"] = i.keyID
	return tok.SignedString(i.key)
}

func (i *Issuer) Parse(raw string) (*jwt.RegisteredClaims, error) {
	var claims jwt.RegisteredClaims
	_, err := jwt.ParseWithClaims(raw, &claims, func(t *jwt.Token) (interface{}, error) {
		return &i.key.PublicKey, nil
	},
		jwt.WithValidMethods([]string{jwt.SigningMethodES256.Alg()}),
		jwt.WithIssuer(i.issuer),
		jwt.WithAudience(i.audience),
		jwt.WithExpirationRequired(),
	)
	if err != nil {
		return nil, err
	}
	return &claims, nil
}
