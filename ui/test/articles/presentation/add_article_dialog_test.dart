import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:readintent_flutter/features/articles/models/article_view.dart";
import "package:readintent_flutter/features/articles/presentation/add_article_dialog.dart";
import "package:readintent_flutter/features/articles/providers/articles_provider.dart";
import "package:readintent_flutter/features/articles/repository/article_repository.dart";

void main() {
  Widget createWidget({required _TestArticles Function() createNotifier}) {
    final container = ProviderContainer(
      overrides: [
        // ignore: deprecated_member_use
        articlesProvider(ArticleView.inbox).overrideWith(createNotifier),
      ],
    );
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddArticleDialog(),
              ),
              child: const Text("Open"),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text("Open"));
    await tester.pumpAndSettle();
  }

  testWidgets("renders URL input and buttons", (tester) async {
    await tester.pumpWidget(
      createWidget(createNotifier: () => _TestArticles()),
    );
    await openDialog(tester);

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text("Cancel"), findsOneWidget);
    expect(find.text("Add"), findsOneWidget);
  });

  testWidgets("validates empty URL", (tester) async {
    await tester.pumpWidget(
      createWidget(createNotifier: () => _TestArticles()),
    );
    await openDialog(tester);

    await tester.tap(find.text("Add"));
    await tester.pumpAndSettle();

    expect(find.text("Please enter a URL"), findsOneWidget);
  });

  testWidgets("validates malformed URL", (tester) async {
    await tester.pumpWidget(
      createWidget(createNotifier: () => _TestArticles()),
    );
    await openDialog(tester);

    await tester.enterText(find.byType(TextFormField), "not-a-url");
    await tester.tap(find.text("Add"));
    await tester.pumpAndSettle();

    expect(find.text("Please enter a valid URL"), findsOneWidget);
  });

  testWidgets("shows snackbar when article queued (offline)", (tester) async {
    await tester.pumpWidget(
      createWidget(
        createNotifier: () =>
            _TestArticles(parseResult: ParseArticleResult(queued: true)),
      ),
    );
    await openDialog(tester);

    await tester.enterText(
      find.byType(TextFormField),
      "https://example.com/article",
    );
    await tester.tap(find.text("Add"));
    await tester.pumpAndSettle();

    expect(
      find.text("Article will be added when you're back online"),
      findsOneWidget,
    );
  });

  testWidgets("no snackbar when article added immediately (online)", (
    tester,
  ) async {
    await tester.pumpWidget(
      createWidget(
        createNotifier: () =>
            _TestArticles(parseResult: ParseArticleResult(queued: false)),
      ),
    );
    await openDialog(tester);

    await tester.enterText(
      find.byType(TextFormField),
      "https://example.com/article",
    );
    await tester.tap(find.text("Add"));
    await tester.pumpAndSettle();

    expect(
      find.text("Article will be added when you're back online"),
      findsNothing,
    );
  });

  testWidgets("shows error message on failure", (tester) async {
    await tester.pumpWidget(
      createWidget(
        createNotifier: () => _TestArticles(parseError: "Something went wrong"),
      ),
    );
    await openDialog(tester);

    await tester.enterText(
      find.byType(TextFormField),
      "https://example.com/article",
    );
    await tester.tap(find.text("Add"));
    await tester.pumpAndSettle();

    expect(find.textContaining("Something went wrong"), findsOneWidget);
  });

  testWidgets("closes dialog on success", (tester) async {
    await tester.pumpWidget(
      createWidget(
        createNotifier: () =>
            _TestArticles(parseResult: ParseArticleResult(queued: false)),
      ),
    );
    await openDialog(tester);
    expect(find.byType(AddArticleDialog), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField),
      "https://example.com/article",
    );
    await tester.tap(find.text("Add"));
    await tester.pumpAndSettle();

    expect(find.byType(AddArticleDialog), findsNothing);
  });
}

class _TestArticles extends Articles {
  final ParseArticleResult? parseResult;
  final String? parseError;

  _TestArticles({this.parseResult, this.parseError});

  @override
  Future<ArticlesState> build(ArticleView? view) async => const ArticlesState();

  @override
  Future<ParseArticleResult> parseArticle(String url) async {
    if (parseError != null) throw Exception(parseError);
    return parseResult ?? ParseArticleResult(queued: false);
  }

  @override
  Future<void> refresh() async {}
}
