import "dart:async";

import "package:fixnum/fixnum.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart";
import "package:readintent_flutter/features/articles/presentation/article_detail_screen.dart";
import "package:readintent_flutter/features/articles/providers/article_detail_provider.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as articles_pb;

final articleMock = articles_pb.Article(
  id: Int64(1),
  title: "Test Article",
  author: "John Doe",
  date: "2026-01-15",
  extractedHtml: "<p>Hello world</p>",
  url: "https://example.com/article",
  description: "A test article",
  image: "https://example.com/image.jpg",
);

void main() {
  Widget createWidget({
    String articleId = "1",
    required Future<articles_pb.Article> Function() fetchArticle,
  }) {
    final container = ProviderContainer(
      overrides: [
        // ignore: deprecated_member_use
        articleDetailProvider.overrideWith(() => _TestArticleDetail(fetchArticle)),
      ],
    );
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: ArticleDetailScreen(articleId: articleId)),
    );
  }

  testWidgets("shows loading state", (WidgetTester tester) async {
    final completer = Completer<articles_pb.Article>();

    await tester.pumpWidget(createWidget(
      fetchArticle: () => completer.future,
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text("Article"), findsOneWidget);

    completer.complete(articleMock);
    await tester.pumpAndSettle();
  });

  testWidgets("shows error state with retry button", (WidgetTester tester) async {
    await tester.pumpWidget(createWidget(
      fetchArticle: () => throw Exception("Server error"),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining("Server error"), findsOneWidget);
    expect(find.text("Retry"), findsOneWidget);
  });

  testWidgets("shows article title in AppBar and header", (WidgetTester tester) async {
    await tester.pumpWidget(createWidget(
      fetchArticle: () async => articleMock,
    ));
    await tester.pumpAndSettle();

    expect(find.text("Test Article"), findsNWidgets(2));
  });

  testWidgets("shows author and date with icons", (WidgetTester tester) async {
    await tester.pumpWidget(createWidget(
      fetchArticle: () async => articleMock,
    ));
    await tester.pumpAndSettle();

    expect(find.text("John Doe"), findsOneWidget);
    expect(find.text("2026-01-15"), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
  });

  testWidgets("hides author and date when empty", (WidgetTester tester) async {
    final emptyArticle = articles_pb.Article(
      id: Int64(1),
      title: "Test Article",
      extractedHtml: "<p>Hello world</p>",
    );
    await tester.pumpWidget(createWidget(
      fetchArticle: () async => emptyArticle,
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_outline), findsNothing);
    expect(find.byIcon(Icons.calendar_today_outlined), findsNothing);
  });

  testWidgets("hides image when URL is empty", (WidgetTester tester) async {
    final noImageArticle = articles_pb.Article(
      id: Int64(1),
      title: "Test Article",
      extractedHtml: "<p>Hello world</p>",
    );
    await tester.pumpWidget(createWidget(
      fetchArticle: () async => noImageArticle,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
  });

  testWidgets("renders HtmlWidget with extracted HTML", (WidgetTester tester) async {
    await tester.pumpWidget(createWidget(
      fetchArticle: () async => articleMock,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(HtmlWidget), findsOneWidget);
  });
}

class _TestArticleDetail extends ArticleDetail {
  final Future<articles_pb.Article> Function() _fetchArticle;
  _TestArticleDetail(this._fetchArticle);

  @override
  Future<articles_pb.Article> build(String id) => _fetchArticle();
}
