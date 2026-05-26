// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_player_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActivePlayer)
final activePlayerProvider = ActivePlayerProvider._();

final class ActivePlayerProvider
    extends $NotifierProvider<ActivePlayer, ActivePlayerState> {
  ActivePlayerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activePlayerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activePlayerHash();

  @$internal
  @override
  ActivePlayer create() => ActivePlayer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActivePlayerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActivePlayerState>(value),
    );
  }
}

String _$activePlayerHash() => r'b2a1a53c8fececacb9563316ce0ab0faabc4804d';

abstract class _$ActivePlayer extends $Notifier<ActivePlayerState> {
  ActivePlayerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ActivePlayerState, ActivePlayerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActivePlayerState, ActivePlayerState>,
              ActivePlayerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
