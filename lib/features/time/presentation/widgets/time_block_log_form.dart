import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_number_field.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/time_controller.dart';
import '../../domain/time_category.dart';
import 'time_budget_editor.dart';
import 'time_kind_icon.dart';

/// Log or edit hours against a category — the app's core input.
/// Quick chips cover the common cases; the keyboard is a fallback.
class TimeBlockLogForm extends ConsumerStatefulWidget {
  const TimeBlockLogForm({
    super.key,
    required this.budgets,
    this.block,
    this.initialBudgetId,
  });

  final List<TimeBudget> budgets;
  final TimeBlock? block;
  final String? initialBudgetId;

  static Future<void> show(
    BuildContext context, {
    required List<TimeBudget> budgets,
    TimeBlock? block,
    String? initialBudgetId,
  }) =>
      showAppSheet<void>(
        context,
        builder: (_) => TimeBlockLogForm(
          budgets: budgets,
          block: block,
          initialBudgetId: initialBudgetId,
        ),
      );

  @override
  ConsumerState<TimeBlockLogForm> createState() => _TimeBlockLogFormState();
}

class _TimeBlockLogFormState extends ConsumerState<TimeBlockLogForm> {
  static const _quickHours = [0.5, 1.0, 2.0, 4.0];

  final _formKey = GlobalKey<FormState>();
  late final _hours = TextEditingController(
      text: widget.block == null ? '' : Formatters.number(widget.block!.hours));
  late final _note = TextEditingController(text: widget.block?.note ?? '');
  String? _budgetId;
  late DateTime _date = widget.block == null
      ? DateTime.now()
      : AppDateUtils.parseDateKey(widget.block!.date);
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final budgets = ref.read(timeBudgetsProvider).valueOrNull ?? widget.budgets;
    final recent = ref.read(recentTimeBlocksProvider).valueOrNull;
    // Default to the most recently logged category, then the first one.
    var candidate = widget.block?.budgetId ??
        widget.initialBudgetId ??
        (recent != null && recent.isNotEmpty ? recent.first.budgetId : null);
    if (candidate != null && !budgets.any((b) => b.id == candidate)) {
      candidate = null;
    }
    _budgetId = candidate ?? (budgets.isEmpty ? null : budgets.first.id);
  }

  @override
  void dispose() {
    _hours.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _budgetId == null) return;
    final isNew = widget.block == null;
    final controller = ref.read(timeControllerProvider);
    final navigator = Navigator.of(context);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    try {
      if (isNew) {
        await controller.logBlock(
          budgetId: _budgetId!,
          date: _date,
          hours: Validators.parseNumber(_hours.text),
          note: note,
        );
      } else {
        await controller.updateBlock(widget.block!.copyWith(
          budgetId: _budgetId!,
          date: AppDateUtils.dateKey(_date),
          hours: Validators.parseNumber(_hours.text),
          note: Value(note),
        ));
      }
    } catch (_) {
      if (mounted) showErrorSnack(context, "That didn't save. Try again.");
      return;
    }
    // Light for a fresh log (a small win), medium for an edit save.
    if (isNew) {
      Haptics.light();
    } else {
      Haptics.medium();
    }
    if (!mounted) return;
    showSuccessSnack(context, isNew ? 'Logged.' : 'Saved.');
    navigator.pop();
  }

  Future<void> _delete() async {
    if (_deleting) return;
    _deleting = true;
    try {
      final block = widget.block!;
      final controller = ref.read(timeControllerProvider);
      final navigator = Navigator.of(context);
      final budgetId = block.budgetId;
      final date = AppDateUtils.parseDateKey(block.date);
      final hours = block.hours;
      final note = block.note;
      try {
        await controller.deleteBlock(block.id);
      } catch (_) {
        if (mounted) {
          showErrorSnack(context, "That didn't delete. Try again.");
        }
        return;
      }
      Haptics.medium();
      if (!mounted) return;
      showUndoSnack(
        context,
        '${Formatters.hours(hours)} removed.',
        onUndo: () => controller.logBlock(
          budgetId: budgetId,
          date: date,
          hours: hours,
          note: note,
        ),
      );
      navigator.pop();
    } finally {
      _deleting = false;
    }
  }

  void _fillHours(double value) {
    Haptics.select();
    setState(() => _hours.text = Formatters.number(value));
  }

  void _setDate(DateTime date) {
    Haptics.select();
    setState(() => _date = date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budgets =
        ref.watch(timeBudgetsProvider).valueOrNull ?? widget.budgets;
    final isNew = widget.block == null;

    _budgetId ??= budgets.isEmpty ? null : budgets.first.id;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final isToday = AppDateUtils.isSameDay(_date, now);
    final isYesterday = AppDateUtils.isSameDay(_date, yesterday);
    final customDate = !isToday && !isYesterday;
    final enteredHours = Validators.tryParseNumber(_hours.text);

    return AppSheet(
      title: isNew ? 'Log time' : 'Edit entry',
      subtitle: isNew
          ? 'Point hours at a category. The scoreboard does the rest.'
          : null,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetButton(
            label: isNew ? 'Log it' : 'Save',
            onPressed: budgets.isEmpty ? null : _save,
          ),
          if (!isNew) ...[
            const SizedBox(height: AppSpace.sm),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.critical,
              ),
              onPressed: _delete,
              child: const Text('Delete entry'),
            ),
          ],
        ],
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (budgets.isEmpty)
                _CreateCategoryFirst(theme: theme)
              else
                DropdownButtonFormField<String>(
                  initialValue: _budgetId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final b in budgets)
                      DropdownMenuItem(
                        value: b.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              TimeCategoryKind.parse(b.kind).icon,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Text(b.name),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    Haptics.select();
                    setState(() => _budgetId = v);
                  },
                  validator: (v) => v == null ? 'Pick a category.' : null,
                ),
              const SizedBox(height: AppSpace.md),
              AppNumberField(
                label: 'Hours',
                controller: _hours,
                suffixText: 'h',
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final base = Validators.positiveNumber(v, label: 'Hours');
                  if (base != null) return base;
                  if (Validators.parseNumber(v!) > 24) {
                    return 'A day maxes out at 24h.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final h in _quickHours)
                    _SelectChip(
                      label: Formatters.hours(h),
                      selected: enteredHours == h,
                      onTap: () => _fillHours(h),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  _SelectChip(
                    label: 'Today',
                    selected: isToday,
                    onTap: () => _setDate(now),
                  ),
                  _SelectChip(
                    label: 'Yesterday',
                    selected: isYesterday,
                    onTap: () => _setDate(yesterday),
                  ),
                  _SelectChip(
                    label: customDate
                        ? Formatters.shortDate(_date)
                        : 'Pick a date',
                    icon: Icons.calendar_today_outlined,
                    selected: customDate,
                    onTap: _pickDate,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              AppTextField(label: 'Note (optional)', controller: _note),
            ],
          ),
        ),
      ],
    );
  }
}

/// Inline dead-end escape: no categories means nowhere to log.
class _CreateCategoryFirst extends StatelessWidget {
  const _CreateCategoryFirst({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.elevated,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No categories yet', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Hours need somewhere to land. Create a category first.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 40),
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
              ),
              onPressed: () => TimeBudgetEditor.show(context),
              child: const Text('Create category'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small pill choice chip with a selection haptic handled by the caller.
class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected
          ? Color.alphaBlend(scheme.primaryTint, scheme.elevated)
          : scheme.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(
          color: selected ? scheme.primaryTintBorder : scheme.outlineFaint,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
