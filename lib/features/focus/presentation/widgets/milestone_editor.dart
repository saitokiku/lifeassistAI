import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_number_field.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/target_date_row.dart';
import '../../application/focus_controller.dart';
import '../../domain/milestone.dart';

/// Create or edit a milestone. A title is enough; a target date and a
/// tracked number are optional depth for milestones that want them.
class MilestoneEditor extends ConsumerStatefulWidget {
  const MilestoneEditor({super.key, this.milestone});

  final Goal? milestone;

  static Future<void> show(BuildContext context, {Goal? milestone}) async {
    final saved = await showAppSheet<bool>(
      context,
      builder: (_) => MilestoneEditor(milestone: milestone),
    );
    if (saved == true && context.mounted) {
      showSuccessSnack(context, 'Milestone saved.');
    }
  }

  @override
  ConsumerState<MilestoneEditor> createState() => _MilestoneEditorState();
}

class _MilestoneEditorState extends ConsumerState<MilestoneEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title =
      TextEditingController(text: widget.milestone?.title ?? '');
  late final _description =
      TextEditingController(text: widget.milestone?.description ?? '');
  late final _unit =
      TextEditingController(text: widget.milestone?.metricName ?? '');
  late final _current = TextEditingController(
      text: widget.milestone == null
          ? '0'
          : Formatters.number(widget.milestone!.currentValue));
  late final _target = TextEditingController(
      text: widget.milestone == null || widget.milestone!.targetValue <= 0
          ? ''
          : Formatters.number(widget.milestone!.targetValue));
  late DateTime? _targetDate = widget.milestone?.targetDateTime;

  /// Whether the numeric tracking fields are open. On by default only when
  /// the milestone already tracks a number.
  late bool _trackNumber = widget.milestone?.isMeasurable ?? false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _unit.dispose();
    _current.dispose();
    _target.dispose();
    super.dispose();
  }

  String? _validateTarget(String? value) {
    if (!_trackNumber) return null;
    final base = Validators.number(value, label: 'Target');
    if (base != null) return base;
    if (Validators.parseNumber(value!) <= 0) {
      return 'Target has to be above zero.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final controller = ref.read(focusControllerProvider);
    final description =
        _description.text.trim().isEmpty ? null : _description.text.trim();
    final metricName =
        !_trackNumber || _unit.text.trim().isEmpty ? null : _unit.text.trim();
    final currentValue =
        _trackNumber ? Validators.parseNumber(_current.text) : 0.0;
    final targetValue =
        _trackNumber ? Validators.parseNumber(_target.text) : 0.0;
    try {
      if (widget.milestone == null) {
        await controller.createMilestone(
          title: _title.text.trim(),
          description: description,
          metricName: metricName,
          currentValue: currentValue,
          targetValue: targetValue,
          targetDate: _targetDate,
        );
      } else {
        await controller.updateMilestone(widget.milestone!.copyWith(
          title: _title.text.trim(),
          description: Value(description),
          metricName: Value(metricName),
          currentValue: currentValue,
          targetValue: targetValue,
          targetDate: Value(
              _targetDate == null ? null : AppDateUtils.dateKey(_targetDate!)),
        ));
      }
      Haptics.medium();
      navigator.pop(true);
    } catch (_) {
      if (mounted) {
        showErrorSnack(context, "That didn't save. Try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.milestone == null;

    return AppSheet(
      title: isNew ? 'New milestone' : 'Edit milestone',
      subtitle: isNew ? 'A concrete step on the way to your goal.' : null,
      footer: AppSheetButton(label: 'Save', onPressed: _save),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Milestone',
                hint: 'e.g. First draft finished',
                controller: _title,
                autofocus: isNew,
                validator: (v) => Validators.required(v, label: 'A title'),
              ),
              const SizedBox(height: AppSpace.md),
              AppTextField(
                label: 'Notes (optional)',
                controller: _description,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpace.sm),
              TargetDateRow(
                date: _targetDate,
                onChanged: (d) => setState(() => _targetDate = d),
              ),
              const SizedBox(height: AppSpace.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Track a number'),
                subtitle: const Text(
                    'For milestones you can count toward, like 20,000 words.'),
                value: _trackNumber,
                onChanged: (v) {
                  Haptics.select();
                  setState(() => _trackNumber = v);
                },
              ),
              if (_trackNumber) ...[
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    Expanded(
                      child: AppNumberField(
                        label: 'Current',
                        controller: _current,
                        validator: (v) => _trackNumber
                            ? Validators.number(v, label: 'Current')
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: AppNumberField(
                        label: 'Target',
                        controller: _target,
                        validator: _validateTarget,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                AppTextField(
                  label: 'Unit (optional)',
                  hint: 'e.g. words, miles',
                  controller: _unit,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
