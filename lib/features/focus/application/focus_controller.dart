import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../data/focus_repository.dart';
import 'focus_state.dart';

final focusRepositoryProvider = Provider<FocusRepository>(
  (ref) => FocusRepository(ref.watch(databaseProvider)),
);

/// The user's current main goal; null until one is set.
final mainGoalProvider = StreamProvider<MainGoal?>(
  (ref) => ref.watch(focusRepositoryProvider).watchCurrentGoal(),
);

final milestonesProvider = StreamProvider<List<Goal>>(
  (ref) => ref.watch(focusRepositoryProvider).watchMilestones(),
);

final growthMetricsProvider = StreamProvider<List<GrowthMetric>>(
  (ref) => ref.watch(focusRepositoryProvider).watchMetrics(),
);

final activeMetricProvider = StreamProvider<GrowthMetric?>(
  (ref) => ref.watch(focusRepositoryProvider).watchActiveMetric(),
);

final metricEntriesProvider =
    StreamProvider.family<List<GrowthMetricEntry>, String>(
  (ref, metricId) => ref.watch(focusRepositoryProvider).watchEntries(metricId),
);

final dailyActionsProvider = StreamProvider<List<DailyExperiment>>(
  (ref) => ref.watch(focusRepositoryProvider).watchActions(),
);

/// Combined Focus view state; null while any source is still loading.
final focusStateProvider = Provider<FocusState?>((ref) {
  final now = readNow(ref);
  final goal = ref.watch(mainGoalProvider);
  final milestones = ref.watch(milestonesProvider);
  final metrics = ref.watch(activeMetricProvider);
  final actions = ref.watch(dailyActionsProvider);
  if (goal.isLoading ||
      milestones.isLoading ||
      metrics.isLoading ||
      actions.isLoading) {
    return null;
  }

  final active = metrics.valueOrNull;
  final entries = active == null
      ? const <GrowthMetricEntry>[]
      : ref.watch(metricEntriesProvider(active.id)).valueOrNull ??
          const <GrowthMetricEntry>[];

  return FocusState(
    goal: goal.valueOrNull,
    milestones: milestones.valueOrNull ?? const [],
    activeMetric: active,
    activeMetricEntries: entries,
    actions: actions.valueOrNull ?? const [],
    today: AppDateUtils.dateOnly(now),
  );
});

/// Thin mutation facade so widgets never touch the repository directly.
class FocusController {
  FocusController(this._repo);

  final FocusRepository _repo;

  // Main goal

  Future<MainGoal> createGoal({
    required String title,
    String why = '',
    DateTime? targetDate,
  }) =>
      _repo.createGoal(title: title, why: why, targetDate: targetDate);

  Future<void> updateGoal(
    MainGoal goal, {
    String? title,
    String? why,
    DateTime? targetDate,
    bool clearTargetDate = false,
  }) =>
      _repo.updateGoal(goal.copyWith(
        title: title ?? goal.title,
        why: why ?? goal.why,
        targetDate: clearTargetDate
            ? const Value(null)
            : targetDate == null
                ? Value(goal.targetDate)
                : Value(AppDateUtils.dateKey(targetDate)),
      ));

  Future<void> pauseGoal(String id) => _repo.setGoalStatus(id, 'paused');

  Future<void> resumeGoal(String id) => _repo.setGoalStatus(id, 'active');

  Future<void> completeGoal(String id) => _repo.setGoalStatus(id, 'completed');

  Future<void> archiveGoal(String id) => _repo.setGoalStatus(id, 'archived');

  // Milestones

  Future<void> createMilestone({
    required String title,
    String? description,
    String? metricName,
    double currentValue = 0,
    double targetValue = 0,
    DateTime? targetDate,
  }) =>
      _repo.createMilestone(
        title: title,
        description: description,
        metricName: metricName,
        currentValue: currentValue,
        targetValue: targetValue,
        targetDate: targetDate,
      );

  Future<void> updateMilestone(Goal milestone) =>
      _repo.updateMilestone(milestone);

  Future<void> setMilestoneDone(String id, bool done) =>
      _repo.setMilestoneDone(id, done);

  Future<void> deleteMilestone(String id) => _repo.deleteMilestone(id);

  // Progress measures

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
      _repo.upsertEntry(
          metricId: metricId, date: date, value: value, note: note);

  Future<void> deleteEntry(String entryId) => _repo.deleteEntry(entryId);

  // Daily actions

  Future<void> logAction({
    required DateTime date,
    required String hypothesis,
    required String actionTaken,
    required String result,
    required String verdict,
    String? notes,
  }) =>
      _repo.logAction(
        date: date,
        hypothesis: hypothesis,
        actionTaken: actionTaken,
        result: result,
        verdict: verdict,
        notes: notes,
      );

  Future<void> updateAction(DailyExperiment action) =>
      _repo.updateAction(action);

  Future<void> deleteAction(String id) => _repo.deleteAction(id);
}

final focusControllerProvider = Provider<FocusController>(
  (ref) => FocusController(ref.watch(focusRepositoryProvider)),
);
