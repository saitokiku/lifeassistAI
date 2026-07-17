import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../application/graph_providers.dart';
import '../application/notes_controller.dart';
import '../graph/graph_model.dart';
import 'widgets/graph_view.dart';

/// The vault from above: every note a dot, every `[[link]]` a line.
/// Hollow dots are ghosts — linked-to notes that don't exist yet; tap
/// one and it does.
class NotesGraphScreen extends ConsumerWidget {
  const NotesGraphScreen({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    GraphNode node,
  ) async {
    if (node.isGhost) {
      final note = await ref
          .read(notesControllerProvider)
          .openOrCreateByTitle(node.title);
      if (context.mounted) unawaited(context.push('/notes/${note.id}'));
    } else {
      unawaited(context.push('/notes/${node.id}'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final layout = ref.watch(graphLayoutProvider);

    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  AppSpace.lg,
                  AppSpace.screen,
                  0,
                ),
                child: Row(
                  children: [
                    const ScreenBackButton(),
                    Expanded(
                      child: Text(
                        'Graph',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  AppSpace.xs,
                  AppSpace.screen,
                  AppSpace.sm,
                ),
                child: Text(
                  layout == null
                      ? 'Mapping the vault…'
                      : '${layout.graph.nodes.length} '
                          'node${layout.graph.nodes.length == 1 ? '' : 's'} · '
                          '${layout.graph.edges.length} '
                          'link${layout.graph.edges.length == 1 ? '' : 's'} — '
                          'pinch to zoom, drag to roam, tap to open.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: layout == null
                    ? const SkeletonList()
                    : layout.graph.edges.isEmpty
                        ? EmptyState(
                            icon: Icons.hub_outlined,
                            title: 'No connections yet',
                            message: 'Wrap a phrase in [[double brackets]] '
                                'inside any note and lines start to appear '
                                'here.',
                            actionLabel: 'Write a note',
                            onAction: () => context.push('/notes/new'),
                          )
                        : ClipRect(
                            child: GraphView(
                              graph: layout.graph,
                              positions: layout.positions,
                              canvasSize: layout.canvasSize,
                              onTapNode: (node) => _open(context, ref, node),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
