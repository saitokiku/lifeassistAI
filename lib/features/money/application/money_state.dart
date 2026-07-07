import '../../../core/storage/app_database.dart';
import '../domain/monthly_money_snapshot.dart';

/// Display-ready money state for the current month.
class MoneyState {
  const MoneyState({
    required this.snapshot,
    required this.categories,
    required this.monthTransactions,
    required this.now,
  });

  final MonthlyMoneySnapshot snapshot;
  final List<BudgetCategory> categories;
  final List<TransactionEntry> monthTransactions;
  final DateTime now;

  BudgetCategory? categoryById(String? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }
}
