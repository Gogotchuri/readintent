import "dart:async";

import "package:fixnum/fixnum.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart";
import "package:mockito/annotations.dart";
import "package:mockito/mockito.dart";
import "package:readintent_flutter/features/articles/api/articles_client.dart";
import "package:readintent_flutter/features/articles/api/articles_client_exceptions.dart";
import "package:readintent_flutter/features/articles/presentation/article_detail_screen.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as articles_pb;

@GenerateMocks([ArticlesClient])
import "article_detail_screen_test.mocks.dart";

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
  late MockArticlesClient mockArticlesClient;
  late ProviderContainer container;

  setUp(() {
    mockArticlesClient = MockArticlesClient();
  });

  Widget createWidget({String articleId = "1"}) {
    container = ProviderContainer(
      overrides: [articlesServiceProvider.overrideWithValue(mockArticlesClient)],
    );
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: ArticleDetailScreen(articleId: articleId)),
    );
  }

  testWidgets("shows loading state", (WidgetTester tester) async {
    final completer = Completer<articles_pb.Article>();
    when(mockArticlesClient.getArticle(any)).thenAnswer((_) => completer.future);

    await tester.pumpWidget(createWidget());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text("Article"), findsOneWidget);
    expect(find.text("Test Article"), findsNothing);

    // Complete to avoid pending timer issues
    completer.complete(articleMock);
    await tester.pumpAndSettle();
  });

  testWidgets("shows error state with retry button", (WidgetTester tester) async {
    when(mockArticlesClient.getArticle(any)).thenThrow(
      ArticlesException("Server error"),
    );

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.textContaining("Server error"), findsOneWidget);
    expect(find.text("Retry"), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets("retry button re-fetches article", (WidgetTester tester) async {
    when(mockArticlesClient.getArticle(any)).thenThrow(
      ArticlesException("Server error"),
    );

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.textContaining("Server error"), findsOneWidget);

    // Re-stub to succeed on retry
    when(mockArticlesClient.getArticle(any)).thenAnswer((_) async => articleMock);

    await tester.tap(find.text("Retry"));
    await tester.pumpAndSettle();

    expect(find.text("Test Article"), findsWidgets);
  });

  testWidgets("shows article title in AppBar and header", (WidgetTester tester) async {
    when(mockArticlesClient.getArticle(any)).thenAnswer((_) async => articleMock);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.text("Test Article"), findsNWidgets(2));
  });

  testWidgets("shows author and date with icons", (WidgetTester tester) async {
    when(mockArticlesClient.getArticle(any)).thenAnswer((_) async => articleMock);

    await tester.pumpWidget(createWidget());
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
    when(mockArticlesClient.getArticle(any)).thenAnswer((_) async => emptyArticle);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_outline), findsNothing);
    expect(find.byIcon(Icons.calendar_today_outlined), findsNothing);
  });

  testWidgets("shows image when URL is non-empty", (WidgetTester tester) async {
    when(mockArticlesClient.getArticle(any)).thenAnswer((_) async => articleMock);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets("hides image when URL is empty", (WidgetTester tester) async {
    final noImageArticle = articles_pb.Article(
      id: Int64(1),
      title: "Test Article",
      extractedHtml: "<p>Hello world</p>",
    );
    when(mockArticlesClient.getArticle(any)).thenAnswer((_) async => noImageArticle);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
  });

  testWidgets("renders HtmlWidget with extracted HTML", (WidgetTester tester) async {
    when(mockArticlesClient.getArticle(any)).thenAnswer((_) async => articleMock);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.byType(HtmlWidget), findsOneWidget);
  });

  testWidgets("shows audio player placeholder", (WidgetTester tester) async {
    when(mockArticlesClient.getArticle(any)).thenAnswer((_) async => articleMock);

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text("Audio player - TODO"), findsOneWidget);
  });
}
