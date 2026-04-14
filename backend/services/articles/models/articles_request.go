package articlemodels

type GetArticlesRequest struct {
	PageSize    int32
	PageToken   string
	Categories  []string
	SearchQuery string
	Author      string
}

type GetArticlesResponse struct {
	Articles      []ArticlePreview
	NextPageToken string
	TotalCount    int32
}
