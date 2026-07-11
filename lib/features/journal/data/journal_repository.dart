import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';

/// Persistence for journal lines. Several entries per day are normal —
/// the bar for writing one is a sentence, not a page.
class JournalRepository {
  JournalRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  /// Newest first; recent slice only, so the screen stays instant even
  /// after years of lines.
  Stream<List<JournalEntry>> watchRecent({int limit = 200}) =>
      (_db.select(_db.journalEntries)
            ..orderBy([
              (t) => OrderingTerm.desc(t.date),
              (t) => OrderingTerm.desc(t.createdAt),
            ])
            ..limit(limit))
          .watch();

  Stream<List<JournalEntry>> watchForDate(String dateKey) =>
      (_db.select(_db.journalEntries)
            ..where((t) => t.date.equals(dateKey))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  Future<void> addEntry(String content, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    await _db.into(_db.journalEntries).insert(JournalEntry(
          id: _uuid.v4(),
          date: AppDateUtils.dateKey(at),
          content: content.trim(),
          createdAt: at,
          updatedAt: at,
        ));
  }

  /// Content edits only — the entry keeps the day it was written.
  Future<void> updateEntry(JournalEntry entry) =>
      _db.update(_db.journalEntries).replace(
            entry.copyWith(updatedAt: DateTime.now()),
          );

  Future<void> deleteEntry(String id) =>
      (_db.delete(_db.journalEntries)..where((t) => t.id.equals(id))).go();
}
