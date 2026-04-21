package database

import (
	"context"
	"embed"

	"github.com/jmoiron/sqlx"
	"github.com/pressly/goose/v3"
)

//go:embed migrations/*.sql
var embedMigrations embed.FS

func MigrationUp(ctx context.Context, db *sqlx.DB) error {
	goose.SetBaseFS(embedMigrations)
	err := goose.SetDialect(string(goose.DialectPostgres))
	if err != nil {
		return err
	}

	return goose.UpContext(ctx, db.DB, "migrations")
}

func MigrationDown(ctx context.Context, db *sqlx.DB) error {
	goose.SetBaseFS(embedMigrations)
	err := goose.SetDialect(string(goose.DialectPostgres))
	if err != nil {
		return err
	}
	return goose.DownContext(ctx, db.DB, "migrations")
}
