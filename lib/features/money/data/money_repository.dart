import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';

/// Persistence for budget categories and transactions.
///
/// Money crosses into cents here: public methods accept user-entered
/// dollar doubles and store integer cents; everything read back out is
/// already cents.
class MoneyRepository {
  MoneyRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  // --- Budget categories ----------------------------------------------------

  Stream<List<BudgetCategory>> watchCategories() =>
      (_db.select(_db.budgetCategories)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<void> createCategory({
    required String name,
    required double monthlyTarget,
    required String flagType,
  }) async {
    final now = DateTime.now();
    final existing = await _db.select(_db.budgetCategories).get();
    await _db.into(_db.budgetCategories).insert(BudgetCategory(
          id: _uuid.v4(),
          name: name,
          monthlyTargetCents: centsFromAmount(monthlyTarget),
          flagType: flagType,
          sortOrder: existing.length,
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<void> updateCategory(BudgetCategory category) =>
      _db.update(_db.budgetCategories).replace(
            category.copyWith(updatedAt: DateTime.now()),
          );

  /// Deleting a category detaches its transactions (they become
  /// uncategorized fog rather than silently disappearing).
  Future<void> deleteCategory(String id) => _db.transaction(() async {
        await (_db.update(_db.transactionEntries)
              ..where((t) => t.categoryId.equals(id)))
            .write(const TransactionEntriesCompanion(
          categoryId: Value(null),
        ));
        await (_db.delete(_db.budgetCategories)..where((t) => t.id.equals(id)))
            .go();
      });

  // --- Transactions ---------------------------------------------------------

  Stream<List<TransactionEntry>> watchMonthTransactions(DateTime month) {
    final prefix = '${month.year.toString().padLeft(4, '0')}-'
        '${month.month.toString().padLeft(2, '0')}-';
    return (_db.select(_db.transactionEntries)
          ..where((t) => t.date.like('$prefix%'))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  /// Transactions on or after [since], oldest first. Powers the monthly
  /// surplus history chart.
  Stream<List<TransactionEntry>> watchTransactionsSince(DateTime since) {
    final key = AppDateUtils.dateKey(since);
    return (_db.select(_db.transactionEntries)
          ..where((t) => t.date.isBiggerOrEqualValue(key))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  Future<void> addTransaction({
    required DateTime date,
    required double amount,
    required String description,
    String? categoryId,
    String? accountId,
    String? sourceRecurringId,
    bool isIntentional = false,
  }) =>
      _db.into(_db.transactionEntries).insert(TransactionEntry(
            id: _uuid.v4(),
            categoryId: categoryId,
            accountId: accountId,
            sourceRecurringId: sourceRecurringId,
            date: AppDateUtils.dateKey(date),
            amountCents: centsFromAmount(amount),
            description: description,
            isIntentional: isIntentional,
            createdAt: DateTime.now(),
          ));

  /// Inserts many rows in one transaction (statement import). Each row
  /// may carry its own category (AI suggestions are per-row). Amounts
  /// arrive as cents — CSV parsing converts at extraction.
  Future<void> addTransactionsBatch(
    List<
            ({
              DateTime date,
              int amountCents,
              String description,
              String? categoryId,
            })>
        rows, {
    String? accountId,
  }) async {
    final now = DateTime.now();
    await _db.batch((batch) {
      batch.insertAll(_db.transactionEntries, [
        for (final row in rows)
          TransactionEntry(
            id: _uuid.v4(),
            categoryId: row.categoryId,
            accountId: accountId,
            sourceRecurringId: null,
            date: AppDateUtils.dateKey(row.date),
            amountCents: row.amountCents,
            description: row.description,
            isIntentional: false,
            createdAt: now,
          ),
      ]);
    });
  }

  /// Duplicate-detection index for statement import: keys of every
  /// transaction in [days] recent days (see CsvImport.duplicateKey).
  Future<Set<String>> recentDuplicateKeys({int days = 400}) async {
    final from = AppDateUtils.dateKey(
        AppDateUtils.subtractDays(DateTime.now(), days));
    final rows = await (_db.select(_db.transactionEntries)
          ..where((t) => t.date.isBiggerOrEqualValue(from)))
        .get();
    return {
      for (final r in rows)
        '${r.date}|${r.amountCents}|'
            '${r.description.trim().toLowerCase()}',
    };
  }

  Future<void> updateTransaction(TransactionEntry entry) =>
      _db.update(_db.transactionEntries).replace(entry);

  Future<void> deleteTransaction(String id) =>
      (_db.delete(_db.transactionEntries)..where((t) => t.id.equals(id))).go();
}
