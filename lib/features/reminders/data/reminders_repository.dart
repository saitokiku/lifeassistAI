import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';

/// Persistence for reminders. OS scheduling is handled by ReminderScheduler;
/// this repository only owns the rows.
class RemindersRepository {
  RemindersRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Stream<List<Reminder>> watchReminders() => (_db.select(_db.reminders)
        ..orderBy([
          (t) => OrderingTerm.asc(t.hour),
          (t) => OrderingTerm.asc(t.minute),
        ]))
      .watch();

  Future<List<Reminder>> getReminders() => _db.select(_db.reminders).get();

  Future<void> createReminder({
    required String title,
    required String message,
    required String type,
    required int hour,
    required int minute,
    int weekdays = 127,
    String? oneShotDate,
    bool enabled = true,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.into(_db.reminders).insert(Reminder(
          id: id,
          title: title,
          message: message,
          type: type,
          hour: hour,
          minute: minute,
          weekdays: weekdays,
          oneShotDate: oneShotDate,
          enabled: enabled,
          notificationId: await _db.allocateNotificationId(),
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<void> updateReminder(Reminder reminder) =>
      _db.update(_db.reminders).replace(
            reminder.copyWith(updatedAt: DateTime.now()),
          );

  Future<void> setEnabled(String id, bool enabled) =>
      (_db.update(_db.reminders)..where((t) => t.id.equals(id)))
          .write(RemindersCompanion(
        enabled: Value(enabled),
        updatedAt: Value(DateTime.now()),
      ));

  Future<void> deleteReminder(String id) =>
      (_db.delete(_db.reminders)..where((t) => t.id.equals(id))).go();

  /// Disables one-shot reminders whose date is behind [todayKey] — they
  /// have either fired or been missed; both mean "done".
  Future<void> disableExpiredOneShots({required String todayKey}) =>
      (_db.update(_db.reminders)
            ..where((t) =>
                t.oneShotDate.isNotNull() &
                t.oneShotDate.isSmallerThanValue(todayKey) &
                t.enabled.equals(true)))
          .write(RemindersCompanion(
        enabled: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));
}
