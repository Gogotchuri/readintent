import "dart:async";
import "dart:math";

import "package:readintent_flutter/core/connectivity.dart";
import "package:readintent_flutter/features/articles/repository/article_repository.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as articles_pb;
import "package:riverpod_annotation/riverpod_annotation.dart";

part "articles_provider.g.dart";

const _minCheckInterval = Duration(seconds: 1);
const _maxCheckInterval = Duration(seconds: 15);

class ArticlesState {
  final List<articles_pb.ArticlePreview> articles;
  final bool isLoading;
  final int totalCount;
  final String? nextPageToken;
  final String? error;

  const ArticlesState({
    this.articles = const [],
    this.isLoading = false,
    this.totalCount = 0,
    this.nextPageToken,
    this.error,
  });

  bool get hasError => error != null;
  bool get hasMore => nextPageToken != null;

  ArticlesState copyWith({
    List<articles_pb.ArticlePreview>? articles,
    bool? isLoading,
    int? totalCount,
    String? nextPageToken,
    String? error,
  }) {
    return ArticlesState(
      articles: articles ?? this.articles,
      isLoading: isLoading ?? this.isLoading,
      totalCount: totalCount ?? this.totalCount,
      // Assign fields explicitly to allow null (no more pages) to be set
      nextPageToken: nextPageToken,
      error: error,
    );
  }
}

@riverpod
class Articles extends _$Articles {
  late final ArticleRepository _repository;
  static const int _pageSize = 20;

  Timer? _checkTimer;
  // Check interval starts at min and increases with backoff up to max if no updates are found
  Duration _checkInterval = _minCheckInterval;
  int _lastCheckedAt = 0;

  @override
  Future<ArticlesState> build() async {
    _repository = ref.read(articleRepositoryProvider);
    ref.onDispose(_stopChecking);

    final initialState = await _fetchInitialPage();
    _startChecking();
    return initialState;
  }

  // Fetches first page from server and updates cache. Returns the fresh data or error if fetch fails.
  Future<ArticlesState> _fetchInitialPage() async {
    try {
      final result = await _repository.getArticles(
        pageSize: _pageSize,
        onUpdated: (updated) {
          final newState = ArticlesState(
            articles: updated.articles,
            totalCount: updated.totalCount,
            nextPageToken: updated.nextPageToken.isEmpty ? null : updated.nextPageToken,
          );
          state = AsyncData(newState);
          _lastCheckedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        },
      );
      return ArticlesState(
        articles: result.articles,
        totalCount: result.totalCount,
        nextPageToken: result.nextPageToken.isEmpty ? null : result.nextPageToken,
      );
    } catch (e) {
      return ArticlesState(error: e.toString());
    }
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore || currentState.isLoading) return;
    if (!ref.read(isOnlineProvider)) return; // No pagination when offline

    state = AsyncData(currentState.copyWith(isLoading: true));
    try {
      final response = await _repository.getArticlesPage(
        pageSize: _pageSize,
        pageToken: currentState.nextPageToken,
      );
      state = AsyncData(
        ArticlesState(
          articles: [...currentState.articles, ...response.articles],
          nextPageToken: response.nextPageToken.isEmpty ? null : response.nextPageToken,
          totalCount: response.totalCount,
        ),
      );
    } catch (e) {
      state = AsyncData(currentState.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchInitialPage());
  }

  Future<ParseArticleResult> parseArticle(String url) async {
    final result = await _repository.parseArticle(url);
    await refresh();
    return result;
  }

  Future<void> deleteArticle(String id) async {
    await _repository.deleteArticle(id);
    await refresh();
  }

  // -- Update checking --

  void _startChecking() {
    _checkTimer?.cancel();
    _checkInterval = _minCheckInterval;
    if (_lastCheckedAt == 0) {
      _lastCheckedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
    _scheduleNextCheck();
  }

  void _stopChecking() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  void _scheduleNextCheck() {
    _checkTimer = Timer(_checkInterval, _performCheck);
  }

  Future<void> _performCheck() async {
    if (!ref.read(isOnlineProvider)) {
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
        // Reset check interval on non-empty response
        _checkInterval = _minCheckInterval;
        // Fetch fresh data without showing loading state
        final freshState = await _fetchFreshPage();
        if (freshState != null) {
          state = AsyncData(freshState);
        }
      } else {
        // multiply by 1.3 can't exceed max
        _checkInterval = Duration(
          milliseconds: min((_checkInterval.inMilliseconds * 1.3).round(), _maxCheckInterval.inMilliseconds),
        );
      }
    } catch (_) {
      // On error, back off and retry
      _checkInterval = _maxCheckInterval;
    }

    _scheduleNextCheck();
  }

  /// Fetches fresh articles without showing loading state (silent refresh).
  /// Fetches at least as many articles as currently visible to avoid losing loaded pages.
  Future<ArticlesState?> _fetchFreshPage() async {
    final currentCount = state.value?.articles.length ?? _pageSize;
    final fetchSize = max(currentCount, _pageSize);
    final response = await _repository.fetchFreshArticles(fetchSize);
    if (response == null) return null;
    return ArticlesState(
      articles: response.articles,
      totalCount: response.totalCount,
      nextPageToken: response.nextPageToken.isEmpty ? null : response.nextPageToken,
    );
  }
}
