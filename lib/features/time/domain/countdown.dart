import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';

export '../../../core/storage/app_database.dart' show Countdown;

/// Age used by the legacy `age28` dynamic countdown. Rows with this key
/// predate the universal redesign; they keep working, but new countdowns
/// use fixed dates.
const int legacyLockInAge = 28;

/// A countdown with its target resolved (dynamic keys computed at read time).
class ResolvedCountdown {
  const ResolvedCountdown({
    required this.countdown,
    required this.targetDate,
    required this.daysLeft,
  });

  final Countdown countdown;
  final DateTime? targetDate;
  final int? daysLeft;

  bool get needsBirthday =>
      countdown.dynamicKey == 'age28' && targetDate == null;

  static ResolvedCountdown resolve(
    Countdown countdown, {
    required DateTime now,
    required DateTime? birthday,
  }) {
    DateTime? target;
    switch (countdown.dynamicKey) {
      case 'age28':
        target = AppDateUtils.birthdayAtAge(birthday, legacyLockInAge);
      case 'endOfYear':
        target = AppDateUtils.endOfYear(now);
      case 'endOfMonth':
        target = AppDateUtils.endOfMonth(now);
      case 'rothIraDeadline':
        target = AppDateUtils.retirementContributionDeadline(now);
      default:
        final raw = countdown.targetDate;
        if (raw != null && raw.isNotEmpty) {
          target = DateTime.tryParse(raw);
        }
    }
    return ResolvedCountdown(
      countdown: countdown,
      targetDate: target,
      daysLeft:
          target == null ? null : AppDateUtils.daysUntil(target, from: now),
    );
  }
}
