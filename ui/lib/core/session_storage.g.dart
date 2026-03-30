// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_storage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// sessionStorage is a provider that exposes an instance of SessionStorage for dependency injection

@ProviderFor(sessionStorage)
final sessionStorageProvider = SessionStorageProvider._();

/// sessionStorage is a provider that exposes an instance of SessionStorage for dependency injection

final class SessionStorageProvider
    extends $FunctionalProvider<SessionStorage, SessionStorage, SessionStorage>
    with $Provider<SessionStorage> {
  /// sessionStorage is a provider that exposes an instance of SessionStorage for dependency injection
  SessionStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionStorageHash();

  @$internal
  @override
  $ProviderElement<SessionStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SessionStorage create(Ref ref) {
    return sessionStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionStorage>(value),
    );
  }
}

String _$sessionStorageHash() => r'081a3de32fa6e123edfa1c352185bdc781a0b59a';
