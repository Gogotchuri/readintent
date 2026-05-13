import "dart:async";
import "dart:io";

import "package:audio_service/audio_service.dart";
import "package:just_audio/just_audio.dart";
import "package:path_provider/path_provider.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "package:readintent_flutter/features/tts/audio_cache.dart";
import "package:readintent_flutter/features/tts/audio_handler.dart";
import "package:readintent_flutter/features/tts/growing_audio_file.dart";
import "package:readintent_flutter/features/tts/model_downloader.dart";
import "package:readintent_flutter/features/tts/phoneme.dart";
import "package:readintent_flutter/features/tts/pipeline.dart";
import "package:readintent_flutter/features/tts/voice_style.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as articles_pb;

part "article_player_provider.g.dart";

class ArticlePlayerState {
  final Duration position;
  final Duration bufferedDuration;
  final Duration? estimatedDuration;
  final bool isPlaying;
  final bool isLoading;
  final bool ttsComplete;
  final String? error;

  const ArticlePlayerState({
    this.position = Duration.zero,
    this.bufferedDuration = Duration.zero,
    this.estimatedDuration,
    this.isPlaying = false,
    this.isLoading = false,
    this.ttsComplete = false,
    this.error,
  });

  ArticlePlayerState copyWith({
    Duration? position,
    Duration? bufferedDuration,
    Duration? estimatedDuration,
    bool? isPlaying,
    bool? isLoading,
    bool? ttsComplete,
    String? error,
  }) {
    return ArticlePlayerState(
      position: position ?? this.position,
      bufferedDuration: bufferedDuration ?? this.bufferedDuration,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      ttsComplete: ttsComplete ?? this.ttsComplete,
      error: error ?? this.error,
    );
  }
}

@riverpod
class ArticlePlayer extends _$ArticlePlayer {
  final AudioCache _cache = AudioCache();
  late final AppAudioHandler _handler;
  GrowingAudioFile? _liveStream;
  StreamSubscription? _positionSub;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _bufferedSub;
  TTSPipeline? _pipeline;
  String? _cumulativeFilePath;
  bool _generating = false;
  Duration _loadedDuration = Duration.zero;
  bool _reloading = false;
  bool _waitingForBuffer = false;
  bool _playerStarted = false;
  MediaItem? _mediaItem;

  @override
  ArticlePlayerState build(String articleId) {
    _handler = ref.read(audioHandlerProvider);
    ref.onDispose(_cleanup);
    return const ArticlePlayerState();
  }

  void _cleanup() {
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _bufferedSub?.cancel();
    _handler.stop();
    _liveStream?.dispose();
    _liveStream = null;
    _loadedDuration = Duration.zero;
    _reloading = false;
    _waitingForBuffer = false;
    _playerStarted = false;
    _mediaItem = null;
    if (_cumulativeFilePath != null) {
      File(_cumulativeFilePath!).delete().ignore();
      _cumulativeFilePath = null;
    }
  }

  MediaItem _buildMediaItem(articles_pb.Article article) {
    return MediaItem(
      id: article.title,
      title: article.title,
      artist: article.author.isNotEmpty ? article.author : null,
      album: "ReadIntent",
    );
  }

  Future<void> play({
    required articles_pb.Article article,
    VoiceStyle voice = VoiceStyle.afSky,
    double speed = 1.0,
  }) async {
    if (_generating) return;

    _cleanup();
    _wirePlayerListeners();

    state = const ArticlePlayerState(isLoading: true);
    final articleText = article.pureText;
    final key = _cache.cacheKey(
      articleId: articleId,
      articleText: articleText,
      voice: voice.key,
      speed: speed,
    );

    final cachedFile = await _cache.load(key);
    if (cachedFile != null) {
      await _playFromFile(cachedFile.path, article);
      return;
    }

    await _generateAndPlay(article: article, voice: voice, speed: speed, cacheKey: key);
  }

  Future<void> _playFromFile(String path, articles_pb.Article article) async {
    final tag = _buildMediaItem(article);
    final duration = await _handler.setSource(path, tag: tag);
    state = state.copyWith(
      isLoading: false,
      ttsComplete: true,
      estimatedDuration: duration,
      bufferedDuration: duration ?? Duration.zero,
    );
    _playerStarted = true;
    await _handler.play();
  }

