package extension

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"math/big"
	"strings"
	"time"

	"github.com/gogotchuri/readintent/backend/services/extension/models"
)

const (
	UserCodeLength   = 6
	DeviceCodeLength = 45
	ExpiresInSeconds = 300 // 5 min
	Interval         = 3   // 3-second intervals for polling
)

type Service struct {
	codeRepo  GrantCodesRepository
	jwt       JWTIssuer
	submitter ArticleParser
}

// NewService creates a new instance of the extension service.
func NewService(repo GrantCodesRepository, jwt JWTIssuer, submitter ArticleParser) *Service {
	return &Service{
		codeRepo:  repo,
		jwt:       jwt,
		submitter: submitter,
	}
}

// GenerateGrantCodes creates a new pair of device and user codes, stores them in the database, and returns them to the caller.
// This method satisfies the implementation of RFC 8628 for the device authorization flow, which is used
// for pairing the extension with the user's account using a user code
func (s *Service) GenerateGrantCodes(ctx context.Context) (models.GrantCodes, error) {
	var err error
	var grantCodes models.GrantCodes
	grantCodes.DeviceCode, err = generateRandomCode(DeviceCodeLength)
	if err != nil {
		return models.GrantCodes{}, fmt.Errorf("failed to generate grant code: %v", err)
	}
	userCode, err := generateRandomCode(UserCodeLength)
	if err != nil {
		return models.GrantCodes{}, fmt.Errorf("failed to generate user code: %v", err)
	}
	grantCodes.Interval = Interval
	grantCodes.ExpiresIn = ExpiresInSeconds
	grantCodes.ExpiresAt = time.Now().Add(time.Duration(ExpiresInSeconds) * time.Second).Unix()

	// Codes not being, highly unlikely, but you never know
	// IF it happens we won't be able to store it due to uniqueness in the database
	// which will simply return an error for such infrequent occasions

	//Setting hashed userCode here to have additional layer of protection against leaks and constant time comparison attacks
	grantCodes.UserCode = HashCode(userCode)
	if err := s.codeRepo.CreateGrantCodes(ctx, grantCodes); err != nil {
		return models.GrantCodes{}, fmt.Errorf("failed to save grant codes: %v", err)
	}
	// We should return the unhashed user code to the client, as it is needed for the user to input it in the extension
	grantCodes.UserCode = userCode

	return grantCodes, nil
}

// CheckPairingStatus checks the status of the pairing process for a given device code.
// It retrieves the grant codes from the database and checks if the device code has been claimed by a user or if it has expired.
// If the device code is claimed, it generates a session token for the user and returns it along with the "paired" status.
// If the device code is still pending, it returns the "pending" status.
// If it has expired, it returns the "expired" status.
func (s *Service) CheckPairingStatus(ctx context.Context, deviceCode string) (models.PairingState, error) {
	grantCodes, err := s.codeRepo.GetDeviceGrant(ctx, deviceCode)
	if err != nil {
		return models.PairingState{}, fmt.Errorf("failed to get grant codes: %v", err)
	}
	notExpired := time.Now().Unix() < grantCodes.ExpiresAt
	notClaimed := grantCodes.ClaimedBy == ""
	if notExpired && notClaimed {
		return models.PairingState{
			Status: models.StatusPending,
		}, nil
	}
	// If we got here, the grant code is not pending and can safely be deleted from the database
	// ensuring it can only be used once for token generation
	// This is crucial, and we must fail if we can't delete the codes
	if err := s.codeRepo.DeleteGrantCodes(ctx, grantCodes); err != nil {
		return models.PairingState{}, fmt.Errorf("failed to delete grant codes: %v", err)
	}

	// Check expiration
	if !notExpired {
		return models.PairingState{
			Status: models.StatusExpired,
		}, nil
	}
	// At this point we can safely generate the session token
	token, err := s.jwt.Generate(grantCodes.ClaimedBy)
	if err != nil {
		return models.PairingState{}, fmt.Errorf("failed claim the device: %v", err)
	}
	return models.PairingState{
		Status:       models.StatusPaired,
		SessionToken: token,
	}, nil
}

// ClaimGrantCode allows a user to claim a grant code by providing the user code and their user ID.
// It updates the database to mark the grant code as claimed by the user.
// This method assumes an authentication layer in front of it already existing and providing the userID,
// so it doesn't perform any authentication checks itself.
// The operation relies on the repository performing an atomic update to ensure that a grant code can only be claimed by one user
func (s *Service) ClaimGrantCode(ctx context.Context, userCode, userID string) error {
	err := s.codeRepo.ClaimGrantCode(ctx, HashCode(userCode), userID)
	if err != nil {
		return fmt.Errorf("failed to claim grant code: %v", err)
	}
	return nil
}

// SubmitArticle submits an article for the user to be processed
func (s *Service) SubmitArticle(ctx context.Context, url, html, userID string) error {
	return s.submitter.ParseArticle(ctx, userID, url, html)
}

func generateRandomCode(l int) (string, error) {
	const characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	res := make([]byte, l)
	for i := 0; i < l; i++ {
		ind, err := rand.Int(rand.Reader, big.NewInt(int64(len(characters))))
		if err != nil {
			return "", err
		}
		res[i] = characters[ind.Int64()]
	}
	return string(res), nil
}

func HashCode(code string) string {
	normalised := strings.ToUpper(strings.ReplaceAll(strings.TrimSpace(code), "-", ""))
	sum := sha256.Sum256([]byte(normalised))
	return hex.EncodeToString(sum[:])
}
