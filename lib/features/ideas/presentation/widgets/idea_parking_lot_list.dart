import 'package:flutter/material.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../application/ideas_state.dart';
import '../../domain/idea_decision.dart';
import '../../domain/parked_idea.dart';
import 'idea_capture_form.dart';
import 'idea_review_card.dart';

/// The parking lot: due-for-review first, then cooling, then decided.
class IdeaParkingLotList extends StatelessWidget {
  const IdeaParkingLotList({super.key, required this.state});

  final IdeasState state;

  @override
  Widget build(BuildContext context) {
    if (state.ideas.isEmpty) {
      return EmptyState(
        icon: Icons.lightbulb_outline,
        title: 'Parking lot is empty',
        message: 'Curiosity captured. Not chased. Park the next shiny thing.',
        actionLabel: 'Park an idea',
        onAction: () => IdeaCaptureForm.show(context),
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
          const SectionHeader(title: 'Cooling off'),
          for (final idea in state.cooling)
            IdeaReviewCard(idea: idea, today: state.today),
        ],
        if (decided.isNotEmpty) ...[
          const SectionHeader(title: 'Decided'),
          for (final idea in decided)
            IdeaReviewCard(idea: idea, today: state.today),
        ],
      ],
    );
  }
}
