import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:wav/wav.dart";
import "package:readintent_flutter/features/tts/growable_audio_stream.dart";

void main() {
  group("GrowableAudioStream", () {
    test("starts with zero buffered duration", () {
      final stream = GrowableAudioStream();
      expect(stream.bufferedDuration, Duration.zero);
    });

    test("bufferedDuration increases as samples are added", () {
      final stream = GrowableAudioStream();
      // 24000 samples = 1 second at 24kHz
      stream.addSamples(Float32List(24000));
      expect(stream.bufferedDuration.inMilliseconds, 1000);
    });

    test("toWavBytes produces a valid WAV file readable by the wav package", () {
      final stream = GrowableAudioStream();
      // Add 1 second of silence
      stream.addSamples(Float32List(24000));
      stream.endStream();

      final wavBytes = stream.toWavBytes();

      // The wav package should be able to read it back
      final parsed = Wav.read(wavBytes);
      expect(parsed.samplesPerSecond, 24000);
      expect(parsed.channels.length, 1);
      expect(parsed.channels[0].length, 24000);
    });

    test("toWavBytes preserves audio data correctly", () {
      final stream = GrowableAudioStream();
      final samples = Float32List.fromList([0.5, -0.5, 1.0, -1.0]);
      stream.addSamples(samples);
      stream.endStream();

      final wavBytes = stream.toWavBytes();
      final parsed = Wav.read(wavBytes);
      final output = parsed.channels[0];

      // 16-bit quantization introduces small rounding
      expect(output[0], closeTo(0.5, 0.001));
      expect(output[1], closeTo(-0.5, 0.001));
      expect(output[2], closeTo(1.0, 0.001));
      expect(output[3], closeTo(-1.0, 0.001));
    });

    test("request returns sourceLength only when ended", () async {
      final stream = GrowableAudioStream();
      stream.addSamples(Float32List(480));

      final midResponse = await stream.request(0, 44);
      expect(midResponse.sourceLength, isNull); // not ended yet

      stream.endStream();
      final endResponse = await stream.request(0, 44);
      expect(endResponse.sourceLength, isNotNull);
    });

    test("isEnded reflects endStream call", () {
      final stream = GrowableAudioStream();
      expect(stream.isEnded, false);
      stream.endStream();
      expect(stream.isEnded, true);
    });

    test("float32 values outside [-1, 1] are clamped", () {
      final stream = GrowableAudioStream();
      final samples = Float32List.fromList([2.0, -2.0]);
      stream.addSamples(samples);
      stream.endStream();

      final wavBytes = stream.toWavBytes();
      final parsed = Wav.read(wavBytes);

      // Clamped values should read back as ±1.0 (within 16-bit precision)
      expect(parsed.channels[0][0], closeTo(1.0, 0.001));
      expect(parsed.channels[0][1], closeTo(-1.0, 0.001));
    });

    test("double addSamples returns correctly", () {
      final stream = GrowableAudioStream();
      stream.addSamples(Float32List(12000)); // 0.5s
      stream.addSamples(Float32List(12000)); // 0.5s
      expect(stream.bufferedDuration.inMilliseconds, 1000);

      stream.endStream();
      final wavBytes = stream.toWavBytes();
      final parsed = Wav.read(wavBytes);
      expect(parsed.channels[0].length, 24000);
    });

    test("request returns PCM data after header", () async {
      final stream = GrowableAudioStream();
      // Add known data
      final samples = Float32List.fromList([0.5]);
      stream.addSamples(samples);
      stream.endStream();

      // Total should be header (44) + 2 bytes (one 16-bit sample)
      final response = await stream.request(0, 46);
      expect(response.contentLength, 46);

      // Read the full response
      final bytes = await response.stream.first;
      expect(bytes.length, 46);
      // First 4 bytes should be "RIFF"
      expect(String.fromCharCodes(bytes.sublist(0, 4)), "RIFF");
    });
  });
}
