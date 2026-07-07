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

import '../../../core/providers.dart';
import '../../../core/storage/seed_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validation.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/app_number_field.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/settings_controller.dart';
import '../data/backup_service.dart';

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(databaseProvider)),
);

/// Settings: money numbers, birthday, theme, philosophy, notifications,
/// export/import, and full reset.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settings == null
          ? const LoadingView()
          : ContentWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  const SectionHeader(title: 'Money'),
                  ListTile(
                    title: const Text('Net monthly income'),
                    subtitle: Text(Formatters.money(settings.monthlyNetIncome)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editNumber(
                      context,
                      ref,
                      title: 'Net monthly income',
                      initial: settings.monthlyNetIncome,
                      onSave: (v) => ref
                          .read(settingsControllerProvider)
                          .setMonthlyNetIncome(v),
                    ),
                  ),
                  ListTile(
                    title: const Text('Target surplus range'),
                    subtitle: Text(
                        '${Formatters.money(settings.targetSurplusLow)} – ${Formatters.money(settings.targetSurplusHigh)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editSurplusRange(context, ref, settings),
                  ),
                  ListTile(
                    title: const Text('Budget targets'),
                    subtitle: const Text('Edit categories on the Money screen'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/money'),
                  ),
                  const SectionHeader(title: 'Time'),
                  ListTile(
                    title: const Text('Weekly time targets'),
                    subtitle: const Text('Edit targets on the Time screen'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/time'),
                  ),
                  const SectionHeader(title: 'Profile'),
                  ListTile(
                    title: const Text('Birthday'),
                    subtitle: Text(settings.birthday == null
                        ? 'Not set — needed for the age-28 countdown'
                        : Formatters.fullDate(settings.birthday!)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: settings.birthday ?? DateTime(1999),
                        firstDate: DateTime(1940),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        await ref
                            .read(settingsControllerProvider)
                            .setBirthday(picked);
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Philosophy line'),
                    subtitle: Text(settings.philosophyText),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editPhilosophy(context, ref, settings),
                  ),
                  const SectionHeader(title: 'Appearance'),
                  ListTile(
                    title: const Text('Theme'),
                    trailing: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                            value: ThemeMode.system, label: Text('Auto')),
                        ButtonSegment(
                            value: ThemeMode.dark, label: Text('Dark')),
                        ButtonSegment(
                            value: ThemeMode.light, label: Text('Light')),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (s) => ref
                          .read(settingsControllerProvider)
                          .setThemeMode(s.first),
                    ),
                  ),
                  const SectionHeader(title: 'Notifications'),
                  ListTile(
                    title: const Text('Reminders'),
                    subtitle:
                        const Text('Manage times and messages per reminder'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/reminders'),
                  ),
                  const SectionHeader(title: 'Data'),
                  ListTile(
                    leading: const Icon(Icons.ios_share_outlined),
                    title: const Text('Export / share data'),
                    subtitle: const Text(
                        'Share a JSON backup (also copied to clipboard)'),
                    onTap: () => _export(context, ref),
                  ),
                  ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: const Text('Import data from JSON'),
                    subtitle: const Text('Choose a file or paste; replaces all data'),
                    onTap: () => _import(context, ref),
                  ),
                  ListTile(
                    leading: Icon(Icons.delete_forever_outlined,
                        color: Theme.of(context).colorScheme.error),
                    title: Text('Reset all data',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    subtitle: const Text('Wipes everything and re-seeds defaults'),
                    onTap: () => _reset(context, ref),
                  ),
                  const SectionHeader(title: 'About'),
                  const _AboutTile(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                    child: Text(
                      'Local-first. No account, no cloud, no analytics.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- helpers --------------------------------------------------------------

  void _editNumber(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required double initial,
    required Future<void> Function(double) onSave,
  }) {
    final controller = TextEditingController(text: initial.toString());
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 16),
              AppNumberField(
                label: title,
                controller: controller,
                validator: (v) => Validators.nonNegativeNumber(v, label: title),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final navigator = Navigator.of(sheetContext);
                  await onSave(Validators.parseNumber(controller.text));
                  navigator.pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editSurplusRange(BuildContext context, WidgetRef ref, settings) {
    final low =
        TextEditingController(text: settings.targetSurplusLow.toString());
    final high =
        TextEditingController(text: settings.targetSurplusHigh.toString());
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Target surplus range',
                  style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 16),
              AppNumberField(
                label: 'Low',
                controller: low,
                validator: (v) => Validators.number(v, label: 'Low'),
              ),
              const SizedBox(height: 12),
              AppNumberField(
                label: 'High',
                controller: high,
                validator: (v) {
                  final base = Validators.number(v, label: 'High');
                  if (base != null) return base;
                  final lowValue = Validators.tryParseNumber(low.text);
                  if (lowValue != null &&
                      Validators.parseNumber(v!) < lowValue) {
                    return 'High must be at or above low.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final navigator = Navigator.of(sheetContext);
                  await ref.read(settingsControllerProvider).setTargetSurplus(
                        low: Validators.parseNumber(low.text),
                        high: Validators.parseNumber(high.text),
                      );
                  navigator.pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editPhilosophy(BuildContext context, WidgetRef ref, settings) {
    final controller = TextEditingController(text: settings.philosophyText);
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Philosophy line',
                  style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Shown at the top of the dashboard',
                controller: controller,
                validator: (v) => Validators.required(v, label: 'Text'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final navigator = Navigator.of(sheetContext);
                  await ref
                      .read(settingsControllerProvider)
                      .setPhilosophyText(controller.text.trim());
                  navigator.pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    // Anchor the share popover (required by iPad; ignored elsewhere).
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      final json = await ref.read(backupServiceProvider).exportJson();
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = 'life_dashboard_export_$stamp.json';

      // Clipboard is a universal fallback the user can always rely on.
      await Clipboard.setData(ClipboardData(text: json));

      if (kIsWeb) {
        final xfile = XFile.fromData(
          utf8.encode(json),
          name: fileName,
          mimeType: 'application/json',
        );
        await Share.shareXFiles([xfile],
            text: 'Life Dashboard backup', sharePositionOrigin: origin);
        messenger.showSnackBar(
            const SnackBar(content: Text('Backup ready. Also copied to clipboard.')));
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(json);
        await Share.shareXFiles([XFile(file.path)],
            text: 'Life Dashboard backup', sharePositionOrigin: origin);
        messenger.showSnackBar(
            const SnackBar(content: Text('Backup shared. Also copied to clipboard.')));
      }
    } catch (_) {
      // Share can be cancelled or unavailable; the clipboard copy still stands.
      messenger.showSnackBar(const SnackBar(
          content: Text('Export copied to clipboard.')));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Import from JSON',
                  style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Choose a .json backup file, or paste one below. This replaces ALL current data.',
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
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
                    setSheetState(() => controller.text = content);
                  } catch (_) {
                    messenger.showSnackBar(const SnackBar(
                        content: Text('Could not read that file.')));
                  }
                },
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Choose .json file'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '{ "app": "Life Dashboard", ... }',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  final navigator = Navigator.of(sheetContext);
                  final messenger = ScaffoldMessenger.of(context);
                  if (controller.text.trim().isEmpty) {
                    messenger.showSnackBar(const SnackBar(
                        content: Text('Choose a file or paste JSON first.')));
                    return;
                  }
                  final confirmed = await showConfirmDialog(
                    sheetContext,
                    title: 'Replace all data?',
                    message:
                        'Current data is deleted and replaced by the backup.',
                    confirmLabel: 'Import',
                  );
                  if (!confirmed) return;
                  final result = await ref
                      .read(backupServiceProvider)
                      .importJson(controller.text);
                  result.when(
                    success: (count) {
                      navigator.pop();
                      messenger.showSnackBar(SnackBar(
                          content: Text('Imported $count records.')));
                    },
                    failure: (message) {
                      messenger.showSnackBar(SnackBar(content: Text(message)));
                    },
                  );
                },
                child: const Text('Import'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reset all data?',
      message:
          'Every metric, transaction, time block, habit, idea, goal, and reminder is deleted. Defaults are re-seeded. This cannot be undone.',
      confirmLabel: 'Reset everything',
    );
    if (!confirmed) return;
    final db = ref.read(databaseProvider);
    await db.clearAllTables();
    await SeedService(db).seedIfNeeded();
    messenger.showSnackBar(
        const SnackBar(content: Text('All data reset to defaults.')));
  }
}

/// Shows the app name and version from the platform package metadata.
class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final version = info == null
            ? '…'
            : 'v${info.version} (${info.buildNumber})';
        return ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Life Dashboard'),
          subtitle: Text(version),
        );
      },
    );
  }
}
