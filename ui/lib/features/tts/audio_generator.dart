import "dart:async";
import "dart:io";

import "package:readintent_flutter/features/tts/audio_cache.dart";
import "package:readintent_flutter/features/tts/growing_audio_file.dart";
import "package:readintent_flutter/features/tts/model_downloader.dart";
import "package:readintent_flutter/features/tts/phoneme.dart";
import "package:readintent_flutter/features/tts/pipeline.dart";
import "package:readintent_flutter/features/tts/voice_style.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart";

class TTSSessionState {
  final Duration bufferedDuration;
  final Duration? estimatedDuration;
  final bool isComplete;
  final String? error;

  const TTSSessionState({
    this.bufferedDuration = Duration.zero,
    this.estimatedDuration,
    this.isComplete = false,
    this.error,
  });

  TTSSessionState copyWith({
    Duration? bufferedDuration,
    Duration? estimatedDuration,
    bool? isComplete,
    String? error,
  }) {
    return TTSSessionState(
      bufferedDuration: bufferedDuration ?? this.bufferedDuration,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      isComplete: isComplete ?? this.isComplete,
      error: error ?? this.error,
    );
  }
}

/// Orchestrates TTS generation for a single article.
/// Owns the pipeline and GrowingAudioFile.
class AudioGenerator {
  late final List<PhonemeChunk> chunks;
  final Article article;
  final VoiceStyle voice;
  final double speed;
  late final String cacheKey;
  final AudioCache cache;

  TTSPipeline? _pipeline;
  GrowingAudioFile? _audioFile;
  bool _disposed = false;

  final StreamController<TTSSessionState> _stateController = StreamController<TTSSessionState>.broadcast();
  TTSSessionState _state = const TTSSessionState();

  AudioGenerator({required this.article, required this.voice, required this.speed, required this.cache}) {
    cacheKey = cache.cacheKey(
      articleId: article.id.toString(),
      articleText: article.pureText,
      voice: voice.key,
      speed: speed,
    );

    chunks = _protoToChunks(article.phonemizerData);
  }

  Stream<TTSSessionState> get stateStream => _stateController.stream;
  TTSSessionState get currentState => _state;
  String? get filePath => _audioFile?.filePath;
  Duration get bufferedDuration => _audioFile?.bufferedDuration ?? Duration.zero;
  bool get isComplete => _state.isComplete;
  Stream<Duration>? get bufferedDurationStream => _audioFile?.bufferedDurationStream;

  /// Returns the cache path if a complete (no .meta companion) file is cached.
  Future<String?> checkCacheForComplete() async {
    final cached = await cache.load(cacheKey);
    if (cached == null) return null;
    // A .meta file means generation was interrupted — not complete
    if (File("${cached.path}.meta").existsSync()) return null;
    return cached.path;
  }

  /// Run TTS generation. Calls [onBufferReady] once the buffer threshold is reached.
  Future<void> generate({
    Duration bufferThreshold = const Duration(seconds: 10),
    required Future<void> Function() onBufferReady,
  }) async {
    if (_disposed) return;

    final cachePath = await cache.pathForKey(cacheKey);

    // Try resume
    final resumed = GrowingAudioFile.tryResume(cachePath);
    final int startIndex;
    if (resumed != null) {
      _audioFile = resumed;
      startIndex = resumed.lastEncodedChunkIndex + 1;
    } else {
      _audioFile = GrowingAudioFile(filePath: cachePath);
      startIndex = 0;
    }

    _emitState(_state.copyWith(bufferedDuration: _audioFile!.bufferedDuration));

    try {
      await _ensurePipeline();
      if (_disposed) return;

      final totalTokens = chunks.fold<int>(0, (sum, c) => sum + c.tokenIds.length);
      int processedTokens = 0;
      // Count tokens from already-processed chunks for estimation
      for (int i = 0; i < startIndex && i < chunks.length; i++) {
        processedTokens += chunks[i].tokenIds.length;
      }

      bool bufferReadyCalled = false;

      // If resuming, we already have playable audio — start the player immediately
      if (startIndex > 0) {
        bufferReadyCalled = true;
        await onBufferReady();
      }

      for (int i = startIndex; i < chunks.length; i++) {
        if (_disposed) return;

        processedTokens += chunks[i].tokenIds.length;
        final result = await _pipeline!.runInference(chunks[i], voice);
        if (_disposed) return;

        await _audioFile!.addChunk(result.audio, i);
        _updateEstimation(processedTokens, totalTokens);

        if (!bufferReadyCalled && _audioFile!.bufferedDuration >= bufferThreshold) {
          bufferReadyCalled = true;
          await onBufferReady();
        }
      }

      // If we never reached threshold, start anyway
      if (!bufferReadyCalled && !_disposed) {
        await onBufferReady();
      }

      if (_disposed) return;

      await _audioFile!.finalize();
      await cache.evictIfNeeded();

      _emitState(
        _state.copyWith(
          isComplete: true,
          bufferedDuration: _audioFile!.bufferedDuration,
          estimatedDuration: _audioFile!.bufferedDuration,
        ),
      );
    } catch (e) {
      if (!_disposed) {
        _emitState(_state.copyWith(error: e.toString()));
      }
      rethrow;
    }
  }

  Future<void> _ensurePipeline() async {
    final assetPaths = await KokoroDownloader.ensureAssets(modelType: ModelType.q4, voiceStyle: voice);
    _pipeline ??= await TTSPipeline.create(assetPaths);
  }

  void _updateEstimation(int processedTokens, int totalTokens) {
    if (_audioFile == null || processedTokens == 0) return;
    final generatedMs = _audioFile!.bufferedDuration.inMilliseconds;
    final estimatedTotalMs = (generatedMs * totalTokens / processedTokens).round();
    _emitState(
      _state.copyWith(
        estimatedDuration: Duration(milliseconds: estimatedTotalMs),
        bufferedDuration: _audioFile!.bufferedDuration,
      ),
    );
  }

  void _emitState(TTSSessionState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _audioFile?.dispose();
    _audioFile = null;
    await _stateController.close();
  }
}

List<PhonemeChunk> _protoToChunks(List<PhonemizerData> protoChunks) {
  //TODO investigate why some token ids are empty
  return protoChunks.where((pd) => pd.tokenIds.isNotEmpty).map((pd) {
    return PhonemeChunk(
      graphemes: pd.graphemes,
      tokenIds: pd.tokenIds.map((id) => id.toInt()).toList(),
      tokenMeta: pd.tokenMeta
          .map((m) => TokenMeta(text: m.text, phonemeLen: m.phonemeLen, hasWhitespace: m.hasWhitespace))
          .toList(),
    );
  }).toList();
}
