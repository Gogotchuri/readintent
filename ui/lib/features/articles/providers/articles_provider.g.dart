// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'articles_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Articles)
final articlesProvider = ArticlesProvider._();

final class ArticlesProvider
    extends $AsyncNotifierProvider<Articles, ArticlesState> {
  ArticlesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'articlesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$articlesHash();

  @$internal
  @override
  Articles create() => Articles();
}

String _$articlesHash() => r'bbdefeb804b014f2de487fbb6e0946dd0f85b5ff';

abstract class _$Articles extends $AsyncNotifier<ArticlesState> {
  FutureOr<ArticlesState> build();
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
    element.handleCreate(ref, build);
  }
}
