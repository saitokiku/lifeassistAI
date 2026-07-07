# Roadmap

## v1 — local-first private app (this repo)

Everything in docs/product_spec.md: full local persistence, dashboard,
Kaizen/Money/Time/Habits/Ideas/Identity/Reminders/Settings, onboarding,
JSON export/import, tests, iOS build scripts. Private use via development
builds / TestFlight internal testing.

## v1.1 — better charts & export ergonomics

- Richer trend charts (30/90-day metric history, weekly hour stacks,
  monthly surplus history)
- Share-sheet export (share_plus) and file-picker import
- Web persistence assets (sqlite3.wasm + drift_worker.js) checked in

## v1.2 — calendar integration

- Read-only device calendar overlay on the Time screen
- One-tap "log this calendar block as Kaizen/Job/..." conversion

## v1.3 — bank import / CSV

- Manual CSV import for transactions (bank export mapping)
- Duplicate detection, bulk categorization, category auto-suggest rules

## v1.4 — cloud sync (opt-in)

- Encrypted sync/backup (still no accounts requirement for local use)
- Multi-device conflict strategy; privacy policy update first

## v2 — public App Store version

- Onboarding generalized beyond the founder profile (configurable hunt,
  categories, and copy)
- App icon/branding, screenshots, marketing page, App Review submission

## v2.1 — paid tier (only if useful)

- One-time purchase or small subscription for sync/advanced analytics
- Free tier keeps the full local-first feature set

## Engineering debt to watch

- drift schema migrations once schemaVersion moves past 1
- Notification rescheduling after device reboot on Android
  (bootReceiver) and iOS 64-pending-notification limit if reminders grow
- Widget/watch complications for the Focus Integrity Score (nice-to-have)
