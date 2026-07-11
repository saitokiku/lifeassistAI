import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/ai/ai_service.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../application/accounts_controller.dart';
import '../../application/money_controller.dart';
import '../../data/csv_import.dart';
import '../../../../core/utils/money.dart';

/// Import a bank-statement CSV as transactions: pick a file, confirm the
/// column mapping, see what will land, import. Duplicates (same day,
/// amount, and description as an existing row) are skipped and said so.
class CsvImportSheet extends ConsumerStatefulWidget {
  const CsvImportSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showAppSheet<void>(context, builder: (_) => const CsvImportSheet());

  @override
  ConsumerState<CsvImportSheet> createState() => _CsvImportSheetState();
}

class _CsvImportSheetState extends ConsumerState<CsvImportSheet> {
  String? _fileName;
  List<List<String>> _table = const [];
  int? _dateCol;
  int? _amountCol;
  int? _descriptionCol;
  String? _accountId;
  String? _error;
  bool _importing = false;

  /// AI category suggestions keyed by row index — applied per-row at
  /// import, only ever with names that exist.
  Map<int, String> _suggestions = const {};
  bool _suggesting = false;

  Future<void> _suggestCategories() async {
    final extraction = _extraction;
    if (extraction == null || extraction.rows.isEmpty || _suggesting) return;
    setState(() => _suggesting = true);
    try {
      final categories =
          ref.read(budgetCategoriesProvider).valueOrNull ?? const [];
      final suggested =
          await ref.read(aiServiceProvider).categorizeTransactions(
        [
          for (final (i, row) in extraction.rows.indexed)
            if (row.description.isNotEmpty)
              (id: '$i', description: row.description),
        ],
        categoryNames: [for (final c in categories) c.name],
      );
      if (!mounted) return;
      setState(() {
        _suggestions = {
          for (final entry in suggested.entries)
            if (int.tryParse(entry.key) case final index?)
              index: entry.value,
        };
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = "Suggestions didn't come through — "
            'importing works fine without them.');
      }
    } finally {
      if (mounted) setState(() => _suggesting = false);
    }
  }

  bool get _ready =>
      _table.isNotEmpty && _dateCol != null && _amountCol != null;

  CsvExtraction? get _extraction => !_ready
      ? null
      : CsvImport.extract(
          _table,
          dateColumn: _dateCol!,
          amountColumn: _amountCol!,
          descriptionColumn: _descriptionCol,
        );

