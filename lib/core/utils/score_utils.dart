import 'dart:math' as math;

import '../theme/app_colors.dart';

/// Inputs for the daily focus score. All values come from real data.
/// The include flags mirror the Today-screen area toggles — a hidden area
/// must not cost points, so its part is excluded and the rest renormalizes.
class FocusScoreInput {
  const FocusScoreInput({
    required this.goalHoursThisWeek,
    required this.goalWeeklyTarget,
    required this.todayActionLogged,
    required this.projectedSurplus,
    required this.targetSurplusLow,
    required this.exerciseOrMeditationToday,
    required this.recoveryHoursThisWeek,
    this.weekday = DateTime.sunday,
    this.hasIncome = true,
    this.includeMoney = true,
    this.includeHealth = true,
    this.includeRecovery = true,
  });

  final double goalHoursThisWeek;
  final double goalWeeklyTarget;
  final bool todayActionLogged;
  final double projectedSurplus;
  final double targetSurplusLow;
  final bool exerciseOrMeditationToday;
  final double recoveryHoursThisWeek;

  /// Today's weekday (Mon=1..Sun=7). The two weekly components are
  /// measured against the fraction of the week that has actually
  /// happened — see [ScoreUtils.focusScore].
  final int weekday;

  /// Whether the user has entered an income. Without one there is no
  /// money signal to score, so the money component is dropped rather
  /// than awarded for free.
  final bool hasIncome;

  final bool includeMoney;
  final bool includeHealth;
  final bool includeRecovery;
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
  final double? moneyScore; // up to 15; null = money area hidden
  final double? healthScore; // 0 or 15; null = habits area hidden
  final double? recoveryScore; // 0, 7, or 15; null = time area hidden

  double get _earned =>
      goalScore +
      actionScore +
      (moneyScore ?? 0) +
      (healthScore ?? 0) +
      (recoveryScore ?? 0);

  /// Only enabled parts count toward the denominator, so 100 stays
  /// reachable no matter which areas are turned off.
  double get _possible =>
      35 +
      20 +
      (moneyScore == null ? 0 : 15) +
      (healthScore == null ? 0 : 15) +
      (recoveryScore == null ? 0 : 15);

  int get total => (_earned / _possible * 100).round().clamp(0, 100);
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

  /// Recovery hours that count as fully protected across a whole week.
  static const double _recoveryWeeklyTarget = 5;

  /// How much of the week has happened, as a fraction (Monday = 1/7).
  /// The score is shown as "today's score", so its weekly components
  /// must be judged against the week SO FAR — otherwise identical
  /// behaviour reads 50/100 on Monday morning and 100/100 on Sunday
  /// night purely because more week has elapsed.
  static double weekFraction(int weekday) =>
      (weekday.clamp(DateTime.monday, DateTime.sunday)) / 7;

  static FocusScoreBreakdown focusScore(FocusScoreInput input) {
    final elapsed = weekFraction(input.weekday);

    final weeklyTarget = input.goalWeeklyTarget > 0
        ? input.goalWeeklyTarget
        : _fallbackWeeklyTarget;
    // Pace, not total: hours-to-date against the share of the target
    // due by today.
    final goalDue = weeklyTarget * elapsed;
    final goalScore =
        (goalDue <= 0 ? 1.0 : math.min(input.goalHoursThisWeek / goalDue, 1.0)) *
            35;

    final actionScore = input.todayActionLogged ? 20.0 : 0.0;

    final double? moneyScore;
    if (!input.includeMoney || !input.hasIncome) {
      // No income entered = no money signal. Awarding the full 15
      // anyway (the old `targetSurplusLow <= 0` branch) handed every
      // new user free points the rest of the app didn't believe in —
      // `moneyCritical` gates on hasIncome, so score and alert
      // disagreed about whether money data existed at all.
      moneyScore = null;
    } else if (input.targetSurplusLow <= 0) {
      moneyScore = input.projectedSurplus >= 0 ? 15.0 : 0.0;
    } else if (input.projectedSurplus >= input.targetSurplusLow) {
      moneyScore = 15.0;
    } else {
      moneyScore =
          math.max(input.projectedSurplus / input.targetSurplusLow, 0.0) * 15;
    }

    final healthScore = !input.includeHealth
        ? null
        : input.exerciseOrMeditationToday
            ? 15.0
            : 0.0;

    // Recovery is also weekly, so it is also paced.
    final double? recoveryScore;
    if (!input.includeRecovery) {
      recoveryScore = null;
    } else {
      final due = _recoveryWeeklyTarget * elapsed;
      recoveryScore = due <= 0
          ? 15.0
          : math.min(input.recoveryHoursThisWeek / due, 1.0) * 15;
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
