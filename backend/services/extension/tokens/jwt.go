package tokens

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
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

// NewIssuer Create JWT token issuer with the key, key ID, issuer, audience and ttl (time to live) for the tokens
// In case the key is passed as nil, this re-generated the key, only recommended in dev environment
func NewIssuer(key *ecdsa.PrivateKey, keyID, issuer, audience string, ttl time.Duration) *Issuer {
	if key == nil {
		genKey, err := loadOrGenerateKey()
		if err != nil {
			panic(err)
		}
		key = genKey
	}
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
	_, err := jwt.ParseWithClaims(raw, &claims, func(t *jwt.Token) (any, error) {
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
func loadOrGenerateKey() (*ecdsa.PrivateKey, error) {
	// TODO take in the config and laod the PEM key from file
	// dev fallback
	return ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
}
