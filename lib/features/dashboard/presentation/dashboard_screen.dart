import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capture/capture_launcher.dart';
import '../../../core/capture/capture_request.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/quick_add_sheet.dart';
import '../../../shared/widgets/section_header.dart';
import '../../focus/application/focus_controller.dart';
import '../../focus/presentation/widgets/growth_metric_entry_form.dart';
import '../../habits/application/habits_controller.dart';
import '../../journal/presentation/widgets/evening_journal_card.dart';
import '../../settings/domain/user_settings.dart';
import '../application/dashboard_controller.dart';
import '../application/dashboard_state.dart';
import 'widgets/check_in_strip.dart';
import 'widgets/goal_snapshot_card.dart';
import 'widgets/long_game_card.dart';
import 'widgets/loose_ends_card.dart';
import 'widgets/scoreboard_grid.dart';
import 'widgets/smart_capture_field.dart';
import 'widgets/today_header.dart';
import 'widgets/up_next_card.dart';

/// Today — one glance answers: what matters now, what needs attention,
/// and what's the best next action.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardStateProvider);
    final anyHabits =
        (ref.watch(habitsStateProvider)?.habits.isNotEmpty) ?? false;

    final showCheckIn =
        state != null && CheckInStrip.hasChips(state, anyHabits: anyHabits);
    final showScoreboard = state != null && ScoreboardGrid.hasTiles(state);
    final showGoalSnapshot = state?.goal != null;

    return Scaffold(
      floatingActionButton: state == null
          ? null
          : FloatingActionButton(
              tooltip: 'Quick add',
              onPressed: () => _quickAdd(context, ref, state),
              child: const Icon(Icons.add),
            ),
      body: SafeArea(
        child: state == null
            ? const SkeletonList()
            : ContentWidth(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.screen,
                    AppSpace.lg,
                    AppSpace.screen,
                    96,
                  ),
                  children: [
                    _Entrance(index: 0, child: TodayHeader(state: state)),
                    const SizedBox(height: AppSpace.xl),
                    _Entrance(index: 1, child: UpNextCard(state: state)),
                    // Renders nothing on devices without Apple Intelligence.
                    const SmartCaptureField(),
                    if (showCheckIn) ...[
                      const SectionHeader(title: 'Check-in'),
                      _Entrance(index: 2, child: CheckInStrip(state: state)),
                    ],
                    if (showScoreboard) ...[
                      const SectionHeader(title: 'This week'),
                      _Entrance(index: 3, child: ScoreboardGrid(state: state)),
                    ],
                    if (showGoalSnapshot) ...[
                      const SizedBox(height: AppSpace.sectionGap),
                      _Entrance(
                        index: 4,
                        child: GoalSnapshotCard(state: state),
                      ),
                    ],
                    if (state.showsArea(DashboardArea.money)) ...[
                      const SizedBox(height: AppSpace.cardGap),
                      _Entrance(index: 5, child: LongGameCard(state: state)),
                    ],
                    LooseEndsCard(state: state),
                    // Evening only: close the day with one journal line.
                    const EveningJournalCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _quickAdd(
    BuildContext context,
    WidgetRef ref,
    DashboardState state,
  ) async {
    // Only offer captures that exist right now.
    final actions = [
      if (state.goalActive) QuickAddAction.goalStep,
      if (state.showsArea(DashboardArea.money)) QuickAddAction.transaction,
      if (state.showsArea(DashboardArea.time)) QuickAddAction.timeBlock,
      if (state.goalActive && state.focus.activeMetric != null)
        QuickAddAction.metricValue,
      if (state.showsArea(DashboardArea.ideas)) QuickAddAction.idea,
    ];
    final action = await showQuickAddSheet(
      context,
      actions: actions.isEmpty ? QuickAddAction.values : actions,
    );
    if (action == null || !context.mounted) return;

    // Everything except the metric value rides the shared capture
    // dispatch — same path as deep links, shortcuts, and Siri.
    switch (action) {
      case QuickAddAction.timeBlock:
        await CaptureLauncher.open(
            context, ref, const CaptureRequest(type: CaptureType.time));
      case QuickAddAction.transaction:
        await CaptureLauncher.open(
            context, ref, const CaptureRequest(type: CaptureType.expense));
      case QuickAddAction.metricValue:
        final metric = ref.read(focusStateProvider)?.activeMetric;
        if (metric == null) {
          context.go('/focus');
          return;
        }
        await GrowthMetricEntryForm.show(context, metric: metric);
      case QuickAddAction.goalStep:
        await CaptureLauncher.open(
            context, ref, const CaptureRequest(type: CaptureType.step));
      case QuickAddAction.idea:
        await CaptureLauncher.open(
            context, ref, const CaptureRequest(type: CaptureType.idea));
    }
  }
}

/// Gentle once-per-mount entrance: fade + 12px rise, staggered 40ms.
/// Lives only on Today; the indexed-stack shell keeps it from re-firing
/// on tab switches. Skipped entirely when the platform asks for reduced
/// motion.
class _Entrance extends StatefulWidget {
  const _Entrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.emphasized,
  );
  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _controller, curve: AppMotion.easeOut);
  Timer? _stagger;

  @override
  void initState() {
    super.initState();
    // A cancellable timer, not Future.delayed — unmounting mid-stagger
    // must not leave a pending callback behind.
    _stagger = Timer(Duration(milliseconds: 40 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _stagger?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return widget.child;
    }
    return FadeTransition(
      opacity: _curve,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 12 * (1 - _curve.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
