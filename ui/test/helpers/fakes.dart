import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:audio_service/audio_service.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:just_audio/just_audio.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
import "package:plugin_platform_interface/plugin_platform_interface.dart";

import "package:readintent_flutter/core/connectivity.dart";
import "package:readintent_flutter/core/player_persistence.dart";
import "package:readintent_flutter/features/auth/providers/auth_provider.dart";
import "package:readintent_flutter/features/tts/audio_handler.dart";
import "package:readintent_flutter/features/tts/phoneme.dart";
import "package:readintent_flutter/features/tts/pipeline.dart";
import "package:readintent_flutter/features/tts/voice_style.dart";
import "package:readintent_flutter/models/auth_state.dart";

// --- FakeAudioHandler ---

class FakeAudioHandler implements AudioHandlerInterface {
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<PlayerState> _playerStateController = StreamController<PlayerState>.broadcast();

  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration? sourceDuration;

  String? lastSourcePath;
  MediaItem? lastMediaItem;
  final List<String> calls = [];

  @override
  Stream<Duration> get positionStream => _positionController.stream;
  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  @override
  bool get isPlaying => _isPlaying;
  @override
  Duration get currentPosition => _currentPosition;

  @override
  Future<Duration?> setSource(String filePath, {MediaItem? tag}) async {
    calls.add("setSource");
    lastSourcePath = filePath;
    if (tag != null) lastMediaItem = tag;
    return sourceDuration;
  }

  @override
  Future<void> play() async {
    calls.add("play");
    _isPlaying = true;
    _emitPlayerState(ProcessingState.ready);
  }

  @override
  Future<void> pause() async {
    calls.add("pause");
    _isPlaying = false;
    _emitPlayerState(ProcessingState.ready);
  }

  @override
  Future<void> stop() async {
    calls.add("stop");
    _isPlaying = false;
    _currentPosition = Duration.zero;
  }

  @override
  Future<void> seek(Duration position) async {
    calls.add("seek");
    _currentPosition = position;
  }

  @override
  Future<void> setSpeed(double speed) async {
    calls.add("setSpeed");
  }

  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    calls.add("updateMediaItem");
    lastMediaItem = mediaItem;
  }

  void emitPosition(Duration position) {
    _currentPosition = position;
    _positionController.add(position);
  }

  void simulateProcessingState(ProcessingState processingState) {
    _emitPlayerState(processingState);
  }

  void _emitPlayerState(ProcessingState processingState) {
    _playerStateController.add(PlayerState(_isPlaying, processingState));
  }

  Future<void> dispose() async {
    await _positionController.close();
    await _playerStateController.close();
  }
}

// --- FakeTTSPipeline ---

class FakeTTSPipeline implements TTSPipeline {
  final Float32List Function(PhonemeChunk chunk) _audioProducer;

  FakeTTSPipeline(this._audioProducer);

  @override
  Future<KokoroResult> runInference(PhonemeChunk chunk, VoiceStyle style) async {
    final audio = _audioProducer(chunk);
    return KokoroResult(
      audio: audio,
      timestamps: [WordTimestamp(word: chunk.graphemes, start: 0.0, end: audio.length / 24000.0)],
      graphemes: chunk.graphemes,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PipelineFactory fakePipelineFactory(Float32List Function(PhonemeChunk chunk) audioProducer) {
  return (VoiceStyle voiceStyle) async => FakeTTSPipeline(audioProducer);
}

/// Produces silence proportional to token count: ~0.5s per 100 tokens (12000 samples).
Float32List defaultAudioProducer(PhonemeChunk chunk) {
  final samplesPerToken = 120; // ~5ms per token at 24kHz
  final length = chunk.tokenIds.length * samplesPerToken;
  return Float32List(length);
}

// --- FakePathProvider ---

class FakePathProvider extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  final Directory tempDir;
  FakePathProvider(this.tempDir);

  @override
  Future<String?> getApplicationSupportPath() async => tempDir.path;

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;
}

// --- Test Container Helper ---

ProviderContainer createTestContainer({
  required FakeAudioHandler handler,
  PipelineFactory? pipelineFactory,
  PlayerPersistence? persistence,
}) {
  return ProviderContainer(
    overrides: [
      audioHandlerProvider.overrideWithValue(handler),
      if (pipelineFactory != null) pipelineFactoryProvider.overrideWithValue(pipelineFactory),
      if (persistence != null) playerPersistenceProvider.overrideWithValue(persistence),
      authProvider.overrideWithValue(const AuthInitial()),
      // Avoid hitting the real connectivity_plus plugin
      connectivityMonitorProvider.overrideWith((ref) => Stream.value(true)),
    ],
  );
}
