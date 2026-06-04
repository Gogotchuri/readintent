// Package broker provides a fan-out mechanism for pushing article preview
// updates to subscribed clients
//
// The current implementation is in-memory and only fans out within a single
// process. It is hidden behind the ArticleBroker interface so a better suited, distributed
// implementation (e.g. Redis Pub/Sub) can be dropped in if we ever run more instances
package broker

import (
	"log/slog"
	"sync"

	"github.com/gogotchuri/readintent/backend/database/models"
)

// subBufferSize is the per-subscription channel buffer. Publishes are dropped
// (not blocked) when a subscriber's buffer is full; This is alright, because we
// only use this to proactively push articles and provide a QOL feature
// If we lose the stream event, the user will get the article the next time
const subBufferSize = 8

// ArticleBroker fans out per-user article preview updates.
type ArticleBroker interface {
	// Subscribe registers a new subscription for the given user. The caller
	// must Close the returned subscription when done.
	Subscribe(userID string) Subscription
	// Publish delivers a preview to all of the user's active subscriptions.
	// It never blocks: a subscriber whose buffer is full silently drops the event.
	Publish(userID string, preview *models.ArticlePreview)
}

// Subscription is a single subscriber's view of the broker.
type Subscription interface {
	// Updates returns the channel on which previews are delivered.
	Updates() <-chan *models.ArticlePreview
	// Close removes the subscription from the broker and closes its channel.
	// It is safe to call multiple times.
	Close()
}

// MemoryBroker is an in-memory, single-process ArticleBroker.
type MemoryBroker struct {
	mu   sync.RWMutex
	subs map[string]map[*subscription]struct{}
}

var _ ArticleBroker = (*MemoryBroker)(nil)

// NewMemoryBroker creates an empty in-memory broker.
func NewMemoryBroker() *MemoryBroker {
	return &MemoryBroker{
		subs: make(map[string]map[*subscription]struct{}),
	}
}

type subscription struct {
	broker *MemoryBroker
	userID string
	ch     chan *models.ArticlePreview

	closeOnce sync.Once
}

func (s *subscription) Updates() <-chan *models.ArticlePreview {
	return s.ch
}

func (s *subscription) Close() {
	s.closeOnce.Do(func() {
		s.broker.remove(s)
		close(s.ch)
	})
}

// Subscribe registers a subscription. Keying the set by subscription pointer
// lets a single user hold multiple concurrent subscriptions
func (b *MemoryBroker) Subscribe(userID string) Subscription {
	sub := &subscription{
		broker: b,
		userID: userID,
		ch:     make(chan *models.ArticlePreview, subBufferSize),
	}
	b.mu.Lock()
	defer b.mu.Unlock()
	set, ok := b.subs[userID]
	if !ok {
		set = make(map[*subscription]struct{})
		b.subs[userID] = set
	}
	set[sub] = struct{}{}
	return sub
}

// Publish delivers the preview to every subscription for the user.
func (b *MemoryBroker) Publish(userID string, preview *models.ArticlePreview) {
	b.mu.RLock()
	defer b.mu.RUnlock()
	for sub := range b.subs[userID] {
		select {
		case sub.ch <- preview:
		default:
			slog.Warn("article broker dropped update for slow subscriber", "user_id", userID)
		}
	}
}

func (b *MemoryBroker) remove(sub *subscription) {
	b.mu.Lock()
	defer b.mu.Unlock()
	set, ok := b.subs[sub.userID]
	if !ok {
		return
	}
	delete(set, sub)
	if len(set) == 0 {
		delete(b.subs, sub.userID)
	}
}
