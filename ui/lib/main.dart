import "package:audio_service/audio_service.dart";
import "package:flutter/material.dart";
import "package:just_audio_media_kit/just_audio_media_kit.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:readintent_flutter/core/router.dart";
import "package:readintent_flutter/core/theme/app_theme.dart";
import "package:readintent_flutter/features/articles/repository/pending_operations.dart";
import "package:readintent_flutter/features/settings/providers/app_settings_provider.dart";
import "package:readintent_flutter/features/tts/audio_handler.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  JustAudioMediaKit.ensureInitialized();

  final audioHandler = AppAudioHandler();

  runApp(
    ProviderScope(
      overrides: [audioHandlerProvider.overrideWithValue(audioHandler)],
      child: const MyApp(),
    ),
  );

  AudioService.init(
    builder: () => audioHandler,
    config: const AudioServiceConfig(
      androidNotificationChannelId: "com.readintent.audio",
      androidNotificationChannelName: "Article Audio",
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      fastForwardInterval: Duration(seconds: 10),
      rewindInterval: Duration(seconds: 10),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate the pending operations watcher so it processes queued ops on reconnect
    ref.watch(pendingOperationsWatcherProvider);

    final router = ref.watch(appRouterProvider);
    final textScale = ref.watch(appSettingsProvider.select((s) => s.textScale));
    final themeMode = ref.watch(appSettingsProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      routerConfig: router,
      title: "ReadIntent",
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // Apply the persisted global font scale to all text in the app.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    );
  }
}
