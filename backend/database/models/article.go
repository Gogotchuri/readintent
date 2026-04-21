package models

import "time"

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
	Id            int64
	Url           string
	Status        string
	Title         string
	Author        string
	PublishedDate string
	ExtractedHtml string
	PureText      string
	Categories    string
	Description   string
	ImageUrl      string
	// This is nullable jsonb field
	PhonemizerData JSONB[PhonemizerData]
	CreatedAt      time.Time
}
type ArticlePreview struct {
	Id            int64
	Url           string
	Status        string
	Title         string
	Author        string
	PublishedDate string
	Categories    string
	Description   string
	ImageUrl      string
	CreatedAt     time.Time
}
