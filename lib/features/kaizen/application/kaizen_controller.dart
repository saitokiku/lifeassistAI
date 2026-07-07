import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../data/kaizen_repository.dart';
import 'kaizen_state.dart';

final kaizenRepositoryProvider = Provider<KaizenRepository>(
  (ref) => KaizenRepository(ref.watch(databaseProvider)),
);

final growthMetricsProvider = StreamProvider<List<GrowthMetric>>(
  (ref) => ref.watch(kaizenRepositoryProvider).watchMetrics(),
);

final activeMetricProvider = StreamProvider<GrowthMetric?>(
  (ref) => ref.watch(kaizenRepositoryProvider).watchActiveMetric(),
);

final metricEntriesProvider =
    StreamProvider.family<List<GrowthMetricEntry>, String>(
  (ref, metricId) => ref.watch(kaizenRepositoryProvider).watchEntries(metricId),
);

final experimentsProvider = StreamProvider<List<DailyExperiment>>(
  (ref) => ref.watch(kaizenRepositoryProvider).watchExperiments(),
);

/// Combined Kaizen view state; null while any source is still loading.
final kaizenStateProvider = Provider<KaizenState?>((ref) {
  final now = readNow(ref);
  final metrics = ref.watch(activeMetricProvider);
  final experiments = ref.watch(experimentsProvider);
  if (metrics.isLoading || experiments.isLoading) return null;

  final active = metrics.valueOrNull;
  final entries = active == null
      ? const <GrowthMetricEntry>[]
      : ref.watch(metricEntriesProvider(active.id)).valueOrNull ??
          const <GrowthMetricEntry>[];

  return KaizenState(
    activeMetric: active,
    activeMetricEntries: entries,
    experiments: experiments.valueOrNull ?? const [],
    today: AppDateUtils.dateOnly(now),
  );
});

/// Thin mutation facade so widgets never touch the repository directly.
class KaizenController {
  KaizenController(this._repo);

  final KaizenRepository _repo;

  Future<void> createMetric({
    required String name,
    required String unit,
    required double weeklyTarget,
    bool makeActive = false,
  }) =>
      _repo.createMetric(
        name: name,
        unit: unit,
        weeklyTarget: weeklyTarget,
        makeActive: makeActive,
      );

  Future<void> updateMetric(GrowthMetric metric) => _repo.updateMetric(metric);

  Future<void> setActiveMetric(String id) => _repo.setActiveMetric(id);

  Future<void> deleteMetric(String id) => _repo.deleteMetric(id);

  Future<void> upsertEntry({
    required String metricId,
    required DateTime date,
    required double value,
    String? note,
  }) =>
      _repo.upsertEntry(metricId: metricId, date: date, value: value, note: note);

  Future<void> deleteEntry(String entryId) => _repo.deleteEntry(entryId);

  Future<void> logExperiment({
    required DateTime date,
    required String hypothesis,
    required String actionTaken,
    required String result,
    required String verdict,
    String? notes,
  }) =>
      _repo.logExperiment(
        date: date,
        hypothesis: hypothesis,
        actionTaken: actionTaken,
        result: result,
        verdict: verdict,
        notes: notes,
      );

  Future<void> updateExperiment(DailyExperiment experiment) =>
      _repo.updateExperiment(experiment);

  Future<void> deleteExperiment(String id) => _repo.deleteExperiment(id);
}

final kaizenControllerProvider = Provider<KaizenController>(
  (ref) => KaizenController(ref.watch(kaizenRepositoryProvider)),
);
