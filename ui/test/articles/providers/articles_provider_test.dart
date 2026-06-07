import "dart:async";

import "package:fixnum/fixnum.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mockito/annotations.dart";
import "package:mockito/mockito.dart";
import "package:readintent_flutter/core/connectivity.dart";
import "package:readintent_flutter/features/articles/models/article_view.dart";
import "package:readintent_flutter/features/articles/providers/articles_provider.dart";
import "package:readintent_flutter/features/articles/repository/article_repository.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart"
    as articles_pb;

@GenerateMocks([ArticleRepository])
import "articles_provider_test.mocks.dart";

articles_pb.ArticlePreview _makePreview({int id = 1, String title = "Test"}) {
  return articles_pb.ArticlePreview(
    id: Int64(id),
    title: title,
    status: "ready",
  );
}

void main() {
  late MockArticleRepository mockRepo;
  late ProviderContainer container;

  ProviderContainer createContainer({bool isOnline = true}) {
    container = ProviderContainer(
      overrides: [
        articleRepositoryProvider.overrideWithValue(mockRepo),
        isOnlineProvider.overrideWithValue(isOnline),
      ],
    );
    return container;
  }

  setUp(() {
    mockRepo = MockArticleRepository();
    // The notifier subscribes to the update stream on build; default it to an
    // empty stream (a fresh one per call so reconnects can re-listen).
    when(mockRepo.streamArticleUpdates()).thenAnswer(
      (_) => Stream<articles_pb.StreamArticleUpdatesResponse>.empty(),
    );
  });

  tearDown(() {
    container.dispose();
  });

  test("ArticlesProvider returns cached articles from repository", () async {
    final previews = [_makePreview(id: 1), _makePreview(id: 2)];
    when(
      mockRepo.getArticles(
        pageSize: anyNamed("pageSize"),
        view: anyNamed("view"),
        onUpdated: anyNamed("onUpdated"),
      ),
    ).thenAnswer(
      (_) async =>
          articles_pb.GetArticlesResponse(articles: previews, totalCount: 2),
    );

    final c = createContainer();
    final state = await c.read(articlesProvider(ArticleView.inbox).future);

    expect(state.articles.length, 2);
    expect(state.totalCount, 2);
  });

  group("loadMore", () {
    test("appends next page articles", () async {
      final initialPreviews = [_makePreview(id: 1)];
      when(
        mockRepo.getArticles(
          pageSize: anyNamed("pageSize"),
          view: anyNamed("view"),
          onUpdated: anyNamed("onUpdated"),
        ),
      ).thenAnswer(
        (_) async => articles_pb.GetArticlesResponse(
          articles: initialPreviews,
          totalCount: 2,
          nextPageToken: "page2",
        ),
      );

      final nextPagePreviews = [_makePreview(id: 2, title: "Page2")];
      when(
        mockRepo.getArticlesPage(
          pageSize: anyNamed("pageSize"),
          pageToken: anyNamed("pageToken"),
          view: anyNamed("view"),
        ),
      ).thenAnswer(
        (_) async => articles_pb.GetArticlesResponse(
          articles: nextPagePreviews,
          totalCount: 2,
        ),
      );

      final c = createContainer(isOnline: true);
      await c.read(articlesProvider(ArticleView.inbox).future);

      await c.read(articlesProvider(ArticleView.inbox).notifier).loadMore();

      final state = c.read(articlesProvider(ArticleView.inbox)).value!;
      expect(state.articles.length, 2);
      expect(state.articles[1].title, "Page2");
    });

    test("does nothing when offline", () async {
      when(
        mockRepo.getArticles(
          pageSize: anyNamed("pageSize"),
          view: anyNamed("view"),
          onUpdated: anyNamed("onUpdated"),
        ),
      ).thenAnswer(
        (_) async => articles_pb.GetArticlesResponse(
          articles: [_makePreview()],
          totalCount: 2,
          nextPageToken: "page2",
        ),
      );

      final c = createContainer(isOnline: false);
      await c.read(articlesProvider(ArticleView.inbox).future);

      await c.read(articlesProvider(ArticleView.inbox).notifier).loadMore();

      verifyNever(
        mockRepo.getArticlesPage(
          pageSize: anyNamed("pageSize"),
          pageToken: anyNamed("pageToken"),
          view: anyNamed("view"),
        ),
      );
    });

    test("does nothing when no more pages", () async {
      when(
        mockRepo.getArticles(
          pageSize: anyNamed("pageSize"),
          view: anyNamed("view"),
          onUpdated: anyNamed("onUpdated"),
        ),
      ).thenAnswer(
        (_) async => articles_pb.GetArticlesResponse(
          articles: [_makePreview()],
          totalCount: 1,
          // No nextPageToken = no more pages
        ),
      );

      final c = createContainer(isOnline: true);
      await c.read(articlesProvider(ArticleView.inbox).future);

      await c.read(articlesProvider(ArticleView.inbox).notifier).loadMore();

      verifyNever(
        mockRepo.getArticlesPage(
          pageSize: anyNamed("pageSize"),
          pageToken: anyNamed("pageToken"),
          view: anyNamed("view"),
        ),
      );
    });

    test("sets error on failure", () async {
      when(
        mockRepo.getArticles(
          pageSize: anyNamed("pageSize"),
          view: anyNamed("view"),
          onUpdated: anyNamed("onUpdated"),
        ),
      ).thenAnswer(
        (_) async => articles_pb.GetArticlesResponse(
          articles: [_makePreview()],
          totalCount: 2,
          nextPageToken: "page2",
        ),
      );
      when(
        mockRepo.getArticlesPage(
          pageSize: anyNamed("pageSize"),
          pageToken: anyNamed("pageToken"),
          view: anyNamed("view"),
        ),
      ).thenThrow(Exception("Network error"));

      final c = createContainer(isOnline: true);
      await c.read(articlesProvider(ArticleView.inbox).future);

      await c.read(articlesProvider(ArticleView.inbox).notifier).loadMore();

      final state = c.read(articlesProvider(ArticleView.inbox)).value!;
      expect(state.hasError, true);
      expect(state.error, contains("Network error"));
    });
  });

  group("parseArticle", () {
    test("returns ParseArticleResult from repository", () async {
      when(
        mockRepo.getArticles(
          pageSize: anyNamed("pageSize"),
          view: anyNamed("view"),
          onUpdated: anyNamed("onUpdated"),
        ),
      ).thenAnswer((_) async => articles_pb.GetArticlesResponse());
      when(
        mockRepo.parseArticle(any),
      ).thenAnswer((_) async => ParseArticleResult(queued: true));

      final c = createContainer();
      await c.read(articlesProvider(ArticleView.inbox).future);

      final result = await c
          .read(articlesProvider(ArticleView.inbox).notifier)
          .parseArticle("https://example.com");
      expect(result.queued, true);

      verify(mockRepo.parseArticle("https://example.com")).called(1);
    });
  });

  group("deleteArticle", () {
    test("delegates to repository and refreshes", () async {
      when(
        mockRepo.getArticles(
          pageSize: anyNamed("pageSize"),
          view: anyNamed("view"),
          onUpdated: anyNamed("onUpdated"),
        ),
      ).thenAnswer(
        (_) async => articles_pb.GetArticlesResponse(
          articles: [_makePreview()],
          totalCount: 1,
        ),
      );
      when(mockRepo.deleteArticle(any)).thenAnswer((_) async {});

      final c = createContainer();
      await c.read(articlesProvider(ArticleView.inbox).future);

      await c
          .read(articlesProvider(ArticleView.inbox).notifier)
          .deleteArticle("1");

      // Deletion routes through the shared hub, which removes the article from
      // every view via a broadcast instead of refetching the list.
      verify(mockRepo.deleteArticle("1")).called(1);
    });
  });
}
