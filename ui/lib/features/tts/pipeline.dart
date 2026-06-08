import "dart:io";
import "dart:isolate";
import "dart:typed_data";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:onnxruntime_v2/onnxruntime_v2.dart";
import "package:readintent_flutter/features/tts/download_status_provider.dart";
import "package:readintent_flutter/features/tts/model_downloader.dart";
import "package:readintent_flutter/features/tts/phoneme.dart";
import "package:readintent_flutter/features/tts/voice_style.dart";

typedef PipelineFactory = Future<TTSPipeline> Function(VoiceStyle voiceStyle);

Future<TTSPipeline> defaultPipelineFactory(VoiceStyle voiceStyle) async {
  final assetPaths = await KokoroDownloader.ensureAssets(
    modelType: ModelType.q4,
    voiceStyle: voiceStyle,
  );
  final pipeline = await TTSPipeline.create(assetPaths);
  await pipeline.ensureVoice(voiceStyle);
  return pipeline;
}

final pipelineFactoryProvider = Provider<PipelineFactory>((ref) {
  // Build the model session exactly once and share it across every caller
  Future<TTSPipeline>? cached;

  Future<TTSPipeline> build(VoiceStyle voiceStyle) async {
    final notifier = ref.read(downloadStatusProvider.notifier);
    try {
      final assetPaths = await KokoroDownloader.ensureAssets(
        modelType: ModelType.q4,
        voiceStyle: voiceStyle,
        onProgress: (name, progress) {
          notifier.set(DownloadStatus("Downloading $name", progress));
        },
      );
      final pipeline = await TTSPipeline.create(assetPaths);
      notifier.set(null);
      return pipeline;
    } catch (e) {
      notifier.set(null);
      rethrow;
    }
  }

  return (VoiceStyle voiceStyle) async {
    cached ??= build(voiceStyle);
    try {
      final pipeline = await cached!;
      // Ensure the requested voice is downloaded and loaded
      await pipeline.ensureVoice(voiceStyle);
      return pipeline;
    } catch (e) {
      cached = null; // allow a retry on the next play/preview
      rethrow;
    }
  };
});

class TTSPipeline {
  final OrtSession _session;
  final VoiceStyles _voiceStyles;

  TTSPipeline._(this._session, this._voiceStyles);

  static Future<TTSPipeline> create(KokoroAssetPaths assetPaths) async {
    final voiceStyles = await VoiceStyles.loadVoiceStyles(
      assetPaths.voiceStylePath,
    );
    final session = await TTSPipeline.initializeONNXSession(
      assetPaths.modelPath,
    );
    return TTSPipeline._(session, voiceStyles);
  }

  Future<void> ensureVoice(VoiceStyle voice) async {
    if (_voiceStyles.hasVoice(voice)) return;
    final path = await KokoroDownloader.ensureVoice(voice);
    _voiceStyles.ensureVoiceLoaded(voice, await File(path).readAsBytes());
  }

  static Future<OrtSession> initializeONNXSession(String modelPath) async {
    OrtEnv.instance.init();
    try {
      // Build the session on a background isolate, and return address for main-isolate construction.
      final address = await Isolate.run(() async {
        OrtEnv.instance.init();
        final sessionOpts = OrtSessionOptions();
        try {
          // This will try to load the providers for the fastest available device GPU > NPU > CPU
          await sessionOpts.appendDefaultProviders();
          final session = OrtSession.fromFile(File(modelPath), sessionOpts);
          sessionOpts.release();
          //TODO certain models might fail to work on some devices, we need to detect such failures and fallback
          return session.address;
        } catch (_) {
          final fallback = OrtSessionOptions();
          fallback.setIntraOpNumThreads(Platform.numberOfProcessors);
          final s = OrtSession.fromFile(File(modelPath), fallback);
          fallback.release();
          return s.address;
        }
      });
      return OrtSession.fromAddress(address);
    } catch (e) {
      // Manual fallback just in case (//TODO need to handle another failure casre)
      final sessionOpts = OrtSessionOptions();
      // Sets parallelism equal to the processor cores when running on CPU
      sessionOpts.setIntraOpNumThreads(Platform.numberOfProcessors);
      final session = OrtSession.fromFile(File(modelPath), sessionOpts);
      sessionOpts.release();
      return session;
    }
  }

