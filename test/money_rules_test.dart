import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/core/utils/money_math.dart';
import 'package:life_dashboard/features/money/domain/money_flag.dart';
import 'package:life_dashboard/features/money/domain/monthly_money_snapshot.dart';

BudgetCategory category({
  required String name,
  required double target,
  required String flagType,
  String id = 'cat',
}) {
  final now = DateTime(2026);
  return BudgetCategory(
    id: id,
    name: name,
    monthlyTarget: target,
    flagType: flagType,
    sortOrder: 0,
    createdAt: now,
    updatedAt: now,
  );
}

TransactionEntry tx({
  required double amount,
  String? categoryId = 'cat',
  String date = '2026-07-05',
  bool intentional = false,
}) =>
    TransactionEntry(
      id: 'tx-$amount-$categoryId',
      categoryId: categoryId,
      date: date,
      amount: amount,
      description: 'test',
      isIntentional: intentional,
      createdAt: DateTime(2026),
    );

void main() {
  group('MoneyMath projections', () {
    test('projected spend extrapolates linearly', () {
      expect(
        MoneyMath.projectedSpend(
            spendSoFar: 100, dayOfMonth: 10, daysInMonth: 30),
        300,
      );
    });

    test('guards day zero and invalid inputs', () {
      expect(
        MoneyMath.projectedSpend(
            spendSoFar: 100, dayOfMonth: 0, daysInMonth: 30),
        100,
      );
      expect(
        MoneyMath.projectedSpend(
            spendSoFar: 100, dayOfMonth: 5, daysInMonth: 0),
        100,
      );
    });

    test('projected surplus and annual projection', () {
      final surplus = MoneyMath.projectedSurplus(
          monthlyNetIncome: 6942, projectedSpend: 3000);
      expect(surplus, 3942);
      expect(MoneyMath.annualSavingsProjection(surplus), 47304);
    });

    test('within target pace', () {
      expect(
        MoneyMath.withinTargetPace(
            projectedSurplus: 3200, targetSurplusLow: 3200),
        isTrue,
      );
      expect(
        MoneyMath.withinTargetPace(
            projectedSurplus: 3100, targetSurplusLow: 3200),
        isFalse,
      );
    });
  });

  group('Category flag rules', () {
    test('warnOverTarget: spending past the target warns', () {
      final flag = MoneyFlagRules.evaluateCategory(
        category:
            category(name: 'Shopping', target: 258, flagType: 'warnOverTarget'),
        spent: 259,
        allIntentional: false,
      );
      expect(flag, isNotNull);
      expect(flag!.severity, MoneyFlagSeverity.warning);

      expect(
        MoneyFlagRules.evaluateCategory(
          category: category(
              name: 'Shopping', target: 258, flagType: 'warnOverTarget'),
          spent: 258,
          allIntentional: false,
        ),
        isNull,
      );
    });

    test('criticalOverZero: any spend at all is critical', () {
      final flag = MoneyFlagRules.evaluateCategory(
        category: category(
            name: 'Impulse buys', target: 0, flagType: 'criticalOverZero'),
        spent: 0.01,
        allIntentional: true,
      );
      expect(flag!.severity, MoneyFlagSeverity.critical);
    });

    test('warnOverZero: travel spend warns', () {
      final flag = MoneyFlagRules.evaluateCategory(
        category: category(name: 'Travel', target: 0, flagType: 'warnOverZero'),
        spent: 50,
        allIntentional: true,
      );
      expect(flag!.severity, MoneyFlagSeverity.warning);
    });

    test('warnOverZeroUnlessIntentional respects intentional flag', () {
      final cat = category(
          name: 'Eating out',
          target: 0,
          flagType: 'warnOverZeroUnlessIntentional');
      expect(
        MoneyFlagRules.evaluateCategory(
            category: cat, spent: 40, allIntentional: false),
        isNotNull,
      );
      expect(
        MoneyFlagRules.evaluateCategory(
            category: cat, spent: 40, allIntentional: true),
        isNull,
      );
    });

    test('none: never flags', () {
      expect(
        MoneyFlagRules.evaluateCategory(
          category: category(name: 'Housing', target: 0, flagType: 'none'),
          spent: 99999,
          allIntentional: false,
        ),
        isNull,
      );
    });
  });

  group('Surplus flags', () {
    test('below low warns, negative is critical', () {
      final warning = MoneyFlagRules.surplusFlags(
          projectedSurplus: 3000, targetSurplusLow: 3200);
      expect(warning.single.severity, MoneyFlagSeverity.warning);

      final critical = MoneyFlagRules.surplusFlags(
          projectedSurplus: -10, targetSurplusLow: 3200);
      expect(critical.single.severity, MoneyFlagSeverity.critical);

      expect(
        MoneyFlagRules.surplusFlags(
            projectedSurplus: 3500, targetSurplusLow: 3200),
        isEmpty,
      );
    });
  });

  group('MonthlyMoneySnapshot', () {
    test('computes rollup, projections, and flags from transactions', () {
      final shopping = category(
          name: 'Shopping',
          target: 258,
          flagType: 'warnOverTarget',
          id: 'shopping');
      final impulse = category(
          name: 'Impulse buys',
          target: 0,
          flagType: 'criticalOverZero',
          id: 'impulse');

      final snapshot = MonthlyMoneySnapshot.compute(
        now: DateTime(2026, 7, 10), // day 10 of 31
        monthlyNetIncome: 6942,
        targetSurplusLow: 3200,
        targetSurplusHigh: 3800,
        categories: [shopping, impulse],
        monthTransactions: [
          tx(amount: 300, categoryId: 'shopping'),
          tx(amount: 20, categoryId: 'impulse'),
          tx(amount: 50, categoryId: null), // uncategorized fog
        ],
        retirementAnnualTarget: 7000,
        retirementContributed: 3500,
        brokerageBalance: 0,
        savingsBalance: 0,
      );

      expect(snapshot.spendSoFar, 370);
      expect(snapshot.projectedSpend, closeTo(370 / 10 * 31, 0.001));
      expect(snapshot.projectedSurplus, closeTo(6942 - 370 / 10 * 31, 0.001));
      expect(snapshot.uncategorizedCount, 1);
      expect(snapshot.retirementProgress, 0.5);

      // Flags: shopping over target (warning), impulse critical, uncategorized.
      expect(
        snapshot.flags.where((f) => f.severity == MoneyFlagSeverity.critical),
        hasLength(1),
      );
      expect(snapshot.flags.length, 3);
      // Critical sorts first.
      expect(snapshot.flags.first.severity, MoneyFlagSeverity.critical);
    });
  });
}
