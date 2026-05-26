-- +goose Up
ALTER TABLE user_articles
  ADD COLUMN player_position_ms INT NOT NULL DEFAULT 0,
  ADD COLUMN scroll_position DOUBLE PRECISION NOT NULL DEFAULT 0,
  ADD COLUMN position_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- +goose Down
ALTER TABLE user_articles
  DROP COLUMN player_position_ms,
  DROP COLUMN scroll_position,
  DROP COLUMN position_updated_at;
