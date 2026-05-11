import "dart:io";
import "dart:typed_data";

import "package:onnxruntime_v2/onnxruntime_v2.dart";
import "package:readintent_flutter/features/tts/model_downloader.dart";
import "package:readintent_flutter/features/tts/phoneme.dart";
import "package:readintent_flutter/features/tts/voice_style.dart";

class TTSPipeline {
  final OrtSession _session;
  final VoiceStyles _voiceStyles;

  TTSPipeline._(this._session, this._voiceStyles);

  static Future<TTSPipeline> create(KokoroAssetPaths assetPaths) async {
    final voiceStyles = await VoiceStyles.loadVoiceStyles(assetPaths.voiceStylePath);
    final session = await TTSPipeline.initializeONNXSession(assetPaths.modelPath);
    return TTSPipeline._(session, voiceStyles);
  }

  static Future<OrtSession> initializeONNXSession(String modelPath) async {
    OrtEnv.instance.init();
    OrtSession? session;
    try {
      final sessionOpts = OrtSessionOptions();
      // This will try to load the providers for the fastest available device
      // GPU > NPU > CPU
      await sessionOpts.appendDefaultProviders();
      session = OrtSession.fromFile(File(modelPath), sessionOpts);
      sessionOpts.release();
      //TODO certain models might fail to work on some devices, we need to detect such failures and fallback
    } catch (e) {
      // Manual fallback just in case (//TODO need to handle another failure casre)
      final sessionOpts = OrtSessionOptions();
      // Sets parallelism equal to the processor cores when running on CPU
      sessionOpts.setIntraOpNumThreads(Platform.numberOfProcessors);
      session = OrtSession.fromFile(File(modelPath), sessionOpts);
      sessionOpts.release();
    }
    return session;
  }

  Future<KokoroResult> runInference(PhonemeChunk chunk, VoiceStyle style) async {
    final seqLen = chunk.tokenIds.length;
    final tokenIds = chunk.tokenIds;

    // Create input tensors
    final tokenTensor = OrtValueTensor.createTensorWithDataList([tokenIds], [1, seqLen]);

    // Get the style vector for the specified voice style
    final styleVector = _voiceStyles.getStyleVector(style, seqLen);
    final styleTensor = OrtValueTensor.createTensorWithDataList(styleVector, [1, 256]);

    final speedTensor = OrtValueTensor.createTensorWithDataList(Float32List.fromList([1.0]), [1]);

    final inputs = {"input_ids": tokenTensor, "style": styleTensor, "speed": speedTensor};

    final runOpts = OrtRunOptions();
    Float32List? audio;
    List<WordTimestamp>? timestamps;

    try {
      final output = await _session.runAsync(runOpts, inputs);
      if (output == null || output.isEmpty || output[0] == null) {
        throw Exception("ONNX Runtime returned null output");
      }
      audio = Float32List.fromList(_flattenNumList(output[0]!.value));
      // If the model provides timestamps, they would be in another output tensor
      if (output.length > 1 && output[1] != null) {
        final predDur = _flattenNumList(output[1]!.value);
        timestamps = [];
        //TODO: We need a bit complex conversion here, described by the author of the timestamped model here: https://gist.github.com/fagenorn/d4aa16704541370d9b9d5f91f1f07b34
      } else {
        // If no timestamps are provided, create a single timestamp for the whole audio
        timestamps = [WordTimestamp(word: chunk.graphemes, start: 0.0, end: audio.length / 24000.0)];
      }
      return KokoroResult(audio: audio, timestamps: timestamps, graphemes: chunk.graphemes);
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

// Flattens a nested list of numbers into a single list of doubles
List<double> _flattenNumList(dynamic value) {
  if (value is num) return [value.toDouble()];
  if (value is List) {
    return value.expand<double>((e) => _flattenNumList(e)).toList();
  }
  return [];
}
