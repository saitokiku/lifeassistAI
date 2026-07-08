import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/app_card.dart';
import '../../habits/application/habits_controller.dart';
import '../../identity/application/identity_controller.dart';
import '../../ideas/application/ideas_controller.dart';
import '../../reminders/application/reminders_controller.dart';

/// The You tab: direction and systems in one place.
///
/// Identity leads (the "why"), then the supporting systems — habits, ideas,
/// reminders, settings — each with a live one-line status.
class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final identity = ref.watch(identityStateProvider);
    final habits = ref.watch(habitsStateProvider);
    final ideas = ref.watch(ideasStateProvider);
    final reminders = ref.watch(remindersStateProvider);

    final doneToday = habits?.habits.where((h) => h.doneToday).length;
    final habitCount = habits?.habits.length;
    final dueCount = ideas?.dueForReview.length ?? 0;
    final coolingCount = ideas?.cooling.length ?? 0;
    final goalCount = identity?.goals.length;

    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen, AppSpace.lg, AppSpace.screen, AppSpace.xxl,
            ),
            children: [
              Text('You', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpace.xs),
              Text(
                'Direction, systems, and settings.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              AppCard(
                tinted: true,
                onTap: () => context.push('/identity'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Identity & direction',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: theme.colorScheme.textTertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      identity == null
                          ? 'Philosophy, goals, and the freedom target.'
                          : identity.philosophyText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (goalCount != null && goalCount > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '$goalCount goal${goalCount == 1 ? '' : 's'} in play',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.cardGap),
              _HubRow(
                icon: Icons.check_circle_outline,
                title: 'Habits',
                caption: habitCount == null
                    ? 'Daily support systems.'
                    : habitCount == 0
                        ? 'Nothing to check off yet.'
                        : '$doneToday of $habitCount done today',
                route: '/habits',
              ),
              const SizedBox(height: AppSpace.cardGap),
              _HubRow(
                icon: Icons.lightbulb_outline,
                title: 'Ideas',
                caption: ideas == null
                    ? 'The parking lot.'
                    : dueCount > 0
                        ? '$dueCount due for a verdict · $coolingCount cooling'
                        : coolingCount > 0
                            ? '$coolingCount cooling — captured, not chased'
                            : 'The lot is clear.',
                route: '/ideas',
                attention: dueCount > 0,
              ),
              const SizedBox(height: AppSpace.cardGap),
              _HubRow(
                icon: Icons.notifications_outlined,
                title: 'Reminders',
                caption: reminders == null
                    ? 'The daily rhythm.'
                    : !reminders.platformSupported
                        ? 'Not available on web.'
                        : !reminders.appNotificationsEnabled
                            ? 'Paused — notifications are off'
                            : '${reminders.enabledCount} on, holding the rhythm',
                route: '/reminders',
              ),
              const SizedBox(height: AppSpace.cardGap),
              _HubRow(
                icon: Icons.settings_outlined,
                title: 'Settings',
                caption: 'Targets, appearance, backup & data.',
                route: '/settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubRow extends StatelessWidget {
  const _HubRow({
    required this.icon,
    required this.title,
    required this.caption,
    required this.route,
    this.attention = false,
  });

  final IconData icon;
  final String title;
  final String caption;
  final String route;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      onTap: () => context.push(route),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: attention
                  ? AppColors.watch.withValues(alpha: 0.14)
                  : scheme.primaryTint,
              borderRadius: BorderRadius.circular(AppRadius.chip + 2),
            ),
            child: Icon(
              icon,
              size: 20,
              color: attention ? AppColors.watch : AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: scheme.textTertiary,
          ),
        ],
      ),
    );
  }
}
