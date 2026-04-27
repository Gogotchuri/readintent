package repositories

import (
	"context"
	"fmt"

	"github.com/gogotchuri/readintent/backend/services/extension"
	"github.com/gogotchuri/readintent/backend/services/extension/models"
	"github.com/jmoiron/sqlx"
)

var _ extension.GrantCodesRepository = &PgGrantCodesRepository{}

type PgGrantCodesRepository struct {
	db *sqlx.DB
}

func NewPgGrantCodesRepository(db *sqlx.DB) *PgGrantCodesRepository {
	return &PgGrantCodesRepository{db: db}
}

func (r *PgGrantCodesRepository) CreateGrantCodes(ctx context.Context, codes models.GrantCodes) error {
	_, err := r.db.ExecContext(ctx, `
		INSERT INTO auth_grant_codes (device_code, user_code, expires_at)
		VALUES ($1, $2, to_timestamp($3))
	`, codes.DeviceCode, codes.UserCode, codes.ExpiresAt)
	if err != nil {
		return fmt.Errorf("failed to create grant codes: %w", err)
	}
	return nil
}

func (r *PgGrantCodesRepository) DeleteGrantCodes(ctx context.Context, codes models.GrantCodes) error {
	_, err := r.db.ExecContext(ctx, `
		DELETE FROM auth_grant_codes WHERE device_code = $1
	`, codes.DeviceCode)
	if err != nil {
		return fmt.Errorf("failed to delete grant codes: %w", err)
	}
	return nil
}

func (r *PgGrantCodesRepository) GetDeviceGrant(ctx context.Context, deviceCode string) (models.GrantCodes, error) {
	var gc models.GrantCodes
	err := r.db.QueryRowxContext(ctx, `
		SELECT device_code, user_code, COALESCE(claimed_by, '') as claimed_by,
			EXTRACT(EPOCH FROM expires_at)::bigint as expires_at
		FROM auth_grant_codes WHERE device_code = $1
	`, deviceCode).Scan(&gc.DeviceCode, &gc.UserCode, &gc.ClaimedBy, &gc.ExpiresAt)
	if err != nil {
		return models.GrantCodes{}, fmt.Errorf("failed to get device grant: %w", err)
	}
	return gc, nil
}

func (r *PgGrantCodesRepository) ClaimGrantCode(ctx context.Context, userCode, userID string) error {
	result, err := r.db.ExecContext(ctx, `
		UPDATE auth_grant_codes SET claimed_by = $1
		WHERE user_code = $2 AND claimed_by IS NULL AND expires_at > NOW()
	`, userID, userCode)
	if err != nil {
		return fmt.Errorf("failed to claim grant code: %w", err)
	}
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to check rows affected: %w", err)
	}
	if rowsAffected == 0 {
		return fmt.Errorf("grant code not found, already claimed, or expired")
	}
	return nil
}
