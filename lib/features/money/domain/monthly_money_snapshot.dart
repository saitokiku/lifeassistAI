import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money_math.dart';
import 'money_flag.dart';

/// Per-category month-to-date rollup.
class CategorySpend {
  const CategorySpend({
    required this.category,
    required this.spent,
    required this.transactionCount,
    required this.allIntentional,
  });

  final BudgetCategory category;
  final double spent;
  final int transactionCount;
  final bool allIntentional;

  double get remaining => category.monthlyTarget - spent;
  double get progress => category.monthlyTarget <= 0
      ? (spent > 0 ? 1.0 : 0.0)
      : (spent / category.monthlyTarget).clamp(0.0, 1.0);
}

/// The whole money picture for the current month, computed from real data.
class MonthlyMoneySnapshot {
  factory MonthlyMoneySnapshot.compute({
    required DateTime now,
    required double monthlyNetIncome,
    required double targetSurplusLow,
    required double targetSurplusHigh,
    required List<BudgetCategory> categories,
    required List<TransactionEntry> monthTransactions,
    required double rothIraAnnualTarget,
    required double rothIraContributed,
    required double brokerageBalance,
    required double savingsBalance,
  }) {
    final dayOfMonth = now.day;
    final daysInMonth = AppDateUtils.daysInMonth(now);

    final spendByCategory = <String, double>{};
    final countByCategory = <String, int>{};
    final intentionalByCategory = <String, bool>{};
    var spendSoFar = 0.0;
    var uncategorizedCount = 0;

    for (final tx in monthTransactions) {
      spendSoFar += tx.amount;
      final catId = tx.categoryId;
      if (catId == null) {
        uncategorizedCount++;
        continue;
      }
      spendByCategory[catId] = (spendByCategory[catId] ?? 0) + tx.amount;
      countByCategory[catId] = (countByCategory[catId] ?? 0) + 1;
      intentionalByCategory[catId] =
          (intentionalByCategory[catId] ?? true) && tx.isIntentional;
    }

    final categorySpends = [
      for (final cat in categories)
        CategorySpend(
          category: cat,
          spent: spendByCategory[cat.id] ?? 0,
          transactionCount: countByCategory[cat.id] ?? 0,
          allIntentional: intentionalByCategory[cat.id] ?? true,
        ),
    ];

    final projectedSpend = MoneyMath.projectedSpend(
      spendSoFar: spendSoFar,
      dayOfMonth: dayOfMonth,
      daysInMonth: daysInMonth,
    );
    final projectedSurplus = MoneyMath.projectedSurplus(
      monthlyNetIncome: monthlyNetIncome,
      projectedSpend: projectedSpend,
    );

    final flags = <MoneyFlag>[
      ...MoneyFlagRules.surplusFlags(
        projectedSurplus: projectedSurplus,
        targetSurplusLow: targetSurplusLow,
      ),
      for (final cs in categorySpends)
        if (MoneyFlagRules.evaluateCategory(
              category: cs.category,
              spent: cs.spent,
              allIntentional: cs.allIntentional,
            )
            case final flag?)
          flag,
      ...MoneyFlagRules.uncategorizedFlag(uncategorizedCount),
    ]..sort((a, b) => b.severity.index.compareTo(a.severity.index));

    return MonthlyMoneySnapshot._(
      monthlyNetIncome: monthlyNetIncome,
      targetSurplusLow: targetSurplusLow,
      targetSurplusHigh: targetSurplusHigh,
      spendSoFar: spendSoFar,
      projectedSpend: projectedSpend,
      projectedSurplus: projectedSurplus,
      annualSavingsProjection:
          MoneyMath.annualSavingsProjection(projectedSurplus),
      categorySpends: categorySpends,
      flags: flags,
      uncategorizedCount: uncategorizedCount,
      rothIraAnnualTarget: rothIraAnnualTarget,
      rothIraContributed: rothIraContributed,
      brokerageBalance: brokerageBalance,
      savingsBalance: savingsBalance,
    );
  }

  const MonthlyMoneySnapshot._({
    required this.monthlyNetIncome,
    required this.targetSurplusLow,
    required this.targetSurplusHigh,
    required this.spendSoFar,
    required this.projectedSpend,
    required this.projectedSurplus,
    required this.annualSavingsProjection,
    required this.categorySpends,
    required this.flags,
    required this.uncategorizedCount,
    required this.rothIraAnnualTarget,
    required this.rothIraContributed,
    required this.brokerageBalance,
    required this.savingsBalance,
  });

  final double monthlyNetIncome;
  final double targetSurplusLow;
  final double targetSurplusHigh;
  final double spendSoFar;
  final double projectedSpend;
  final double projectedSurplus;
  final double annualSavingsProjection;
  final List<CategorySpend> categorySpends;
  final List<MoneyFlag> flags;
  final int uncategorizedCount;
  final double rothIraAnnualTarget;
  final double rothIraContributed;
  final double brokerageBalance;
  final double savingsBalance;

  double get rothIraProgress => rothIraAnnualTarget <= 0
      ? 0
      : (rothIraContributed / rothIraAnnualTarget).clamp(0.0, 1.0);

  bool get withinTargetPace => MoneyMath.withinTargetPace(
        projectedSurplus: projectedSurplus,
        targetSurplusLow: targetSurplusLow,
      );
}
