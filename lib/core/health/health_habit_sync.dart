import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../providers.dart';
import '../storage/app_database.dart';
import '../utils/date_utils.dart';
import 'health_service.dart';

/// Turns Apple Health data into habit logs for habits the user has
/// explicitly mapped (Habits.healthMetric + healthTarget).
///
/// Rules, in order of importance:
/// 1. **Manual always wins.** A log whose source isn't 'health' is never
///    touched — checking a habit yourself outranks the sensor.
/// 2. **Boolean habits** get checked (value 1, source 'health') when the
///    day's metric reaches the target; a previously auto-written check
///    is removed if the target is no longer met (only our own writes are
///    ever removed).
/// 3. **Numeric/duration habits** get the raw metric value logged, so
///    the habit history is real data, not a proxy checkmark.
/// 4. Nulls from HealthKit (no data — or no permission, which reads
///    identically by Apple's design) change nothing.
///
/// Syncs today and yesterday: health data lands late, and yesterday's
/// final numbers often arrive after midnight.
final healthHabitSyncProvider = Provider<HealthHabitSync>(
  (ref) => HealthHabitSync(
    ref.watch(databaseProvider),
    ref.watch(healthServiceProvider),
  ),
);

class HealthHabitSync {
  HealthHabitSync(this._db, this._service);

  static const metrics = <String, String>{
    'steps': 'Steps',
    'sleepHours': 'Sleep (hours)',
    'mindfulMinutes': 'Mindfulness (minutes)',
    'workoutMinutes': 'Workouts (minutes)',
  };

  final AppDatabase _db;
  final HealthService _service;
  final _uuid = const Uuid();

  /// Applies health data to mapped habits. Returns how many logs were
  /// written or removed. Cheap no-op when nothing is mapped or the
  /// bridge isn't ready.
  Future<int> sync({DateTime? now}) async {
    final mapped = await (_db.select(_db.habits)
          ..where((t) => t.healthMetric.isNotNull() &
              t.isArchived.equals(false)))
        .get();
    if (mapped.isEmpty) return 0;
    if (await _service.availability() != HealthAvailability.ready) return 0;

    final today = now ?? DateTime.now();
    var changed = 0;
    for (final day in [today, today.subtract(const Duration(days: 1))]) {
      final summary = await _service.dailySummary(day);
      if (summary == null) continue;
      for (final habit in mapped) {
        changed += await _applyDay(habit, day, summary);
      }
    }
    return changed;
  }

  double? _metricValue(HealthDailySummary s, String metric) =>
      switch (metric) {
        'steps' => s.steps?.toDouble(),
        'sleepHours' => s.sleepHours,
        'mindfulMinutes' => s.mindfulMinutes,
        'workoutMinutes' => s.workoutMinutes,
        _ => null,
      };

  Future<int> _applyDay(
    Habit habit,
    DateTime day,
    HealthDailySummary summary,
  ) async {
    final value = _metricValue(summary, habit.healthMetric!);
    if (value == null) return 0;

    final key = AppDateUtils.dateKey(day);
    final existing = await (_db.select(_db.habitLogs)
          ..where((t) => t.habitId.equals(habit.id) & t.date.equals(key)))
        .getSingleOrNull();
    if (existing != null && existing.source != 'health') return 0;

    if (habit.type == 'boolean') {
      final target = habit.healthTarget ?? 0;
      final met = target > 0 && value >= target;
      if (met) {
        if (existing != null) return 0; // already checked by us
        await _db.into(_db.habitLogs).insert(HabitLog(
              id: _uuid.v4(),
              habitId: habit.id,
              date: key,
              value: 1,
              note: null,
              source: 'health',
            ));
        return 1;
      }
      if (existing != null) {
        // Our own earlier check no longer holds (target raised, data
        // revised). Removing it keeps the streak honest.
        await (_db.delete(_db.habitLogs)
              ..where((t) => t.id.equals(existing.id)))
            .go();
        return 1;
      }
      return 0;
    }

    // Numeric/duration: log the real number, lightly rounded.
    final rounded = (value * 10).roundToDouble() / 10;
    if (existing != null) {
      if (existing.value == rounded) return 0;
      await (_db.update(_db.habitLogs)
            ..where((t) => t.id.equals(existing.id)))
          .write(HabitLogsCompanion(value: Value(rounded)));
      return 1;
    }
    await _db.into(_db.habitLogs).insert(HabitLog(
          id: _uuid.v4(),
          habitId: habit.id,
          date: key,
          value: rounded,
          note: null,
          source: 'health',
        ));
    return 1;
  }
}
