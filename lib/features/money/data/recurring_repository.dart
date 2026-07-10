import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';

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
            amount: amount,
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

  /// Creates this month's entry for every active recurring expense whose
  /// day has arrived and that hasn't been materialized this month yet.
  /// Idempotent per month via lastMaterializedMonth; safe to call on
  /// every launch and every day rollover. Returns how many landed.
  Future<int> materialize({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final monthKey = '${today.year}-${today.month.toString().padLeft(2, '0')}';
    final rows = await (_db.select(_db.recurringTransactions)
          ..where((t) => t.active.equals(true)))
        .get();

    var created = 0;
    for (final row in rows) {
      if (row.lastMaterializedMonth == monthKey) continue;
      final day = row.dayOfMonth.clamp(1, AppDateUtils.daysInMonth(today));
      if (today.day < day) continue; // its day hasn't arrived yet

      await _db.transaction(() async {
        await _db.into(_db.transactionEntries).insert(TransactionEntry(
              id: _uuid.v4(),
              categoryId: row.categoryId,
              accountId: null,
              sourceRecurringId: row.id,
              date: AppDateUtils.dateKey(
                  DateTime(today.year, today.month, day)),
              amount: row.amount,
              description: row.description,
              isIntentional: row.isIntentional,
              createdAt: DateTime.now(),
            ));
        await (_db.update(_db.recurringTransactions)
              ..where((t) => t.id.equals(row.id)))
            .write(RecurringTransactionsCompanion(
          lastMaterializedMonth: Value(monthKey),
        ));
      });
      created++;
    }
    return created;
  }
}
