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
import '../../../core/errors/error_log.dart';
import '../../../core/errors/result.dart';
import '../../../core/health/health_habit_sync.dart';
import '../../../core/health/health_service.dart';
import '../../../core/native/capture_queue_drain.dart';
import '../../../core/native/live_activity_service.dart';
import '../../../core/providers.dart';
import '../../../core/security/app_lock.dart';
import '../../../core/storage/seed_service.dart';
import '../../../core/storage/settings_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/date_utils.dart';
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
import '../../notes/application/notes_controller.dart';
import '../../notes/data/vault_service.dart';
import '../../reminders/application/reminders_controller.dart';
import '../application/settings_controller.dart';
import '../data/auto_backup_service.dart';
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
          AppSpace.screen,
          AppSpace.lg,
          AppSpace.screen,
          AppSpace.xxl,
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
            AppCopy.settingsTagline,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SectionHeader(title: 'About you'),
          _SettingsGroup(children: [
            _SettingsRow(
              icon: Icons.person_outline,
              title: 'Your name',
              value: settings.displayName.isEmpty
                  ? 'Not set'
                  : settings.displayName,
              onTap: () => _NameSheet.show(context, settings: settings),
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
              icon: Icons.outlined_flag,
              title: 'Main goal',
              subtitle: 'On the Focus tab.',
              link: true,
              onTap: () => context.go('/focus'),
            ),
          ]),
          const SectionHeader(title: 'Targets'),
          _SettingsGroup(children: [
            _SettingsRow(
              icon: Icons.payments_outlined,
              title: 'Net monthly income',
              value: settings.hasIncome
                  ? Formatters.money(settings.monthlyNetIncome)
                  : 'Not set',
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
          const SectionHeader(title: 'Today screen'),
          _AreasCard(settings: settings),
          const SectionHeader(title: 'Appearance'),
          const _ThemeCard(),
          const _SettingsGroup(children: [_CurrencyRow()]),
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
          const SectionHeader(title: 'Privacy'),
          const _SettingsGroup(children: [_AppLockRow()]),
          const SectionHeader(title: 'Data'),
          const _SettingsGroup(children: [
            _ExportRow(),
            _ImportRow(),
            _HealthRow(),
            _FailedCapturesRow(),
            _DiagnosticsRow(),
          ]),
          const SectionHeader(title: 'Notes vault'),
          const _SettingsGroup(children: [
            if (!kIsWeb) _LiveVaultRow(),
            _VaultShareRow(),
            _VaultImportFilesRow(),
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
            padding: const EdgeInsets.fromLTRB(
                AppSpace.xs, AppSpace.lg, AppSpace.xs, 0),
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
                    style:
                        theme.textTheme.bodyMedium?.copyWith(color: titleColor),
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
              AppSpace.lg,
              0,
              AppSpace.lg,
              AppSpace.lg - AppSpace.xs,
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
            '${AppConstants.appName}, then try again.',
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

/// Biometric/PIN gate on open. Hidden on unsupported devices instead of
/// showing a switch that can't work.
class _AppLockRow extends ConsumerStatefulWidget {
  const _AppLockRow();

  @override
  ConsumerState<_AppLockRow> createState() => _AppLockRowState();
}

class _AppLockRowState extends ConsumerState<_AppLockRow> {
  Future<void> _toggle(bool value) async {
    Haptics.select();
    await ref.read(preferencesProvider).setAppLockEnabled(value);
    if (!mounted) return;
    setState(() {});
    showSuccessSnack(
      context,
      value ? 'App lock on. Locks when you leave the app.' : 'App lock off.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final supported =
        ref.watch(appLockSupportedProvider).valueOrNull ?? false;
    final enabled = ref.read(preferencesProvider).appLockEnabled;

    return _SettingsRow(
      icon: Icons.lock_outline_rounded,
      title: 'App lock',
      subtitle: !supported
          ? 'No screen lock set up on this device.'
          : enabled
              ? 'Asks for Face ID / fingerprint / PIN on open.'
              : 'Off. The app opens without asking.',
      trailing: Switch(
        value: enabled && supported,
        onChanged: supported ? _toggle : null,
      ),
      onTap: supported ? () => _toggle(!enabled) : null,
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
    final lastBackupAt =
        ref.watch(settingsProvider).valueOrNull?.lastBackupAt;
    final String subtitle;
    if (lastBackupAt == null) {
      subtitle = 'Everything as one file. Never backed up yet.';
    } else {
      // dayProvider, not DateTime.now(): the label rolls over at
      // midnight while the screen sits open.
      final days = AppDateUtils.daysBetween(lastBackupAt, ref.watch(dayProvider));
      subtitle = switch (days) {
        0 => 'Last backup: today.',
        1 => 'Last backup: yesterday.',
        _ => 'Last backup: $days days ago.',
      };
    }

    return _SettingsRow(
      icon: Icons.ios_share_outlined,
      title: 'Export backup',
      subtitle: subtitle,
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

// --- notes vault -------------------------------------------------------------

/// The live Obsidian mirror: on means every note exists as `.md` in
/// Files › Life Assist › LifeAssistVault the moment it changes, and
/// edits made there (Files app, Obsidian over iCloud) fold back in on
/// return. Replaces the old export-then-re-import two-step.
class _LiveVaultRow extends ConsumerStatefulWidget {
  const _LiveVaultRow();

  @override
  ConsumerState<_LiveVaultRow> createState() => _LiveVaultRowState();
}

class _LiveVaultRowState extends ConsumerState<_LiveVaultRow> {
  bool _busy = false;

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    Haptics.select();
    setState(() => _busy = true);
    try {
      await ref.read(preferencesProvider).setLiveVaultEnabled(value);
      final vault = ref.read(liveVaultProvider);
      if (value) {
        await vault.start();
        if (mounted) {
          showSuccessSnack(
            context,
            'Live vault on — notes stay mirrored in Files › Life Assist '
            '› ${VaultService.folderName}.',
          );
        }
      } else {
        await vault.stop();
        if (mounted) {
          showSuccessSnack(
              context, 'Live vault off. The mirrored files stay put.');
        }
      }
    } catch (_) {
      if (mounted) showErrorSnack(context, "That didn't stick. Try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.read(preferencesProvider).liveVaultEnabled;
    return _SettingsRow(
      icon: Icons.sync_outlined,
      title: 'Live vault',
      subtitle: enabled
          ? 'Notes mirror to Files as .md; outside edits fold back in.'
          : 'Off. Notes only leave via the .zip below.',
      trailing: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(value: enabled, onChanged: _toggle),
      onTap: _busy ? null : () => _toggle(!enabled),
    );
  }
}

/// Shares the vault as one zip — the portable copy for a computer or
/// straight into an Obsidian vault.
class _VaultShareRow extends ConsumerStatefulWidget {
  const _VaultShareRow();

  @override
  ConsumerState<_VaultShareRow> createState() => _VaultShareRowState();
}

class _VaultShareRowState extends ConsumerState<_VaultShareRow> {
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    // Anchor the share popover (required by iPad; ignored elsewhere).
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      final bytes = await ref.read(vaultServiceProvider).zipBytes();
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'LifeAssistVault_$stamp.zip';
      final XFile xfile;
      if (kIsWeb) {
        xfile = XFile.fromData(bytes, name: fileName, mimeType: 'application/zip');
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        xfile = XFile(file.path);
      }
      await Share.shareXFiles(
        [xfile],
        text: 'Life Assist notes vault',
        sharePositionOrigin: origin,
      );
    } catch (_) {
      if (mounted) showErrorSnack(context, "That didn't share. Try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      icon: Icons.folder_zip_outlined,
      title: 'Share vault (.zip)',
      subtitle: 'All notes as .md files, zipped.',
      trailing: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _busy ? null : _share,
    );
  }
}

/// Multi-file `.md` import — from an Obsidian vault or anywhere else.
class _VaultImportFilesRow extends ConsumerStatefulWidget {
  const _VaultImportFilesRow();

  @override
  ConsumerState<_VaultImportFilesRow> createState() =>
      _VaultImportFilesRowState();
}

class _VaultImportFilesRowState extends ConsumerState<_VaultImportFilesRow> {
  bool _busy = false;

  Future<void> _import() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md', 'markdown', 'txt'],
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final payloads = <VaultPayload>[];
      for (final picked in result.files) {
        final String content;
        if (picked.bytes != null) {
          content = utf8.decode(picked.bytes!, allowMalformed: true);
        } else if (picked.path != null) {
          content = await File(picked.path!).readAsString();
        } else {
          continue;
        }
        payloads.add(VaultPayload(name: picked.name, content: content));
      }
      final outcome =
          await ref.read(vaultServiceProvider).importPayloads(payloads);
      if (!mounted) return;
      showSuccessSnack(context, _importSummary(outcome));
    } catch (_) {
      if (mounted) {
        showErrorSnack(context, "Couldn't read those files. Try again.");
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      icon: Icons.note_add_outlined,
      title: 'Import notes (.md)',
      subtitle: 'Pick markdown files; matching notes update in place.',
      trailing: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _busy ? null : _import,
    );
  }
}

String _importSummary(VaultImportResult outcome) {
  if (outcome.total == 0) return 'Nothing importable in those files.';
  final parts = <String>[
    if (outcome.created > 0)
      '${outcome.created} new note${outcome.created == 1 ? '' : 's'}',
    if (outcome.updated > 0) '${outcome.updated} updated',
  ];
  return 'Imported ${parts.join(' · ')}.';
}

/// Siri/widget captures that couldn't be read stay in a capped graveyard
/// instead of vanishing — this row exists only while any do.
/// Apple Health connection row. Invisible unless this build actually
/// has HealthKit switched on (capability + LAHealthKitEnabled), so a
/// TestFlight build without it shows nothing to configure.
class _HealthRow extends ConsumerStatefulWidget {
  const _HealthRow();

  @override
  ConsumerState<_HealthRow> createState() => _HealthRowState();
}

class _HealthRowState extends ConsumerState<_HealthRow> {
  bool _requested = false;

  Future<void> _connect() async {
    final service = ref.read(healthServiceProvider);
    await service.requestPermission();
    // HealthKit hides read grants; all we honestly know is that the
    // sheet ran. Sync now — data appears if access was allowed. Force
    // past the foreground throttle: the user is watching this row.
    await ref.read(healthHabitSyncProvider).sync(force: true);
    if (mounted) setState(() => _requested = true);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    final availability = ref.watch(healthAvailabilityProvider).valueOrNull;
    if (availability != HealthAvailability.ready) {
      return const SizedBox.shrink();
    }
    return _SettingsRow(
      icon: Icons.favorite_outline,
      title: 'Apple Health',
      subtitle: _requested
          ? 'Requested. Mapped habits update when the app opens.'
          : 'Allow access, then map habits to steps, sleep, and more.',
      onTap: _connect,
    );
  }
}

class _FailedCapturesRow extends ConsumerStatefulWidget {
  const _FailedCapturesRow();

  @override
  ConsumerState<_FailedCapturesRow> createState() =>
      _FailedCapturesRowState();
}

class _FailedCapturesRowState extends ConsumerState<_FailedCapturesRow> {
  Future<void> _clear() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Discard unreadable captures?',
      message: 'These Siri captures could not be imported (unknown '
          'category, malformed data). Discarding cannot be undone.',
      confirmLabel: 'Discard them',
    );
    if (!confirmed || !mounted) return;
    await CaptureQueueDrain.clearFailed(ref.read(bridgePathsProvider));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    final int count;
    try {
      count = CaptureQueueDrain.failedCount(ref.watch(bridgePathsProvider));
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (count == 0) return const SizedBox.shrink();

    return _SettingsRow(
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.watch,
      title: count == 1
          ? '1 Siri capture couldn\'t be read'
          : '$count Siri captures couldn\'t be read',
      subtitle: 'Kept for review. Tap to discard.',
      onTap: _clear,
    );
  }
}

/// Which symbol money is shown with.
///
/// Display only — amounts are stored as integer cents in one currency
/// and never converted, so this relabels figures rather than
/// recalculating them. The row says so, because a money app that
/// silently "converted" would be worse than one that can't.
class _CurrencyRow extends ConsumerStatefulWidget {
  const _CurrencyRow();

  @override
  ConsumerState<_CurrencyRow> createState() => _CurrencyRowState();
}

class _CurrencyRowState extends ConsumerState<_CurrencyRow> {
  Future<void> _pick() async {
    final prefs = ref.read(preferencesProvider);
    await showAppSheet<void>(
      context,
      builder: (sheetContext) => AppSheet(
        title: 'Currency symbol',
        subtitle: 'Changes how amounts are shown. Your numbers stay '
            'exactly as they are — nothing is converted.',
        children: [
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final symbol in CurrencyOptions.symbols)
                ChoiceChip(
                  label: Text(symbol),
                  selected: Formatters.currencySymbol == symbol,
                  onSelected: (_) async {
                    await prefs.setCurrencySymbol(symbol);
                    Formatters.configureCurrency(
                      symbol: symbol,
                      locale: Formatters.numberLocale,
                    );
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      icon: Icons.attach_money,
      title: 'Currency',
      value: Formatters.currencySymbol,
      onTap: _pick,
    );
  }
}

/// Recent failures, on device only.
///
/// The app deliberately has no analytics and no crash reporter, which
/// also meant a user could say no more than "it didn't work" — and
/// nobody could find out why. This shows the in-memory error ring and
/// offers to copy it, so a bug report can carry evidence without any
/// data leaving the device.
class _DiagnosticsRow extends ConsumerStatefulWidget {
  const _DiagnosticsRow();

  @override
  ConsumerState<_DiagnosticsRow> createState() => _DiagnosticsRowState();
}

class _DiagnosticsRowState extends ConsumerState<_DiagnosticsRow> {
  Future<void> _open() async {
    final log = ref.read(errorLogProvider);
    final text = log.asText();
    await showAppSheet<void>(
      context,
      builder: (sheetContext) => AppSheet(
        title: 'Diagnostics',
        children: [
          Text(
            log.isEmpty
                ? 'Nothing has gone wrong this session.'
                : 'Recent problems, newest first. This stays on your '
                    'device — copy it if you want to report something.',
            style: Theme.of(sheetContext).textTheme.bodySmall,
          ),
          if (!log.isEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: Theme.of(sheetContext).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              child: SelectableText(
                text,
                style: const TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            AppSheetButton(
              label: 'Copy',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
            ),
            const SizedBox(height: AppSpace.sm),
            TextButton(
              onPressed: () {
                log.clear();
                Navigator.of(sheetContext).pop();
              },
              child: const Text('Clear'),
            ),
          ],
        ],
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.read(errorLogProvider).entries.length;
    return _SettingsRow(
      icon: Icons.bug_report_outlined,
      title: 'Diagnostics',
      subtitle: count == 0
          ? 'Nothing has gone wrong this session.'
          : count == 1
              ? '1 problem recorded this session.'
              : '$count problems recorded this session.',
      onTap: _open,
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
          title: AppConstants.appName,
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

/// Serializes everything and opens the OS share sheet anchored to
/// [context]'s render box (iPad popover contract). The clipboard is an
/// explicit opt-in fallback — a whole-database copy never lands there
/// silently, because synced clipboards leak.
Future<void> _runExport(BuildContext context, WidgetRef ref) async {
  // Anchor the share popover (required by iPad; ignored elsewhere).
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;

  final String json;
  try {
    json = await ref.read(backupServiceProvider).exportJson();
  } catch (_) {
    if (!context.mounted) return;
    showErrorSnack(context, "That didn't export. Try again.");
    return;
  }

  Future<void> markBackedUp() => ref
      .read(settingsRepositoryProvider)
      .setValue(SettingsKeys.lastBackupAt, DateTime.now().toIso8601String());

  void offerClipboardFallback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share dismissed. Copy it instead?'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: json));
            await markBackedUp();
          },
        ),
      ),
    );
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
        text: '${AppConstants.appName} backup',
        sharePositionOrigin: origin,
      );
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(json);
      result = await Share.shareXFiles(
        [XFile(file.path)],
        text: '${AppConstants.appName} backup',
        sharePositionOrigin: origin,
      );
    }
    if (!context.mounted) return;
    if (result.status == ShareResultStatus.success) {
      await markBackedUp();
      if (!context.mounted) return;
      showSuccessSnack(context, 'Backup saved.');
    } else {
      offerClipboardFallback();
    }
  } catch (_) {
    // Share unavailable on this platform; offer the clipboard explicitly.
    if (!context.mounted) return;
    offerClipboardFallback();
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

class _NameSheet extends ConsumerStatefulWidget {
  const _NameSheet({required this.settings});

  final UserSettings settings;

  static Future<void> show(
    BuildContext context, {
    required UserSettings settings,
  }) =>
      showAppSheet<void>(
        context,
        builder: (_) => _NameSheet(settings: settings),
      );

  @override
  ConsumerState<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends ConsumerState<_NameSheet> {
  late final _name = TextEditingController(
    text: widget.settings.displayName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    await ref.read(settingsControllerProvider).setDisplayName(_name.text);
    Haptics.medium();
    if (!mounted) return;
    showSuccessSnack(context, 'Saved.');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Your name',
      subtitle: 'Used for greetings only. Leave it empty to skip.',
      footer: AppSheetButton(label: 'Save', onPressed: _save),
      children: [
        AppTextField(
          label: 'Name',
          hint: 'What should we call you?',
          controller: _name,
          autofocus: true,
        ),
      ],
    );
  }
}

/// Which optional modules the Today screen shows.
class _AreasCard extends ConsumerWidget {
  const _AreasCard({required this.settings});

  final UserSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today shows these areas',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 2),
          Text(
            'Your goal always shows. Turn the rest on or off.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final area in DashboardArea.values)
                FilterChip(
                  label: Text(area.label),
                  selected: settings.showsArea(area),
                  onSelected: (on) {
                    Haptics.select();
                    final next = {...settings.dashboardAreas};
                    on ? next.add(area) : next.remove(area);
                    ref
                        .read(settingsControllerProvider)
                        .setDashboardAreas(next);
                  },
                ),
            ],
          ),
        ],
      ),
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
      subtitle: 'Used for age-based countdowns. Nothing else.',
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
    this.app,
    this.schemaVersion,
    this.exportedAt,
    this.recordCount,
    required this.hasData,
  });

  final String? app;
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
        app: decoded['app']?.toString(),
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
      return "That file doesn't look like a ${AppConstants.appName} backup.";
    }
    // Only our own exports (current or pre-rename) may replace the
    // database — any other JSON with a `data` key used to slip through.
    if (envelope.app != AppConstants.appName &&
        envelope.app != BackupService.legacyAppName) {
      return "That file doesn't look like a ${AppConstants.appName} backup.";
    }
    // A record-free backup could only erase; refuse it up front.
    if ((envelope.recordCount ?? 0) == 0) {
      return 'This backup contains no records.';
    }
    final version = int.tryParse(envelope.schemaVersion ?? '');
    final current = int.parse(AppConstants.exportSchemaVersion);
    // Older backups import fine (they're normalized on the way in); only a
    // backup from a NEWER app is unreadable.
    if (version != null && version > current) {
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
      _envelope =
          _paste.text.trim().isEmpty ? null : _Envelope.tryParse(_paste.text);
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
      message: 'Your current data is deleted and replaced with this backup. '
          'There is no undo.',
      confirmLabel: 'Replace data',
    );
    if (!confirmed || !mounted) return;

    final navigator = Navigator.of(context);
    // Safety copy of what's about to be replaced — the current data must
    // never have zero copies while a foreign file overwrites it.
    await AutoBackupService(
      BackupService(ref.read(databaseProvider)),
      ref.read(preferencesProvider),
    ).safetyCopy('pre_import');
    if (!mounted) return;
    // The next launch re-runs seed + legacy migration over the restored data.
    await ref.read(preferencesProvider).clearDataRevision();
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
          () =>
              _error = "That backup couldn't be restored. Nothing was changed.",
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
            _fileName == null
                ? 'Choose a backup file'
                : 'Choose a different file',
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
    final prefs = ref.read(preferencesProvider);
    // Safety copy first — "no undo" should mean "you chose not to",
    // never "there was no copy".
    await AutoBackupService(BackupService(db), prefs).safetyCopy('pre_reset');
    // A running timer's lock-screen Live Activity must end with the
    // timer, or it keeps counting with no way to dismiss it in-app.
    await ref.read(liveActivityServiceProvider).stopFocusTimer();
    // Queued Siri captures written before the reset would drain
    // afterwards and re-insert data the user just erased.
    if (!kIsWeb) {
      try {
        await ref.read(captureQueueDrainProvider).purgeAll();
      } catch (_) {
        // No bridge (tests, desktop): nothing queued to purge.
      }
    }
    // Clearing the revision first makes the next launch re-run seeding
    // even if the app dies between the clear and the re-seed below.
    await prefs.clearDataRevision();
    await prefs.clearRunningTimer();
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
          'Everything is deleted: your goal and its history, transactions, '
          'accounts, time blocks, habits, ideas, notes, journal, '
          'countdowns, reminders, and principles. Settings go back to the '
          'starter defaults. A safety copy is written to the backups '
          'folder first, but there is no in-app undo.',
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
