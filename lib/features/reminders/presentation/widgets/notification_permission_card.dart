import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../application/reminders_controller.dart';
import '../../application/reminders_state.dart';

/// Master notification switch + permission request, with graceful handling
/// for denied permission and unsupported platforms (web).
class NotificationPermissionCard extends ConsumerWidget {
  const NotificationPermissionCard({super.key, required this.state});

  final RemindersState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!state.platformSupported) {
      return const MetricCard(
        title: 'Notifications',
        badgeLabel: 'Unavailable',
        badgeLevel: StatusLevel.neutral,
        supportText:
            'Local notification scheduling is not available on web. Reminders still save and will fire on iOS/Android builds.',
      );
    }

    return MetricCard(
      title: 'Notifications',
      badgeLabel: state.appNotificationsEnabled ? 'On' : 'Off',
      badgeLevel: state.appNotificationsEnabled
          ? StatusLevel.aligned
          : StatusLevel.watch,
      supportText: state.appNotificationsEnabled
          ? '${state.enabledCount} reminder${state.enabledCount == 1 ? '' : 's'} scheduled daily.'
          : 'Enable to get the morning command, experiment nudge, money check, and night review.',
      child: Align(
        alignment: Alignment.centerLeft,
        child: state.appNotificationsEnabled
            ? OutlinedButton(
                onPressed: () async {
                  await ref
                      .read(remindersControllerProvider)
                      .disableNotifications();
                  if (context.mounted) {
                    showSuccessSnack(context, 'Notifications disabled.');
                  }
                },
                child: const Text('Disable notifications'),
              )
            : FilledButton(
                onPressed: () async {
                  final granted = await ref
                      .read(remindersControllerProvider)
                      .enableNotifications();
                  if (context.mounted) {
                    if (granted) {
                      showSuccessSnack(context, 'Reminders scheduled.');
                    } else {
                      showErrorSnack(
                        context,
                        'Permission denied. Enable notifications for Life Dashboard in system settings, then try again.',
                      );
                    }
                  }
                },
                child: const Text('Enable notifications'),
              ),
      ),
    );
  }
}
