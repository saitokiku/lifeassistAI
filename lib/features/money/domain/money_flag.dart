import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
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
  /// [allIntentional] applies to warnOverZeroUnlessIntentional: true when
  /// every transaction in the category this month is marked intentional.
  static MoneyFlag? evaluateCategory({
    required BudgetCategory category,
    required double spent,
    required bool allIntentional,
  }) {
    final type = BudgetFlagType.parse(category.flagType);
    switch (type) {
      case BudgetFlagType.none:
        return null;
      case BudgetFlagType.warnOverTarget:
        if (spent > category.monthlyTarget) {
          return MoneyFlag(
            severity: MoneyFlagSeverity.warning,
            kind: MoneyFlagKind.category,
            categoryId: category.id,
            message:
                '${category.name} is over target: ${Formatters.money(spent)} of ${Formatters.money(category.monthlyTarget)}.',
          );
        }
        return null;
      case BudgetFlagType.warnOverZero:
        if (spent > 0) {
          return MoneyFlag(
            severity: MoneyFlagSeverity.warning,
            kind: MoneyFlagKind.category,
            categoryId: category.id,
            message:
                '${category.name} spend is ${Formatters.money(spent)}. Target is \$0.',
          );
        }
        return null;
      case BudgetFlagType.warnOverZeroUnlessIntentional:
        if (spent > 0 && !allIntentional) {
          return MoneyFlag(
            severity: MoneyFlagSeverity.warning,
            kind: MoneyFlagKind.category,
            categoryId: category.id,
            message:
                '${category.name} spend is ${Formatters.money(spent)} and not marked intentional.',
          );
        }
        return null;
      case BudgetFlagType.criticalOverZero:
        if (spent > 0) {
          return MoneyFlag(
            severity: MoneyFlagSeverity.critical,
            kind: MoneyFlagKind.category,
            categoryId: category.id,
            message:
                '${category.name} spend is ${Formatters.money(spent)}. Hard floor is \$0.',
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
              'Spending is on pace to end the month ${Formatters.money(-projectedSurplus)} past income.',
        ),
      ];
    }
    if (projectedSurplus < targetSurplusLow) {
      return [
        MoneyFlag(
          severity: MoneyFlagSeverity.warning,
          kind: MoneyFlagKind.surplus,
          message:
              'Projected surplus ${Formatters.money(projectedSurplus)} is below your ${Formatters.money(targetSurplusLow)} target.',
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
