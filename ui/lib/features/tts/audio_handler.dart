import "dart:async";

import "package:audio_service/audio_service.dart";
import "package:just_audio/just_audio.dart";

class ArticleAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  ArticleAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  AudioPlayer get player => _player;

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: switch (_player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: 0,
    );
  }

  void setArticleMetadata({required String title, String? author}) {
    mediaItem.add(MediaItem(
      id: title,
      title: title,
      artist: author,
      album: "ReadIntent",
    ));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> fastForward() =>
      _player.seek(_player.position + const Duration(seconds: 15));

  @override
  Future<void> rewind() {
    final target = _player.position - const Duration(seconds: 15);
    return _player.seek(target.isNegative ? Duration.zero : target);
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
