import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/ai_service.dart';
import '../../../../core/capture/capture_request.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../habits/application/habits_controller.dart';
import '../../../money/application/money_controller.dart';
import '../../../time/application/time_controller.dart';

/// Natural-language capture, on-device (Foundation Models, iOS 26+).
///
/// "coffee 4.50 yesterday and 2h deep work" → chips, one per parsed
/// draft. Tapping a chip opens the SAME prefilled sheet manual capture
/// uses — the model proposes, the user confirms, nothing writes silently.
/// On devices without Apple Intelligence this widget renders nothing.
class SmartCaptureField extends ConsumerStatefulWidget {
  const SmartCaptureField({super.key});

  @override
  ConsumerState<SmartCaptureField> createState() => _SmartCaptureFieldState();
}

class _SmartCaptureFieldState extends ConsumerState<SmartCaptureField> {
  final _text = TextEditingController();
  List<AiCaptureDraft> _drafts = const [];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    final text = _text.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _drafts = const [];
    });
    try {
      final categories =
          ref.read(budgetCategoriesProvider).valueOrNull ?? const [];
      final budgets = ref.read(timeBudgetsProvider).valueOrNull ?? const [];
      final habits =
          ref.read(habitsStateProvider)?.habits ?? const [];
      final drafts = await ref.read(aiServiceProvider).parseCapture(
            text,
            categoryNames: [for (final c in categories) c.name],
            timeBudgetNames: [for (final b in budgets) b.name],
            habitNames: [for (final h in habits) h.habit.name],
          );
      if (!mounted) return;
      setState(() {
        _drafts = drafts;
        _error = drafts.isEmpty ? "Couldn't find anything to log." : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = "That didn't parse. Log it by hand.");
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openDraft(AiCaptureDraft draft) {
    Haptics.select();
    final type = switch (draft.kind) {
      'expense' => CaptureType.expense,
      'time' => CaptureType.time,
      'idea' => CaptureType.idea,
      'reminder' => CaptureType.reminder,
      // Habits check off in place — there's no sheet to prefill.
      'habit' => null,
      // Unreachable: AiCaptureDraft.tryParse rejects unknown kinds. If
      // one ever slipped through it must NOT land in the habit branch
      // (which used to share this arm and silently navigated the user
      // to the Habits tab).
      _ => null,
    };
    if (type == null) {
      if (draft.kind == 'habit') {
        ref.read(pendingRouteProvider.notifier).state = '/habits';
      }
      return;
    }
    ref.read(pendingCaptureProvider.notifier).state = CaptureRequest(
      type: type,
      amount:
          draft.amountCents == null ? null : draft.amountCents! / 100.0,
      hours: draft.hours,
      text: draft.text,
      category: draft.categoryName,
      dateKey: draft.dateIso,
    );
    setState(() =>
        _drafts = _drafts.where((d) => !identical(d, draft)).toList());
  }

  String _chipLabel(AiCaptureDraft d) {
    final parts = <String>[
      switch (d.kind) {
        'expense' => d.amountCents == null
            ? 'Expense'
            : '\$${(d.amountCents! / 100).toStringAsFixed(2)}',
        'time' => d.hours == null ? 'Time' : '${d.hours}h',
        'idea' => 'Idea',
        'reminder' => 'Reminder',
        'habit' => 'Habit',
        _ => d.kind,
      },
      if (d.categoryName != null) d.categoryName!,
      if (d.text != null && d.text!.isNotEmpty) d.text!,
    ];
    final label = parts.join(' · ');
    return label.length > 40 ? '${label.substring(0, 39)}…' : label;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final availability = ref.watch(aiAvailabilityProvider).valueOrNull;
    if (availability != AiAvailability.available) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.cardGap),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
          AppSpace.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: scheme.brandLabel),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: TextField(
                    controller: _text,
                    decoration: const InputDecoration(
                      hintText: 'Say it once: "coffee 4.50 and 2h deep work"',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _parse(),
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    tooltip: 'Parse with on-device AI',
                    visualDensity: VisualDensity.compact,
                    onPressed: _parse,
                    icon: Icon(Icons.arrow_upward_rounded,
                        size: 20, color: scheme.brandLabel),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                _error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.watch),
              ),
            ],
            if (_drafts.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final draft in _drafts)
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: Text(_chipLabel(draft)),
                      onPressed: () => _openDraft(draft),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Tap to review and save — nothing is logged until you '
                'confirm. On-device, nothing leaves the phone.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
