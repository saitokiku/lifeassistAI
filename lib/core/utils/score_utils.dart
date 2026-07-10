import 'dart:math' as math;

import '../theme/app_colors.dart';

/// Inputs for the daily focus score. All values come from real data.
class FocusScoreInput {
  const FocusScoreInput({
    required this.goalHoursThisWeek,
    required this.goalWeeklyTarget,
    required this.todayActionLogged,
    required this.projectedSurplus,
    required this.targetSurplusLow,
    required this.exerciseOrMeditationToday,
    required this.recoveryHoursThisWeek,
  });

  final double goalHoursThisWeek;
  final double goalWeeklyTarget;
  final bool todayActionLogged;
  final double projectedSurplus;
  final double targetSurplusLow;
  final bool exerciseOrMeditationToday;
  final double recoveryHoursThisWeek;
}

class FocusScoreBreakdown {
  const FocusScoreBreakdown({
    required this.goalScore,
    required this.actionScore,
    required this.moneyScore,
    required this.healthScore,
    required this.recoveryScore,
  });

  final double goalScore; // up to 35
  final double actionScore; // 0 or 20
  final double moneyScore; // up to 15
  final double healthScore; // 0 or 15
  final double recoveryScore; // 0, 7, or 15

  int get total =>
      (goalScore + actionScore + moneyScore + healthScore + recoveryScore)
          .round()
          .clamp(0, 100);
}

class ScoreUtils {
  ScoreUtils._();

  /// Hours count as on-track from 80% of the weekly target, and as
  /// slipping below half of it. Ratios, not absolutes, so the score is
  /// honest for a 5-hour week and a 40-hour week alike.
  static const double _hoursAlignedRatio = 0.8;
  static const double _hoursWatchRatio = 0.5;

  /// Fallback weekly target when none is configured.
  static const double _fallbackWeeklyTarget = 10;

  static FocusScoreBreakdown focusScore(FocusScoreInput input) {
    final target = input.goalWeeklyTarget > 0
        ? input.goalWeeklyTarget
        : _fallbackWeeklyTarget;
    final goalScore = math.min(input.goalHoursThisWeek / target, 1.0) * 35;

    final actionScore = input.todayActionLogged ? 20.0 : 0.0;

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
      goalScore: goalScore,
      actionScore: actionScore,
      moneyScore: moneyScore,
      healthScore: healthScore,
      recoveryScore: recoveryScore,
    );
  }

  static String focusScoreLabel(int score) {
    if (score >= 80) return 'On track';
    if (score >= 60) return 'Steady';
    if (score >= 40) return 'Slipping';
    return 'Needs attention';
  }

  /// The day score never turns red — a quiet morning isn't an emergency.
  /// Red is reserved for genuinely critical signals (money flags).
  static StatusLevel focusScoreStatus(int score) {
    if (score >= 80) return StatusLevel.aligned;
    return StatusLevel.watch;
  }

  /// Weekly goal hours against their target: 80%+ on track, 50%+ watch.
  static StatusLevel goalHoursStatus(double hours, double target) {
    if (target <= 0) return StatusLevel.neutral;
    final ratio = hours / target;
    if (ratio >= _hoursAlignedRatio) return StatusLevel.aligned;
    if (ratio >= _hoursWatchRatio) return StatusLevel.watch;
    return StatusLevel.critical;
  }

  static String goalHoursLabel(double hours, double target) {
    return switch (goalHoursStatus(hours, target)) {
      StatusLevel.aligned => 'On track',
      StatusLevel.watch => 'Behind',
      StatusLevel.critical => 'Far behind',
      StatusLevel.neutral => 'No target',
    };
  }

  /// Recovery: 0 critical, under 5 warning, otherwise aligned.
  static StatusLevel recoveryStatus(double decompressHours) {
    if (decompressHours <= 0) return StatusLevel.critical;
    if (decompressHours < 5) return StatusLevel.watch;
    return StatusLevel.aligned;
  }

  static String recoveryLabel(double decompressHours) {
    if (decompressHours <= 0) return 'At zero';
    if (decompressHours < 5) return 'Thin';
    return 'Protected';
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
  }) {
    if (projectedSurplus < 0) return 'Overspent';
    if (projectedSurplus < targetSurplusLow) return 'Under target';
    return 'On track';
  }
}