  Future<KokoroResult> runInference(
    PhonemeChunk chunk,
    VoiceStyle style,
  ) async {
    final seqLen = chunk.tokenIds.length;
    final tokenIds = chunk.tokenIds;

    // Create input tensors
    final tokenTensor = OrtValueTensor.createTensorWithDataList(
      [tokenIds],
      [1, seqLen],
    );

    // Get the style vector for the specified voice style
    final styleVector = _voiceStyles.getStyleVector(style, seqLen);
    final styleTensor = OrtValueTensor.createTensorWithDataList(styleVector, [
      1,
      256,
    ]);

    final speedTensor = OrtValueTensor.createTensorWithDataList(
      Float32List.fromList([1.1]),
      [1],
    );

    final inputs = {
      "input_ids": tokenTensor,
      "style": styleTensor,
      "speed": speedTensor,
    };

    final runOpts = OrtRunOptions();
    Float32List? audio;
    List<WordTimestamp>? timestamps;

    try {
      final output = await _session.runAsync(runOpts, inputs);
      if (output == null || output.isEmpty || output[0] == null) {
        throw Exception("ONNX Runtime returned null output");
      }
      audio = Float32List.fromList(_flattenNumList(output[0]!.value));
      // If the model provides predicted durations, convert to word timestamps
      if (output.length > 1 && output[1] != null) {
        final predDur = _flattenNumList(output[1]!.value);
        timestamps = joinTimestamps(chunk.tokenMeta, predDur);
      } else {
        // If no timestamps are provided, create a single timestamp for the whole audio
        timestamps = [
          WordTimestamp(
            word: chunk.graphemes,
            start: 0.0,
            end: audio.length / 24000.0,
          ),
        ];
      }
      return KokoroResult(
        audio: audio,
        timestamps: timestamps,
        graphemes: chunk.graphemes,
      );
      //TODO
    } catch (e) {
      rethrow;
    } finally {
      // Clean up input tensors
      tokenTensor.release();
      styleTensor.release();
      speedTensor.release();
      runOpts.release();
    }
  }
}

// ----------------------
// Helpers
// ----------------------

/// Converts predicted phoneme durations from the ONNX model into word-level timestamps.
///
/// Ported from the reference Python implementation by the Kokoro timestamped model author:
/// https://gist.github.com/fagenorn/d4aa16704541370d9b9d5f91f1f07b34
///
/// [tokens] maps to chunk.tokenMeta - one entry per word/punctuation token.
/// [predDur] is the flattened predicted duration tensor (output[1]).
/// MAGIC_DIVISOR = 80 converts half-frames to seconds (hop_size=600, sr=24000).
List<WordTimestamp> joinTimestamps(
  List<TokenMeta> tokens,
  List<double> predDur,
) {
  const magicDivisor = 80.0;

  if (tokens.isEmpty || predDur.length < 3) return [];

  // BOS offset: predDur[0] is the begin-of-sequence token
  double left = 2 * (predDur[0] - 3).clamp(0, double.infinity);
  double right = left;
  int i = 1; // Skip BOS token

  final timestamps = <WordTimestamp>[];

  for (final t in tokens) {
    if (i >= predDur.length - 1) break; // Stop before EOS token

    // Token with no phonemes (e.g., punctuation)
    if (t.phonemeLen == 0) {
      if (t.hasWhitespace) {
        i += 1;
        if (i >= predDur.length) break;
        left = right + predDur[i];
        right = left + predDur[i];
        i += 1;
      }
      continue;
    }

    final j = i + t.phonemeLen;
    if (j >= predDur.length) break;

    final startTs = left / magicDivisor;

    // Sum durations for all phonemes in this token
    double tokenDur = 0;
    for (int k = i; k < j; k++) {
      tokenDur += predDur[k];
    }

    final spaceDur = t.hasWhitespace ? predDur[j] : 0.0;
    left = right + (2 * tokenDur) + spaceDur;
    final endTs = left / magicDivisor;
    right = left + spaceDur;

    i = j + (t.hasWhitespace ? 1 : 0);

    timestamps.add(WordTimestamp(word: t.text, start: startTs, end: endTs));
  }

  return timestamps;
}

// Flattens a nested list of numbers into a single list of doubles
List<double> _flattenNumList(dynamic value) {
  if (value is num) return [value.toDouble()];
  if (value is List) {
    return value.expand<double>((e) => _flattenNumList(e)).toList();
  }
  return [];
}
