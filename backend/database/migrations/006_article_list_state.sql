-- +goose Up
-- Per-user list placement. inbox/archive are mutually exclusive; is_favorite is
-- an orthogonal flag so an article can be favorited while in either list.
ALTER TABLE user_articles
  ADD COLUMN list_state VARCHAR(20) NOT NULL DEFAULT 'inbox',
  ADD COLUMN is_favorite BOOLEAN NOT NULL DEFAULT FALSE;

-- +goose Down
ALTER TABLE user_articles
  DROP COLUMN list_state,
  DROP COLUMN is_favorite;
