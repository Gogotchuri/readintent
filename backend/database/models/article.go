package models

import (
	"encoding/json"
	"errors"
	"time"
)

type ArticleStatus string

const (
	ArticleStatusProcessing    = "processing"
	ArticleStatusReady         = "ready"
	ArticleStatusTextReady     = "text-ready"
	ArticleStatusPhonemesReady = "phonemes-ready"
	ArticleStatusFailed        = "failed"
)

type PhonemizerTokenMeta struct {
	Text          string `json:"text"`
	PhonemeLen    uint32 `json:"phoneme_len"`
	HasWhitespace bool   `json:"has_whitespace"`
}

type PhonemizerData struct {
	Graphemes string                `json:"graphemes"`
	Phonemes  string                `json:"phonemes"`
	TokenIds  []int64               `json:"token_ids"`
	TokenMeta []PhonemizerTokenMeta `json:"token_meta"`
}
type Article struct {
	Id               int64                   `db:"id" json:"id"`
	Url              string                  `db:"url" json:"url"`
	Status           string                  `db:"status" json:"status"` // processing by default
	Title            NullString              `db:"title" json:"title"`
	Author           NullString              `db:"author" json:"author"`
	PublishedDate    NullString              `db:"published_date" json:"published_date"`
	ExtractedHtml    NullString              `db:"extracted_html" json:"extracted_html"`
	PureText         NullString              `db:"pure_text" json:"pure_text"`
	Categories       NullString              `db:"categories" json:"categories"`
	Description      NullString              `db:"description" json:"description"`
	ImageUrl         NullString              `db:"image_url" json:"image"`
	PhonemizerData   JSONB[[]PhonemizerData] `db:"phonemizer_data" json:"phonemizer_data"`
	CreatedAt        time.Time               `db:"created_at" json:"created_at"`
	PlayerPositionMs int64                   `db:"player_position_ms" json:"player_position_ms"`
	ScrollPosition   float64                 `db:"scroll_position" json:"scroll_position"`
	PlaybackSpeed    float64                 `db:"playback_speed" json:"playback_speed"`
}

func (a *Article) GenerateDescriptionIfNone(l int) {
	if a.Description.Valid {
		return
	}
	if a.PureText.Valid && a.PureText.String() != "" {
		a.Description = NewNullString(a.PureText.String()[:min(l, len(a.PureText.String()))])
	}
}

func ArticleFromScrape(msg string) (Article, error) {
	var article Article
	if err := json.Unmarshal([]byte(msg), &article); err != nil {
		return Article{}, err
	}
	if article.Url == "" {
		return Article{}, errors.New("invalid article url")
	}
	// After scrape out result will be text ready with no phonemes
	article.Status = ArticleStatusTextReady
	return article, nil

}

type ArticlePreview struct {
	Id               int64      `db:"id" json:"id"`
	Url              string     `db:"url" json:"url"`
	Status           string     `db:"status" json:"status"`
	Title            NullString `db:"title" json:"title"`
	Author           NullString `db:"author" json:"author"`
	PublishedDate    NullString `db:"published_date" json:"published_date"`
	Categories       NullString `db:"categories" json:"categories"`
	Description      NullString `db:"description" json:"description"`
	ImageUrl         NullString `db:"image_url" json:"image_url"`
	CreatedAt        time.Time  `db:"created_at" json:"created_at"`
	PlayerPositionMs int64      `db:"player_position_ms" json:"player_position_ms"`
	ScrollPosition   float64    `db:"scroll_position" json:"scroll_position"`
}
