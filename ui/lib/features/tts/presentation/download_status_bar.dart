import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:readintent_flutter/features/tts/download_status_provider.dart";

class DownloadStatusBar extends ConsumerWidget {
  const DownloadStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(downloadStatusProvider);
    if (status == null) return const SizedBox.shrink();

    final theme = Theme.of(context).colorScheme;
    final isDeterminate = status.progress >= 0;
    final percentage = isDeterminate ? (status.progress * 100).toInt() : null;

    return Container(
      color: theme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              value: isDeterminate ? status.progress : null,
              color: theme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        status.label,
                        style: TextStyle(
                          color: theme.onPrimaryContainer,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (percentage != null)
                      Text(
                        "$percentage%",
                        style: TextStyle(
                          color: theme.onPrimaryContainer,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                if (isDeterminate) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: status.progress,
                      minHeight: 3,
                      backgroundColor: theme.onPrimaryContainer.withValues(alpha: 0.2),
                      color: theme.onPrimaryContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
