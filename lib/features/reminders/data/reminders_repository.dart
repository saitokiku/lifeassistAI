import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/seed_service.dart';

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
          enabled: enabled,
          notificationId: SeedService.notificationIdFor(id),
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
}
