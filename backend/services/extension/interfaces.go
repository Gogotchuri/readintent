package extension

import (
	"context"

	"github.com/gogotchuri/readintent/backend/services/extension/models"
)

type GrantCodesRepository interface {
	CreateGrantCodes(ctx context.Context, codes models.GrantCodes) error
	DeleteGrantCodes(ctx context.Context, codes models.GrantCodes) error
	GetDeviceGrant(ctx context.Context, deviceCode string) (models.GrantCodes, error)
	ClaimGrantCode(ctx context.Context, userCode, userID string) error
}

type JWTIssuer interface {
	Generate(userID string) (string, error)
}

type ArticleParser interface {
	ParseArticle(ctx context.Context, userID, url, html string) error
}
