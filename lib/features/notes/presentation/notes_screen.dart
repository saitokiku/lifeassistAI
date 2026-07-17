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
import '../../../shared/widgets/section_header.dart';
import '../application/notes_controller.dart';
import '../domain/note.dart';

/// The vault: every note, newest thought first. Writing is one tap;
/// linking is two brackets. Tag chips narrow the list; archived notes
/// stay tucked away until asked for.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key, this.initialTag});

  /// Pre-selected tag filter (deep link `/notes?tag=x`, tag taps).
  final String? initialTag;

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String? _tag;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _tag = widget.initialTag;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = ref.watch(allNotesProvider).valueOrNull;
    final tagRows = ref.watch(allTagRowsProvider).valueOrNull ?? const [];
    final linkCount = ref.watch(noteLinkCountProvider).valueOrNull ?? 0;

    if (all == null) {
      return const Scaffold(body: SafeArea(child: SkeletonList()));
    }

    // Tag → note ids, and the distinct chip row.
    final taggedIds = <String, Set<String>>{};
    for (final row in tagRows) {
      taggedIds.putIfAbsent(row.tag, () => {}).add(row.noteId);
    }
    final tags = taggedIds.keys.toList()..sort();
    // A stale filter (tag edited away) silently clears.
    final tag = (_tag != null && taggedIds.containsKey(_tag)) ? _tag : null;

    bool matches(Note n) => tag == null || taggedIds[tag]!.contains(n.id);
    final active =
        [for (final n in all) if (!n.isArchived && matches(n)) n];
    final archived =
        [for (final n in all) if (n.isArchived && matches(n)) n];
    final activeTotal = all.where((n) => !n.isArchived).length;

    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
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
                  IconButton(
                    tooltip: 'Graph',
                    onPressed: () => context.push('/notes/graph'),
                    icon: const Icon(Icons.hub_outlined),
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
                activeTotal == 0
                    ? 'Think in links: [[connect]] notes, #tag themes.'
                    : tag != null
                        ? '#$tag · ${active.length} '
                            'note${active.length == 1 ? '' : 's'}'
                        : '$activeTotal '
                            'note${activeTotal == 1 ? '' : 's'} · '
                            '$linkCount link${linkCount == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: AppSpace.md),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: tags.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpace.xs),
                    itemBuilder: (context, i) {
                      final t = tags[i];
                      final selected = t == tag;
                      return FilterChip(
                        label: Text('#$t'),
                        selected: selected,
                        showCheckmark: false,
                        labelStyle: theme.textTheme.labelMedium?.copyWith(
                          color: selected
                              ? AppColors.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        onSelected: (_) =>
                            setState(() => _tag = selected ? null : t),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.lg),
              if (activeTotal == 0)
                EmptyState(
                  icon: Icons.hub_outlined,
                  title: 'Your vault is empty',
                  message: 'Write anything. Wrap a phrase in '
                      '[[double brackets]] and the graph starts '
                      'growing on its own.',
                  actionLabel: 'First note',
                  onAction: () => context.push('/notes/new'),
                )
              else if (active.isEmpty && archived.isEmpty)
                EmptyState(
                  icon: Icons.tag_rounded,
                  title: 'Nothing under #$tag',
                  message: 'That tag lives on other notes. Clear the '
                      'filter to see everything.',
                  actionLabel: 'Clear filter',
                  onAction: () => setState(() => _tag = null),
                )
              else ...[
                for (final note in active)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.cardGap),
                    child: _NoteRow(note: note),
                  ),
                if (archived.isNotEmpty) ...[
                  if (_showArchived) ...[
                    const SectionHeader(title: 'Archived'),
                    for (final note in archived)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpace.cardGap),
                        child: Opacity(
                          opacity: 0.55,
                          child: _NoteRow(note: note),
                        ),
                      ),
                  ],
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _showArchived = !_showArchived),
                      child: Text(
                        _showArchived
                            ? 'Hide archived'
                            : 'Show archived (${archived.length})',
                      ),
                    ),
                  ),
                ],
              ],
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
