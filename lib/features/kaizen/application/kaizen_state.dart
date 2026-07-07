import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/daily_experiment.dart';

/// Derived, display-ready Kaizen numbers.
class KaizenState {
  const KaizenState({
    required this.activeMetric,
    required this.activeMetricEntries,
    required this.experiments,
    required this.today,
  });

  final GrowthMetric? activeMetric;
  final List<GrowthMetricEntry> activeMetricEntries; // newest first
  final List<DailyExperiment> experiments; // newest first
  final DateTime today;

  String get todayKey => AppDateUtils.dateKey(today);

  DailyExperiment? get todayExperiment {
    for (final e in experiments) {
      if (e.date == todayKey) return e;
    }
    return null;
  }

  bool get todayExperimentLogged => todayExperiment != null;

  Set<String> get loggedExperimentDays =>
      experiments.map((e) => e.date).toSet();

  int get experimentStreak =>
      ExperimentStats.streak(loggedExperimentDays, today);

  int get missedDaysLast30 =>
      ExperimentStats.missedDays(loggedExperimentDays, today);

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
