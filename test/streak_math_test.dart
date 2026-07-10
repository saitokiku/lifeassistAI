import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/utils/date_utils.dart';
import 'package:life_dashboard/core/utils/weekdays.dart';
import 'package:life_dashboard/features/focus/domain/daily_action.dart';
import 'package:life_dashboard/features/habits/domain/habit_log.dart';

/// Streaks are the app's most emotionally loaded number — the math gets
/// pinned down here so forgiveness never turns into flattery.
void main() {
  // Thursday 2026-07-09; the week runs Mon 07-06 .. Sun 07-12.
  final today = DateTime(2026, 7, 9);

  Set<String> days(List<String> keys) => keys.toSet();

  String key(DateTime d) => AppDateUtils.dateKey(d);

  Set<String> lastNDays(int n, {DateTime? endingAt, Set<int>? skipOffsets}) {
    final end = endingAt ?? today;
    return {
      for (var i = 0; i < n; i++)
        if (!(skipOffsets?.contains(i) ?? false))
          key(end.subtract(Duration(days: i))),
    };
  }

  group('HabitStats.streak — daily habits', () {
    test('unbroken run counts every day', () {
      expect(HabitStats.streak(lastNDays(5), today), 5);
    });

    test('empty log is zero', () {
      expect(HabitStats.streak(const {}, today), 0);
    });

    test('an open today does not break the streak', () {
      // Logged yesterday and before, nothing yet today.
      final logged = lastNDays(4, skipOffsets: {0});
      expect(HabitStats.streak(logged, today), 3);
    });

    test('one missed day is forgiven (grace), not counted', () {
      // 6 logged days with a hole two days ago: streak keeps the run.
      final logged = lastNDays(7, skipOffsets: {2});
      expect(HabitStats.streak(logged, today), 6);
    });

    test('two misses in the same week break the streak', () {
      // Holes on Tue (offset 2) and Mon (offset 3) — same Mon-Sun week.
      final logged = lastNDays(7, skipOffsets: {2, 3});
      expect(HabitStats.streak(logged, today), 2);
    });

    test('grace can be used once per calendar week', () {
      // A hole this week (Tue, offset 2) and one last week (offset 7 =
      // Thursday 07-02) — both forgiven, everything else counts.
      final logged = lastNDays(14, skipOffsets: {2, 7});
      expect(HabitStats.streak(logged, today), 12);
    });

    test('grace cannot mint a streak from nothing', () {
      // Only ancient history logged; the recent tail is dead.
      final logged = days(['2026-06-01', '2026-06-02']);
      expect(HabitStats.streak(logged, today), 0);
    });

    test('grace off restores strict counting', () {
      final logged = lastNDays(7, skipOffsets: {2});
      expect(
        HabitStats.streak(logged, today, allowGraceDay: false),
        2,
      );
    });
  });

  group('HabitStats.streak — weekday-scheduled habits', () {
    // Mon/Wed/Fri mask: bits 0, 2, 4.
    const monWedFri = 1 | (1 << 2) | (1 << 4);

    test('unscheduled days are skipped, not broken', () {
      // Today is Thu (unscheduled). Logged Wed 07-08, Mon 07-06,
      // Fri 07-03, Wed 07-01: four scheduled hits in a row.
      final logged = days(['2026-07-08', '2026-07-06', '2026-07-03',
          '2026-07-01']);
      expect(
        HabitStats.streak(logged, today, weekdays: monWedFri,
            allowGraceDay: false),
        4,
      );
    });

    test('a missed scheduled day still breaks (without grace)', () {
      // Wed 07-08 logged, Mon 07-06 missed, Fri 07-03 logged.
      final logged = days(['2026-07-08', '2026-07-03']);
      expect(
        HabitStats.streak(logged, today, weekdays: monWedFri,
            allowGraceDay: false),
        1,
      );
    });

    test('grace forgives one scheduled miss', () {
      final logged = days(['2026-07-08', '2026-07-03', '2026-07-01']);
      expect(
        HabitStats.streak(logged, today, weekdays: monWedFri),
        3, // Mon 07-06 forgiven; Wed+Fri+Wed counted.
      );
    });

    test('scheduledCountThisWeek counts mask days', () {
      expect(HabitStats.scheduledCountThisWeek(monWedFri), 3);
      expect(HabitStats.scheduledCountThisWeek(WeekdayMask.all), 7);
    });
  });

  group('DailyActionStats.streak', () {
    test('delegates with the same grace rules', () {
      final logged = lastNDays(7, skipOffsets: {2});
      expect(DailyActionStats.streak(logged, today), 6);
    });
  });

  group('WeekdayMask', () {
    test('describe names the common shapes', () {
      expect(WeekdayMask.describe(WeekdayMask.all), 'Every day');
      expect(WeekdayMask.describe(WeekdayMask.weekdaysOnly), 'Weekdays');
      expect(WeekdayMask.describe(WeekdayMask.weekendOnly), 'Weekends');
      expect(WeekdayMask.describe(1 | (1 << 2)), 'Mon, Wed');
    });

    test('toggle flips a single day', () {
      const monOnly = 1;
      final withWed = WeekdayMask.toggle(monOnly, DateTime.wednesday);
      expect(WeekdayMask.has(withWed, DateTime.wednesday), isTrue);
      expect(WeekdayMask.toggle(withWed, DateTime.wednesday), monOnly);
    });

    test('isDueOn matches the calendar', () {
      // 2026-07-09 is a Thursday.
      expect(WeekdayMask.isDueOn(1 << 3, DateTime(2026, 7, 9)), isTrue);
      expect(WeekdayMask.isDueOn(1, DateTime(2026, 7, 9)), isFalse);
    });
  });
}
