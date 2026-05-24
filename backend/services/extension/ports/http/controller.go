package http

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"strings"

	"github.com/gogotchuri/readintent/backend/services/articles/urlutil"
)

func (es *ExtensionServer) handleRequestCodes(w http.ResponseWriter, r *http.Request) {
	codes, err := es.service.GenerateGrantCodes(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, err)
		return
	}
	writeJson(w, http.StatusOK, codes)
}

func (es *ExtensionServer) handlePairingStatus(w http.ResponseWriter, r *http.Request) {
	deviceID := r.URL.Query().Get("device_id")
	if deviceID == "" {
		writeError(w, http.StatusBadRequest, fmt.Errorf("device_id query parameter is required"))
		return
	}
	status, err := es.service.CheckPairingStatus(r.Context(), deviceID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, err)
		return
	}
	writeJson(w, http.StatusOK, status)
}

func (es *ExtensionServer) handleSubmitArticle(w http.ResponseWriter, r *http.Request) {
	authHeader := r.Header.Get("Authorization")
	if !strings.HasPrefix(authHeader, "Bearer ") {
		writeError(w, http.StatusUnauthorized, fmt.Errorf("missing or invalid authorization header"))
		return
	}
	claims, err := es.tp.Parse(strings.TrimPrefix(authHeader, "Bearer "))
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}

	//Parse body
	var body struct {
		URL  string `json:"url"`
		HTML string `json:"html"`
	}
	defer r.Body.Close()
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	userID := claims.Subject
	if err := es.service.SubmitArticle(r.Context(), userID, body.URL, body.HTML); err != nil {
		if urlutil.IsValidationError(err) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusInternalServerError, err)
		return
	}
	writeJson(w, http.StatusOK, map[string]string{"status": "ok"})
}

func writeJson(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(data); err != nil {
		slog.Error("failed to encode JSON response", "error", err)
	}
}
func writeError(w http.ResponseWriter, status int, err error) {
	type errorResponse struct {
		Error string `json:"error"`
	}
	resp := errorResponse{
		Error: err.Error(),
	}
	writeJson(w, status, resp)
}
