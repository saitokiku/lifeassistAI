import '../constants/reminder_templates.dart';
import '../storage/app_database.dart';

/// Builds the notification body for a reminder. A reminder's stored message
/// wins; empty messages fall back to the rotating template for its type.
class ReminderMessageBuilder {
  ReminderMessageBuilder._();

  static String bodyFor(Reminder reminder, {DateTime? day}) {
    final message = reminder.message.trim();
    if (message.isNotEmpty) return message;
    return ReminderTemplates.rotatingMessageFor(
        reminder.type, day ?? DateTime.now());
  }
}
