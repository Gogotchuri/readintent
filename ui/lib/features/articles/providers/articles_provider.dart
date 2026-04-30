import "package:readintent_flutter/features/articles/api/articles_client.dart";
import "package:readintent_flutter/features/articles/api/articles_client_exceptions.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as articles_pb;
import "package:riverpod_annotation/riverpod_annotation.dart";

part "articles_provider.g.dart";

// State class to hold the list of articles and loading/error states
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
      nextPageToken: nextPageToken ?? this.nextPageToken,
      error: error ?? this.error,
    );
  }
}

@riverpod
class Articles extends _$Articles {
  late final ArticlesClient _articlesClient;
  static const int _pageSize = 20;

  @override
  Future<ArticlesState> build() async {
    _articlesClient = ref.read(articlesServiceProvider);
    return _fetchInitialPage();
  }

  Future<ArticlesState> _fetchInitialPage() async {
    try {
      final response = await _articlesClient.getArticles(pageSize: _pageSize);
      return ArticlesState(
        articles: response.articles,
        totalCount: response.totalCount,
        nextPageToken: response.nextPageToken,
      );
    } catch (e) {
      return ArticlesState(error: e.toString());
    }
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore || currentState.isLoading) return;

    state = AsyncData(currentState.copyWith(isLoading: true));
    try {
      final response = await _articlesClient.getArticles(
        pageSize: _pageSize,
        pageToken: currentState.nextPageToken,
      );
      state = AsyncData(
        ArticlesState(
          articles: [...currentState.articles, ...response.articles],
          nextPageToken: response.nextPageToken,
          totalCount: response.totalCount,
        ),
      );
    } on ArticlesException catch (e) {
      state = AsyncData(currentState.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _fetchInitialPage());
    } on ArticlesException catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> parseArticle(String url) async {
    await _articlesClient.parseArticle(url);
    await refresh();
  }
}
