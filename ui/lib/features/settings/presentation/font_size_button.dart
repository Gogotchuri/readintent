import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:readintent_flutter/features/settings/providers/app_settings_provider.dart";

class FontSizeButton extends StatelessWidget {
  const FontSizeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.format_size),
      tooltip: "Font size",
      onPressed: () => showModalBottomSheet(
        context: context,
        builder: (_) => const _FontSizeSheet(),
      ),
    );
  }
}

class _FontSizeSheet extends ConsumerWidget {
  const _FontSizeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(appSettingsProvider.select((s) => s.textScale));
    final notifier = ref.read(appSettingsProvider.notifier);
    final percent = (scale * 100).round();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Font size", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.remove),
                  tooltip: "Decrease",
                  onPressed: scale > AppSettings.minScale
                      ? notifier.decreaseFont
                      : null,
                ),
                Text(
                  "$percent%",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add),
                  tooltip: "Increase",
                  onPressed: scale < AppSettings.maxScale
                      ? notifier.increaseFont
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: scale == 1.0 ? null : notifier.resetFont,
              child: const Text("Reset to 100%"),
            ),
          ],
        ),
      ),
    );
  }
}
