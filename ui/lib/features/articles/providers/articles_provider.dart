import "package:readintent_flutter/core/connectivity.dart";
import "package:readintent_flutter/features/articles/repository/article_repository.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as articles_pb;
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

@riverpod
class Articles extends _$Articles {
  late final ArticleRepository _repository;
  static const int _pageSize = 20;

  @override
  Future<ArticlesState> build() async {
    _repository = ref.read(articleRepositoryProvider);
    return _fetchInitialPage();
  }

  // Fetches first page from server and updates cache. Returns the fresh data or error if fetch fails.
  Future<ArticlesState> _fetchInitialPage() async {
    try {
      final result = await _repository.getArticles(
        pageSize: _pageSize,
        onUpdated: (updated) {
          state = AsyncData(
            ArticlesState(
              articles: updated.articles,
              totalCount: updated.totalCount,
              nextPageToken: updated.nextPageToken.isEmpty ? null : updated.nextPageToken,
            ),
          );
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
}
