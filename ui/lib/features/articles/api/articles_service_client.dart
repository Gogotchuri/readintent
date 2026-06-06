import "package:readintent_flutter/proto/articles/v1/articles_service.connect.client.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart"
    as articles_pb;

/// Interface for the articles RPC calls. Wraps the generated connectRPC client
/// so it can be mocked in tests.
abstract class ArticlesServiceClientI {
  Future<articles_pb.GetArticlesResponse> getArticles(
    articles_pb.GetArticlesRequest input,
  );
  Future<articles_pb.GetArticleResponse> getArticle(
    articles_pb.GetArticleRequest input,
  );
  Future<articles_pb.ParseArticleResponse> parseArticle(
    articles_pb.ParseArticleRequest input,
  );
  Future<articles_pb.DeleteArticleResponse> deleteArticle(
    articles_pb.DeleteArticleRequest input,
  );
  Future<articles_pb.CheckForUpdatesResponse> checkForUpdates(
    articles_pb.CheckForUpdatesRequest input,
  );
  Future<articles_pb.SaveArticleProgressResponse> saveArticleProgress(
    articles_pb.SaveArticleProgressRequest input,
  );
  Stream<articles_pb.StreamArticleUpdatesResponse> streamArticleUpdates(
    articles_pb.StreamArticleUpdatesRequest input,
  );
}

class ConnectArticlesServiceClient implements ArticlesServiceClientI {
  final ArticlesServiceClient _client;
  ConnectArticlesServiceClient(this._client);

  @override
  Future<articles_pb.GetArticlesResponse> getArticles(
    articles_pb.GetArticlesRequest input,
  ) => _client.getArticles(input);
  @override
  Future<articles_pb.GetArticleResponse> getArticle(
    articles_pb.GetArticleRequest input,
  ) => _client.getArticle(input);
  @override
  Future<articles_pb.ParseArticleResponse> parseArticle(
    articles_pb.ParseArticleRequest input,
  ) => _client.parseArticle(input);
  @override
  Future<articles_pb.DeleteArticleResponse> deleteArticle(
    articles_pb.DeleteArticleRequest input,
  ) => _client.deleteArticle(input);
  @override
  Future<articles_pb.CheckForUpdatesResponse> checkForUpdates(
    articles_pb.CheckForUpdatesRequest input,
  ) => _client.checkForUpdates(input);
  @override
  Future<articles_pb.SaveArticleProgressResponse> saveArticleProgress(
    articles_pb.SaveArticleProgressRequest input,
  ) => _client.saveArticleProgress(input);
  @override
  Stream<articles_pb.StreamArticleUpdatesResponse> streamArticleUpdates(
    articles_pb.StreamArticleUpdatesRequest input,
  ) => _client.streamArticleUpdates(input);
}
