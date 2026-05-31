import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:readintent_flutter/core/connectivity.dart";
import "package:readintent_flutter/features/articles/presentation/article_player_widget.dart";
import "package:readintent_flutter/features/articles/presentation/articles_screen.dart";
import "package:readintent_flutter/features/articles/presentation/mini_player_widget.dart";
import "package:readintent_flutter/features/articles/providers/article_player_provider.dart";
import "package:readintent_flutter/features/settings/presentation/settings_screen.dart";
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
  int _selectedTabIndex = 0;

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

  /// Determine which bottom nav tab to highlight based on current route.
  int _computeSelectedIndex(String currentPath) {
    if (currentPath == "/home") return _selectedTabIndex;
    if (currentPath.startsWith("/articles/")) return 0; // Articles tab
    if (currentPath == "/pair-extension") return 1; // Settings tab
    return _selectedTabIndex;
  }

  void _onTabSelected(int index, bool isOnHome) {
    setState(() => _selectedTabIndex = index);
    if (!isOnHome) context.go("/home");
  }

  @override
  Widget build(BuildContext context) {
    final activeState = ref.watch(activePlayerProvider);
    final hasActiveArticle = activeState.hasActiveArticle;
    final hasDownloadStatus = ref.watch(
      downloadStatusProvider.select((s) => s != null),
    );
    final isOnline = ref.watch(isOnlineProvider);

    // Route detection
    final currentPath = GoRouterState.of(context).uri.path;
    final isOnHome = currentPath == "/home";
    String? routeArticleId;
    try {
      routeArticleId = GoRouterState.of(context).pathParameters["id"];
    } catch (_) {}
    final isOnMatchingDetail =
        routeArticleId != null && routeArticleId == activeState.articleId;

    return Column(
      children: [
        // Offline banner
        if (!isOnline)
          Container(
            width: double.infinity,
            color: Colors.orange[700],
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text("You're offline",
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),

        // Main content area
        Expanded(
          child: isOnHome
              ? IndexedStack(
                  index: _selectedTabIndex,
                  children: const [
                    ArticlesScreen(),
                    SettingsScreen(),
                  ],
                )
              : widget.child,
        ),

        // Download status bar OR player widget
        if (hasDownloadStatus) const DownloadStatusBar(),
        if (hasActiveArticle && !hasDownloadStatus)
          // We will show a player of the current article always on the details page.
          // In order to avoid flashing the player when user navigates between articles due to frame timing
          // we show mini player and give the full player enough time to load and take over 
          isOnMatchingDetail
              ? const ArticlePlayerWidget()
              : const MiniPlayerWidget(),

        // Bottom navigation bar
        NavigationBar(
          selectedIndex: _computeSelectedIndex(currentPath),
          onDestinationSelected: (i) => _onTabSelected(i, isOnHome),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article),
              label: "Articles",
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: "Settings",
            ),
          ],
        ),
      ],
    );
  }
}
