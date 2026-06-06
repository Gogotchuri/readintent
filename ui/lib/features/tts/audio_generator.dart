import "dart:async";
import "dart:io";

import "package:readintent_flutter/features/tts/audio_cache.dart";
import "package:readintent_flutter/features/tts/growing_audio_file.dart";
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

  final PipelineFactory _pipelineFactory;
  TTSPipeline? _pipeline;
  GrowingAudioFile? _audioFile;
  bool _disposed = false;
  List<WordTimestamp> _wordTimestamps = [];
  double _accumulatedSeconds = 0.0;

  final StreamController<TTSSessionState> _stateController =
      StreamController<TTSSessionState>.broadcast();
  TTSSessionState _state = const TTSSessionState();

  AudioGenerator({
    required this.article,
    required this.voice,
    required this.speed,
    required this.cache,
    required PipelineFactory pipelineFactory,
  }) : _pipelineFactory = pipelineFactory {
    cacheKey = cache.cacheKey(
      articleId: article.id.toString(),
      articleText: article.pureText,
      voice: voice.key,
      speed: speed,
    );

    chunks = protoToChunks(article.phonemizerData);
  }

  Stream<TTSSessionState> get stateStream => _stateController.stream;
  TTSSessionState get currentState => _state;
  String? get filePath => _audioFile?.filePath;
  Duration get bufferedDuration =>
      _audioFile?.bufferedDuration ?? Duration.zero;
  bool get isComplete => _state.isComplete;
  Stream<Duration>? get bufferedDurationStream =>
      _audioFile?.bufferedDurationStream;
  List<WordTimestamp> get wordTimestamps => List.unmodifiable(_wordTimestamps);

  /// Returns the cache path if a complete (no .meta companion) file is cached.
  Future<String?> checkCacheForComplete() async {
    final cached = await cache.load(cacheKey);
    if (cached == null) return null;
    // A .meta file means generation was interrupted - not complete
    if (File("${cached.path}.meta").existsSync()) return null;
    return cached.path;
  }

  /// Run TTS generation. Calls [onBufferReady] once the buffer threshold is reached. Can be called multiple times if the buffer is consumed and more generation is needed.
  Future<void> generate({
    Duration bufferThreshold = const Duration(seconds: 10),
    required Future<void> Function() onBufferReady,
  }) async {
    if (_disposed) return;

    // Setup audio file (resume if possible) and get the starting chunk index
    final startIndex = await _initAudioFile();
    _emitState(_state.copyWith(bufferedDuration: _audioFile!.bufferedDuration));

    try {
      await _ensurePipeline();
      if (_disposed) return;

      final totalTokens = chunks.fold<int>(
        0,
        (sum, c) => sum + c.tokenIds.length,
      );
      int processedTokens = 0;
      for (int i = 0; i < startIndex && i < chunks.length; i++) {
        processedTokens += chunks[i].tokenIds.length;
      }

      bool bufferReadyCalled = false;

      // If we are resuming from a previous session, we might already have enough buffered audio
      if (startIndex > 0) {
        await _restoreResumeState();
        bufferReadyCalled = true;
        await onBufferReady();
      }

      for (int i = startIndex; i < chunks.length; i++) {
        if (_disposed) return;

        processedTokens += chunks[i].tokenIds.length;
        final result = await _pipeline!.runInference(chunks[i], voice);
        if (_disposed) return;

        _appendTimestamps(result.timestamps);
        await _audioFile!.addChunk(result.audio, i);
        _accumulatedSeconds =
            _audioFile!.bufferedDuration.inMilliseconds / 1000.0;
        // Save timestamps incrementally so they survive interrupted generation
        await cache.saveTimestamps(cacheKey, _wordTimestamps);
        _updateEstimation(processedTokens, totalTokens);

        // Call onBufferReady if we have reached the threshold and haven't called it since the last chunk was added
        if (!bufferReadyCalled &&
            _audioFile!.bufferedDuration >= bufferThreshold) {
          bufferReadyCalled = true;
          await onBufferReady();
        }
      }

      if (!bufferReadyCalled && !_disposed) {
        await onBufferReady();
      }

      if (!_disposed) await _finalizeGeneration();
    } catch (e) {
      if (!_disposed) {
        _emitState(_state.copyWith(error: e.toString()));
      }
      rethrow;
    }
  }

  /// Sets up or resumes the audio file. Returns the chunk index to start from.
  Future<int> _initAudioFile() async {
    final cachePath = await cache.pathForKey(cacheKey);
    final resumed = GrowingAudioFile.tryResume(cachePath);
    if (resumed != null) {
      _audioFile = resumed;
      return resumed.lastEncodedChunkIndex + 1;
    }
    _audioFile = GrowingAudioFile(filePath: cachePath);
    return 0;
  }

  /// Restores accumulated seconds and cached timestamps when resuming.
  Future<void> _restoreResumeState() async {
    _accumulatedSeconds = _audioFile!.bufferedDuration.inMilliseconds / 1000.0;
    final cachedTs = await cache.loadTimestamps(cacheKey);
    if (cachedTs != null) {
      _wordTimestamps = cachedTs;
    }
  }

  /// Offsets chunk-local timestamps by [_accumulatedSeconds] and appends them.
  void _appendTimestamps(List<WordTimestamp> chunkTimestamps) {
    for (final wt in chunkTimestamps) {
      _wordTimestamps.add(
        WordTimestamp(
          word: wt.word,
          start: wt.start + _accumulatedSeconds,
          end: wt.end + _accumulatedSeconds,
        ),
      );
    }
  }

  /// Finalizes the audio file, saves timestamps, and emits completion.
  Future<void> _finalizeGeneration() async {
    await _audioFile!.finalize();
    await cache.saveTimestamps(cacheKey, _wordTimestamps);
    await cache.evictIfNeeded();

    _emitState(
      _state.copyWith(
        isComplete: true,
        bufferedDuration: _audioFile!.bufferedDuration,
        estimatedDuration: _audioFile!.bufferedDuration,
      ),
    );
  }

  Future<List<WordTimestamp>?> loadCachedTimestamps() =>
      cache.loadTimestamps(cacheKey);

  Future<void> _ensurePipeline() async {
    _pipeline ??= await _pipelineFactory(voice);
  }

  void _updateEstimation(int processedTokens, int totalTokens) {
    if (_audioFile == null || processedTokens == 0) return;
    final generatedMs = _audioFile!.bufferedDuration.inMilliseconds;
    final estimatedTotalMs = (generatedMs * totalTokens / processedTokens)
        .round();
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

List<PhonemeChunk> protoToChunks(List<PhonemizerData> protoChunks) {
  //TODO investigate why some token ids are empty
  return protoChunks.where((pd) => pd.tokenIds.isNotEmpty).map((pd) {
    return PhonemeChunk(
      graphemes: pd.graphemes,
      tokenIds: pd.tokenIds.map((id) => id.toInt()).toList(),
      tokenMeta: pd.tokenMeta
          .map(
            (m) => TokenMeta(
              text: m.text,
              phonemeLen: m.phonemeLen,
              hasWhitespace: m.hasWhitespace,
            ),
          )
          .toList(),
    );
  }).toList();
}
