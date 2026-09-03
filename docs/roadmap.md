# Roadmap

## Shipped

- **v1** — local-first persistence, the five tabs, onboarding, JSON
  export/import, iOS build scripts.
- **v1.1** — trend charts (fl_chart), share-sheet export with clipboard
  fallback, file-picker import with paste fallback, web persistence via
  a committed drift worker.
- **v2** — the universal **main goal** system replaced the original
  single-owner experience: user-defined goal with why, timeframe and
  status, milestones, an optional progress measure, daily steps. New
  information architecture (Today / Focus / Money / Time / You),
  rebuilt onboarding, neutral seed data, one product voice. Schema v2
  migrates existing data; v1 backups still import.
- **v3** — tracked accounts with balance history, recurring expenses
  that materialize as real transactions, bank-CSV statement import with
  duplicate detection, guided weekly reviews, per-habit and per-reminder
  weekday schedules.
- **v4** — money moved to **integer cents** end to end, so sums are
  exact; plus the journal.
- **v5** — Apple Health habit mappings and a source tag on every habit
  log (`manual | siri | health`; manual always wins).
- **v6** — Notes: a built-in Zettelkasten with `[[wiki links]]`, tags,
  backlinks, a graph, and an Obsidian-compatible vault in Files.
- **v7** — real UNIQUE constraints behind the three "one row per day"
  invariants, and stored (rather than derived) notification ids.
- **iOS integration** — App Intents for Siri capture that works with the
  phone locked, entity resolution, on-device Foundation Models for
  parsing and drafting, widgets, a Control Center button, and the
  focus-timer Live Activity.

## Next

- **Launch** — App Store screenshots, marketing page, App Review
  submission. The privacy policy ([privacy.md](privacy.md)) and support
  page ([support.md](support.md)) are written and ready to host.
- **Calendar overlay** — read-only device calendar on the Time screen,
  with one-tap conversion of a calendar block into logged time.
- **Reminder robustness** — Android rescheduling after reboot, and
  staying under the iOS 64-pending-notification ceiling as reminder
  counts grow.

## Deliberately not doing (yet)

- **Cloud sync.** Encrypted, opt-in, no-account sync is the only version
  worth building, and it needs the privacy policy updated first. A
  rushed version would cost the local-first guarantee that makes the app
  worth using.
- **Live bank feeds.** They need third-party credentials and a token
  server. The integration seam is documented in
  [BANK_CONNECTIONS.md](BANK_CONNECTIONS.md); CSV import covers the real
  need without asking anyone for their bank login.
- **Accounts, social, gamification.** Not planned.