  Future<void> _pickFile() async {
    setState(() => _error = null);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      final String content;
      if (picked.bytes != null) {
        content = utf8.decode(picked.bytes!, allowMalformed: true);
      } else if (picked.path != null) {
        content = await File(picked.path!).readAsString();
      } else {
        return;
      }
      final table = CsvImport.parse(content);
      if (table.isEmpty) {
        setState(() =>
            _error = "That file doesn't read as CSV. Try another export.");
        return;
      }
      final guess = CsvImport.guessMapping(table);
      if (!mounted) return;
      setState(() {
        _fileName = picked.name;
        _table = table;
        _dateCol = guess.date;
        _amountCol = guess.amount;
        _descriptionCol = guess.description;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = "Couldn't read that file. Try another one.");
      }
    }
  }

  Future<void> _import() async {
    final extraction = _extraction;
    if (extraction == null || _importing) return;
    if (extraction.rows.isEmpty) {
      setState(() => _error = 'Nothing importable with this mapping.');
      return;
    }
    setState(() {
      _importing = true;
      _error = null;
    });
    final controller = ref.read(moneyControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final textStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: AppColors.textPrimaryDark);
    try {
      final categories =
          ref.read(budgetCategoriesProvider).valueOrNull ?? const [];
      String? categoryIdFor(int index) {
        final name = _suggestions[index];
        if (name == null) return null;
        for (final c in categories) {
          if (c.name == name) return c.id;
        }
        return null;
      }

      final existing = await controller.recentDuplicateKeys();
      final seen = <String>{};
      final fresh = <({
        DateTime date,
        int amountCents,
        String description,
        String? categoryId,
      })>[];
      var duplicates = 0;
      for (final (index, row) in extraction.rows.indexed) {
        final key = CsvImport.duplicateKey(
          dateKey: AppDateUtils.dateKey(row.date),
          amountCents: row.amountCents,
          description: row.description,
        );
        if (existing.contains(key) || !seen.add(key)) {
          duplicates++;
          continue;
        }
        fresh.add((
          date: row.date,
          amountCents: row.amountCents,
          description: row.description,
          categoryId: categoryIdFor(index),
        ));
      }
      if (fresh.isNotEmpty) {
        await controller.importTransactions(fresh, accountId: _accountId);
      }
      Haptics.medium();
      navigator.pop();
      final parts = <String>[
        'Imported ${fresh.length} transaction${fresh.length == 1 ? '' : 's'}.',
        if (duplicates > 0)
          '$duplicates duplicate${duplicates == 1 ? '' : 's'} skipped.',
        if (extraction.skippedDeposits > 0)
          '${extraction.skippedDeposits} deposit'
              '${extraction.skippedDeposits == 1 ? '' : 's'} ignored.',
      ];
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(parts.join(' '), style: textStyle),
      ));
    } catch (_) {
      if (mounted) {
        setState(() {
          _importing = false;
          _error = "The import didn't finish. Nothing was half-written.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];
    final extraction = _extraction;

    return AppSheet(
      title: 'Import statement',
      subtitle: 'A CSV export from your bank becomes real transactions. '
          'Spending only — deposits are ignored.',
      footer: AppSheetButton(
        label: _importing
            ? 'Importing…'
            : extraction == null
                ? 'Import'
                : 'Import ${extraction.rows.length}',
        onPressed: _ready && !_importing ? _import : null,
      ),
      children: [
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.folder_open_outlined, size: 20),
          label: Text(
            _fileName == null ? 'Choose a CSV file' : 'Choose a different file',
          ),
        ),
        if (_fileName != null) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            '$_fileName · ${_table.length} rows',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (_table.isNotEmpty) ...[
          const SizedBox(height: AppSpace.lg),
          Text(
            'COLUMNS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          _columnPicker(
            label: 'Date',
            value: _dateCol,
            onChanged: (v) => setState(() => _dateCol = v),
          ),
          const SizedBox(height: AppSpace.sm),
          _columnPicker(
            label: 'Amount',
            value: _amountCol,
            onChanged: (v) => setState(() => _amountCol = v),
          ),
          const SizedBox(height: AppSpace.sm),
          _columnPicker(
            label: 'Description',
            value: _descriptionCol,
            optional: true,
            onChanged: (v) => setState(() => _descriptionCol = v),
          ),
          if (accounts.isNotEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            DropdownButtonFormField<String?>(
              initialValue: _accountId,
              decoration:
                  const InputDecoration(labelText: 'Tag account (optional)'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No account'),
                ),
                for (final a in accounts)
                  DropdownMenuItem<String?>(value: a.id, child: Text(a.name)),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
          ],
          if (extraction != null &&
              extraction.rows.isNotEmpty &&
              ref.watch(aiAvailabilityProvider).valueOrNull ==
                  AiAvailability.available) ...[
            const SizedBox(height: AppSpace.md),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _suggesting ? null : _suggestCategories,
                icon: _suggesting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 16),
                label: Text(_suggestions.isEmpty
                    ? 'Suggest categories (on-device)'
                    : '${_suggestions.length} categorized — tap to redo'),
              ),
            ),
          ],
          if (extraction != null) ...[
            const SizedBox(height: AppSpace.lg),
            Text(
              'PREVIEW',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            if (extraction.rows.isEmpty)
              Text(
                'Nothing parses with this mapping — check the date and '
                'amount columns.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.watch),
              )
            else ...[
              for (final row in extraction.rows.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.xs),
                  child: Row(
                    children: [
                      Text(
                        Formatters.shortDate(row.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFeatures: AppTypography.tabularFigures,
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Text(
                          row.description.isEmpty ? '—' : row.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Text(
                        Formatters.money(amountFromCents(row.amountCents)),
                        style: theme.textTheme.numberBody.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                [
                  '${extraction.rows.length} to import',
                  if (extraction.skippedDeposits > 0)
                    '${extraction.skippedDeposits} deposits ignored',
                  if (extraction.skippedUnparsed > 0)
                    "${extraction.skippedUnparsed} rows didn't parse",
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.textTertiary,
                ),
              ),
            ],
          ],
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpace.md),
          Text(
            _error!,
            style:
                theme.textTheme.bodySmall?.copyWith(color: AppColors.critical),
          ),
        ],
      ],
    );
  }

  Widget _columnPicker({
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
    bool optional = false,
  }) {
    final headers = _table.isNotEmpty && CsvImport.looksLikeHeader(_table.first)
        ? _table.first
        : null;
    final width = _table.isEmpty ? 0 : _table.first.length;
    return DropdownButtonFormField<int?>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        if (optional)
          const DropdownMenuItem<int?>(value: null, child: Text('None')),
        for (var i = 0; i < width; i++)
          DropdownMenuItem<int?>(
            value: i,
            child: Text(
              headers != null && headers[i].isNotEmpty
                  ? headers[i]
                  : 'Column ${i + 1}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) {
        Haptics.select();
        onChanged(v);
      },
    );
  }
}
