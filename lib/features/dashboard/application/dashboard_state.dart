import '../../../core/providers.dart' show DayPart;
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
  weeklyReview,
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
    this.dayPart = DayPart.morning,
    this.weeklyReviewDone = false,
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

  /// Coarse time of day — morning plans, evening closes.
  final DayPart dayPart;

  /// Whether this week's review has been written.
  final bool weeklyReviewDone;

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

  /// Sunday is review day: the week is effectively written.
  bool get weeklyReviewDue =>
      focus.today.weekday == DateTime.sunday && !weeklyReviewDone;

  /// One sayable sentence for Siri's "what's next in Life Assist".
  String get upNextSpoken => switch (upNext) {
        UpNextKind.setGoal => 'Set your main goal — the app organizes '
            'itself around it.',
        UpNextKind.goalCompleted =>
          'You finished ${goal?.title ?? 'your goal'}. Take the win.',
        UpNextKind.moneyCritical => 'Money needs a look before anything '
            'else today.',
        UpNextKind.logAction =>
          "Take one small step toward ${goal?.title ?? 'your goal'} and "
              'log it.',
        UpNextKind.logGoalTime =>
          'Hours on ${goal?.title ?? 'your goal'} are behind this week.',
        UpNextKind.logMetric => 'Log your progress measure to keep the '
            'trend honest.',
        UpNextKind.weeklyReview =>
          "It's Sunday — five minutes closes the week.",
        UpNextKind.protectRecovery =>
          'No downtime logged this week. Protect a block.',
        UpNextKind.reviewIdeas =>
          '$ideasDueForReview idea${ideasDueForReview == 1 ? ' is' : 's are'} '
              'ready for a verdict.',
        UpNextKind.nextMilestone =>
          'Next milestone: ${focus.nextMilestone?.title ?? 'on Focus'}.',
        UpNextKind.steady => "You're on pace. Nothing urgent is waiting.",
      };

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
    if (weeklyReviewDue) return UpNextKind.weeklyReview;
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
