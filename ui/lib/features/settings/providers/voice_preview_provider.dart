import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:flutter/services.dart" show rootBundle;
import "package:just_audio/just_audio.dart";
import "package:path_provider/path_provider.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:wav/wav.dart";

import "package:readintent_flutter/features/tts/phoneme.dart";
import "package:readintent_flutter/features/tts/pipeline.dart";
import "package:readintent_flutter/features/tts/voice_style.dart";

part "voice_preview_provider.g.dart";

const _samplePhonemesAsset = "assets/voice_samples/sample_phonemes.json";
const _sampleRate = 24000; // Kokoro output sample rate

enum VoicePreviewStatus { idle, generating, playing }

class VoicePreviewState {
  // The voice currently generating or playing, if any.
  final VoiceStyle? activeVoice;
  final VoicePreviewStatus status;
  final String? error;

  const VoicePreviewState({
    this.activeVoice,
    this.status = VoicePreviewStatus.idle,
    this.error,
  });

  bool isGenerating(VoiceStyle v) =>
      status == VoicePreviewStatus.generating && activeVoice == v;
  bool isPlaying(VoiceStyle v) =>
      status == VoicePreviewStatus.playing && activeVoice == v;
}

/// Generates short, on-device voice previews.
/// Generated WAV clips are cached in the temp dir keyed by voice.
@Riverpod(keepAlive: true)
class VoicePreview extends _$VoicePreview {
  final AudioPlayer _player = AudioPlayer();
  PhonemeChunk? _sample;
  bool _sampleLoaded = false;

  @override
  VoicePreviewState build() {
    // Reset to idle when a preview finishes playing.
    final sub = _player.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) {
        _player.stop();
        state = const VoicePreviewState();
      }
    });
    ref.onDispose(() {
      sub.cancel();
      _player.dispose();
    });
    return const VoicePreviewState();
  }

  /// Tap handler: stop if this voice is already active, otherwise preview it.
  Future<void> toggle(VoiceStyle voice) async {
    if (state.activeVoice == voice && state.status != VoicePreviewStatus.idle) {
      await stop();
      return;
    }
    await preview(voice);
  }

  Future<void> stop() async {
    await _player.stop();
    state = const VoicePreviewState();
  }

  Future<void> preview(VoiceStyle voice) async {
    if (state.status == VoicePreviewStatus.generating) return; // busy
    await _player.stop();

    final sample = await _loadSample();
    if (sample == null || sample.tokenIds.isEmpty) {
      state = VoicePreviewState(
        error: "Preview unavailable",
        activeVoice: voice,
      );
      return;
    }

    state = VoicePreviewState(
      status: VoicePreviewStatus.generating,
      activeVoice: voice,
    );
    try {
      final path = await _ensureClip(voice, sample);
      await _player.setAudioSource(AudioSource.file(path));
      state = VoicePreviewState(
        status: VoicePreviewStatus.playing,
        activeVoice: voice,
      );
      await _player.play();
    } catch (e) {
      state = VoicePreviewState(
        error: "Preview unavailable",
        activeVoice: voice,
      );
    }
  }

  /// Generates WAV clip for [voice] and returns its path.
  Future<String> _ensureClip(VoiceStyle voice, PhonemeChunk sample) async {
    final dir = await getTemporaryDirectory();
    final path = "${dir.path}/voice_preview_${voice.key}.wav";
    final file = File(path);
    if (await file.exists()) return path;

    // The factory returns a shared, memoized pipeline with [voice] already
    // downloaded and loaded, so the model session isn't duplicated per voice.
    final pipeline = await ref.read(pipelineFactoryProvider)(voice);
    final result = await pipeline.runInference(sample, voice);
    await _writeWav(path, result.audio);
    return path;
  }

  Future<void> _writeWav(String path, Float32List samples) async {
    final channel = Float64List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      channel[i] = samples[i].clamp(-1.0, 1.0).toDouble();
    }
    await Wav([channel], _sampleRate).writeFile(path);
  }

  Future<PhonemeChunk?> _loadSample() async {
    if (_sampleLoaded) return _sample;
    _sampleLoaded = true;
    try {
      final raw = await rootBundle.loadString(_samplePhonemesAsset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final tokenIds = (json["tokenIds"] as List).map((e) => e as int).toList();
      final tokenMeta = (json["tokenMeta"] as List)
          .map(
            (e) => TokenMeta(
              text: e["text"] as String,
              phonemeLen: e["phonemeLen"] as int,
              hasWhitespace: e["hasWhitespace"] as bool,
            ),
          )
          .toList();
      _sample = PhonemeChunk(
        graphemes: json["graphemes"] as String? ?? "",
        tokenIds: tokenIds,
        tokenMeta: tokenMeta,
      );
    } catch (_) {
      _sample = null; // Asset missing or not yet populated.
    }
    return _sample;
  }
}
