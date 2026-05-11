import "package:fixnum/fixnum.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

import "package:readintent_flutter/features/articles/presentation/article_player_widget.dart";
import "package:readintent_flutter/features/articles/providers/article_player_provider.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as articles_pb;

void main() {
  late articles_pb.Article article;

  setUp(() {
    article = articles_pb.Article(
      id: Int64(1),
      title: "Test Article",
      author: "Test Author",
      status: "ready",
    );
  });

  Widget buildWidget({ArticlePlayerState? overrideState}) {
    return ProviderScope(
      overrides: [
        if (overrideState != null)
          articlePlayerProvider("1").overrideWith(() {
            return _FakeArticlePlayer(overrideState);
          }),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ArticlePlayerWidget(article: article),
        ),
      ),
    );
  }

  group("ArticlePlayerWidget", () {
    testWidgets("shows play button in initial state", (tester) async {
      await tester.pumpWidget(buildWidget(
        overrideState: const ArticlePlayerState(),
      ));

      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    });

    testWidgets("shows pause button when playing", (tester) async {
      await tester.pumpWidget(buildWidget(
        overrideState: const ArticlePlayerState(isPlaying: true),
      ));

      expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
    });

    testWidgets("shows loading spinner when loading", (tester) async {
      await tester.pumpWidget(buildWidget(
        overrideState: const ArticlePlayerState(isLoading: true),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets("shows time labels", (tester) async {
      await tester.pumpWidget(buildWidget(
        overrideState: const ArticlePlayerState(
          position: Duration(seconds: 30),
          estimatedDuration: Duration(minutes: 5),
        ),
      ));

      expect(find.text("00:30"), findsOneWidget);
      expect(find.text("05:00"), findsOneWidget);
    });

    testWidgets("shows generating indicator during TTS", (tester) async {
      await tester.pumpWidget(buildWidget(
        overrideState: const ArticlePlayerState(
          bufferedDuration: Duration(seconds: 10),
          ttsComplete: false,
        ),
      ));

      expect(find.text("Generating..."), findsOneWidget);
    });

    testWidgets("shows error message", (tester) async {
      await tester.pumpWidget(buildWidget(
        overrideState: const ArticlePlayerState(error: "Something failed"),
      ));

      expect(find.text("Something failed"), findsOneWidget);
    });
  });
}

class _FakeArticlePlayer extends ArticlePlayer {
  final ArticlePlayerState _initialState;
  _FakeArticlePlayer(this._initialState);

  @override
  ArticlePlayerState build(String articleId) => _initialState;
}
