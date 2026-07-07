import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/settings_keys.dart';
import '../../../core/utils/date_utils.dart';
import '../../settings/application/settings_controller.dart';
import '../data/money_repository.dart';
import '../domain/monthly_money_snapshot.dart';
import 'money_state.dart';

final moneyRepositoryProvider = Provider<MoneyRepository>(
  (ref) => MoneyRepository(ref.watch(databaseProvider)),
);

final budgetCategoriesProvider = StreamProvider<List<BudgetCategory>>(
  (ref) => ref.watch(moneyRepositoryProvider).watchCategories(),
);

/// Transactions for the current month; re-created when the month rolls over.
final monthTransactionsProvider = StreamProvider<List<TransactionEntry>>((ref) {
  final now = readNow(ref);
  final month = DateTime(now.year, now.month);
  return ref.watch(moneyRepositoryProvider).watchMonthTransactions(month);
});

/// Combined money view state; null while sources are loading.
final moneyStateProvider = Provider<MoneyState?>((ref) {
  final now = readNow(ref);
  final settings = ref.watch(settingsProvider).valueOrNull;
  final categories = ref.watch(budgetCategoriesProvider).valueOrNull;
  final transactions = ref.watch(monthTransactionsProvider).valueOrNull;
  if (settings == null || categories == null || transactions == null) {
    return null;
  }

  final snapshot = MonthlyMoneySnapshot.compute(
    now: now,
    monthlyNetIncome: settings.monthlyNetIncome,
    targetSurplusLow: settings.targetSurplusLow,
    targetSurplusHigh: settings.targetSurplusHigh,
    categories: categories,
    monthTransactions: transactions,
    rothIraAnnualTarget: settings.rothIraAnnualTarget,
    rothIraContributed: settings.rothIraContributed,
    brokerageBalance: settings.brokerageBalance,
    savingsBalance: settings.savingsBalance,
  );

  return MoneyState(
    snapshot: snapshot,
    categories: categories,
    monthTransactions: transactions,
    now: now,
  );
});

/// One month's spend vs income for the surplus history chart.
class MonthlySurplusPoint {
  const MonthlySurplusPoint({
    required this.month,
    required this.income,
    required this.spend,
    required this.isPartial,
  });

  final DateTime month;
  final double income;
  final double spend;

  /// True for the current month (still accumulating).
  final bool isPartial;

  double get surplus => income - spend;
}

/// How many months of history the money chart shows.
const int kMonthlyHistoryMonths = 6;

final _txSinceProvider =
    StreamProvider.family<List<TransactionEntry>, DateTime>((ref, since) {
  return ref.watch(moneyRepositoryProvider).watchTransactionsSince(since);
});

/// Last [kMonthlyHistoryMonths] months of surplus (oldest first). Income is
/// the current configured monthly net income applied to each month (we don't
/// keep historical income). Null while sources load.
final monthlySurplusHistoryProvider =
    Provider<List<MonthlySurplusPoint>?>((ref) {
  final now = readNow(ref);
  final settings = ref.watch(settingsProvider).valueOrNull;
  final firstMonth =
      DateTime(now.year, now.month - (kMonthlyHistoryMonths - 1));
  final txs = ref.watch(_txSinceProvider(firstMonth)).valueOrNull;
  if (settings == null || txs == null) return null;

  final spendByMonth = <String, double>{};
  for (final tx in txs) {
    final d = AppDateUtils.parseDateKey(tx.date);
    final key = '${d.year}-${d.month}';
    spendByMonth[key] = (spendByMonth[key] ?? 0) + tx.amount;
  }

  return [
    for (var i = 0; i < kMonthlyHistoryMonths; i++)
      () {
        final month = DateTime(firstMonth.year, firstMonth.month + i);
        final key = '${month.year}-${month.month}';
        return MonthlySurplusPoint(
          month: month,
          income: settings.monthlyNetIncome,
          spend: spendByMonth[key] ?? 0,
          isPartial: month.year == now.year && month.month == now.month,
        );
      }(),
  ];
});

class MoneyController {
  MoneyController(this._ref);

  final Ref _ref;

  MoneyRepository get _repo => _ref.read(moneyRepositoryProvider);

  Future<void> createCategory({
    required String name,
    required double monthlyTarget,
    required String flagType,
  }) =>
      _repo.createCategory(
          name: name, monthlyTarget: monthlyTarget, flagType: flagType);

  Future<void> updateCategory(BudgetCategory category) =>
      _repo.updateCategory(category);

  Future<void> deleteCategory(String id) => _repo.deleteCategory(id);

  Future<void> addTransaction({
    required DateTime date,
    required double amount,
    required String description,
    String? categoryId,
    bool isIntentional = false,
  }) =>
      _repo.addTransaction(
        date: date,
        amount: amount,
        description: description,
        categoryId: categoryId,
        isIntentional: isIntentional,
      );

  Future<void> updateTransaction(TransactionEntry entry) =>
      _repo.updateTransaction(entry);

  Future<void> deleteTransaction(String id) => _repo.deleteTransaction(id);

  Future<void> setMonthlyNetIncome(double value) => _ref
      .read(settingsRepositoryProvider)
      .setNumber(SettingsKeys.monthlyNetIncome, value);

  Future<void> setTargetSurplus({required double low, required double high}) async {
    final repo = _ref.read(settingsRepositoryProvider);
    await repo.setNumber(SettingsKeys.targetSurplusLow, low);
    await repo.setNumber(SettingsKeys.targetSurplusHigh, high);
  }

  Future<void> setRothIra({double? annualTarget, double? contributed}) async {
    final repo = _ref.read(settingsRepositoryProvider);
    if (annualTarget != null) {
      await repo.setNumber(SettingsKeys.rothIraAnnualTarget, annualTarget);
    }
    if (contributed != null) {
      await repo.setNumber(SettingsKeys.rothIraContributed, contributed);
    }
  }

  Future<void> setBalances({double? brokerage, double? savings}) async {
    final repo = _ref.read(settingsRepositoryProvider);
    if (brokerage != null) {
      await repo.setNumber(SettingsKeys.brokerageBalance, brokerage);
    }
    if (savings != null) {
      await repo.setNumber(SettingsKeys.savingsBalance, savings);
    }
  }
}

final moneyControllerProvider =
    Provider<MoneyController>((ref) => MoneyController(ref));
