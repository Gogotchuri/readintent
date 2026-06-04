package broker

import (
	"testing"
	"time"

	"github.com/gogotchuri/readintent/backend/database/models"
)

func recv(t *testing.T, sub Subscription) *models.ArticlePreview {
	t.Helper()
	select {
	case p := <-sub.Updates():
		return p
	case <-time.After(time.Second):
		t.Fatal("timed out waiting for update")
		return nil
	}
}

func TestPublishDeliversToAllSubscribersOfUser(t *testing.T) {
	b := NewMemoryBroker()
	sub1 := b.Subscribe("user-1")
	defer sub1.Close()
	sub2 := b.Subscribe("user-1")
	defer sub2.Close()

	want := &models.ArticlePreview{Id: 42, Status: "ready"}
	b.Publish("user-1", want)

	if got := recv(t, sub1); got.Id != want.Id {
		t.Fatalf("sub1 got id %d, want %d", got.Id, want.Id)
	}
	if got := recv(t, sub2); got.Id != want.Id {
		t.Fatalf("sub2 got id %d, want %d", got.Id, want.Id)
	}
}

func TestPublishIsolatedPerUser(t *testing.T) {
	b := NewMemoryBroker()
	sub := b.Subscribe("user-1")
	defer sub.Close()
	other := b.Subscribe("user-2")
	defer other.Close()

	b.Publish("user-2", &models.ArticlePreview{Id: 7})

	select {
	case p := <-sub.Updates():
		t.Fatalf("user-1 should not receive user-2's update, got id %d", p.Id)
	case <-time.After(50 * time.Millisecond):
		// expected: no delivery
	}
	if got := recv(t, other); got.Id != 7 {
		t.Fatalf("user-2 got id %d, want 7", got.Id)
	}
}

func TestPublishDropsForSlowConsumer(t *testing.T) {
	b := NewMemoryBroker()
	sub := b.Subscribe("user-1")
	defer sub.Close()

	// Fill the buffer plus a couple extra; extras are dropped, not blocked.
	for i := range subBufferSize + 5 {
		b.Publish("user-1", &models.ArticlePreview{Id: int64(i)})
	}

	count := 0
	for {
		select {
		case <-sub.Updates():
			count++
			continue
		case <-time.After(50 * time.Millisecond):
		}
		break
	}
	if count != subBufferSize {
		t.Fatalf("buffered %d events, want %d", count, subBufferSize)
	}
}

func TestCloseIsIdempotentAndCleansUpMap(t *testing.T) {
	b := NewMemoryBroker()
	sub := b.Subscribe("user-1")

	sub.Close()
	sub.Close() // must not panic (double close)

	b.mu.RLock()
	_, exists := b.subs["user-1"]
	b.mu.RUnlock()
	if exists {
		t.Fatal("expected user entry to be removed from map after last sub closed")
	}

	// Publishing to a now-empty user must be a no-op, not a panic.
	b.Publish("user-1", &models.ArticlePreview{Id: 1})
}

func TestCloseRemovesOnlyOneSubscription(t *testing.T) {
	b := NewMemoryBroker()
	sub1 := b.Subscribe("user-1")
	sub2 := b.Subscribe("user-1")
	defer sub2.Close()

	sub1.Close()

	b.Publish("user-1", &models.ArticlePreview{Id: 99})
	if got := recv(t, sub2); got.Id != 99 {
		t.Fatalf("remaining sub got id %d, want 99", got.Id)
	}
}
