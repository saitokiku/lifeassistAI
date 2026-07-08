import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/reminder_type.dart';

/// Soft indigo reserved for the night review — the one hue the palette
/// doesn't carry. Identification only, never status.
const Color _nightIndigo = Color(0xFF8DA2F2);

/// Presentation-only visual identity per reminder type: a glyph and a soft
/// identifying tint so the list reads at a glance.
extension ReminderTypeVisuals on ReminderType {
  IconData get glyph => switch (this) {
        ReminderType.morningCommand => Icons.wb_twilight,
        ReminderType.kaizenExperiment => Icons.science,
        ReminderType.moneyCheck => Icons.account_balance_wallet,
        ReminderType.nightReview => Icons.nightlight,
        ReminderType.custom => Icons.notifications,
      };

  Color get tint => switch (this) {
        ReminderType.morningCommand => AppColors.watch,
        ReminderType.kaizenExperiment => AppColors.primary,
        ReminderType.moneyCheck => AppColors.aligned,
        ReminderType.nightReview => _nightIndigo,
        ReminderType.custom => AppColors.neutral,
      };

  /// The hour this kind of nudge usually belongs to. Used as an editor
  /// prefill only — never forced on saved reminders.
  TimeOfDay get typicalTime => switch (this) {
        ReminderType.morningCommand => const TimeOfDay(hour: 8, minute: 0),
        ReminderType.kaizenExperiment => const TimeOfDay(hour: 12, minute: 0),
        ReminderType.moneyCheck => const TimeOfDay(hour: 18, minute: 0),
        ReminderType.nightReview => const TimeOfDay(hour: 22, minute: 0),
        ReminderType.custom => const TimeOfDay(hour: 9, minute: 0),
      };
}

/// 40px tinted icon well — the same treatment the You hub rows use.
class TintedIconWell extends StatelessWidget {
  const TintedIconWell({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.chip + 2),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
