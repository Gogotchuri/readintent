package config

import (
	"fmt"

	"github.com/caarlos0/env/v6"
	"github.com/joho/godotenv"
)

type Config struct {
	AuthServerPort     int            `env:"AUTHSERVER_PORT" default:"5050"`
	ArticlesServerPort int            `env:"ARTICLESERVER_PORT" default:"6060"`
	DatabaseConfig     DatabaseConfig `env:"DATABASE_CONFIG"`
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

func SetEnvFromFile(path string) error {
	if path == "" {
		path = ".env"
	}
	return godotenv.Load(path)
}

func LoadConfigFromEnv() (*Config, error) {
	var c Config
	err := env.Parse(&c)
	return &c, err
}
