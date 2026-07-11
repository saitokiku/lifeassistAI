import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/target_date_row.dart';
import '../../application/focus_controller.dart';
import '../../domain/main_goal.dart';

/// Set or edit the main goal — the one outcome the app organizes itself
/// around. A title is all that's required; the why and a timeframe are
/// welcome but optional.
class MainGoalEditor extends ConsumerStatefulWidget {
  const MainGoalEditor({super.key, this.goal, this.replacing = false});

  /// The goal being edited; null when setting one for the first time.
  final MainGoal? goal;

  /// True when starting a fresh goal while an old one gets archived.
  final bool replacing;

  static Future<void> show(
    BuildContext context, {
    MainGoal? goal,
    bool replacing = false,
  }) async {
    final message = await showAppSheet<String>(
      context,
      builder: (_) => MainGoalEditor(goal: goal, replacing: replacing),
    );
    if (message != null && context.mounted) {
      showSuccessSnack(context, message);
    }
  }

  @override
  ConsumerState<MainGoalEditor> createState() => _MainGoalEditorState();
}

class _MainGoalEditorState extends ConsumerState<MainGoalEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(
      text: widget.replacing ? '' : widget.goal?.title ?? '');
  late final _why = TextEditingController(
      text: widget.replacing ? '' : widget.goal?.why ?? '');
  late DateTime? _targetDate =
      widget.replacing ? null : widget.goal?.targetDateTime;

  bool get _isNew => widget.goal == null || widget.replacing;

  @override
  void dispose() {
    _title.dispose();
    _why.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final controller = ref.read(focusControllerProvider);
    try {
      if (_isNew) {
        await controller.createGoal(
          title: _title.text.trim(),
          why: _why.text.trim(),
          targetDate: _targetDate,
        );
      } else {
        await controller.updateGoal(
          widget.goal!,
          title: _title.text.trim(),
          why: _why.text.trim(),
          targetDate: _targetDate,
          clearTargetDate: _targetDate == null,
        );
      }
      Haptics.medium();
      navigator.pop(_isNew ? 'Goal set. One step at a time.' : 'Saved.');
    } catch (_) {
      if (mounted) showErrorSnack(context, "That didn't save. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: _isNew ? 'Your main goal' : 'Edit goal',
      subtitle: _isNew
          ? 'The one outcome you most want to move toward right now.'
          : null,
      footer: AppSheetButton(
        label: _isNew ? 'Set goal' : 'Save',
        onPressed: _save,
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Goal',
                hint: 'e.g. Finish nursing school',
                controller: _title,
                autofocus: _isNew,
                validator: (v) => Validators.required(v, label: 'A goal'),
              ),
              const SizedBox(height: AppSpace.md),
              AppTextField(
                label: 'Why it matters (optional)',
                hint: 'In your own words.',
                controller: _why,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpace.sm),
              TargetDateRow(
                date: _targetDate,
                emptyLabel: 'Add a timeframe',
                onChanged: (d) => setState(() => _targetDate = d),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
