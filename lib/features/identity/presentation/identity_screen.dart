import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validation.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/identity_controller.dart';
import '../domain/life_philosophy.dart';
import 'widgets/freedom_target_card.dart';
import 'widgets/goal_progress_list.dart';
import 'widgets/goals_editor.dart';
import 'widgets/philosophy_card.dart';

/// Identity module: philosophy, operating identity, goals, freedom target.
class IdentityScreen extends ConsumerWidget {
  const IdentityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(identityStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Identity')),
      body: state == null
          ? const LoadingView()
          : ContentWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  PhilosophyCard(philosophyText: state.philosophyText),
                  SectionHeader(
                    title: 'Current operating identity',
                    trailing: TextButton.icon(
                      onPressed: () => _addStatement(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                  ),
                  for (final statement in state.statements)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(Icons.person_outline, size: 20),
                      title: Text(statement.content),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () =>
                                _editStatement(context, ref, statement),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              final confirmed = await showConfirmDialog(
                                context,
                                title: 'Delete statement?',
                                message: 'Removes this identity statement.',
                              );
                              if (confirmed) {
                                await ref
                                    .read(identityControllerProvider)
                                    .deleteStatement(statement.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  const SectionHeader(title: 'Freedom target'),
                  FreedomTargetCard(target: state.primaryFreedomTarget),
                  SectionHeader(
                    title: 'Goals',
                    trailing: TextButton.icon(
                      onPressed: () => GoalsEditor.show(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New'),
                    ),
                  ),
                  GoalProgressList(goals: state.goals),
                ],
              ),
            ),
    );
  }

  void _addStatement(BuildContext context, WidgetRef ref) {
    _statementSheet(context, initial: '', onSave: (text) async {
      await ref.read(identityControllerProvider).createStatement(text);
    });
  }

  void _editStatement(
      BuildContext context, WidgetRef ref, IdentityStatement statement) {
    _statementSheet(context, initial: statement.content, onSave: (text) async {
      await ref
          .read(identityControllerProvider)
          .updateStatement(statement.copyWith(content: text));
    });
  }

  void _statementSheet(
    BuildContext context, {
    required String initial,
    required Future<void> Function(String) onSave,
  }) {
    final controller = TextEditingController(text: initial);
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
              Text('Identity statement',
                  style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Statement',
                controller: controller,
                validator: (v) => Validators.required(v, label: 'Statement'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final navigator = Navigator.of(sheetContext);
                  await onSave(controller.text.trim());
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
}
