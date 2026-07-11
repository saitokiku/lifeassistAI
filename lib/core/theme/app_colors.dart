import 'package:flutter/material.dart';

/// Palette for the calm operator console. Dark mode first.
///
/// Color is semantic, never ambient: teal = brand/interactive,
/// green = on track, amber = watch, red = needs attention, gray = neutral.
class AppColors {
  AppColors._();

  // Dark surfaces — tonal steps, separation without heavy borders.
  static const Color bgDark = Color(0xFF0A0C10);
  static const Color surfaceDark = Color(0xFF10141B);
  static const Color cardDark = Color(0xFF151A23);
  static const Color elevatedDark = Color(0xFF1B2130);
  static const Color outlineDark = Color(0xFF232B38);
  static const Color outlineFaintDark = Color(0xFF1A202B);

  // Light surfaces
  static const Color bgLight = Color(0xFFF5F6F8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color elevatedLight = Color(0xFFF0F2F5);
  static const Color outlineLight = Color(0xFFE3E7EE);
  static const Color outlineFaintLight = Color(0xFFEBEEF3);

  // Accent
  static const Color primary = Color(0xFF4FD1C5);
  static const Color primaryBright = Color(0xFF7EEADF);
  static const Color primaryDim = Color(0xFF2C7A73);
  static const Color onPrimary = Color(0xFF06211E);

  // Status
  static const Color aligned = Color(0xFF3DDC97);
  static const Color watch = Color(0xFFF5B94E);
  static const Color critical = Color(0xFFF87171);
  static const Color neutral = Color(0xFF8B93A3);

  // Text
  static const Color textPrimaryDark = Color(0xFFECF0F6);
  static const Color textSecondaryDark = Color(0xFF98A2B3);
  static const Color textTertiaryDark = Color(0xFF5F6B7E);
  static const Color textPrimaryLight = Color(0xFF161B26);
  static const Color textSecondaryLight = Color(0xFF5A6472);
  static const Color textTertiaryLight = Color(0xFF8A93A2);
}

/// A four-level status used across cards and badges.
enum StatusLevel { aligned, watch, critical, neutral }

extension StatusLevelX on StatusLevel {
  Color get color => switch (this) {
        StatusLevel.aligned => AppColors.aligned,
        StatusLevel.watch => AppColors.watch,
        StatusLevel.critical => AppColors.critical,
        StatusLevel.neutral => AppColors.neutral,
      };
}

/// Theme-aware color roles that don't fit Material's ColorScheme.
extension AppColorsX on ColorScheme {
  bool get _isDark => brightness == Brightness.dark;

  /// Third text tier, for de-emphasized metadata.
  Color get textTertiary =>
      _isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

  /// Raised surface inside a card (inputs, chips, wells).
  Color get elevated =>
      _isDark ? AppColors.elevatedDark : AppColors.elevatedLight;

  /// Barely-there hairline for card edges.
  Color get outlineFaint =>
      _isDark ? AppColors.outlineFaintDark : AppColors.outlineFaintLight;

  /// Soft brand-tinted fill for hero cards and icon wells.
  Color get primaryTint => AppColors.primary.withValues(alpha: 0.10);

  /// Border for brand-tinted surfaces.
  Color get primaryTintBorder => AppColors.primary.withValues(alpha: 0.28);

  /// Brand color for small text labels. The bright teal reads fine on dark
  /// surfaces but is ~1.9:1 on white, so light mode uses the deep teal.
  Color get brandLabel =>
      _isDark ? AppColors.primary : AppColors.primaryDim;
}
