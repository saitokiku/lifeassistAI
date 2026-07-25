import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../habits/application/habits_controller.dart';
import '../../journal/presentation/widgets/evening_journal_card.dart';
import '../../settings/domain/user_settings.dart';
import '../application/dashboard_controller.dart';
import 'widgets/check_in_strip.dart';
import 'widgets/discover_card.dart';
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
    final hasError = ref.watch(dashboardHasErrorProvider);
    final anyHabits =
        (ref.watch(habitsStateProvider)?.habits.isNotEmpty) ?? false;

    // A failed stream must not render as a calm day of zeros — Today
    // aggregates everything, so it is the screen most able to lie.
    if (state == null && hasError) {
      return Scaffold(
        body: SafeArea(
          child: ContentWidth(
            child: ErrorState(
              title: "Today didn't load.",
              message: AppCopy.dataSafeRetry,
              onRetry: () => refreshDashboard(ref),
            ),
          ),
        ),
      );
    }

    final showCheckIn =
        state != null && CheckInStrip.hasChips(state, anyHabits: anyHabits);
    final showScoreboard = state != null && ScoreboardGrid.hasTiles(state);
    final showGoalSnapshot = state?.goal != null;

    // Capture lives in the console bar's center button now — no FAB.
    return Scaffold(
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
                    // One-time launch tour; disappears once dismissed.
                    const DiscoverCard(),
                  ],
                ),
              ),
      ),
    );
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
