import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:drift/drift.dart" hide isNull, isNotNull;
import "package:fixnum/fixnum.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mockito/annotations.dart";
import "package:mockito/mockito.dart";
import "package:readintent_flutter/core/connectivity.dart";
import "package:readintent_flutter/core/database/app_database.dart";
import "package:readintent_flutter/features/articles/api/articles_client.dart";
import "package:readintent_flutter/features/articles/repository/article_repository.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart"
    as articles_pb;

@GenerateMocks([AppDatabase, ArticlesClient])
import "article_repository_test.mocks.dart";

// Test fixtures
ArticlePreview makePreviewRow({
  int id = 1,
  String status = "ready",
  String title = "Test Article",
  String author = "Author",
  String date = "2026-01-15",
  String url = "https://example.com/article",
  String categories = '["tech"]',
  String description = "A test article",
  String imageUrl = "https://example.com/image.jpg",
  int sortOrder = 0,
  int cachedAt = 1000,
  int playerPositionMs = 0,
  double scrollPosition = 0.0,
}) {
  return ArticlePreview(
    id: id,
    status: status,
    title: title,
    author: author,
    date: date,
    url: url,
    categories: categories,
    description: description,
    imageUrl: imageUrl,
    sortOrder: sortOrder,
    cachedAt: cachedAt,
    playerPositionMs: playerPositionMs,
    scrollPosition: scrollPosition,
  );
}

ArticleDetail makeDetailRow({
  int id = 1,
  String extractedHtml = "<p>Hello</p>",
  String processedHtml = "<p>Hello</p>",
  String pureText = "Hello",
  Uint8List? phonemizerBlob,
  int cachedAt = 1000,
}) {
  return ArticleDetail(
    id: id,
    extractedHtml: extractedHtml,
    processedHtml: processedHtml,
    pureText: pureText,
    phonemizerBlob: phonemizerBlob,
    cachedAt: cachedAt,
  );
}

articles_pb.ArticlePreview makePreviewProto({
  int id = 1,
  String status = "ready",
  String title = "Test Article",
  String author = "Author",
  String date = "2026-01-15",
  String url = "https://example.com/article",
  List<String> categories = const ["tech"],
  String description = "A test article",
  String image = "https://example.com/image.jpg",
}) {
  return articles_pb.ArticlePreview(
    id: Int64(id),
    status: status,
    title: title,
    author: author,
    date: date,
    url: url,
    categories: categories,
    description: description,
    image: image,
  );
}

articles_pb.Article makeArticleProto({
  int id = 1,
  String status = "ready",
  String title = "Test Article",
  String author = "Author",
  String date = "2026-01-15",
  String url = "https://example.com/article",
  List<String> categories = const ["tech"],
  String description = "A test article",
  String image = "https://example.com/image.jpg",
  String extractedHtml = "<p>Hello</p>",
  String pureText = "Hello",
  List<articles_pb.PhonemizerData>? phonemizerData,
}) {
  return articles_pb.Article(
    id: Int64(id),
    status: status,
    title: title,
    author: author,
    date: date,
    url: url,
    categories: categories,
    description: description,
    image: image,
    extractedHtml: extractedHtml,
    pureText: pureText,
    phonemizerData: phonemizerData,
  );
}

