import "dart:typed_data";

import "package:just_audio/just_audio.dart";
import "package:wav/wav.dart";

class PhonemeChunk {
  final String graphemes;
  final List<int> tokenIds;
  final List<TokenMeta> tokenMeta;

  const PhonemeChunk({required this.graphemes, required this.tokenIds, required this.tokenMeta});
}

class TokenMeta {
  final String text;
  final int phonemeLen;
  final bool hasWhitespace;

  const TokenMeta({required this.text, required this.phonemeLen, required this.hasWhitespace});
}

class WordTimestamp {
  final String word;
  final double start;
  final double end;

  const WordTimestamp({required this.word, required this.start, required this.end});

  @override
  String toString() => '"$word" ${start.toStringAsFixed(3)}s - ${end.toStringAsFixed(3)}s';
}

class KokoroResult {
  final Float32List audio;
  final List<WordTimestamp> timestamps;
  final String graphemes;

  const KokoroResult({required this.audio, required this.timestamps, required this.graphemes});
}
