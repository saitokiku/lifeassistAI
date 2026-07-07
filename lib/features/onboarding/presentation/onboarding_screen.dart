import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/default_targets.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validation.dart';
import '../../../routing/app_router.dart';
import '../../../shared/widgets/app_number_field.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../kaizen/application/kaizen_controller.dart';
import '../../reminders/application/reminders_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../../time/application/time_controller.dart';
import '../../time/domain/time_category.dart';

/// First-launch onboarding. Collects the numbers that drive the dashboard;
/// fully skippable — sensible defaults are already seeded either way.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  // Step 1: money
  final _moneyFormKey = GlobalKey<FormState>();
  final _income =
      TextEditingController(text: DefaultTargets.monthlyNetIncome.toString());
  final _surplusLow =
      TextEditingController(text: DefaultTargets.targetSurplusLow.toString());
  final _surplusHigh =
      TextEditingController(text: DefaultTargets.targetSurplusHigh.toString());

  // Step 2: kaizen
  final _kaizenFormKey = GlobalKey<FormState>();
  final _kaizenTarget = TextEditingController(
      text: DefaultTargets.weeklyKaizenHoursTarget.toString());
  final _metricName =
      TextEditingController(text: DefaultTargets.defaultGrowthMetricName);
  final _metricUnit =
      TextEditingController(text: DefaultTargets.defaultGrowthMetricUnit);

  // Step 3: profile & reminders
  DateTime? _birthday;
  TimeOfDay _morning = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _night = const TimeOfDay(hour: 22, minute: 0);
  bool _enableNotifications = true;

  @override
  void dispose() {
    _pageController.dispose();
    _income.dispose();
    _surplusLow.dispose();
    _surplusHigh.dispose();
    _kaizenTarget.dispose();
    _metricName.dispose();
    _metricUnit.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page == 1 && !(_moneyFormKey.currentState?.validate() ?? true)) {
      return;
    }
    if (_page == 2 && !(_kaizenFormKey.currentState?.validate() ?? true)) {
      return;
    }
    if (_page < 3) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      await _finish(applyInputs: true);
    }
  }

  /// Persists onboarding answers into the already-seeded records, marks
  /// onboarding complete, and goes to the dashboard.
  Future<void> _finish({required bool applyInputs}) async {
    final router = GoRouter.of(context);

    if (applyInputs) {
      final settings = ref.read(settingsControllerProvider);
      await settings
          .setMonthlyNetIncome(Validators.parseNumber(_income.text));
      await settings.setTargetSurplus(
        low: Validators.parseNumber(_surplusLow.text),
        high: Validators.parseNumber(_surplusHigh.text),
      );
      if (_birthday != null) await settings.setBirthday(_birthday);

      // Kaizen weekly hours live on the Kaizen time budget row.
      final db = ref.read(databaseProvider);
      final budgets = await db.select(db.timeBudgets).get();
      for (final budget in budgets) {
        if (TimeCategoryKind.parse(budget.kind) == TimeCategoryKind.kaizen) {
          await ref.read(timeControllerProvider).updateBudget(
                budget.copyWith(
                  weeklyTargetHours: Validators.parseNumber(_kaizenTarget.text),
                ),
              );
        }
      }

      // Rename the seeded active metric to the user's chosen hunt.
      final metrics = await db.select(db.growthMetrics).get();
      for (final metric in metrics.where((m) => m.isActive)) {
        await ref.read(kaizenControllerProvider).updateMetric(
              metric.copyWith(
                name: _metricName.text.trim().isEmpty
                    ? metric.name
                    : _metricName.text.trim(),
                unit: _metricUnit.text.trim().isEmpty
                    ? metric.unit
                    : _metricUnit.text.trim(),
              ),
            );
      }

      // Morning command / night review times.
      final reminders = await db.select(db.reminders).get();
      for (final reminder in reminders) {
        if (reminder.type == 'morningCommand') {
          await db.update(db.reminders).replace(reminder.copyWith(
              hour: _morning.hour,
              minute: _morning.minute,
              updatedAt: DateTime.now()));
        } else if (reminder.type == 'nightReview') {
          await db.update(db.reminders).replace(reminder.copyWith(
              hour: _night.hour,
              minute: _night.minute,
              updatedAt: DateTime.now()));
        }
      }

      if (_enableNotifications) {
        await ref.read(remindersControllerProvider).enableNotifications();
      }
    }

    await ref.read(preferencesProvider).setOnboardingComplete(true);
    ref.invalidate(appRouterProvider);
    router.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextButton(
                  onPressed: () => _finish(applyInputs: false),
                  child: const Text('Skip — use defaults'),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _intro(theme),
                  _moneyStep(theme),
                  _kaizenStep(theme),
                  _profileStep(theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('${_page + 1} / 4', style: theme.textTheme.bodySmall),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(_page == 3 ? 'Start' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wrap(List<Widget> children) => ListView(
        padding: const EdgeInsets.all(24),
        children: children,
      );

  Widget _intro(ThemeData theme) => _wrap([
        const SizedBox(height: 24),
        Text('Life Dashboard', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          AppConstants.philosophyLine,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'This is an operator dashboard, not a habit tracker. '
          'It keeps hours and money pointed at the one thing that compounds — '
          'Kaizen growth — while protecting the recovery floor.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'Four quick steps. Everything is editable later. Skip anytime — '
          'sensible defaults are already in place.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ]);

  Widget _moneyStep(ThemeData theme) => _wrap([
        Text('Money', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(AppCopy.moneyScoreboard, style: theme.textTheme.bodySmall),
        const SizedBox(height: 20),
        Form(
          key: _moneyFormKey,
          child: Column(
            children: [
              AppNumberField(
                label: 'Net monthly income',
                controller: _income,
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Income'),
              ),
              const SizedBox(height: 12),
              AppNumberField(
                label: 'Target surplus (low)',
                controller: _surplusLow,
                validator: (v) => Validators.number(v, label: 'Low'),
              ),
              const SizedBox(height: 12),
              AppNumberField(
                label: 'Target surplus (high)',
                controller: _surplusHigh,
                validator: (v) => Validators.number(v, label: 'High'),
              ),
            ],
          ),
        ),
      ]);

  Widget _kaizenStep(ThemeData theme) => _wrap([
        Text('Kaizen', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(AppCopy.oneHunt, style: theme.textTheme.bodySmall),
        const SizedBox(height: 20),
        Form(
          key: _kaizenFormKey,
          child: Column(
            children: [
              AppNumberField(
                label: 'Weekly Kaizen hours target',
                controller: _kaizenTarget,
                suffixText: 'h',
                validator: (v) =>
                    Validators.positiveNumber(v, label: 'Target'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Active growth metric',
                controller: _metricName,
                validator: (v) => Validators.required(v, label: 'Metric'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Metric unit',
                controller: _metricUnit,
                validator: (v) => Validators.required(v, label: 'Unit'),
              ),
            ],
          ),
        ),
      ]);

  Widget _profileStep(ThemeData theme) => _wrap([
        Text('Rhythm', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(AppCopy.recoveryLoadBearing, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.cake_outlined),
          title: Text(_birthday == null
              ? 'Birthday (for the age-${AppConstants.lockInAge} countdown)'
              : Formatters.fullDate(_birthday!)),
          trailing: TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _birthday ?? DateTime(1999),
                firstDate: DateTime(1940),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _birthday = picked);
            },
            child: const Text('Set'),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.wb_sunny_outlined),
          title: Text('Morning command · ${_morning.format(context)}'),
          trailing: TextButton(
            onPressed: () async {
              final picked = await showTimePicker(
                  context: context, initialTime: _morning);
              if (picked != null) setState(() => _morning = picked);
            },
            child: const Text('Change'),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.nightlight_outlined),
          title: Text('Night review · ${_night.format(context)}'),
          trailing: TextButton(
            onPressed: () async {
              final picked =
                  await showTimePicker(context: context, initialTime: _night);
              if (picked != null) setState(() => _night = picked);
            },
            child: const Text('Change'),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable notifications'),
          subtitle: const Text('Asks for OS permission on Start.'),
          value: _enableNotifications,
          onChanged: (v) => setState(() => _enableNotifications = v),
        ),
      ]);
}
