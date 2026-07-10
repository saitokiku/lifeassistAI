# Life Assist

One quiet place to run your life.

Life Assist is a local-first personal operating system built around a
simple idea: **pick one main goal, keep it in front of you, and keep the
rest of life — money, time, habits, ideas — honest with light logging.**

## How it's organized

Five tabs — **Today · Focus · Money · Time · You** — on a shared design
system (bundled Inter + Space Grotesk, dark-first, one component library).

- **Today** — what matters now: a greeting, one "Up next" action chosen
  from your real state, one-tap check-ins (goal step, tracked measure,
  habits), the week's key numbers, a snapshot of your goal, and the long
  game. Modules appear only for areas you've chosen to manage.
- **Focus** — your main goal, in your words ("Kaizen", "Finish nursing
  school", "Become debt-free"…): why it matters, timeframe, milestones to
  check off, an optional progress measure with trend charts, and a daily
  step log with honest worked / adjust / didn't-work reviews. Goals can be
  edited, paused, completed, or replaced; history stays.
- **Money** — monthly income vs spending: projected surplus, leak flags,
  budget categories, a transaction log, surplus history, and the long
  game (retirement pace, balances, an optional long-term target). Until
  income is set, the screen invites setup instead of guessing.
- **Time** — weekly hours against targets, available time today, a
  goal-vs-everything-else history chart, countdowns, and the time log.
- **You** — the person behind the data: your personal line, operating
  principles, and the supporting systems — Habits, Ideas (a 7-day cooling
  parking lot), Reminders, and Settings — each with a live status line.

First launch runs a four-step onboarding: what the app is → your main
goal (skippable) → your name and areas → a light daily rhythm. Every
answer is optional and everything can be changed later.

All data persists locally in SQLite (drift). No cloud, no account, no
analytics. Seed defaults are neutral starting points that become ordinary
editable records.

## Tech stack

Flutter (Material 3, dark mode first) · Dart · flutter_riverpod ·
go_router (StatefulShellRoute — tabs keep their state) · drift + SQLite
(drift_flutter, sqlite3_flutter_libs) · flutter_local_notifications +
timezone · shared_preferences (small app flags only) · intl · uuid ·
fl_chart (trend/history charts) plus a custom-painted sparkline ·
share_plus + file_picker (backup export/import) · package_info_plus
(version) · bundled Inter + Space Grotesk fonts (OFL, licenses in
`assets/fonts/`).

Design system: tokens in `lib/core/theme/` (spacing, radii, motion,
palette, type scale) and a shared component library in
`lib/shared/widgets/` (cards, tiles, sheet scaffold with busy-state
buttons, check rings, status pills, progress, skeletons, empty/error
states, undo snacks, haptics). Motion respects the platform's
reduced-motion preference.

Architecture: clean-ish layers per feature — `data/` (repositories over
drift), `domain/` (models + pure rules), `application/` (Riverpod providers
+ derived state), `presentation/` (screens/widgets). Drift's generated data
classes serve as the domain row types; domain files add enums, rules, and
computed models on top.

### Data schema & migrations

Schema v2 introduced the universal main-goal system. Upgrading from v1
(and importing v1 backup files) is handled automatically:

- `MainGoals` table added; the old free-standing `goals` become
  milestones (`isDone`, `sortOrder` columns added).
- Stored legacy values are rewritten (`kaizen` time kind → `goal`,
  `kaizenExperiment` reminder type → `dailyAction`).
- A database that contains pre-v2 activity gets its original goal
  ("Kaizen") created as real user data — nothing is lost.

See `lib/core/storage/legacy_migration.dart` and
`test/legacy_migration_test.dart`.

## Run it

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerate drift code (already checked in)
flutter run                # pick a device/simulator
```

Useful scripts (all in `scripts/`):

| Script | Does |
| --- | --- |
| `analyze.sh` | `flutter pub get` + `flutter analyze` |
| `test.sh` | full test suite |
| `run_ios.sh [device-id]` | debug run on iPhone/simulator |
| `build_ios_release.sh` | clean → analyze → test → `flutter build ios --release` |
| `build_ipa_release.sh` | same, then `flutter build ipa --release` |

## Test

```bash
flutter test
```

Covers the focus score, money projections and flag rules, time budget
math and recovery logic, the idea cooling rule, repository persistence
(in-memory SQLite) including JSON export/import round-trips, the
Kaizen-era → main-goal migration, and end-to-end smoke tests for
navigation, goal setup, and onboarding.

## Build for iPhone / IPA

Requires macOS with Xcode and an Apple Developer account. Short version:

```bash
flutter build ios --release   # archive-ready build
flutter build ipa --release   # .ipa in build/ios/ipa/
```

Full walkthrough (signing, TestFlight): see
[docs/release_ios.md](docs/release_ios.md) and
[docs/app_store_checklist.md](docs/app_store_checklist.md).

## Project structure

```
lib/
├── main.dart / app.dart / bootstrap.dart
├── core/            constants, theme, utils, storage (drift + migrations), notifications, errors
├── routing/         go_router config
├── shared/          layout (adaptive nav) + reusable widgets
└── features/
    ├── dashboard/   Today — aggregated state + the Up-next engine
    ├── focus/       the main goal: milestones, measures, daily steps
    ├── money/       budgets + transactions + flags + the long game
    ├── time/        budgets + blocks + countdowns
    ├── habits/      habits + logs
    ├── ideas/       parking lot with the 7-day cooling rule
    ├── identity/    personal line + operating principles (+ long-term target data)
    ├── reminders/   local notifications
    ├── settings/    settings + backup (export/import)
    ├── you/         the You hub
    └── onboarding/  first-launch flow
docs/                product docs, AI roadmap, release docs
scripts/             analyze/test/run/build helpers
test/                unit + repository + smoke tests
```

## Current limitations

- Web: `drift_worker.js` is committed; drop `web/sqlite3.wasm` in for
  persistence (one download — see `web/README.md`). Without it the web
  build runs but data is in-memory. Local notifications don't exist on web
  (the UI says so and degrades gracefully). iOS/Android are the real targets.
- No bank/CSV import, calendar integration, or cloud sync (roadmap).
  Cloud sync is intentionally deferred — it needs a backend + auth and would
  compromise the local-first, no-account privacy stance if rushed.
- App icon is a placeholder; signing/bundle id must be configured in Xcode
  before device installs.
- Reminders use inexact Android alarms; on iOS times are exact but require
  notification permission.

See [docs/roadmap.md](docs/roadmap.md) for what's next and
[docs/AI_PRODUCT_ROADMAP.md](docs/AI_PRODUCT_ROADMAP.md) for how AI may
(carefully) join later.
