// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_player_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ArticlePlayer)
final articlePlayerProvider = ArticlePlayerFamily._();

final class ArticlePlayerProvider
    extends $NotifierProvider<ArticlePlayer, ArticlePlayerState> {
  ArticlePlayerProvider._({
    required ArticlePlayerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'articlePlayerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$articlePlayerHash();

  @override
  String toString() {
    return r'articlePlayerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ArticlePlayer create() => ArticlePlayer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArticlePlayerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArticlePlayerState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ArticlePlayerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$articlePlayerHash() => r'00c2995ddf717ed6649034beb4af33f568f68233';

final class ArticlePlayerFamily extends $Family
    with
        $ClassFamilyOverride<
          ArticlePlayer,
          ArticlePlayerState,
          ArticlePlayerState,
          ArticlePlayerState,
          String
        > {
  ArticlePlayerFamily._()
    : super(
        retry: null,
        name: r'articlePlayerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ArticlePlayerProvider call(String articleId) =>
      ArticlePlayerProvider._(argument: articleId, from: this);

  @override
  String toString() => r'articlePlayerProvider';
}

abstract class _$ArticlePlayer extends $Notifier<ArticlePlayerState> {
  late final _$args = ref.$arg as String;
  String get articleId => _$args;

  ArticlePlayerState build(String articleId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ArticlePlayerState, ArticlePlayerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ArticlePlayerState, ArticlePlayerState>,
              ArticlePlayerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
