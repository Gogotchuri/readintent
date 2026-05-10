import "package:connectrpc/connect.dart";
import "package:fixnum/fixnum.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mockito/annotations.dart";
import "package:mockito/mockito.dart";
import "package:readintent_flutter/features/articles/api/articles_client.dart";
import "package:readintent_flutter/features/articles/api/articles_client_exceptions.dart";
import "package:readintent_flutter/features/articles/api/articles_service_client.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as articles_pb;

@GenerateMocks([ArticlesServiceClientI])
import "articles_client_test.mocks.dart";

final articleMock = articles_pb.Article(
  id: Int64(1),
  title: "Test Article",
  author: "John Doe",
  date: "2026-01-15",
  extractedHtml: "<p>Hello world</p>",
  url: "https://example.com/article",
  description: "A test article",
  image: "https://example.com/image.jpg",
);

void main() {
  late MockArticlesServiceClientI mockClient;
  late ArticlesClient articlesClient;

  setUp(() {
    mockClient = MockArticlesServiceClientI();
    articlesClient = ArticlesClient(client: mockClient);
  });

  test("getArticle returns article on success", () async {
    when(mockClient.getArticle(any)).thenAnswer(
      (_) async => articles_pb.GetArticleResponse(article: articleMock),
    );

    final article = await articlesClient.getArticle("1");
    expect(article.title, "Test Article");
    expect(article.author, "John Doe");
    expect(article.id, Int64(1));
  });

  test("getArticle throws ArticlesException on ConnectException", () async {
    when(mockClient.getArticle(any)).thenThrow(
      ConnectException(Code.notFound, "Not found"),
    );

    expect(
      () => articlesClient.getArticle("1"),
      throwsA(
        isA<ArticlesException>()
            .having((e) => e.message, "message", contains("Failed to fetch article"))
            .having((e) => e.message, "message", contains("Not found")),
      ),
    );
  });

  test("getArticle throws ArticlesException on generic exception", () async {
    when(mockClient.getArticle(any)).thenThrow(Exception("Network error"));

    expect(
      () => articlesClient.getArticle("1"),
      throwsA(
        isA<ArticlesException>()
            .having((e) => e.message, "message", contains("Failed to fetch article"))
            .having((e) => e.message, "message", contains("Network error")),
      ),
    );
  });
}
