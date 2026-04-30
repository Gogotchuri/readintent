package articlesconnectrpc

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strconv"

	"connectrpc.com/connect"
	"connectrpc.com/validate"
	"github.com/gogotchuri/readintent/backend/database/models"
	"github.com/gogotchuri/readintent/backend/middlewares"
	v1 "github.com/gogotchuri/readintent/backend/proto/articles/v1"
	"github.com/gogotchuri/readintent/backend/proto/articles/v1/articlesv1connect"
	"github.com/gogotchuri/readintent/backend/services/articles"
	iomodels "github.com/gogotchuri/readintent/backend/services/articles/models"
)

var _ articlesv1connect.ArticlesServiceHandler = &ArticlesServer{}

type ArticlesServer struct {
	service       *articles.Service
	sessionGetter middlewares.SessionGetter
}

func NewArticlesServer(service *articles.Service, sessionGetter middlewares.SessionGetter) *ArticlesServer {
	return &ArticlesServer{service: service, sessionGetter: sessionGetter}
}

func (a *ArticlesServer) BindArticlesServerToMux(mux *http.ServeMux) {
	interceptors := connect.WithInterceptors(
		middlewares.NewSessionInterceptor(a.sessionGetter).NewUnaryInterceptor(),
		validate.NewInterceptor(),
	)
	path, handler := articlesv1connect.NewArticlesServiceHandler(a, interceptors)
	mux.Handle(path, handler)
}

func (a *ArticlesServer) ParseArticle(ctx context.Context, req *connect.Request[v1.ParseArticleRequest]) (*connect.Response[v1.ParseArticleResponse], error) {
	session := middlewares.SessionFromCtx(ctx)
	if session == nil {
		return nil, connect.NewError(connect.CodeUnauthenticated, errors.New("no valid session"))
	}

	if err := a.service.ParseArticle(ctx, session.Identity.ID, req.Msg.GetUrl(), ""); err != nil {
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("parsing article: %w", err))
	}

	return connect.NewResponse(&v1.ParseArticleResponse{}), nil
}

func (a *ArticlesServer) GetArticles(ctx context.Context, req *connect.Request[v1.GetArticlesRequest]) (*connect.Response[v1.GetArticlesResponse], error) {
	session := middlewares.SessionFromCtx(ctx)
	if session == nil {
		return nil, connect.NewError(connect.CodeUnauthenticated, errors.New("no valid session"))
	}

	searchQ := iomodels.GetArticlesRequest{
		PageSize:  req.Msg.GetPageSize(),
		PageToken: req.Msg.GetPageToken(),
	}
	if req.Msg.SearchQuery != nil {
		searchQ.SearchQuery = *req.Msg.SearchQuery
	}
	if req.Msg.Author != nil {
		searchQ.Author = *req.Msg.Author
	}

	result, err := a.service.GetArticles(ctx, session.Identity.ID, searchQ)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("getting articles: %w", err))
	}

	return connect.NewResponse(&v1.GetArticlesResponse{
		Articles:      protoArticlePreviewsFromArticlePreviews(result.Articles),
		NextPageToken: result.NextPageToken,
		TotalCount:    result.TotalCount,
	}), nil
}

func (a *ArticlesServer) GetArticle(ctx context.Context, req *connect.Request[v1.GetArticleRequest]) (*connect.Response[v1.GetArticleResponse], error) {
	session := middlewares.SessionFromCtx(ctx)
	if session == nil {
		return nil, connect.NewError(connect.CodeUnauthenticated, errors.New("no valid session"))
	}

	id, err := strconv.ParseInt(req.Msg.GetId(), 10, 64)
	if err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("invalid article id: %w", err))
	}

	article, err := a.service.GetArticle(ctx, session.Identity.ID, id)
	if err != nil {
		if errors.Is(err, articles.ErrArticleNotFound) {
			return nil, connect.NewError(connect.CodeNotFound, errors.New("article not found"))
		}
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("getting article: %w", err))
	}
	return connect.NewResponse(&v1.GetArticleResponse{
		Article: protoArticleFromArticle(article),
	}), nil
}

func (a *ArticlesServer) DeleteArticle(ctx context.Context, req *connect.Request[v1.DeleteArticleRequest]) (*connect.Response[v1.DeleteArticleResponse], error) {
	session := middlewares.SessionFromCtx(ctx)
	if session == nil {
		return nil, connect.NewError(connect.CodeUnauthenticated, errors.New("no valid session"))
	}

	id, err := strconv.ParseInt(req.Msg.GetId(), 10, 64)
	if err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("invalid article id: %w", err))
	}

	if err := a.service.DeleteArticle(ctx, session.Identity.ID, id); err != nil {
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("deleting article: %w", err))
	}

	return connect.NewResponse(&v1.DeleteArticleResponse{}), nil
}

func protoArticleFromArticle(article *models.Article) *v1.Article {
	protoArticle := &v1.Article{
		Id:            article.Id,
		Status:        article.Status,
		Title:         article.Title.String(),
		Author:        article.Author.String(),
		Date:          article.PublishedDate.String(),
		ExtractedHtml: article.ExtractedHtml.String(),
		PureText:      article.PureText.String(),
		Description:   article.Description.StringRef(),
		Image:         article.ImageUrl.StringRef(),
		Url:           article.Url,
	}
	return protoArticle
}

func protoArticlePreviewsFromArticlePreviews(articles []models.ArticlePreview) []*v1.ArticlePreview {
	var previews []*v1.ArticlePreview
	for _, a := range articles {
		preview := &v1.ArticlePreview{
			Id:          a.Id,
			Status:      a.Status,
			Title:       a.Title.String(),
			Author:      a.Author.String(),
			Date:        a.PublishedDate.String(),
			Description: a.Description.StringRef(),
			Image:       a.ImageUrl.StringRef(),
			Url:         a.Url,
		}
		previews = append(previews, preview)
	}
	return previews
}
