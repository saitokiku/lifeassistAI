import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';

/// Persistence for the main goal and everything under it: milestones,
/// progress measures (growth metrics + entries), and daily actions.
class FocusRepository {
  FocusRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  // --- Main goal ------------------------------------------------------------

  /// The goal the app organizes itself around: the most recent non-archived
  /// one. A completed goal stays current — celebrated, not vanished — until
  /// the user starts the next one; only archived goals leave the stage.
  Stream<MainGoal?> watchCurrentGoal() => (_db.select(_db.mainGoals)
        ..where((t) => t.status.isIn(['active', 'paused', 'completed']))
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
        ..limit(1))
      .watchSingleOrNull();

  Stream<List<MainGoal>> watchAllGoals() => (_db.select(_db.mainGoals)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Future<MainGoal> createGoal({
    required String title,
    String why = '',
    DateTime? targetDate,
  }) async {
    final now = DateTime.now();
    final goal = MainGoal(
      id: _uuid.v4(),
      title: title,
      why: why,
      targetDate: targetDate == null ? null : AppDateUtils.dateKey(targetDate),
      status: 'active',
      createdAt: now,
      updatedAt: now,
      completedAt: null,
    );
    await _db.transaction(() async {
      // Starting a new goal shelves any other open one — one goal at a time.
      await (_db.update(_db.mainGoals)
            ..where((t) => t.status.isIn(['active', 'paused'])))
          .write(MainGoalsCompanion(
        status: const Value('archived'),
        updatedAt: Value(now),
      ));
      await _db.into(_db.mainGoals).insert(goal);
    });
    return goal;
  }

  Future<void> updateGoal(MainGoal goal) => _db.update(_db.mainGoals).replace(
        goal.copyWith(updatedAt: DateTime.now()),
      );

  Future<void> setGoalStatus(String id, String status) async {
    final now = DateTime.now();
    await (_db.update(_db.mainGoals)..where((t) => t.id.equals(id)))
        .write(MainGoalsCompanion(
      status: Value(status),
      updatedAt: Value(now),
      completedAt: Value(status == 'completed' ? now : null),
    ));
  }

  // --- Milestones -----------------------------------------------------------

  Stream<List<Goal>> watchMilestones() => (_db.select(_db.goals)
        ..orderBy([
          (t) => OrderingTerm.asc(t.isDone),
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.createdAt),
        ]))
      .watch();

  Future<Goal> createMilestone({
    required String title,
    String? description,
    String? metricName,
    double currentValue = 0,
    double targetValue = 0,
    DateTime? targetDate,
  }) async {
    final now = DateTime.now();
    final count = await _db.goals.count().getSingle();
    final milestone = Goal(
      id: _uuid.v4(),
      title: title,
      description: description,
      metricName: metricName,
      currentValue: currentValue,
      targetValue: targetValue,
      targetDate: targetDate == null ? null : AppDateUtils.dateKey(targetDate),
      isDone: false,
      sortOrder: count,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.goals).insert(milestone);
    return milestone;
  }

  Future<void> updateMilestone(Goal milestone) => _db.update(_db.goals).replace(
        milestone.copyWith(updatedAt: DateTime.now()),
      );

