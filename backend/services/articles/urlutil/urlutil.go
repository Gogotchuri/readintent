package urlutil

//go:generate go run gen_tracking_params.go

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"sort"
	"strings"
	"time"
)

const MaxURLLength = 255

var (
	ErrEmptyURL      = fmt.Errorf("URL must not be empty")
	ErrInvalidURL    = fmt.Errorf("URL is not valid")
	ErrInvalidScheme = fmt.Errorf("URL must use http or https scheme")
	ErrMissingHost   = fmt.Errorf("URL must have a host")
	ErrURLTooLong    = fmt.Errorf("normalized URL exceeds %d characters", MaxURLLength)
)

// ValidateAndClean validates, normalizes, and strips tracking params from a URL.
func ValidateAndClean(rawURL string) (string, error) {
	rawURL = strings.TrimSpace(rawURL)
	if rawURL == "" {
		return "", ErrEmptyURL
	}

	u, err := url.Parse(rawURL)
	if err != nil {
		return "", fmt.Errorf("%w: %v", ErrInvalidURL, err)
	}

	u.Scheme = strings.ToLower(u.Scheme)
	if u.Scheme != "http" && u.Scheme != "https" {
		return "", ErrInvalidScheme
	}
	if u.Host == "" {
		return "", ErrMissingHost
	}

	// Normalize
	u.Host = strings.ToLower(u.Host)
	if len(u.Path) > 1 && strings.HasSuffix(u.Path, "/") {
		u.Path = strings.TrimRight(u.Path, "/")
	}
	u.Fragment = ""
	u.RawFragment = ""
	u.User = nil

	// Strip tracking params, sort remaining for deterministic dedup
	u.RawQuery = encodeQuerySorted(stripTrackingParams(u.Query()))

	result := u.String()
	if len(result) > MaxURLLength {
		return "", ErrURLTooLong
	}
	return result, nil
}

// IsValidationError returns true if err is a URL validation error.
func IsValidationError(err error) bool {
	return errors.Is(err, ErrEmptyURL) || errors.Is(err, ErrInvalidURL) ||
		errors.Is(err, ErrInvalidScheme) || errors.Is(err, ErrMissingHost) ||
		errors.Is(err, ErrURLTooLong)
}

// ResolveAndClean validates, cleans, follows redirects, and cleans the final URL.
// On redirect failure, falls back to the initially cleaned URL.
func ResolveAndClean(ctx context.Context, rawURL string) (string, error) {
	cleaned, err := ValidateAndClean(rawURL)
	if err != nil {
		return "", err
	}

	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	client := &http.Client{
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			if len(via) >= 10 {
				return fmt.Errorf("too many redirects")
			}
			return nil
		},
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodHead, cleaned, nil)
	if err != nil {
		return cleaned, nil // fallback
	}
	resp, err := client.Do(req)
	if err != nil {
		return cleaned, nil // fallback on network error
	}
	defer resp.Body.Close()

	finalURL := resp.Request.URL.String()
	if finalURL == cleaned {
		return cleaned, nil
	}

	// Clean the resolved URL too (destination may have tracking params)
	resolvedClean, err := ValidateAndClean(finalURL)
	if err != nil {
		return cleaned, nil // fallback if resolved URL is invalid
	}
	return resolvedClean, nil
}

func stripTrackingParams(params url.Values) url.Values {
	clean := make(url.Values)
	for key, values := range params {
		if _, isTracking := trackingParams[strings.ToLower(key)]; isTracking {
			continue
		}
		clean[key] = values
	}
	return clean
}

func encodeQuerySorted(v url.Values) string {
	if len(v) == 0 {
		return ""
	}
	keys := make([]string, 0, len(v))
	for k := range v {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	var buf strings.Builder
	for i, k := range keys {
		for j, val := range v[k] {
			if i > 0 || j > 0 {
				buf.WriteByte('&')
			}
			buf.WriteString(url.QueryEscape(k))
			buf.WriteByte('=')
			buf.WriteString(url.QueryEscape(val))
		}
	}
	return buf.String()
}
