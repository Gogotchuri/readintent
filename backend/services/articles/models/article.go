package articlemodels

type PhonemizerTokenMeta struct {
	Text          string
	PhonemeLen    uint32
	HasWhitespace bool
}

type PhonemizerData struct {
	Graphemes string
	Phonemes  string
	TokenIds  []int64
	TokenMeta []*PhonemizerTokenMeta
}

type ArticlePreview struct {
	Id          string
	Status      string
	Title       string
	Author      string
	Date        string
	Url         string
	Categories  []string
	Description string
	Image       string
}

type Article struct {
	Id             string
	Status         string
	Title          string
	Author         string
	Date           string
	ExtractedHtml  string
	PureText       string
	Url            string
	Categories     []string
	Description    string
	Image          string
	PhonemizerData *PhonemizerData
}
