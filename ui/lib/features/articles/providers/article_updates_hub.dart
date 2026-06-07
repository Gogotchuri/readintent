import "dart:async";
import "dart:math";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:readintent_flutter/core/connectivity.dart";
import "package:readintent_flutter/features/articles/models/article_view.dart";
import "package:readintent_flutter/features/articles/providers/article_updates_channel.dart";
import "package:readintent_flutter/features/articles/repository/article_repository.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart"
    as articles_pb;

// Polling fallback cadence (used only when stream is unavailable).
const _minCheckInterval = Duration(seconds: 1);
const _maxCheckInterval = Duration(seconds: 30);

/// Owns the single article-update connection shared by every list view: one
/// push stream (+ polling fallback) and the article-mutation actions. Pushed
/// previews are persisted once here and re-broadcast
class ArticleUpdatesHub {
  ArticleUpdatesHub(this._repository, this._isOnline) {
    _channel = ArticleUpdatesChannel(
      connect: _repository.streamArticleUpdates,
      isOnline: _isOnline,
    );
    _channelSubs = <StreamSubscription>[
      _channel.previews.listen(_onPushedPreview),
      _channel.resyncRequests.listen((_) => _emitRefresh()),
      _channel.pollingMode.listen(
        (poll) => poll ? _startChecking() : _stopChecking(),
      ),
    ];
    _lastCheckedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _channel.start();
  }

  final ArticleRepository _repository;
  final bool Function() _isOnline;

  late final ArticleUpdatesChannel _channel;
  late final List<StreamSubscription> _channelSubs;

  final _previews = StreamController<articles_pb.ArticlePreview>.broadcast();
  final _refreshRequests = StreamController<void>.broadcast();
  final _removals = StreamController<int>.broadcast();

  Timer? _checkTimer;
  Duration _checkInterval = _minCheckInterval;
  int _lastCheckedAt = 0;
  bool _pollingActive = false;

  Stream<articles_pb.ArticlePreview> get previews => _previews.stream;

  /// Fires when views should refetch their first page
  Stream<void> get refreshRequests => _refreshRequests.stream;

  /// Emits an article id that has been deleted, so every view drops it.
  Stream<int> get removals => _removals.stream;

  // Actions
  Future<ParseArticleResult> parseArticle(String url) =>
      _repository.parseArticle(url);

  /// Deletes an article and tells every view to drop it.
  Future<void> deleteArticle(String id) async {
    await _repository.deleteArticle(id);
    final intId = int.tryParse(id);
    if (intId != null) _emit(_removals, intId);
  }

  /// Moves an article between lists or toggles its favorite flag
  Future<void> setArticleState(
    String id, {
    ArticleListState? listState,
    bool? isFavorite,
  }) async {
    final updated = await _repository.setArticleState(
      id,
      listState: listState,
      isFavorite: isFavorite,
    );
    // Already persisted by the repository; just broadcast
    if (updated != null) _emit(_previews, updated);
  }

  // Connection lifecycle
  void onConnectivity(bool online) => _channel.onConnectivity(online);

  /// Suspends all background activity while the app is backgrounded.
  void suspend() {
    _channel.suspend();
    _stopChecking();
  }

  /// Resumes streaming when the app returns to the foreground.
  void resume() => _channel.resume();

  Future<void> dispose() async {
    for (final s in _channelSubs) {
      await s.cancel();
    }
    _stopChecking();
    await _channel.dispose();
    await _previews.close();
    await _refreshRequests.close();
    await _removals.close();
  }

  // -- Push handling --

  void _onPushedPreview(articles_pb.ArticlePreview preview) {
    // Persist once, centrally, so the three views don't each write the row.
    _repository.upsertPreviewFromUpdate(preview).catchError((_) {});
    _emit(_previews, preview);
    _lastCheckedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  // -- Polling fallback (active only while the channel reports pollingMode) --

  void _startChecking() {
    _checkTimer?.cancel();
    _pollingActive = true;
    _checkInterval = _minCheckInterval;
    if (_lastCheckedAt == 0) {
      _lastCheckedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
    _scheduleNextCheck();
  }

  void _stopChecking() {
    _pollingActive = false;
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  void _scheduleNextCheck() {
    if (!_pollingActive) return;
    _checkTimer = Timer(_checkInterval, _performCheck);
  }

  Future<void> _performCheck() async {
    if (!_isOnline()) {
      _scheduleNextCheck();
      return;
    }
    try {
      final response = await _repository.checkForUpdates(_lastCheckedAt);
      if (response == null) {
        _scheduleNextCheck();
        return;
      }
      if (response.hasUpdates) {
        _lastCheckedAt = response.serverTimestamp.toInt();
        _checkInterval = _minCheckInterval;
        // Each view refetches its own first page.
        _emitRefresh();
      } else {
        // Back off up to the max while idle.
        _checkInterval = Duration(
          milliseconds: min(
            (_checkInterval.inMilliseconds * 1.3).round(),
            _maxCheckInterval.inMilliseconds,
          ),
        );
      }
    } catch (_) {
      _checkInterval = _maxCheckInterval;
    }
    _scheduleNextCheck();
  }

  void _emitRefresh() => _emit(_refreshRequests, null);

  void _emit<T>(StreamController<T> controller, T value) {
    if (!controller.isClosed) controller.add(value);
  }
}

/// Single shared hub for the whole session. Non-autoDispose so the push stream
/// stays connected across tab switches and detail screens.
final articleUpdatesHubProvider = Provider<ArticleUpdatesHub>((ref) {
  final repository = ref.read(articleRepositoryProvider);
  final hub = ArticleUpdatesHub(repository, () => ref.read(isOnlineProvider));
  ref.listen(isOnlineProvider, (_, online) => hub.onConnectivity(online));
  ref.onDispose(hub.dispose);
  return hub;
});
