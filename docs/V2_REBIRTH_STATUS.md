# V2 Design Rebirth — status & resume notes

Living checklist for the from-scratch UI / UX / on-device-AI / deep-Obsidian
rebuild. Branch: `claude/life-assist-redesign-105upu`. Version: **1.2.0+6**.
Full plan of record: the approved v2 Design Rebirth plan (4 tracks + Capture
Inbox centerpiece).

## Done and pushed

- **Foundation** — killed ink (`NoSplash` + transparent highlights),
  `Pressable` primitive, motion tokens, `InstrumentPageTransitionsBuilder`,
  Lucide icon vocabulary (`lib/ui/app_icons.dart`).
- **Wave 1** — `ConsoleTabBar` (floating pill, centered Capture button),
  `ConsoleRail`, `TimerDock` (running timer visible on every tab), `AppShell`
  wiring, Today redesign. "You" moved from the tab bar to a header glyph.
- **Wave 2** — Money / Time / Focus headers on `TabPageHeader`; all six FABs
  removed; **Time "Today" card** (daily total + per-budget line above "This
  week") — the daily/weekly split the user asked for.
- **Capture Inbox** (`lib/ui/capture_inbox.dart`) — the headline feature.
  Speak (`speech_to_text`, auto-sends on final result), type, paste, or drop a
  photo (iOS Vision OCR via `ios/Runner/VisionBridge.swift`, channel
  `lifeassist/vision`). `CaptureParser` sorts free text into typed confirm
  chips (expense / time / reminder / idea) that save through the existing
  prefilled forms. Old quick-add sheet retired; its shortcuts are the inbox's
  empty state. Purpose strings (mic + speech) + Android `RECORD_AUDIO` added.
- **Wave 3** — You **Library grid** (systems as status tiles, Notes+Journal
  first); notes editor **markdown toolbar** + **"Link it"** on unlinked
  mentions + **daily note** action; **live Obsidian vault**
  (`lib/features/notes/data/live_vault_service.dart`, default on) — write-
  through mirror + fold-in on resume, Obsidian-native `tags:` frontmatter,
  stopped writing nonstandard `zettel:` key. Settings vault section collapsed
  to one "Live vault" switch.

Local gates green at each step: `flutter analyze` clean, **209 tests pass**,
`flutter build web --release` succeeds. (We verify locally, not via CI.)

## Remaining — pick up here

1. **Weekly/daily clarity on the other tabs** (user asked; Time is done, rest
   deferred to "leave notes"): **Money** is month-scoped — a "today's spend"
   line and/or a this-week strip would mirror Time's Today card. **Focus** is
   goal-scoped and already has a today sense. Cheap, high-value, do first.
2. **Wave 4** (#45) — Settings sub-pages (Profile & Targets / Appearance /
   Notifications / Data & Vault / Privacy / About), remaining screens on the
   kit, app-wide undo via a Toast slot.
3. **Wave 5** (#46) — onboarding rebuilt as the branded 3-screen intro.
4. **AI-2** (#48) — note link/tag suggestions (chips on save), summaries,
   semantic search (`NLContextualEmbedding`). Link-suggestion infra already
   exists via `unlinkedMentions` + the new "Link it" action.
5. **AI-3** (#49) — weekly-review draft, morning "what matters" line, evening
   journal prompt, with static fallbacks off `aiAvailabilityProvider`.
6. **Finale to Apple** (#50) — version already 1.2.0+6. Then: merge branch to
   `main` (see below), regenerate App Store screenshots on the new design,
   refresh Android APK.

## Getting a build to Apple (the point of all this)

The code is committed and pushed to `claude/life-assist-redesign-105upu`. To
build the next TestFlight update:

1. Get the branch onto `main` (direct push to main 403s; open a PR from
   `claude/life-assist-redesign-105upu` and merge it).
2. `git checkout main && git pull`
3. `flutter build ipa --release` (or open `ios/Runner.xcworkspace` in Xcode).
4. Upload via Transporter / Xcode Organizer. Export compliance and the
   privacy manifest are already baked in; nine purpose strings are declared
   (see `docs/release_ios.md`).
5. TestFlight "What to Test" copy lives with the release docs.

## Conventions locked for this work

- Never put the model identifier in commits/PRs/code.
- Commits end with the `Co-Authored-By` + `Claude-Session` trailer.
- Develop/push only on `claude/life-assist-redesign-105upu`.
- All modal sheets route through `showAppSheet` (`useRootNavigator: true`) or
  the floating bar covers their footers.
- Smoke test finds widgets by text/tooltip; preserve labels ('Quick add',
  'Log time', 'Add expense', 'Park an idea', 'Goal step', 'Capture', 'You',
  'Search') when reworking chrome.
