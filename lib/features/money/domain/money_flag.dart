import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import 'budget_category.dart';

enum MoneyFlagSeverity { warning, critical }

/// What a flag is about — lets UI route taps without parsing messages.
enum MoneyFlagKind { category, surplus, uncategorized }

/// A leak/violation surfaced on the Money screen and dashboard.
class MoneyFlag {
  const MoneyFlag({
    required this.severity,
    required this.message,
    required this.kind,
    this.categoryId,
  });

  final MoneyFlagSeverity severity;
  final String message;
  final MoneyFlagKind kind;
  final String? categoryId;

  StatusLevel get status => severity == MoneyFlagSeverity.critical
      ? StatusLevel.critical
      : StatusLevel.watch;
}

/// Pure rule evaluation. Unit tested in money_rules_test.dart.
class MoneyFlagRules {
  MoneyFlagRules._();

  /// Evaluates one category's month-to-date spend against its flag rule.
  /// Comparisons happen in integer cents — an over-target flag can never
  /// be a float artifact. [allIntentional] applies to
  /// warnOverZeroUnlessIntentional: true when every transaction in the
  /// category this month is marked intentional.
  static MoneyFlag? evaluateCategory({
    required BudgetCategory category,
    required int spentCents,
    required bool allIntentional,
  }) {
    final type = BudgetFlagType.parse(category.flagType);
    final spent = amountFromCents(spentCents);
    switch (type) {
      case BudgetFlagType.none:
        return null;
      case BudgetFlagType.warnOverTarget:
        if (spentCents > category.monthlyTargetCents) {
          return MoneyFlag(
            severity: MoneyFlagSeverity.warning,
            kind: MoneyFlagKind.category,
            categoryId: category.id,
            message:
                '${category.name} is over target: ${Formatters.moneyExact(spent)} of ${Formatters.moneyExact(amountFromCents(category.monthlyTargetCents))}.',
          );
        }
        return null;
      case BudgetFlagType.warnOverZero:
        if (spentCents > 0) {
          return MoneyFlag(
            severity: MoneyFlagSeverity.warning,
            kind: MoneyFlagKind.category,
            categoryId: category.id,
            message:
                '${category.name} spend is ${Formatters.moneyExact(spent)}. Target is \$0.',
          );
        }
        return null;
      case BudgetFlagType.warnOverZeroUnlessIntentional:
        if (spentCents > 0 && !allIntentional) {
          return MoneyFlag(
            severity: MoneyFlagSeverity.warning,
            kind: MoneyFlagKind.category,
            categoryId: category.id,
            message:
                '${category.name} spend is ${Formatters.moneyExact(spent)} and not marked intentional.',
          );
        }
        return null;
      case BudgetFlagType.criticalOverZero:
        if (spentCents > 0) {
          return MoneyFlag(
            severity: MoneyFlagSeverity.critical,
            kind: MoneyFlagKind.category,
            categoryId: category.id,
            message:
                '${category.name} spend is ${Formatters.moneyExact(spent)}. Hard floor is \$0.',
          );
        }
        return null;
    }
  }

  static List<MoneyFlag> surplusFlags({
    required double projectedSurplus,
    required double targetSurplusLow,
  }) {
    if (projectedSurplus < 0) {
      return [
        MoneyFlag(
          severity: MoneyFlagSeverity.critical,
          kind: MoneyFlagKind.surplus,
          message:
              'Spending is on pace to end the month ${Formatters.moneyExact(-projectedSurplus)} past income.',
        ),
      ];
    }
    if (projectedSurplus < targetSurplusLow) {
      return [
        MoneyFlag(
          severity: MoneyFlagSeverity.warning,
          kind: MoneyFlagKind.surplus,
          message:
              'Projected surplus ${Formatters.moneyExact(projectedSurplus)} is below your ${Formatters.moneyExact(targetSurplusLow)} target.',
        ),
      ];
    }
    return const [];
  }

  static List<MoneyFlag> uncategorizedFlag(int uncategorizedCount) {
    if (uncategorizedCount == 0) return const [];
    return [
      MoneyFlag(
        severity: MoneyFlagSeverity.warning,
        kind: MoneyFlagKind.uncategorized,
        message:
            '$uncategorizedCount transaction${uncategorizedCount == 1 ? '' : 's'} without a category this month — patterns hide there.',
      ),
    ];
  }
}
