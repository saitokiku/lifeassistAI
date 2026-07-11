import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../application/journal_controller.dart';
import 'journal_entry_sheet.dart';

/// Evening-only Today card: close the day with one journal line. Says
/// honestly when the day is already written, and renders nothing at all
/// before evening — mornings are for starting, not summarizing.
class EveningJournalCard extends ConsumerWidget {
  const EveningJournalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayPart = ref.watch(dayPartProvider);
    if (dayPart != DayPart.evening) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final todayCount =
        ref.watch(todayJournalProvider).valueOrNull?.length ?? 0;
    final written = todayCount > 0;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.cardGap),
      child: AppCard(
        onTap: () => JournalEntrySheet.show(context),
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
                Icons.edit_note_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    written ? 'Today is written' : 'Close the day',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    written
                        ? '$todayCount line${todayCount == 1 ? '' : 's'} in '
                            'the journal. Add another if the day earned it.'
                        : 'One honest line about today. That counts as done.',
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
      ),
    );
  }
}
