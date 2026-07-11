import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../habits/application/habits_controller.dart';
import '../../identity/application/identity_controller.dart';
import '../../identity/presentation/widgets/philosophy_card.dart';
import '../../identity/presentation/widgets/statement_editor.dart';
import '../../identity/presentation/widgets/statement_list.dart';
import '../../ideas/application/ideas_controller.dart';
import '../../journal/application/journal_controller.dart';
import '../../reminders/application/reminders_controller.dart';
import '../../review/application/review_controller.dart';
import '../../review/presentation/weekly_review_sheet.dart';
import '../../search/presentation/search_sheet.dart';
import '../../settings/application/settings_controller.dart';

/// The You tab: who this is for, in their own words — a personal line,
/// operating principles — then the supporting systems, each with a live
/// one-line status.
class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final identity = ref.watch(identityStateProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final habits = ref.watch(habitsStateProvider);
    final ideas = ref.watch(ideasStateProvider);
    final reminders = ref.watch(remindersStateProvider);
    final weeklyReview = ref.watch(currentWeekReviewProvider).valueOrNull;
    final journalToday = ref.watch(todayJournalProvider).valueOrNull?.length;

    final doneToday = habits?.habits.where((h) => h.doneToday).length;
    final habitCount = habits?.habits.length;
    final dueCount = ideas?.dueForReview.length ?? 0;
    final coolingCount = ideas?.cooling.length ?? 0;

    final name = settings?.displayName ?? '';

    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.lg,
              AppSpace.screen,
              AppSpace.xxl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name.isEmpty ? 'You' : name,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Search everything',
                    onPressed: () => SearchSheet.show(context),
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                AppCopy.youTagline,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              PhilosophyCard(philosophyText: identity?.philosophyText ?? ''),
              SectionHeader(
                title: 'Operating principles',
                trailing: TextButton.icon(
                  onPressed: () => StatementEditor.show(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ),
              StatementList(statements: identity?.statements ?? const []),
              const SectionHeader(title: 'Rituals'),
              _ReviewRow(done: weeklyReview != null),
              const SectionHeader(title: 'Systems'),
              _HubRow(
                icon: Icons.check_circle_outline,
                title: 'Habits',
                caption: habitCount == null
                    ? 'Small daily supports.'
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
                    ? 'A parking lot for new ideas.'
                    : dueCount > 0
                        ? '$dueCount waiting on a decision · $coolingCount cooling'
                        : coolingCount > 0
                            ? '$coolingCount cooling — parked for now'
                            : 'The lot is clear.',
                route: '/ideas',
                attention: dueCount > 0,
              ),
              const SizedBox(height: AppSpace.cardGap),
              _HubRow(
                icon: Icons.notifications_outlined,
                title: 'Reminders',
                caption: reminders == null
                    ? 'Gentle nudges through the day.'
                    : !reminders.platformSupported
                        ? 'Not available on web.'
                        : !reminders.appNotificationsEnabled
                            ? 'Paused — notifications are off'
                            : '${reminders.enabledCount} on through the day',
                route: '/reminders',
              ),
              const SizedBox(height: AppSpace.cardGap),
              _HubRow(
                icon: Icons.edit_note_rounded,
                title: 'Journal',
                caption: journalToday == null
                    ? 'One honest line a day.'
                    : journalToday == 0
                        ? "Today isn't written yet."
                        : 'Today is written · '
                            '$journalToday line${journalToday == 1 ? '' : 's'}',
                route: '/journal',
              ),
              const SizedBox(height: AppSpace.cardGap),
              _HubRow(
                icon: Icons.settings_outlined,
                title: 'Settings',
                caption: 'Name, targets, appearance, backup & data.',
                route: '/settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The weekly review ritual entry, with an honest status line.
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      onTap: () => WeeklyReviewSheet.show(context),
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
              color: scheme.primaryTint,
              borderRadius: BorderRadius.circular(AppRadius.chip + 2),
            ),
            child: const Icon(
              Icons.history_edu_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly review', style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  done
                      ? 'This week is written. Edit any time.'
                      : 'Five minutes to close the week — due Sunday.',
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
