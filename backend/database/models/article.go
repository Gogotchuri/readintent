package models

import (
	"time"
)

type ArticleStatus string

const (
	ArticleStatusProcessing = "processing"
	ArticleStatusReady      = "ready"
	ArticleStatusTextReady  = "text-ready"
	ArticleStatusFailed     = "failed"
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
	Id             int64                 `db:"id" json:"id"`
	Url            string                `db:"url" json:"url"`
	Status         string                `db:"status" json:"status"` // processing by default
	Title          NullString            `db:"title" json:"title"`
	Author         NullString            `db:"author" json:"author"`
	PublishedDate  NullString            `db:"published_date" json:"published_date"`
	ExtractedHtml  NullString            `db:"extracted_html" json:"extracted_html"`
	PureText       NullString            `db:"pure_text" json:"pure_text"`
	Categories     NullString            `db:"categories" json:"categories"`
	Description    NullString            `db:"description" json:"description"`
	ImageUrl       NullString            `db:"image_url" json:"image_url"`
	PhonemizerData JSONB[PhonemizerData] `db:"phonemizer_data" json:"phonemizer_data"`
	CreatedAt      time.Time             `db:"created_at" json:"created_at"`
}
type ArticlePreview struct {
	Id            int64      `db:"id" json:"id"`
	Url           string     `db:"url" json:"url"`
	Status        string     `db:"status" json:"status"`
	Title         NullString `db:"title" json:"title"`
	Author        NullString `db:"author" json:"author"`
	PublishedDate NullString `db:"published_date" json:"published_date"`
	Categories    NullString `db:"categories" json:"categories"`
	Description   NullString `db:"description" json:"description"`
	ImageUrl      NullString `db:"image_url" json:"image_url"`
	CreatedAt     time.Time  `db:"created_at" json:"created_at"`
}
