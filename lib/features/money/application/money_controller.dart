import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/settings_keys.dart';
import '../../../core/utils/date_utils.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/data/settings_repository.dart';
import '../data/money_repository.dart';
import '../data/recurring_repository.dart';
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
  final now = readToday(ref);
  final month = DateTime(now.year, now.month);
  return ref.watch(moneyRepositoryProvider).watchMonthTransactions(month);
});

/// Combined money view state; null while sources are loading.
final moneyStateProvider = Provider<MoneyState?>((ref) {
  final now = readToday(ref);
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
    retirementAnnualTarget: settings.retirementAnnualTarget,
    retirementContributed: settings.retirementContributed,
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

// --- Recurring expenses ------------------------------------------------------

final recurringRepositoryProvider = Provider<RecurringRepository>(
  (ref) => RecurringRepository(ref.watch(databaseProvider)),
);

final recurringProvider = StreamProvider<List<RecurringTransaction>>(
  (ref) => ref.watch(recurringRepositoryProvider).watchRecurring(),
);

/// Materializes due recurring expenses into real transactions. Watched by
/// the Money screen; re-runs on day rollover. Idempotent per month.
final recurringMaterializerProvider = FutureProvider<int>((ref) {
  final today = readToday(ref);
  return ref.watch(recurringRepositoryProvider).materialize(now: today);
});

// --- Month browsing ----------------------------------------------------------

/// How many months back the Money screen is looking (0 = this month).
final viewedMonthOffsetProvider = StateProvider<int>((ref) => 0);

final viewedMonthProvider = Provider<DateTime>((ref) {
  final today = readToday(ref);
  final offset = ref.watch(viewedMonthOffsetProvider);
  return DateTime(today.year, today.month - offset);
});

final _monthTransactionsForProvider = StreamProvider.autoDispose
    .family<List<TransactionEntry>, DateTime>((ref, month) {
  return ref.watch(moneyRepositoryProvider).watchMonthTransactions(month);
});

/// Money state for the month the user is looking at. Identical to
/// [moneyStateProvider] for the current month; for a finished month the
/// "projection" is pinned to the month's end, so projected == actual.
final viewedMoneyStateProvider = Provider<MoneyState?>((ref) {
  if (ref.watch(viewedMonthOffsetProvider) == 0) {
    return ref.watch(moneyStateProvider);
  }
  final month = ref.watch(viewedMonthProvider);
  final settings = ref.watch(settingsProvider).valueOrNull;
  final categories = ref.watch(budgetCategoriesProvider).valueOrNull;
  final transactions =
      ref.watch(_monthTransactionsForProvider(month)).valueOrNull;
  final snapshots = ref.watch(incomeSnapshotsProvider).valueOrNull;
  if (settings == null || categories == null || transactions == null) {
    return null;
  }

  final monthEnd = AppDateUtils.endOfMonth(month);
  final snapshot = MonthlyMoneySnapshot.compute(
    now: monthEnd,
    monthlyNetIncome: snapshots == null
        ? settings.monthlyNetIncome
        : SettingsRepository.incomeForMonth(
            snapshots, month, settings.monthlyNetIncome),
    targetSurplusLow: settings.targetSurplusLow,
    targetSurplusHigh: settings.targetSurplusHigh,
    categories: categories,
    monthTransactions: transactions,
    retirementAnnualTarget: settings.retirementAnnualTarget,
    retirementContributed: settings.retirementContributed,
    brokerageBalance: settings.brokerageBalance,
    savingsBalance: settings.savingsBalance,
  );

  return MoneyState(
    snapshot: snapshot,
    categories: categories,
    monthTransactions: transactions,
    now: monthEnd,
  );
});

/// One month's spend vs income for the surplus history chart.
class MonthlySurplusPoint {
  const MonthlySurplusPoint({
    required this.month,
    required this.income,
    required this.spend,
    required this.isPartial,
    required this.hasData,
  });

  final DateTime month;
  final double income;
  final double spend;

  /// True for the current month (still accumulating).
  final bool isPartial;

  /// False when the month has no logged transactions at all — the chart
  /// shows a gap instead of pretending the month was a perfect surplus.
  final bool hasData;

  double get surplus => income - spend;
}

/// How many months of history the money chart shows.
const int kMonthlyHistoryMonths = 6;

/// autoDispose: the `since` argument advances as months roll over, so old
/// instances must release their drift subscriptions instead of leaking.
final _txSinceProvider = StreamProvider.autoDispose
    .family<List<TransactionEntry>, DateTime>((ref, since) {
  return ref.watch(moneyRepositoryProvider).watchTransactionsSince(since);
});

/// Month key → income snapshot, for honest history math.
final incomeSnapshotsProvider = StreamProvider<Map<String, double>>(
  (ref) => ref.watch(settingsRepositoryProvider).watchIncomeSnapshots(),
);

/// Last [kMonthlyHistoryMonths] months of surplus (oldest first). Each
/// month uses the income snapshot that applied back then; months without
/// any logged transactions carry [MonthlySurplusPoint.hasData] = false.
/// Null while sources load.
final monthlySurplusHistoryProvider =
    Provider<List<MonthlySurplusPoint>?>((ref) {
  final now = readToday(ref);
  final settings = ref.watch(settingsProvider).valueOrNull;
  final snapshots = ref.watch(incomeSnapshotsProvider).valueOrNull;
  final firstMonth =
      DateTime(now.year, now.month - (kMonthlyHistoryMonths - 1));
  final txs = ref.watch(_txSinceProvider(firstMonth)).valueOrNull;
  if (settings == null || txs == null || snapshots == null) return null;

  final spendByMonth = <String, double>{};
  for (final tx in txs) {
    final d = AppDateUtils.parseDateKey(tx.date);
    final key = SettingsRepository.monthKey(d);
    spendByMonth[key] = (spendByMonth[key] ?? 0) + tx.amount;
  }

  return [
    for (var i = 0; i < kMonthlyHistoryMonths; i++)
      () {
        final month = DateTime(firstMonth.year, firstMonth.month + i);
        final key = SettingsRepository.monthKey(month);
        final isPartial = month.year == now.year && month.month == now.month;
        final hasData = isPartial || spendByMonth.containsKey(key);
        return MonthlySurplusPoint(
          month: month,
          income: hasData
              ? SettingsRepository.incomeForMonth(
                  snapshots, month, settings.monthlyNetIncome)
              : 0,
          spend: spendByMonth[key] ?? 0,
          isPartial: isPartial,
          hasData: hasData,
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

  // Recurring expenses

  Future<void> createRecurring({
    required double amount,
    required String description,
    required int dayOfMonth,
    String? categoryId,
    bool isIntentional = true,
  }) async {
    await _ref.read(recurringRepositoryProvider).createRecurring(
          amount: amount,
          description: description,
          dayOfMonth: dayOfMonth,
          categoryId: categoryId,
          isIntentional: isIntentional,
        );
    // A newly added expense whose day already passed lands this month too.
    await _ref.read(recurringRepositoryProvider).materialize();
  }

  Future<void> updateRecurring(RecurringTransaction row) =>
      _ref.read(recurringRepositoryProvider).updateRecurring(row);

  Future<void> deleteRecurring(String id) =>
      _ref.read(recurringRepositoryProvider).deleteRecurring(id);

  // Statement import

  Future<void> importTransactions(
    List<({DateTime date, double amount, String description})> rows, {
    String? accountId,
  }) =>
      _repo.addTransactionsBatch(rows, accountId: accountId);

  Future<Set<String>> recentDuplicateKeys() => _repo.recentDuplicateKeys();

  Future<void> setMonthlyNetIncome(double value) =>
      _ref.read(settingsRepositoryProvider).setMonthlyNetIncome(value);

  Future<void> setTargetSurplus(
      {required double low, required double high}) async {
    final repo = _ref.read(settingsRepositoryProvider);
    await repo.setNumber(SettingsKeys.targetSurplusLow, low);
    await repo.setNumber(SettingsKeys.targetSurplusHigh, high);
  }

  Future<void> setRetirement(
      {double? annualTarget, double? contributed}) async {
    final repo = _ref.read(settingsRepositoryProvider);
    if (annualTarget != null) {
      await repo.setNumber(SettingsKeys.retirementAnnualTarget, annualTarget);
    }
    if (contributed != null) {
      await repo.setNumber(SettingsKeys.retirementContributed, contributed);
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
