// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'articles_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(articlesService)
final articlesServiceProvider = ArticlesServiceProvider._();

final class ArticlesServiceProvider
    extends $FunctionalProvider<ArticlesClient, ArticlesClient, ArticlesClient>
    with $Provider<ArticlesClient> {
  ArticlesServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'articlesServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$articlesServiceHash();

  @$internal
  @override
  $ProviderElement<ArticlesClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ArticlesClient create(Ref ref) {
    return articlesService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArticlesClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArticlesClient>(value),
    );
  }
}

String _$articlesServiceHash() => r'5a0e5a0e245c1a1614d17171179224cf55767ba0';
