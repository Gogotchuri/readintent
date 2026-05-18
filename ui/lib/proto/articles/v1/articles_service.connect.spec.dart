//
//  Generated code. Do not modify.
//  source: articles/v1/articles_service.proto
//

import "package:connectrpc/connect.dart" as connect;
import "articles_service.pb.dart" as articlesv1articles_service;

abstract final class ArticlesService {
  /// Fully-qualified name of the ArticlesService service.
  static const name = 'articles.v1.ArticlesService';

  static const parseArticle = connect.Spec(
    '/$name/ParseArticle',
    connect.StreamType.unary,
    articlesv1articles_service.ParseArticleRequest.new,
    articlesv1articles_service.ParseArticleResponse.new,
  );

  static const getArticles = connect.Spec(
    '/$name/GetArticles',
    connect.StreamType.unary,
    articlesv1articles_service.GetArticlesRequest.new,
    articlesv1articles_service.GetArticlesResponse.new,
  );

  static const getArticle = connect.Spec(
    '/$name/GetArticle',
    connect.StreamType.unary,
    articlesv1articles_service.GetArticleRequest.new,
    articlesv1articles_service.GetArticleResponse.new,
  );

  static const deleteArticle = connect.Spec(
    '/$name/DeleteArticle',
    connect.StreamType.unary,
    articlesv1articles_service.DeleteArticleRequest.new,
    articlesv1articles_service.DeleteArticleResponse.new,
  );

  static const checkForUpdates = connect.Spec(
    '/$name/CheckForUpdates',
    connect.StreamType.unary,
    articlesv1articles_service.CheckForUpdatesRequest.new,
    articlesv1articles_service.CheckForUpdatesResponse.new,
  );
}
