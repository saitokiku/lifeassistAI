import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/app_typography.dart';
import '../features/time/application/time_controller.dart';
import '../features/time/presentation/widgets/time_block_log_form.dart';
import '../shared/haptics.dart';
import 'app_icons.dart';
import 'pressable.dart';

/// The running focus timer, docked above the console bar on EVERY tab —
/// a timer you started must never be out of sight or out of reach.
/// Tapping the pill goes to Time; the square stops and opens the
/// prefilled log form. Renders nothing when no timer runs.
class TimerDock extends ConsumerStatefulWidget {
  const TimerDock({super.key});

  @override
  ConsumerState<TimerDock> createState() => _TimerDockState();
}

class _TimerDockState extends ConsumerState<TimerDock> {
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker(bool running) {
    if (running && _ticker == null) {
      _ticker =
          Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    } else if (!running && _ticker != null) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  String _elapsed(DateTime startedAt) {
    final d = DateTime.now().difference(startedAt);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  Future<void> _stop() async {
    final budgets =
        ref.read(timeBudgetsProvider).valueOrNull ?? const [];
    final result = await ref.read(timeControllerProvider).stopTimer();
    if (result == null || !mounted) return;
    Haptics.medium();
    await TimeBlockLogForm.show(
      context,
      budgets: budgets,
      initialBudgetId: result.budgetId,
      initialHours: result.hours,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final running = ref.watch(runningTimerProvider);
    _syncTicker(running != null);
    if (running == null) return const SizedBox.shrink();

    final budgets = ref.watch(timeBudgetsProvider).valueOrNull;
    final name = budgets
            ?.where((b) => b.id == running.budgetId)
            .map((b) => b.name)
            .firstOrNull ??
        'Focus';

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.xxl, 0, AppSpace.xxl, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Pressable(
                onTap: () => context.go('/time'),
                semanticLabel: 'Running timer: $name. Open Time.',
                dense: true,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.only(left: AppSpace.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _PulsingDot(),
                      const SizedBox(width: AppSpace.sm),
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Text(
                        _elapsed(running.startedAt),
                        style: theme.textTheme.numberBody.copyWith(
                          color: theme.brightness == Brightness.dark
                              ? AppColors.primaryBright
                              : AppColors.primaryDim,
                        ),
                      ),
                      Tooltip(
                        message: 'Stop timer',
                        child: Pressable(
                          onTap: _stop,
                          haptic: PressHaptic.medium,
                          semanticLabel: 'Stop timer',
                          dense: true,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpace.md,
                            ),
                            child: Icon(
                              AppIcons.done,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
      );
    }
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
