package config

import (
	"fmt"

	"github.com/caarlos0/env/v6"
	"github.com/joho/godotenv"
)

type Config struct {
	Environment         string         `env:"ENVIRONMENT" default:"dev"`
	AuthServerPort      int            `env:"AUTH_SERVER_PORT" default:"5050"`
	ArticlesServerPort  int            `env:"ARTICLE_SERVER_PORT" default:"6060"`
	ExtensionServerPort int            `env:"EXTENSION_SERVER_PORT" default:"6061"`
	KratosPublicURL     string         `env:"KRATOS_PUBLIC_URL" default:"http://localhost:4433"`
	DatabaseConfig      DatabaseConfig `env:"DATABASE_CONFIG"`
	RedisStreams        RedisStreams   `env:"REDIS_STREAMS"`
}

func (c Config) IsDev() bool {
	return c.Environment == "dev"
}

type RedisStreams struct {
	Hostname string `env:"REDIS_HOSTNAME" default:"localhost"`
	Port     int    `env:"REDIS_PORT" default:"6379"`
	Password string `env:"REDIS_PASSWORD" default:""`
	DB       int    `env:"REDIS_DB" default:"0"`

	GroupName    string `env:"REDIS_GROUP_NAME" default:""`
	ConsumerName string `env:"REDIS_CONSUMER_NAME" default:""`
}

type DatabaseConfig struct {
	Hostname string `env:"HOSTNAME" default:"localhost"`
	Port     int    `env:"PORT" default:"5432"`
	Username string `env:"USERNAME" default:"postgres"`
	Password string `env:"PASSWORD" default:"postgres"`
	Database string `env:"DATABASE" default:"postgres"`
	SSLMode  string `env:"SSLMODE" default:"disable"`
}

func (dc DatabaseConfig) Driver() string {
	return "postgres"
}

func (dc DatabaseConfig) GetDSN() string {
	return fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		dc.Hostname, dc.Port, dc.Username, dc.Password, dc.Database, dc.SSLMode)
}

// SetEnvFromFile loads environment variables from a file. If the path is empty, it defaults to ".env".
// The thing to be careful about - This will not override the existing ENV variables and should be treated as providing
// default values in the absence of ENV variable.
func SetEnvFromFile(path string) error {
	if path == "" {
		path = ".env"
	}
	return godotenv.Load(path)
}

// LoadConfigFromEnv loads the configuration from environment variables and returns a Config struct.
func LoadConfigFromEnv() (*Config, error) {
	var c Config
	err := env.Parse(&c)
	return &c, err
}
