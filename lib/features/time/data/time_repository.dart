import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';

/// Persistence for time budgets, time blocks, and countdowns.
class TimeRepository {
  TimeRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  // --- Time budgets ---------------------------------------------------------

  Stream<List<TimeBudget>> watchBudgets() => (_db.select(_db.timeBudgets)
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .watch();

  Future<void> createBudget({
    required String name,
    required String kind,
    required double weeklyTargetHours,
  }) async {
    final existing = await _db.select(_db.timeBudgets).get();
    await _db.into(_db.timeBudgets).insert(TimeBudget(
          id: _uuid.v4(),
          name: name,
          kind: kind,
          weeklyTargetHours: weeklyTargetHours,
          sortOrder: existing.length,
        ));
  }

  Future<void> updateBudget(TimeBudget budget) =>
      _db.update(_db.timeBudgets).replace(budget);

  Future<void> deleteBudget(String id) => _db.transaction(() async {
        await (_db.delete(_db.timeBlocks)..where((t) => t.budgetId.equals(id)))
            .go();
        await (_db.delete(_db.timeBudgets)..where((t) => t.id.equals(id))).go();
      });

  // --- Time blocks ----------------------------------------------------------

  Stream<List<TimeBlock>> watchWeekBlocks(DateTime weekOf) {
    final keys = AppDateUtils.weekDateKeys(weekOf);
    return (_db.select(_db.timeBlocks)
          ..where((t) => t.date.isIn(keys))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Stream<List<TimeBlock>> watchRecentBlocks({int limit = 100}) =>
      (_db.select(_db.timeBlocks)
            ..orderBy([
              (t) => OrderingTerm.desc(t.date),
              (t) => OrderingTerm.desc(t.createdAt),
            ])
            ..limit(limit))
          .watch();

  /// Blocks logged on or after [since] (a date key boundary), oldest first.
  /// Used by the weekly-hours history chart.
  Stream<List<TimeBlock>> watchBlocksSince(DateTime since) {
    final key = AppDateUtils.dateKey(since);
    return (_db.select(_db.timeBlocks)
          ..where((t) => t.date.isBiggerOrEqualValue(key))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  Future<void> logBlock({
    required String budgetId,
    required DateTime date,
    required double hours,
    String? note,
  }) =>
      _db.into(_db.timeBlocks).insert(TimeBlock(
            id: _uuid.v4(),
            budgetId: budgetId,
            date: AppDateUtils.dateKey(date),
            hours: hours,
            note: note,
            createdAt: DateTime.now(),
          ));

  Future<void> updateBlock(TimeBlock block) =>
      _db.update(_db.timeBlocks).replace(block);

  Future<void> deleteBlock(String id) =>
      (_db.delete(_db.timeBlocks)..where((t) => t.id.equals(id))).go();

  // --- Countdowns -----------------------------------------------------------

  Stream<List<Countdown>> watchCountdowns() => (_db.select(_db.countdowns)
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .watch();

  Future<void> createCountdown({
    required String title,
    required DateTime targetDate,
  }) async {
    final existing = await _db.select(_db.countdowns).get();
    await _db.into(_db.countdowns).insert(Countdown(
          id: _uuid.v4(),
          title: title,
          targetDate: AppDateUtils.dateKey(targetDate),
          dynamicKey: null,
          sortOrder: existing.length,
        ));
  }

  Future<void> updateCountdown(Countdown countdown) =>
      _db.update(_db.countdowns).replace(countdown);

  Future<void> deleteCountdown(String id) =>
      (_db.delete(_db.countdowns)..where((t) => t.id.equals(id))).go();
}
