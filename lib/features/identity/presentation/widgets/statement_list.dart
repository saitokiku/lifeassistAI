import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/identity_controller.dart';
import '../../domain/life_philosophy.dart';
import 'statement_editor.dart';

/// Operating identity statements: one card, one row per line.
/// Swipe or use the row menu to delete — undo puts it right back.
class StatementList extends ConsumerWidget {
  const StatementList({super.key, required this.statements});

  final List<IdentityStatement> statements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (statements.isEmpty) {
      return EmptyState(
        icon: Icons.fingerprint,
        title: 'No statements yet',
        message:
            'One-liners you want to operate by. Try "I finish what I start."',
        actionLabel: 'Add statement',
        onAction: () => StatementEditor.show(context),
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Column(
        children: [
          for (var i = 0; i < statements.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.cardPadding,
                ),
                child: Container(
                  height: 1,
                  color: theme.colorScheme.outlineFaint,
                ),
              ),
            _StatementRow(statement: statements[i]),
          ],
        ],
      ),
    );
  }
}

class _StatementRow extends ConsumerWidget {
  const _StatementRow({required this.statement});

  final IdentityStatement statement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('statement-${statement.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpace.xl),
        color: AppColors.critical.withValues(alpha: 0.14),
        child: const Icon(
          Icons.delete_outline_rounded,
          size: 20,
          color: AppColors.critical,
        ),
      ),
      onDismissed: (_) => _deleteWithUndo(context, ref),
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpace.cardPadding,
          right: AppSpace.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                child: Text(
                  statement.content,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: theme.colorScheme.textTertiary,
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  StatementEditor.show(context, statement: statement);
                } else if (value == 'delete') {
                  _deleteWithUndo(context, ref);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteWithUndo(BuildContext context, WidgetRef ref) {
    final controller = ref.read(identityControllerProvider);
    final content = statement.content;
    Haptics.light();
    controller.deleteStatement(statement.id);
    showUndoSnack(context, 'Statement deleted.', onUndo: () {
      controller.createStatement(content);
    });
  }
}
