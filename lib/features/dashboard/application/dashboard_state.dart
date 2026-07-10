import '../../../core/theme/app_colors.dart';
import '../../../core/utils/score_utils.dart';
import '../../focus/application/focus_state.dart';
import '../../focus/domain/main_goal.dart';
import '../../money/application/money_state.dart';
import '../../money/domain/money_flag.dart';
import '../../settings/domain/user_settings.dart';
import '../../time/application/time_state.dart';

/// What the "Up next" card should point the user at, in priority order.
enum UpNextKind {
  setGoal,
  goalCompleted,
  moneyCritical,
  logAction,
  logGoalTime,
  logMetric,
  protectRecovery,
  reviewIdeas,
  nextMilestone,
  steady,
}

/// Everything the Today screen shows, derived from the module states.
class DashboardState {
  DashboardState({
    required this.focus,
    required this.money,
    required this.time,
    required this.settings,
    required this.exerciseOrMeditationToday,
    required this.parkedIdeaCount,
    required this.ideasDueForReview,
  }) {
    focusScore = ScoreUtils.focusScore(FocusScoreInput(
      goalHoursThisWeek: time.goalHoursThisWeek,
      goalWeeklyTarget: time.goalWeeklyTarget,
      todayActionLogged: focus.todayActionLogged,
      projectedSurplus: money.snapshot.projectedSurplus,
      targetSurplusLow: money.snapshot.targetSurplusLow,
      exerciseOrMeditationToday: exerciseOrMeditationToday,
      recoveryHoursThisWeek: time.recoveryHoursThisWeek,
      // Hidden areas are excluded from the score, not silently failed.
      includeMoney: settings.showsArea(DashboardArea.money),
      includeHealth: settings.showsArea(DashboardArea.habits),
      includeRecovery: settings.showsArea(DashboardArea.time),
    ));
    upNext = _resolveUpNext();
  }

  final FocusState focus;
  final MoneyState money;
  final TimeState time;
  final UserSettings settings;
  final bool exerciseOrMeditationToday;
  final int parkedIdeaCount;
  final int ideasDueForReview;

  late final FocusScoreBreakdown focusScore;
  late final UpNextKind upNext;

  MainGoal? get goal => focus.goal;

  bool get goalActive => goal?.isActive ?? false;

  /// The score ring only means something once a goal is being pursued.
  bool get showScore => goalActive;

  bool showsArea(DashboardArea area) => settings.showsArea(area);

  bool get moneyCritical =>
      showsArea(DashboardArea.money) &&
      settings.hasIncome &&
      (money.snapshot.projectedSurplus < 0 ||
          money.snapshot.flags
              .any((f) => f.severity == MoneyFlagSeverity.critical));

  bool get goalHoursBehind =>
      time.goalWeeklyTarget > 0 &&
      time.goalHoursThisWeek < time.goalWeeklyTarget * 0.5;

  StatusLevel get goalHoursStatus =>
      ScoreUtils.goalHoursStatus(time.goalHoursThisWeek, time.goalWeeklyTarget);

  StatusLevel get recoveryStatus =>
      ScoreUtils.recoveryStatus(time.recoveryHoursThisWeek);

  StatusLevel get surplusStatus => ScoreUtils.surplusStatus(
        projectedSurplus: money.snapshot.projectedSurplus,
        targetSurplusLow: money.snapshot.targetSurplusLow,
      );

  /// The one thing most worth doing right now.
  UpNextKind _resolveUpNext() {
    if (goal == null) return UpNextKind.setGoal;
    if (goal!.isCompleted) return UpNextKind.goalCompleted;
    if (moneyCritical) return UpNextKind.moneyCritical;
    if (goalActive) {
      if (!focus.todayActionLogged) return UpNextKind.logAction;
      if (showsArea(DashboardArea.time) && goalHoursBehind) {
        return UpNextKind.logGoalTime;
      }
      if (focus.activeMetric != null && focus.todayMetricValue == null) {
        return UpNextKind.logMetric;
      }
    }
    if (showsArea(DashboardArea.time) && time.recoveryHoursThisWeek <= 0) {
      return UpNextKind.protectRecovery;
    }
    if (showsArea(DashboardArea.ideas) && ideasDueForReview > 0) {
      return UpNextKind.reviewIdeas;
    }
    if (goalActive && focus.nextMilestone != null) {
      return UpNextKind.nextMilestone;
    }
    return UpNextKind.steady;
  }
}
