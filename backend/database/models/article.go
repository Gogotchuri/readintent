package models

import "time"

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
	Id             int64                 `db:"id"`
	Url            string                `db:"url"`
	Status         string                `db:"status"` // processing by default
	Title          string                `db:"title"`
	Author         string                `db:"author"`
	PublishedDate  string                `db:"published_date"`
	ExtractedHtml  string                `db:"extracted_html"`
	PureText       string                `db:"pure_text"`
	Categories     string                `db:"categories"`
	Description    string                `db:"description"`
	ImageUrl       string                `db:"image_url"`
	PhonemizerData JSONB[PhonemizerData] `db:"phonemizer_data"`
	CreatedAt      time.Time             `db:"created_at"`
}
type ArticlePreview struct {
	Id            int64     `db:"id"`
	Url           string    `db:"url"`
	Status        string    `db:"status"`
	Title         string    `db:"title"`
	Author        string    `db:"author"`
	PublishedDate string    `db:"published_date"`
	Categories    string    `db:"categories"`
	Description   string    `db:"description"`
	ImageUrl      string    `db:"image_url"`
	CreatedAt     time.Time `db:"created_at"`
}
