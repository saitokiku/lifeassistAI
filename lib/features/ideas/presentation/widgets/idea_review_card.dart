import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../application/ideas_controller.dart';
import '../../domain/idea_decision.dart';
import '../../domain/parked_idea.dart';
import 'idea_capture_form.dart';

/// One parked idea with cooling state and decision actions.
class IdeaReviewCard extends ConsumerWidget {
  const IdeaReviewCard({super.key, required this.idea, required this.today});

  final ParkedIdea idea;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cooling = idea.isCooling(today);
    final canActivate = idea.canActivate(today);
    final decision = idea.decisionEnum;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(idea.title, style: theme.textTheme.titleSmall),
                ),
                if (decision != IdeaDecision.undecided)
                  StatusBadge(
                    label: decision.label,
                    level: switch (decision) {
                      IdeaDecision.integrate => StatusLevel.aligned,
                      IdeaDecision.later => StatusLevel.watch,
                      IdeaDecision.ignore => StatusLevel.critical,
                      IdeaDecision.undecided => StatusLevel.neutral,
                    },
                  )
                else if (cooling)
                  StatusBadge(
                    label:
                        'Cooling · ${idea.daysUntilReview(today)}d',
                    level: StatusLevel.neutral,
                  )
                else
                  const StatusBadge(label: 'Review due', level: StatusLevel.watch),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await IdeaCaptureForm.show(context, idea: idea);
                    } else if (value == 'delete') {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: 'Delete idea?',
                        message: 'Removes "${idea.title}" from the lot.',
                      );
                      if (confirmed) {
                        await ref
                            .read(ideasControllerProvider)
                            .deleteIdea(idea.id);
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
            if (idea.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              Text(idea.description!,
                  style: theme.textTheme.bodySmall, maxLines: 3),
            ],
            const SizedBox(height: 4),
            Text(
              [
                if (idea.category?.isNotEmpty ?? false) idea.category!,
                'captured ${idea.dateCaptured}',
                'review ${idea.reviewDate}',
                if (idea.directlyHelpsKaizenThisWeek) 'helps Kaizen this week',
              ].join(' · '),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (idea.whyTempting?.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              Text('Tempting because: ${idea.whyTempting}',
                  style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final d in [
                  IdeaDecision.ignore,
                  IdeaDecision.later,
                  IdeaDecision.integrate,
                ])
                  ActionChip(
                    label: Text(d.label),
                    onPressed: d == IdeaDecision.integrate && !canActivate
                        ? null
                        : () async {
                            await ref
                                .read(ideasControllerProvider)
                                .setDecision(idea.id, d.name);
                          },
                  ),
                if (decision != IdeaDecision.undecided)
                  ActionChip(
                    label: const Text('Reopen'),
                    onPressed: () async {
                      await ref.read(ideasControllerProvider).setDecision(
                          idea.id, IdeaDecision.undecided.name);
                    },
                  ),
              ],
            ),
            if (!canActivate) ...[
              const SizedBox(height: 6),
              Text(
                'Integrate unlocks when cooling ends or it directly helps Kaizen this week.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
