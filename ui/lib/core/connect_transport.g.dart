// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_transport.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(connectTransport)
final connectTransportProvider = ConnectTransportProvider._();

final class ConnectTransportProvider
    extends
        $FunctionalProvider<
          connect_p.Transport,
          connect_p.Transport,
          connect_p.Transport
        >
    with $Provider<connect_p.Transport> {
  ConnectTransportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectTransportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectTransportHash();

  @$internal
  @override
  $ProviderElement<connect_p.Transport> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  connect_p.Transport create(Ref ref) {
    return connectTransport(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(connect_p.Transport value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<connect_p.Transport>(value),
    );
  }
}

String _$connectTransportHash() => r'191fc11550421b81f2988a6b955ab2d50225f24a';
