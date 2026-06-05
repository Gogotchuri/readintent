package config

import (
	"os"
	"testing"

	"github.com/google/go-cmp/cmp"
)

func TestLoadConfig(t *testing.T) {
	// Creates config file in Temp dir
	// Loads config env from file
	// Then loads config from ENV
	tmpDirt := t.TempDir()
	expectedConfig := &Config{
		Environment:     "test",
		Port:            5051,
		KratosPublicURL: "http://localhost:9999",
		DatabaseConfig: DatabaseConfig{
			Hostname: "dbhost",
			Port:     6000,
			Username: "user",
			Password: "pass",
			Database: "mydb",
			SSLMode:  "require",
		},
		RedisStreams: RedisStreams{
			Hostname:     "redishost",
			Port:         6380,
			Password:     "redispass",
			DB:           2,
			GroupName:    "grp",
			ConsumerName: "cons",
		},
	}
	// SetEnvFromFile does not override variables already present in the
	// environment, so clear the keys we assert on to keep the test deterministic.
	keys := []string{
		"ENVIRONMENT", "PORT", "KRATOS_PUBLIC_URL",
		"DATABASE_CONFIG_HOSTNAME", "DATABASE_CONFIG_PORT", "DATABASE_CONFIG_USERNAME",
		"DATABASE_CONFIG_PASSWORD", "DATABASE_CONFIG_DATABASE", "DATABASE_CONFIG_SSLMODE",
		"REDIS_HOSTNAME", "REDIS_PORT", "REDIS_PASSWORD", "REDIS_DB",
		"REDIS_GROUP_NAME", "REDIS_CONSUMER_NAME",
	}
	for _, k := range keys {
		t.Setenv(k, "") // registers cleanup to restore the original value
		if err := os.Unsetenv(k); err != nil {
			t.Fatalf("Failed to unset env %s: %v", k, err)
		}
	}

	err := os.WriteFile(tmpDirt+"/.env", []byte(`
ENVIRONMENT=test
PORT=5051
KRATOS_PUBLIC_URL=http://localhost:9999
DATABASE_CONFIG_HOSTNAME=dbhost
DATABASE_CONFIG_PORT=6000
DATABASE_CONFIG_USERNAME=user
DATABASE_CONFIG_PASSWORD=pass
DATABASE_CONFIG_DATABASE=mydb
DATABASE_CONFIG_SSLMODE=require
REDIS_HOSTNAME=redishost
REDIS_PORT=6380
REDIS_PASSWORD=redispass
REDIS_DB=2
REDIS_GROUP_NAME=grp
REDIS_CONSUMER_NAME=cons
`), 0644)

	if err != nil {
		t.Fatal(err)
	}
	err = SetEnvFromFile(tmpDirt + "/.env")
	if err != nil {
		t.Fatalf("Failed to set env from file: %v", err)
	}

	config, err := LoadConfigFromEnv()
	if err != nil {
		t.Fatalf("Failed to load config from env: %v", err)
	}
	// Make sure the loaded config matches expectedConfig
	if diff := cmp.Diff(expectedConfig, config); diff != "" {
		t.Fatalf("Unexpected diff (-want +got): %v", diff)
	}
}
