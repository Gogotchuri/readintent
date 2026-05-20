import "dart:async";
import "dart:convert";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:readintent_flutter/core/connectivity.dart";
import "package:readintent_flutter/core/database/app_database.dart";
import "package:readintent_flutter/features/articles/api/articles_client.dart";
import "package:readintent_flutter/features/articles/providers/articles_provider.dart";
import "package:readintent_flutter/models/operation.dart";

const _maxRetries = 3;

class PendingOperationsProcessor {
  final AppDatabase _db;
  final ArticlesClient _remote;
  final Ref _ref;
  bool _processing = false;
  Timer? _retryTimer;

  PendingOperationsProcessor(this._db, this._remote, this._ref);

  Future<void> processQueue() async {
    if (_processing) return;
    _processing = true;

    try {
      var processed = 0;
      final ops = await _db.getPendingOps();
      for (final op in ops) {
        final success = await _executeOp(op);
        if (!success) break; // Preserve FIFO order on failure
        processed++;
      }

      // Refresh article list if any ops were processed to make it referesh from server
      if (processed > 0) {
        _ref.invalidate(articlesProvider);
      }
      if (processed != ops.length) {
        // Not all ops processed, likely due to failure. Schedule retry after delay.
        // The retry count will be incremented for the failed op, so it will eventually be marked as failed after max retries
        // and stop blocking the queue.
        _retryTimer = Timer(const Duration(seconds: 5), processQueue);
      }
    } finally {
      _processing = false;
    }
  }

  // Returns true if op either failed permanently or succeeded, false if it should be retried later
  Future<bool> _executeOp(PendingOperation op) async {
    try {
      final payload = jsonDecode(op.payload) as Map<String, dynamic>;

      switch (op.type) {
        case opParseArticle:
          await _remote.parseArticle(payload["url"] as String);
          break;
        case opDeleteArticle:
          await _remote.deleteArticle(payload["article_id"] as String);
          break;
        default:
          // Unknown op type
          await _db.updatePendingOp(
            op.id,
            status: opStatusFailed,
            lastError: "Unknown: ${op.type}",
          );
          return true;
      }

      await _db.deletePendingOp(op.id);
      return true;
    } catch (e) {
      final newRetry = op.retryCount + 1;
      if (newRetry >= _maxRetries) {
        await _db.updatePendingOp(
          op.id,
          retryCount: newRetry,
          lastError: e.toString(),
          status: opStatusFailed,
        );
        return true; // Move past failed op
      }
      await _db.updatePendingOp(
        op.id,
        retryCount: newRetry,
        lastError: e.toString(),
      );
      return false; // Stop processing
    }
  }

  void dispose() {
    _retryTimer?.cancel();
  }
}

final pendingOperationsProcessorProvider = Provider<PendingOperationsProcessor>(
  (ref) {
    final db = ref.read(appDatabaseProvider);
    final remote = ref.read(articlesServiceProvider);
    return PendingOperationsProcessor(db, remote, ref);
  },
);

/// Watches connectivity and triggers queue processing when coming online.
final pendingOperationsWatcherProvider = Provider<void>((ref) {
  // Be pessimistic and assume we have no connection by default
  final isOnline =
      ref.watch(connectivityMonitorProvider).whenData((v) => v).value ?? false;
  if (isOnline) {
    final processor = ref.read(pendingOperationsProcessorProvider);
    ref.onDispose(() => processor.dispose());
    processor.processQueue();
  }
});
