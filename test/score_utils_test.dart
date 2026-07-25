import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/theme/app_colors.dart';
import 'package:life_dashboard/core/utils/score_utils.dart';

void main() {
  group('Focus score', () {
    FocusScoreInput input({
      double goalHours = 0,
      double goalTarget = 42,
      bool action = false,
      double surplus = 0,
      double surplusLow = 3200,
      bool health = false,
      double recovery = 0,
    }) =>
        FocusScoreInput(
          goalHoursThisWeek: goalHours,
          goalWeeklyTarget: goalTarget,
          todayActionLogged: action,
          projectedSurplus: surplus,
          targetSurplusLow: surplusLow,
          exerciseOrMeditationToday: health,
          recoveryHoursThisWeek: recovery,
        );

    test('perfect week scores 100', () {
      final score = ScoreUtils.focusScore(input(
        goalHours: 42,
        action: true,
        surplus: 3500,
        health: true,
        recovery: 10.5,
      ));
      expect(score.total, 100);
      expect(score.goalScore, 35);
      expect(score.actionScore, 20);
      expect(score.moneyScore, 15);
      expect(score.healthScore, 15);
      expect(score.recoveryScore, 15);
    });

    test('zero week scores 0', () {
      expect(ScoreUtils.focusScore(input()).total, 0);
    });

    test('goal hours are proportional and capped', () {
      expect(ScoreUtils.focusScore(input(goalHours: 21)).goalScore,
          closeTo(17.5, 0.001));
      expect(ScoreUtils.focusScore(input(goalHours: 84)).goalScore, 35);
    });

    test('goal hours scale to a small weekly target too', () {
      // 5 of a 10-hour target = half of the 35 points.
      expect(
        ScoreUtils.focusScore(input(goalHours: 5, goalTarget: 10)).goalScore,
        closeTo(17.5, 0.001),
      );
    });

    test('money score scales below the floor and clamps negative', () {
      expect(ScoreUtils.focusScore(input(surplus: 1600)).moneyScore,
          closeTo(7.5, 0.001));
      expect(ScoreUtils.focusScore(input(surplus: -500)).moneyScore, 0);
      expect(ScoreUtils.focusScore(input(surplus: 3200)).moneyScore, 15);
    });

    test('with no surplus floor set, any non-negative surplus earns 15', () {
      expect(ScoreUtils.focusScore(input(surplus: 0, surplusLow: 0)).moneyScore,
          15);
      expect(
          ScoreUtils.focusScore(input(surplus: -1, surplusLow: 0)).moneyScore,
          0);
    });

    test('recovery scales with the hours due so far, capped at 15', () {
      // Paced like the goal hours: by Sunday the whole 5h is due, so 5h
      // is full marks and 2h is 2/5 of them. The old shape was a cliff
      // (15 / 7 / 0) whose middle tier was an unexplained magic number.
      expect(ScoreUtils.focusScore(input(recovery: 5)).recoveryScore, 15);
      expect(ScoreUtils.focusScore(input(recovery: 2)).recoveryScore, 6);
      expect(ScoreUtils.focusScore(input(recovery: 0)).recoveryScore, 0);
      // Over-delivering doesn't earn more than the part is worth.
      expect(ScoreUtils.focusScore(input(recovery: 40)).recoveryScore, 15);
    });

    test('labels match spec bands', () {
      expect(ScoreUtils.focusScoreLabel(85), 'On track');
      expect(ScoreUtils.focusScoreLabel(80), 'On track');
      expect(ScoreUtils.focusScoreLabel(79), 'Steady');
      expect(ScoreUtils.focusScoreLabel(60), 'Steady');
      expect(ScoreUtils.focusScoreLabel(59), 'Slipping');
      expect(ScoreUtils.focusScoreLabel(40), 'Slipping');
      expect(ScoreUtils.focusScoreLabel(39), 'Needs attention');
      expect(ScoreUtils.focusScoreLabel(0), 'Needs attention');
    });
  });

  group('Goal hours status', () {
    test('ratio-based: 80%+ aligned, 50%+ watch, below critical', () {
      expect(ScoreUtils.goalHoursStatus(42, 42), StatusLevel.aligned);
      expect(ScoreUtils.goalHoursStatus(33.6, 42), StatusLevel.aligned);
      expect(ScoreUtils.goalHoursStatus(33, 42), StatusLevel.watch);
      expect(ScoreUtils.goalHoursStatus(21, 42), StatusLevel.watch);
      expect(ScoreUtils.goalHoursStatus(20, 42), StatusLevel.critical);
      // The same ratios hold for a small target.
      expect(ScoreUtils.goalHoursStatus(8, 10), StatusLevel.aligned);
      expect(ScoreUtils.goalHoursStatus(5, 10), StatusLevel.watch);
      expect(ScoreUtils.goalHoursStatus(4.9, 10), StatusLevel.critical);
      // No target → neutral, never punished.
      expect(ScoreUtils.goalHoursStatus(3, 0), StatusLevel.neutral);
      expect(ScoreUtils.goalHoursLabel(4, 10), 'Far behind');
      expect(ScoreUtils.goalHoursLabel(9, 10), 'On track');
    });
  });

  group('Recovery status', () {
    test('0 critical, under 5 warning, 5+ aligned', () {
      expect(ScoreUtils.recoveryStatus(0), StatusLevel.critical);
      expect(ScoreUtils.recoveryStatus(4.9), StatusLevel.watch);
      expect(ScoreUtils.recoveryStatus(5), StatusLevel.aligned);
      expect(ScoreUtils.recoveryStatus(10.5), StatusLevel.aligned);
      expect(ScoreUtils.recoveryLabel(0), 'At zero');
      expect(ScoreUtils.recoveryLabel(3), 'Thin');
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
