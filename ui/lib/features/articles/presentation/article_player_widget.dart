import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:marquee/marquee.dart";

import "package:readintent_flutter/features/articles/providers/article_player_provider.dart";

class ArticlePlayerWidget extends ConsumerWidget {
  const ArticlePlayerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activePlayerProvider);
    final controller = ref.read(activePlayerProvider.notifier);
    String? routeArticleId;
    try {
      routeArticleId = GoRouterState.of(context).pathParameters["id"];
    } catch (_) {}
    final onArticleDetail = routeArticleId != null && routeArticleId == state.articleId;

    return GestureDetector(
      onTap: onArticleDetail ? null : () => context.push("/articles/${state.articleId}"),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTitleRow(context, state.articleTitle ?? "", onArticleDetail ? null : controller),
              const SizedBox(height: 4),
              _buildProgressSlider(context, state, controller),
              const SizedBox(height: 4),
              _buildTimeLabels(context, state),
              _buildControls(context, ref, state, controller, onArticleDetail),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    state.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context, String title, ActivePlayer? controller) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)
        ?? const TextStyle(fontWeight: FontWeight.w500);
    final fontSize = style.fontSize ?? 14.0;
    final lineHeight = style.height ?? 1.2;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: fontSize * lineHeight + 4,
            child: _AutoMarquee(text: title, style: style),
          ),
        ),
        if (controller != null)
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: controller.stop,
            tooltip: "Stop playback",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildProgressSlider(BuildContext context, ActivePlayerState state, ActivePlayer controller) {
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
          backgroundColor: Theme.of(context).colorScheme.outlineVariant,
          valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.outline),
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

  Widget _buildTimeLabels(BuildContext context, ActivePlayerState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(_formatDuration(state.position), style: Theme.of(context).textTheme.labelSmall),
        if (!state.ttsComplete && state.bufferedDuration > Duration.zero)
          Text(
            "Generating...",
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        Text(_formatEndTime(state), style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    ActivePlayerState state,
    ActivePlayer controller,
    bool onArticleDetail,
  ) {
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
        if (onArticleDetail) ...[
          const SizedBox(width: 8),
          _buildSyncButton(ref),
        ],
      ],
    );
  }

  Widget _buildSyncButton(WidgetRef ref) {
    final syncEnabled = ref.watch(activePlayerProvider.select((s) => s.syncEnabled));
    return IconButton(
      icon: Icon(syncEnabled ? Icons.sync : Icons.sync_disabled),
      color: syncEnabled ? null : Colors.grey,
      onPressed: () => ref.read(activePlayerProvider.notifier).toggleSync(),
      tooltip: syncEnabled ? "Disable auto-scroll" : "Enable auto-scroll",
    );
  }

  Widget _buildPlayButton(ActivePlayerState state, ActivePlayer controller) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    return IconButton(
      iconSize: 40,
      onPressed: controller.togglePlayPause,
      icon: Icon(state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
    );
  }

  static String _formatEndTime(ActivePlayerState state) {
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

/// Shows a plain Text if it fits, or a scrolling Marquee if it overflows.
class _AutoMarquee extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _AutoMarquee({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();

        if (textPainter.width <= constraints.maxWidth) {
          return Text(text, style: style, maxLines: 1);
        }

        return Marquee(
          text: text,
          style: style,
          velocity: 30,
          blankSpace: 80,
          pauseAfterRound: const Duration(seconds: 2),
          startAfter: const Duration(seconds: 1),
        );
      },
    );
  }
}
