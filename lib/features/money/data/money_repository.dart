import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';

/// Persistence for budget categories and transactions.
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
          monthlyTarget: monthlyTarget,
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

  Future<void> addTransaction({
    required DateTime date,
    required double amount,
    required String description,
    String? categoryId,
    bool isIntentional = false,
  }) =>
      _db.into(_db.transactionEntries).insert(TransactionEntry(
            id: _uuid.v4(),
            categoryId: categoryId,
            date: AppDateUtils.dateKey(date),
            amount: amount,
            description: description,
            isIntentional: isIntentional,
            createdAt: DateTime.now(),
          ));

  Future<void> updateTransaction(TransactionEntry entry) =>
      _db.update(_db.transactionEntries).replace(entry);

  Future<void> deleteTransaction(String id) =>
      (_db.delete(_db.transactionEntries)..where((t) => t.id.equals(id))).go();
}
