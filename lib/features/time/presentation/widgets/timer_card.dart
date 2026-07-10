import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../application/time_controller.dart';
import '../../domain/time_category.dart';
import 'time_block_log_form.dart';
import 'time_kind_icon.dart';

/// The focus timer: start it against a category, stop it into a prefilled
/// log entry. Survives app restarts via SharedPreferences.
class TimerCard extends ConsumerStatefulWidget {
  const TimerCard({super.key, required this.budgets});

  final List<TimeBudget> budgets;

  @override
  ConsumerState<TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends ConsumerState<TimerCard> {
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker(bool running) {
    if (running && _ticker == null) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    } else if (!running && _ticker != null) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  Future<void> _start() async {
    if (widget.budgets.isEmpty) return;
    final budgetId = await showAppSheet<String>(
      context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return AppSheet(
          title: 'Time what?',
          children: [
            for (final b in widget.budgets)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  TimeCategoryKind.parse(b.kind).icon,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(b.name),
                onTap: () => Navigator.of(sheetContext).pop(b.id),
              ),
          ],
        );
      },
    );
    if (budgetId == null) return;
    Haptics.medium();
    await ref.read(timeControllerProvider).startTimer(budgetId);
  }

  Future<void> _stop() async {
    final result = await ref.read(timeControllerProvider).stopTimer();
    if (result == null || !mounted) return;
    Haptics.medium();
    await TimeBlockLogForm.show(
      context,
      budgets: widget.budgets,
      initialBudgetId: result.budgetId,
      initialHours: result.hours,
    );
  }

  String _elapsedLabel(DateTime startedAt) {
    final d = DateTime.now().difference(startedAt);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final running = ref.watch(runningTimerProvider);
    _syncTicker(running != null);

    if (running == null) {
      if (widget.budgets.isEmpty) return const SizedBox.shrink();
      return AppCard(
        onTap: _start,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Row(
          children: [
            Icon(Icons.timer_outlined,
                size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                'Start a focus timer',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Icon(Icons.play_arrow_rounded,
                size: 22, color: scheme.brandLabel),
          ],
        ),
      );
    }

    final budget =
        widget.budgets.where((b) => b.id == running.budgetId).firstOrNull;

    return AppCard(
      tinted: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 20, color: scheme.brandLabel),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _elapsedLabel(running.startedAt),
                  style: theme.textTheme.numberMedium.copyWith(fontSize: 22),
                ),
                Text(
                  budget?.name ?? 'Timing…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.critical,
              minimumSize: const Size(64, 38),
            ),
            onPressed: _stop,
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }
}
