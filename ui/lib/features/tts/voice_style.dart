// Based on the https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX
// We have a pythong example of how the voice bin files are used in python using numpy. We can try to replicate that in Dart.
// Style vector based on len(tokens), ref_s has shape (1, 256)
// voices = np.fromfile('./voices/af.bin', dtype=np.float32).reshape(-1, 1, 256)
// ref_s = voices[len(tokens)]
//
// We need to understand what exactly the 2 python lines are doing to replicate the behavior.
// The Kokoro model is using style vectors of shape (1, 256) to condition the TTS model.
// But the Kokoro voice style vectors for each voice are dependant on the length of the input tokens,
// each voice has different style vector, given the length of the input token ids.
// np.fromfile('./voices/af.bin', dtype=np.float32) is converting the binary voice file into a numpy flat array of type float32.
// The reshape(-1, 1, 256) part is then reshaping the array into a shape that can be indexed by the length of the input tokens, (-1 means infer the size of that dimension)
// Essentially if the voice file is of size l then the resulting shape will be (l/256, 1, 256). Sequences of 256 float32 vectors.

import "dart:io";
import "dart:typed_data";

// converts the binary voice file to a Float32List that can be used to calculate the style vector for the TTS model
Float32List _convertVoiceFileToFloat32List(Uint8List bytes) {
  final offset = bytes.offsetInBytes;
  final length = bytes.lengthInBytes ~/ Float32List.bytesPerElement;
  return bytes.buffer.asFloat32List(offset, length);
}

Float32List _getStyleVector(Float32List voiceData, int tokenLength) {
  final styleVectorSize = 256;
  final numStyleVectors = voiceData.length ~/ styleVectorSize;

  // Log a warning if tokenLength exceeds the number of available style vectors
  if (tokenLength >= numStyleVectors) {
    //TODO: Replace with proper logging
    print(
      "Warning: tokenLength $tokenLength exceeds available style vectors $numStyleVectors. Clamping to maximum available index.",
    );
  }
  tokenLength = tokenLength.clamp(0, numStyleVectors - 1);

  final startIndex = tokenLength * styleVectorSize;
  final endIndex = startIndex + styleVectorSize;

  return Float32List.sublistView(voiceData, startIndex, endIndex);
}

class VoiceStyles {
  late final Map<VoiceStyle, Float32List> styles;

  // Private constructor to initialize the styles map after loading the voice files as uint8 lists (Bytes)
  VoiceStyles._(Map<VoiceStyle, Uint8List> voiceData) {
    styles = voiceData.map(
      (voice, data) => MapEntry(voice, _convertVoiceFileToFloat32List(data)),
    );
  }

  // Given a directory path, load all voice files and create a VoiceStyles instance
  // If the directory contains files that don't match any known VoiceStyle, they will be skipped
  static Future<VoiceStyles> loadVoiceStyles(String voicePath) async {
    //Remove last file identifier if included in the path, we need the directory to load all voice files
    final pathSegments = voicePath.split("/");
    if (pathSegments.isNotEmpty) {
      pathSegments.removeLast();
    }
    final voicesDir = Directory(pathSegments.join("/"));
    if (!await voicesDir.exists()) {
      throw ArgumentError("Voice styles directory not found: $voicePath");
    }
    final voiceData = await _loadVoiceFiles(voicesDir);
    return VoiceStyles._(voiceData);
  }

  static Future<Map<VoiceStyle, Uint8List>> _loadVoiceFiles(
    Directory voicesDir,
  ) async {
    final Map<VoiceStyle, Uint8List> voiceData = {};
    await for (final entity in voicesDir.list()) {
      if (entity is File && entity.path.endsWith(".bin")) {
        final voiceKey = entity.uri.pathSegments.last.split(".").first;

        final voice = VoiceStyle.values.firstWhere(
          (s) => s.key == voiceKey,
          orElse: () => VoiceStyle.unknown,
        );
        if (voice == VoiceStyle.unknown) {
          continue; // Skip unknown styles
        }

        final bytes = await entity.readAsBytes();
        voiceData[voice] = bytes;
      }
    }
    return voiceData;
  }

  Float32List getStyleVector(VoiceStyle style, int tokenLength) {
    final voiceData = styles[style];
    if (voiceData == null) {
      throw ArgumentError("Voice style ${style.key} not found");
    }
    return _getStyleVector(voiceData, tokenLength);
  }

  List<VoiceStyle> get availableVoices => styles.keys.toList();

  bool hasVoice(VoiceStyle voice) => styles.containsKey(voice);

  // Load an additional voice into the live styles map
  void ensureVoiceLoaded(VoiceStyle voice, Uint8List bytes) {
    styles.putIfAbsent(voice, () => _convertVoiceFileToFloat32List(bytes));
  }
}

enum VoiceGender {
  male("Male"),
  female("Female");

  const VoiceGender(this.label);
  final String label;
}

enum VoiceAccent {
  american("American"),
  british("British");

  const VoiceAccent(this.label);
  final String label;
}

// The key prefix encodes accent + gender: a*=American, b*=British; *f=Female,
// *m=Male. Label/gender/accent are derived from the key.
enum VoiceStyle {
  // American Female
  afHeart("af_heart"),
  afAlloy("af_alloy"),
  afAoede("af_aoede"),
  afBella("af_bella"),
  afJessica("af_jessica"),
  afKore("af_kore"),
  afNicole("af_nicole"),
  afNova("af_nova"),
  afRiver("af_river"),
  afSarah("af_sarah"),
  afSky("af_sky"),
  // American Male
  amAdam("am_adam"),
  amEcho("am_echo"),
  amEric("am_eric"),
  amFenrir("am_fenrir"),
  amLiam("am_liam"),
  amMichael("am_michael"),
  amOnyx("am_onyx"),
  amPuck("am_puck"),
  amSanta("am_santa"),
  // British Female
  bfAlice("bf_alice"),
  bfEmma("bf_emma"),
  bfIsabella("bf_isabella"),
  bfLily("bf_lily"),
  // British Male
  bmDaniel("bm_daniel"),
  bmFable("bm_fable"),
  bmGeorge("bm_george"),
  bmLewis("bm_lewis"),
  unknown("unknown");

  const VoiceStyle(this.key);

  final String key;
  // Humanized display name from the key (e.g. "af_sky" -> "Sky").
  String get label {
    final name = key.contains("_") ? key.split("_").last : key;
    return "${name[0].toUpperCase()}${name.substring(1)}";
  }

  VoiceAccent get accent =>
      key.startsWith("b") ? VoiceAccent.british : VoiceAccent.american;
  VoiceGender get gender =>
      key[1] == "f" ? VoiceGender.female : VoiceGender.male;
  String get filename => "$key.bin";
  String get filepath => "assets/voices/$filename";
  // URL for the voice style vector based on the key
  String get url =>
      "https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/resolve/main/voices/$key.bin?download=true";
}
