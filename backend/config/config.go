package config

import (
	"fmt"

	"github.com/caarlos0/env/v6"
	"github.com/joho/godotenv"
)

type Config struct {
	Environment     string         `env:"ENVIRONMENT" envDefault:"dev"`
	Port            int            `env:"PORT" envDefault:"5050"`
	KratosPublicURL string         `env:"KRATOS_PUBLIC_URL" envDefault:"http://localhost:4433"`
	DatabaseConfig  DatabaseConfig `envPrefix:"DATABASE_CONFIG_"`
	RedisStreams    RedisStreams   `envPrefix:"REDIS_"`
}

func (c Config) IsDev() bool {
	return c.Environment == "dev"
}

type RedisStreams struct {
	Hostname string `env:"HOSTNAME" envDefault:"localhost"`
	Port     int    `env:"PORT" envDefault:"6379"`
	Password string `env:"PASSWORD" envDefault:""`
	DB       int    `env:"DB" envDefault:"0"`

	GroupName    string `env:"GROUP_NAME" envDefault:""`
	ConsumerName string `env:"CONSUMER_NAME" envDefault:""`
}

type DatabaseConfig struct {
	Hostname string `env:"HOSTNAME" envDefault:"localhost"`
	Port     int    `env:"PORT" envDefault:"5432"`
	Username string `env:"USERNAME" envDefault:"postgres"`
	Password string `env:"PASSWORD" envDefault:"postgres"`
	Database string `env:"DATABASE" envDefault:"postgres"`
	SSLMode  string `env:"SSLMODE" envDefault:"disable"`
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
