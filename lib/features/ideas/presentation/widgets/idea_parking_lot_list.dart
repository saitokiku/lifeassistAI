import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../application/ideas_controller.dart';
import '../../application/ideas_state.dart';
import '../../domain/idea_decision.dart';
import '../../domain/parked_idea.dart';
import 'idea_capture_form.dart';
import 'idea_phrases.dart';
import 'idea_review_card.dart';
import 'idea_snacks.dart';

/// The parking lot in priority order: verdicts owed first, then cooling,
/// then the decided pile — collapsed, because history shouldn't weigh
/// more than work.
class IdeaParkingLotList extends StatefulWidget {
  const IdeaParkingLotList({super.key, required this.state});

  final IdeasState state;

  @override
  State<IdeaParkingLotList> createState() => _IdeaParkingLotListState();
}

class _IdeaParkingLotListState extends State<IdeaParkingLotList> {
  bool _showDecided = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state.ideas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpace.xxxl),
        child: EmptyState(
          icon: Icons.lightbulb_outline,
          title: 'The lot is empty.',
          message: 'Park the next idea that grabs you. '
              '${AppCopy.ideasCoolingExplainer}',
          actionLabel: 'Park an idea',
          onAction: () => IdeaCaptureForm.show(context),
        ),
      );
    }

    final decided = state.ideas
        .where((i) => i.decisionEnum != IdeaDecision.undecided)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.dueForReview.isNotEmpty) ...[
          const SectionHeader(title: 'Due for a verdict'),
          for (final idea in state.dueForReview)
            IdeaReviewCard(idea: idea, today: state.today),
        ],
        if (state.cooling.isNotEmpty) ...[
          const SectionHeader(title: 'Cooling'),
          for (final idea in state.cooling)
            IdeaReviewCard(idea: idea, today: state.today),
        ],
        if (decided.isNotEmpty) ...[
          SectionHeader(
            title: 'Decided (${decided.length})',
            trailing: TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                Haptics.select();
                setState(() => _showDecided = !_showDecided);
              },
              child: Text(_showDecided ? 'Hide' : 'Show'),
            ),
          ),
          if (_showDecided)
            for (final idea in decided)
              _DecidedRow(idea: idea, today: state.today),
        ],
      ],
    );
  }
}

/// A settled idea, kept compact. The only action is Reopen — re-deciding
/// goes back through the lot, so a stray tap can't silently overwrite a
/// past verdict.
class _DecidedRow extends ConsumerWidget {
  const _DecidedRow({required this.idea, required this.today});

  final ParkedIdea idea;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final decision = idea.decisionEnum;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    idea.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      StatusBadge(label: decision.label, level: decision.level),
                      const SizedBox(width: AppSpace.sm),
                      Flexible(
                        child: Text(
                          IdeaPhrases.parked(idea, today),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            TextButton(
              onPressed: () => _reopen(context, ref),
              child: const Text('Reopen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reopen(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(ideasControllerProvider);
    final previous = idea.decisionEnum;
    // Captured before the await — the row moves back into the lot (and
    // this widget unmounts) as soon as the write lands.
    final messenger = ScaffoldMessenger.of(context);
    final textTheme = Theme.of(context).textTheme;
    Haptics.light();
    try {
      await controller.setDecision(idea.id, IdeaDecision.undecided.name);
      showIdeaUndoSnack(
        messenger,
        textTheme,
        'Reopened. Back in the lot.',
        // Undo is a write too — it must be able to report failure.
        onUndo: () async {
          try {
            await controller.setDecision(idea.id, previous.name);
          } catch (_) {
            showIdeaErrorSnack(
                messenger, textTheme, "That didn't undo. Try again.");
          }
        },
      );
    } catch (_) {
      showIdeaErrorSnack(messenger, textTheme, "That didn't save. Try again.");
    }
  }
}
