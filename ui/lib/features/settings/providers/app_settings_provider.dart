import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:readintent_flutter/features/tts/voice_style.dart";

part "app_settings_provider.g.dart";

/// App-wide, persisted user preferences: global text (font) scale and the
/// selected TTS voice. Backed by SharedPreferences.
class AppSettingsState {
  final double textScale;
  final VoiceStyle voice;

  const AppSettingsState({this.textScale = 1.0, this.voice = VoiceStyle.afSky});

  AppSettingsState copyWith({double? textScale, VoiceStyle? voice}) {
    return AppSettingsState(
      textScale: textScale ?? this.textScale,
      voice: voice ?? this.voice,
    );
  }
}

@Riverpod(keepAlive: true)
class AppSettings extends _$AppSettings {
  static const _textScaleKey = "app_text_scale";
  static const _voiceKey = "app_voice_style";

  // Font scale bounds and step for the top-bar zoom control.
  static const double minScale = 0.8;
  static const double maxScale = 2.0;
  static const double scaleStep = 0.1;

  @override
  AppSettingsState build() {
    // Return defaults synchronously so the UI can render immediately, then
    // hydrate from persisted storage (mirrors ActivePlayer._restoreLastPlayed).
    _load();
    return const AppSettingsState();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scale = prefs.getDouble(_textScaleKey);
      final voiceKey = prefs.getString(_voiceKey);
      final voice = voiceKey == null
          ? state.voice
          : VoiceStyle.values.firstWhere(
              (v) => v.key == voiceKey,
              orElse: () => state.voice,
            );
      state = state.copyWith(
        textScale: scale?.clamp(minScale, maxScale),
        voice: voice,
      );
    } catch (_) {
      // Best-effort restore - keep defaults on corrupt/missing data.
    }
  }

  Future<void> setTextScale(double scale) async {
    final clamped = scale.clamp(minScale, maxScale);
    state = state.copyWith(textScale: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textScaleKey, clamped);
  }

  Future<void> increaseFont() => setTextScale(state.textScale + scaleStep);

  Future<void> decreaseFont() => setTextScale(state.textScale - scaleStep);

  Future<void> resetFont() => setTextScale(1.0);

  Future<void> setVoice(VoiceStyle voice) async {
    if (voice == state.voice) return;
    state = state.copyWith(voice: voice);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voiceKey, voice.key);
  }
}
