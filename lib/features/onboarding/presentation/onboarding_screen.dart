import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../routing/app_router.dart';
import '../../../shared/haptics.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/target_date_row.dart';
import '../../focus/application/focus_controller.dart';
import '../../reminders/application/reminders_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/domain/user_settings.dart';

/// First-launch onboarding: what the app is, the user's main goal, a little
/// about them, and the daily rhythm. Four short steps; every field is
/// optional and everything can be changed later.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  bool _finishing = false;

  static const int _pageCount = 4;

  // Step 2: the main goal
  final _goalTitle = TextEditingController();
  final _goalWhy = TextEditingController();
  DateTime? _goalDate;

  // Step 3: about you
  final _name = TextEditingController();
  final Set<DashboardArea> _areas = {...DashboardArea.all};

  // Step 4: rhythm
  TimeOfDay _morning = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _evening = const TimeOfDay(hour: 21, minute: 30);
  bool _enableNotifications = true;

  @override
  void dispose() {
    _pageController.dispose();
    _goalTitle.dispose();
    _goalWhy.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_finishing) return;
    if (_page < _pageCount - 1) {
      FocusScope.of(context).unfocus();
      await _pageController.nextPage(
        duration: AppMotion.standard,
        curve: AppMotion.easeOut,
      );
    } else {
      await _finish();
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

  /// Persists whatever the user shared, marks onboarding complete, and
  /// lands on Today. Empty fields simply apply nothing.
  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    // Captured before the awaits — the context may unmount mid-flight.
    final router = GoRouter.of(context);

    try {
      final settings = ref.read(settingsControllerProvider);

      final name = _name.text.trim();
      if (name.isNotEmpty) await settings.setDisplayName(name);

      if (_areas.length != DashboardArea.all.length) {
        await settings.setDashboardAreas(_areas);
      }

      final goalTitle = _goalTitle.text.trim();
      if (goalTitle.isNotEmpty) {
        await ref.read(focusControllerProvider).createGoal(
              title: goalTitle,
              why: _goalWhy.text.trim(),
              targetDate: _goalDate,
            );
      }

      // Morning plan / evening review times on the seeded reminders.
      final db = ref.read(databaseProvider);
      final reminders = await db.select(db.reminders).get();
      for (final reminder in reminders) {
        if (reminder.type == 'morningCommand') {
          await db.update(db.reminders).replace(reminder.copyWith(
              hour: _morning.hour,
              minute: _morning.minute,
              updatedAt: DateTime.now()));
        } else if (reminder.type == 'nightReview') {
          await db.update(db.reminders).replace(reminder.copyWith(
              hour: _evening.hour,
              minute: _evening.minute,
              updatedAt: DateTime.now()));
        }
      }

      if (_enableNotifications) {
        await ref.read(remindersControllerProvider).enableNotifications();
      }

      Haptics.medium();
      await ref.read(preferencesProvider).setOnboardingComplete(true);
      ref.invalidate(appRouterProvider);
      router.go('/today');
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
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _welcome(theme),
                    _goalStep(theme),
                    _aboutStep(theme),
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

  String get _nextLabel {
    if (_page == 0) return 'Get started';
    if (_page == _pageCount - 1) return 'Start';
    if (_page == 1 && _goalTitle.text.trim().isEmpty) return 'Skip for now';
    return 'Next';
  }

  Widget _footer(ThemeData theme) {
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
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                  child: const Text('Back'),
                ),
              const Spacer(),
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
                    : Text(_nextLabel),
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

  Widget _stepIntro(ThemeData theme, String title, String support) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpace.sm),
          Text(
            support,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      );

  Widget _welcome(ThemeData theme) => _wrap([
        const SizedBox(height: AppSpace.xxxl + AppSpace.lg),
        Text(AppConstants.appName, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpace.sm),
        Text(
          'One quiet place to run your life.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpace.xxxl),
        const _ValueLine(
          icon: Icons.outlined_flag,
          text: 'Pick one main goal and move it a little every day.',
        ),
        const SizedBox(height: AppSpace.lg),
        const _ValueLine(
          icon: Icons.wb_sunny_outlined,
          text: 'See what matters today — not everything at once.',
        ),
        const SizedBox(height: AppSpace.lg),
        const _ValueLine(
          icon: Icons.donut_small_outlined,
          text: 'Keep money, time, and habits honest with light logging.',
        ),
        const SizedBox(height: AppSpace.xxxl),
        Text(
          'Local-first. No account, no cloud, no analytics — your data '
          'stays on this device.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.textTertiary,
          ),
        ),
      ]);

  Widget _goalStep(ThemeData theme) => _wrap([
        _stepIntro(
          theme,
          'What are you working toward?',
          'The one outcome that matters most right now. The app keeps it '
              'in front of you. You can change it, pause it, or set it '
              'later.',
        ),
        const SizedBox(height: AppSpace.xl),
        AppTextField(
          label: 'Your main goal',
          hint: 'e.g. Finish nursing school',
          controller: _goalTitle,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final example in const [
              'Build my business',
              'Get out of debt',
              'Run a marathon',
              'Publish my novel',
            ])
              ActionChip(
                label: Text(example),
                onPressed: () {
                  Haptics.select();
                  setState(() => _goalTitle.text = example);
                },
              ),
          ],
        ),
        if (_goalTitle.text.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpace.lg),
          AppTextField(
            label: 'Why it matters (optional)',
            hint: 'In your own words.',
            controller: _goalWhy,
            maxLines: 2,
          ),
          const SizedBox(height: AppSpace.sm),
          TargetDateRow(
            date: _goalDate,
            emptyLabel: 'Add a timeframe (optional)',
            onChanged: (d) => setState(() => _goalDate = d),
          ),
        ],
      ]);

  Widget _aboutStep(ThemeData theme) => _wrap([
        _stepIntro(
          theme,
          'About you',
          'A name for greetings, and the areas you want on your Today '
              'screen. All of it optional, all of it changeable.',
        ),
        const SizedBox(height: AppSpace.xl),
        AppTextField(
          label: 'Your name (optional)',
          hint: 'What should we call you?',
          controller: _name,
        ),
        const SizedBox(height: AppSpace.xl),
        Text(
          'Manage these areas',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpace.sm),
        for (final area in DashboardArea.values)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(area.label),
            subtitle: Text(area.description),
            value: _areas.contains(area),
            onChanged: (on) {
              Haptics.select();
              setState(() {
                on == true ? _areas.add(area) : _areas.remove(area);
              });
            },
          ),
      ]);

  Widget _rhythmStep(ThemeData theme) => _wrap([
        _stepIntro(
          theme,
          'A light daily rhythm',
          'Two gentle nudges: plan the day in the morning, close it at '
              'night. Adjust or turn them off anytime.',
        ),
        const SizedBox(height: AppSpace.xl),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          child: Column(
            children: [
              _TimeRow(
                icon: Icons.wb_sunny_outlined,
                title: 'Morning plan',
                time: _morning,
                onPicked: (t) => setState(() => _morning = t),
              ),
              const Divider(height: 1, indent: AppSpace.lg + 40 + AppSpace.md),
              _TimeRow(
                icon: Icons.nightlight_outlined,
                title: 'Evening review',
                time: _evening,
                onPicked: (t) => setState(() => _evening = t),
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
          'That\'s it. Everything else waits until you need it.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ]);
}

// --- widgets -----------------------------------------------------------------

/// One value-proposition line: glyph + statement. Pure typography.
class _ValueLine extends StatelessWidget {
  const _ValueLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
        ),
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
