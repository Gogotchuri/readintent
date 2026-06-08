import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:readintent_flutter/features/auth/providers/auth_provider.dart";
import "package:readintent_flutter/features/settings/providers/app_settings_provider.dart";

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.watch(appSettingsProvider.select((s) => s.voice));
    final themeMode = ref.watch(appSettingsProvider.select((s) => s.themeMode));
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.extension),
            title: const Text("Pair Extension"),
            subtitle: const Text("Connect your browser extension"),
            onTap: () => context.push("/pair-extension"),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.record_voice_over),
            title: const Text("Voice"),
            subtitle: Text(voice.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push("/voice-settings"),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text("Appearance"),
            subtitle: Text(_themeModeLabel(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeModeSheet(context, ref, themeMode),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }

  static String _themeModeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => "System default",
    ThemeMode.light => "Light",
    ThemeMode.dark => "Dark",
  };

  void _showThemeModeSheet(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: RadioGroup<ThemeMode>(
            groupValue: current,
            onChanged: (selected) {
              if (selected != null) {
                ref.read(appSettingsProvider.notifier).setThemeMode(selected);
              }
              Navigator.of(sheetContext).pop();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    value: mode,
                    title: Text(_themeModeLabel(mode)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
