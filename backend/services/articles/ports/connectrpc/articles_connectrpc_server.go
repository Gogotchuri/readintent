package articlesconnectrpc

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"connectrpc.com/connect"
	"connectrpc.com/validate"
	"github.com/gogotchuri/readintent/backend/database/models"
	"github.com/gogotchuri/readintent/backend/middlewares"
	v1 "github.com/gogotchuri/readintent/backend/proto/articles/v1"
	"github.com/gogotchuri/readintent/backend/proto/articles/v1/articlesv1connect"
	"github.com/gogotchuri/readintent/backend/services/articles"
	"github.com/gogotchuri/readintent/backend/services/articles/broker"
	iomodels "github.com/gogotchuri/readintent/backend/services/articles/models"
	"github.com/gogotchuri/readintent/backend/services/articles/urlutil"
)

var _ articlesv1connect.ArticlesServiceHandler = &ArticlesServer{}

// streamHeartbeatInterval is how often a heartbeat event is sent on an idle
// stream to survive intermediate proxy idle timeouts.
const streamHeartbeatInterval = 20 * time.Second

type ArticlesServer struct {
	service       *articles.Service
	sessionGetter middlewares.SessionGetter
	broker        broker.ArticleBroker
	// shutdownCtx is the root server context; cancelled on shutdown so open
	// streams close within the graceful-shutdown window instead of timing out.
	shutdownCtx context.Context
}

func NewArticlesServer(shutdownCtx context.Context, service *articles.Service, sessionGetter middlewares.SessionGetter, articleBroker broker.ArticleBroker) *ArticlesServer {
	return &ArticlesServer{
		service:       service,
		sessionGetter: sessionGetter,
		broker:        articleBroker,
		shutdownCtx:   shutdownCtx,
	}
}

func (a *ArticlesServer) BindArticlesServerToMux(mux *http.ServeMux) {
	interceptors := connect.WithInterceptors(
		middlewares.NewSessionInterceptor(a.sessionGetter),
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
		if urlutil.IsValidationError(err) {
			return nil, connect.NewError(connect.CodeInvalidArgument, err)
		}
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

func (a *ArticlesServer) CheckForUpdates(ctx context.Context, req *connect.Request[v1.CheckForUpdatesRequest]) (*connect.Response[v1.CheckForUpdatesResponse], error) {
	session := middlewares.SessionFromCtx(ctx)
	if session == nil {
		return nil, connect.NewError(connect.CodeUnauthenticated, errors.New("no valid session"))
	}

	since := time.Unix(req.Msg.GetLastCheckedAt(), 0)
	hasUpdates, serverTime, err := a.service.CheckForUpdates(ctx, session.Identity.ID, since)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("checking for updates: %w", err))
	}

	return connect.NewResponse(&v1.CheckForUpdatesResponse{
		HasUpdates:      hasUpdates,
		ServerTimestamp: serverTime.Unix(),
	}), nil
}

func (a *ArticlesServer) SaveArticleProgress(ctx context.Context, req *connect.Request[v1.SaveArticleProgressRequest]) (*connect.Response[v1.SaveArticleProgressResponse], error) {
	session := middlewares.SessionFromCtx(ctx)
	if session == nil {
		return nil, connect.NewError(connect.CodeUnauthenticated, errors.New("no valid session"))
	}

	id, err := strconv.ParseInt(req.Msg.GetArticleId(), 10, 64)
	if err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("invalid article id: %w", err))
	}

	if err := a.service.SaveArticleProgress(ctx, session.Identity.ID, id, req.Msg.GetPlayerPositionMs(), req.Msg.GetScrollPosition(), req.Msg.GetPlaybackSpeed()); err != nil {
		return nil, connect.NewError(connect.CodeInternal, fmt.Errorf("saving article progress: %w", err))
	}

	return connect.NewResponse(&v1.SaveArticleProgressResponse{}), nil
}

func (a *ArticlesServer) StreamArticleUpdates(ctx context.Context, _ *connect.Request[v1.StreamArticleUpdatesRequest], stream *connect.ServerStream[v1.StreamArticleUpdatesResponse]) error {
	session := middlewares.SessionFromCtx(ctx)
	if session == nil {
		return connect.NewError(connect.CodeUnauthenticated, errors.New("no valid session"))
	}

	sub := a.broker.Subscribe(session.Identity.ID)
	defer sub.Close()

	heartbeat := time.NewTicker(streamHeartbeatInterval)
	defer heartbeat.Stop()

	for {
		select {
		case <-ctx.Done():
			return nil
		case <-a.shutdownCtx.Done():
			return nil
		case preview := <-sub.Updates():
			msg := &v1.StreamArticleUpdatesResponse{
				Article:   protoArticlePreviewFromArticlePreview(preview),
				EventType: "updated",
			}
			if err := stream.Send(msg); err != nil {
				return err
			}
		case <-heartbeat.C:
			if err := stream.Send(&v1.StreamArticleUpdatesResponse{EventType: "heartbeat"}); err != nil {
				return err
			}
		}
	}
}

func protoArticleFromArticle(article *models.Article) *v1.Article {
	var phonemes []*v1.PhonemizerData
	if article.PhonemizerData.Valid {
		phonemes = make([]*v1.PhonemizerData, len(article.PhonemizerData.Data))
		for _, pd := range article.PhonemizerData.Data {
			phonemes = append(phonemes, protoPhonemesFromPhonemizerData(pd))
		}
	}
	protoArticle := &v1.Article{
		Id:               article.Id,
		Status:           article.Status,
		Title:            article.Title.String(),
		Author:           article.Author.String(),
		Date:             article.PublishedDate.String(),
		ExtractedHtml:    article.ExtractedHtml.String(),
		PureText:         article.PureText.String(),
		Description:      article.Description.StringRef(),
		Image:            article.ImageUrl.StringRef(),
		Url:              article.Url,
		PhonemizerData:   phonemes,
		PlayerPositionMs: article.PlayerPositionMs,
		ScrollPosition:   article.ScrollPosition,
		PlaybackSpeed:    article.PlaybackSpeed,
	}
	return protoArticle
}

func protoPhonemesFromPhonemizerData(pd models.PhonemizerData) *v1.PhonemizerData {
	tokenMeta := make([]*v1.PhonemizerTokenMeta, len(pd.TokenMeta))
	for i, tm := range pd.TokenMeta {
		tokenMeta[i] = &v1.PhonemizerTokenMeta{
			Text:          tm.Text,
			PhonemeLen:    tm.PhonemeLen,
			HasWhitespace: tm.HasWhitespace,
		}
	}
	return &v1.PhonemizerData{
		Graphemes: pd.Graphemes,
		Phonemes:  pd.Phonemes,
		TokenIds:  pd.TokenIds,
		TokenMeta: tokenMeta,
	}
}

func protoArticlePreviewFromArticlePreview(a *models.ArticlePreview) *v1.ArticlePreview {
	return &v1.ArticlePreview{
		Id:               a.Id,
		Status:           a.Status,
		Title:            a.Title.String(),
		Author:           a.Author.String(),
		Date:             a.PublishedDate.String(),
		Description:      a.Description.StringRef(),
		Image:            a.ImageUrl.StringRef(),
		Url:              a.Url,
		PlayerPositionMs: a.PlayerPositionMs,
		ScrollPosition:   a.ScrollPosition,
	}
}

func protoArticlePreviewsFromArticlePreviews(articles []models.ArticlePreview) []*v1.ArticlePreview {
	var previews []*v1.ArticlePreview
	for i := range articles {
		previews = append(previews, protoArticlePreviewFromArticlePreview(&articles[i]))
	}
	return previews
}
