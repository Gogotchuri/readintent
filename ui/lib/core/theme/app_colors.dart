import "package:flutter/material.dart";

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color favorite;
  final Color onFavorite;

  /// archive action
  final Color archive;

  /// tint on archived items
  final Color archived;
  final Color onArchive;

  /// attention tint for non-error states (offline banner, in-progress labels)
  final Color warning;
  final Color onWarning;

  const AppColors({
    required this.favorite,
    required this.onFavorite,
    required this.archive,
    required this.archived,
    required this.onArchive,
    required this.warning,
    required this.onWarning,
  });

  static const peach = Color(0xFFF7B267);
  static const teal = Color(0xFF006466);

  static const light = AppColors(
    favorite: peach,
    onFavorite: Colors.white,
    archive: Color(0xFF607D8B),
    archived: teal,
    onArchive: Colors.white,
    warning: peach, // orange 700
    onWarning: Colors.white,
  );

  AppColors copyWith({
    Color? favorite,
    Color? onFavorite,
    Color? archive,
    Color? archived,
    Color? onArchive,
    Color? warning,
    Color? onWarning,
  }) {
    return AppColors(
      favorite: favorite ?? this.favorite,
      onFavorite: onFavorite ?? this.onFavorite,
      archive: archive ?? this.archive,
      archived: archived ?? this.archived,
      onArchive: onArchive ?? this.onArchive,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      favorite: Color.lerp(favorite, other.favorite, t)!,
      onFavorite: Color.lerp(onFavorite, other.onFavorite, t)!,
      archive: Color.lerp(archive, other.archive, t)!,
      archived: Color.lerp(archived, other.archived, t)!,
      onArchive: Color.lerp(onArchive, other.onArchive, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
    );
  }
}

/// Safe access to [AppColors] from a [BuildContext]. Falls back to the light
extension AppColorsX on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
