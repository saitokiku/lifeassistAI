import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../ui/app_icons.dart';
import '../../../ui/pressable.dart';
import '../../../ui/tab_page_header.dart';
import '../../habits/application/habits_controller.dart';
import '../../identity/application/identity_controller.dart';
import '../../identity/presentation/widgets/philosophy_card.dart';
import '../../identity/presentation/widgets/statement_editor.dart';
import '../../identity/presentation/widgets/statement_list.dart';
import '../../ideas/application/ideas_controller.dart';
import '../../journal/application/journal_controller.dart';
import '../../notes/application/notes_controller.dart';
import '../../reminders/application/reminders_controller.dart';
import '../../review/application/review_controller.dart';
import '../../review/presentation/weekly_review_sheet.dart';
import '../../search/presentation/search_sheet.dart';
import '../../settings/application/settings_controller.dart';

/// The You tab: who this is for, in their own words — a personal line,
/// operating principles — then the Library: every supporting system as
/// a tile with a live one-line status. Notes and Journal sit first;
/// they're the two the day actually ends in.
class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityStateProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final habits = ref.watch(habitsStateProvider);
    final ideas = ref.watch(ideasStateProvider);
    final reminders = ref.watch(remindersStateProvider);
    final weeklyReview = ref.watch(currentWeekReviewProvider).valueOrNull;
    final journalToday = ref.watch(todayJournalProvider).valueOrNull?.length;
    final notes = ref.watch(notesProvider).valueOrNull;
    final noteLinks = ref.watch(noteLinkCountProvider).valueOrNull ?? 0;

    final doneToday = habits?.habits.where((h) => h.doneToday).length;
    final habitCount = habits?.habits.length;
    final dueCount = ideas?.dueForReview.length ?? 0;
    final coolingCount = ideas?.cooling.length ?? 0;

    final name = settings?.displayName ?? '';

    final tiles = <_LibraryTileData>[
      _LibraryTileData(
        icon: AppIcons.notes,
        title: 'Notes',
        caption: notes == null
            ? 'Think in links.'
            : notes.isEmpty
                ? 'Your Zettelkasten awaits its first note.'
                : '${notes.length} note${notes.length == 1 ? '' : 's'}'
                    ' · $noteLinks link${noteLinks == 1 ? '' : 's'}',
        route: '/notes',
      ),
      _LibraryTileData(
        icon: AppIcons.journal,
        title: 'Journal',
        caption: journalToday == null
            ? 'One honest line a day.'
            : journalToday == 0
                ? "Today isn't written yet."
                : 'Today is written · '
                    '$journalToday line${journalToday == 1 ? '' : 's'}',
        route: '/journal',
      ),
      _LibraryTileData(
        icon: AppIcons.habits,
        title: 'Habits',
        caption: habitCount == null
            ? 'Small daily supports.'
            : habitCount == 0
                ? 'Nothing to check off yet.'
                : '$doneToday of $habitCount done today',
        route: '/habits',
      ),
      _LibraryTileData(
        icon: AppIcons.ideas,
        title: 'Ideas',
        caption: ideas == null
            ? 'A parking lot for new ideas.'
            : dueCount > 0
                ? '$dueCount waiting on a decision'
                : coolingCount > 0
                    ? '$coolingCount cooling — parked for now'
                    : 'The lot is clear.',
        route: '/ideas',
        attention: dueCount > 0,
      ),
      _LibraryTileData(
        icon: AppIcons.reminders,
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
      _LibraryTileData(
        icon: AppIcons.settings,
        title: 'Settings',
        caption: 'Name, targets, backup & data.',
        route: '/settings',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.lg,
              AppSpace.screen,
              96,
            ),
            children: [
              TabPageHeader(
                title: name.isEmpty ? 'You' : name,
                subtitle: AppCopy.youTagline,
                showGlobalActions: false,
                actions: [
                  HeaderGlyphButton(
                    icon: AppIcons.search,
                    tooltip: 'Search everything',
                    onTap: () => SearchSheet.show(context),
                  ),
                ],
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
              const SectionHeader(title: 'Library'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpace.cardGap,
                crossAxisSpacing: AppSpace.cardGap,
                childAspectRatio: 1.3,
                children: [
                  for (final tile in tiles) _LibraryTile(data: tile),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryTileData {
  const _LibraryTileData({
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
}

/// One Library tile: glyph up top, name, live status line. The status
/// is the point — the grid reads as a dashboard of the quiet systems.
class _LibraryTile extends StatelessWidget {
  const _LibraryTile({required this.data});

  final _LibraryTileData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Pressable(
      onTap: () => context.push(data.route),
      haptic: PressHaptic.select,
      semanticLabel: data.title,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: scheme.outlineFaint),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: data.attention
                        ? AppColors.watch.withValues(alpha: 0.14)
                        : scheme.primaryTint,
                    borderRadius: BorderRadius.circular(AppRadius.chip + 2),
                  ),
                  child: Icon(
                    data.icon,
                    size: 17,
                    color:
                        data.attention ? AppColors.watch : AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (data.attention)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.watch,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(data.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              data.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
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
              AppIcons.review,
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
            AppIcons.forward,
            size: 16,
            color: scheme.textTertiary,
          ),
        ],
      ),
    );
  }
}
