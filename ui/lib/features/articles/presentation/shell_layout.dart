import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:readintent_flutter/core/connectivity.dart";
import "package:readintent_flutter/features/articles/presentation/articles_screen.dart";
import "package:readintent_flutter/features/auth/providers/auth_provider.dart";

class ShellLayout extends ConsumerStatefulWidget {
  const ShellLayout({super.key});

  @override
  ConsumerState<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends ConsumerState<ShellLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.menu_book, size: 32),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: "Logout",
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                    },
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.article_outlined),
                selectedIcon: Icon(Icons.article),
                label: Text("Articles"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text("Settings"),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final isOnline = ref.watch(isOnlineProvider);
                    if (isOnline) return const SizedBox.shrink();
                    return Container(
                      width: double.infinity,
                      color: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text("You're offline", style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const ArticlesScreen();
      case 1:
        // Settings will be used to sync with the extension
        return const Center(child: Text("Settings - ..."));
      default:
        return const SizedBox.shrink();
    }
  }
}
