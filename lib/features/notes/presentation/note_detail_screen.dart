import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/haptics.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/graph_providers.dart';
import '../application/notes_controller.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import 'widgets/graph_view.dart';
import 'widgets/note_markdown.dart';

/// One note: a full markdown editor with live `[[link]]` / `#tag`
/// autocomplete, a rendered preview with tappable links, and the
/// backlinks that make a pile of notes a Zettelkasten.
class NoteDetailScreen extends ConsumerStatefulWidget {
  const NoteDetailScreen({super.key, this.noteId});

  /// Null opens a fresh, unsaved note.
  final String? noteId;

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _bodyFocus = FocusNode();

  Note? _note;
  bool _loading = true;
  bool _editing = true;
  bool _dirty = false;
  bool _saving = false;
  bool _missing = false;

  List<String> _allTitles = const [];
  List<String> _allTags = const [];
  List<_Suggestion> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _body.addListener(_recomputeSuggestions);
    _title.addListener(_markDirty);
    _body.addListener(_markDirty);
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final controller = ref.read(notesControllerProvider);
    if (widget.noteId != null) {
      final note = await ref
          .read(notesRepositoryProvider)
          .getNote(widget.noteId!);
      if (!mounted) return;
      if (note == null) {
        setState(() {
          _loading = false;
          _missing = true;
        });
        return;
      }
      _note = note;
      _title.text = note.title;
      _body.text = note.content;
      _dirty = false;
      // An existing note opens readable; a fresh one opens writable.
      _editing = note.content.trim().isEmpty;
    }
    final titles = await controller.titleSuggestions();
    final tags = await controller.tagSuggestions();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _allTitles = titles;
      _allTags = tags;
    });
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  /// Persists current text. A brand-new note is only created once it
  /// has any text — backing out of an empty editor leaves no residue.
  Future<void> _save() async {
    if (_saving) return;
    final title = _title.text.trim();
    final content = _body.text;
    if (_note == null && title.isEmpty && content.trim().isEmpty) return;
    if (!_dirty) return;
    _saving = true;
    try {
      final controller = ref.read(notesControllerProvider);
      if (_note == null) {
        _note = await controller.createNote(title: title, content: content);
      } else {
        _note = await controller.saveNote(
          _note!,
          title: title,
          content: content,
        );
      }
      _dirty = false;
      // Fresh corpus so a just-written [[title]] autocompletes next time.
      _allTitles = await controller.titleSuggestions();
      _allTags = await controller.tagSuggestions();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) showErrorSnack(context, "That didn't save. Try again.");
    } finally {
      _saving = false;
    }
  }

  Future<void> _togglePreview() async {
    if (_editing) await _save();
    if (!mounted) return;
    setState(() {
      _editing = !_editing;
      _suggestions = const [];
    });
    if (_editing) _bodyFocus.requestFocus();
  }

  Future<void> _openLink(String target) async {
    await _save();
    if (!mounted) return;
    final note =
        await ref.read(notesControllerProvider).openOrCreateByTitle(target);
    if (!mounted) return;
    if (note.id == _note?.id) return; // a note may cite itself
    unawaited(context.push('/notes/${note.id}'));
  }

  Future<void> _delete() async {
    final note = _note;
    if (note == null) {
      context.pop();
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this note?',
      message: 'Links written to it elsewhere stay as text and simply '
          'point nowhere. This cannot be undone.',
    );
    if (!confirmed || !mounted) return;
    await ref.read(notesControllerProvider).deleteNote(note.id);
    Haptics.medium();
    if (mounted) context.pop();
  }

  Future<void> _toggleArchived() async {
    final note = _note;
    if (note == null) return;
    await ref
        .read(notesControllerProvider)
        .setArchived(note.id, !note.isArchived);
    setState(() => _note = note.copyWith(isArchived: !note.isArchived));
  }

  // ------------------------------------------------------- autocomplete

  /// Looks left of the cursor for an open `[[query` or `#query` and
  /// turns the matching corpus into tappable completions.
  void _recomputeSuggestions() {
    if (!_editing) return;
    final sel = _body.selection;
    final text = _body.text;
    if (!sel.isValid || !sel.isCollapsed) {
      _setSuggestions(const []);
      return;
    }
    final before = text.substring(0, sel.baseOffset);

    // [[query — open bracket pair, nothing closing it yet.
    final open = before.lastIndexOf('[[');
    if (open >= 0) {
      final query = before.substring(open + 2);
      if (!query.contains(']') && !query.contains('\n') && query.length < 60) {
        final needle = query.trim().toLowerCase();
        _setSuggestions([
          for (final t in _allTitles.where(
            (t) =>
                t.toLowerCase().contains(needle) &&
                t.toLowerCase() != needle,
          ))
            _Suggestion(
              label: '[[$t]]',
              apply: () => _replaceRange(open, sel.baseOffset, '[[$t]] '),
          ),
        ].take(6).toList());
        return;
      }
    }

    // #query — a tag token under the cursor.
    final tagMatch = RegExp(r'(?:^|[\s(])#([A-Za-z0-9_\-/]*)$').firstMatch(before);
    if (tagMatch != null) {
      final query = tagMatch[1]!.toLowerCase();
      final start = sel.baseOffset - query.length - 1;
      _setSuggestions([
        for (final t in _allTags.where(
          (t) => t.startsWith(query) && t != query,
        ))
          _Suggestion(
            label: '#$t',
            apply: () => _replaceRange(start, sel.baseOffset, '#$t '),
          ),
      ].take(6).toList());
      return;
    }

    _setSuggestions(const []);
  }

  void _setSuggestions(List<_Suggestion> next) {
    if (next.isEmpty && _suggestions.isEmpty) return;
    setState(() => _suggestions = next);
  }

  void _replaceRange(int start, int end, String replacement) {
    final text = _body.text;
    _body.value = TextEditingValue(
      text: text.replaceRange(start, end, replacement),
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
    _bodyFocus.requestFocus();
  }

  // -------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_loading) {
      return const Scaffold(body: SafeArea(child: SkeletonList()));
    }
    if (_missing) {
      return Scaffold(
        body: SafeArea(
          child: ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpace.lg),
                const Row(children: [ScreenBackButton()]),
                Expanded(
                  child: Center(
                    child: Text(
                      'This note no longer exists.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        // Leaving is saving — the repository call outlives the screen.
        if (didPop && _dirty) _save();
      },
      child: Scaffold(
        body: SafeArea(
          child: ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.screen,
                    AppSpace.md,
                    AppSpace.screen,
                    0,
                  ),
                  child: Row(
                    children: [
                      const ScreenBackButton(),
                      Expanded(
                        child: Text(
                          _note == null ? 'New note' : 'Note',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: _editing ? 'Preview' : 'Edit',
                        onPressed: _togglePreview,
                        icon: Icon(
                          _editing
                              ? Icons.visibility_outlined
                              : Icons.edit_outlined,
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Note actions',
                        onSelected: (value) => switch (value) {
                          'archive' => _toggleArchived(),
                          'delete' => _delete(),
                          _ => null,
                        },
                        itemBuilder: (context) => [
                          if (_note != null)
                            PopupMenuItem(
                              value: 'archive',
                              child: Text(
                                _note!.isArchived ? 'Unarchive' : 'Archive',
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _editing ? _buildEditor(theme) : _buildPreview(theme),
                ),
                if (_editing && _suggestions.isNotEmpty)
                  _SuggestionBar(suggestions: _suggestions),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(ThemeData theme) {
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.sm,
        AppSpace.screen,
        AppSpace.lg,
      ),
      children: [
        TextField(
          controller: _title,
          style: theme.textTheme.headlineSmall,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Title',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
          onSubmitted: (_) => _bodyFocus.requestFocus(),
        ),
        if (_note != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: Text(
              _note!.zettelId,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.textTertiary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        TextField(
          controller: _body,
          focusNode: _bodyFocus,
          maxLines: null,
          minLines: 12,
          keyboardType: TextInputType.multiline,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          decoration: const InputDecoration(
            hintText: 'Write. Wrap a phrase in [[double brackets]] to link '
                'it; #tag the themes. Markdown works.',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(ThemeData theme) {
    final scheme = theme.colorScheme;
    final note = _note;
    final tags =
        note == null ? const <NoteTag>[] : ref.watch(noteTagsProvider(note.id)).valueOrNull ?? const <NoteTag>[];
    final backlinks = note == null
        ? const <Backlink>[]
        : ref.watch(backlinksProvider(note.id)).valueOrNull ??
            const <Backlink>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.sm,
        AppSpace.screen,
        AppSpace.xxl,
      ),
      children: [
        Text(
          note?.displayTitle ?? _title.text,
          style: theme.textTheme.headlineSmall,
        ),
        if (note != null) ...[
          const SizedBox(height: 2),
          Text(
            '${note.zettelId} · edited ${Formatters.shortDate(note.updatedAt)}'
            '${note.isArchived ? ' · archived' : ''}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.textTertiary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        if (_body.text.trim().isEmpty)
          Text(
            'Nothing here yet — tap the pencil to write.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          NoteMarkdown(data: _body.text, onOpenLink: _openLink),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              for (final t in tags)
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
        if (note != null) _LocalGraph(noteId: note.id),
        if (backlinks.isNotEmpty) ...[
          const SectionHeader(title: 'Linked mentions'),
          for (final b in backlinks)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.cardGap),
              child: AppCard(
                onTap: () => context.push('/notes/${b.source.id}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.source.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (b.source.preview.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        b.source.preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// The note's immediate neighborhood, drawn small — enough to see what
/// this thought touches; the full map is one tap away.
class _LocalGraph extends ConsumerWidget {
  const _LocalGraph({required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(localGraphProvider(noteId));
    if (layout == null || layout.graph.edges.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Graph',
          trailing: TextButton(
            onPressed: () => context.push('/notes/graph'),
            child: const Text('Full map'),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: GraphView(
                graph: layout.graph,
                positions: layout.positions,
                canvasSize: layout.canvasSize,
                focusId: noteId,
                fit: true,
                onTapNode: (node) async {
                  if (node.id == noteId) return;
                  if (node.isGhost) {
                    final note = await ref
                        .read(notesControllerProvider)
                        .openOrCreateByTitle(node.title);
                    if (context.mounted) {
                      unawaited(context.push('/notes/${note.id}'));
                    }
                  } else {
                    unawaited(context.push('/notes/${node.id}'));
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Suggestion {
  const _Suggestion({required this.label, required this.apply});

  final String label;
  final VoidCallback apply;
}

/// Completion chips riding above the keyboard while `[[` or `#` is open.
class _SuggestionBar extends StatelessWidget {
  const _SuggestionBar({required this.suggestions});

  final List<_Suggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.screen,
          vertical: AppSpace.xs,
        ),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpace.xs),
        itemBuilder: (context, i) => ActionChip(
          label: Text(suggestions[i].label),
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.primary,
          ),
          onPressed: suggestions[i].apply,
        ),
      ),
    );
  }
}
