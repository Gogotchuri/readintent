import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:flutter_lame/flutter_lame.dart";

/// Accumulates PCM audio samples during TTS generation.
/// Encodes to MP3 incrementally via LAME and writes directly to a cache file.
/// Supports resume with a .meta file.
class GrowingAudioFile {
  static const int sampleRate = 24000; // Default sample rate for Kokoro TTS
  static const int _bytesPerSecond = sampleRate * 2; // 16-bit mono

  final String filePath;
  final StreamController<void> _updateController =
      StreamController<void>.broadcast();
  int _pcmLength;
  int _lastEncodedChunkIndex;

  final LameMp3Encoder _encoder = LameMp3Encoder(
    numChannels: 1,
    sampleRate: sampleRate,
    bitRate: 128,
  );

  GrowingAudioFile({required this.filePath})
    : _pcmLength = 0,
      _lastEncodedChunkIndex = -1;

  GrowingAudioFile.resume({
    required this.filePath,
    required int lastEncodedChunkIndex,
    required int pcmLength,
  }) : _pcmLength = pcmLength,
       _lastEncodedChunkIndex = lastEncodedChunkIndex;

  /// Try to resume from a .meta file. Returns a resumed instance or null.
  static GrowingAudioFile? tryResume(String filePath) {
    final metaFile = File("$filePath.meta");
    if (!metaFile.existsSync()) return null;
    final mp3File = File(filePath);
    if (!mp3File.existsSync()) return null;

    try {
      final json =
          jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
      final lastChunkIndex = json["lastChunkIndex"] as int;
      final pcmLength = json["pcmLength"] as int;
      return GrowingAudioFile.resume(
        filePath: filePath,
        lastEncodedChunkIndex: lastChunkIndex,
        pcmLength: pcmLength,
      );
    } catch (_) {
      return null;
    }
  }

  int get lastEncodedChunkIndex => _lastEncodedChunkIndex;

  /// Duration of audio buffered so far.
  Duration get bufferedDuration =>
      Duration(milliseconds: (_pcmLength * 1000) ~/ _bytesPerSecond);

  /// Stream of buffered duration updates.
  Stream<Duration> get bufferedDurationStream =>
      _updateController.stream.map((_) => bufferedDuration);

  /// Add a chunk of audio samples, encode to MP3, and append to the file.
  Future<void> addChunk(Float32List samples, int chunkIndex) async {
    _pcmLength += samples.length * 2; // 16-bit = 2 bytes per sample

    final mp3Bytes = await _encodeSamples(samples);
    if (mp3Bytes.isNotEmpty) {
      await File(
        filePath,
      ).writeAsBytes(mp3Bytes, mode: FileMode.append, flush: true);
    }

    _lastEncodedChunkIndex = chunkIndex;
    _writeMeta();

    if (!_updateController.isClosed) {
      _updateController.add(null);
    }
  }

  /// Flush remaining MP3 frames and delete the .meta file to signal completion.
  Future<void> finalize() async {
    final finalBytes = await _encoder.flush();
    if (finalBytes.isNotEmpty) {
      await File(
        filePath,
      ).writeAsBytes(finalBytes, mode: FileMode.append, flush: true);
    }
    // Delete meta file to signal the file is complete
    final metaFile = File("$filePath.meta");
    if (await metaFile.exists()) {
      await metaFile.delete();
    }
  }

  Future<void> dispose() async {
    await _encoder.close();
    await _updateController.close();
  }

  Future<Uint8List> _encodeSamples(Float32List samples) async {
    final float64 = Float64List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      float64[i] = samples[i].clamp(-1.0, 1.0).toDouble();
    }
    return _encoder.encodeDouble(leftChannel: float64);
  }

  void _writeMeta() {
    final meta = jsonEncode({
      "lastChunkIndex": _lastEncodedChunkIndex,
      "pcmLength": _pcmLength,
    });
    File("$filePath.meta").writeAsStringSync(meta);
  }
}
