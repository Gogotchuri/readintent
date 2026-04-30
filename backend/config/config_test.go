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
		Port: 5051,
		DatabaseConfig: DatabaseConfig{
			Hostname: "localhost",
			Port:     5432,
			Username: "postgres",
			Password: "postgres",
			Database: "postgres",
			SSLMode:  "disable",
		},
	}
	err := os.WriteFile(tmpDirt+"/.env", []byte(`
AUTHSERVER_PORT=5051
ARTICLESERVER_PORT=6061
HOSTNAME=localhost
PORT=5432
USERNAME=postgres
PASSWORD=postgres
DATABASE=postgres
SSLMODE=disable
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
