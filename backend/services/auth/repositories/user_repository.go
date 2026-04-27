package repositories

import (
	"context"

	"github.com/jmoiron/sqlx"
)

type UserRepository struct {
	db *sqlx.DB
}

func NewUserRepository(db *sqlx.DB) UserRepository {
	return UserRepository{
		db: db,
	}
}
func (r UserRepository) CreateUser(ctx context.Context, id string) error {
	_, err := r.db.ExecContext(ctx, "INSERT INTO users (id) VALUES ($1)", id)
	return err
}
