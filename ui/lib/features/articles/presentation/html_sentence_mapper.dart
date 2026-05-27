import "package:html/dom.dart" as dom;
import "package:html/parser.dart" as html_parser;

import "package:readintent_flutter/features/tts/sentence_builder.dart";

/// Injects `<span data-sentence="N">` markers around sentence text in HTML.
/// Used for text highlighting during TTS playback.
///
/// Walks DOM text nodes and sentence texts in parallel with normalized
/// whitespace matching. Sentences that span multiple text nodes produce
/// multiple spans with the same `data-sentence` attribute.
///
/// Returns the modified HTML string. If matching fails mid-way, remaining
/// sentences are left unmarked (graceful degradation).
String injectSentenceSpans(String html, List<SentenceText> sentences) {
  if (sentences.isEmpty) return html;

  final doc = html_parser.parseFragment(html);
  final textNodes = _collectTextNodes(doc);
  if (textNodes.isEmpty) return html;

  int currentNode = 0;
  int currentChar = 0;

  for (final sentence in sentences) {
    final words = sentence.text.split(RegExp(r"\s+"));
    if (words.isEmpty) continue;

    final match = _findAndWrapSentence(textNodes, currentNode, currentChar, words, sentence.index);
    if (match == null) break; // Graceful degradation

    currentNode = match.nodeIndex;
    currentChar = match.charOffset;
  }

  return _serializeFragment(doc);
}

/// Collects all non-empty text nodes from the DOM in document order.
List<dom.Text> _collectTextNodes(dom.Node node) {
  final result = <dom.Text>[];
  for (final child in node.nodes) {
    if (child is dom.Text) {
      if (child.data.trim().isNotEmpty) result.add(child);
    } else {
      result.addAll(_collectTextNodes(child));
    }
  }
  return result;
}

/// Serializes a DocumentFragment back to HTML.
String _serializeFragment(dom.DocumentFragment doc) {
  final buffer = StringBuffer();
  for (final node in doc.nodes) {
    if (node is dom.Element) {
      buffer.write(node.outerHtml);
    } else if (node is dom.Text) {
      buffer.write(node.data);
    }
  }
  return buffer.toString();
}

/// Helper class to track position in text nodes during matching.
class _Cursor {
  final int nodeIndex;
  final int charOffset;
  _Cursor(this.nodeIndex, this.charOffset);
}

/// Finds all [words] sequentially in [textNodes] starting from the given
/// position, then wraps matched text portions in `<span data-sentence="N">`.
/// Returns the cursor position after the last matched word, or null on failure.
_Cursor? _findAndWrapSentence(
  List<dom.Text> textNodes,
  int startNode,
  int startChar,
  List<String> words,
  int sentenceIndex,
) {
  int nodeIdx = startNode;
  int charIdx = startChar;

  // Track which range of each text node belongs to this sentence
  // Key: index into textNodes, Value: (start, end) char range
  final nodeRanges = <int, (int, int)>{};
  int? firstNode;

  for (final word in words) {
    // Find this word in the current (or subsequent) text node
    final found = _findWord(textNodes, nodeIdx, charIdx, word);
    if (found == null) return null;

    nodeIdx = found.nodeIndex;
    final wordStart = found.charOffset;
    final wordEnd = wordStart + word.length;

    firstNode ??= nodeIdx;

    // Extend or create the range for this text node
    final existing = nodeRanges[nodeIdx];
    if (existing != null) {
      nodeRanges[nodeIdx] = (existing.$1, wordEnd);
    } else {
      nodeRanges[nodeIdx] = (wordStart, wordEnd);
    }

    charIdx = wordEnd;
  }

  // Wrap matched ranges in reverse node order so DOM mutations
  // on higher-index nodes don't shift positions of lower-index ones.
  final wrappedNodes = nodeRanges.keys.toList()..sort((a, b) => b.compareTo(a));
  for (final ni in wrappedNodes) {
    final (start, end) = nodeRanges[ni]!;
    // Add an id anchor only on the first span of each sentence
    final anchorId = ni == firstNode ? "sentence-$sentenceIndex" : null;
    final afterNode = _wrapTextRange(textNodes[ni], start, end, sentenceIndex, anchorId: anchorId);
    // Replace the old (now detached) text node reference with the leftover
    // "after" text node so the next sentence can find remaining text.
    if (afterNode != null) {
      textNodes[ni] = afterNode;
    }
  }

  // charIdx was computed against the original text node content.
  // If that node was wrapped, textNodes[nodeIdx] is now the "after" portion,
  // which starts at what was `end` in the original. Shift accordingly.
  final wrappedRange = nodeRanges[nodeIdx];
  final adjustedCharIdx = wrappedRange != null ? charIdx - wrappedRange.$2 : charIdx;

  return _Cursor(nodeIdx, adjustedCharIdx.clamp(0, double.maxFinite.toInt()));
}

/// Scans forward through text nodes to find [word] starting at the given position.
_Cursor? _findWord(List<dom.Text> textNodes, int nodeIdx, int charIdx, String word) {
  while (nodeIdx < textNodes.length) {
    final text = textNodes[nodeIdx].data;

    // Skip whitespace at current position
    int i = charIdx;
    while (i < text.length && text[i].trim().isEmpty) {
      i++;
    }

    // Try exact match at current position first
    if (i + word.length <= text.length && text.substring(i, i + word.length) == word) {
      return _Cursor(nodeIdx, i);
    }

    // Fall back to searching the rest of this text node
    final idx = text.indexOf(word, i);
    if (idx >= 0) return _Cursor(nodeIdx, idx);

    // Move to next text node
    nodeIdx++;
    charIdx = 0;
  }
  return null;
}

/// Splits a text node and wraps the [start]..[end] range in a
/// `<span data-sentence="N">` element.
/// Returns the "after" [dom.Text] node if one was created, so the caller
/// can update its text node list for subsequent matching.
dom.Text? _wrapTextRange(dom.Text textNode, int start, int end, int sentenceIndex, {String? anchorId}) {
  final text = textNode.data;
  final parent = textNode.parentNode;
  if (parent == null) return null;

  final clampedEnd = end.clamp(0, text.length);
  if (start >= clampedEnd || start >= text.length) return null;

  // Removed the matched text portion from the original text node
  final before = text.substring(0, start);
  final matched = text.substring(start, clampedEnd);
  final after = text.substring(clampedEnd);

  final nodeIndex = parent.nodes.indexOf(textNode);
  if (nodeIndex < 0) return null;

  parent.nodes.removeAt(nodeIndex);

  
  int insertAt = nodeIndex;
  if (before.isNotEmpty) {
    parent.nodes.insert(insertAt, dom.Text(before));
    insertAt++;
  }

  final span = dom.Element.tag("span")
    ..attributes["data-sentence"] = sentenceIndex.toString();
  if (anchorId != null) {
    span.attributes["id"] = anchorId;
  }
  span.append(dom.Text(matched));
  parent.nodes.insert(insertAt, span);
  insertAt++;

  dom.Text? afterNode;
  if (after.isNotEmpty) {
    afterNode = dom.Text(after);
    parent.nodes.insert(insertAt, afterNode);
  }
  return afterNode;
}
