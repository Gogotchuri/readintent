-- +goose Up
ALTER TABLE user_articles
  ADD COLUMN playback_speed DOUBLE PRECISION NOT NULL DEFAULT 1.0;

-- +goose Down
ALTER TABLE user_articles
  DROP COLUMN playback_speed;
