import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/providers.dart' show DayPart;
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/features/dashboard/application/dashboard_state.dart';
import 'package:life_dashboard/features/focus/application/focus_state.dart';
import 'package:life_dashboard/features/money/application/money_state.dart';
import 'package:life_dashboard/features/money/domain/monthly_money_snapshot.dart';
import 'package:life_dashboard/features/settings/domain/user_settings.dart';
import 'package:life_dashboard/features/time/application/time_state.dart';

/// The Up Next ladder is the app's central product logic and had no
/// direct test. These cover every branch, its priority ordering, and the
/// two defects found in review: the month-start false alarm and the
/// unused time-of-day signal.
void main() {
  // 2026-07-08 is a Wednesday; 2026-07-12 a Sunday; 2026-07-13 a Monday.
  final wednesday = DateTime(2026, 7, 8);

  MainGoal goalRow({String status = 'active'}) => MainGoal(
        id: 'g1',
        title: 'Ship the thing',
        why: '',
        targetDate: null,
        status: status,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        completedAt: status == 'completed' ? DateTime(2026, 7, 1) : null,
      );

  DailyExperiment actionRow(DateTime day) => DailyExperiment(
        id: 'a1',
        date: '${day.year}-${day.month.toString().padLeft(2, '0')}'
            '-${day.day.toString().padLeft(2, '0')}',
        hypothesis: '',
        actionTaken: 'did a thing',
        result: '',
        verdict: 'confirm',
        notes: null,
        createdAt: day,
        updatedAt: day,
      );

  TransactionEntry txRow(String date, int cents) => TransactionEntry(
        id: 'tx-$date-$cents',
        categoryId: null,
        accountId: null,
        sourceRecurringId: null,
        date: date,
        amountCents: cents,
        description: 'rent',
        isIntentional: true,
        createdAt: DateTime(2026, 7, 1),
      );

  DashboardState build({
    DateTime? today,
    String goalStatus = 'active',
    bool goalSet = true,
    bool actionLogged = false,
    double goalHours = 100,
    double recoveryHours = 5,
    int ideasDue = 0,
    bool reviewDone = true,
    DayPart dayPart = DayPart.morning,
    double income = 5000,
    List<TransactionEntry> transactions = const [],
  }) {
    final day = today ?? wednesday;
    final settings = UserSettings(
      displayName: '',
      monthlyNetIncome: income,
      targetSurplusLow: 0,
      targetSurplusHigh: 0,
      birthday: null,
      retirementAnnualTarget: 0,
      retirementContributed: 0,
      brokerageBalance: 0,
      savingsBalance: 0,
      philosophyText: '',
      dashboardAreas: DashboardArea.values.toSet(),
    );
    final snapshot = MonthlyMoneySnapshot.compute(
      now: day,
      monthlyNetIncome: income,
      targetSurplusLow: 0,
      targetSurplusHigh: 0,
      categories: const [],
      monthTransactions: transactions,
      retirementAnnualTarget: 0,
      retirementContributed: 0,
      brokerageBalance: 0,
      savingsBalance: 0,
    );
    return DashboardState(
      focus: FocusState(
        goal: goalSet ? goalRow(status: goalStatus) : null,
        milestones: const [],
        activeMetric: null,
        activeMetricEntries: const [],
        actions: actionLogged ? [actionRow(day)] : const [],
        today: day,
      ),
      money: MoneyState(
        snapshot: snapshot,
        categories: const [],
        monthTransactions: transactions,
        now: day,
      ),
      time: TimeState.compute(
        now: day,
        budgets: [
          TimeBudget(
            id: 'b-goal',
            name: 'Main goal',
            kind: 'goal',
            weeklyTargetHours: 10,
            sortOrder: 0,
          ),
          TimeBudget(
            id: 'b-rest',
            name: 'Downtime',
            kind: 'decompress',
            weeklyTargetHours: 8,
            sortOrder: 1,
          ),
        ],
        weekBlocks: [
          if (goalHours > 0)
            TimeBlock(
              id: 'tb-goal',
              budgetId: 'b-goal',
              date: '2026-07-06',
              hours: goalHours,
              note: null,
              createdAt: day,
            ),
          if (recoveryHours > 0)
            TimeBlock(
              id: 'tb-rest',
              budgetId: 'b-rest',
              date: '2026-07-06',
              hours: recoveryHours,
              note: null,
              createdAt: day,
            ),
        ],
        countdowns: const [],
        birthday: null,
      ),
      settings: settings,
      exerciseOrMeditationToday: false,
      parkedIdeaCount: 0,
      ideasDueForReview: ideasDue,
      dayPart: dayPart,
      weeklyReviewDone: reviewDone,
    );
  }

  group('priority ladder', () {
    test('no goal outranks everything', () {
      expect(build(goalSet: false, ideasDue: 3).upNext, UpNextKind.setGoal);
    });

    test('a completed goal is celebrated before any chore', () {
      expect(build(goalStatus: 'completed', ideasDue: 3).upNext,
          UpNextKind.goalCompleted);
    });

    test('an unlogged step beats hours, measure, ideas', () {
      expect(build(actionLogged: false, ideasDue: 5).upNext,
          UpNextKind.logAction);
    });

    test('hours far behind come next once the step is logged', () {
      expect(build(actionLogged: true, goalHours: 1).upNext,
          UpNextKind.logGoalTime);
    });

    test('zero downtime asks to protect recovery', () {
      expect(build(actionLogged: true, recoveryHours: 0).upNext,
          UpNextKind.protectRecovery);
    });

    test('ideas due surface once the goal work is handled', () {
      expect(build(actionLogged: true, ideasDue: 2).upNext,
          UpNextKind.reviewIdeas);
    });

    test('a settled day says so', () {
      expect(build(actionLogged: true).upNext, UpNextKind.steady);
    });

    test('a paused goal skips the goal branches', () {
      final state = build(goalStatus: 'paused', actionLogged: false);
      expect(state.upNext, isNot(UpNextKind.logAction));
    });
  });

  group('money never cries wolf at the start of a month', () {
    test('rent on the 1st does NOT hijack Up Next', () {
      final state = build(
        today: DateTime(2026, 7, 1),
        transactions: [txRow('2026-07-01', 150000)], // $1,500 rent
        income: 5000,
      );
      // Straight-line, this projects $46,500 of spend. That is an
      // artifact of the calendar, not a spending problem.
      expect(state.moneyCritical, isFalse);
      expect(state.upNext, isNot(UpNextKind.moneyCritical));
    });

    test('the same overspend mid-month IS critical', () {
      final state = build(
        today: DateTime(2026, 7, 20),
        transactions: [txRow('2026-07-01', 900000)], // $9,000 spent
        income: 5000,
      );
      expect(state.moneyCritical, isTrue);
      expect(state.upNext, UpNextKind.moneyCritical);
    });

    test('with no income there is no money verdict at all', () {
      final state = build(
        today: DateTime(2026, 7, 20),
        transactions: [txRow('2026-07-01', 900000)],
        income: 0,
      );
      expect(state.moneyCritical, isFalse);
    });
  });

  group('time of day reorders, not just rewords', () {
    test('evening puts the weekly review above starting new work', () {
      final evening = build(
        today: DateTime(2026, 7, 12), // Sunday
        actionLogged: true,
        goalHours: 1, // hours behind — a "plan more work" prompt
        reviewDone: false,
        dayPart: DayPart.evening,
      );
      expect(evening.upNext, UpNextKind.weeklyReview);

      final morning = build(
        today: DateTime(2026, 7, 12),
        actionLogged: true,
        goalHours: 1,
        reviewDone: false,
        dayPart: DayPart.morning,
      );
      expect(morning.upNext, UpNextKind.logGoalTime);
    });

    test('logging the step still comes first in the evening', () {
      final state = build(
        today: DateTime(2026, 7, 12),
        actionLogged: false,
        reviewDone: false,
        dayPart: DayPart.evening,
      );
      expect(state.upNext, UpNextKind.logAction);
    });

    test('the review is reachable on Monday too, not only Sunday', () {
      expect(
        build(
          today: DateTime(2026, 7, 13), // Monday
          actionLogged: true,
          reviewDone: false,
        ).upNext,
        UpNextKind.weeklyReview,
      );
    });
  });

  group('the spoken line always says something', () {
    test('every kind has non-empty Siri copy', () {
      for (final state in [
        build(goalSet: false),
        build(goalStatus: 'completed'),
        build(actionLogged: false),
        build(actionLogged: true, goalHours: 1),
        build(actionLogged: true, recoveryHours: 0),
        build(actionLogged: true, ideasDue: 2),
        build(actionLogged: true),
      ]) {
        expect(state.upNextSpoken.trim(), isNotEmpty);
      }
    });
  });
}
