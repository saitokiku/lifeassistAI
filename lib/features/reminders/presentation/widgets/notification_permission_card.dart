import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/reminders_controller.dart';
import '../../application/reminders_state.dart';
import 'reminder_type_visuals.dart';

/// Master notification status with four honest states:
/// unsupported (web), off, blocked at the system level, and on.
///
/// The blocked state is remembered in widget state after a denied
/// permission request, so the user isn't left tapping a dead button.
class NotificationPermissionCard extends ConsumerStatefulWidget {
  const NotificationPermissionCard({super.key, required this.state});

  final RemindersState state;

  @override
  ConsumerState<NotificationPermissionCard> createState() =>
      _NotificationPermissionCardState();
}

class _NotificationPermissionCardState
    extends ConsumerState<NotificationPermissionCard> {
  /// True after enableNotifications() came back false — the OS said no.
  bool _denied = false;

  /// Guards both the enable and disable calls against double taps.
  bool _busy = false;

  Future<void> _enable() async {
    if (_busy) return;
    setState(() => _busy = true);
    final controller = ref.read(remindersControllerProvider);
    try {
      final granted = await controller.enableNotifications();
      if (!mounted) return;
      if (granted) {
        Haptics.medium();
        setState(() => _denied = false);
        showSuccessSnack(context, 'Reminders scheduled.');
      } else {
        setState(() => _denied = true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    if (_busy) return;
    setState(() => _busy = true);
    final controller = ref.read(remindersControllerProvider);
    try {
      await controller.disableNotifications();
      Haptics.select();
      if (mounted) showSuccessSnack(context, 'Notifications off.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (!state.platformSupported) return _unsupported(context);
    if (state.appNotificationsEnabled) return _on(context, state);
    if (_denied) return _blocked(context);
    return _off(context);
  }

  /// Web: quiet, no button. Reminders remain a fully working list.
  Widget _unsupported(BuildContext context) {
    return AppCard(
      child: _StatusRow(
        icon: Icons.notifications_off_outlined,
        color: AppColors.neutral,
        title: 'Notifications',
        caption:
            "Notifications don't exist on web. Reminders still organize your day.",
      ),
    );
  }

  /// Compact confirmation: an aligned dot and one line.
  Widget _on(BuildContext context, RemindersState state) {
    final theme = Theme.of(context);
    final n = state.enabledCount;
    final line = n == 0
        ? 'Notifications on — every reminder below is off.'
        : '$n reminder${n == 1 ? '' : 's'} on, holding the rhythm.';

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.aligned,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(line, style: theme.textTheme.bodyMedium),
          ),
          TextButton(
            onPressed: _busy ? null : _disable,
            child: const Text('Turn off'),
          ),
        ],
      ),
    );
  }

  /// Persistent denied state — honest about where the fix lives.
  Widget _blocked(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StatusRow(
            icon: Icons.notifications_off,
            color: AppColors.critical,
            title: 'Notifications blocked',
            caption:
                'Notifications are blocked at the system level. Allow them '
                'in system settings, then come back.',
          ),
          const SizedBox(height: AppSpace.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _busy ? null : _enable,
              child: const Text('Try again'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _off(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StatusRow(
            icon: Icons.notifications_off_outlined,
            color: AppColors.watch,
            title: 'Notifications off',
            caption:
                'The reminders below are just a list until notifications are on.',
          ),
          const SizedBox(height: AppSpace.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _busy ? null : _enable,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Text('Enable notifications'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.caption,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TintedIconWell(icon: icon, color: color),
        const SizedBox(width: AppSpace.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                caption,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
