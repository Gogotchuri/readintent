//
//  Generated code. Do not modify.
//  source: articles/v1/articles_service.proto
//

import "package:connectrpc/connect.dart" as connect;
import "articles_service.pb.dart" as articlesv1articles_service;
import "articles_service.connect.spec.dart" as specs;

extension type ArticlesServiceClient (connect.Transport _transport) {
  Future<articlesv1articles_service.ParseArticleResponse> parseArticle(
    articlesv1articles_service.ParseArticleRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ArticlesService.parseArticle,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<articlesv1articles_service.GetArticlesResponse> getArticles(
    articlesv1articles_service.GetArticlesRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ArticlesService.getArticles,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<articlesv1articles_service.GetArticleResponse> getArticle(
    articlesv1articles_service.GetArticleRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ArticlesService.getArticle,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<articlesv1articles_service.DeleteArticleResponse> deleteArticle(
    articlesv1articles_service.DeleteArticleRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ArticlesService.deleteArticle,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<articlesv1articles_service.CheckForUpdatesResponse> checkForUpdates(
    articlesv1articles_service.CheckForUpdatesRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.ArticlesService.checkForUpdates,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
