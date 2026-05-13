import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:readintent_flutter/features/articles/providers/article_player_provider.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as articles_pb;

class ArticlePlayerWidget extends ConsumerWidget {
  final articles_pb.Article article;

  const ArticlePlayerWidget({super.key, required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleId = article.id.toString();
    final playerState = ref.watch(articlePlayerProvider(articleId));
    final controller = ref.read(articlePlayerProvider(articleId).notifier);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgressSlider(context, playerState, controller),
          const SizedBox(height: 4),
          _buildTimeLabels(context, playerState),
          _buildControls(context, playerState, controller),
          if (playerState.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                playerState.error!,
                style: TextStyle(color: Colors.red[700], fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider(BuildContext context, ArticlePlayerState state, ArticlePlayer controller) {
    final totalMs = (state.estimatedDuration ?? Duration.zero).inMilliseconds;
    final positionMs = state.position.inMilliseconds;
    final bufferedMs = state.bufferedDuration.inMilliseconds;
    final progress = totalMs > 0 ? (positionMs / totalMs).clamp(0.0, 1.0) : 0.0;
    final bufferedProgress = totalMs > 0 ? (bufferedMs / totalMs).clamp(0.0, 1.0) : 0.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        LinearProgressIndicator(
          value: bufferedProgress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation(Colors.grey[400]!),
          minHeight: 3,
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Colors.transparent,
            thumbColor: Theme.of(context).colorScheme.primary,
          ),
          child: Slider(
            value: progress,
            onChanged: totalMs > 0
                ? (v) => controller.seekTo(Duration(milliseconds: (v * totalMs).round()))
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeLabels(BuildContext context, ArticlePlayerState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(_formatDuration(state.position), style: Theme.of(context).textTheme.labelSmall),
        if (!state.ttsComplete && state.bufferedDuration > Duration.zero)
          Text(
            "Generating...",
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
          ),
        Text(_formatEndTime(state), style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _buildControls(BuildContext context, ArticlePlayerState state, ArticlePlayer controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: state.position > Duration.zero ? controller.jumpBackward : null,
          icon: const Icon(Icons.replay_10),
        ),
        const SizedBox(width: 8),
        _buildPlayButton(state, controller),
        const SizedBox(width: 8),
        IconButton(
          onPressed:
              state.ttsComplete || state.position + const Duration(seconds: 15) <= state.bufferedDuration
              ? controller.jumpForward
              : null,
          icon: const Icon(Icons.forward_10),
        ),
      ],
    );
  }

  Widget _buildPlayButton(ArticlePlayerState state, ArticlePlayer controller) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    final neverPlayed =
        !state.isPlaying && state.position == Duration.zero && state.bufferedDuration == Duration.zero;

    return IconButton(
      iconSize: 40,
      onPressed: neverPlayed ? () => controller.play(article: article) : controller.togglePlayPause,
      icon: Icon(state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
    );
  }

  static String _formatEndTime(ArticlePlayerState state) {
    if (state.estimatedDuration == null) return "--:--";
    final formatted = _formatDuration(state.estimatedDuration!);
    return state.ttsComplete ? formatted : "~$formatted";
  }

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
}
