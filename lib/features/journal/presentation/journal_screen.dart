import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/haptics.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../application/journal_controller.dart';
import 'widgets/journal_entry_sheet.dart';

/// The journal: one honest line at a time, newest day first. The
/// composer lives at the top so writing costs seconds — no blank-page
/// ritual, no prompts to satisfy.
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _composer = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(journalRepositoryProvider).addEntry(text);
      Haptics.medium();
      _composer.clear();
    } catch (_) {
      if (mounted) showErrorSnack(context, "That didn't save. Try again.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = ref.watch(recentJournalProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: entries == null
            ? const SkeletonList()
            : ContentWidth(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.screen,
                    AppSpace.lg,
                    AppSpace.screen,
                    96,
                  ),
                  children: [
                    Row(
                      children: [
                        const ScreenBackButton(),
                        Text('Journal', style: theme.textTheme.headlineSmall),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'One honest line at a time. Nothing is required.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    _Composer(
                      controller: _composer,
                      saving: _saving,
                      onSave: _save,
                    ),
                    const SizedBox(height: AppSpace.xl),
                    if (entries.isEmpty)
                      const EmptyState(
                        icon: Icons.edit_note_rounded,
                        title: 'Nothing written yet',
                        message: 'A sentence about today is plenty. '
                            'Future you will thank you.',
                      )
                    else
                      ..._groupedByDay(context, entries),
                  ],
                ),
              ),
      ),
    );
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    if (AppDateUtils.isSameDay(day, now)) return 'Today';
    if (AppDateUtils.isSameDay(day, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return Formatters.shortDate(day);
  }

  List<Widget> _groupedByDay(
      BuildContext context, List<JournalEntry> entries) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];
    String? lastDate;
    for (final entry in entries) {
      if (entry.date != lastDate) {
        lastDate = entry.date;
        widgets.add(Padding(
          padding: const EdgeInsets.only(
            top: AppSpace.md,
            bottom: AppSpace.xs,
          ),
          child: Text(
            _dayLabel(AppDateUtils.parseDateKey(entry.date)),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ));
      }
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.cardGap),
        child: AppCard(
          onTap: () => JournalEntrySheet.show(context, entry: entry),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          child: Text(entry.content, style: theme.textTheme.bodyMedium),
        ),
      ));
    }
    return widgets;
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.saving,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSave(),
            decoration: const InputDecoration(
              hintText: 'What happened today?',
            ),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        IconButton.filled(
          tooltip: 'Save entry',
          onPressed: saving ? null : onSave,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_upward_rounded),
        ),
      ],
    );
  }
}
