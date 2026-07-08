import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../settings/application/settings_controller.dart';

/// Inline birthday capture for the age-28 countdown — no detour through
/// Settings. Input-first date picker, one save.
class BirthdaySheet extends ConsumerStatefulWidget {
  const BirthdaySheet({super.key});

  static Future<void> show(BuildContext context) => showAppSheet<void>(
        context,
        builder: (_) => const BirthdaySheet(),
      );

  @override
  ConsumerState<BirthdaySheet> createState() => _BirthdaySheetState();
}

class _BirthdaySheetState extends ConsumerState<BirthdaySheet> {
  DateTime? _date;

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.input,
      initialDate: _date ?? DateTime(now.year - 26, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final date = _date;
    if (date == null) return;
    final navigator = Navigator.of(context);
    try {
      await ref.read(settingsControllerProvider).setBirthday(date);
    } catch (_) {
      if (mounted) showErrorSnack(context, "That didn't save. Try again.");
      return;
    }
    Haptics.medium();
    if (!mounted) return;
    showSuccessSnack(context, 'Saved. The clock is running.');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSheet(
      title: 'Set your birthday',
      subtitle: 'Powers the age-28 countdown. Nothing else.',
      footer: AppSheetButton(
        label: 'Save',
        onPressed: _date == null ? null : _save,
      ),
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _pick,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Birthday',
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
            ),
            isEmpty: _date == null,
            child: _date == null
                ? null
                : Text(
                    Formatters.fullDate(_date!),
                    style: theme.textTheme.bodyLarge,
                  ),
          ),
        ),
      ],
    );
  }
}
