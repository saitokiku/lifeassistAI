import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/result.dart';
import '../../../core/providers.dart';
import '../../../core/storage/seed_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validation.dart';
import '../../../shared/haptics.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_number_field.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../reminders/application/reminders_controller.dart';
import '../application/settings_controller.dart';
import '../data/backup_service.dart';
import '../domain/user_settings.dart';

// Note: this provider lives in the presentation layer for historical reasons;
// moving it would touch files outside this feature's UI, so it stays put.
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(databaseProvider)),
);

/// Settings: targets, appearance, notifications, and your data.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull;

    final Widget body;
    if (settingsAsync.hasError && settings == null) {
      body = ErrorState(
        title: "Settings didn't load.",
        message: 'Your data is safe. Give it another try.',
        onRetry: () => ref.invalidate(settingsProvider),
      );
    } else if (settings == null) {
      body = const SkeletonList();
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen, AppSpace.lg, AppSpace.screen, AppSpace.xxl,
        ),
        children: [
          Row(
            children: [
              const ScreenBackButton(),
              Text('Settings', style: theme.textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Targets, appearance, and your data.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SectionHeader(title: 'Targets'),
          _SettingsGroup(children: [
            _SettingsRow(
              icon: Icons.payments_outlined,
              title: 'Net monthly income',
              value: Formatters.money(settings.monthlyNetIncome),
              onTap: () => _IncomeSheet.show(context, settings: settings),
            ),
            _SettingsRow(
              icon: Icons.savings_outlined,
              title: 'Target surplus range',
              value:
                  '${Formatters.money(settings.targetSurplusLow)} – ${Formatters.money(settings.targetSurplusHigh)}',
              onTap: () => _SurplusSheet.show(context, settings: settings),
            ),
            _SettingsRow(
              icon: Icons.cake_outlined,
              title: 'Birthday',
              value: settings.birthday == null
                  ? 'Not set'
                  : Formatters.fullDate(settings.birthday!),
              onTap: () => _BirthdaySheet.show(context, settings: settings),
            ),
            _SettingsRow(
              icon: Icons.format_quote_outlined,
              title: 'Philosophy line',
              value: settings.philosophyText,
              onTap: () => _PhilosophySheet.show(context, settings: settings),
            ),
            _SettingsRow(
              icon: Icons.pie_chart_outline,
              title: 'Budget targets',
              subtitle: 'On the Money screen.',
              link: true,
              onTap: () => context.go('/money'),
            ),
            _SettingsRow(
              icon: Icons.schedule_outlined,
              title: 'Weekly time targets',
              subtitle: 'On the Time screen.',
              link: true,
              onTap: () => context.go('/time'),
            ),
          ]),
          const SectionHeader(title: 'Appearance'),
          const _ThemeCard(),
          const SectionHeader(title: 'Notifications'),
          _SettingsGroup(children: [
            const _NotificationsRow(),
            _SettingsRow(
              icon: Icons.alarm_outlined,
              title: 'Manage reminders',
              subtitle: 'Times and messages for each nudge.',
              link: true,
              onTap: () => context.go('/reminders'),
            ),
          ]),
          const SectionHeader(title: 'Data'),
          const _SettingsGroup(children: [
            _ExportRow(),
            _ImportRow(),
          ]),
          const SectionHeader(title: 'Danger zone'),
          _SettingsGroup(children: [
            _SettingsRow(
              icon: Icons.delete_forever_outlined,
              iconColor: AppColors.critical,
              titleColor: AppColors.critical,
              title: 'Reset everything',
              subtitle: 'Back to the starter defaults. No undo.',
              onTap: () => _ResetSheet.show(context),
            ),
          ]),
          const SectionHeader(title: 'About'),
          const _SettingsGroup(children: [_AboutRow()]),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.lg, AppSpace.xs, 0),
            child: Text(
              'Local-first. No account, no cloud, no analytics.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.textTertiary,
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(child: ContentWidth(child: body)),
    );
  }
}

// --- building blocks --------------------------------------------------------

/// Rounded icon well used by every settings row.
class _IconWell extends StatelessWidget {
  const _IconWell(this.icon, {this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip + 2),
      ),
      child: Icon(icon, size: 20, color: c),
    );
  }
}

