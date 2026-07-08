import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/quick_add_sheet.dart';
import '../../../shared/widgets/section_header.dart';
import '../../ideas/presentation/widgets/idea_capture_form.dart';
import '../../kaizen/application/kaizen_controller.dart';
import '../../kaizen/presentation/widgets/experiment_log_form.dart';
import '../../kaizen/presentation/widgets/growth_metric_entry_form.dart';
import '../../money/application/money_controller.dart';
import '../../money/presentation/widgets/transaction_entry_form.dart';
import '../../time/application/time_controller.dart';
import '../../time/presentation/widgets/time_block_log_form.dart';
import '../application/dashboard_controller.dart';
import 'widgets/check_in_strip.dart';
import 'widgets/focus_card.dart';
import 'widgets/freedom_progress_card.dart';
import 'widgets/growth_metric_overview_card.dart';
import 'widgets/loose_ends_card.dart';
import 'widgets/scoreboard_grid.dart';
import 'widgets/today_header.dart';

/// Today — the command center. One glance answers: what matters now,
/// what's slipping, and what's the next useful action.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardStateProvider);

    return Scaffold(
      floatingActionButton: state == null
          ? null
          : FloatingActionButton(
              tooltip: 'Quick add',
              onPressed: () => _quickAdd(context, ref),
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
                    _Entrance(index: 1, child: FocusCard(state: state)),
                    const SectionHeader(title: 'Check-in'),
                    _Entrance(index: 2, child: CheckInStrip(state: state)),
                    const SectionHeader(title: 'Scoreboard'),
                    _Entrance(index: 3, child: ScoreboardGrid(state: state)),
                    const SizedBox(height: AppSpace.cardGap),
                    _Entrance(
                      index: 4,
                      child: GrowthMetricOverviewCard(state: state),
                    ),
                    const SizedBox(height: AppSpace.cardGap),
                    _Entrance(
                      index: 5,
                      child: FreedomProgressCard(state: state),
                    ),
                    LooseEndsCard(state: state),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _quickAdd(BuildContext context, WidgetRef ref) async {
    final action = await showQuickAddSheet(context);
    if (action == null || !context.mounted) return;

    switch (action) {
      case QuickAddAction.timeBlock:
        final time = ref.read(timeStateProvider);
        if (time == null) return;
        await TimeBlockLogForm.show(context, budgets: time.budgets);
      case QuickAddAction.transaction:
        final money = ref.read(moneyStateProvider);
        if (money == null) return;
        await TransactionEntryForm.show(context,
            categories: money.categories);
      case QuickAddAction.metricValue:
        final kaizen = ref.read(kaizenStateProvider);
        final metric = kaizen?.activeMetric;
        if (metric == null) {
          context.go('/kaizen');
          return;
        }
        await GrowthMetricEntryForm.show(context, metric: metric);
      case QuickAddAction.experiment:
        final kaizen = ref.read(kaizenStateProvider);
        await ExperimentLogForm.show(context,
            experiment: kaizen?.todayExperiment);
      case QuickAddAction.idea:
        await IdeaCaptureForm.show(context);
    }
  }
}

/// Gentle once-per-mount entrance: fade + 12px rise, staggered 40ms.
/// Lives only on Today; the indexed-stack shell keeps it from re-firing
/// on tab switches.
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

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 40 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
