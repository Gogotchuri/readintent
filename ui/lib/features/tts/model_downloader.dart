import "dart:io";

import "package:path_provider/path_provider.dart";
import "package:dio/dio.dart";
import "package:readintent_flutter/features/tts/voice_style.dart";

enum ModelType {
  // Q4 quantized model, larger but usually better performance on most devices that have enough VRAM to run it. Around 300MB in size.
  q4("model_q4.onnx", 305),
  // Smaller than Q4, but may have compatibility issues. Around 155MB in size.
  q4f16("model_q4f16.onnx", 155),
  // Q8F16 The smallest option and a good balance.
  q8f16("model_q8f16.onnx", 86),
  // Quantized model with 8-bit integer weights
  quantized("model_quantized.onnx", 92.4);

  const ModelType(this.filename, this.sizeInMB);

  final String filename;
  String get filepath => "assets/models/$filename";
  // Used as a fallback total size during download progress display
  final double sizeInMB;
  // URL for the model based on the filename
  String get url =>
      "https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX-timestamped/resolve/main/onnx/$filename?download=true";
}

// Callback type for download progress updates
typedef DownloadProgressCallback = void Function(String name, double progress);

class KokoroAssetPaths {
  final String modelPath;
  final String voiceStylePath;

  KokoroAssetPaths({required this.modelPath, required this.voiceStylePath});
}

// --------------------------
// KokoroDownloader
// --------------------------

class KokoroDownloader {
  static KokoroAssetPaths? _cachedPaths;

  static Future<KokoroAssetPaths> ensureAssets({
    required ModelType modelType,
    required VoiceStyle voiceStyle,
    DownloadProgressCallback? onProgress,
  }) async {
    // If we already have cached paths, return them immediately
    if (_cachedPaths != null) {
      return _cachedPaths!;
    }

    try {
      // Start both downloads in parallel
      final results = await Future.wait([
        _downloadVoice(voiceStyle, onProgress),
        _downloadModel(modelType, onProgress),
      ]);

      // Cache the paths for future calls
      _cachedPaths = KokoroAssetPaths(voiceStylePath: results[0], modelPath: results[1]);

      return _cachedPaths!;
    } catch (e) {
      throw Exception("Failed to download assets: $e");
    }
  }

  static Future<String> _downloadVoice(VoiceStyle voiceStyle, DownloadProgressCallback? onProgress) async {
    // Each is around 0.5MB in size
    return _ensureFile(voiceStyle.url, voiceStyle.filepath, 0.5, onProgress);
  }

  static Future<String> _downloadModel(ModelType modelType, DownloadProgressCallback? onProgress) async {
    return _ensureFile(modelType.url, modelType.filepath, modelType.sizeInMB, onProgress);
  }

  static Future<String> _ensureFile(
    String url,
    String filepath,
    double fallbackSizeInMb,
    DownloadProgressCallback? onProgress,
  ) async {
    final dir = await getApplicationSupportDirectory();
    final filePath = "${dir.path}/$filepath";
    final filename = filepath.split("/").last;

    if (await File(filePath).exists()) {
      return filePath; // File already exists, return the path
    }

    final dio = Dio();
    await dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total == -1) {
          total = (fallbackSizeInMb * 1024 * 1024).toInt(); // Use fallback size if total is unknown
        }
        if (total > 0 && received <= total) {
          final progress = received / total;
          onProgress?.call(filename, progress);
        }
      },
    );

    return filePath;
  }
}
