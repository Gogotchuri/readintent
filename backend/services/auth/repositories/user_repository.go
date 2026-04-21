package repositories

import (
	"context"
	"database/sql"
)

type UserRepository struct {
	db *sql.DB
}

func NewUserRepository(db *sql.DB) UserRepository {
	return UserRepository{
		db: db,
	}
}
func (r UserRepository) CreateUser(ctx context.Context, id string) error {
	_, err := r.db.ExecContext(ctx, "INSERT INTO users (id) VALUES ($1)", id)
	return err
}
