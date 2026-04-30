package database

import (
	"fmt"

	"github.com/gogotchuri/readintent/backend/config"
	"github.com/redis/go-redis/v9"
)

func NewRedisClient(cfg config.RedisStreams) *redis.Client {
	redisClient := redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%d", cfg.Hostname, cfg.Port),
		Password: cfg.Password,
		DB:       cfg.DB,
	})
	return redisClient
}
