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
      // The weekly components are judged against the week so far, so
      // the same behaviour scores the same on Monday and on Sunday.
      weekday: focus.today.weekday,
      hasIncome: settings.hasIncome,
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

  /// Money needs attention before anything else today.
  ///
  /// A projected overspend only counts once the projection means
  /// something. Rent on the 1st makes a straight-line projection scream
  /// (one $1,500 charge extrapolates to $46,500), which used to outrank
  /// the daily step and hand every rent-payer a false alarm for the
  /// first days of every month. Category flags are real observations,
  /// not extrapolations, so those still count immediately.
  bool get moneyCritical =>
      showsArea(DashboardArea.money) &&
      settings.hasIncome &&
      ((money.snapshot.projectedSurplus < 0 &&
              money.snapshot.projectionIsMeaningful) ||
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

  /// Review time: Sunday, or Monday before the week gets going. A
  /// Sunday-only window meant that missing one Sunday skipped the
  /// ritual entirely for that week — and because the review sat below
  /// three daily branches, it almost never surfaced at all.
  bool get weeklyReviewDue =>
      !weeklyReviewDone &&
      (focus.today.weekday == DateTime.sunday ||
          focus.today.weekday == DateTime.monday);

  /// Evening is for closing the day, not starting new work.
  bool get _isEvening => dayPart == DayPart.evening || dayPart == DayPart.late_;

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
  ///
  /// Time of day genuinely reorders this, rather than only rewording it:
  /// evenings close the day (log the step you took, write the review),
  /// mornings and afternoons plan it (put hours in, move the measure).
  UpNextKind _resolveUpNext() {
    if (goal == null) return UpNextKind.setGoal;
    if (goal!.isCompleted) return UpNextKind.goalCompleted;
    if (moneyCritical) return UpNextKind.moneyCritical;

    // Evening: the week's review is a closing act, so it outranks
    // starting anything new — but logging today's step still comes
    // first, because that IS closing the day.
    if (_isEvening) {
      if (goalActive && !focus.todayActionLogged) return UpNextKind.logAction;
      if (weeklyReviewDue) return UpNextKind.weeklyReview;
    }

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
