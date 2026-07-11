import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../application/journal_controller.dart';

/// Write or edit one journal entry. New entries land on today; editing
/// keeps the entry on the day it was written.
class JournalEntrySheet extends ConsumerStatefulWidget {
  const JournalEntrySheet({super.key, this.entry});

  final JournalEntry? entry;

  static Future<void> show(BuildContext context, {JournalEntry? entry}) =>
      showAppSheet<void>(
        context,
        builder: (_) => JournalEntrySheet(entry: entry),
      );

  @override
  ConsumerState<JournalEntrySheet> createState() => _JournalEntrySheetState();
}

class _JournalEntrySheetState extends ConsumerState<JournalEntrySheet> {
  late final _content = TextEditingController(
    text: widget.entry?.content ?? '',
  );
  bool _busy = false;

  /// Save failure shown inside the sheet — a snack would render behind
  /// the modal barrier and go unseen.
  String? _error;

  bool get _isEdit => widget.entry != null;

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _content.text.trim();
    if (text.isEmpty || _busy) return;
    _busy = true;
    setState(() => _error = null);
    final navigator = Navigator.of(context);
    try {
      final repo = ref.read(journalRepositoryProvider);
      if (widget.entry == null) {
        await repo.addEntry(text);
      } else {
        await repo.updateEntry(widget.entry!.copyWith(content: text));
      }
      Haptics.medium();
      navigator.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _error = "That didn't save. Try again.");
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    _busy = true;
    final navigator = Navigator.of(context);
    try {
      await ref.read(journalRepositoryProvider).deleteEntry(widget.entry!.id);
      Haptics.medium();
      navigator.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _error = "That didn't delete. Try again.");
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSheet(
      title: _isEdit ? 'Edit entry' : 'Tonight, in one line',
      subtitle: _isEdit
          ? Formatters.fullDate(AppDateUtils.parseDateKey(widget.entry!.date))
          : 'What happened, how it felt, what mattered. A sentence is '
              'plenty.',
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 16, color: theme.colorScheme.error),
                  const SizedBox(width: 6),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          AppSheetButton(
            label: _isEdit ? 'Save changes' : 'Save entry',
            onPressed: _save,
          ),
          if (_isEdit)
            TextButton(
              onPressed: _delete,
              child: Text(
                'Delete entry',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
      children: [
        TextField(
          controller: _content,
          autofocus: !_isEdit,
          minLines: 3,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'What happened today?',
          ),
        ),
      ],
    );
  }
}
