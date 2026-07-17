import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../application/notes_controller.dart';
import '../domain/note.dart';

/// The vault: every note, newest thought first. Writing is one tap;
/// linking is two brackets.
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notes = ref.watch(notesProvider).valueOrNull;
    final linkCount = ref.watch(noteLinkCountProvider).valueOrNull ?? 0;

    return Scaffold(
      body: SafeArea(
        child: notes == null
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
                        Expanded(
                          child: Text(
                            'Notes',
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                        IconButton.filled(
                          tooltip: 'New note',
                          onPressed: () => context.push('/notes/new'),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      notes.isEmpty
                          ? 'Think in links: [[connect]] notes, #tag themes.'
                          : '${notes.length} '
                              'note${notes.length == 1 ? '' : 's'} · '
                              '$linkCount link${linkCount == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    if (notes.isEmpty)
                      EmptyState(
                        icon: Icons.hub_outlined,
                        title: 'Your vault is empty',
                        message: 'Write anything. Wrap a phrase in '
                            '[[double brackets]] and the graph starts '
                            'growing on its own.',
                        actionLabel: 'First note',
                        onAction: () => context.push('/notes/new'),
                      )
                    else
                      for (final note in notes)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpace.cardGap),
                          child: _NoteRow(note: note),
                        ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _NoteRow extends ConsumerWidget {
  const _NoteRow({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tags = ref.watch(noteTagsProvider(note.id)).valueOrNull ?? const [];
    final preview = note.preview;

    return AppCard(
      onTap: () => context.push('/notes/${note.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                Formatters.shortDate(note.updatedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.textTertiary,
                ),
              ),
            ],
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              children: [
                for (final t in tags.take(4))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryTint,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      '#${t.tag}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