  Future<void> _generateAndPlay({
    required articles_pb.Article article,
    required VoiceStyle voice,
    required double speed,
    required String cacheKey,
  }) async {
    _generating = true;
    final tempDir = await getTemporaryDirectory();
    _cumulativeFilePath = "${tempDir.path}/readintent_tts_${articleId}_cumulative.mp3";

    try {
      await _ensurePipeline(voice);
      final chunks = _protoToChunks(article.phonemizerData);
      final totalTokens = _totalTokens(chunks);
      _setupLiveStream();
      _mediaItem = _buildMediaItem(article);

      bool playerStarted = false;
      int processedTokens = 0;

      for (int i = 0; i < chunks.length; i++) {
        if (_liveStream == null) break;
        processedTokens += chunks[i].tokenIds.length;
        await _generateNextChunk(chunks[i], voice, processedTokens, totalTokens);

        // Start playback once we have enough audio
        if (!playerStarted &&
            _liveStream != null &&
            _liveStream!.bufferedDuration >= const Duration(seconds: 10)) {
          // TODO configurable threshold, remove magic number
          await _startPlayer();
          playerStarted = true;
        }
      }

      // If we generated all chunks but never reached 10s threshold, start anyway
      if (!playerStarted && _liveStream != null) {
        await _startPlayer();
      }

      // Finalize
      if (_liveStream == null) return;
      await _finalizeGeneration(cacheKey);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _generating = false;
    }
  }

  Future<void> _startPlayer() async {
    await _loadPlayerSource();
    state = state.copyWith(isLoading: false);
    _playerStarted = true;
    await _handler.play();
  }

  Future<void> _ensurePipeline(VoiceStyle voice) async {
    //TODO need to show download progress
    final assetPaths = await KokoroDownloader.ensureAssets(modelType: ModelType.q4, voiceStyle: voice);
    _pipeline ??= await TTSPipeline.create(assetPaths);
  }

  void _setupLiveStream() {
    _liveStream = GrowingAudioFile();
    _bufferedSub = _liveStream!.bufferedDurationStream.listen((d) {
      state = state.copyWith(bufferedDuration: d);
    });
  }

  Future<void> _generateNextChunk(
    PhonemeChunk chunk,
    VoiceStyle voice,
    int processedTokens,
    int totalTokens,
  ) async {
    final result = await _pipeline!.runInference(chunk, voice);
    if (_liveStream == null) return;

    _liveStream!.addSamples(result.audio);
    _updateEstimation(processedTokens, totalTokens);

    final mp3Bytes = await _liveStream!.encodeSamples(result.audio);
    if (mp3Bytes.isNotEmpty) {
      File(_cumulativeFilePath!).writeAsBytesSync(mp3Bytes, mode: FileMode.append);
    }

    if (_waitingForBuffer) {
      _waitingForBuffer = false;
      await _reloadAndResume();
    }
  }

  void _updateEstimation(int processedTokens, int totalTokens) {
    if (_liveStream == null || processedTokens == 0) return;
    final generatedMs = _liveStream!.bufferedDuration.inMilliseconds;
    final estimatedTotalMs = (generatedMs * totalTokens / processedTokens).round();
    final estimatedDuration = Duration(milliseconds: estimatedTotalMs);
    state = state.copyWith(estimatedDuration: estimatedDuration);
    if (_mediaItem != null) {
      _handler.updateMediaItem(_mediaItem!.copyWith(duration: estimatedDuration));
    }
  }

  Future<void> _loadPlayerSource() async {
    final tag = _mediaItem?.copyWith(duration: state.estimatedDuration ?? state.bufferedDuration);
    await _handler.setSource(_cumulativeFilePath!, tag: tag);
    _loadedDuration = state.bufferedDuration;
  }

