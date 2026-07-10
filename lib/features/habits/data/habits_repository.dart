import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';

/// Persistence for habits and habit logs.
class HabitsRepository {
  HabitsRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Stream<List<Habit>> watchHabits({bool includeArchived = false}) {
    final query = _db.select(_db.habits)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    return query.watch();
  }

  Stream<List<HabitLog>> watchAllLogs() =>
      (_db.select(_db.habitLogs)..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  Future<void> createHabit({
    required String name,
    required String type,
    String? unit,
    int weekdays = 127,
    int? reminderHour,
    int? reminderMinute,
  }) async {
    final existing = await _db.select(_db.habits).get();
    await _db.into(_db.habits).insert(Habit(
          id: _uuid.v4(),
          name: name,
          type: type,
          unit: unit,
          weekdays: weekdays,
          reminderHour: reminderHour,
          reminderMinute: reminderMinute,
          sortOrder: existing.length,
          isArchived: false,
          createdAt: DateTime.now(),
        ));
  }

  Future<void> updateHabit(Habit habit) =>
      _db.update(_db.habits).replace(habit);

  Future<void> deleteHabit(String id) => _db.transaction(() async {
        await (_db.delete(_db.habitLogs)..where((t) => t.habitId.equals(id)))
            .go();
        await (_db.delete(_db.habits)..where((t) => t.id.equals(id))).go();
      });

  /// Logs (or replaces) a habit's value for a date.
  Future<void> upsertLog({
    required String habitId,
    required DateTime date,
    required double value,
    String? note,
  }) async {
    final key = AppDateUtils.dateKey(date);
    final existing = await (_db.select(_db.habitLogs)
          ..where((t) => t.habitId.equals(habitId) & t.date.equals(key)))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.habitLogs)..where((t) => t.id.equals(existing.id)))
          .write(HabitLogsCompanion(value: Value(value), note: Value(note)));
    } else {
      await _db.into(_db.habitLogs).insert(HabitLog(
            id: _uuid.v4(),
            habitId: habitId,
            date: key,
            value: value,
            note: note,
          ));
    }
  }

  /// Removes the log for a date (un-checks a habit).
  Future<void> removeLog({required String habitId, required DateTime date}) =>
      (_db.delete(_db.habitLogs)
            ..where((t) =>
                t.habitId.equals(habitId) &
                t.date.equals(AppDateUtils.dateKey(date))))
          .go();
}
