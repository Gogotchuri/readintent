package adapters

import (
	"testing"
)

const (
	kratosPublicURL = "http://localhost:4433"
)

func TestNewKratosClient(t *testing.T) {
	kratosClient := NewKratosClient(kratosPublicURL)

	if kratosClient.client == nil {
		t.Errorf("Expected Kratos API client to be initialized, got nil")
	}

	if len(kratosClient.client.GetConfig().Servers) != 1 {
		t.Errorf("Expected 1 server configuration, got %d", len(kratosClient.client.GetConfig().Servers))
	}

	if kratosClient.client.GetConfig().Servers[0].URL != kratosPublicURL {
		t.Errorf("Expected server URL to be %s, got %s", kratosPublicURL, kratosClient.client.GetConfig().Servers[0].URL)
	}
}
