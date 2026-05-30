import "package:audio_service/audio_service.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:just_audio/just_audio.dart";

final audioHandlerProvider = Provider<AudioHandlerInterface>((ref) {
  throw UnimplementedError("audioHandlerProvider must be overridden in main");
});

abstract class AudioHandlerInterface {
  Future<Duration?> setSource(String filePath, {MediaItem? tag});
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> updateMediaItem(MediaItem mediaItem);

  Stream<Duration> get positionStream;
  Stream<PlayerState> get playerStateStream;
  bool get isPlaying;
  Duration get currentPosition;
}

// This is a simple wrapper around just_audio's AudioPlayer to integrate with audio_service
// It exposes methods to set the audio source and control playback, and broadcasts state changes to audio_service
// Allows for background audio playback and integration with system media controls
class AppAudioHandler extends BaseAudioHandler with SeekHandler implements AudioHandlerInterface {
  final AudioPlayer _player = AudioPlayer();

  AppAudioHandler() {
    _player.playerStateStream.listen((_) => _broadcastState());
  }

  @override
  Stream<Duration> get positionStream => _player.positionStream;
  @override
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  @override
  bool get isPlaying => _player.playing;
  @override
  Duration get currentPosition => _player.position;

  @override
  Future<Duration?> setSource(String filePath, {MediaItem? tag}) async {
    if (tag != null) {
      mediaItem.add(tag);
    }
    return _player.setAudioSource(AudioSource.file(filePath));
  }

  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  void _broadcastState() {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.rewind,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
        MediaControl.stop,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      processingState: _mapProcessingState(_player.processingState),
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  static AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }
}