void main() {
  late MockAppDatabase mockDb;
  late MockArticlesClient mockRemote;
  late ProviderContainer container;
  late ArticleRepository repository;

  ArticleRepository createRepository({bool isOnline = true}) {
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(mockDb),
        articlesServiceProvider.overrideWithValue(mockRemote),
        isOnlineProvider.overrideWithValue(isOnline),
      ],
    );
    return ArticleRepository(
      mockDb,
      mockRemote,
      container.read(providerRefProvider),
    );
  }

  setUp(() {
    mockDb = MockAppDatabase();
    mockRemote = MockArticlesClient();
  });

  tearDown(() {
    container.dispose();
  });

  group("getArticles", () {
    test("returns cached articles immediately", () async {
      final rows = [
        makePreviewRow(id: 1),
        makePreviewRow(id: 2, title: "Second"),
      ];
      when(mockDb.getAllPreviews()).thenAnswer((_) async => rows);

      repository = createRepository(isOnline: false);
      final result = await repository.getArticles();

      expect(result.articles.length, 2);
      expect(result.articles[0].id, Int64(1));
      expect(result.articles[1].title, "Second");
    });

    test("triggers background fetch when online", () async {
      when(mockDb.getAllPreviews()).thenAnswer((_) async => []);

      final serverResponse = articles_pb.GetArticlesResponse(
        articles: [makePreviewProto()],
        totalCount: 1,
      );
      when(
        mockRemote.getArticles(
          pageSize: anyNamed("pageSize"),
          pageToken: anyNamed("pageToken"),
        ),
      ).thenAnswer((_) async => serverResponse);
      when(mockDb.replacePreviews(any)).thenAnswer((_) async {});

      repository = createRepository(isOnline: true);
      await repository.getArticles();

      // Allow background future to complete
      await Future.delayed(Duration.zero);

      verify(
        mockRemote.getArticles(
          pageSize: anyNamed("pageSize"),
          pageToken: anyNamed("pageToken"),
        ),
      ).called(1);
      verify(mockDb.replacePreviews(any)).called(1);
    });

    test("calls onUpdated with fresh data when online", () async {
      when(mockDb.getAllPreviews()).thenAnswer((_) async => []);

      final serverResponse = articles_pb.GetArticlesResponse(
        articles: [makePreviewProto(title: "Fresh")],
        totalCount: 1,
      );
      when(
        mockRemote.getArticles(
          pageSize: anyNamed("pageSize"),
          pageToken: anyNamed("pageToken"),
        ),
      ).thenAnswer((_) async => serverResponse);
      when(mockDb.replacePreviews(any)).thenAnswer((_) async {});

      repository = createRepository(isOnline: true);
      final completer = Completer<articles_pb.GetArticlesResponse>();

      await repository.getArticles(
        onUpdated: (updated) => completer.complete(updated),
      );

      final updated = await completer.future;
      expect(updated.articles[0].title, "Fresh");
    });

    test("does NOT fetch from server when offline", () async {
      when(mockDb.getAllPreviews()).thenAnswer((_) async => []);

      repository = createRepository(isOnline: false);
      await repository.getArticles();

      await Future.delayed(Duration.zero);
      verifyNever(
        mockRemote.getArticles(
          pageSize: anyNamed("pageSize"),
          pageToken: anyNamed("pageToken"),
        ),
      );
    });

    test("ignores background fetch errors", () async {
      when(mockDb.getAllPreviews()).thenAnswer((_) async => []);
      when(
        mockRemote.getArticles(
          pageSize: anyNamed("pageSize"),
          pageToken: anyNamed("pageToken"),
        ),
      ).thenThrow(Exception("Network error"));

      repository = createRepository(isOnline: true);
      // Should not throw
      final result = await repository.getArticles();

      await Future.delayed(Duration.zero);
      expect(result.articles, isEmpty);
    });
  });

  group("getArticle", () {
    test("returns cached article when both preview and detail exist", () async {
      final preview = makePreviewRow();
      final detail = makeDetailRow();
      when(mockDb.getDetail(1)).thenAnswer((_) async => detail);
      when(mockDb.getPreview(1)).thenAnswer((_) async => preview);

      repository = createRepository(isOnline: false);
      final article = await repository.getArticle("1");

      expect(article, isNotNull);
      expect(article!.title, "Test Article");
      expect(article.extractedHtml, "<p>Hello</p>");
    });

    test("returns null when offline and not cached", () async {
      when(mockDb.getDetail(1)).thenAnswer((_) async => null);
      when(mockDb.getPreview(1)).thenAnswer((_) async => null);

      repository = createRepository(isOnline: false);
      final article = await repository.getArticle("1");

      expect(article, isNull);
    });

    test("waits for fetch when online and not cached", () async {
      when(mockDb.getDetail(1)).thenAnswer((_) async => null);
      when(mockDb.getPreview(1)).thenAnswer((_) async => null);

      final serverArticle = makeArticleProto(title: "From Server");
      when(mockRemote.getArticle("1")).thenAnswer((_) async => serverArticle);
      when(mockDb.upsertPreview(any)).thenAnswer((_) async {});
      when(mockDb.upsertDetail(any)).thenAnswer((_) async {});

      repository = createRepository(isOnline: true);
      final article = await repository.getArticle("1");

      expect(article, isNotNull);
      expect(article!.title, "From Server");
    });

    test("caches fetched detail and preview", () async {
      when(mockDb.getDetail(1)).thenAnswer((_) async => null);
      when(mockDb.getPreview(1)).thenAnswer((_) async => null);

      final serverArticle = makeArticleProto();
      when(mockRemote.getArticle("1")).thenAnswer((_) async => serverArticle);
      when(mockDb.upsertPreview(any)).thenAnswer((_) async {});
      when(mockDb.upsertDetail(any)).thenAnswer((_) async {});

      repository = createRepository(isOnline: true);
      await repository.getArticle("1");

      verify(mockDb.upsertPreview(any)).called(1);
      verify(mockDb.upsertDetail(any)).called(1);
    });
  });

  group("parseArticle", () {
    test("online: calls remote and returns queued=false", () async {
      when(mockRemote.parseArticle(any)).thenAnswer((_) async {});

      repository = createRepository(isOnline: true);
      final result = await repository.parseArticle("https://example.com");

      expect(result.queued, false);
      verify(mockRemote.parseArticle("https://example.com")).called(1);
    });

    test("offline: inserts pending op and returns queued=true", () async {
      when(mockDb.insertPendingOp(any)).thenAnswer((_) async => 1);

      repository = createRepository(isOnline: false);
      final result = await repository.parseArticle("https://example.com");

      expect(result.queued, true);
      final captured =
          verify(mockDb.insertPendingOp(captureAny)).captured.single
              as PendingOperationsCompanion;
      expect(captured.type.value, "parse_article");
      final payload =
          jsonDecode(captured.payload.value) as Map<String, dynamic>;
      expect(payload["url"], "https://example.com");
    });
  });

  group("deleteArticle", () {
    test("online success: deletes locally then remotely", () async {
      final preview = makePreviewRow();
      when(mockDb.getPreview(1)).thenAnswer((_) async => preview);
      when(mockDb.getDetail(1)).thenAnswer((_) async => null);
      when(mockDb.deletePreview(1)).thenAnswer((_) async {});
      when(mockRemote.deleteArticle("1")).thenAnswer((_) async {});

      repository = createRepository(isOnline: true);
      await repository.deleteArticle("1");

      verify(mockDb.deletePreview(1)).called(1);
      verify(mockRemote.deleteArticle("1")).called(1);
    });

    test("online failure: restores preview and detail", () async {
      final preview = makePreviewRow();
      final detail = makeDetailRow();
      when(mockDb.getPreview(1)).thenAnswer((_) async => preview);
      when(mockDb.getDetail(1)).thenAnswer((_) async => detail);
      when(mockDb.deletePreview(1)).thenAnswer((_) async {});
      when(mockRemote.deleteArticle("1")).thenThrow(Exception("Server error"));
      when(mockDb.upsertPreview(any)).thenAnswer((_) async {});
      when(mockDb.upsertDetail(any)).thenAnswer((_) async {});

      repository = createRepository(isOnline: true);
      expect(() => repository.deleteArticle("1"), throwsException);

      await Future.delayed(Duration.zero);
      verify(mockDb.upsertPreview(any)).called(1);
      verify(mockDb.upsertDetail(any)).called(1);
    });

    test("offline: deletes locally and queues op", () async {
      final preview = makePreviewRow();
      when(mockDb.getPreview(1)).thenAnswer((_) async => preview);
      when(mockDb.getDetail(1)).thenAnswer((_) async => null);
      when(mockDb.deletePreview(1)).thenAnswer((_) async {});
      when(mockDb.insertPendingOp(any)).thenAnswer((_) async => 1);

      repository = createRepository(isOnline: false);
      await repository.deleteArticle("1");

      verify(mockDb.deletePreview(1)).called(1);
      verifyNever(mockRemote.deleteArticle(any));
      verify(mockDb.insertPendingOp(captureAny)).called(1);
    });
  });
}

/// Helper provider to get a Ref for the repository
final providerRefProvider = Provider<Ref>((ref) => ref);
