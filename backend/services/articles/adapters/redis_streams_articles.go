package adapters

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strconv"
	"strings"
	"time"

	"github.com/gogotchuri/readintent/backend/config"
	"github.com/redis/go-redis/v9"
)

// Define stream even names to emit and consume
const (
	// ScrapeInputStream is the main event emitted by the article service submitting article (url) for scrapping
	ScrapeInputStream = "scrape:jobs"
	// ScrapeResultStream article scraping done event (can also indicate failure) we should ingest it and store the intermediate result before the phonemizer is done
	ScrapeResultStream = "scrape:results"
	// PhonemizerResultStream phonemizer service will emit this event once it has phonemized the successfully scraped article
	PhonemizerResultStream = "phonemize:results"
)

type ListenerFunc func(ctx context.Context, msgValues map[string]any) error

type ArticlesHub struct {
	client    *redis.Client
	conf      config.RedisStreams
	listeners map[string]ListenerFunc
}

func NewArticlesHub(client *redis.Client, conf config.RedisStreams) *ArticlesHub {
	return &ArticlesHub{
		client: client,
		conf:   conf,
	}
}

func (h *ArticlesHub) SubmitArticle(ctx context.Context, articleID int64, url, html string) error {
	values := map[string]interface{}{
		"article_id": strconv.FormatInt(articleID, 10),
		"url":        url,
	}
	if html != "" {
		values["html"] = html
	}
	return h.client.XAdd(ctx, &redis.XAddArgs{
		Stream: ScrapeInputStream,
		Values: values,
	}).Err()
}

func (h *ArticlesHub) AddListener(eventStream string, listener ListenerFunc) {
	if h.listeners == nil {
		h.listeners = make(map[string]ListenerFunc)
	}
	h.listeners[eventStream] = listener
}

func (h *ArticlesHub) publishToListeners(ctx context.Context, eventStream string, messages []redis.XMessage) {
	listener, ok := h.listeners[eventStream]
	if !ok {
		slog.Warn(fmt.Sprintf("No listeners found for event stream %s", eventStream))
		return
	}
	for _, msg := range messages {
		if err := listener(ctx, msg.Values); err == nil {
			slog.Info(fmt.Sprintf("Successfully processed message %s from stream %s", msg.ID, eventStream))
			// We can acknowledge the processed message if the listener handled it
			err = h.client.XAck(context.Background(), eventStream, h.conf.GroupName, msg.ID).Err()
			if err != nil {
				slog.Error(fmt.Sprintf("Error acknowledging message %s from stream %s: %v", msg.ID, eventStream, err))
			}
		} else {
			slog.Error(fmt.Sprintf("Error processing message %s from stream %s: %v", msg.ID, eventStream, err))
		}
	}
}

func (h *ArticlesHub) Listen(ctx context.Context) error {
	// Ensure the groups exist before we start consuming
	if err := h.ensureGroups(ctx); err != nil {
		return err
	}
	for {
		res, err := h.client.XReadGroup(ctx, &redis.XReadGroupArgs{
			Group:    h.conf.GroupName,
			Consumer: h.conf.ConsumerName,
			Streams:  []string{ScrapeResultStream, PhonemizerResultStream, ">", ">"},
			Count:    10,
			Block:    5 * time.Second,
		}).Result()
		if err != nil {
			if errors.Is(err, redis.Nil) {
				continue // No messages, continue listening
			}
			// Log the error and continue listening
			slog.Error(fmt.Sprintf("error reading from scrape result stream: %v", err))
			continue
		}
		for _, msg := range res {
			// Process the message based on the stream it came from
			switch msg.Stream {
			case ScrapeResultStream:
				go h.publishToListeners(ctx, ScrapeResultStream, msg.Messages)
			case PhonemizerResultStream:
				go h.publishToListeners(ctx, PhonemizerResultStream, msg.Messages)
			default:
				slog.Warn(fmt.Sprintf("Received message from unknown stream %s", msg.Stream))
			}
		}
		// Make sure to respect context cancell
		select {
		case <-ctx.Done():
			slog.Info("Stopping ArticlesHub listener")
			return nil
		default:
		}
	}
}

// ensureGroups We are going to listen to the results and create the same group and consumer name for each stream
func (h *ArticlesHub) ensureGroups(ctx context.Context) error {
	if err := h.client.XGroupCreateMkStream(ctx, ScrapeResultStream, h.conf.GroupName, "$").Err(); err != nil {
		// Make sure the error is BUSYGROUP, which means the group already exists
		if !strings.Contains(err.Error(), "BUSYGROUP") {
			return err
		}
	}
	if err := h.client.XGroupCreateMkStream(ctx, PhonemizerResultStream, h.conf.GroupName, "$").Err(); err != nil {
		// Make sure the error is BUSYGROUP, which means the group already exists
		if !strings.Contains(err.Error(), "BUSYGROUP") {
			return err
		}
	}
	return nil
}