  Future<void> setMilestoneDone(String id, bool done) async {
    await (_db.update(_db.goals)..where((t) => t.id.equals(id)))
        .write(GoalsCompanion(
      isDone: Value(done),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> deleteMilestone(String id) =>
      (_db.delete(_db.goals)..where((t) => t.id.equals(id))).go();

  /// Rewrites sortOrder to match [orderedIds] (position = order).
  Future<void> reorderMilestones(List<String> orderedIds) =>
      _db.transaction(() async {
        final now = DateTime.now();
        for (final (i, id) in orderedIds.indexed) {
          await (_db.update(_db.goals)..where((t) => t.id.equals(id)))
              .write(GoalsCompanion(
            sortOrder: Value(i),
            updatedAt: Value(now),
          ));
        }
      });

  // --- Progress measures (growth metrics) -----------------------------------

  Stream<List<GrowthMetric>> watchMetrics() => (_db.select(_db.growthMetrics)
        ..orderBy([
          (t) => OrderingTerm.desc(t.isActive),
          (t) => OrderingTerm.asc(t.createdAt),
        ]))
      .watch();

  Stream<GrowthMetric?> watchActiveMetric() => (_db.select(_db.growthMetrics)
        ..where((t) => t.isActive.equals(true))
        ..limit(1))
      .watchSingleOrNull();

  Future<GrowthMetric> createMetric({
    required String name,
    required String unit,
    required double weeklyTarget,
    bool makeActive = false,
  }) async {
    final now = DateTime.now();
    final metric = GrowthMetric(
      id: _uuid.v4(),
      name: name,
      unit: unit,
      currentValue: 0,
      weeklyTarget: weeklyTarget,
      isActive: false,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.growthMetrics).insert(metric);
    if (makeActive) await setActiveMetric(metric.id);
    return metric;
  }

  Future<void> updateMetric(GrowthMetric metric) =>
      _db.update(_db.growthMetrics).replace(
            metric.copyWith(updatedAt: DateTime.now()),
          );

  /// Exactly one metric is active at a time.
  Future<void> setActiveMetric(String id) => _db.transaction(() async {
        await (_db.update(_db.growthMetrics)
              ..where((t) => t.isActive.equals(true)))
            .write(const GrowthMetricsCompanion(isActive: Value(false)));
        await (_db.update(_db.growthMetrics)..where((t) => t.id.equals(id)))
            .write(GrowthMetricsCompanion(
          isActive: const Value(true),
          updatedAt: Value(DateTime.now()),
        ));
      });

  Future<void> deleteMetric(String id) => _db.transaction(() async {
        await (_db.delete(_db.growthMetricEntries)
              ..where((t) => t.metricId.equals(id)))
            .go();
        await (_db.delete(_db.growthMetrics)..where((t) => t.id.equals(id)))
            .go();
      });

  // --- Metric entries -------------------------------------------------------

  Stream<List<GrowthMetricEntry>> watchEntries(String metricId) =>
      (_db.select(_db.growthMetricEntries)
            ..where((t) => t.metricId.equals(metricId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  /// Adds (or replaces) the entry for a date and refreshes the metric's
  /// currentValue to the latest entry by date.
  Future<void> upsertEntry({
    required String metricId,
    required DateTime date,
    required double value,
    String? note,
  }) async {
    final key = AppDateUtils.dateKey(date);
    await _db.transaction(() async {
      // Atomic against the (metricId, date) unique index — see the note
      // in HabitsRepository.upsertLog.
      await _db.into(_db.growthMetricEntries).insert(
            GrowthMetricEntry(
              id: _uuid.v4(),
              metricId: metricId,
              date: key,
              value: value,
              note: note,
            ),
            onConflict: DoUpdate(
              (_) => GrowthMetricEntriesCompanion(
                value: Value(value),
                note: Value(note),
              ),
              target: [
                _db.growthMetricEntries.metricId,
                _db.growthMetricEntries.date,
              ],
            ),
          );
      await _refreshCurrentValue(metricId);
    });
  }

  Future<void> deleteEntry(String entryId) async {
    final entry = await (_db.select(_db.growthMetricEntries)
          ..where((t) => t.id.equals(entryId)))
        .getSingleOrNull();
    if (entry == null) return;
    await _db.transaction(() async {
      await (_db.delete(_db.growthMetricEntries)
            ..where((t) => t.id.equals(entryId)))
          .go();
      await _refreshCurrentValue(entry.metricId);
    });
  }

  Future<void> _refreshCurrentValue(String metricId) async {
    final latest = await (_db.select(_db.growthMetricEntries)
          ..where((t) => t.metricId.equals(metricId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(1))
        .getSingleOrNull();
    await (_db.update(_db.growthMetrics)..where((t) => t.id.equals(metricId)))
        .write(GrowthMetricsCompanion(
      currentValue: Value(latest?.value ?? 0),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // --- Daily actions --------------------------------------------------------

  /// Actions newest-first. When [sinceDays] is set, only rows within that
  /// trailing window (from [today]) are streamed — the date index makes
  /// this cheap no matter how long the log grows.
  Stream<List<DailyExperiment>> watchActions(
      {int? sinceDays, DateTime? today}) {
    final query = _db.select(_db.dailyExperiments)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (sinceDays != null) {
      final from =
          AppDateUtils.subtractDays(today ?? DateTime.now(), sinceDays);
      query.where(
          (t) => t.date.isBiggerOrEqualValue(AppDateUtils.dateKey(from)));
    }
    return query.watch();
  }

  Future<void> logAction({
    required DateTime date,
    required String hypothesis,
    required String actionTaken,
    required String result,
    required String verdict,
    String? notes,
  }) async {
    final now = DateTime.now();
    await _db.into(_db.dailyExperiments).insert(DailyExperiment(
          id: _uuid.v4(),
          date: AppDateUtils.dateKey(date),
          hypothesis: hypothesis,
          actionTaken: actionTaken,
          result: result,
          verdict: verdict,
          notes: notes,
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<void> updateAction(DailyExperiment action) =>
      _db.update(_db.dailyExperiments).replace(
            action.copyWith(updatedAt: DateTime.now()),
          );

  Future<void> deleteAction(String id) =>
      (_db.delete(_db.dailyExperiments)..where((t) => t.id.equals(id))).go();
}
