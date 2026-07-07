import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/theme/app_colors.dart';
import 'package:life_dashboard/core/utils/score_utils.dart';

void main() {
  group('Focus Integrity Score', () {
    FocusScoreInput input({
      double kaizenHours = 0,
      double kaizenTarget = 42,
      bool experiment = false,
      double surplus = 0,
      double surplusLow = 3200,
      bool health = false,
      double recovery = 0,
    }) =>
        FocusScoreInput(
          kaizenHoursThisWeek: kaizenHours,
          kaizenWeeklyTarget: kaizenTarget,
          todayExperimentLogged: experiment,
          projectedSurplus: surplus,
          targetSurplusLow: surplusLow,
          exerciseOrMeditationToday: health,
          recoveryHoursThisWeek: recovery,
        );

    test('perfect week scores 100', () {
      final score = ScoreUtils.focusScore(input(
        kaizenHours: 42,
        experiment: true,
        surplus: 3500,
        health: true,
        recovery: 10.5,
      ));
      expect(score.total, 100);
      expect(score.kaizenScore, 35);
      expect(score.experimentScore, 20);
      expect(score.moneyScore, 15);
      expect(score.healthScore, 15);
      expect(score.recoveryScore, 15);
    });

    test('zero week scores 0', () {
      expect(ScoreUtils.focusScore(input()).total, 0);
    });

    test('kaizen hours are proportional and capped', () {
      expect(ScoreUtils.focusScore(input(kaizenHours: 21)).kaizenScore,
          closeTo(17.5, 0.001));
      expect(ScoreUtils.focusScore(input(kaizenHours: 84)).kaizenScore, 35);
    });

    test('money score scales below the floor and clamps negative', () {
      expect(ScoreUtils.focusScore(input(surplus: 1600)).moneyScore,
          closeTo(7.5, 0.001));
      expect(ScoreUtils.focusScore(input(surplus: -500)).moneyScore, 0);
      expect(ScoreUtils.focusScore(input(surplus: 3200)).moneyScore, 15);
    });

    test('recovery gives 15 at 5h, 7 when above zero, 0 at zero', () {
      expect(ScoreUtils.focusScore(input(recovery: 5)).recoveryScore, 15);
      expect(ScoreUtils.focusScore(input(recovery: 2)).recoveryScore, 7);
      expect(ScoreUtils.focusScore(input(recovery: 0)).recoveryScore, 0);
    });

    test('labels match spec bands', () {
      expect(ScoreUtils.focusScoreLabel(85), 'Aligned');
      expect(ScoreUtils.focusScoreLabel(80), 'Aligned');
      expect(ScoreUtils.focusScoreLabel(79), 'Acceptable');
      expect(ScoreUtils.focusScoreLabel(60), 'Acceptable');
      expect(ScoreUtils.focusScoreLabel(59), 'Drifting');
      expect(ScoreUtils.focusScoreLabel(40), 'Drifting');
      expect(ScoreUtils.focusScoreLabel(39), 'Correction needed');
      expect(ScoreUtils.focusScoreLabel(0), 'Correction needed');
    });
  });

  group('Kaizen hours status', () {
    test('35+ aligned, 25-34.9 watch, below 25 drifting', () {
      expect(ScoreUtils.kaizenHoursStatus(42), StatusLevel.aligned);
      expect(ScoreUtils.kaizenHoursStatus(35), StatusLevel.aligned);
      expect(ScoreUtils.kaizenHoursStatus(34.9), StatusLevel.watch);
      expect(ScoreUtils.kaizenHoursStatus(25), StatusLevel.watch);
      expect(ScoreUtils.kaizenHoursStatus(24.9), StatusLevel.critical);
      expect(ScoreUtils.kaizenHoursLabel(24), 'Drifting');
    });
  });

  group('Recovery status', () {
    test('0 critical, under 5 warning, 5+ aligned', () {
      expect(ScoreUtils.recoveryStatus(0), StatusLevel.critical);
      expect(ScoreUtils.recoveryStatus(4.9), StatusLevel.watch);
      expect(ScoreUtils.recoveryStatus(5), StatusLevel.aligned);
      expect(ScoreUtils.recoveryStatus(10.5), StatusLevel.aligned);
      expect(ScoreUtils.recoveryLabel(0), 'Critical');
      expect(ScoreUtils.recoveryLabel(3), 'Warning');
    });
  });

  group('Surplus status', () {
    test('negative critical, below low watch, otherwise aligned', () {
      expect(
        ScoreUtils.surplusStatus(projectedSurplus: -1, targetSurplusLow: 3200),
        StatusLevel.critical,
      );
      expect(
        ScoreUtils.surplusStatus(
            projectedSurplus: 3199, targetSurplusLow: 3200),
        StatusLevel.watch,
      );
      expect(
        ScoreUtils.surplusStatus(
            projectedSurplus: 3200, targetSurplusLow: 3200),
        StatusLevel.aligned,
      );
    });
  });
}
