// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_health.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ServerHealth tracks whether the backend is reachable and healthy by polling
/// the `/health` endpoint. A response with HTTP status >= 500, a timeout, or a
/// connection error is treated as unhealthy; any response < 500 means the
/// server is reachable. Polling only happens while the device itself has a
/// network connection (the device signal already covers the offline case).

@ProviderFor(ServerHealth)
final serverHealthProvider = ServerHealthProvider._();

/// ServerHealth tracks whether the backend is reachable and healthy by polling
/// the `/health` endpoint. A response with HTTP status >= 500, a timeout, or a
/// connection error is treated as unhealthy; any response < 500 means the
/// server is reachable. Polling only happens while the device itself has a
/// network connection (the device signal already covers the offline case).
final class ServerHealthProvider extends $NotifierProvider<ServerHealth, bool> {
  /// ServerHealth tracks whether the backend is reachable and healthy by polling
  /// the `/health` endpoint. A response with HTTP status >= 500, a timeout, or a
  /// connection error is treated as unhealthy; any response < 500 means the
  /// server is reachable. Polling only happens while the device itself has a
  /// network connection (the device signal already covers the offline case).
  ServerHealthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverHealthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverHealthHash();

  @$internal
  @override
  ServerHealth create() => ServerHealth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$serverHealthHash() => r'897a6c4962aae2e5bca4f69ca3341efbb6d5ad56';

/// ServerHealth tracks whether the backend is reachable and healthy by polling
/// the `/health` endpoint. A response with HTTP status >= 500, a timeout, or a
/// connection error is treated as unhealthy; any response < 500 means the
/// server is reachable. Polling only happens while the device itself has a
/// network connection (the device signal already covers the offline case).

abstract class _$ServerHealth extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
