import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/loading_view.dart';
import '../application/dashboard_controller.dart';
import 'widgets/experiment_status_card.dart';
import 'widgets/focus_integrity_card.dart';
import 'widgets/freedom_progress_card.dart';
import 'widgets/growth_metric_overview_card.dart';
import 'widgets/kaizen_overview_card.dart';
import 'widgets/money_overview_card.dart';
import 'widgets/philosophy_header.dart';
import 'widgets/recovery_floor_card.dart';
import 'widgets/today_command_card.dart';

/// The operator dashboard. One glance: am I pointing hours and money at the
/// thing that compounds, and am I sustainable?
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardStateProvider);

    return Scaffold(
      body: SafeArea(
        child: state == null
            ? const LoadingView()
            : ContentWidth(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    PhilosophyHeader(
                      philosophyText: state.identity.philosophyText,
                    ),
                    const SizedBox(height: 16),
                    TodayCommandCard(command: state.command),
                    const SizedBox(height: 12),
                    KaizenOverviewCard(state: state),
                    const SizedBox(height: 12),
                    GrowthMetricOverviewCard(state: state),
                    const SizedBox(height: 12),
                    ExperimentStatusCard(state: state),
                    const SizedBox(height: 12),
                    MoneyOverviewCard(state: state),
                    const SizedBox(height: 12),
                    RecoveryFloorCard(state: state),
                    const SizedBox(height: 12),
                    FocusIntegrityCard(state: state),
                    const SizedBox(height: 12),
                    FreedomProgressCard(state: state),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}
