# Life Dashboard

A personal life operating system. Not a habit tracker — an operator dashboard.

> **Money = scoreboard · Curiosity = engine · Freedom = actual goal**

One glance should answer: *am I pointing my hours and money at the one thing
that compounds (Kaizen growth), and am I sustainable?*

## What it does

- **Dashboard** — Kaizen hours this week, active growth metric with 7-day
  trend, today's kill-or-confirm experiment, projected monthly surplus,
  recovery floor, Focus Integrity Score (0–100), freedom progress, and a
  generated Today's Command.
- **Kaizen** — growth metrics (one active hunt at a time), dated metric
  entries, daily experiments with kill/confirm/iterate verdicts, streaks,
  missed days.
- **Money** — income, budget categories with leak-flag rules, transactions,
  month-to-date and projected spend, surplus targets, Roth IRA and manual
  balances.
- **Time** — weekly time budgets (actual vs target), time block logging,
  available time today, countdowns (age-28 lock-in, end of year/month,
  Roth IRA deadline, custom).
- **Habits** — boolean/numeric/duration habits, today's checklist, streaks.
- **Ideas** — anti-diffusion parking lot with a 7-day cooling rule.
- **Identity** — philosophy, operating identity statements, goals, freedom
  target.
- **Reminders** — editable daily local notifications (morning command,
  experiment nudge, money check, night review, custom).
- **Settings** — everything editable; JSON export/import; full reset.

All data persists locally in SQLite (drift). No cloud, no account, no
analytics. Seed defaults are inserted once on first launch and become
ordinary editable records.

## Tech stack

Flutter (Material 3, dark mode first) · Dart · flutter_riverpod ·
go_router · drift + SQLite (drift_flutter, sqlite3_flutter_libs) ·
flutter_local_notifications + timezone · shared_preferences (small app
flags only) · intl · uuid · custom-painted charts (no chart package).

Architecture: clean-ish layers per feature — `data/` (repositories over
drift), `domain/` (models + pure rules), `application/` (Riverpod providers
+ derived state), `presentation/` (screens/widgets). Drift's generated data
classes serve as the domain row types; domain files add enums, rules, and
computed models on top.

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

Covers the Focus Integrity Score, money projections and flag rules, time
budget math and recovery logic, the idea cooling rule, and repository
persistence (in-memory SQLite), including JSON export/import round-trips.

## Build for iPhone / IPA

Requires macOS with Xcode and an Apple Developer account. Short version:

```bash
flutter build ios --release   # archive-ready build
flutter build ipa --release   # .ipa in build/ios/ipa/
```

Full walkthrough (signing, bundle id `com.kaizen.lifedashboard`, TestFlight):
see [docs/release_ios.md](docs/release_ios.md) and
[docs/app_store_checklist.md](docs/app_store_checklist.md).

## Project structure

```
lib/
├── main.dart / app.dart / bootstrap.dart
├── core/            constants, theme, utils, storage (drift), notifications, errors
├── routing/         go_router config
├── shared/          layout (adaptive nav) + reusable widgets
└── features/
    ├── dashboard/   aggregated state + cards
    ├── kaizen/      metrics + experiments
    ├── money/       budgets + transactions + flags
    ├── time/        budgets + blocks + countdowns
    ├── habits/      habits + logs
    ├── ideas/       parking lot
    ├── identity/    philosophy, goals, freedom target
    ├── reminders/   local notifications
    ├── settings/    settings + backup (export/import)
    └── onboarding/  first-launch flow
docs/                product spec, data model, scoring rules, release docs
scripts/             analyze/test/run/build helpers
test/                unit + repository tests
```

## Current limitations (v1)

- Web: data persists via drift's web fallback only if `sqlite3.wasm` /
  `drift_worker.js` are added to `web/`; local notifications don't exist on
  web (the UI says so and degrades gracefully). iOS/Android are the real
  targets.
- Export/import is copy-paste JSON (plus a best-effort file save to the app
  documents folder). No share sheet yet (roadmap v1.1).
- No bank import, calendar integration, or cloud sync (roadmap).
- App icon is a placeholder; signing/bundle id must be configured in Xcode
  before device installs.
- Reminders use inexact Android alarms; on iOS times are exact but require
  notification permission.

See [docs/roadmap.md](docs/roadmap.md) for what's next.
