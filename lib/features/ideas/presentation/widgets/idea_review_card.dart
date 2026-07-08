import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../application/ideas_controller.dart';
import '../../domain/idea_decision.dart';
import '../../domain/parked_idea.dart';
import 'idea_capture_form.dart';
import 'idea_phrases.dart';
import 'idea_snacks.dart';

/// One undecided idea: full detail when due for a verdict, compact while
/// cooling. The verdict row is the whole point — semantic colors, real
/// feedback, and a lock that means it.
class IdeaReviewCard extends ConsumerWidget {
  const IdeaReviewCard({super.key, required this.idea, required this.today});

  final ParkedIdea idea;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final decision = idea.decisionEnum;
    final cooling = idea.isCooling(today);
    final due = decision == IdeaDecision.undecided && !cooling;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.cardGap),
      child: AppCard(
        onTap: () => IdeaCaptureForm.show(context, idea: idea),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(idea.title, style: theme.textTheme.titleMedium),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                if (decision != IdeaDecision.undecided)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: StatusBadge(
                      label: decision.label,
                      level: decision.level,
                    ),
                  ),
                _OverflowMenu(idea: idea),
              ],
            ),
            if (due) ..._dueBody(theme, scheme),
            if (cooling && decision == IdeaDecision.undecided)
              ..._coolingBody(theme),
            if (decision == IdeaDecision.undecided) ...[
              const SizedBox(height: AppSpace.md),
              _verdictRow(context, ref, cooling: cooling),
            ],
          ],
        ),
      ),
    );
  }

  /// Everything a verdict needs: the pitch, the pull, the payoff, the age.
  List<Widget> _dueBody(ThemeData theme, ColorScheme scheme) {
    return [
      if (idea.description?.isNotEmpty ?? false) ...[
        const SizedBox(height: 6),
        Text(
          idea.description!,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
      if (idea.whyTempting?.isNotEmpty ?? false) ...[
        const SizedBox(height: 6),
        _FactLine(label: 'Tempting because', text: idea.whyTempting!),
      ],
      if (idea.potentialValue?.isNotEmpty ?? false) ...[
        const SizedBox(height: 6),
        _FactLine(label: 'Potential value', text: idea.potentialValue!),
      ],
      const SizedBox(height: 10),
      Text(
        [
          if (idea.category?.isNotEmpty ?? false) idea.category!,
          IdeaPhrases.parked(idea, today),
          IdeaPhrases.due(idea, today),
        ].join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.textTertiary,
        ),
      ),
    ];
  }

  /// While cooling the card stays compact — captured, not chased. The
  /// progress bar carries age and countdown in one quiet line.
  List<Widget> _coolingBody(ThemeData theme) {
    return [
      if (idea.directlyHelpsKaizenThisWeek) ...[
        const SizedBox(height: AppSpace.sm),
        const StatusBadge(
          label: 'Helps the hunt — can integrate now',
          level: StatusLevel.aligned,
        ),
      ],
      const SizedBox(height: AppSpace.md),
      LabeledProgressBar(
        progress: IdeaPhrases.coolingProgress(idea, today),
        color: AppColors.neutral,
        height: 4,
        leading: IdeaPhrases.parked(idea, today),
        trailing: IdeaPhrases.verdictIn(idea, today),
      ),
    ];
  }

  /// Three verdicts, each in its semantic color.
  ///
  /// During cooling, Ignore and Later drop to text-button weight — early
  /// verdicts are allowed (kill obvious noise on sight), not encouraged;
  /// the ritual is to let ideas cool. Integrate is the gated one: the
  /// repository does NOT enforce `canActivate`, so this lock IS the
  /// anti-diffusion rule.
  Widget _verdictRow(BuildContext context, WidgetRef ref,
      {required bool cooling}) {
    final canActivate = idea.canActivate(today);

    Widget verdict(IdeaDecision d, IconData icon, {required bool emphasized}) {
      return _VerdictButton(
        label: d.label,
        icon: icon,
        color: d.color,
        emphasized: emphasized,
        onTap: () => _decide(context, ref, d),
      );
    }

    return Row(
      children: [
        Expanded(
          child: verdict(
            IdeaDecision.ignore,
            Icons.close_rounded,
            emphasized: !cooling,
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: verdict(
            IdeaDecision.later,
            Icons.schedule_rounded,
            emphasized: !cooling,
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: canActivate
              ? verdict(
                  IdeaDecision.integrate,
                  Icons.call_merge_rounded,
                  emphasized: true,
                )
              : _LockedIntegrate(daysLeft: idea.daysUntilReview(today)),
        ),
      ],
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    IdeaDecision d,
  ) async {
    final controller = ref.read(ideasControllerProvider);
    // Captured before the await: the drift stream regroups (and disposes)
    // this card the moment the decision lands.
    final messenger = ScaffoldMessenger.of(context);
    final textTheme = Theme.of(context).textTheme;
    Haptics.medium();
    try {
      await controller.setDecision(idea.id, d.name);
      showIdeaUndoSnack(
        messenger,
        textTheme,
        'Marked ${d.label.toLowerCase()}.',
        // Undo is a write too — it must be able to report failure.
        onUndo: () async {
          try {
            await controller.setDecision(
                idea.id, IdeaDecision.undecided.name);
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

/// Edit and delete, kept quiet but visible. Delete is a hard delete —
/// it earns a confirm sheet, no undo pretense.
class _OverflowMenu extends ConsumerWidget {
  const _OverflowMenu({required this.idea});

  final ParkedIdea idea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      tooltip: 'More',
      onSelected: (value) async {
        if (value == 'edit') {
          await IdeaCaptureForm.show(context, idea: idea);
        } else if (value == 'delete') {
          await _delete(context, ref);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            'Delete',
            style: TextStyle(color: AppColors.critical),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(Icons.more_horiz, size: 20, color: scheme.textTertiary),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(ideasControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final textTheme = Theme.of(context).textTheme;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete idea?',
      message: 'Removes "${idea.title}" from the lot. This one has no undo.',
    );
    if (!confirmed) return;
    try {
      await controller.deleteIdea(idea.id);
      showIdeaSuccessSnack(messenger, textTheme, 'Deleted.');
    } catch (_) {
      showIdeaErrorSnack(
          messenger, textTheme, "That didn't delete. Try again.");
    }
  }
}

/// 'Label — detail' line for the reflective prompts captured at parking
/// time. Potential value finally gets its moment — it's exactly what a
/// verdict needs.
class _FactLine extends StatelessWidget {
  const _FactLine({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label — ',
            style: style?.copyWith(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: text),
        ],
      ),
      style: style,
    );
  }
}

/// A verdict action. Emphasized = tinted pill in the verdict's semantic
/// color; otherwise text-button weight for de-emphasized early verdicts.
class _VerdictButton extends StatelessWidget {
  const _VerdictButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.emphasized = true,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!emphasized) {
      return TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon, size: 15),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
    }

    return Material(
      color: color.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Integrate, explicitly locked: a lock and the days remaining — never a
/// bare disabled chip that just looks broken.
class _LockedIntegrate extends StatelessWidget {
  const _LockedIntegrate({required this.daysLeft});

  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final days = daysLeft < 1 ? 1 : daysLeft;

    return Tooltip(
      message:
          'Unlocks when cooling ends — or when it directly helps the hunt '
          'this week.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: scheme.elevated,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: scheme.outlineFaint),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 13, color: scheme.textTertiary),
                const SizedBox(width: 4),
                Text(
                  'Cooling · $days day${days == 1 ? '' : 's'} left',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
