import "dart:async";
import "dart:typed_data";

import "package:wav/wav.dart";

/// Accumulates PCM audio samples during TTS generation.
/// Tracks buffered duration and produces a final WAV file for caching.
class GrowableAudioStream {
  static const int sampleRate = 24000; // Default sample rate for Kokoro TTS
  static const int _bytesPerSecond = sampleRate * 2; // 16-bit mono

  final List<Float32List> _rawChunks = [];
  final StreamController<void> _updateController = StreamController<void>.broadcast();
  bool _ended = false;
  int _pcmLength = 0;

  /// Add new Float32 audio samples (mono, 24kHz).
  void addSamples(Float32List samples) {
    _rawChunks.add(samples);
    _pcmLength += samples.length * 2; // 16-bit = 2 bytes per sample
    if (!_updateController.isClosed) {
      _updateController.add(null);
    }
  }

  /// Signal that no more samples will be added.
  void endStream() {
    _ended = true;
    if (!_updateController.isClosed) {
      _updateController.add(null);
    }
  }

  /// Duration of audio buffered so far.
  Duration get bufferedDuration => Duration(milliseconds: (_pcmLength * 1000) ~/ _bytesPerSecond);

  /// Stream of buffered duration updates.
  Stream<Duration> get bufferedDurationStream => _updateController.stream.map((_) => bufferedDuration);

  bool get isEnded => _ended;

  /// Convert a single chunk of Float32 samples to a complete WAV file.
  static Uint8List chunkToWavBytes(Float32List samples) {
    final float64 = Float64List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      float64[i] = samples[i].clamp(-1.0, 1.0).toDouble();
    }
    final wav = Wav([float64], sampleRate, WavFormat.pcm16bit);
    return Uint8List.fromList(wav.write());
  }

  /// Get accumulated audio as a complete WAV file (for caching).
  Uint8List toWavBytes() {
    final totalSamples = _rawChunks.fold<int>(0, (sum, c) => sum + c.length);
    final float64 = Float64List(totalSamples);
    int offset = 0;
    for (final chunk in _rawChunks) {
      for (int i = 0; i < chunk.length; i++) {
        float64[offset + i] = chunk[i].clamp(-1.0, 1.0).toDouble();
      }
      offset += chunk.length;
    }
    final wav = Wav([float64], sampleRate, WavFormat.pcm16bit);
    return Uint8List.fromList(wav.write());
  }

  Future<void> dispose() async {
    await _updateController.close();
  }
}
