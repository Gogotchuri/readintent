import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:readintent_flutter/features/tts/growing_audio_file.dart";

void main() {
  group("GrowableAudioStream", () {
    test("starts with zero buffered duration", () {
      final stream = GrowingAudioFile();
      expect(stream.bufferedDuration, Duration.zero);
    });

    test("bufferedDuration increases as samples are added", () {
      final stream = GrowingAudioFile();
      // 24000 samples = 1 second at 24kHz
      stream.addSamples(Float32List(24000));
      expect(stream.bufferedDuration.inMilliseconds, 1000);
    });

    test("isEnded reflects endStream call", () {
      final stream = GrowingAudioFile();
      expect(stream.isEnded, false);
      stream.endStream();
      expect(stream.isEnded, true);
    });

    test("double addSamples returns correct duration", () {
      final stream = GrowingAudioFile();
      stream.addSamples(Float32List(12000)); // 0.5s
      stream.addSamples(Float32List(12000)); // 0.5s
      expect(stream.bufferedDuration.inMilliseconds, 1000);
    });

    test("encodeSamples produces valid MP3 frames", () async {
      final stream = GrowingAudioFile();
      final samples = Float32List(24000); // 1 second of silence
      stream.addSamples(samples);

      final mp3Bytes = await stream.encodeSamples(samples);
      expect(mp3Bytes.isNotEmpty, true);
      // MP3 frame sync word: first 11 bits are all 1s (0xFF followed by 0xE0+ mask)
      expect(mp3Bytes[0], 0xFF);
      expect(mp3Bytes[1] & 0xE0, 0xE0);

      await stream.dispose();
    });

    test("incremental encoding produces valid concatenated MP3", () async {
      final stream = GrowingAudioFile();
      final chunk1 = Float32List(12000); // 0.5s
      final chunk2 = Float32List(12000); // 0.5s
      stream.addSamples(chunk1);
      stream.addSamples(chunk2);

      final bytes1 = await stream.encodeSamples(chunk1);
      final bytes2 = await stream.encodeSamples(chunk2);
      final flushed = await stream.flushEncoder();

      final totalLength = bytes1.length + bytes2.length + flushed.length;
      expect(totalLength, greaterThan(0));

      // First bytes should be valid MP3 frame header
      expect(bytes1[0], 0xFF);
      expect(bytes1[1] & 0xE0, 0xE0);

      await stream.dispose();
    });

    test("flushEncoder returns bytes (possibly empty) without error", () async {
      final stream = GrowingAudioFile();
      final samples = Float32List(24000);
      stream.addSamples(samples);
      await stream.encodeSamples(samples);
      stream.endStream();

      final flushed = await stream.flushEncoder();
      // Flush should return a Uint8List (may be empty if all frames were already emitted)
      expect(flushed, isA<Uint8List>());

      await stream.dispose();
    });
  });
}
