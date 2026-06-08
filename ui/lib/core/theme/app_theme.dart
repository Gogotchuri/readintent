import "package:flutter/material.dart";

import "package:readintent_flutter/core/theme/app_colors.dart";

/// Central Material 3 themes for the app. Light and dark [ThemeData]
class AppTheme {
  AppTheme._();

  static const primarySeed = Color(0xFF006466);

  static final ThemeData light = _build(Brightness.light, AppColors.light);
  static final ThemeData dark = _build(Brightness.dark, AppColors.light);

  static ThemeData _build(Brightness brightness, AppColors appColors) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [appColors],
      appBarTheme: const AppBarTheme(toolbarHeight: 44),
    );
  }
}
