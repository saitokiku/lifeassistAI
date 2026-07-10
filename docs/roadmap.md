# Roadmap

## v1 — local-first private app ✅

Full local persistence, dashboard, Kaizen/Money/Time/Habits/Ideas/
Identity/Reminders/Settings, onboarding, JSON export/import, tests, iOS
build scripts. Private use via development builds / TestFlight internal
testing.

## v1.1 — better charts & export ergonomics ✅

- Richer trend charts (fl_chart): 30/90-day metric history line chart,
  weekly hour stacks, monthly surplus history bars
- Share-sheet export (share_plus) with clipboard fallback; file-picker
  import (file_picker) with paste fallback
- `drift_worker.js` compiled and committed under `web/`; `sqlite3.wasm`
  documented in `web/README.md` (single manual download — the release
  asset host is blocked in the build sandbox, so it can't be vendored here)
- App version shown in Settings → About

## v2 — universal product ✅ (this revamp)

- The hardcoded Kaizen experience replaced by a universal **main goal**
  system (Focus tab): user-defined goal with why/timeframe/status,
  milestones, optional progress measure, daily steps
- Safe migration: schema v2, legacy enum rewrites, the original "Kaizen"
  goal derived from existing data; v1 backups still import
- New IA: Today / Focus / Money / Time / You; identity folded into You;
  long-term target moved to Money
- Onboarding rebuilt around goal setup; neutral seed data; one product
  voice; app renamed **Life Assist**
- Personalizable Today (area modules), reduced-motion support, honest
  zero-income states

## v2.1 — launch readiness

- Real app icon/branding, screenshots, marketing page
- App Review submission; privacy policy finalized
- Widget/watch complications for the day score (nice-to-have)

## v2.2 — calendar integration

- Read-only device calendar overlay on the Time screen
- One-tap "log this calendar block as goal time / work / ..." conversion

## v2.3 — bank import / CSV

- Manual CSV import for transactions (bank export mapping)
- Duplicate detection, bulk categorization, category auto-suggest rules

## v2.4 — cloud sync (opt-in)

- Encrypted sync/backup (still no accounts requirement for local use)
- Multi-device conflict strategy; privacy policy update first

## AI (separate track)

Staged plan, principles, and architecture live in
[AI_PRODUCT_ROADMAP.md](AI_PRODUCT_ROADMAP.md). The app must stay
excellent without it.

## Engineering debt to watch

- Notification rescheduling after device reboot on Android
  (bootReceiver) and iOS 64-pending-notification limit if reminders grow
- `docs/product_spec.md`, `docs/scoring_rules.md`, and
  `docs/life_philosophy.md` describe v1 and are kept as historical
  context; current behavior is documented in the README and
  `docs/data_model.md`
