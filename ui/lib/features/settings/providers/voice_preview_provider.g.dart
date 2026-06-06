// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_preview_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Generates short, on-device voice previews.
/// Generated WAV clips are cached in the temp dir keyed by voice.

@ProviderFor(VoicePreview)
final voicePreviewProvider = VoicePreviewProvider._();

/// Generates short, on-device voice previews.
/// Generated WAV clips are cached in the temp dir keyed by voice.
final class VoicePreviewProvider
    extends $NotifierProvider<VoicePreview, VoicePreviewState> {
  /// Generates short, on-device voice previews.
  /// Generated WAV clips are cached in the temp dir keyed by voice.
  VoicePreviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voicePreviewProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voicePreviewHash();

  @$internal
  @override
  VoicePreview create() => VoicePreview();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoicePreviewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoicePreviewState>(value),
    );
  }
}

String _$voicePreviewHash() => r'3f218c1aa78c53d56649f623b2e4e44ef5ca588b';

/// Generates short, on-device voice previews.
/// Generated WAV clips are cached in the temp dir keyed by voice.

abstract class _$VoicePreview extends $Notifier<VoicePreviewState> {
  VoicePreviewState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<VoicePreviewState, VoicePreviewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VoicePreviewState, VoicePreviewState>,
              VoicePreviewState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
