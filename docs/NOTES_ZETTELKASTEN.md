# Notes — the built-in Zettelkasten

A linked note system with an Obsidian-compatible vault: markdown notes,
`[[wiki links]]`, `#tags`, backlinks, an auto-drawn graph, and a
round-trip to plain `.md` files on disk. Local-first like everything
else in the app — no account, no sync service.

## The model

| Table | Role |
|---|---|
| `Notes` | The source of truth: `id` (uuid), `zettelId` (timestamp key, permanent address), `title`, `content` (markdown), `isArchived`, timestamps. |
| `NoteLinks` | Derived index: one row per distinct `[[target]]` in a note. `targetId` is the resolved note — or **null**, which makes it a *ghost*: a link to a note that doesn't exist yet. |
| `NoteTags` | Derived index: one row per distinct `#tag` (lowercased; nested `#area/health` kept whole). |

`NoteLinks`/`NoteTags` are **never hand-maintained**: every save
reindexes that note inside the same transaction
(`NotesRepository.saveNote`), and every bulk write (backup restore,
vault import) ends with `reindexAll()`. Deleting or renaming a note
re-homes inbound links honestly — the text keeps saying what it said,
so links follow *titles*, not rows.

- **Ghosts solidify.** Write `[[Atomic Habits]]` before the note
  exists and the link is a ghost; the moment a note takes that title
  (typed, tapped-to-create, or imported) every ghost pointing at it
  resolves.
- **Zettel ids** are `yyyyMMddHHmmss` (suffixed on same-second
  collisions) — human-sortable, stable across renames, shown on the
  note under the title.

## The grammar

Parsing lives in `lib/features/notes/domain/note_parsing.dart` (pure,
unit-tested):

- Links: `[[Target]]`, `[[Target|shown text]]`, `[[Target#Heading]]`
  (heading refs resolve to the note). Case-insensitive resolution.
- Tags: `#tag`, `#nested/tag`, `#with-dash_or_underscore`; needs at
  least one letter (`#123` is an issue number, not a tag); headings
  (`# Title`) and URL fragments don't match.
- Code is quiet: fenced ``` blocks and `inline code` are ignored by
  the indexer.

The same definitions drive the editor's rendering (custom
`flutter_markdown` inline syntaxes) so what the index sees and what
the screen shows can't drift.

## The screens

- **Notes list** (`/notes`, You tab → Notes): newest-edited first,
  preview line, tag chips, live "n notes · m links" count.
- **Editor** (`/notes/:id`): full markdown, edit ↔ preview toggle.
  While typing, an open `[[` or `#` pops completion chips above the
  keyboard. Preview renders markdown with tappable wiki links (tap a
  ghost → the note is created on the spot), tinted tags, the
  **Linked mentions** (backlinks) list, and a local **Graph**
  mini-map. Leaving saves; an untouched new note leaves no residue.
- **Graph** (`/notes/graph`): every note a dot (size = degree, color =
  first tag), ghosts hollow, links as lines. Pinch to zoom, drag to
  roam, tap to open. Layout is a deterministic Fruchterman–Reingold
  (golden-angle seeding, zero randomness) so the map keeps its shape
  between visits — `lib/features/notes/graph/`.

Notes also appear in everything-search and in JSON backups (notes
only; the link/tag index is rebuilt on restore).

## The vault (Obsidian round-trip)

`lib/features/notes/data/obsidian_vault.dart` defines the file format;
`vault_service.dart` moves whole vaults. Settings → **Notes vault**:

- **Export notes to Files** — writes every note as
  `Documents/LifeAssistVault/<Title>.md`. Because the app declares
  `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace`, the
  folder is visible in the Files app (On My iPhone → Life Assist) —
  point a Mac at it, or copy it into an Obsidian vault as-is.
- **Share vault (.zip)** — the same files, zipped, through the share
  sheet.
- **Import notes (.md)** — multi-file picker; plain Obsidian files
  work (frontmatter optional, title falls back to the filename).
- **Re-import from Files** — re-reads the vault folder, picking up
  edits made in the Files app or files dropped there.

Each file carries YAML frontmatter (`id`, `zettel`, `title`,
`created`, `updated`, `archived`) so **re-importing your own export
updates in place** — dedupe matches by id, then zettel id, then
case-insensitive title; only then is a new note created. Foreign
frontmatter keys are tolerated and ignored. Exports clean up only
stale files that carry our `id:` and whose note was deleted; anything
hand-made in the folder is never touched.

Live two-way sync with an *external* folder (e.g. an existing Obsidian
vault elsewhere on device) needs iOS security-scoped bookmarks — a
native follow-up, deliberately out of scope for 1.0.

## Extensibility seam

The graph draws `GraphNode {id, title, kind}` — nothing notes-specific.
Journal entries, ideas, goals, or people can join the map later by
mapping to nodes with their own `kind` plus link rows; layout, view,
and hit-testing never ask what a node is. Same for search and backup:
each new kind is one block, one table key.

## Tests

`test/note_parsing_test.dart`, `test/notes_repository_test.dart`,
`test/note_graph_test.dart`, `test/obsidian_vault_test.dart`, plus the
Notes/graph steps in `test/screens_smoke_test.dart` — parsing edge
cases, ghost lifecycle, rename re-homing, backup and vault round-trips,
layout determinism.
