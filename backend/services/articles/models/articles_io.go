package articlemodels

import (
	"fmt"
	"time"

	"github.com/gogotchuri/readintent/backend/database/models"
)

type GetArticlesRequest struct {
	PageSize    int32
	PageToken   string
	Categories  []string
	SearchQuery string
	Author      string
}

type GetArticlesResponse struct {
	Articles      []models.ArticlePreview
	NextPageToken string
	TotalCount    int32
}

// ParsePageToken decodes a "unixMicro:id" token into a cursor timestamp and ID.
// Returns nil timestamp for an empty token (first page).
func ParsePageToken(token string) (*time.Time, int64) {
	if token == "" {
		return nil, 0
	}
	var unixMicro, id int64
	if _, err := fmt.Sscanf(token, "%d:%d", &unixMicro, &id); err != nil {
		return nil, 0
	}
	t := time.UnixMicro(unixMicro)
	return &t, id
}

// EncodePageToken encodes a cursor timestamp and ID into a "unixMicro:id" token.
func EncodePageToken(t time.Time, id int64) string {
	return fmt.Sprintf("%d:%d", t.UnixMicro(), id)
}
