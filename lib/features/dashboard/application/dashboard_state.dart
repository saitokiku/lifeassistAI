import '../../../core/theme/app_colors.dart';
import '../../../core/utils/score_utils.dart';
import '../../identity/application/identity_state.dart';
import '../../kaizen/application/kaizen_state.dart';
import '../../money/application/money_state.dart';
import '../../time/application/time_state.dart';

/// Today's Command: one action per front, generated from real state.
class TodayCommand {
  const TodayCommand({
    required this.kaizenAction,
    required this.moneyConstraint,
    required this.recoveryAction,
    required this.antiDiffusionReminder,
  });

  final String kaizenAction;
  final String moneyConstraint;
  final String recoveryAction;
  final String antiDiffusionReminder;
}

/// Everything the dashboard shows, derived from the four module states.
class DashboardState {
  DashboardState({
    required this.kaizen,
    required this.money,
    required this.time,
    required this.identity,
    required this.exerciseOrMeditationToday,
    required this.parkedIdeaCount,
    required this.ideasDueForReview,
  }) {
    final breakdown = ScoreUtils.focusScore(FocusScoreInput(
      kaizenHoursThisWeek: time.kaizenHoursThisWeek,
      kaizenWeeklyTarget: time.kaizenWeeklyTarget,
      todayExperimentLogged: kaizen.todayExperimentLogged,
      projectedSurplus: money.snapshot.projectedSurplus,
      targetSurplusLow: money.snapshot.targetSurplusLow,
      exerciseOrMeditationToday: exerciseOrMeditationToday,
      recoveryHoursThisWeek: time.recoveryHoursThisWeek,
    ));
    focusScore = breakdown;
    command = _buildCommand();
  }

  final KaizenState kaizen;
  final MoneyState money;
  final TimeState time;
  final IdentityState identity;
  final bool exerciseOrMeditationToday;
  final int parkedIdeaCount;
  final int ideasDueForReview;

  late final FocusScoreBreakdown focusScore;
  late final TodayCommand command;

  StatusLevel get kaizenHoursStatus =>
      ScoreUtils.kaizenHoursStatus(time.kaizenHoursThisWeek);

  StatusLevel get recoveryStatus =>
      ScoreUtils.recoveryStatus(time.recoveryHoursThisWeek);

  StatusLevel get surplusStatus => ScoreUtils.surplusStatus(
        projectedSurplus: money.snapshot.projectedSurplus,
        targetSurplusLow: money.snapshot.targetSurplusLow,
      );

  TodayCommand _buildCommand() {
    // One Kaizen action.
    final String kaizenAction;
    if (!kaizen.todayExperimentLogged) {
      kaizenAction =
          'Run one same-day Kaizen experiment before touching a new idea.';
    } else if (time.kaizenHoursThisWeek < time.kaizenWeeklyTarget * 0.5) {
      kaizenAction =
          'Verdict logged. Now bank Kaizen hours — the week is behind target.';
    } else if (kaizen.todayMetricValue == null) {
      kaizenAction = "Log today's growth metric value. Keep the scoreboard live.";
    } else {
      kaizenAction = 'Kaizen is on pace. Protect the priority block tomorrow.';
    }

    // One money constraint.
    final snapshot = money.snapshot;
    final String moneyConstraint;
    final criticalFlag = snapshot.flags
        .where((f) => f.severity.name == 'critical')
        .toList();
    if (criticalFlag.isNotEmpty) {
      moneyConstraint = criticalFlag.first.message;
    } else if (snapshot.projectedSurplus < snapshot.targetSurplusLow) {
      moneyConstraint =
          'Projected surplus is under the floor. No discretionary spend today.';
    } else if (snapshot.uncategorizedCount > 0) {
      moneyConstraint = 'Undefined misc is fog. Categorize it.';
    } else {
      moneyConstraint = 'Spending is on pace. Keep the surplus pointed at freedom.';
    }

    // One recovery action.
    final String recoveryAction;
    if (time.recoveryHoursThisWeek <= 0) {
      recoveryAction =
          'Recovery is at zero. Schedule one decompress block today — it is load-bearing.';
    } else if (time.recoveryHoursThisWeek < 5) {
      recoveryAction =
          'Recovery is thin this week. Protect one decompress block tonight.';
    } else {
      recoveryAction = 'Recovery floor is holding. Keep it protected.';
    }

    // One anti-diffusion reminder.
    final String antiDiffusion;
    if (ideasDueForReview > 0) {
      antiDiffusion =
          '$ideasDueForReview parked idea${ideasDueForReview == 1 ? '' : 's'} finished cooling. Give a verdict: ignore, later, or integrate.';
    } else if (parkedIdeaCount > 0) {
      antiDiffusion =
          '$parkedIdeaCount idea${parkedIdeaCount == 1 ? '' : 's'} parked and cooling. Curiosity captured. Not chased.';
    } else {
      antiDiffusion = 'One hunt. New ideas go to the parking lot, not the calendar.';
    }

    return TodayCommand(
      kaizenAction: kaizenAction,
      moneyConstraint: moneyConstraint,
      recoveryAction: recoveryAction,
      antiDiffusionReminder: antiDiffusion,
    );
  }
}
