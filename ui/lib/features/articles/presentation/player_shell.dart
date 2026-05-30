import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:readintent_flutter/features/articles/presentation/article_player_widget.dart";
import "package:readintent_flutter/features/articles/providers/article_player_provider.dart";
import "package:readintent_flutter/features/tts/download_status_provider.dart";
import "package:readintent_flutter/features/tts/model_downloader.dart";
import "package:readintent_flutter/features/tts/presentation/download_status_bar.dart";

class PlayerShell extends ConsumerStatefulWidget {
  final Widget child;
  const PlayerShell({super.key, required this.child});

  @override
  ConsumerState<PlayerShell> createState() => _PlayerShellState();
}

class _PlayerShellState extends ConsumerState<PlayerShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preloadModel();
  }

  void _preloadModel() async {
    final notifier = ref.read(downloadStatusProvider.notifier);
    try {
      await KokoroDownloader.preloadAll(
        modelType: ModelType.q4,
        onProgress: (name, progress) {
          notifier.set(DownloadStatus("Downloading $name", progress));
        },
      );
      notifier.set(null);
    } catch (_) {
      notifier.set(null);
      // Silent fail - download retried when user plays
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(activePlayerProvider.notifier).persistState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveArticle = ref.watch(
      activePlayerProvider.select((s) => s.hasActiveArticle),
    );
    final hasDownloadStatus = ref.watch(
      downloadStatusProvider.select((s) => s != null),
    );

    if (!hasActiveArticle && !hasDownloadStatus) return widget.child;

    return Column(
      children: [
        Expanded(child: widget.child),
        if (hasDownloadStatus) const DownloadStatusBar(),
        if (hasActiveArticle && !hasDownloadStatus) const ArticlePlayerWidget(),
      ],
    );
  }
}
