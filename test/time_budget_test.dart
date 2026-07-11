import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/core/utils/date_utils.dart';
import 'package:life_dashboard/features/time/application/time_state.dart';
import 'package:life_dashboard/features/time/domain/countdown.dart';
import 'package:life_dashboard/features/time/domain/time_category.dart';
import 'package:life_dashboard/features/time/domain/weekly_time_budget.dart';

TimeBudget budget(String id, String name, String kind, double target) =>
    TimeBudget(
      id: id,
      name: name,
      kind: kind,
      weeklyTargetHours: target,
      sortOrder: 0,
    );

TimeBlock block(String budgetId, String date, double hours) => TimeBlock(
      id: '$budgetId-$date-$hours',
      budgetId: budgetId,
      date: date,
      hours: hours,
      note: null,
      createdAt: DateTime(2026),
    );

void main() {
  group('Week math', () {
    test('weeks start Monday', () {
      // 2026-07-07 is a Tuesday; the week starts Monday 2026-07-06.
      final start = AppDateUtils.startOfWeek(DateTime(2026, 7, 7));
      expect(start, DateTime(2026, 7, 6));
      expect(
          AppDateUtils.weekDateKeys(DateTime(2026, 7, 7)).first, '2026-07-06');
      expect(
          AppDateUtils.weekDateKeys(DateTime(2026, 7, 7)).last, '2026-07-12');
    });

    test('daysInMonth handles leap years', () {
      expect(AppDateUtils.daysInMonth(DateTime(2028, 2)), 29);
      expect(AppDateUtils.daysInMonth(DateTime(2026, 2)), 28);
    });
  });

  group('Weekly budget progress', () {
    test('progress and remaining per category', () {
      final p = WeeklyTimeBudgetProgress(
        budget: budget('k', 'Kaizen', 'kaizen', 42),
        actualHours: 21,
      );
      expect(p.progress, 0.5);
      expect(p.remainingHours, 21);
      expect(p.isOverTarget, isFalse);

      final over = WeeklyTimeBudgetProgress(
        budget: budget('a', 'Admin', 'admin', 10),
        actualHours: 12,
      );
      expect(over.isOverTarget, isTrue);
      expect(over.remainingHours, -2);
    });
  });

  group('TimeState.compute', () {
    final now = DateTime(2026, 7, 7); // Tuesday
    final budgets = [
      budget('goal', 'Main goal', 'goal', 42),
      budget('decompress', 'Downtime', 'decompress', 10.5),
      budget('exercise', 'Exercise', 'exercise', 5),
    ];

    test('sums goal and recovery hours for the current week', () {
      final state = TimeState.compute(
        now: now,
        budgets: budgets,
        weekBlocks: [
          block('goal', '2026-07-06', 6),
          block('goal', '2026-07-07', 4),
          block('decompress', '2026-07-06', 2),
        ],
        countdowns: const [],
        birthday: null,
      );
      expect(state.goalHoursThisWeek, 10);
      expect(state.goalWeeklyTarget, 42);
      expect(state.recoveryHoursThisWeek, 2);
      expect(state.recoveryWeeklyTarget, 10.5);
    });

    test('available time today = 24 minus hours logged today', () {
      final state = TimeState.compute(
        now: now,
        budgets: budgets,
        weekBlocks: [
          block('goal', '2026-07-07', 5),
          block('exercise', '2026-07-07', 1),
          block('goal', '2026-07-06', 8), // yesterday, not counted today
        ],
        countdowns: const [],
        birthday: null,
      );
      expect(state.hoursLoggedToday, 6);
      expect(state.availableHoursToday, 18);
    });

    test('health hours today counts exercise/meditation kinds only', () {
      final state = TimeState.compute(
        now: now,
        budgets: budgets,
        weekBlocks: [
          block('exercise', '2026-07-07', 0.5),
          block('goal', '2026-07-07', 3),
        ],
        countdowns: const [],
        birthday: null,
      );
      expect(state.healthHoursToday, 0.5);
    });
  });

  group('Legacy kind parsing', () {
    test("stored 'kaizen' and 'toastmasters' kinds still parse", () {
      expect(TimeCategoryKind.parse('kaizen'), TimeCategoryKind.goal);
      expect(TimeCategoryKind.parse('toastmasters'), TimeCategoryKind.other);
      expect(TimeCategoryKind.parse('goal'), TimeCategoryKind.goal);
      expect(TimeCategoryKind.parse('nonsense'), TimeCategoryKind.other);
    });
  });

  group('Countdowns', () {
    final now = DateTime(2026, 7, 7);

    Countdown countdown({String? date, String? dynamicKey}) => Countdown(
          id: 'c',
          title: 't',
          targetDate: date,
          dynamicKey: dynamicKey,
          sortOrder: 0,
        );

    test('age-28 needs a birthday', () {
      final unresolved = ResolvedCountdown.resolve(
        countdown(dynamicKey: 'age28'),
        now: now,
        birthday: null,
      );
      expect(unresolved.needsBirthday, isTrue);
      expect(unresolved.daysLeft, isNull);

      final resolved = ResolvedCountdown.resolve(
        countdown(dynamicKey: 'age28'),
        now: now,
        birthday: DateTime(2000, 1, 15),
      );
      expect(resolved.targetDate, DateTime(2028, 1, 15));
      expect(resolved.needsBirthday, isFalse);
    });

    test('end of year / month / legacy retirement deadline compute from now',
        () {
      expect(
        ResolvedCountdown.resolve(countdown(dynamicKey: 'endOfYear'),
                now: now, birthday: null)
            .targetDate,
        DateTime(2026, 12, 31),
      );
      expect(
        ResolvedCountdown.resolve(countdown(dynamicKey: 'endOfMonth'),
                now: now, birthday: null)
            .targetDate,
        DateTime(2026, 7, 31),
      );
      // After April 15, the legacy retirement deadline rolls to next year.
      expect(
        ResolvedCountdown.resolve(countdown(dynamicKey: 'rothIraDeadline'),
                now: now, birthday: null)
            .targetDate,
        DateTime(2027, 4, 15),
      );
    });

    test('fixed dates parse and count down', () {
      final resolved = ResolvedCountdown.resolve(
        countdown(date: '2026-07-17'),
        now: now,
        birthday: null,
      );
      expect(resolved.daysLeft, 10);
    });
  });
}
