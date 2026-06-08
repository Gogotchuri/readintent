import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:readintent_flutter/features/tts/voice_style.dart";

part "app_settings_provider.g.dart";

/// App-wide, persisted user preferences: global text (font) scale, the selected
/// TTS voice and the light/dark theme mode. Backed by SharedPreferences.
class AppSettingsState {
  final double textScale;
  final VoiceStyle voice;
  final ThemeMode themeMode;

  const AppSettingsState({
    this.textScale = 1.0,
    this.voice = VoiceStyle.afSky,
    this.themeMode = ThemeMode.system,
  });

  AppSettingsState copyWith({
    double? textScale,
    VoiceStyle? voice,
    ThemeMode? themeMode,
  }) {
    return AppSettingsState(
      textScale: textScale ?? this.textScale,
      voice: voice ?? this.voice,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

@Riverpod(keepAlive: true)
class AppSettings extends _$AppSettings {
  static const _textScaleKey = "app_text_scale";
  static const _voiceKey = "app_voice_style";
  static const _themeModeKey = "app_theme_mode";

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
      final themeKey = prefs.getString(_themeModeKey);
      final themeMode = themeKey == null
          ? state.themeMode
          : ThemeMode.values.firstWhere(
              (m) => m.name == themeKey,
              orElse: () => state.themeMode,
            );
      state = state.copyWith(
        textScale: scale?.clamp(minScale, maxScale),
        voice: voice,
        themeMode: themeMode,
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

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state.themeMode) return;
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }
}
