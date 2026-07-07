import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';

/// Persistence for growth metrics, metric entries, and daily experiments.
class KaizenRepository {
  KaizenRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  // --- Growth metrics -------------------------------------------------------

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
        await (_db.delete(_db.growthMetrics)..where((t) => t.id.equals(id))).go();
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
      final existing = await (_db.select(_db.growthMetricEntries)
            ..where((t) => t.metricId.equals(metricId) & t.date.equals(key)))
          .getSingleOrNull();
      if (existing != null) {
        await (_db.update(_db.growthMetricEntries)
              ..where((t) => t.id.equals(existing.id)))
            .write(GrowthMetricEntriesCompanion(
          value: Value(value),
          note: Value(note),
        ));
      } else {
        await _db.into(_db.growthMetricEntries).insert(GrowthMetricEntry(
              id: _uuid.v4(),
              metricId: metricId,
              date: key,
              value: value,
              note: note,
            ));
      }
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

  // --- Daily experiments ----------------------------------------------------

  Stream<List<DailyExperiment>> watchExperiments() =>
      (_db.select(_db.dailyExperiments)
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  Stream<DailyExperiment?> watchExperimentForDate(DateTime date) =>
      (_db.select(_db.dailyExperiments)
            ..where((t) => t.date.equals(AppDateUtils.dateKey(date)))
            ..limit(1))
          .watchSingleOrNull();

  Future<void> logExperiment({
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

  Future<void> updateExperiment(DailyExperiment experiment) =>
      _db.update(_db.dailyExperiments).replace(
            experiment.copyWith(updatedAt: DateTime.now()),
          );

  Future<void> deleteExperiment(String id) =>
      (_db.delete(_db.dailyExperiments)..where((t) => t.id.equals(id))).go();
}
