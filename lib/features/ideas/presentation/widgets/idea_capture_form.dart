import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/ideas_controller.dart';
import '../../domain/parked_idea.dart';
import 'idea_snacks.dart';

/// Capture or edit a parked idea.
///
/// Capture is title-first: one field, one switch, done — parking a shiny
/// thing should cost almost nothing. The reflective prompts (description,
/// why tempting, potential value, category) sit behind "Add detail".
/// Editing opens with everything visible, and says nothing about cooling:
/// editing never restarts the clock, so we say nothing rather than lie.
class IdeaCaptureForm extends ConsumerStatefulWidget {
  const IdeaCaptureForm({super.key, this.idea, this.initialTitle});

  final ParkedIdea? idea;

  /// Capture-bus prefill (voice/shortcut capture).
  final String? initialTitle;

  static Future<void> show(
    BuildContext context, {
    ParkedIdea? idea,
    String? initialTitle,
  }) =>
      showAppSheet<void>(
        context,
        builder: (_) => IdeaCaptureForm(idea: idea, initialTitle: initialTitle),
      );

  @override
  ConsumerState<IdeaCaptureForm> createState() => _IdeaCaptureFormState();
}

class _IdeaCaptureFormState extends ConsumerState<IdeaCaptureForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(
      text: widget.idea?.title ?? widget.initialTitle ?? '');
  late final _description =
      TextEditingController(text: widget.idea?.description ?? '');
  late final _category =
      TextEditingController(text: widget.idea?.category ?? '');
  late final _whyTempting =
      TextEditingController(text: widget.idea?.whyTempting ?? '');
  late final _potentialValue =
      TextEditingController(text: widget.idea?.potentialValue ?? '');
  late bool _helpsGoal = widget.idea?.helpsMainGoal ?? false;

  /// Detail is collapsed on capture, expanded on edit.
  late bool _showDetail = widget.idea != null;

  /// Guards the keyboard-done path against double submits; the sheet
  /// button already guards itself.
  bool _saving = false;

  /// Save failure shown inside the sheet — a snack would render behind
  /// the modal barrier and go unseen.
  String? _error;

  bool get _isEdit => widget.idea != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _category.dispose();
    _whyTempting.dispose();
    _potentialValue.dispose();
    super.dispose();
  }

  String? _emptyToNull(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _saving = true;
    setState(() => _error = null);
    final controller = ref.read(ideasControllerProvider);
    // Captured before any await; the sheet pops before the snack shows.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final textTheme = Theme.of(context).textTheme;
    try {
      if (widget.idea == null) {
        // The repository owns the review date — cooling cannot be skipped
        // or shortened at capture, so the form never passes one.
        await controller.captureIdea(
          title: _title.text.trim(),
          description: _emptyToNull(_description),
          category: _emptyToNull(_category),
          whyTempting: _emptyToNull(_whyTempting),
          potentialValue: _emptyToNull(_potentialValue),
          helpsMainGoal: _helpsGoal,
        );
      } else {
        // Full-row update. dateCaptured, reviewDate, decision, and
        // createdAt ride along untouched — editing never resets the
        // cooling clock or the verdict.
        await controller.updateIdea(widget.idea!.copyWith(
          title: _title.text.trim(),
          description: Value(_emptyToNull(_description)),
          category: Value(_emptyToNull(_category)),
          whyTempting: Value(_emptyToNull(_whyTempting)),
          potentialValue: Value(_emptyToNull(_potentialValue)),
          helpsMainGoal: _helpsGoal,
        ));
      }
      Haptics.medium();
      navigator.pop();
      showIdeaSuccessSnack(
        messenger,
        textTheme,
        _isEdit ? 'Updated.' : 'Parked. Let it cool.',
      );
    } catch (_) {
      // The sheet stays open for retry, so the error must live inside it.
      if (mounted) {
        setState(() => _error = "That didn't save. Try again.");
      } else {
        showIdeaErrorSnack(
            messenger, textTheme, "That didn't save. Try again.");
      }
    } finally {
      _saving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: _isEdit ? 'Edit idea' : 'Park an idea',
      subtitle: _isEdit
          ? null
          : 'It cools for ${AppConstants.ideaCoolingDays} days, '
              'then gets a verdict.',
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
                      size: 16, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 6),
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
              ),
            ),
          AppSheetButton(
            label: _isEdit ? 'Save changes' : 'Park it',
            onPressed: _save,
          ),
        ],
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                autofocus: !_isEdit,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                validator: (v) => Validators.required(v, label: 'Title'),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'The shiny thing, in one line',
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Directly helps my main goal'),
                subtitle: const Text('The only way to skip cooling.'),
                value: _helpsGoal,
                onChanged: (v) {
                  Haptics.select();
                  setState(() => _helpsGoal = v);
                },
              ),
              if (!_showDetail)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      Haptics.select();
                      setState(() => _showDetail = true);
                    },
                    icon: const Icon(Icons.expand_more_rounded, size: 18),
                    label: const Text('Add detail'),
                  ),
                )
              else ...[
                const SizedBox(height: AppSpace.xs),
                AppTextField(
                  label: 'Description',
                  controller: _description,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpace.md),
                AppTextField(
                  label: 'Why is it tempting?',
                  controller: _whyTempting,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpace.md),
                AppTextField(
                  label: 'Potential value',
                  controller: _potentialValue,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpace.md),
                AppTextField(label: 'Category', controller: _category),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
