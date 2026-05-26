import "package:readintent_flutter/features/tts/phoneme.dart";

/// Pre-computed sentence text boundary from phonemizer token metadata.
class SentenceText {
  final int index;
  final String text;
  final int wordCount; // Number of phoneme-bearing tokens in this sentence

  const SentenceText({
    required this.index,
    required this.text,
    required this.wordCount,
  });
}

final _sentenceEndPattern = RegExp(r"[.?!]$");

/// Walks all chunks' tokenMeta sequentially, grouping tokens into sentences
/// by detecting sentence-ending punctuation at the end of a token's text.
/// Tracks the number of phoneme-bearing tokens (words) per sentence so that
/// [assignSentenceTimestamps] can directly slice the word timestamps list.
List<SentenceText> buildSentenceTexts(List<PhonemeChunk> chunks) {
  final sentences = <SentenceText>[];
  final buffer = StringBuffer();
  int wordsInSentence = 0;

  for (final chunk in chunks) {
    for (final token in chunk.tokenMeta) {
      if (token.phonemeLen == 0 && token.text.trim().isEmpty) continue;

      if (buffer.isNotEmpty) buffer.write(" ");
      buffer.write(token.text);

      // Only tokens with phonemes produce a WordTimestamp
      if (token.phonemeLen > 0) wordsInSentence++;

      if (_sentenceEndPattern.hasMatch(token.text.trim())) {
        sentences.add(SentenceText(
          index: sentences.length,
          text: buffer.toString().trim(),
          wordCount: wordsInSentence,
        ));
        buffer.clear();
        wordsInSentence = 0;
      }
    }
  }

  if (buffer.isNotEmpty) {
    sentences.add(SentenceText(
      index: sentences.length,
      text: buffer.toString().trim(),
      wordCount: wordsInSentence,
    ));
  }

  return sentences;
}

/// Assigns timestamps to pre-computed sentence boundaries using word timestamps.
/// Each sentence knows its [wordCount] (phoneme-bearing tokens), so we just
/// slice that many entries from the dense word timestamps list.
List<SentenceTimestamp> assignSentenceTimestamps(
  List<SentenceText> sentences,
  List<WordTimestamp> wordTimestamps,
) {
  if (sentences.isEmpty || wordTimestamps.isEmpty) return [];

  final result = <SentenceTimestamp>[];
  int wordIdx = 0;

  for (final sentence in sentences) {
    if (sentence.wordCount == 0 || wordIdx >= wordTimestamps.length) continue;

    final firstWord = wordIdx;
    final lastWord = (wordIdx + sentence.wordCount - 1).clamp(0, wordTimestamps.length - 1);
    wordIdx = lastWord + 1;

    result.add(SentenceTimestamp(
      index: sentence.index,
      text: sentence.text,
      startSeconds: wordTimestamps[firstWord].start,
      endSeconds: wordTimestamps[lastWord].end,
      startWordIndex: firstWord,
      endWordIndex: lastWord,
    ));
  }

  return result;
}
