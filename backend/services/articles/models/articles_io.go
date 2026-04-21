package articlemodels

import (
	"fmt"

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

// ParsePageToken takes a page token in the format "unixTime:fromID" and returns the unix time and fromID components.
func ParsePageToken(token string) (int64, int64) {
	if token == "" {
		return 0, 0 // No token means start from the beginning
	}
	var unixTime int64
	var fromID int64
	_, err := fmt.Sscanf(token, "%d:%d", &unixTime, &fromID)
	if err != nil {
		return 0, 0
	}
	return unixTime, fromID
}

// EncodePageToken encodes unixTime and fromID into a string in the format "unixTime:fromID".
func EncodePageToken(unixTime int64, fromID int64) string {
	return fmt.Sprintf("%d:%d", unixTime, fromID)
}
