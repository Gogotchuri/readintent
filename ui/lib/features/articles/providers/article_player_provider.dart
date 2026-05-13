import "dart:async";

import "package:audio_service/audio_service.dart";
import "package:just_audio/just_audio.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "package:readintent_flutter/features/tts/audio_cache.dart";
import "package:readintent_flutter/features/tts/audio_handler.dart";
import "package:readintent_flutter/features/tts/phoneme.dart";
import "package:readintent_flutter/features/tts/audio_generator.dart";
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
  AudioGenerator? _session;
  StreamSubscription? _sessionStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _bufferedSub;
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
    _sessionStateSub?.cancel();
    _handler.stop(); // Stop playback on cleanup
    _session?.dispose();
    _session = null;
    _loadedDuration = Duration.zero;
    _reloading = false;
    _waitingForBuffer = false;
    _playerStarted = false;
    _mediaItem = null;
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
    if (_session != null) return;

    _cleanup();
    await _handler.stop();
    _wirePlayerListeners();

    state = const ArticlePlayerState(isLoading: true);

    try {
      _session = AudioGenerator(article: article, voice: voice, speed: speed, cache: _cache);

      // Check cache first, if we have completely generated audio available, skip straight to playback
      final cachedPath = await _session!.checkCacheForComplete();
      if (cachedPath != null) {
        await _playFromFile(cachedPath, article);
        return;
      }

      _mediaItem = _buildMediaItem(article);

      // Listen to session state updates
      _sessionStateSub = _session!.stateStream.listen((sessionState) {
        state = state.copyWith(
          bufferedDuration: sessionState.bufferedDuration,
          estimatedDuration: sessionState.estimatedDuration,
        );

        if (sessionState.estimatedDuration != null && _mediaItem != null) {
          _handler.updateMediaItem(_mediaItem!.copyWith(duration: sessionState.estimatedDuration));
        }

        if (sessionState.isComplete) {
          final actualDuration = sessionState.bufferedDuration;
          state = state.copyWith(
            ttsComplete: true,
            estimatedDuration: actualDuration,
            bufferedDuration: actualDuration,
          );
          if (_mediaItem != null) {
            _handler.updateMediaItem(_mediaItem!.copyWith(duration: actualDuration));
          }
          // Final reload so player has the complete file
          _reloadPlayer();
        }

        // Handle buffer stall recovery
        if (_waitingForBuffer && !sessionState.isComplete) {
          _waitingForBuffer = false;
          _reloadAndResume();
        }
      });

      // Subscribe to buffered duration from the audio file for granular updates
      _bufferedSub = _session!.bufferedDurationStream?.listen((d) {
        state = state.copyWith(bufferedDuration: d);
      });

      await _session!.generate(onBufferReady: () => _startPlayer());
    } catch (e) {
      _cleanup();
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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

  Future<void> _startPlayer() async {
    await _loadPlayerSource();
    state = state.copyWith(isLoading: false);
    _playerStarted = true;
    await _handler.play();
  }

  Future<void> _loadPlayerSource() async {
    if (_session?.filePath == null) return;
    final tag = _mediaItem?.copyWith(duration: state.estimatedDuration ?? state.bufferedDuration);
    try {
      await _handler.setSource(_session!.filePath!, tag: tag);
      _loadedDuration = state.bufferedDuration;
    } catch (e) {
      // This is most likely non-issue and mostly caused by the player concurrently trying to load an incomplete file
      print("Error loading audio source: $e");
    }
  }

  Future<void> _reloadPlayer() async {
    if (_reloading || _session?.filePath == null) return;
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
      state = state.copyWith(isPlaying: _handler.player.playing);
    }
  }

  Future<void> _reloadAndResume() async {
    if (_reloading || _session?.filePath == null) return;
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

}
