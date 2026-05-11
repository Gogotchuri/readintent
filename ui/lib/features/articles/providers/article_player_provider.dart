import "dart:async";
import "dart:io";

import "package:just_audio_background/just_audio_background.dart";
import "package:just_audio/just_audio.dart";
import "package:path_provider/path_provider.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "package:readintent_flutter/features/tts/audio_cache.dart";
import "package:readintent_flutter/features/tts/growable_audio_stream.dart";
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
  final AudioPlayer _player = AudioPlayer();
  GrowableAudioStream? _liveStream;
  StreamSubscription? _positionSub;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _bufferedSub;
  TTSPipeline? _pipeline;
  Directory? _chunkDir;
  bool _generating = false;

  @override
  ArticlePlayerState build(String articleId) {
    ref.onDispose(_cleanup);
    return const ArticlePlayerState();
  }

  void _cleanup() {
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _bufferedSub?.cancel();
    _liveStream?.dispose();
    _liveStream = null;
    _chunkDir?.delete(recursive: true).catchError((_) => _chunkDir!);
    _chunkDir = null;
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

    // Build cache key using concatenated graphemes as article text
    final articleText = article.pureText;
    final key = _cache.cacheKey(
      articleId: articleId,
      articleText: articleText,
      voice: voice.key,
      speed: speed,
    );

    // Try cache first
    final cachedFile = await _cache.load(key);
    if (cachedFile != null) {
      await _playFromFile(cachedFile.path, article);
      return;
    }

    // Generate live
    await _generateAndPlay(article: article, voice: voice, speed: speed, cacheKey: key);
  }

  Future<void> _playFromFile(String path, articles_pb.Article article) async {
    final duration = await _player.setAudioSource(AudioSource.file(path, tag: _buildMediaItem(article)));
    state = state.copyWith(
      isLoading: false,
      ttsComplete: true,
      estimatedDuration: duration,
      bufferedDuration: duration ?? Duration.zero,
    );
    await _player.play();
  }

  Future<void> _generateAndPlay({
    required articles_pb.Article article,
    required VoiceStyle voice,
    required double speed,
    required String cacheKey,
  }) async {
    _generating = true;
    final tempDir = await getTemporaryDirectory();
    _chunkDir = Directory("${tempDir.path}/readintent_tts_$articleId");
    await _chunkDir!.create(recursive: true);

    try {
      // Ensure model + voice assets
      //TODO need to show download progress
      final assetPaths = await KokoroDownloader.ensureAssets(modelType: ModelType.q4, voiceStyle: voice);

      _pipeline ??= await TTSPipeline.create(assetPaths);

      // Map proto PhonemizerData chunks to PhonemeChunks
      final chunks = _protoToChunks(article.phonemizerData);

      // Estimate duration: ~6ms per token at 1x speed
      final totalTokens = chunks.fold<int>(0, (sum, c) => sum + c.tokenIds.length);
      final estimatedMs = (totalTokens * 6.0 / speed).round();
      state = state.copyWith(estimatedDuration: Duration(milliseconds: estimatedMs));

      // Generate first chunk
      final firstResult = await _pipeline!.runInference(chunks.first, voice);

      // Accumulate audio data for duration tracking and final cache WAV
      _liveStream = GrowableAudioStream();
      _liveStream!.addSamples(firstResult.audio);
      _bufferedSub = _liveStream!.bufferedDurationStream.listen((d) {
        state = state.copyWith(bufferedDuration: d);
      });

      // Calibrate estimate from first chunk
      final firstChunkDurationMs = (firstResult.audio.length * 1000) ~/ 24000;
      final estimatedTotalMs = (firstChunkDurationMs * totalTokens / chunks.first.tokenIds.length).round();
      state = state.copyWith(estimatedDuration: Duration(milliseconds: estimatedTotalMs));

      // Write first chunk as a standalone WAV file
      final firstFile = File("${_chunkDir!.path}/chunk_0.wav");
      await firstFile.writeAsBytes(GrowableAudioStream.chunkToWavBytes(firstResult.audio));

      // Set up playlist with first chunk and start playback
      final mediaItem = _buildMediaItem(article);
      await _player.setAudioSources([
        AudioSource.file(firstFile.path, tag: mediaItem),
      ]);
      state = state.copyWith(isLoading: false);
      await _player.play();

      // Generate remaining chunks, append to playlist dynamically
      for (int i = 1; i < chunks.length; i++) {
        if (_liveStream == null) break; // disposed during generation

        final result = await _pipeline!.runInference(chunks[i], voice);
        _liveStream!.addSamples(result.audio);

        final chunkFile = File("${_chunkDir!.path}/chunk_$i.wav");
        await chunkFile.writeAsBytes(GrowableAudioStream.chunkToWavBytes(result.audio));
        await _player.addAudioSource(AudioSource.file(chunkFile.path, tag: mediaItem));
      }

      // Generation complete
      if (_liveStream == null) return; // disposed
      _liveStream!.endStream();
      final actualDuration = _liveStream!.bufferedDuration;
      state = state.copyWith(ttsComplete: true, estimatedDuration: actualDuration);

      // Save concatenated WAV to cache, then clean up chunk files
      final wavBytes = _liveStream!.toWavBytes();
      unawaited(_cache.save(cacheKey, wavBytes));
      unawaited(_chunkDir!.delete(recursive: true).then((_) => _chunkDir = null));
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _generating = false;
    }
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

  void _wirePlayerListeners() {
    _positionSub = _player.positionStream.listen((p) {
      state = state.copyWith(position: p);
    });
    _playerStateSub = _player.playerStateStream.listen((s) {
      state = state.copyWith(
        isPlaying: s.playing,
        isLoading:
            s.processingState == ProcessingState.loading || s.processingState == ProcessingState.buffering,
      );
    });
  }

  Future<void> pause() async => _player.pause();
  Future<void> resume() async => _player.play();

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seekTo(Duration target) async {
    if (state.ttsComplete) {
      await _player.seek(target);
      return;
    }
    // During generation, clamp to buffered range
    final maxMs = (state.bufferedDuration - const Duration(milliseconds: 500)).inMilliseconds.clamp(
      0,
      state.bufferedDuration.inMilliseconds,
    );
    final clampedMs = target.inMilliseconds.clamp(0, maxMs);
    await _player.seek(Duration(milliseconds: clampedMs));
  }

  Future<void> jumpForward() async => seekTo(state.position + const Duration(seconds: 15));

  Future<void> jumpBackward() async {
    final target = state.position - const Duration(seconds: 15);
    await seekTo(target.isNegative ? Duration.zero : target);
  }
}
