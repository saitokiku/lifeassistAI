import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/haptics.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../dashboard/application/dashboard_controller.dart';
import '../application/review_controller.dart';

/// The weekly review ritual: the week's real numbers, one honest
/// reflection, one emphasis for next week. Closes the capture → glance →
/// act → review loop.
class WeeklyReviewSheet extends ConsumerStatefulWidget {
  const WeeklyReviewSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showAppSheet<void>(context, builder: (_) => const WeeklyReviewSheet());

  @override
  ConsumerState<WeeklyReviewSheet> createState() => _WeeklyReviewSheetState();
}

class _WeeklyReviewSheetState extends ConsumerState<WeeklyReviewSheet> {
  final _reflection = TextEditingController();
  final _emphasis = TextEditingController();
  bool _seeded = false;
  bool _busy = false;

  @override
  void dispose() {
    _reflection.dispose();
    _emphasis.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    _busy = true;
    final navigator = Navigator.of(context);
    try {
      await ref.read(reviewControllerProvider).saveReview(
            weekOf: DateTime.now(),
            reflection: _reflection.text.trim(),
            emphasis: _emphasis.text.trim(),
          );
    } catch (_) {
      _busy = false;
      if (mounted) showErrorSnack(context, "That didn't save. Try again.");
      return;
    }
    Haptics.medium();
    if (!mounted) return;
    showSuccessSnack(context, 'Week closed. See you Monday.');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(dashboardStateProvider);
    final existing = ref.watch(currentWeekReviewProvider).valueOrNull;

    // Prefill once when editing an already-written review.
    if (!_seeded && existing != null) {
      _seeded = true;
      _reflection.text = existing.reflection;
      _emphasis.text = existing.emphasis;
    }

    final facts = <(String, String)>[
      if (state != null) ...[
        (
          'Hours on the goal',
          '${Formatters.hours(state.time.goalHoursThisWeek)} of '
              '${Formatters.hours(state.time.goalWeeklyTarget)}',
        ),
        (
          'Downtime',
          Formatters.hours(state.time.recoveryHoursThisWeek),
        ),
        if (state.settings.hasIncome)
          (
            'Money pace',
            '${Formatters.moneySigned(state.money.snapshot.projectedSurplus)} projected',
          ),
        (
          'Ideas awaiting a verdict',
          '${state.ideasDueForReview}',
        ),
      ],
    ];

    return AppSheet(
      title: 'Weekly review',
      subtitle: 'Five minutes: look at what happened, name what matters '
          'next. No grades.',
      footer: AppSheetButton(
        label: existing == null ? 'Close the week' : 'Update review',
        onPressed: _save,
      ),
      children: [
        if (facts.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              color: scheme.elevated,
              borderRadius: BorderRadius.circular(AppRadius.tile),
            ),
            child: Column(
              children: [
                for (final (i, fact) in facts.indexed) ...[
                  if (i > 0) const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fact.$1,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        fact.$2,
                        style: theme.textTheme.numberBody.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
        ],
        AppTextField(
          label: 'What happened this week?',
          hint: 'The honest version — wins, misses, surprises.',
          controller: _reflection,
          maxLines: 3,
        ),
        const SizedBox(height: AppSpace.md),
        AppTextField(
          label: 'Next week leans on…',
          hint: 'One emphasis, not a plan.',
          controller: _emphasis,
          maxLines: 2,
        ),
        if (existing != null) ...[
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 14, color: AppColors.aligned),
              const SizedBox(width: 6),
              Text(
                'Already written this week — editing updates it.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
