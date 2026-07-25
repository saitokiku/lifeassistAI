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

  Future<List<Habit>> getHabits() => _db.select(_db.habits).get();

  /// How many days of logs are streamed. The streak walk can only see
  /// this far back, so it also bounds the largest streak the app can
  /// state exactly — see [HabitView.streakIsCapped], which renders
  /// anything at the ceiling as "N+" rather than a number that silently
  /// stops growing. Two years covers essentially every real streak
  /// while keeping the stream small (one row per habit per day).
  static const int logWindowDays = 730;

  /// Logs newest-first, bounded to a trailing window — enough for streaks
  /// and the heatmap without streaming the whole table forever.
  Stream<List<HabitLog>> watchRecentLogs(
      {required DateTime today, int sinceDays = logWindowDays}) {
    final from = AppDateUtils.dateKey(
        AppDateUtils.subtractDays(today, sinceDays));
    return (_db.select(_db.habitLogs)
          ..where((t) => t.date.isBiggerOrEqualValue(from))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<void> createHabit({
    required String name,
    required String type,
    String? unit,
    int weekdays = 127,
    int? reminderHour,
    int? reminderMinute,
    String? healthMetric,
    double? healthTarget,
  }) async {
    final count = await _db.habits.count().getSingle();
    // Allocated once and stored, never re-derived from a hash — see
    // NotificationIds.
    final notificationId = await _db.allocateNotificationId();
    await _db.into(_db.habits).insert(Habit(
          id: _uuid.v4(),
          name: name,
          type: type,
          unit: unit,
          weekdays: weekdays,
          reminderHour: reminderHour,
          reminderMinute: reminderMinute,
          notificationId: notificationId,
          healthMetric: healthMetric,
          healthTarget: healthTarget,
          sortOrder: count,
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

  /// Logs (or replaces) a habit's value for a date. [source] records who
  /// wrote it; a manual edit of an automated log takes ownership.
  Future<void> upsertLog({
    required String habitId,
    required DateTime date,
    required double value,
    String? note,
    String source = 'manual',
  }) async {
    final key = AppDateUtils.dateKey(date);
    // Single atomic statement against the (habitId, date) unique index.
    // The old read-then-write raced with the Health sync and the Siri
    // drain — both write today's logs, unawaited and unsynchronized —
    // and a duplicate then made getSingleOrNull() throw forever.
    await _db.into(_db.habitLogs).insert(
          HabitLog(
            id: _uuid.v4(),
            habitId: habitId,
            date: key,
            value: value,
            note: note,
            source: source,
          ),
          onConflict: DoUpdate(
            (_) => HabitLogsCompanion(
              value: Value(value),
              note: Value(note),
              source: Value(source),
            ),
            target: [_db.habitLogs.habitId, _db.habitLogs.date],
          ),
        );
  }

  /// Removes the log for a date (un-checks a habit).
  Future<void> removeLog({required String habitId, required DateTime date}) =>
      (_db.delete(_db.habitLogs)
            ..where((t) =>
                t.habitId.equals(habitId) &
                t.date.equals(AppDateUtils.dateKey(date))))
          .go();
}
