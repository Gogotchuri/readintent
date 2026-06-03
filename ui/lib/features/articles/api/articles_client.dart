import "package:fixnum/fixnum.dart";
import "package:readintent_flutter/core/connect_transport.dart";
import "package:readintent_flutter/features/articles/api/articles_client_exceptions.dart";
import "package:readintent_flutter/features/articles/api/articles_service_client.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.connect.client.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart"
    as articles_pb;
import "package:connectrpc/connect.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "articles_client.g.dart";

class ArticlesClient {
  final ArticlesServiceClientI _client;
  ArticlesClient({required ArticlesServiceClientI client}) : _client = client;

  Future<articles_pb.GetArticlesResponse> getArticles({
    int pageSize = 20,
    String? pageToken,
  }) async {
    try {
      return await _client.getArticles(
        articles_pb.GetArticlesRequest(
          pageSize: pageSize,
          pageToken: pageToken,
        ),
      );
    } on ConnectException catch (e) {
      handleArticlesConnectException(e, "fetch articles");
    } catch (e) {
      throw ArticlesException("Failed to fetch articles: $e");
    }
  }

  Future<void> parseArticle(String url) async {
    try {
      await _client.parseArticle(articles_pb.ParseArticleRequest(url: url));
    } on ConnectException catch (e) {
      handleArticlesConnectException(e, "parse article");
    } catch (e) {
      throw ArticlesException("Failed to parse article: $e");
    }
  }

  Future<articles_pb.Article> getArticle(String id) async {
    try {
      final response = await _client.getArticle(
        articles_pb.GetArticleRequest(id: id),
      );
      return response.article;
    } on ConnectException catch (e) {
      handleArticlesConnectException(e, "fetch article");
    } catch (e) {
      throw ArticlesException("Failed to fetch article: $e");
    }
  }

  Future<void> deleteArticle(String id) async {
    try {
      await _client.deleteArticle(articles_pb.DeleteArticleRequest(id: id));
    } on ConnectException catch (e) {
      handleArticlesConnectException(e, "delete article");
    } catch (e) {
      throw ArticlesException("Failed to delete article: $e");
    }
  }

  Future<articles_pb.CheckForUpdatesResponse> checkForUpdates(
    int lastCheckedAtUnixSeconds,
  ) async {
    try {
      return await _client.checkForUpdates(
        articles_pb.CheckForUpdatesRequest(
          lastCheckedAt: Int64(lastCheckedAtUnixSeconds),
        ),
      );
    } on ConnectException catch (e) {
      handleArticlesConnectException(e, "check for updates");
    } catch (e) {
      throw ArticlesException("Failed to check for updates: $e");
    }
  }

  /// Server-streaming subscription to article updates
  Stream<articles_pb.StreamArticleUpdatesResponse> streamArticleUpdates() {
    return _client.streamArticleUpdates(
      articles_pb.StreamArticleUpdatesRequest(),
    );
  }

  Future<void> saveArticleProgress({
    required String articleId,
    required int playerPositionMs,
    required double scrollPosition,
    double playbackSpeed = 0,
  }) async {
    try {
      await _client.saveArticleProgress(
        articles_pb.SaveArticleProgressRequest(
          articleId: articleId,
          playerPositionMs: Int64(playerPositionMs),
          scrollPosition: scrollPosition,
          playbackSpeed: playbackSpeed,
        ),
      );
    } on ConnectException catch (e) {
      handleArticlesConnectException(e, "save article progress");
    } catch (e) {
      throw ArticlesException("Failed to save article progress: $e");
    }
  }
}

@riverpod
ArticlesClient articlesService(Ref ref) {
  final transport = ref.read(connectTransportProvider);
  return ArticlesClient(
    client: ConnectArticlesServiceClient(ArticlesServiceClient(transport)),
  );
}
