import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/money_math.dart';
import 'money_flag.dart';

/// Per-category month-to-date rollup. Sums are integer cents — exact —
/// with dollar getters for display.
class CategorySpend {
  const CategorySpend({
    required this.category,
    required this.spentCents,
    required this.transactionCount,
    required this.allIntentional,
  });

  final BudgetCategory category;
  final int spentCents;
  final int transactionCount;
  final bool allIntentional;

  double get spent => amountFromCents(spentCents);
  int get remainingCents => category.monthlyTargetCents - spentCents;
  double get remaining => amountFromCents(remainingCents);
  double get progress => category.monthlyTargetCents <= 0
      ? (spentCents > 0 ? 1.0 : 0.0)
      : (spentCents / category.monthlyTargetCents).clamp(0.0, 1.0);
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
    required double retirementAnnualTarget,
    required double retirementContributed,
    required double brokerageBalance,
    required double savingsBalance,
  }) {
    final dayOfMonth = now.day;
    final daysInMonth = AppDateUtils.daysInMonth(now);

    // All summing happens in integer cents; doubles appear only after
    // the totals are final (projection is estimation anyway).
    final spendByCategory = <String, int>{};
    final countByCategory = <String, int>{};
    final intentionalByCategory = <String, bool>{};
    var spendCentsSoFar = 0;
    var uncategorizedCount = 0;

    for (final tx in monthTransactions) {
      spendCentsSoFar += tx.amountCents;
      final catId = tx.categoryId;
      if (catId == null) {
        uncategorizedCount++;
        continue;
      }
      spendByCategory[catId] = (spendByCategory[catId] ?? 0) + tx.amountCents;
      countByCategory[catId] = (countByCategory[catId] ?? 0) + 1;
      intentionalByCategory[catId] =
          (intentionalByCategory[catId] ?? true) && tx.isIntentional;
    }

    final categorySpends = [
      for (final cat in categories)
        CategorySpend(
          category: cat,
          spentCents: spendByCategory[cat.id] ?? 0,
          transactionCount: countByCategory[cat.id] ?? 0,
          allIntentional: intentionalByCategory[cat.id] ?? true,
        ),
    ];

    final spendSoFar = amountFromCents(spendCentsSoFar);
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
          spentCents: cs.spentCents,
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
      spendCentsSoFar: spendCentsSoFar,
      projectedSpend: projectedSpend,
      projectedSurplus: projectedSurplus,
      annualSavingsProjection:
          MoneyMath.annualSavingsProjection(projectedSurplus),
      categorySpends: categorySpends,
      flags: flags,
      uncategorizedCount: uncategorizedCount,
      retirementAnnualTarget: retirementAnnualTarget,
      retirementContributed: retirementContributed,
      brokerageBalance: brokerageBalance,
      savingsBalance: savingsBalance,
    );
  }

  const MonthlyMoneySnapshot._({
    required this.monthlyNetIncome,
    required this.targetSurplusLow,
    required this.targetSurplusHigh,
    required this.spendCentsSoFar,
    required this.projectedSpend,
    required this.projectedSurplus,
    required this.annualSavingsProjection,
    required this.categorySpends,
    required this.flags,
    required this.uncategorizedCount,
    required this.retirementAnnualTarget,
    required this.retirementContributed,
    required this.brokerageBalance,
    required this.savingsBalance,
  });

  final double monthlyNetIncome;
  final double targetSurplusLow;
  final double targetSurplusHigh;

  /// Month-to-date spend, exact.
  final int spendCentsSoFar;
  double get spendSoFar => amountFromCents(spendCentsSoFar);
  final double projectedSpend;
  final double projectedSurplus;
  final double annualSavingsProjection;
  final List<CategorySpend> categorySpends;
  final List<MoneyFlag> flags;
  final int uncategorizedCount;
  final double retirementAnnualTarget;
  final double retirementContributed;
  final double brokerageBalance;
  final double savingsBalance;

  double get retirementProgress => retirementAnnualTarget <= 0
      ? 0
      : (retirementContributed / retirementAnnualTarget).clamp(0.0, 1.0);

  bool get withinTargetPace => MoneyMath.withinTargetPace(
        projectedSurplus: projectedSurplus,
        targetSurplusLow: targetSurplusLow,
      );
}
