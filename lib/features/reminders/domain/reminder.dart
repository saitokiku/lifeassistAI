/// Reminder domain model.
library;

export '../../../core/storage/app_database.dart' show Reminder;

import '../../../core/storage/app_database.dart';
import 'reminder_type.dart';

extension ReminderX on Reminder {
  ReminderType get typeEnum => ReminderType.parse(type);
}
