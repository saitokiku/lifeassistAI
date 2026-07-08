import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/default_targets.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validation.dart';
import '../../../routing/app_router.dart';
import '../../../shared/haptics.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/app_card.dart';
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

  /// Highest page the user may swipe to; raised by Next after validation.
  int _maxAllowedPage = 0;
  bool _finishing = false;

  // Page 2: money
  final _moneyFormKey = GlobalKey<FormState>();
  final _income = TextEditingController(
    text: Formatters.number(DefaultTargets.monthlyNetIncome),
  );
  final _surplusLow = TextEditingController(
    text: Formatters.number(DefaultTargets.targetSurplusLow),
  );
  final _surplusHigh = TextEditingController(
    text: Formatters.number(DefaultTargets.targetSurplusHigh),
  );

  // Page 3: kaizen
  final _kaizenFormKey = GlobalKey<FormState>();
  final _kaizenTarget = TextEditingController(
    text: Formatters.number(DefaultTargets.weeklyKaizenHoursTarget),
  );
  final _metricName =
      TextEditingController(text: DefaultTargets.defaultGrowthMetricName);
  final _metricUnit =
      TextEditingController(text: DefaultTargets.defaultGrowthMetricUnit);

  // Page 4: rhythm
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
    if (_finishing) return;
    if (_page == 1 && !(_moneyFormKey.currentState?.validate() ?? true)) {
      return;
    }
    if (_page == 2 && !(_kaizenFormKey.currentState?.validate() ?? true)) {
      return;
    }
    if (_page < 3) {
      FocusScope.of(context).unfocus();
      _maxAllowedPage = _page + 1;
      await _pageController.nextPage(
        duration: AppMotion.standard,
        curve: AppMotion.easeOut,
      );
    } else {
      await _finish(applyInputs: true);
    }
  }

  Future<void> _back() async {
    if (_finishing || _page == 0) return;
    FocusScope.of(context).unfocus();
    await _pageController.previousPage(
      duration: AppMotion.standard,
      curve: AppMotion.easeOut,
    );
  }

  /// Persists onboarding answers into the already-seeded records, marks
  /// onboarding complete, and goes to the dashboard.
  Future<void> _finish({required bool applyInputs}) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    // Captured before the awaits — the context may unmount mid-flight.
    final router = GoRouter.of(context);

    try {
      if (applyInputs) {
        final settings = ref.read(settingsControllerProvider);
        await settings
            .setMonthlyNetIncome(Validators.parseNumber(_income.text));
        await settings.setTargetSurplus(
          low: Validators.parseNumber(_surplusLow.text),
          high: Validators.parseNumber(_surplusHigh.text),
        );

        // Kaizen weekly hours live on the Kaizen time budget row.
        final db = ref.read(databaseProvider);
        final budgets = await db.select(db.timeBudgets).get();
        for (final budget in budgets) {
          if (TimeCategoryKind.parse(budget.kind) == TimeCategoryKind.kaizen) {
            await ref.read(timeControllerProvider).updateBudget(
                  budget.copyWith(
                    weeklyTargetHours:
                        Validators.parseNumber(_kaizenTarget.text),
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

        Haptics.medium();
      }

      await ref.read(preferencesProvider).setOnboardingComplete(true);
      ref.invalidate(appRouterProvider);
      router.go('/dashboard');
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          maxWidth: 560,
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  // Swiping back is free; forward stays gated on validation.
                  physics: _GatedPagePhysics(allowedPage: () => _maxAllowedPage),
                  onPageChanged: (i) => setState(() {
                    _page = i;
                    _maxAllowedPage = i;
                  }),
                  children: [
                    _welcome(theme),
                    _moneyStep(theme),
                    _kaizenStep(theme),
                    _rhythmStep(theme),
                  ],
                ),
              ),
              _footer(theme),
            ],
          ),
        ),
      ),
    );
  }

  // --- footer ---------------------------------------------------------------

  Widget _footer(ThemeData theme) {
    final scheme = theme.colorScheme;
    final quiet = TextButton.styleFrom(
      foregroundColor: scheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dots(index: _page),
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              if (_page > 0)
                TextButton(
                  onPressed: _finishing ? null : _back,
                  style: quiet,
                  child: const Text('Back'),
                ),
              const Spacer(),
              TextButton(
                onPressed:
                    _finishing ? null : () => _finish(applyInputs: false),
                style: quiet,
                child: const Text('Skip'),
              ),
              const SizedBox(width: AppSpace.sm),
              FilledButton(
                onPressed: _finishing ? null : _next,
                child: _finishing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Text(_page == 3 ? 'Start' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- pages ------------------------------------------------------------------

  Widget _wrap(List<Widget> children) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen, AppSpace.xl, AppSpace.screen, AppSpace.xxl,
        ),
        children: children,
      );

  Widget _tagline(ThemeData theme, String text) => Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      );

  Widget _welcome(ThemeData theme) => _wrap([
        const SizedBox(height: AppSpace.xxxl + AppSpace.lg),
        Text('Life Dashboard', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpace.xxxl),
        const _TriadLine(
          icon: Icons.account_balance_wallet_outlined,
          text: 'Money is the scoreboard.',
        ),
        const SizedBox(height: AppSpace.lg),
        const _TriadLine(
          icon: Icons.trending_up,
          text: 'Curiosity is the engine.',
        ),
        const SizedBox(height: AppSpace.lg),
        const _TriadLine(
          icon: Icons.outlined_flag,
          text: 'Freedom is the goal.',
        ),
        const SizedBox(height: AppSpace.xxxl),
        Text(
          'Local-first. No accounts. Your data stays here.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.textTertiary,
          ),
        ),
      ]);

  Widget _moneyStep(ThemeData theme) => _wrap([
        Text('Money', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpace.xs),
        _tagline(theme, AppCopy.moneyScoreboard),
        const SizedBox(height: AppSpace.xxl),
        Form(
          key: _moneyFormKey,
          child: Column(
            children: [
              _NumberField(
                label: 'Net monthly income',
                controller: _income,
                suffixText: r'$',
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Income'),
              ),
              const SizedBox(height: AppSpace.md),
              _NumberField(
                label: 'Target surplus (low)',
                controller: _surplusLow,
                suffixText: r'$',
                validator: (v) => Validators.number(v, label: 'Low'),
              ),
              const SizedBox(height: AppSpace.md),
              _NumberField(
                label: 'Target surplus (high)',
                controller: _surplusHigh,
                suffixText: r'$',
                textInputAction: TextInputAction.done,
                validator: (v) {
                  final base = Validators.number(v, label: 'High');
                  if (base != null) return base;
                  final low = Validators.tryParseNumber(_surplusLow.text);
                  if (low != null && Validators.parseNumber(v!) < low) {
                    return "High target can't be under the low one.";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ]);

  Widget _kaizenStep(ThemeData theme) => _wrap([
        Text('Kaizen', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpace.xs),
        _tagline(theme, AppCopy.oneHunt),
        const SizedBox(height: AppSpace.sm),
        Text(
          'Pick the hours you will protect and the one number that proves '
          'progress.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        Form(
          key: _kaizenFormKey,
          child: Column(
            children: [
              _NumberField(
                label: 'Weekly hours target',
                controller: _kaizenTarget,
                suffixText: 'h',
                validator: (v) => Validators.positiveNumber(v, label: 'Target'),
              ),
              const SizedBox(height: AppSpace.md),
              AppTextField(
                label: 'Growth metric',
                controller: _metricName,
                validator: (v) => Validators.required(v, label: 'Metric'),
              ),
              const SizedBox(height: AppSpace.md),
              AppTextField(
                label: 'Unit',
                controller: _metricUnit,
                textInputAction: TextInputAction.done,
                validator: (v) => Validators.required(v, label: 'Unit'),
              ),
            ],
          ),
        ),
      ]);

  Widget _rhythmStep(ThemeData theme) => _wrap([
        Text('Rhythm', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpace.xs),
        _tagline(theme, AppCopy.recoveryLoadBearing),
        const SizedBox(height: AppSpace.xxl),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          child: Column(
            children: [
              _TimeRow(
                icon: Icons.wb_sunny_outlined,
                title: 'Morning command',
                time: _morning,
                onPicked: (t) => setState(() => _morning = t),
              ),
              const Divider(height: 1, indent: AppSpace.lg + 40 + AppSpace.md),
              _TimeRow(
                icon: Icons.nightlight_outlined,
                title: 'Night review',
                time: _night,
                onPicked: (t) => setState(() => _night = t),
              ),
              const Divider(height: 1, indent: AppSpace.lg + 40 + AppSpace.md),
              _ToggleRow(
                icon: Icons.notifications_outlined,
                title: 'Daily reminders',
                subtitle: 'Permission is requested when you tap Start.',
                value: _enableNotifications,
                onChanged: (v) {
                  Haptics.select();
                  setState(() => _enableNotifications = v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Text(
          'Skip applies nothing. You can change all of this later in Settings.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ]);
}

// --- widgets -----------------------------------------------------------------

/// One line of the triad: glyph + statement. Pure typography.
class _TriadLine extends StatelessWidget {
  const _TriadLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpace.md),
        Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
      ],
    );
  }
}

/// Progress dots: the active page stretches into a pill.
class _Dots extends StatelessWidget {
  const _Dots({required this.index});

  final int index;

  static const int count = 4;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppMotion.standard,
            curve: AppMotion.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? AppColors.primary : scheme.outline,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
      ],
    );
  }
}

/// Tappable time row: icon well, title, current time as the value.
class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.icon,
    required this.title,
    required this.time,
    required this.onPicked,
  });

  final IconData icon;
  final String title;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onPicked;

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: time);
    if (picked != null) {
      Haptics.select();
      onPicked(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _pick(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: 10,
        ),
        child: Row(
          children: [
            _IconWell(icon),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(title, style: theme.textTheme.bodyMedium),
            ),
            Text(
              Formatters.timeOfDay(time.hour, time.minute),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Switch row matching the time rows' anatomy.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: 10,
        ),
        child: Row(
          children: [
            _IconWell(icon),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Rounded icon well shared by the rhythm rows.
class _IconWell extends StatelessWidget {
  const _IconWell(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.chip + 2),
      ),
      child: Icon(icon, size: 20, color: AppColors.primary),
    );
  }
}

/// Numeric input matching AppNumberField, plus keyboard chaining.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    this.suffixText,
    this.validator,
    this.textInputAction = TextInputAction.next,
  });

  final String label;
  final TextEditingController controller;
  final String? suffixText;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator ?? (v) => Validators.number(v, label: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      textInputAction: textInputAction,
      decoration: InputDecoration(labelText: label, suffixText: suffixText),
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}

/// Lets the user swipe back through completed steps while keeping forward
/// movement on the validated Next button.
///
/// Works as a hard boundary at the highest validated page, so neither drags
/// nor velocity-only flings can advance past it — only Next (which raises
/// the limit after validation) moves the view forward.
class _GatedPagePhysics extends ScrollPhysics {
  const _GatedPagePhysics({required this.allowedPage, super.parent});

  /// The furthest page the user may reach right now.
  final int Function() allowedPage;

  @override
  _GatedPagePhysics applyTo(ScrollPhysics? ancestor) =>
      _GatedPagePhysics(allowedPage: allowedPage, parent: buildParent(ancestor));

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (!position.hasViewportDimension || position.viewportDimension <= 0) {
      return super.applyBoundaryConditions(position, value);
    }
    final vp = position.viewportDimension;
    final allowedPx = allowedPage() * vp;
    // The page the view is currently on or returning to; the half-pixel
    // slack absorbs float error when resting exactly on a page boundary.
    final ceilPx = ((position.pixels - 0.5) / vp).ceilToDouble() * vp;
    var limit = ceilPx > allowedPx ? ceilPx : allowedPx;
    if (limit < position.minScrollExtent) limit = position.minScrollExtent;
    if (limit > position.maxScrollExtent) limit = position.maxScrollExtent;
    if (value > limit && value > position.pixels) {
      // Report everything past the limit as overscroll (i.e. blocked).
      return value - limit;
    }
    return super.applyBoundaryConditions(position, value);
  }
}
