import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../application/time_controller.dart';
import '../../domain/countdown.dart';
import 'countdown_editor.dart';

/// Countdowns with days remaining. The age-28 countdown asks for a birthday
/// until one is set.
class CountdownList extends ConsumerWidget {
  const CountdownList({super.key, required this.countdowns});

  final List<ResolvedCountdown> countdowns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        for (final rc in countdowns)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(rc.countdown.title),
              subtitle: rc.needsBirthday
                  ? const Text('Set birthday to activate.')
                  : rc.targetDate == null
                      ? const Text('No date set.')
                      : Text(Formatters.fullDate(rc.targetDate!)),
              leading: const Icon(Icons.hourglass_bottom, size: 20),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (rc.needsBirthday)
                    TextButton(
                      onPressed: () => context.go('/settings'),
                      child: const Text('Set birthday'),
                    )
                  else if (rc.daysLeft != null)
                    Text(
                      '${rc.daysLeft}d',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: rc.daysLeft! < 30
                                ? AppColors.watch
                                : AppColors.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await CountdownEditor.show(context,
                            countdown: rc.countdown);
                      } else if (value == 'delete') {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'Delete countdown?',
                          message: 'Removes "${rc.countdown.title}".',
                        );
                        if (confirmed) {
                          await ref
                              .read(timeControllerProvider)
                              .deleteCountdown(rc.countdown.id);
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
