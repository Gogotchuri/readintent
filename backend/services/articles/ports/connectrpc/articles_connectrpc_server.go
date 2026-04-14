package articlesconnectrpc

import (
	"context"

	"connectrpc.com/connect"
	v1 "github.com/gogotchuri/readintent/backend/proto/articles/v1"
	"github.com/gogotchuri/readintent/backend/proto/articles/v1/articlesv1connect"
)

var _ articlesv1connect.ArticlesServiceHandler = &ArticlesService{}

type ArticlesService struct {
	service *ArticlesService
}

func (a ArticlesService) ParseArticle(ctx context.Context, c *connect.Request[v1.ParseArticleRequest]) (*connect.Response[v1.ParseArticleResponse], error) {
	//TODO implement me
	panic("implement me")
}

func (a ArticlesService) GetArticles(ctx context.Context, c *connect.Request[v1.GetArticlesRequest]) (*connect.Response[v1.GetArticlesResponse], error) {
	//TODO implement me
	panic("implement me")
}

func (a ArticlesService) GetArticle(ctx context.Context, c *connect.Request[v1.GetArticleRequest]) (*connect.Response[v1.GetArticleResponse], error) {
	//TODO implement me
	panic("implement me")
}

func (a ArticlesService) DeleteArticle(ctx context.Context, c *connect.Request[v1.DeleteArticleRequest]) (*connect.Response[v1.DeleteArticleResponse], error) {
	//TODO implement me
	panic("implement me")
}
