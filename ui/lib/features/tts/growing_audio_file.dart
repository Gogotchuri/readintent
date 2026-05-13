import "dart:async";
import "dart:typed_data";

import "package:flutter_lame/flutter_lame.dart";

/// Accumulates PCM audio samples during TTS generation.
/// Encodes to MP3 incrementally via LAME for append-only file writes.
class GrowingAudioFile {
  static const int sampleRate = 24000; // Default sample rate for Kokoro TTS
  static const int _bytesPerSecond = sampleRate * 2; // 16-bit mono

  final List<Float32List> _rawChunks = [];
  final StreamController<void> _updateController = StreamController<void>.broadcast();
  bool _ended = false;
  int _pcmLength = 0;

  final LameMp3Encoder _encoder = LameMp3Encoder(numChannels: 1, sampleRate: sampleRate, bitRate: 64);

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

  /// Encode a Float32List chunk to MP3 bytes using the instance encoder.
  /// Maintains LAME's bit reservoir across calls for correct encoding.
  Future<Uint8List> encodeSamples(Float32List samples) async {
    final float64 = Float64List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      float64[i] = samples[i].clamp(-1.0, 1.0).toDouble();
    }
    return _encoder.encodeDouble(leftChannel: float64);
  }

  Future<Uint8List> flushEncoder() async {
    return _encoder.flush();
  }

  Future<void> dispose() async {
    await _encoder.close();
    await _updateController.close();
  }
}
