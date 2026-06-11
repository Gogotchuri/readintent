// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'articles_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-view article list. One instance per [ArticleView] (inbox/favorite/
/// archive), each independently paginated. The shared [ArticleUpdatesHub] owns
/// the connection; this notifier only reacts to its broadcasts.

@ProviderFor(Articles)
final articlesProvider = ArticlesFamily._();

/// Per-view article list. One instance per [ArticleView] (inbox/favorite/
/// archive), each independently paginated. The shared [ArticleUpdatesHub] owns
/// the connection; this notifier only reacts to its broadcasts.
final class ArticlesProvider
    extends $AsyncNotifierProvider<Articles, ArticlesState> {
  /// Per-view article list. One instance per [ArticleView] (inbox/favorite/
  /// archive), each independently paginated. The shared [ArticleUpdatesHub] owns
  /// the connection; this notifier only reacts to its broadcasts.
  ArticlesProvider._({
    required ArticlesFamily super.from,
    required ArticleView? super.argument,
  }) : super(
         retry: null,
         name: r'articlesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$articlesHash();

  @override
  String toString() {
    return r'articlesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Articles create() => Articles();

  @override
  bool operator ==(Object other) {
    return other is ArticlesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$articlesHash() => r'a91648a34f1dbdcbc8fa7da3bb9343d9b05e9d22';

/// Per-view article list. One instance per [ArticleView] (inbox/favorite/
/// archive), each independently paginated. The shared [ArticleUpdatesHub] owns
/// the connection; this notifier only reacts to its broadcasts.

final class ArticlesFamily extends $Family
    with
        $ClassFamilyOverride<
          Articles,
          AsyncValue<ArticlesState>,
          ArticlesState,
          FutureOr<ArticlesState>,
          ArticleView?
        > {
  ArticlesFamily._()
    : super(
        retry: null,
        name: r'articlesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Per-view article list. One instance per [ArticleView] (inbox/favorite/
  /// archive), each independently paginated. The shared [ArticleUpdatesHub] owns
  /// the connection; this notifier only reacts to its broadcasts.

  ArticlesProvider call(ArticleView? view) =>
      ArticlesProvider._(argument: view, from: this);

  @override
  String toString() => r'articlesProvider';
}

/// Per-view article list. One instance per [ArticleView] (inbox/favorite/
/// archive), each independently paginated. The shared [ArticleUpdatesHub] owns
/// the connection; this notifier only reacts to its broadcasts.

abstract class _$Articles extends $AsyncNotifier<ArticlesState> {
  late final _$args = ref.$arg as ArticleView?;
  ArticleView? get view => _$args;

  FutureOr<ArticlesState> build(ArticleView? view);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ArticlesState>, ArticlesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ArticlesState>, ArticlesState>,
              AsyncValue<ArticlesState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
