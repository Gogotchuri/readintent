import "package:audio_service/audio_service.dart";
import "package:flutter/material.dart";
import "package:just_audio_media_kit/just_audio_media_kit.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:readintent_flutter/core/router.dart";
import "package:readintent_flutter/features/tts/audio_handler.dart";

late final ArticleAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  JustAudioMediaKit.ensureInitialized();

  audioHandler = await AudioService.init(
    builder: () => ArticleAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: "com.readintent.audio",
      androidNotificationChannelName: "Article Audio",
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      routerConfig: router,
      title: "ReadIntent",
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}
