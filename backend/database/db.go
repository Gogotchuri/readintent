package database

import (
	"context"

	"github.com/gogotchuri/readintent/backend/config"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

func NewDatabaseConnection(ctx context.Context, conf config.DatabaseConfig) (*sqlx.DB, error) {
	db, err := sqlx.ConnectContext(ctx, conf.Driver(), conf.GetDSN())
	if err != nil {
		return nil, err
	}
	return db, nil
}
