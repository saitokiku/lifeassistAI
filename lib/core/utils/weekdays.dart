/// Weekday bitmask helpers shared by reminders and habit schedules.
/// Bit 0 = Monday … bit 6 = Sunday; 127 = every day.
class WeekdayMask {
  WeekdayMask._();

  static const int all = 127;
  static const int weekdaysOnly = 31; // Mon–Fri
  static const int weekendOnly = 96; // Sat–Sun

  /// One-letter labels indexed by `weekday - DateTime.monday`.
  static const List<String> shortLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static const List<String> dayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', // Monday-first
  ];

  static bool has(int mask, int weekday) =>
      mask & (1 << (weekday - DateTime.monday)) != 0;

  static int toggle(int mask, int weekday) =>
      mask ^ (1 << (weekday - DateTime.monday));

  static bool isDueOn(int mask, DateTime date) => has(mask, date.weekday);

  static int countDays(int mask) {
    var n = 0;
    for (var d = DateTime.monday; d <= DateTime.sunday; d++) {
      if (has(mask, d)) n++;
    }
    return n;
  }

  /// Human description: 'Every day', 'Weekdays', 'Weekends', or day list.
  static String describe(int mask) {
    final normalized = mask & all;
    if (normalized == all || normalized == 0) return 'Every day';
    if (normalized == weekdaysOnly) return 'Weekdays';
    if (normalized == weekendOnly) return 'Weekends';
    final days = <String>[
      for (var d = DateTime.monday; d <= DateTime.sunday; d++)
        if (has(normalized, d)) dayNames[d - DateTime.monday],
    ];
    return days.join(', ');
  }
}
