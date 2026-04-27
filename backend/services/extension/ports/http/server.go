package http

import (
	"net/http"

	"github.com/gogotchuri/readintent/backend/services/extension"
	"github.com/golang-jwt/jwt/v5"
)

type tokenParser interface {
	Parse(raw string) (*jwt.RegisteredClaims, error)
}
type ExtensionServer struct {
	service *extension.Service
	tp      tokenParser
}

func NewExtensionServer(service *extension.Service, parser tokenParser) *ExtensionServer {
	return &ExtensionServer{
		service: service,
		tp:      parser,
	}
}

func (es *ExtensionServer) RegisterRoutes(router *http.ServeMux) {
	router.HandleFunc("POST /extension/submit-article", es.handleSubmitArticle)
	router.HandleFunc("GET /extension/pairing/status", es.handlePairingStatus)
	router.HandleFunc("GET /extension/pairing/request-codes", es.handleRequestCodes)
}
