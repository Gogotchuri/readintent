import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:readintent_flutter/features/articles/providers/article_player_provider.dart";

class MiniPlayerWidget extends ConsumerWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activePlayerProvider);
    final controller = ref.read(activePlayerProvider.notifier);
    final theme = Theme.of(context);

    final totalMs = (state.estimatedDuration ?? Duration.zero).inMilliseconds;
    final positionMs = state.position.inMilliseconds;
    final progress = totalMs > 0 ? (positionMs / totalMs).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => context.push("/articles/${state.articleId}"),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Progress background fill
                  Container(
                    width: constraints.maxWidth * progress,
                    height: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  // Content row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        _buildImage(state.articleImageUrl, theme),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextColumn(state, theme)),
                        _buildRewindButton(state, controller),
                        _buildPlayButton(state, controller),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String? imageUrl, ThemeData theme) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _buildImageFallback(theme),
        ),
      );
    }
    return _buildImageFallback(theme);
  }

  Widget _buildImageFallback(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.article, color: theme.colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildTextColumn(ActivePlayerState state, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.articleTitle ?? "",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        if (state.articleAuthor != null) ...[
          const SizedBox(height: 2),
          Text(
            state.articleAuthor!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRewindButton(ActivePlayerState state, ActivePlayer controller) {
    return IconButton(
      icon: const Icon(Icons.replay_10, size: 24),
      onPressed: state.position > Duration.zero ? controller.jumpBackward : null,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }

  Widget _buildPlayButton(ActivePlayerState state, ActivePlayer controller) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    return IconButton(
      icon: Icon(
        state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
        size: 32,
      ),
      onPressed: controller.togglePlayPause,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