  Future<void> _reloadPlayer() async {
    if (_reloading || _cumulativeFilePath == null || _liveStream == null) return;
    if (state.bufferedDuration <= _loadedDuration) return; // nothing new

    _reloading = true;
    try {
      final wasPlaying = _handler.player.playing;
      final savedPosition = _handler.player.position;
      await _loadPlayerSource();
      await _handler.seek(savedPosition);
      if (wasPlaying) await _handler.play();
    } finally {
      _reloading = false;
    }
  }

  Future<void> _reloadAndResume() async {
    if (_reloading || _cumulativeFilePath == null) return;
    _reloading = true;
    try {
      final pos = _handler.player.position;
      await _loadPlayerSource();
      await _handler.seek(pos);
      await _handler.play();
      state = state.copyWith(isLoading: false, isPlaying: true);
    } finally {
      _reloading = false;
    }
  }

  Future<void> _finalizeGeneration(String cacheKey) async {
    _liveStream!.endStream();
    final actualDuration = _liveStream!.bufferedDuration;

    // Flush remaining MP3 frames from encoder
    final finalBytes = await _liveStream!.flushEncoder();
    if (finalBytes.isNotEmpty) {
      File(_cumulativeFilePath!).writeAsBytesSync(finalBytes, mode: FileMode.append);
    }

    // Final reload so player has the complete file
    await _reloadPlayer();

    state = state.copyWith(
      ttsComplete: true,
      estimatedDuration: actualDuration,
      bufferedDuration: actualDuration,
    );

    // Update media control with actual duration
    if (_mediaItem != null) {
      _handler.updateMediaItem(_mediaItem!.copyWith(duration: actualDuration));
    }

    // Move cumulative MP3 directly to cache
    unawaited(_cache.saveFile(cacheKey, File(_cumulativeFilePath!)));
    _cumulativeFilePath = null;
  }

  // --- Player listeners ---

  void _wirePlayerListeners() {
    _positionSub = _handler.player.positionStream.listen((p) {
      if (_reloading) return;
      state = state.copyWith(position: p);
      // Trigger reload when nearing end of loaded audio
      if (!state.ttsComplete && !_reloading) {
        final threshold = _loadedDuration - const Duration(milliseconds: 300);
        if (p >= threshold && state.bufferedDuration > _loadedDuration) {
          _reloadPlayer();
        }
      }
    });

    _playerStateSub = _handler.player.playerStateStream.listen((s) {
      if (_reloading) return;
      if (!_playerStarted) return;

      if (s.processingState == ProcessingState.completed) {
        if (!state.ttsComplete) {
          // Ran out of loaded audio during generation — wait for more
          _waitingForBuffer = true;
          state = state.copyWith(isLoading: true, isPlaying: false);
        } else {
          // Track naturally finished
          state = state.copyWith(isPlaying: false);
        }
        return;
      }

      state = state.copyWith(
        isPlaying: s.playing,
        isLoading:
            s.processingState == ProcessingState.loading || s.processingState == ProcessingState.buffering,
      );
    });
  }

  Future<void> pause() async => _handler.pause();
  Future<void> resume() async => _handler.play();

  Future<void> togglePlayPause() async {
    if (_handler.player.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seekTo(Duration target) async {
    if (state.ttsComplete) {
      await _handler.seek(target);
      return;
    }

    // If seeking beyond loaded range, reload first if the buffer has caught up
    if (target > _loadedDuration && state.bufferedDuration > _loadedDuration) {
      await _reloadPlayer();
    }

    // Clamp to buffered range
    final maxMs = (state.bufferedDuration - const Duration(milliseconds: 500)).inMilliseconds.clamp(
      0,
      state.bufferedDuration.inMilliseconds,
    );
    final clampedMs = target.inMilliseconds.clamp(0, maxMs);
    await _handler.seek(Duration(milliseconds: clampedMs));
  }

  Future<void> jumpForward() async => seekTo(state.position + const Duration(seconds: 15));

  Future<void> jumpBackward() async {
    final target = state.position - const Duration(seconds: 15);
    await seekTo(target.isNegative ? Duration.zero : target);
  }

  List<PhonemeChunk> _protoToChunks(List<articles_pb.PhonemizerData> protoChunks) {
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

  int _totalTokens(List<PhonemeChunk> chunks) => chunks.fold<int>(0, (sum, c) => sum + c.tokenIds.length);
}
