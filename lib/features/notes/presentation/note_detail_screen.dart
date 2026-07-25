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
import '../../../ui/app_icons.dart';
import '../../../ui/pressable.dart';
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

  /// Programmatic controller writes must not read as user edits.
  bool _syncingControllers = false;

  /// A newer row that arrived (vault fold-in, another screen) while the
  /// editor held unsaved text; _save preserves it as a conflict copy
  /// instead of blind-overwriting it.
  Note? _externalRow;

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
    if (_syncingControllers) return;
    if (!_dirty) setState(() => _dirty = true);
  }

  /// An outside edit landed (vault fold-in on resume, another screen).
  /// Clean editor: refresh silently — the screen finally lives up to
  /// noteProvider's "re-renders on outside edits" contract. Dirty
  /// editor: remember the newer row so _save keeps both versions.
  void _onExternalChange(Note row) {
    final loaded = _note;
    if (loaded == null || !row.updatedAt.isAfter(loaded.updatedAt)) return;
    if (_dirty) {
      _externalRow = row;
      return;
    }
    _syncingControllers = true;
    _title.text = row.title;
    _body.text = row.content;
    _syncingControllers = false;
    setState(() {
      _note = row;
      _dirty = false;
    });
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
        // The note changed under the editor while it held unsaved text.
        // The version on screen wins the row, but the other version is
        // kept as its own note — a conflict must never cost content.
        final external = _externalRow;
        _externalRow = null;
        if (external != null &&
            external.updatedAt.isAfter(_note!.updatedAt) &&
            (external.content != content || external.title != title)) {
          final base = external.title.trim().isEmpty
              ? 'Untitled'
              : external.title.trim();
          await controller.createNote(
            title: '$base (conflict)',
            content: external.content,
          );
          if (mounted) {
            showErrorSnack(
              context,
              'This note changed outside the editor — that version was '
              'kept as "$base (conflict)".',
            );
          }
          _note = external;
        }
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

    // Outside edits (vault fold-in on resume, saves from another
    // screen) reach the open editor instead of being clobbered by it.
    final noteId = widget.noteId;
    if (noteId != null) {
      ref.listen(noteProvider(noteId), (previous, next) {
        final row = next.valueOrNull;
        if (row != null) _onExternalChange(row);
      });
    }

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
                if (_editing)
                  _EditorToolbar(controller: _body, focus: _bodyFocus),
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
    final unlinked = note == null
        ? const <Note>[]
        : ref.watch(unlinkedMentionsProvider(note.id)).valueOrNull ??
            const <Note>[];

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
          NoteMarkdown(
            data: _body.text,
            onOpenLink: _openLink,
            onTapTag: (tag) => _openTag(context, tag),
          ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              for (final t in tags)
                InkWell(
                  onTap: () => _openTag(context, t.tag),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  child: Container(
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
        if (unlinked.isNotEmpty) ...[
          const SectionHeader(title: 'Unlinked mentions'),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: Text(
              'These say “${note!.displayTitle}” without linking it yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final n in unlinked)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.cardGap),
              child: AppCard(
                onTap: () => context.push('/notes/${n.id}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          if (n.preview.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              n.preview,
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
                    const SizedBox(width: AppSpace.sm),
                    // One tap turns the plain mention into a [[link]]
                    // inside the other note — the graph grows itself.
                    TextButton(
                      onPressed: () => _linkMention(n),
                      child: const Text('Link it'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  void _openTag(BuildContext context, String tag) {
    unawaited(context.push(
      Uri(path: '/notes', queryParameters: {'tag': tag}).toString(),
    ));
  }

  /// Wraps the first free-standing mention of this note's title inside
  /// [other] in `[[brackets]]`, preserving the words as written. Skips
  /// occurrences already inside a link so nothing nests.
  Future<void> _linkMention(Note other) async {
    final title = _note?.title.trim() ?? '';
    if (title.isEmpty) return;
    final pattern = RegExp(RegExp.escape(title), caseSensitive: false);
    Match? hit;
    for (final m in pattern.allMatches(other.content)) {
      final before = other.content.substring(0, m.start);
      final open = before.lastIndexOf('[[');
      if (open >= 0 && open > before.lastIndexOf(']]')) continue;
      hit = m;
      break;
    }
    if (hit == null) return;
    final linked = other.content
        .replaceRange(hit.start, hit.end, '[[${hit[0]}]]');
    await ref
        .read(notesControllerProvider)
        .saveNote(other, title: other.title, content: linked);
    Haptics.select();
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

/// One row of markdown affordances above the keyboard — wrap or prefix
/// without hunting the symbol keyboard. `[[` and `#` land as raw text,
/// so they light up the same autocomplete typing them would.
class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({required this.controller, required this.focus});

  final TextEditingController controller;
  final FocusNode focus;

  void _wrap(String left, String right) {
    final value = controller.value;
    final sel = value.selection;
    if (!sel.isValid) {
      final text = value.text + left + right;
      controller.value = TextEditingValue(
        text: text,
        selection:
            TextSelection.collapsed(offset: text.length - right.length),
      );
    } else if (sel.isCollapsed) {
      final text =
          value.text.replaceRange(sel.start, sel.start, left + right);
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: sel.start + left.length),
      );
    } else {
      final selected = value.text.substring(sel.start, sel.end);
      final text = value.text
          .replaceRange(sel.start, sel.end, '$left$selected$right');
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(
            offset: sel.end + left.length + right.length),
      );
    }
    focus.requestFocus();
  }

  /// Toggles [prefix] at the start of the caret's line.
  void _prefixLine(String prefix) {
    final value = controller.value;
    final sel = value.selection;
    final text = value.text;
    final offset = (sel.isValid ? sel.start : text.length).clamp(0, text.length);
    final lineStart =
        offset == 0 ? 0 : text.lastIndexOf('\n', offset - 1) + 1;
    final already = text.startsWith(prefix, lineStart);
    final next = already
        ? text.replaceRange(lineStart, lineStart + prefix.length, '')
        : text.replaceRange(lineStart, lineStart, prefix);
    final delta = already ? -prefix.length : prefix.length;
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(
          offset: (offset + delta).clamp(0, next.length)),
    );
    focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final actions = <(IconData, String, VoidCallback)>[
      (AppIcons.wikiLink, 'Link a note', () => _wrap('[[', '')),
      (AppIcons.tag, 'Tag', () => _wrap('#', '')),
      (AppIcons.bold, 'Bold', () => _wrap('**', '**')),
      (AppIcons.italic, 'Italic', () => _wrap('*', '*')),
      (AppIcons.heading, 'Heading', () => _prefixLine('## ')),
      (AppIcons.bulletList, 'List', () => _prefixLine('- ')),
      (AppIcons.checkbox, 'Checklist', () => _prefixLine('- [ ] ')),
    ];
    return Container(
      height: 46,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: 4,
        ),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 2),
        itemBuilder: (context, i) {
          final (icon, tooltip, action) = actions[i];
          return Tooltip(
            message: tooltip,
            child: Pressable(
              onTap: action,
              haptic: PressHaptic.select,
              semanticLabel: tooltip,
              pressedScale: 0.9,
              dense: true,
              child: SizedBox(
                width: 40,
                height: 38,
                child: Icon(icon, size: 17, color: scheme.onSurfaceVariant),
              ),
            ),
          );
        },
      ),
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
