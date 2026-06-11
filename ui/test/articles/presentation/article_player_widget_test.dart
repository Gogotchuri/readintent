import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

import "package:readintent_flutter/features/articles/presentation/article_player_widget.dart";
import "package:readintent_flutter/features/articles/providers/article_player_provider.dart";

void main() {
  Widget buildWidget({required ActivePlayerState state}) {
    return ProviderScope(
      overrides: [
        activePlayerProvider.overrideWith(() {
          return _FakeActivePlayer(state);
        }),
      ],
      child: const MaterialApp(home: Scaffold(body: ArticlePlayerWidget())),
    );
  }

  group("ArticlePlayerWidget", () {
    testWidgets("shows play button when not playing", (tester) async {
      await tester.pumpWidget(
        buildWidget(state: const ActivePlayerState(articleId: "1")),
      );

      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    });

    testWidgets("shows pause button when playing", (tester) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(articleId: "1", isPlaying: true),
        ),
      );

      expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
    });

    testWidgets("shows loading spinner when loading", (tester) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(articleId: "1", isLoading: true),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets("shows time labels", (tester) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(
            articleId: "1",
            position: Duration(seconds: 30),
            estimatedDuration: Duration(minutes: 5),
            ttsComplete: true,
          ),
        ),
      );

      expect(find.text("00:30"), findsOneWidget);
      expect(find.text("05:00"), findsOneWidget);
    });

    testWidgets("shows generating indicator during TTS", (tester) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(
            articleId: "1",
            bufferedDuration: Duration(seconds: 10),
            ttsComplete: false,
          ),
        ),
      );

      expect(find.text("Generating..."), findsOneWidget);
    });

    testWidgets("shows error message", (tester) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(
            articleId: "1",
            error: "Something failed",
          ),
        ),
      );

      expect(find.text("Something failed"), findsOneWidget);
    });

    // --- Progress Slider ---

    testWidgets("slider value reflects position/estimatedDuration ratio", (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(
            articleId: "1",
            position: Duration(seconds: 30),
            estimatedDuration: Duration(seconds: 60),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, closeTo(0.5, 0.01));
    });

    testWidgets("slider disabled when estimatedDuration is zero", (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(
            articleId: "1",
            position: Duration.zero,
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.onChanged, isNull);
    });

    testWidgets("slider enabled when estimatedDuration is non-zero", (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(
            articleId: "1",
            position: Duration(seconds: 10),
            estimatedDuration: Duration(seconds: 60),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.onChanged, isNotNull);
    });

    // --- Button States ---

    testWidgets("skip backward disabled at position=0", (tester) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(
            articleId: "1",
            position: Duration.zero,
            isPlaying: true,
          ),
        ),
      );

      final backButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.replay_10),
      );
      expect(backButton.onPressed, isNull);
    });

    testWidgets("skip backward enabled at position>0", (tester) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(
            articleId: "1",
            position: Duration(seconds: 5),
            isPlaying: true,
          ),
        ),
      );

      final backButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.replay_10),
      );
      expect(backButton.onPressed, isNotNull);
    });

    testWidgets(
      "skip forward disabled when position+15s > bufferedDuration and not complete",
      (tester) async {
        await tester.pumpWidget(
          buildWidget(
            state: const ActivePlayerState(
              articleId: "1",
              position: Duration(seconds: 10),
              bufferedDuration: Duration(seconds: 20),
              ttsComplete: false,
              isPlaying: true,
            ),
          ),
        );

        final fwdButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.forward_10),
        );
        expect(fwdButton.onPressed, isNull);
      },
    );

    testWidgets("skip forward enabled when ttsComplete", (tester) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(
            articleId: "1",
            position: Duration(seconds: 10),
            bufferedDuration: Duration(seconds: 20),
            ttsComplete: true,
            isPlaying: true,
          ),
        ),
      );

      final fwdButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.forward_10),
      );
      expect(fwdButton.onPressed, isNotNull);
    });

    testWidgets("skip forward enabled when position+15s <= bufferedDuration", (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(
            articleId: "1",
            position: Duration(seconds: 5),
            bufferedDuration: Duration(seconds: 30),
            ttsComplete: false,
            isPlaying: true,
          ),
        ),
      );

      final fwdButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.forward_10),
      );
      expect(fwdButton.onPressed, isNotNull);
    });

    // --- Display States ---

    testWidgets("end time shows --:-- when estimatedDuration is null", (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(state: const ActivePlayerState(articleId: "1")),
      );

      expect(find.text("--:--"), findsOneWidget);
    });

    testWidgets("end time shows ~MM:SS during generation", (tester) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(
            articleId: "1",
            estimatedDuration: Duration(minutes: 5),
            ttsComplete: false,
            bufferedDuration: Duration(seconds: 10),
          ),
        ),
      );

      expect(find.text("~05:00"), findsOneWidget);
    });

    testWidgets("end time shows MM:SS when complete", (tester) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(
            articleId: "1",
            estimatedDuration: Duration(minutes: 5),
            ttsComplete: true,
          ),
        ),
      );

      expect(find.text("05:00"), findsOneWidget);
    });

    testWidgets("Generating... hidden when ttsComplete", (tester) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(
            articleId: "1",
            bufferedDuration: Duration(seconds: 10),
            ttsComplete: true,
          ),
        ),
      );

      expect(find.text("Generating..."), findsNothing);
    });

    testWidgets("Generating... hidden when bufferedDuration=0", (tester) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(
            articleId: "1",
            bufferedDuration: Duration.zero,
            ttsComplete: false,
          ),
        ),
      );

      expect(find.text("Generating..."), findsNothing);
    });

    testWidgets("error text displayed in error color", (tester) async {
      await tester.pumpWidget(
        buildWidget(
          state: const ActivePlayerState(
            articleId: "1",
            error: "Network failure",
          ),
        ),
      );

      final context = tester.element(find.text("Network failure"));
      final errorText = tester.widget<Text>(find.text("Network failure"));
      expect(errorText.style?.color, Theme.of(context).colorScheme.error);
    });
  });
}

class _FakeActivePlayer extends ActivePlayer {
  final ActivePlayerState _initialState;
  _FakeActivePlayer(this._initialState);

  @override
  ActivePlayerState build() => _initialState;
}