/// One card per section: rows separated by hairlines.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Column(
        children: [
          for (final (i, row) in children.indexed) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: AppSpace.lg + 40 + AppSpace.md,
              ),
            row,
          ],
        ],
      ),
    );
  }
}

/// A settings row. Value rows show the current value and open a sheet;
/// link rows show a chevron and leave the screen.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.iconColor,
    this.titleColor,
    this.subtitle,
    this.value,
    this.trailing,
    this.link = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Color? iconColor;
  final Color? titleColor;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final bool link;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: 10,
        ),
        child: Row(
          children: [
            _IconWell(icon, color: iconColor),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: titleColor),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: AppSpace.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 168),
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
            if (trailing != null) ...[
              const SizedBox(width: AppSpace.sm),
              trailing!,
            ],
            if (link) ...[
              const SizedBox(width: AppSpace.xs),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Theme picker: a full-width segmented control. Dark is the house default.
class _ThemeCard extends ConsumerWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Column(
        children: [
          const _SettingsRow(icon: Icons.dark_mode_outlined, title: 'Theme'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, 0, AppSpace.lg, AppSpace.lg - AppSpace.xs,
            ),
            child: SegmentedButton<ThemeMode>(
              expandedInsets: EdgeInsets.zero,
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) {
                Haptics.select();
                ref.read(settingsControllerProvider).setThemeMode(s.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Master notifications toggle. Enabling runs the one sanctioned path:
/// RemindersController.enableNotifications() — permission, persist, resync.
class _NotificationsRow extends ConsumerStatefulWidget {
  const _NotificationsRow();

  @override
  ConsumerState<_NotificationsRow> createState() => _NotificationsRowState();
}

class _NotificationsRowState extends ConsumerState<_NotificationsRow> {
  bool _busy = false;

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    Haptics.select();
    try {
      final controller = ref.read(remindersControllerProvider);
      if (value) {
        final granted = await controller.enableNotifications();
        if (!mounted) return;
        if (granted) {
          showSuccessSnack(context, 'Reminders scheduled.');
        } else {
          showErrorSnack(
            context,
            'Blocked at the system level. Allow notifications for '
            'Life Dashboard, then try again.',
          );
        }
      } else {
        await controller.disableNotifications();
        if (!mounted) return;
        showSuccessSnack(context, 'Notifications off.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(notificationsEnabledProvider);
    final supported = ref.watch(notificationServiceProvider).isSupported;

    return _SettingsRow(
      icon: Icons.notifications_outlined,
      title: 'Notifications',
      subtitle: !supported
          ? 'Not available on web.'
          : enabled
              ? 'Daily nudges are on.'
              : 'Off. Reminders stay quiet.',
      trailing: Switch(
        value: enabled,
        onChanged: supported && !_busy ? _toggle : null,
      ),
      onTap: supported && !_busy ? () => _toggle(!enabled) : null,
    );
  }
}

/// Export row with an in-row progress state — the tap never feels dead.
class _ExportRow extends ConsumerStatefulWidget {
  const _ExportRow();

  @override
  ConsumerState<_ExportRow> createState() => _ExportRowState();
}

class _ExportRowState extends ConsumerState<_ExportRow> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _runExport(context, ref);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      icon: Icons.ios_share_outlined,
      title: 'Export backup',
      subtitle: 'Everything as one file. Also copied to clipboard.',
      trailing: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _busy ? null : _export,
    );
  }
}

class _ImportRow extends StatelessWidget {
  const _ImportRow();

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      icon: Icons.download_outlined,
      title: 'Import backup',
      subtitle: 'Replace everything with a saved backup.',
      onTap: () => _ImportSheet.show(context),
    );
  }
}

/// Version row with reserved layout — the value fades in, no '…' flash.
class _AboutRow extends StatefulWidget {
  const _AboutRow();

  @override
  State<_AboutRow> createState() => _AboutRowState();
}

class _AboutRowState extends State<_AboutRow> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (context, snapshot) {
        final info = snapshot.data;
        return _SettingsRow(
          icon: Icons.info_outline,
          title: 'Life Dashboard',
          trailing: AnimatedOpacity(
            opacity: info == null ? 0 : 1,
            duration: AppMotion.standard,
            curve: AppMotion.easeOut,
            child: Text(
              info == null ? '' : 'v${info.version} (${info.buildNumber})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }
}

// --- export flow -------------------------------------------------------------

/// Serializes everything, copies it to the clipboard, then opens the OS
/// share sheet anchored to [context]'s render box (iPad popover contract).
/// A cancelled share is a quiet no-op — the clipboard copy still stands.
Future<void> _runExport(BuildContext context, WidgetRef ref) async {
  // Anchor the share popover (required by iPad; ignored elsewhere).
  final box = context.findRenderObject() as RenderBox?;
  final origin =
      box == null ? null : box.localToGlobal(Offset.zero) & box.size;

  final String json;
  try {
    json = await ref.read(backupServiceProvider).exportJson();
    // Clipboard is a universal fallback the user can always rely on.
    await Clipboard.setData(ClipboardData(text: json));
  } catch (_) {
    if (!context.mounted) return;
    showErrorSnack(context, "That didn't export. Try again.");
    return;
  }

  final stamp =
      DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
  final fileName = 'life_dashboard_export_$stamp.json';

  try {
    final ShareResult result;
    if (kIsWeb) {
      final xfile = XFile.fromData(
        utf8.encode(json),
        name: fileName,
        mimeType: 'application/json',
      );
      result = await Share.shareXFiles(
        [xfile],
        text: 'Life Dashboard backup',
        sharePositionOrigin: origin,
      );
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(json);
      result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Life Dashboard backup',
        sharePositionOrigin: origin,
      );
    }
    if (!context.mounted) return;
    if (result.status == ShareResultStatus.success) {
      showSuccessSnack(context, 'Backup shared. Also on your clipboard.');
    } else {
      showSuccessSnack(context, 'Backup copied to your clipboard.');
    }
  } catch (_) {
    // Share cancelled or unavailable; the clipboard copy still stands.
    if (!context.mounted) return;
    showSuccessSnack(context, 'Backup copied to your clipboard.');
  }
}

// --- edit sheets -------------------------------------------------------------

class _IncomeSheet extends ConsumerStatefulWidget {
  const _IncomeSheet({required this.settings});

  final UserSettings settings;

  static Future<void> show(
    BuildContext context, {
    required UserSettings settings,
  }) =>
      showAppSheet<void>(
        context,
        builder: (_) => _IncomeSheet(settings: settings),
      );

  @override
  ConsumerState<_IncomeSheet> createState() => _IncomeSheetState();
}

class _IncomeSheetState extends ConsumerState<_IncomeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: Formatters.number(widget.settings.monthlyNetIncome, maxDecimals: 2),
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final navigator = Navigator.of(context);
    await ref
        .read(settingsControllerProvider)
        .setMonthlyNetIncome(Validators.parseNumber(_amount.text));
    Haptics.medium();
    if (!mounted) return;
    showSuccessSnack(context, 'Saved.');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Net monthly income',
      subtitle: 'Take-home per month. The scoreboard baseline.',
      footer: AppSheetButton(label: 'Save', onPressed: _save),
      children: [
        Form(
          key: _formKey,
          child: AppNumberField(
            label: 'Amount',
            controller: _amount,
            suffixText: r'$',
            validator: (v) => Validators.nonNegativeNumber(v, label: 'Amount'),
          ),
        ),
      ],
    );
  }
}

class _SurplusSheet extends ConsumerStatefulWidget {
  const _SurplusSheet({required this.settings});

  final UserSettings settings;

  static Future<void> show(
    BuildContext context, {
    required UserSettings settings,
  }) =>
      showAppSheet<void>(
        context,
        builder: (_) => _SurplusSheet(settings: settings),
      );

  @override
  ConsumerState<_SurplusSheet> createState() => _SurplusSheetState();
}

class _SurplusSheetState extends ConsumerState<_SurplusSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _low = TextEditingController(
    text: Formatters.number(widget.settings.targetSurplusLow, maxDecimals: 2),
  );
  late final _high = TextEditingController(
    text: Formatters.number(widget.settings.targetSurplusHigh, maxDecimals: 2),
  );

  @override
  void dispose() {
    _low.dispose();
    _high.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final navigator = Navigator.of(context);
    await ref.read(settingsControllerProvider).setTargetSurplus(
          low: Validators.parseNumber(_low.text),
          high: Validators.parseNumber(_high.text),
        );
    Haptics.medium();
    if (!mounted) return;
    showSuccessSnack(context, 'Saved.');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Target surplus range',
      subtitle: 'The band you aim to keep each month.',
      footer: AppSheetButton(label: 'Save', onPressed: _save),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppNumberField(
                label: 'Low',
                controller: _low,
                suffixText: r'$',
                validator: (v) => Validators.number(v, label: 'Low'),
              ),
              const SizedBox(height: AppSpace.md),
              AppNumberField(
                label: 'High',
                controller: _high,
                suffixText: r'$',
                validator: (v) {
                  final base = Validators.number(v, label: 'High');
                  if (base != null) return base;
                  final low = Validators.tryParseNumber(_low.text);
                  if (low != null && Validators.parseNumber(v!) < low) {
                    return "High target can't be under the low one.";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhilosophySheet extends ConsumerStatefulWidget {
  const _PhilosophySheet({required this.settings});

  final UserSettings settings;

  static Future<void> show(
    BuildContext context, {
    required UserSettings settings,
  }) =>
      showAppSheet<void>(
        context,
        builder: (_) => _PhilosophySheet(settings: settings),
      );

  @override
  ConsumerState<_PhilosophySheet> createState() => _PhilosophySheetState();
}

class _PhilosophySheetState extends ConsumerState<_PhilosophySheet> {
  final _formKey = GlobalKey<FormState>();
  late final _text = TextEditingController(
    text: widget.settings.philosophyText,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final navigator = Navigator.of(context);
    await ref
        .read(settingsControllerProvider)
        .setPhilosophyText(_text.text.trim());
    Haptics.medium();
    if (!mounted) return;
    showSuccessSnack(context, 'Saved.');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Philosophy line',
      subtitle: 'One line at the top of Today. Make it yours.',
      footer: AppSheetButton(label: 'Save', onPressed: _save),
      children: [
        Form(
          key: _formKey,
          child: AppTextField(
            label: 'Philosophy line',
            hint: AppConstants.philosophyLine,
            controller: _text,
            maxLines: 2,
            validator: (v) => Validators.required(v, label: 'Philosophy line'),
          ),
        ),
      ],
    );
  }
}

class _BirthdaySheet extends ConsumerWidget {
  const _BirthdaySheet({required this.settings});

  final UserSettings settings;

  static Future<void> show(
    BuildContext context, {
    required UserSettings settings,
  }) =>
      showAppSheet<void>(
        context,
        builder: (_) => _BirthdaySheet(settings: settings),
      );

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final picked = await showDatePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.input,
      initialDate: settings.birthday ?? DateTime(1999),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    await ref.read(settingsControllerProvider).setBirthday(picked);
    Haptics.medium();
    if (!context.mounted) return;
    showSuccessSnack(context, 'Saved.');
    navigator.pop();
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    await ref.read(settingsControllerProvider).setBirthday(null);
    Haptics.medium();
    if (!context.mounted) return;
    showSuccessSnack(context, 'Birthday cleared.');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final birthday = settings.birthday;

    return AppSheet(
      title: 'Birthday',
      subtitle: 'Drives the age-${AppConstants.lockInAge} countdown.',
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetButton(
            label: birthday == null ? 'Set birthday' : 'Change birthday',
            onPressed: () => _pick(context, ref),
          ),
          if (birthday != null) ...[
            const SizedBox(height: AppSpace.sm),
            TextButton(
              onPressed: () => _clear(context, ref),
              child: const Text('Clear birthday'),
            ),
          ],
        ],
      ),
      children: [
        Row(
          children: [
            const _IconWell(Icons.cake_outlined),
            const SizedBox(width: AppSpace.md),
            Text(
              birthday == null ? 'Not set yet.' : Formatters.fullDate(birthday),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}

// --- import ------------------------------------------------------------------

/// Lenient read of a backup's envelope — used for the pre-import preview.
class _Envelope {
  const _Envelope({
    this.schemaVersion,
    this.exportedAt,
    this.recordCount,
    required this.hasData,
  });

  final String? schemaVersion;
  final DateTime? exportedAt;
  final int? recordCount;
  final bool hasData;

  static _Envelope? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final data = decoded['data'];
      int? count;
      if (data is Map<String, dynamic>) {
        var total = 0;
        for (final rows in data.values) {
          if (rows is List) total += rows.length;
        }
        count = total;
      }
      return _Envelope(
        schemaVersion: decoded['schemaVersion']?.toString(),
        exportedAt: DateTime.tryParse(decoded['exportedAt']?.toString() ?? ''),
        recordCount: count,
        hasData: data is Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  String? get previewLine {
    final parts = <String>[
      if (exportedAt != null) 'Exported ${Formatters.fullDate(exportedAt!)}',
      if (recordCount != null)
        '$recordCount record${recordCount == 1 ? '' : 's'}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class _ImportSheet extends ConsumerStatefulWidget {
  const _ImportSheet();

  static Future<void> show(BuildContext context) =>
      showAppSheet<void>(context, builder: (_) => const _ImportSheet());

  @override
  ConsumerState<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends ConsumerState<_ImportSheet> {
  final _paste = TextEditingController();
  String? _fileName;
  String? _fileContent;
  bool _showPaste = false;
  String? _error;
  _Envelope? _envelope;

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  String get _raw => _fileContent ?? _paste.text;

  /// Everything that can be checked without touching the database.
  String? _staticCheck(String raw) {
    final envelope = _Envelope.tryParse(raw);
    if (envelope == null || !envelope.hasData) {
      return "That file doesn't look like a Life Dashboard backup.";
    }
    if (envelope.schemaVersion != null &&
        envelope.schemaVersion != AppConstants.exportSchemaVersion) {
      return 'This backup is from a newer version of the app.';
    }
    return null;
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      final String content;
      if (picked.bytes != null) {
        content = utf8.decode(picked.bytes!);
      } else if (picked.path != null) {
        content = await File(picked.path!).readAsString();
      } else {
        return;
      }
      if (!mounted) return;
      setState(() {
        _fileName = picked.name;
        _fileContent = content;
        _envelope = _Envelope.tryParse(content);
        _error = _staticCheck(content);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = "Couldn't read that file. Try another one.");
    }
  }

  void _clearFile() {
    setState(() {
      _fileName = null;
      _fileContent = null;
      _envelope = _paste.text.trim().isEmpty
          ? null
          : _Envelope.tryParse(_paste.text);
      _error = null;
    });
  }

  Future<void> _import() async {
    final raw = _raw;
    if (raw.trim().isEmpty) {
      setState(() => _error = 'Pick a file or paste a backup first.');
      return;
    }
    final staticError = _staticCheck(raw);
    if (staticError != null) {
      setState(() => _error = staticError);
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: 'Replace everything?',
      message:
          'Your current data is deleted and replaced with this backup. '
          'There is no undo.',
      confirmLabel: 'Replace data',
    );
    if (!confirmed || !mounted) return;

    final navigator = Navigator.of(context);
    final result = await ref.read(backupServiceProvider).importJson(raw);
    if (!mounted) return;

    switch (result) {
      case Success<int>(:final value):
        // Resync OS schedules to the imported reminder rows via the one
        // sanctioned path — only when the app-level toggle is on.
        var resynced = false;
        if (ref.read(notificationsEnabledProvider)) {
          resynced =
              await ref.read(remindersControllerProvider).enableNotifications();
        }
        Haptics.medium();
        if (!mounted) return;
        showSuccessSnack(
          context,
          resynced
              ? 'Imported $value records. Reminders rescheduled.'
              : 'Imported $value records.',
        );
        navigator.pop();
      case Failure<int>():
        // Human copy only — never surface exception internals.
        setState(
          () => _error = "That backup couldn't be restored. Nothing was changed.",
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preview = _envelope?.previewLine;

    return AppSheet(
      title: 'Import backup',
      subtitle: 'Bring back a saved backup. This replaces everything.',
      footer: AppSheetButton(label: 'Import backup', onPressed: _import),
      children: [
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.folder_open_outlined, size: 20),
          label: Text(
            _fileName == null ? 'Choose a backup file' : 'Choose a different file',
          ),
        ),
        if (_fileName != null) ...[
          const SizedBox(height: AppSpace.md),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: const Icon(
                Icons.insert_drive_file_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              label: Text(
                _fileName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onDeleted: _clearFile,
            ),
          ),
        ],
        if (preview != null) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            preview,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpace.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _showPaste = !_showPaste),
            style: TextButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
            ),
            child: Text(_showPaste ? 'Hide the paste box' : 'Paste it instead'),
          ),
        ),
        if (_showPaste) ...[
          const SizedBox(height: AppSpace.xs),
          TextField(
            controller: _paste,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Paste the backup contents here.',
            ),
            onChanged: (text) {
              if (_fileContent != null) return;
              setState(() {
                _error = null;
                _envelope =
                    text.trim().isEmpty ? null : _Envelope.tryParse(text);
              });
            },
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: AppColors.critical,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.critical,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// --- reset -------------------------------------------------------------------

class _ResetSheet extends ConsumerStatefulWidget {
  const _ResetSheet();

  static Future<void> show(BuildContext context) =>
      showAppSheet<void>(context, builder: (_) => const _ResetSheet());

  @override
  ConsumerState<_ResetSheet> createState() => _ResetSheetState();
}

class _ResetSheetState extends ConsumerState<_ResetSheet> {
  bool _exporting = false;

  Future<void> _exportFirst() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await _runExport(context, ref);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _reset() async {
    Haptics.medium();
    final navigator = Navigator.of(context);
    final db = ref.read(databaseProvider);
    // Order is load-bearing: clear, then re-seed the empty tables.
    await db.clearAllTables();
    await SeedService(db).seedIfNeeded();
    var resynced = false;
    if (ref.read(notificationsEnabledProvider)) {
      resynced =
          await ref.read(remindersControllerProvider).enableNotifications();
    }
    if (!mounted) return;
    showSuccessSnack(
      context,
      resynced
          ? 'Everything reset. Reminders rescheduled.'
          : 'Everything reset to defaults.',
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSheet(
      title: 'Reset everything?',
      children: [
        Text(
          'Every metric, transaction, time block, habit, idea, goal, '
          'countdown, reminder, and identity line is deleted, and settings '
          'go back to the starter defaults. There is no undo.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpace.xxl),
        OutlinedButton(
          onPressed: _exporting ? null : _exportFirst,
          child: _exporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : const Text('Export first'),
        ),
        const SizedBox(height: AppSpace.sm),
        AppSheetButton(
          label: 'Reset everything',
          destructive: true,
          onPressed: _reset,
        ),
        const SizedBox(height: AppSpace.sm),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
