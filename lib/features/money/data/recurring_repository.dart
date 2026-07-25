import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';

/// Persistence for monthly recurring expenses plus the materializer that
/// turns them into real TransactionEntries once their day arrives.
class RecurringRepository {
  RecurringRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Stream<List<RecurringTransaction>> watchRecurring() =>
      (_db.select(_db.recurringTransactions)
            ..orderBy([(t) => OrderingTerm.asc(t.dayOfMonth)]))
          .watch();

  Future<void> createRecurring({
    required double amount,
    required String description,
    required int dayOfMonth,
    String? categoryId,
    bool isIntentional = true,
  }) =>
      _db.into(_db.recurringTransactions).insert(RecurringTransaction(
            id: _uuid.v4(),
            categoryId: categoryId,
            amountCents: centsFromAmount(amount),
            description: description,
            dayOfMonth: dayOfMonth.clamp(1, 31),
            isIntentional: isIntentional,
            active: true,
            lastMaterializedMonth: null,
            createdAt: DateTime.now(),
          ));

  Future<void> updateRecurring(RecurringTransaction row) =>
      _db.update(_db.recurringTransactions).replace(row);

  Future<void> deleteRecurring(String id) =>
      (_db.delete(_db.recurringTransactions)..where((t) => t.id.equals(id)))
          .go();

  /// Backfill window: months missed while the app was closed are caught
  /// up to this many months back. Far above any realistic absence; keeps
  /// a corrupted marker or wild clock from generating decades of rows.
  static const int maxCatchUpMonths = 24;

  /// Creates the monthly entry for every active recurring expense in
  /// every month from the last materialized one through today — a user
  /// away for three months comes back to a complete ledger, not a
  /// silently under-counted one (which would also inflate projected
  /// surplus for exactly the months they weren't looking).
  ///
  /// Idempotent two ways: the per-row lastMaterializedMonth marker, and
  /// a per-(recurring, month) lookup on sourceRecurringId — so a
  /// concurrent call or a stale editor write-back of the marker can
  /// never double-post a month. Safe to call on every launch and every
  /// day rollover. Returns how many entries landed.
  Future<int> materialize({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final rows = await (_db.select(_db.recurringTransactions)
          ..where((t) => t.active.equals(true)))
        .get();

    var created = 0;
    for (final row in rows) {
      for (final month in _monthsDue(row.lastMaterializedMonth, today)) {
        final day = row.dayOfMonth.clamp(1, AppDateUtils.daysInMonth(month));
        final isCurrentMonth =
            month.year == today.year && month.month == today.month;
        if (isCurrentMonth && today.day < day) continue; // not arrived yet
        final monthKey = _monthKey(month);

        // Second idempotence layer: skip months that already have this
        // recurring's entry, whoever wrote it.
        final monthStart = '$monthKey-01';
        final nextMonthStart = _monthKey(DateTime(month.year, month.month + 1));
        final existing = await (_db.select(_db.transactionEntries)
              ..where((t) =>
                  t.sourceRecurringId.equals(row.id) &
                  t.date.isBiggerOrEqualValue(monthStart) &
                  t.date.isSmallerThanValue('$nextMonthStart-01'))
              ..limit(1))
            .get();
        if (existing.isNotEmpty) {
          await _advanceMarker(row.id, monthKey);
          continue;
        }

        await _db.transaction(() async {
          await _db.into(_db.transactionEntries).insert(TransactionEntry(
                id: _uuid.v4(),
                categoryId: row.categoryId,
                accountId: null,
                sourceRecurringId: row.id,
                date: AppDateUtils.dateKey(
                    DateTime(month.year, month.month, day)),
                amountCents: row.amountCents,
                description: row.description,
                isIntentional: row.isIntentional,
                createdAt: DateTime.now(),
              ));
          await _advanceMarker(row.id, monthKey);
        });
        created++;
      }
    }
    return created;
  }

  /// The months this row still owes an entry for, oldest first, ending
  /// at the current month. A row that has never materialized starts now
  /// — creating a recurring expense doesn't invent history.
  List<DateTime> _monthsDue(String? lastKey, DateTime today) {
    final current = DateTime(today.year, today.month);
    final last = _parseMonthKey(lastKey);
    if (last == null) return [current];
    final months = <DateTime>[];
    var next = DateTime(last.year, last.month + 1);
    while (!next.isAfter(current)) {
      months.add(next);
      next = DateTime(next.year, next.month + 1);
    }
    if (months.length > maxCatchUpMonths) {
      return months.sublist(months.length - maxCatchUpMonths);
    }
    return months;
  }

  Future<void> _advanceMarker(String id, String monthKey) =>
      (_db.update(_db.recurringTransactions)..where((t) => t.id.equals(id)))
          .write(RecurringTransactionsCompanion(
        lastMaterializedMonth: Value(monthKey),
      ));

  static String _monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  static DateTime? _parseMonthKey(String? key) {
    if (key == null) return null;
    final parts = key.split('-');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) return null;
    return DateTime(year, month);
  }
}
