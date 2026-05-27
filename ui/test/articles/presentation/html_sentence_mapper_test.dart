import "package:flutter_test/flutter_test.dart";
import "package:readintent_flutter/features/articles/presentation/html_sentence_mapper.dart";
import "package:readintent_flutter/features/tts/sentence_builder.dart";

/// Helper to build a [SentenceText] with only the fields the mapper uses.
SentenceText _sentence(int index, String text) => SentenceText(index: index, text: text, wordCount: 0);

void main() {
  group("injectSentenceSpans", () {
    test("returns html unchanged when sentences list is empty", () {
      const html = "<p>Hello world.</p>";
      expect(injectSentenceSpans(html, []), html);
    });

    test("wraps a single sentence in one paragraph", () {
      const html = "<p>Hello world.</p>";
      final result = injectSentenceSpans(html, [_sentence(0, "Hello world.")]);

      expect(result, contains('data-sentence="0"'));
      expect(result, contains('id="sentence-0"'));
      expect(result, contains("Hello world."));
    });

    test("wraps two consecutive sentences in one paragraph", () {
      const html = "<p>First sentence. Second sentence.</p>";
      final result = injectSentenceSpans(html, [
        _sentence(0, "First sentence."),
        _sentence(1, "Second sentence."),
      ]);

      expect(result, contains('data-sentence="0"'));
      expect(result, contains('data-sentence="1"'));
    });

    test("wraps sentences across multiple paragraphs", () {
      const html = "<p>First.</p><p>Second.</p>";
      final result = injectSentenceSpans(html, [_sentence(0, "First."), _sentence(1, "Second.")]);

      expect(result, contains('data-sentence="0"'));
      expect(result, contains('data-sentence="1"'));
    });

    test("handles sentence spanning multiple HTML tags", () {
      const html = "<p>Start of <b>sentence</b> here.</p>";
      final result = injectSentenceSpans(html, [_sentence(0, "Start of sentence here.")]);

      // The sentence should be wrapped across the text nodes
      expect(result, contains('data-sentence="0"'));
      // The bold tag should still exist
      expect(result, contains("<b>"));
    });

    test("preserves HTML structure around sentences", () {
      const html = '<p>Hello.</p><div class="x">World.</div>';
      final result = injectSentenceSpans(html, [_sentence(0, "Hello."), _sentence(1, "World.")]);

      expect(result, contains('<div class="x"'));
      expect(result, contains('data-sentence="0"'));
      expect(result, contains('data-sentence="1"'));
    });

    test("handles text with extra whitespace", () {
      const html = "<p>  Hello   world.  </p>";
      final result = injectSentenceSpans(html, [_sentence(0, "Hello world.")]);

      expect(result, contains('data-sentence="0"'));
    });

    test("stops gracefully when sentence text not found in HTML", () {
      const html = "<p>Hello world.</p>";
      final result = injectSentenceSpans(html, [
        _sentence(0, "Hello world."),
        _sentence(1, "This does not exist."),
      ]);

      // First sentence should still be wrapped
      expect(result, contains('data-sentence="0"'));
      // Second should not appear
      expect(result, isNot(contains('data-sentence="1"')));
    });

    test("returns html unchanged when no text nodes exist", () {
      const html = '<img src="test.png"/>';
      final result = injectSentenceSpans(html, [_sentence(0, "Hello.")]);
      // Should not crash, just return as-is (serialized)
      expect(result, isNotEmpty);
    });

    test("handles nested inline tags", () {
      const html = "<p>A <em>quick <b>brown</b></em> fox.</p>";
      final result = injectSentenceSpans(html, [_sentence(0, "A quick brown fox.")]);

      expect(result, contains('data-sentence="0"'));
      expect(result, contains("<em>"));
      expect(result, contains("<b>"));
    });

    test("leaves text before and after sentence unwrapped", () {
      const html = "<p>Before. Target. After.</p>";
      final result = injectSentenceSpans(html, [_sentence(0, "Target.")]);

      expect(result, contains('data-sentence="0"'));
      // "Before." should not be in a span
      expect(result, isNot(contains('data-sentence="0">Before')));
    });

    test("handles empty html", () {
      expect(injectSentenceSpans("", [_sentence(0, "Hello.")]), isEmpty);
    });

    test("handles multiple sentences with punctuation-only separators", () {
      const html = "<p>First? Second! Third.</p>";
      final result = injectSentenceSpans(html, [
        _sentence(0, "First?"),
        _sentence(1, "Second!"),
        _sentence(2, "Third."),
      ]);

      expect(result, contains('data-sentence="0"'));
      expect(result, contains('data-sentence="1"'));
      expect(result, contains('data-sentence="2"'));
    });
  });
}
