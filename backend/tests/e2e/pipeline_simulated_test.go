package e2e

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"connectrpc.com/connect"
	v1 "github.com/gogotchuri/readintent/backend/proto/articles/v1"
	"github.com/redis/go-redis/v9"
)

// simulateScraper mimics the Python scraper service.
// Reads from scrape:jobs, publishes extracted article to scrape:results.
func simulateScraper(ctx context.Context, t *testing.T, rc *redis.Client) {
	t.Helper()
	const group = "scraper-group"
	const consumer = "scraper-sim"
	const inputStream = "scrape:jobs"
	const outputStream = "scrape:results"

	rc.XGroupCreateMkStream(ctx, inputStream, group, "0")

	for {
		select {
		case <-ctx.Done():
			return
		default:
		}
		res, err := rc.XReadGroup(ctx, &redis.XReadGroupArgs{
			Group:    group,
			Consumer: consumer,
			Streams:  []string{inputStream, ">"},
			Count:    10,
			Block:    2 * time.Second,
		}).Result()
		if err != nil {
			continue
		}
		for _, stream := range res {
			for _, msg := range stream.Messages {
				articleID := msg.Values["article_id"].(string)
				url := msg.Values["url"].(string)

				result, _ := json.Marshal(map[string]any{
					"url":            url,
					"title":          "Test Article Title",
					"author":         "Test Author",
					"date":           "2024-01-15",
					"extracted_html": "<p>This is the extracted HTML content of the test article.</p>",
					"pure_text":      "This is the extracted HTML content of the test article.",
					"categories":     nil,
					"description":    "A test article for E2E testing",
					"image":          nil,
				})

				rc.XAdd(ctx, &redis.XAddArgs{
					Stream: outputStream,
					Values: map[string]any{
						"article_id": articleID,
						"result":     string(result),
					},
				})
				rc.XAck(ctx, inputStream, group, msg.ID)
			}
		}
	}
}

// simulatePhonemizer mimics the Python phonemizer service.
// Reads from scrape:results (own group), publishes phonemizer data to phonemize:results.
func simulatePhonemizer(ctx context.Context, t *testing.T, rc *redis.Client) {
	t.Helper()
	const group = "phonemizer-group"
	const consumer = "phonemizer-sim"
	const inputStream = "scrape:results"
	const outputStream = "phonemize:results"

	rc.XGroupCreateMkStream(ctx, inputStream, group, "0")

	for {
		select {
		case <-ctx.Done():
			return
		default:
		}
		res, err := rc.XReadGroup(ctx, &redis.XReadGroupArgs{
			Group:    group,
			Consumer: consumer,
			Streams:  []string{inputStream, ">"},
			Count:    10,
			Block:    2 * time.Second,
		}).Result()
		if err != nil {
			continue
		}
		for _, stream := range res {
			for _, msg := range stream.Messages {
				articleID := msg.Values["article_id"].(string)

				result, _ := json.Marshal([]map[string]any{{
					"graphemes": "This is the extracted HTML content of the test article.",
					"phonemes":  "This is the extracted HTML content of the test article",
					"token_ids": []int{1, 2, 3, 4, 5, 6},
					"token_meta": []map[string]any{
						{"text": "This", "phoneme_len": 3, "has_whitespace": true},
						{"text": "is", "phoneme_len": 2, "has_whitespace": true},
						{"text": "the", "phoneme_len": 2, "has_whitespace": true},
						{"text": "extracted", "phoneme_len": 10, "has_whitespace": true},
						{"text": "HTML", "phoneme_len": 10, "has_whitespace": true},
						{"text": "content", "phoneme_len": 7, "has_whitespace": false},
					},
				}})

				rc.XAdd(ctx, &redis.XAddArgs{
					Stream: outputStream,
					Values: map[string]any{
						"article_id": articleID,
						"result":     string(result),
					},
				})
				rc.XAck(ctx, inputStream, group, msg.ID)
			}
		}
	}
}

func TestFullPipeline_Simulated(t *testing.T) {
	db, redisClient := startPostgresAndRedis(t)
	baseURL := startBackend(t, db, redisClient)

	ctx, cancel := context.WithCancel(t.Context())
	t.Cleanup(cancel)
	go simulateScraper(ctx, t, redisClient)
	go simulatePhonemizer(ctx, t, redisClient)

	// Give simulators and backend listener time to set up groups
	time.Sleep(1 * time.Second)

	client := newArticlesClient(t, baseURL)

	// Submit article
	_, err := client.ParseArticle(t.Context(), connect.NewRequest(&v1.ParseArticleRequest{
		Url: "https://example.com/test-e2e-article",
	}))
	if err != nil {
		t.Fatalf("ParseArticle: %v", err)
	}

	// Poll until ready. The simulated pipeline is near-instant once messages
	// flow, so this only needs headroom for container/consumer-group startup.
	resp := pollArticleUntilReady(t, client, 30*time.Second)

	if resp.TotalCount != 1 {
		t.Fatalf("expected 1 article, got %d", resp.TotalCount)
	}
	article := resp.Articles[0]
	if article.Status != "ready" {
		t.Errorf("expected status 'ready', got %q", article.Status)
	}
	if article.Url != "https://example.com/test-e2e-article" {
		t.Errorf("unexpected URL: %s", article.Url)
	}
	t.Logf("Passed! Article title: %s, author: %s, published date: %s", article.Title, article.Author, article.Date)
}
