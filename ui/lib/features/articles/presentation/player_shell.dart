import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:readintent_flutter/core/connectivity.dart";
import "package:readintent_flutter/core/theme/app_colors.dart";
import "package:readintent_flutter/features/articles/models/article_view.dart";
import "package:readintent_flutter/features/articles/presentation/article_player_widget.dart";
import "package:readintent_flutter/features/articles/presentation/articles_screen.dart";
import "package:readintent_flutter/features/articles/presentation/mini_player_widget.dart";
import "package:readintent_flutter/features/articles/providers/article_player_provider.dart";
import "package:readintent_flutter/features/articles/providers/article_updates_hub.dart";
import "package:readintent_flutter/features/settings/presentation/settings_screen.dart";
import "package:readintent_flutter/features/tts/download_status_provider.dart";
import "package:readintent_flutter/features/tts/model_downloader.dart";
import "package:readintent_flutter/features/tts/presentation/download_status_bar.dart";

enum _ShellTab {
  inbox(
    view: ArticleView.inbox,
    icon: Icons.inbox_outlined,
    selectedIcon: Icons.inbox,
    label: "Inbox",
  ),
  favorite(
    view: ArticleView.favorite,
    icon: Icons.star_outline,
    selectedIcon: Icons.star,
    label: "Favorite",
  ),
  archive(
    view: ArticleView.archive,
    icon: Icons.archive_outlined,
    selectedIcon: Icons.archive,
    label: "Archive",
  ),
  settings(
    view: null, // null view => the Settings screen
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: "Settings",
  );

  const _ShellTab({
    required this.view,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final ArticleView? view;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  Widget get screen =>
      view == null ? const SettingsScreen() : ArticlesScreen(view: view!);

  NavigationDestination get destination => NavigationDestination(
    icon: Icon(icon),
    selectedIcon: Icon(selectedIcon),
    label: label,
  );
}

class PlayerShell extends ConsumerStatefulWidget {
  final Widget child;
  const PlayerShell({super.key, required this.child});

  @override
  ConsumerState<PlayerShell> createState() => _PlayerShellState();
}

class _PlayerShellState extends ConsumerState<PlayerShell>
    with WidgetsBindingObserver {
  int _selectedTabIndex = 0;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _bannerShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preloadModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncOfflineBanner(ref.read(isOnlineProvider));
    });
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

  void _syncOfflineBanner(bool isOnline) {
    final messenger = _messengerKey.currentState;
    if (messenger == null) return;
    if (!isOnline && !_bannerShowing) {
      _bannerShowing = true;
      final colors = context.appColors;
      messenger.showMaterialBanner(
        MaterialBanner(
          minActionBarHeight: 24,
          backgroundColor: colors.warning,
          dividerColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 22),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 16, color: colors.onWarning),
              const SizedBox(width: 8),
              Text(
                "You're offline",
                style: TextStyle(color: colors.onWarning, fontSize: 13),
              ),
            ],
          ),
          actions: const [SizedBox.shrink()],
        ),
      );
    } else if (isOnline && _bannerShowing) {
      _bannerShowing = false;
      messenger.hideCurrentMaterialBanner();
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
      ref.read(articleUpdatesHubProvider).suspend();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(articleUpdatesHubProvider).resume();
    }
  }

  /// Determine which bottom nav tab to highlight based on current route.
  int _computeSelectedIndex(String currentPath) {
    if (currentPath == "/home") return _selectedTabIndex;
    if (currentPath.startsWith("/articles/")) return _ShellTab.inbox.index;
    if (currentPath == "/pair-extension") return _ShellTab.settings.index;
    if (currentPath == "/voice-settings") return _ShellTab.settings.index;
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
    ref.watch(articleUpdatesHubProvider);
    ref.listen<bool>(
      isOnlineProvider,
      (_, isOnline) => _syncOfflineBanner(isOnline),
    );

    // Route detection
    final currentPath = GoRouterState.of(context).uri.path;
    final isOnHome = currentPath == "/home";
    String? routeArticleId;
    try {
      routeArticleId = GoRouterState.of(context).pathParameters["id"];
    } catch (_) {}
    final isOnMatchingDetail =
        routeArticleId != null && routeArticleId == activeState.articleId;

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Column(
        children: [
          // Main content area
          Expanded(
            child: isOnHome
                ? IndexedStack(
                    index: _selectedTabIndex,
                    children: [for (final t in _ShellTab.values) t.screen],
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

          // Bottom navigation bar.
          // NavigationBar's internal SafeArea would otherwise add a large padding at the top,
          MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: NavigationBar(
              selectedIndex: _computeSelectedIndex(currentPath),
              onDestinationSelected: (i) => _onTabSelected(i, isOnHome),
              destinations: [for (final t in _ShellTab.values) t.destination],
              height: 68,
            ),
          ),
        ],
      ),
    );
  }
}
