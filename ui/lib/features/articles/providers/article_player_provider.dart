import "dart:async";

import "package:audio_service/audio_service.dart";
import "package:just_audio/just_audio.dart";
import "package:readintent_flutter/core/player_persistence.dart";
import "package:readintent_flutter/features/articles/repository/article_repository.dart";
import "package:readintent_flutter/features/auth/providers/auth_provider.dart";
import "package:readintent_flutter/features/tts/pipeline.dart";
import "package:readintent_flutter/models/auth_state.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

import "package:readintent_flutter/features/tts/audio_cache.dart";
import "package:readintent_flutter/features/tts/audio_handler.dart";
import "package:readintent_flutter/features/tts/audio_generator.dart";
import "package:readintent_flutter/features/tts/voice_style.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart"
    as articles_pb;

part "article_player_provider.g.dart";

const Object _sentinel = Object();

/// Resolves a sentinel-guarded copyWith parameter:
/// returns [current] if [value] was not passed, otherwise casts [value] to T.
T _resolve<T>(Object? value, T current) =>
    identical(value, _sentinel) ? current : value as T;

class ActivePlayerState {
  final String? articleId;
  final String? articleTitle;
  final String? articleAuthor;
  final String? articleImageUrl;
  final Duration position;
  final Duration bufferedDuration;
  final Duration? estimatedDuration;
  final bool isPlaying;
  final bool isLoading;
  final bool ttsComplete;
  final String? error;

  const ActivePlayerState({
    this.articleId,
    this.articleTitle,
    this.articleAuthor,
    this.articleImageUrl,
    this.position = Duration.zero,
    this.bufferedDuration = Duration.zero,
    this.estimatedDuration,
    this.isPlaying = false,
    this.isLoading = false,
    this.ttsComplete = false,
    this.error,
  });

  bool get hasActiveArticle => articleId != null;

  ActivePlayerState copyWith({
    Object? articleId = _sentinel,
    Object? articleTitle = _sentinel,
    Object? articleAuthor = _sentinel,
    Object? articleImageUrl = _sentinel,
    Duration? position,
    Duration? bufferedDuration,
    Object? estimatedDuration = _sentinel,
    bool? isPlaying,
    bool? isLoading,
    bool? ttsComplete,
    Object? error = _sentinel,
  }) {
    return ActivePlayerState(
      articleId: _resolve(articleId, this.articleId),
      articleTitle: _resolve(articleTitle, this.articleTitle),
      articleAuthor: _resolve(articleAuthor, this.articleAuthor),
      articleImageUrl: _resolve(articleImageUrl, this.articleImageUrl),
      position: position ?? this.position,
      bufferedDuration: bufferedDuration ?? this.bufferedDuration,
      estimatedDuration: _resolve(estimatedDuration, this.estimatedDuration),
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      ttsComplete: ttsComplete ?? this.ttsComplete,
      error: _resolve(error, this.error),
    );
  }
}

@Riverpod(keepAlive: true)
class ActivePlayer extends _$ActivePlayer {
  final AudioCache _cache = AudioCache();
  late final PlayerPersistence _persistence;
  late final AudioHandlerInterface _handler;
  late final PipelineFactory _pipelineFactory;
  AudioGenerator? _session;
  StreamSubscription? _sessionStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _bufferedSub;
  Duration _loadedDuration = Duration.zero;
  bool _reloading = false;
  bool _waitingForBuffer = false;
  bool _playerStarted = false;
  bool _restoring = false;
  MediaItem? _mediaItem;
  articles_pb.Article? _loadedArticle;
  Duration _resumePosition = Duration.zero;
  DateTime _lastPersistTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  ActivePlayerState build() {
    _handler = ref.read(audioHandlerProvider);
    _pipelineFactory = ref.read(pipelineFactoryProvider);
    _persistence = ref.read(playerPersistenceProvider);
    ref.onDispose(_cleanup);

    // Stop playback on logout
    ref.listen(authProvider, (_, next) {
      if (next is AuthUnauthenticated) stop();
    });

    // Restore last-played on startup
    _restoreLastPlayed();

    return const ActivePlayerState();
  }

