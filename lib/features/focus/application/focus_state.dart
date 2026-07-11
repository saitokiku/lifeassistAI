import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/daily_action.dart';
import '../domain/main_goal.dart';

/// Derived, display-ready state for the main goal and its supporting loops.
class FocusState {
  const FocusState({
    required this.goal,
    required this.milestones,
    required this.activeMetric,
    required this.activeMetricEntries,
    required this.actions,
    required this.today,
  });

  /// The current main goal; null until the user sets one.
  final MainGoal? goal;

  /// Milestones, undone first (each in stored order).
  final List<Goal> milestones;

  final GrowthMetric? activeMetric;
  final List<GrowthMetricEntry> activeMetricEntries; // newest first
  final List<DailyExperiment> actions; // newest first
  final DateTime today;

  bool get hasGoal => goal != null;

  bool get goalPaused => goal?.isPaused ?? false;

  String get todayKey => AppDateUtils.dateKey(today);

  /// The next undone milestone, if any.
  Goal? get nextMilestone {
    for (final m in milestones) {
      if (!m.isDone) return m;
    }
    return null;
  }

  int get milestonesDone => milestones.where((m) => m.isDone).length;

  DailyExperiment? get todayAction {
    for (final a in actions) {
      if (a.date == todayKey) return a;
    }
    return null;
  }

  bool get todayActionLogged => todayAction != null;

  Set<String> get loggedActionDays => actions.map((a) => a.date).toSet();

  int get actionStreak => DailyActionStats.streak(loggedActionDays, today);

  int get missedDaysLast30 =>
      DailyActionStats.missedDays(loggedActionDays, today);

  /// Today's value for the active metric, if logged.
  double? get todayMetricValue {
    for (final e in activeMetricEntries) {
      if (e.date == todayKey) return e.value;
    }
    return null;
  }

  /// Last 7 days of metric values (oldest first) for the trend sparkline.
  /// Days without an entry carry the previous value forward; leading gaps
  /// are null.
  List<double?> get sevenDayTrend {
    final byDate = {for (final e in activeMetricEntries) e.date: e.value};
    final keys = AppDateUtils.lastDateKeys(today, 7);
    double? carry;
    // Find the latest value before the window to seed the carry.
    final windowStart = keys.first;
    final before = activeMetricEntries
        .where((e) => e.date.compareTo(windowStart) < 0)
        .toList();
    if (before.isNotEmpty) carry = before.first.value;
    return [
      for (final k in keys) carry = byDate[k] ?? carry,
    ];
  }
}
