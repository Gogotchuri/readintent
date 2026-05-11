import "package:flutter/material.dart";
import "package:just_audio_background/just_audio_background.dart";
import "package:just_audio_media_kit/just_audio_media_kit.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:readintent_flutter/core/router.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  JustAudioMediaKit.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: "com.readintent.audio",
    androidNotificationChannelName: "Article Audio",
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
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
