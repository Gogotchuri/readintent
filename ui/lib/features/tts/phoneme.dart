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

class AudioStream extends StreamAudioSource {
  final Uint8List _audioBytes;

  AudioStream(this._audioBytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _audioBytes.length;
    final contentLen = end - start;
    final stream = Stream.value(Uint8List.sublistView(_audioBytes, start, end));
    return StreamAudioResponse(
      sourceLength: _audioBytes.length,
      contentLength: contentLen,
      offset: start,
      stream: stream,
      contentType: "audio/wav",
    );
  }
}

class KokoroResult {
  final Float32List audio;
  final List<WordTimestamp> timestamps;
  final String graphemes;

  const KokoroResult({required this.audio, required this.timestamps, required this.graphemes});

  Wav getWavAudio() {
    return Wav(
      [Float64List.fromList(audio.map((e) => e.toDouble()).toList())],
      24000, // Default sample rate for Kokoro
    );
  }

  // TODO this will work for a single chunk, but we need to handle multiple chunks and combine their timestamps and audio properly
  AudioStream getAudioStream() {
    final wav = getWavAudio();
    final wavBytes = Uint8List.fromList(wav.write());
    return AudioStream(wavBytes);
  }
}
