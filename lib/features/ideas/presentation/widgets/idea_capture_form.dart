import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/ideas_controller.dart';
import '../../domain/parked_idea.dart';

/// Capture or edit a parked idea. Review date auto-sets 7 days out.
class IdeaCaptureForm extends ConsumerStatefulWidget {
  const IdeaCaptureForm({super.key, this.idea});

  final ParkedIdea? idea;

  static Future<void> show(BuildContext context, {ParkedIdea? idea}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => IdeaCaptureForm(idea: idea),
      );

  @override
  ConsumerState<IdeaCaptureForm> createState() => _IdeaCaptureFormState();
}

class _IdeaCaptureFormState extends ConsumerState<IdeaCaptureForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.idea?.title ?? '');
  late final _description =
      TextEditingController(text: widget.idea?.description ?? '');
  late final _category =
      TextEditingController(text: widget.idea?.category ?? '');
  late final _whyTempting =
      TextEditingController(text: widget.idea?.whyTempting ?? '');
  late final _potentialValue =
      TextEditingController(text: widget.idea?.potentialValue ?? '');
  late bool _helpsKaizen = widget.idea?.directlyHelpsKaizenThisWeek ?? false;

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
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(ideasControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      if (widget.idea == null) {
        await controller.captureIdea(
          title: _title.text.trim(),
          description: _emptyToNull(_description),
          category: _emptyToNull(_category),
          whyTempting: _emptyToNull(_whyTempting),
          potentialValue: _emptyToNull(_potentialValue),
          directlyHelpsKaizenThisWeek: _helpsKaizen,
        );
      } else {
        await controller.updateIdea(widget.idea!.copyWith(
          title: _title.text.trim(),
          description: Value(_emptyToNull(_description)),
          category: Value(_emptyToNull(_category)),
          whyTempting: Value(_emptyToNull(_whyTempting)),
          potentialValue: Value(_emptyToNull(_potentialValue)),
          directlyHelpsKaizenThisWeek: _helpsKaizen,
        ));
      }
      navigator.pop();
      messenger.showSnackBar(
          const SnackBar(content: Text(AppCopy.curiosityCaptured)));
    } catch (_) {
      messenger
          .showSnackBar(const SnackBar(content: Text('Could not save idea.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.idea == null ? 'Park an idea' : 'Edit idea',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'It cools for ${AppConstants.ideaCoolingDays} days unless it directly helps Kaizen this week.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Title',
                controller: _title,
                validator: (v) => Validators.required(v, label: 'Title'),
                autofocus: widget.idea == null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Description', controller: _description, maxLines: 2),
              const SizedBox(height: 12),
              AppTextField(label: 'Category', controller: _category),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Why is it tempting?',
                  controller: _whyTempting,
                  maxLines: 2),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Potential value',
                  controller: _potentialValue,
                  maxLines: 2),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Directly helps Kaizen this week'),
                subtitle: const Text('Only then can it skip cooling.'),
                value: _helpsKaizen,
                onChanged: (v) => setState(() => _helpsKaizen = v),
              ),
              FilledButton(onPressed: _save, child: const Text('Park it')),
            ],
          ),
        ),
      ),
    );
  }
}
