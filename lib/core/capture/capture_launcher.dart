import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/application/dashboard_controller.dart';
import '../../features/settings/domain/user_settings.dart';
import '../../features/focus/application/focus_controller.dart';
import '../../features/focus/presentation/widgets/growth_metric_entry_form.dart';
import '../../shared/widgets/quick_add_sheet.dart';
import '../../features/focus/presentation/widgets/action_log_form.dart';
import '../../features/ideas/presentation/widgets/idea_capture_form.dart';
import '../../features/money/application/money_controller.dart';
import '../../features/money/presentation/widgets/transaction_entry_form.dart';
import '../../features/reminders/presentation/widgets/reminder_editor.dart';
import '../../features/time/application/time_controller.dart';
import '../../features/time/presentation/widgets/time_block_log_form.dart';
import 'capture_request.dart';
import 'name_resolver.dart';

/// Opens the sheet a [CaptureRequest] asks for, prefilled.
///
/// This is the single dispatch behind deep links, app shortcuts, notification
/// taps, and Siri. It AWAITS each provider's first value instead of bailing
/// when a cold-started stream hasn't emitted yet — the old quick-add switch
/// silently dropped captures during startup, which is fatal for voice input
/// (the user has already put the phone away).
class CaptureLauncher {
  CaptureLauncher._();

  /// The tab that owns each capture type — deep links land there first so
  /// the sheet dismisses onto relevant context.
  static String tabFor(CaptureType type) => switch (type) {
        CaptureType.expense => '/money',
        CaptureType.time => '/time',
        CaptureType.step => '/focus',
        CaptureType.idea => '/ideas',
        CaptureType.reminder => '/reminders',
      };

  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    CaptureRequest request,
  ) async {
    switch (request.type) {
      case CaptureType.expense:
        final categories = await ref.read(budgetCategoriesProvider.future);
        if (!context.mounted) return;
        await TransactionEntryForm.show(
          context,
          categories: categories,
          initialAmount: request.amount,
          initialDescription: request.text,
          initialCategoryId:
              resolveByName(request.category, {for (final c in categories) c.id: c.name}),
        );
      case CaptureType.time:
        final budgets = await ref.read(timeBudgetsProvider.future);
        if (!context.mounted) return;
        await TimeBlockLogForm.show(
          context,
          budgets: budgets,
          initialBudgetId:
              resolveByName(request.category, {for (final b in budgets) b.id: b.name}),
          initialHours: request.hours,
          initialNote: request.text,
        );
      case CaptureType.step:
        // Await the actions stream so "already logged today" resolves to
        // an edit instead of a duplicate, even on cold start.
        await ref.read(dailyActionsProvider.future);
        if (!context.mounted) return;
        final todayAction = ref.read(focusStateProvider)?.todayAction;
        await ActionLogForm.show(
          context,
          action: todayAction,
          initialActionText: request.text,
        );
      case CaptureType.idea:
        await IdeaCaptureForm.show(context, initialTitle: request.text);
      case CaptureType.reminder:
        await ReminderEditor.show(
          context,
          initialTitle: request.text,
          initialHour: request.hour,
          initialMinute: request.minute,
        );
    }
  }

  /// The console capture button's dispatch: offer the captures that
  /// exist right now (mirrors the old Today FAB), then ride the shared
  /// capture path. This is the seam the Capture Inbox replaces later.
  static Future<void> quickAdd(BuildContext context, WidgetRef ref) async {
    final state = ref.read(dashboardStateProvider);
    final actions = state == null
        ? QuickAddAction.values
        : [
            if (state.goalActive) QuickAddAction.goalStep,
            if (state.showsArea(DashboardArea.money))
              QuickAddAction.transaction,
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

    switch (action) {
      case QuickAddAction.timeBlock:
        await open(context, ref, const CaptureRequest(type: CaptureType.time));
      case QuickAddAction.transaction:
        await open(
            context, ref, const CaptureRequest(type: CaptureType.expense));
      case QuickAddAction.metricValue:
        final metric = ref.read(focusStateProvider)?.activeMetric;
        if (metric == null) {
          if (context.mounted) GoRouter.of(context).go('/focus');
          return;
        }
        await GrowthMetricEntryForm.show(context, metric: metric);
      case QuickAddAction.goalStep:
        await open(context, ref, const CaptureRequest(type: CaptureType.step));
      case QuickAddAction.idea:
        await open(context, ref, const CaptureRequest(type: CaptureType.idea));
    }
  }
}
