import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/identity_controller.dart';
import '../../domain/life_philosophy.dart';

/// Create or edit an operating identity statement.
class StatementEditor extends ConsumerStatefulWidget {
  const StatementEditor({super.key, this.statement});

  final IdentityStatement? statement;

  static Future<void> show(BuildContext context,
      {IdentityStatement? statement}) async {
    final saved = await showAppSheet<bool>(
      context,
      builder: (_) => StatementEditor(statement: statement),
    );
    if (saved == true && context.mounted) {
      showSuccessSnack(context, 'Saved.');
    }
  }

  @override
  ConsumerState<StatementEditor> createState() => _StatementEditorState();
}

class _StatementEditorState extends ConsumerState<StatementEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _content =
      TextEditingController(text: widget.statement?.content ?? '');

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final controller = ref.read(identityControllerProvider);
    final text = _content.text.trim();
    try {
      if (widget.statement == null) {
        await controller.createStatement(text);
      } else {
        await controller
            .updateStatement(widget.statement!.copyWith(content: text));
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
    return AppSheet(
      title: widget.statement == null ? 'New statement' : 'Edit statement',
      subtitle: 'One line you operate by.',
      footer: AppSheetButton(label: 'Save', onPressed: _save),
      children: [
        Form(
          key: _formKey,
          child: AppTextField(
            label: 'Statement',
            hint: 'e.g. The W-2 is funding, not identity.',
            controller: _content,
            maxLines: 2,
            autofocus: true,
            validator: (v) => Validators.required(v, label: 'Statement'),
          ),
        ),
      ],
    );
  }
}
