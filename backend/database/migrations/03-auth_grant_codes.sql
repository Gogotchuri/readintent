-- Authorization grant codes table
-- +goose Up
BEGIN;
CREATE TABLE auth_grant_codes (
    device_code VARCHAR(255) PRIMARY KEY,
    user_code VARCHAR(255) NOT NULL UNIQUE,
    claimed_by VARCHAR(255) REFERENCES users(id) ON DELETE CASCADE,
    client_id VARCHAR(255),
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
COMMIT;

-- +goose Down
BEGIN;
DROP TABLE auth_grant_codes;
COMMIT;