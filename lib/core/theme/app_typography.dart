import 'package:flutter/material.dart';

/// Type system: Inter carries the UI, Space Grotesk carries the numbers.
///
/// Material slot mapping (what each slot means in this app):
/// - displaySmall   → hero numbers (SG Bold 34)
/// - headlineMedium → large stat values (SG Bold 28)
/// - headlineSmall  → screen titles, greeting (SG Bold 22)
/// - titleLarge     → sheet titles (Inter SemiBold 18)
/// - titleMedium    → card titles (Inter SemiBold 16)
/// - titleSmall     → secondary titles/labels (Inter SemiBold 14)
/// - bodyLarge      → input text (Inter 16)
/// - bodyMedium     → body copy (Inter 15)
/// - bodySmall      → captions, metadata (Inter 12.5)
/// - labelLarge     → buttons (Inter SemiBold 15)
/// - labelMedium    → chips, small labels (Inter Medium 13)
/// - labelSmall     → overline section headers (Inter SemiBold 11, tracked)
class AppTypography {
  AppTypography._();

  static const String ui = 'Inter';
  static const String display = 'Space Grotesk';

  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  static TextTheme textTheme(Color primaryText, Color secondaryText) {
    TextStyle inter(double size, FontWeight weight, double height,
            {Color? color, double? spacing}) =>
        TextStyle(
          fontFamily: ui,
          fontSize: size,
          fontWeight: weight,
          height: height / size,
          letterSpacing: spacing,
          color: color ?? primaryText,
        );

    TextStyle grotesk(double size, FontWeight weight, double height) =>
        TextStyle(
          fontFamily: display,
          fontSize: size,
          fontWeight: weight,
          height: height / size,
          color: primaryText,
          fontFeatures: tabularFigures,
        );

    return TextTheme(
      displaySmall: grotesk(34, FontWeight.w700, 40),
      headlineMedium: grotesk(28, FontWeight.w700, 34),
      headlineSmall: grotesk(22, FontWeight.w700, 28),
      titleLarge: inter(18, FontWeight.w600, 24),
      titleMedium: inter(16, FontWeight.w600, 22),
      titleSmall: inter(14, FontWeight.w600, 20),
      bodyLarge: inter(16, FontWeight.w400, 24),
      bodyMedium: inter(15, FontWeight.w400, 21),
      bodySmall: inter(12.5, FontWeight.w400, 17, color: secondaryText),
      labelLarge: inter(15, FontWeight.w600, 20),
      labelMedium: inter(13, FontWeight.w500, 18),
      labelSmall: inter(11, FontWeight.w600, 16, spacing: 0.6),
    );
  }
}

/// Numeric styles that don't map to Material slots.
extension AppNumberStyles on TextTheme {
  /// Mid-size stat value (tiles): SG Medium 20.
  TextStyle get numberMedium => TextStyle(
        fontFamily: AppTypography.display,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 26 / 20,
        color: displaySmall?.color,
        fontFeatures: AppTypography.tabularFigures,
      );

  /// Inline numeric emphasis inside body copy.
  TextStyle get numberBody => TextStyle(
        fontFamily: AppTypography.display,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 21 / 15,
        color: bodyMedium?.color,
        fontFeatures: AppTypography.tabularFigures,
      );
}
