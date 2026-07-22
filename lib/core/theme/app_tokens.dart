import 'package:flutter/animation.dart';

/// Spacing scale. Every gap in the app comes from here — no magic numbers.
class AppSpace {
  AppSpace._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Horizontal padding for every screen's content.
  static const double screen = 20;

  /// Vertical gap between sibling cards.
  static const double cardGap = 12;

  /// Vertical gap between sections.
  static const double sectionGap = 28;

  /// Inner padding of a standard card.
  static const double cardPadding = 18;

  /// Inner padding of a compact tile.
  static const double tilePadding = 14;
}

/// Corner radii. One radius per component role.
class AppRadius {
  AppRadius._();

  static const double card = 20;
  static const double tile = 16;
  static const double input = 14;
  static const double chip = 10;
  static const double sheet = 28;
  static const double snack = 14;

  /// Pill shape for buttons.
  static const double pill = 999;
}

/// Motion tokens. Subtle, purposeful, never decorative.
class AppMotion {
  AppMotion._();

  /// Press feedback and other near-instant responses.
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard state changes (fills, fades, toggles).
  static const Duration standard = Duration(milliseconds: 220);

  /// Emphasized moments: sheets, completion morphs, number rolls.
  static const Duration emphasized = Duration(milliseconds: 320);

  /// Animated numbers and progress sweeps.
  static const Duration sweep = Duration(milliseconds: 450);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.easeOutBack;

  /// Sheets and the tab bar's sliding dot: a settled, physical spring.
  static const Curve sheetIn = Curves.easeOutQuint;

  /// Tab-switch cross-fade duration (kept quicker than [standard] so
  /// navigation feels weightless).
  static const Duration tabSwitch = Duration(milliseconds: 180);
}
