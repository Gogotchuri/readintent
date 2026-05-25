import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:readintent_flutter/features/articles/presentation/article_player_widget.dart";
import "package:readintent_flutter/features/articles/providers/article_player_provider.dart";

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

    if (!hasActiveArticle) return widget.child;

    return Column(
      children: [
        Expanded(child: widget.child),
        const ArticlePlayerWidget(),
      ],
    );
  }
}