  void _cleanup() {
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _bufferedSub?.cancel();
    _sessionStateSub?.cancel();
    _session?.dispose();
    _session = null;
    _loadedDuration = Duration.zero;
    _reloading = false;
    _waitingForBuffer = false;
    _playerStarted = false;
    _restoring = false;
    _mediaItem = null;
    _loadedArticle = null;
    _lastPersistTime = DateTime.fromMillisecondsSinceEpoch(0);
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
    _restoring = false; // Cancel any in-progress restore
    final newArticleId = article.id.toString();

    // Same article already active with audio loaded - just resume
    if (state.articleId == newArticleId && _playerStarted) {
      if (!state.isPlaying) await resume();
      return;
    }

    // Preserve restored position if resuming the same article
    _resumePosition = state.articleId == newArticleId ? state.position : Duration.zero;

    // If no local position, use server position from the article proto
    if (_resumePosition == Duration.zero && article.playerPositionMs > 0) {
      _resumePosition = Duration(milliseconds: article.playerPositionMs.toInt());
    }

    // Different article or first play - tear down current session
    _cleanup();
    await _handler.stop();
    _loadedArticle = article;
    _wirePlayerListeners();

    state = ActivePlayerState(
      articleId: newArticleId,
      articleTitle: article.title,
      articleAuthor: article.author.isNotEmpty ? article.author : null,
      articleImageUrl: article.image.isNotEmpty ? article.image : null,
      position: _resumePosition,
      isLoading: true,
    );

    persistState();

    try {
      _session = AudioGenerator(
        article: article,
        voice: voice,
        speed: speed,
        cache: _cache,
        pipelineFactory: _pipelineFactory,
      );

      // Check cache first — if we have completely generated audio, skip to playback
      final cachedPath = await _session!.checkCacheForComplete();
      if (cachedPath != null) {
        await _playFromFile(cachedPath, article);
        return;
      }

      _mediaItem = _buildMediaItem(article);

      // Listen to session state updates (buffered duration, TTS completion)
      _sessionStateSub = _session!.stateStream.listen((sessionState) {
        state = state.copyWith(
          bufferedDuration: sessionState.bufferedDuration,
          estimatedDuration: sessionState.estimatedDuration,
        );

        if (sessionState.estimatedDuration != null && _mediaItem != null) {
          _handler.updateMediaItem(
            _mediaItem!.copyWith(duration: sessionState.estimatedDuration),
          );
        }

        if (sessionState.isComplete) {
          final actualDuration = sessionState.bufferedDuration;
          state = state.copyWith(
            ttsComplete: true,
            estimatedDuration: actualDuration,
            bufferedDuration: actualDuration,
          );
          if (_mediaItem != null) {
            _handler.updateMediaItem(
              _mediaItem!.copyWith(duration: actualDuration),
            );
          }
          _reloadPlayer();
        }

        // Ran out of generated audio, waiting for more — resume when available
        if (_waitingForBuffer && !sessionState.isComplete) {
          _waitingForBuffer = false;
          _reloadAndResume();
        }
      });

      _bufferedSub = _session!.bufferedDurationStream?.listen((d) {
        state = state.copyWith(bufferedDuration: d);
      });

      await _session!.generate(onBufferReady: () => _startPlayer());
    } catch (e) {
      _cleanup();
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Set the active article metadata so the player widget appears,
  /// without starting playback. No-op if this article is already active.
  void loadArticle(articles_pb.Article article) {
    final newArticleId = article.id.toString();

    if (state.articleId == newArticleId) {
      _loadedArticle = article;
      return;
    }

    // Different article — stop current playback and clean up
    _cleanup();
    _handler.stop();
    _loadedArticle = article;

    state = ActivePlayerState(
      articleId: newArticleId,
      articleTitle: article.title,
      articleAuthor: article.author.isNotEmpty ? article.author : null,
      articleImageUrl: article.image.isNotEmpty ? article.image : null,
    );
  }

  Future<void> stop() async {
    _cleanup();
    await _handler.stop();
    state = const ActivePlayerState();
    await _persistence.clear();
  }

  Future<void> _playFromFile(
    String path,
    articles_pb.Article article,
  ) async {
    final tag = _buildMediaItem(article);
    final duration = await _handler.setSource(path, tag: tag);
    // Seek to restored position if resuming a previously played article
    if (_resumePosition > Duration.zero) {
      await _handler.seek(_resumePosition);
    }
    _playerStarted = true;
    state = state.copyWith(
      isLoading: false,
      ttsComplete: true,
      position: _resumePosition,
      estimatedDuration: duration,
      bufferedDuration: duration ?? Duration.zero,
    );
    await _handler.play();
  }

  Future<void> _startPlayer() async {
    await _loadPlayerSource();
    if (_resumePosition > Duration.zero) {
      await _handler.seek(_resumePosition);
    }
    _playerStarted = true;
    state = state.copyWith(isLoading: false, position: _resumePosition);
    await _handler.play();
  }

  Future<void> _loadPlayerSource() async {
    if (_session?.filePath == null) return;
    final tag = _mediaItem?.copyWith(
      duration: state.estimatedDuration ?? state.bufferedDuration,
    );
    try {
      await _handler.setSource(_session!.filePath!, tag: tag);
      _loadedDuration = state.bufferedDuration;
    } catch (e) {
      print("Error loading audio source: $e");
    }
  }

  Future<void> _reloadPlayer() async {
    if (_reloading || _session?.filePath == null) return;
    if (state.bufferedDuration <= _loadedDuration) return;

    _reloading = true;
    try {
      final wasPlaying = _handler.isPlaying;
      final savedPosition = _handler.currentPosition;
      await _loadPlayerSource();
      await _handler.seek(savedPosition);
      if (wasPlaying) await _handler.play();
    } finally {
      _reloading = false;
      state = state.copyWith(isPlaying: _handler.isPlaying);
    }
  }

  Future<void> _reloadAndResume() async {
    if (_reloading || _session?.filePath == null) return;
    _reloading = true;
    try {
      final pos = _handler.currentPosition;
      await _loadPlayerSource();
      await _handler.seek(pos);
      await _handler.play();
      state = state.copyWith(isLoading: false, isPlaying: true);
    } finally {
      _reloading = false;
    }
  }

  void _wirePlayerListeners() {
    _positionSub = _handler.positionStream.listen((p) {
      if (_reloading || !_playerStarted) return;
      state = state.copyWith(position: p);

      // Persist position every ~5 seconds
      final now = DateTime.now();
      if (now.difference(_lastPersistTime).inSeconds >= 5) {
        _lastPersistTime = now;
        persistState();
      }

      // Trigger reload when nearing end of loaded audio
      if (!state.ttsComplete && !_reloading) {
        final threshold = _loadedDuration - const Duration(milliseconds: 300);
        if (p >= threshold && state.bufferedDuration > _loadedDuration) {
          _reloadPlayer();
        }
      }
    });

    _playerStateSub = _handler.playerStateStream.listen((s) {
      if (_reloading) return;
      if (!_playerStarted) return;

      if (s.processingState == ProcessingState.completed) {
        if (!state.ttsComplete) {
          _waitingForBuffer = true;
          state = state.copyWith(isLoading: true, isPlaying: false);
        } else {
          state = state.copyWith(isPlaying: false);
        }
        return;
      }

      state = state.copyWith(
        isPlaying: s.playing,
        isLoading: s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering,
      );
    });
  }

  Future<void> pause() async => _handler.pause();
  Future<void> resume() async => _handler.play();

  Future<void> togglePlayPause() async {
    if (!_playerStarted) {
      // Have the article object — start playback directly
      if (_loadedArticle != null) {
        await play(article: _loadedArticle!);
        return;
      }
      // Restored from persistence — fetch the article from the repository
      if (state.articleId != null) {
        await _fetchAndPlay(state.articleId!);
        return;
      }
      return;
    }
    if (_handler.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> _fetchAndPlay(String articleId) async {
    state = state.copyWith(isLoading: true);
    try {
      final repository = ref.read(articleRepositoryProvider);
      final article = await repository.getArticle(articleId);
      if (article == null) {
        state = state.copyWith(isLoading: false, error: "Article not available offline");
        return;
      }
      await play(article: article);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> seekTo(Duration target) async {
    if (state.ttsComplete) {
      await _handler.seek(target);
      return;
    }

    if (target > _loadedDuration && state.bufferedDuration > _loadedDuration) {
      await _reloadPlayer();
    }

    final maxMs = (state.bufferedDuration - const Duration(milliseconds: 500))
        .inMilliseconds
        .clamp(0, state.bufferedDuration.inMilliseconds);
    final clampedMs = target.inMilliseconds.clamp(0, maxMs);
    await _handler.seek(Duration(milliseconds: clampedMs));
  }

  Future<void> jumpForward() async =>
      seekTo(state.position + const Duration(seconds: 15));

  Future<void> jumpBackward() async {
    final target = state.position - const Duration(seconds: 15);
    await seekTo(target.isNegative ? Duration.zero : target);
  }

  void persistState() {
    if (state.articleId == null) return;
    _persistence.save(
      articleId: state.articleId!,
      articleTitle: state.articleTitle,
      articleAuthor: state.articleAuthor,
      articleImageUrl: state.articleImageUrl,
      positionMs: state.position.inMilliseconds,
      estimatedDurationMs: state.estimatedDuration?.inMilliseconds,
      ttsComplete: state.ttsComplete,
    );
    // Fire-and-forget server sync
    try {
      ref.read(articleRepositoryProvider).saveArticleProgress(
        articleId: state.articleId!,
        playerPositionMs: state.position.inMilliseconds,
      );
    } catch (_) {
      // Skip server sync if repository is not available
    }
  }

  Future<void> _restoreLastPlayed() async {
    _restoring = true;
    try {
      final data = await _persistence.load();
      // Abort if play() was called while we were loading
      if (!_restoring || data == null) return;

      final localPositionMs = data["positionMs"] as int? ?? 0;

      state = ActivePlayerState(
        articleId: data["articleId"] as String,
        articleTitle: data["articleTitle"] as String?,
        articleAuthor: data["articleAuthor"] as String?,
        articleImageUrl: data["articleImageUrl"] as String?,
        position: Duration(milliseconds: localPositionMs),
        estimatedDuration: data["estimatedDurationMs"] != null
            ? Duration(milliseconds: data["estimatedDurationMs"] as int)
            : null,
        ttsComplete: data["ttsComplete"] as bool? ?? false,
        isPlaying: false,
      );

      // Check if server has a newer position
      final articleId = data["articleId"] as String;
      try {
        final repository = ref.read(articleRepositoryProvider);
        final article = await repository.getArticle(articleId);
        if (!_restoring) return; // play() was called in the meantime
        // Take the largest position between local and server, to avoid regressions 
        if (article != null && article.playerPositionMs.toInt() > localPositionMs) {
          state = state.copyWith(
            position: Duration(milliseconds: article.playerPositionMs.toInt()),
          );
        }
      } catch (_) {
        // Best-effort — server position is optional and won't interfere with local restore if it fails
      }
    } catch (_) {
      // Best-effort restore — don't crash on corrupt/missing data
    } finally {
      _restoring = false;
    }
  }
}
