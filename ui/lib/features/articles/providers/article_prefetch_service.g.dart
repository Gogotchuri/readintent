// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_prefetch_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Silently prefetches article detail and caches them in the background for offline playback

@ProviderFor(ArticlePrefetchService)
final articlePrefetchServiceProvider = ArticlePrefetchServiceProvider._();

/// Silently prefetches article detail and caches them in the background for offline playback
final class ArticlePrefetchServiceProvider
    extends $NotifierProvider<ArticlePrefetchService, void> {
  /// Silently prefetches article detail and caches them in the background for offline playback
  ArticlePrefetchServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'articlePrefetchServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$articlePrefetchServiceHash();

  @$internal
  @override
  ArticlePrefetchService create() => ArticlePrefetchService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$articlePrefetchServiceHash() =>
    r'580d962ea1977c4beffff91001108ac3d2a7d859';

/// Silently prefetches article detail and caches them in the background for offline playback

abstract class _$ArticlePrefetchService extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
