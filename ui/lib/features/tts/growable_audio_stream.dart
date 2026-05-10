import "dart:async";
import "dart:typed_data";

import "package:just_audio/just_audio.dart";
import "package:wav/wav.dart";

/// A StreamAudioSource that grows as new PCM samples are added.
/// Serves a WAV stream to just_audio for live playback during TTS generation.
class GrowableAudioStream extends StreamAudioSource {
  static const int sampleRate = 24000; // Default sample rate for Kokoro TTS
  static const int _bytesPerSecond = sampleRate * 2; // 16-bit mono
  static const int _headerSize = 44;

  // Streaming header generated via wav package, size fields patched to max.
  static final Uint8List _streamingHeader = _buildStreamingHeader();

  final BytesBuilder _pcmBuilder = BytesBuilder(copy: false);
  final List<Float32List> _rawChunks = []; // Keep originals for wav package
  // Controller to notify listeners when new data is added or stream ends.
  // Allows multipl listeners
  final StreamController<void> _updateController = StreamController<void>.broadcast();
  bool _ended = false;
  int _pcmLength = 0;

  GrowableAudioStream() : super(tag: "kokoro-live");

  /// Add new Float32 audio samples (mono, 24kHz).
  void addSamples(Float32List samples) {
    _rawChunks.add(samples);
    final int16Bytes = _float32ToInt16Bytes(samples);
    _pcmBuilder.add(int16Bytes);
    _pcmLength += int16Bytes.length;
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
  /// Emitted whenever new samples are added or the stream ends, allowing UI to reactively update buffering indicators.
  Stream<Duration> get bufferedDurationStream => _updateController.stream.map((_) => bufferedDuration);

  bool get isEnded => _ended;

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

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;

    // Wait for data if the requested range isn't available yet
    while (!_ended && start >= _headerSize + _pcmLength) {
      await _updateController.stream.first;
    }

    final currentTotal = _headerSize + _pcmLength;
    end ??= currentTotal;
    // To prevent requesting beyond current total, we clamp the end. just_audio should handle this and wait for more data if needed.
    final actualEnd = end.clamp(start, currentTotal);

    final responseBytes = _getBytes(start, actualEnd);

    return StreamAudioResponse(
      sourceLength: _ended ? currentTotal : null,
      contentLength: responseBytes.length,
      offset: start,
      stream: Stream.value(responseBytes),
      contentType: "audio/wav",
    );
  }

  Uint8List _getBytes(int start, int end) {
    final pcmBytes = _pcmBuilder.toBytes();
    final result = BytesBuilder(copy: false);

    // We have split the Wav file into a fixed header of size 44 bytes and a separate PCM bytes.
    // Which means we might need need to serve bytes from the header, the PCM data, or a combination of both depending on the requested range.
    final startsInHeader = start < _headerSize;
    final endsInHeader = end <= _headerSize;

    // Check if we start in header:
    // If we also end in header, we simply need to serve bytes with the header
    // Otherwise, we need to serve the header bytes first, then serve the PCM bytes from 0 until the end value.
    if (startsInHeader) {
      final headerEnd = end.clamp(0, _headerSize);
      result.add(Uint8List.sublistView(_streamingHeader, start, headerEnd));
      if (endsInHeader) {
        return result.toBytes();
      }
      final pcmEnd = (end - _headerSize).clamp(0, pcmBytes.length);
      result.add(Uint8List.sublistView(pcmBytes, 0, pcmEnd));
      return result.toBytes();
    }
    // If we start beyond the header, we just need to serve the PCM bytes from start-headerSize until end-headerSize.
    final pcmStart = start - _headerSize;
    final pcmEnd = (end - _headerSize).clamp(pcmStart, pcmBytes.length);
    result.add(Uint8List.sublistView(pcmBytes, pcmStart, pcmEnd));

    return result.toBytes();
  }

  /// Build a streaming WAV header
  /// The wav package doesn't support streaming, it assumes the whole file is available at the start, so we need to get around that
  /// We don't know the exact final file size at the start, so we need to patch the header each time.
  static Uint8List _buildStreamingHeader() {
    // Create minimal WAV header with max sizes, so just_audio can start playback immediately.
    final wav = Wav([Float64List(1)], sampleRate, WavFormat.pcm16bit);
    final bytes = Uint8List.fromList(wav.write());
    final bd = ByteData.sublistView(bytes);
    // We set the file size to 2^31-1 to indicate that the size is unknown/infinite, this should be handled correctly by just_audio
    // Read more about WAV file format here:
    // https://web.archive.org/web/20200206065911/http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/WAVE.html
    // https://cran.r-project.org/web/packages/ctypesio/vignettes/wave-format.html
    bd.setUint32(4, 0x7FFFFFFF, Endian.little); // RIFF chunk size
    bd.setUint32(40, 0x7FFFFFFF, Endian.little); // data chunk size
    return Uint8List.sublistView(bytes, 0, _headerSize);
  }

  // Convert Float32 samples to Int16 bytes for WAV encoding.
  // Clamps samples to [-1.0, 1.0] and scales to 16-bit range.
  static Uint8List _float32ToInt16Bytes(Float32List samples) {
    final out = Int16List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      out[i] = (samples[i].clamp(-1.0, 1.0) * 32767).toInt();
    }
    return out.buffer.asUint8List();
  }

  Future<void> dispose() async {
    await _updateController.close();
  }
}
