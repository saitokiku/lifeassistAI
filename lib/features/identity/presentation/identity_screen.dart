import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/identity_controller.dart';
import 'widgets/freedom_target_card.dart';
import 'widgets/goal_progress_list.dart';
import 'widgets/goals_editor.dart';
import 'widgets/philosophy_card.dart';
import 'widgets/statement_editor.dart';
import 'widgets/statement_list.dart';

/// Identity — the why behind the numbers: philosophy, the freedom target,
/// operating statements, and goals.
class IdentityScreen extends ConsumerWidget {
  const IdentityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statements = ref.watch(identityStatementsProvider);
    final goals = ref.watch(goalsProvider);
    final targets = ref.watch(freedomTargetsProvider);
    final state = ref.watch(identityStateProvider);

    final hasError = statements.hasError || goals.hasError || targets.hasError;

    final Widget body;
    if (hasError) {
      body = ErrorState(
        onRetry: () {
          ref.invalidate(identityStatementsProvider);
          ref.invalidate(goalsProvider);
          ref.invalidate(freedomTargetsProvider);
        },
      );
    } else if (state == null) {
      body = const SkeletonList();
    } else {
      body = ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.lg,
            AppSpace.screen,
            AppSpace.xxl,
          ),
          children: [
            Row(
              children: [
                const ScreenBackButton(),
                Text('Identity', style: theme.textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              'The why behind the numbers.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            PhilosophyCard(philosophyText: state.philosophyText),
            const SectionHeader(title: 'Freedom target'),
            FreedomTargetCard(target: state.primaryFreedomTarget),
            SectionHeader(
              title: 'Operating identity',
              trailing: TextButton.icon(
                onPressed: () => StatementEditor.show(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ),
            StatementList(statements: state.statements),
            SectionHeader(
              title: 'Goals',
              trailing: TextButton.icon(
                onPressed: () => GoalsEditor.show(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New goal'),
              ),
            ),
            GoalProgressList(goals: state.goals),
          ],
        ),
      );
    }

    return Scaffold(body: SafeArea(child: body));
  }
}
