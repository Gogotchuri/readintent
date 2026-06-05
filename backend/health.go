package main

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/jmoiron/sqlx"
	"github.com/redis/go-redis/v9"
)

// healthChecker reports whether an upstream dependency is reachable (e.g. Kratos).
type healthChecker interface {
	Health(ctx context.Context) error
}

// registerHealthRoutes wires a readiness endpoint onto the mux. It reports the
// backend as healthy only when the database, Redis, and Kratos all respond, so
// that clients treat a degraded dependency (503) the same as an unreachable
// server.
func registerHealthRoutes(mux *http.ServeMux, db *sqlx.DB, redisClient *redis.Client, kratos healthChecker) {
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()

		status, code := "ok", http.StatusOK
		if err := db.PingContext(ctx); err != nil {
			status, code = "unavailable", http.StatusServiceUnavailable
		} else if err := redisClient.Ping(ctx).Err(); err != nil {
			status, code = "unavailable", http.StatusServiceUnavailable
		} else if err := kratos.Health(ctx); err != nil {
			status, code = "unavailable", http.StatusServiceUnavailable
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(code)
		_ = json.NewEncoder(w).Encode(map[string]string{"status": status})
	})
}
