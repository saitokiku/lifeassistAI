import 'dart:math' as math;

import '../theme/app_colors.dart';

/// Inputs for the Focus Integrity Score. All values come from real data.
class FocusScoreInput {
  const FocusScoreInput({
    required this.kaizenHoursThisWeek,
    required this.kaizenWeeklyTarget,
    required this.todayExperimentLogged,
    required this.projectedSurplus,
    required this.targetSurplusLow,
    required this.exerciseOrMeditationToday,
    required this.recoveryHoursThisWeek,
  });

  final double kaizenHoursThisWeek;
  final double kaizenWeeklyTarget;
  final bool todayExperimentLogged;
  final double projectedSurplus;
  final double targetSurplusLow;
  final bool exerciseOrMeditationToday;
  final double recoveryHoursThisWeek;
}

class FocusScoreBreakdown {
  const FocusScoreBreakdown({
    required this.kaizenScore,
    required this.experimentScore,
    required this.moneyScore,
    required this.healthScore,
    required this.recoveryScore,
  });

  final double kaizenScore; // up to 35
  final double experimentScore; // 0 or 20
  final double moneyScore; // up to 15
  final double healthScore; // 0 or 15
  final double recoveryScore; // 0, 7, or 15

  int get total => (kaizenScore + experimentScore + moneyScore + healthScore + recoveryScore)
      .round()
      .clamp(0, 100);
}

class ScoreUtils {
  ScoreUtils._();

  static FocusScoreBreakdown focusScore(FocusScoreInput input) {
    final target = input.kaizenWeeklyTarget > 0 ? input.kaizenWeeklyTarget : 42.0;
    final kaizenScore =
        math.min(input.kaizenHoursThisWeek / target, 1.0) * 35;

    final experimentScore = input.todayExperimentLogged ? 20.0 : 0.0;

    final double moneyScore;
    if (input.targetSurplusLow <= 0) {
      moneyScore = input.projectedSurplus >= 0 ? 15.0 : 0.0;
    } else if (input.projectedSurplus >= input.targetSurplusLow) {
      moneyScore = 15.0;
    } else {
      moneyScore =
          math.max(input.projectedSurplus / input.targetSurplusLow, 0.0) * 15;
    }

    final healthScore = input.exerciseOrMeditationToday ? 15.0 : 0.0;

    final double recoveryScore;
    if (input.recoveryHoursThisWeek >= 5) {
      recoveryScore = 15.0;
    } else if (input.recoveryHoursThisWeek > 0) {
      recoveryScore = 7.0;
    } else {
      recoveryScore = 0.0;
    }

    return FocusScoreBreakdown(
      kaizenScore: kaizenScore,
      experimentScore: experimentScore,
      moneyScore: moneyScore,
      healthScore: healthScore,
      recoveryScore: recoveryScore,
    );
  }

  static String focusScoreLabel(int score) {
    if (score >= 80) return 'Aligned';
    if (score >= 60) return 'Acceptable';
    if (score >= 40) return 'Drifting';
    return 'Correction needed';
  }

  static StatusLevel focusScoreStatus(int score) {
    if (score >= 80) return StatusLevel.aligned;
    if (score >= 60) return StatusLevel.watch;
    if (score >= 40) return StatusLevel.watch;
    return StatusLevel.critical;
  }

  /// Kaizen hours: 35+ aligned, 25–34.9 watch, below 25 drifting (critical).
  static StatusLevel kaizenHoursStatus(double hours) {
    if (hours >= 35) return StatusLevel.aligned;
    if (hours >= 25) return StatusLevel.watch;
    return StatusLevel.critical;
  }

  static String kaizenHoursLabel(double hours) {
    if (hours >= 35) return 'Aligned';
    if (hours >= 25) return 'Watch';
    return 'Drifting';
  }

  /// Recovery: 0 critical, under 5 warning, otherwise aligned.
  static StatusLevel recoveryStatus(double decompressHours) {
    if (decompressHours <= 0) return StatusLevel.critical;
    if (decompressHours < 5) return StatusLevel.watch;
    return StatusLevel.aligned;
  }

  static String recoveryLabel(double decompressHours) {
    if (decompressHours <= 0) return 'Critical';
    if (decompressHours < 5) return 'Warning';
    return 'Aligned';
  }

  /// Surplus status: negative critical, below low watch, otherwise aligned.
  static StatusLevel surplusStatus({
    required double projectedSurplus,
    required double targetSurplusLow,
  }) {
    if (projectedSurplus < 0) return StatusLevel.critical;
    if (projectedSurplus < targetSurplusLow) return StatusLevel.watch;
    return StatusLevel.aligned;
  }

  static String surplusLabel({
    required double projectedSurplus,
    required double targetSurplusLow,
    required double targetSurplusHigh,
  }) {
    if (projectedSurplus < 0) return 'Critical';
    if (projectedSurplus < targetSurplusLow) return 'Watch';
    if (projectedSurplus > targetSurplusHigh) return 'Aligned';
    return 'Aligned';
  }
}
