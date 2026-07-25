import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/utils/date_utils.dart';
import 'package:life_dashboard/features/habits/domain/habit_log.dart';

/// Day arithmetic must be calendar arithmetic. `Duration(days: n)` is
/// exact elapsed time while a local DateTime is wall-clock, so stepping
/// across a spring-forward transition landed on the wrong calendar day:
/// walking back from 2025-03-12 skipped 2025-03-09 entirely, which
/// dropped a day out of every trailing window and let a missed habit day
/// pass unnoticed inside a streak.
///
/// These assertions are timezone-independent — they check the *calendar*
/// identities that `Duration` math breaks in DST zones and that
/// [AppDateUtils.addDays] / [AppDateUtils.subtractDays] preserve
/// everywhere. Run the suite with `TZ=America/New_York` to exercise the
/// original failure directly.
void main() {
  group('addDays / subtractDays are calendar-exact', () {
    test('a 30-day window contains 30 distinct consecutive days', () {
      final keys = AppDateUtils.lastDateKeys(DateTime(2025, 3, 12), 30);
      expect(keys, hasLength(30));
      expect(keys.toSet(), hasLength(30), reason: 'no duplicates');
      expect(keys.last, '2025-03-12');
      expect(keys.first, '2025-02-11');
      // The spring-forward day itself must be present.
      expect(keys, contains('2025-03-09'));
      // And the sequence must be gapless.
      for (var i = 1; i < keys.length; i++) {
        final prev = DateTime.parse(keys[i - 1]);
        final cur = DateTime.parse(keys[i]);
        expect(AppDateUtils.daysBetween(prev, cur), 1);
      }
    });

    test('stepping back one day at a time never skips a date', () {
      var day = DateTime(2025, 3, 12);
      final seen = <String>[];
      for (var i = 0; i < 6; i++) {
        seen.add(AppDateUtils.dateKey(day));
        day = AppDateUtils.subtractDays(day, 1);
      }
      expect(seen, [
        '2025-03-12',
        '2025-03-11',
        '2025-03-10',
        '2025-03-09',
        '2025-03-08',
        '2025-03-07',
      ]);
    });

    test('fall-back windows are gapless too', () {
      final keys = AppDateUtils.lastDateKeys(DateTime(2025, 11, 5), 10);
      expect(keys.toSet(), hasLength(10));
      expect(keys, contains('2025-11-02'));
    });

    test('addDays normalizes across month and year ends', () {
      expect(AppDateUtils.dateKey(AppDateUtils.addDays(DateTime(2026, 1, 31), 1)),
          '2026-02-01');
      expect(
          AppDateUtils.dateKey(AppDateUtils.addDays(DateTime(2026, 12, 31), 1)),
          '2027-01-01');
      expect(
          AppDateUtils.dateKey(AppDateUtils.subtractDays(DateTime(2028, 3, 1), 1)),
          '2028-02-29');
    });
  });

  group('daysBetween does not truncate short or long days', () {
    test('consecutive days are always exactly one apart', () {
      for (final d in [
        DateTime(2025, 3, 9),
        DateTime(2025, 11, 2),
        DateTime(2026, 7, 25),
      ]) {
        expect(AppDateUtils.daysBetween(d, AppDateUtils.addDays(d, 1)), 1);
        expect(AppDateUtils.daysBetween(AppDateUtils.addDays(d, 1), d), -1);
      }
    });

    test('a countdown across spring-forward reads the right number', () {
      // 2025-03-08 → 2025-03-10 is two calendar days even though only
      // 47 real hours elapse in a DST zone.
      expect(
        AppDateUtils.daysUntil(DateTime(2025, 3, 10),
            from: DateTime(2025, 3, 8)),
        2,
      );
    });
  });

  group('streaks span the transition', () {
    test('a habit logged every day keeps its full streak across DST', () {
      final days = <String>{
        for (var i = 0; i < 8; i++)
          AppDateUtils.dateKey(
              AppDateUtils.subtractDays(DateTime(2025, 3, 12), i)),
      };
      expect(
        HabitStats.streak(days, DateTime(2025, 3, 12), weekdays: 127),
        8,
      );
    });

    test('missing the spring-forward day is noticed', () {
      final days = <String>{
        for (var i = 0; i < 8; i++)
          AppDateUtils.dateKey(
              AppDateUtils.subtractDays(DateTime(2025, 3, 12), i)),
      }..remove('2025-03-09');
      // Three logged days, then the gap. Grace forgives one miss per
      // week, so the run continues into the prior week but the skipped
      // day is genuinely evaluated rather than stepped over.
      final withGrace =
          HabitStats.streak(days, DateTime(2025, 3, 12), weekdays: 127);
      final withoutGrace = HabitStats.streak(
        days,
        DateTime(2025, 3, 12),
        weekdays: 127,
        allowGraceDay: false,
      );
      expect(withoutGrace, 3, reason: 'the gap stops the streak');
      expect(withGrace, greaterThan(withoutGrace));
    });
  });
}
