/// Reminder domain model.
library;

export '../../../core/storage/app_database.dart' show Reminder;

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/weekdays.dart';
import 'reminder_type.dart';

extension ReminderX on Reminder {
  ReminderType get typeEnum => ReminderType.parse(type);

  bool get isOneShot => oneShotDate != null && oneShotDate!.isNotEmpty;

  /// 'Every day', 'Weekdays', 'Mon, Wed', or 'Once · Jul 12'.
  String get scheduleLabel {
    if (isOneShot) {
      final date = AppDateUtils.tryParseDateKey(oneShotDate!);
      return date == null ? 'Once' : 'Once · ${Formatters.shortDate(date)}';
    }
    return WeekdayMask.describe(weekdays);
  }
}
