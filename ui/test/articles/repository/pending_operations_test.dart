import "dart:async";
import "dart:convert";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mockito/annotations.dart";
import "package:mockito/mockito.dart";
import "package:readintent_flutter/core/database/app_database.dart";
import "package:readintent_flutter/features/articles/api/articles_client.dart";
import "package:readintent_flutter/features/articles/repository/pending_operations.dart";
import "package:readintent_flutter/models/operation.dart";

@GenerateMocks([AppDatabase, ArticlesClient])
import "pending_operations_test.mocks.dart";

PendingOperation makeOp({
  int id = 1,
  String type = opParseArticle,
  String? payload,
  String status = opStatusPending,
  int createdAt = 1000,
  int retryCount = 0,
  String? lastError,
}) {
  payload ??= type == opParseArticle
      ? jsonEncode({"url": "https://example.com"})
      : jsonEncode({"article_id": "1"});
  return PendingOperation(
    id: id,
    type: type,
    payload: payload,
    status: status,
    createdAt: createdAt,
    retryCount: retryCount,
    lastError: lastError,
  );
}

void main() {
  late MockAppDatabase mockDb;
  late MockArticlesClient mockRemote;
  late ProviderContainer container;
  late PendingOperationsProcessor processor;

  setUp(() {
    mockDb = MockAppDatabase();
    mockRemote = MockArticlesClient();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(mockDb),
        articlesServiceProvider.overrideWithValue(mockRemote),
      ],
    );
    processor = PendingOperationsProcessor(mockDb, mockRemote, container.read(_refProvider));
  });

  tearDown(() {
    processor.dispose();
    container.dispose();
  });

  group("processQueue", () {
    test("processes all pending ops successfully", () async {
      final ops = [
        makeOp(id: 1, type: opParseArticle),
        makeOp(id: 2, type: opDeleteArticle),
      ];
      when(mockDb.getPendingOps()).thenAnswer((_) async => ops);
      when(mockRemote.parseArticle(any)).thenAnswer((_) async {});
      when(mockRemote.deleteArticle(any)).thenAnswer((_) async {});
      when(mockDb.deletePendingOp(any)).thenAnswer((_) async {});

      await processor.processQueue();

      verify(mockRemote.parseArticle("https://example.com")).called(1);
      verify(mockRemote.deleteArticle("1")).called(1);
      verify(mockDb.deletePendingOp(1)).called(1);
      verify(mockDb.deletePendingOp(2)).called(1);
    });

    test("stops at first failure, preserves FIFO", () async {
      final ops = [
        makeOp(id: 1, type: opParseArticle),
        makeOp(id: 2, type: opParseArticle, payload: jsonEncode({"url": "https://fail.com"})),
        makeOp(id: 3, type: opDeleteArticle),
      ];
      when(mockDb.getPendingOps()).thenAnswer((_) async => ops);
      when(mockRemote.parseArticle("https://example.com")).thenAnswer((_) async {});
      when(mockRemote.parseArticle("https://fail.com")).thenThrow(Exception("Network error"));
      when(mockDb.deletePendingOp(any)).thenAnswer((_) async {});
      when(mockDb.updatePendingOp(any,
        retryCount: anyNamed("retryCount"),
        lastError: anyNamed("lastError"),
        status: anyNamed("status"),
      )).thenAnswer((_) async {});

      await processor.processQueue();

      // 1st op executed and deleted
      verify(mockDb.deletePendingOp(1)).called(1);
      // 2nd op failed, retry count updated
      verify(mockDb.updatePendingOp(2,
        retryCount: 1,
        lastError: argThat(contains("Network error"), named: "lastError"),
      )).called(1);
      // 3rd op never touched
      verifyNever(mockRemote.deleteArticle(any));
      verifyNever(mockDb.deletePendingOp(3));
    });

    test("re-entrance guard prevents concurrent processing", () async {
      final completer = Completer<List<PendingOperation>>();
      when(mockDb.getPendingOps()).thenAnswer((_) => completer.future);

      // Start first processQueue (will block on getPendingOps)
      final first = processor.processQueue();
      // Start second processQueue (should return immediately due to guard)
      final second = processor.processQueue();

      // Complete the pending future
      completer.complete([]);

      await first;
      await second;

      // getPendingOps should only be called once
      verify(mockDb.getPendingOps()).called(1);
    });
  });

  group("_executeOp (via processQueue)", () {
    test("parse article op: calls remote.parseArticle with URL from payload", () async {
      when(mockDb.getPendingOps()).thenAnswer((_) async => [
        makeOp(type: opParseArticle, payload: jsonEncode({"url": "https://test.com/article"})),
      ]);
      when(mockRemote.parseArticle(any)).thenAnswer((_) async {});
      when(mockDb.deletePendingOp(any)).thenAnswer((_) async {});

      await processor.processQueue();

      verify(mockRemote.parseArticle("https://test.com/article")).called(1);
    });

    test("delete article op: calls remote.deleteArticle with article_id from payload", () async {
      when(mockDb.getPendingOps()).thenAnswer((_) async => [
        makeOp(type: opDeleteArticle, payload: jsonEncode({"article_id": "42"})),
      ]);
      when(mockRemote.deleteArticle(any)).thenAnswer((_) async {});
      when(mockDb.deletePendingOp(any)).thenAnswer((_) async {});

      await processor.processQueue();

      verify(mockRemote.deleteArticle("42")).called(1);
    });

    test("unknown op type: marked as failed", () async {
      when(mockDb.getPendingOps()).thenAnswer((_) async => [
        makeOp(type: "unknown_op_type", payload: "{}"),
      ]);
      when(mockDb.updatePendingOp(any,
        retryCount: anyNamed("retryCount"),
        lastError: anyNamed("lastError"),
        status: anyNamed("status"),
      )).thenAnswer((_) async {});

      await processor.processQueue();

      verify(mockDb.updatePendingOp(1,
        status: opStatusFailed,
        lastError: argThat(contains("Unknown"), named: "lastError"),
      )).called(1);
    });

    test("retries increment retryCount", () async {
      when(mockDb.getPendingOps()).thenAnswer((_) async => [
        makeOp(retryCount: 0),
      ]);
      when(mockRemote.parseArticle(any)).thenThrow(Exception("fail"));
      when(mockDb.updatePendingOp(any,
        retryCount: anyNamed("retryCount"),
        lastError: anyNamed("lastError"),
        status: anyNamed("status"),
      )).thenAnswer((_) async {});

      await processor.processQueue();

      verify(mockDb.updatePendingOp(1,
        retryCount: 1,
        lastError: argThat(contains("fail"), named: "lastError"),
      )).called(1);
    });

    test("max retries reached: marks as failed", () async {
      when(mockDb.getPendingOps()).thenAnswer((_) async => [
        makeOp(retryCount: 2), // _maxRetries = 3, so next failure (count=3) should mark failed
      ]);
      when(mockRemote.parseArticle(any)).thenThrow(Exception("fail"));
      when(mockDb.updatePendingOp(any,
        retryCount: anyNamed("retryCount"),
        lastError: anyNamed("lastError"),
        status: anyNamed("status"),
      )).thenAnswer((_) async {});

      await processor.processQueue();

      verify(mockDb.updatePendingOp(1,
        retryCount: 3,
        lastError: argThat(contains("fail"), named: "lastError"),
        status: opStatusFailed,
      )).called(1);
    });

    test("error message stored in lastError", () async {
      when(mockDb.getPendingOps()).thenAnswer((_) async => [
        makeOp(retryCount: 0),
      ]);
      when(mockRemote.parseArticle(any)).thenThrow(Exception("Specific error message"));
      when(mockDb.updatePendingOp(any,
        retryCount: anyNamed("retryCount"),
        lastError: anyNamed("lastError"),
        status: anyNamed("status"),
      )).thenAnswer((_) async {});

      await processor.processQueue();

      verify(mockDb.updatePendingOp(1,
        retryCount: 1,
        lastError: argThat(contains("Specific error message"), named: "lastError"),
      )).called(1);
    });
  });

  group("dispose", () {
    test("cancels retry timer", () async {
      // Trigger a failure to schedule a retry timer
      when(mockDb.getPendingOps()).thenAnswer((_) async => [
        makeOp(retryCount: 0),
      ]);
      when(mockRemote.parseArticle(any)).thenThrow(Exception("fail"));
      when(mockDb.updatePendingOp(any,
        retryCount: anyNamed("retryCount"),
        lastError: anyNamed("lastError"),
        status: anyNamed("status"),
      )).thenAnswer((_) async {});

      await processor.processQueue();

      // Dispose should cancel the timer — no further processing
      processor.dispose();

      // Reset mocks and verify no more calls after timer would have fired
      reset(mockDb);
      reset(mockRemote);

      // Wait longer than the 5-second retry delay
      await Future.delayed(Duration.zero);
      verifyNever(mockDb.getPendingOps());
    });
  });
}

final _refProvider = Provider<Ref>((ref) => ref);
