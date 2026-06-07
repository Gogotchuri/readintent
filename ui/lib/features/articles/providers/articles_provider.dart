import "dart:async";
import "dart:math";

import "package:readintent_flutter/core/connectivity.dart";
import "package:readintent_flutter/features/articles/models/article_view.dart";
import "package:readintent_flutter/features/articles/providers/article_updates_hub.dart";
import "package:readintent_flutter/features/articles/repository/article_repository.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart"
    as articles_pb;
import "package:riverpod_annotation/riverpod_annotation.dart";

part "articles_provider.g.dart";

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

/// Per-view article list. One instance per [ArticleView] (inbox/favorite/
/// archive), each independently paginated. The shared [ArticleUpdatesHub] owns
/// the connection; this notifier only reacts to its broadcasts.
@riverpod
class Articles extends _$Articles {
  // Not `final`: assigned in build(), which Riverpod may re-run on the same
  // instance. `late final` would throw LateInitializationError on a rebuild.
  late ArticleRepository _repository;
  late ArticleUpdatesHub _hub;
  late ArticleView _view;
  static const int _pageSize = 20;

  @override
  Future<ArticlesState> build(ArticleView? view) async {
    _view = view ?? ArticleView.inbox; // Default to inbox if no view provided
    _repository = ref.read(articleRepositoryProvider);
    _hub = ref.watch(articleUpdatesHubProvider);

    final subs = <StreamSubscription>[
      _hub.previews.listen(_mergePreview),
      _hub.removals.listen(_removeById),
      _hub.refreshRequests.listen((_) => _resync()),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        s.cancel();
      }
    });

    return _fetchInitialPage();
  }

  // Fetches first page from server and updates cache. Returns the fresh data or error if fetch fails.
  Future<ArticlesState> _fetchInitialPage() async {
    try {
      final result = await _repository.getArticles(
        pageSize: _pageSize,
        view: _view,
        onUpdated: (updated) {
          final newState = ArticlesState(
            articles: updated.articles,
            totalCount: updated.totalCount,
            nextPageToken: updated.nextPageToken.isEmpty
                ? null
                : updated.nextPageToken,
          );
          state = AsyncData(newState);
        },
      );
      return ArticlesState(
        articles: result.articles,
        totalCount: result.totalCount,
        nextPageToken: result.nextPageToken.isEmpty
            ? null
            : result.nextPageToken,
      );
    } catch (e) {
      return ArticlesState(error: e.toString());
    }
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore || currentState.isLoading)
      return;
    if (!ref.read(isOnlineProvider)) return; // No pagination when offline

    state = AsyncData(currentState.copyWith(isLoading: true));
    try {
      final response = await _repository.getArticlesPage(
        pageSize: _pageSize,
        pageToken: currentState.nextPageToken,
        view: _view,
      );
      state = AsyncData(
        ArticlesState(
          articles: [...currentState.articles, ...response.articles],
          nextPageToken: response.nextPageToken.isEmpty
              ? null
              : response.nextPageToken,
          totalCount: response.totalCount,
        ),
      );
    } catch (e) {
      state = AsyncData(
        currentState.copyWith(isLoading: false, error: e.toString()),
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchInitialPage());
  }

  Future<ParseArticleResult> parseArticle(String url) => _hub.parseArticle(url);

  Future<void> deleteArticle(String id) => _hub.deleteArticle(id);

  Future<void> setArticleState(
    String id, {
    ArticleListState? listState,
    bool? isFavorite,
  }) => _hub.setArticleState(id, listState: listState, isFavorite: isFavorite);

  /// Refetches the first page with no loading state after a reconnect or
  /// poll-detected update, recovering changes missed while disconnected.
  Future<void> _resync() async {
    final freshState = await _fetchFreshPage();
    if (freshState != null) state = AsyncData(freshState);
  }

  /// Fetches fresh articles without showing loading state (silent refresh).
  /// Fetches at least as many articles as currently visible to avoid losing loaded pages.
  Future<ArticlesState?> _fetchFreshPage() async {
    final currentCount = state.value?.articles.length ?? _pageSize;
    final fetchSize = max(currentCount, _pageSize);
    final response = await _repository.fetchFreshArticles(fetchSize, _view);
    if (response == null) return null;
    return ArticlesState(
      articles: response.articles,
      totalCount: response.totalCount,
      nextPageToken: response.nextPageToken.isEmpty
          ? null
          : response.nextPageToken,
    );
  }

  /// Merges a single preview into this view
  void _mergePreview(articles_pb.ArticlePreview preview) {
    final current = state.value;
    if (current == null) return;

    final belongs = _view.contains(preview);
    final articles = [...current.articles];
    final idx = articles.indexWhere((a) => a.id == preview.id);
    final present = idx >= 0;

    int delta = 0;
    if (belongs && !present) {
      articles.insert(0, preview);
      delta = 1;
    } else if (belongs && present) {
      articles[idx] = preview;
    } else if (!belongs && present) {
      articles.removeAt(idx);
      delta = -1;
    } else {
      return; // doesn't belong and isn't present
    }
    // Build explicitly to preserve nextPageToken.
    state = AsyncData(
      ArticlesState(
        articles: articles,
        totalCount: current.totalCount + delta,
        nextPageToken: current.nextPageToken,
      ),
    );
  }

  /// Drops a deleted article from this view if present.
  void _removeById(int id) {
    final current = state.value;
    if (current == null) return;
    final idx = current.articles.indexWhere((a) => a.id.toInt() == id);
    if (idx < 0) return;
    final articles = [...current.articles]..removeAt(idx);
    state = AsyncData(
      ArticlesState(
        articles: articles,
        totalCount: max(0, current.totalCount - 1),
        nextPageToken: current.nextPageToken,
      ),
    );
  }
}
