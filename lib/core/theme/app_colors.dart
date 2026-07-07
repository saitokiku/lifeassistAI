import 'package:flutter/material.dart';

/// Palette for the command-center look. Dark mode first.
class AppColors {
  AppColors._();

  // Dark surfaces
  static const Color bgDark = Color(0xFF0B0E13);
  static const Color surfaceDark = Color(0xFF12161E);
  static const Color cardDark = Color(0xFF171D28);
  static const Color outlineDark = Color(0xFF2A3140);

  // Light surfaces
  static const Color bgLight = Color(0xFFF6F7F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color outlineLight = Color(0xFFD8DDE5);

  // Accent
  static const Color primary = Color(0xFF4FD1C5);
  static const Color primaryDim = Color(0xFF2C7A73);
  static const Color onPrimary = Color(0xFF06211E);

  // Status
  static const Color aligned = Color(0xFF34D399);
  static const Color watch = Color(0xFFFBBF24);
  static const Color critical = Color(0xFFF87171);
  static const Color neutral = Color(0xFF8B93A3);

  // Text
  static const Color textPrimaryDark = Color(0xFFE7EBF2);
  static const Color textSecondaryDark = Color(0xFF9AA3B2);
  static const Color textPrimaryLight = Color(0xFF171C26);
  static const Color textSecondaryLight = Color(0xFF5A6372);
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
