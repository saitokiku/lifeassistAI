import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_number_field.dart';
import '../../application/habits_controller.dart';
import '../../application/habits_state.dart';
import '../../domain/habit.dart';

/// Today's checklist: tap to complete boolean habits, enter values for
/// numeric/duration habits. Tapping a done habit un-logs it.
class HabitChecklist extends ConsumerWidget {
  const HabitChecklist({super.key, required this.state});

  final HabitsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(habitsControllerProvider);
    return Column(
      children: [
        for (final view in state.habits)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: CheckboxListTile(
              value: view.doneToday,
              onChanged: (checked) async {
                if (checked == false) {
                  await controller.unlogHabit(
                      habitId: view.habit.id, date: state.today);
                  return;
                }
                final type = HabitType.parse(view.habit.type);
                if (type == HabitType.boolean) {
                  await controller.logHabit(
                    habitId: view.habit.id,
                    date: state.today,
                    value: 1,
                  );
                } else {
                  await _askValue(context, ref, view);
                }
              },
              title: Text(view.habit.name),
              subtitle: Text(_subtitle(view)),
              secondary: view.streak > 0
                  ? Text('${view.streak}d',
                      style: Theme.of(context).textTheme.titleMedium)
                  : null,
            ),
          ),
      ],
    );
  }

  String _subtitle(HabitView view) {
    final parts = <String>['${view.weeklyCount}/7 this week'];
    final log = view.todayLog;
    final type = HabitType.parse(view.habit.type);
    if (log != null && type != HabitType.boolean) {
      parts.add('today: ${log.value} ${view.habit.unit ?? ''}'.trim());
    }
    return parts.join(' · ');
  }

  Future<void> _askValue(
      BuildContext context, WidgetRef ref, HabitView view) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(view.habit.name),
        content: Form(
          key: formKey,
          child: AppNumberField(
            label: 'Value${view.habit.unit == null ? '' : ' (${view.habit.unit})'}',
            controller: controller,
            validator: (v) => Validators.positiveNumber(v, label: 'Value'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(dialogContext)
                  .pop(Validators.parseNumber(controller.text));
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
    if (saved != null) {
      await ref.read(habitsControllerProvider).logHabit(
            habitId: view.habit.id,
            date: view.today,
            value: saved,
          );
    }
  }
}
