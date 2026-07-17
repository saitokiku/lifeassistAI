# Life Assist — Scrutiny Report

*A full-repository review performed after Phases 0–6 landed (commit
range `7fcfa7a…` through the widgets finish). Method: automated sweeps
(analyzer, full test suite, pattern greps for swallowed errors, clock
misuse, force-unwraps, thread-blocking IO, locale traps) plus a manual
read of every high-risk seam — the Siri queue, the entity mirror, the
migrations, the backup codec, the Xcode project surgery, and the CI
pipeline. Findings are ranked; three were fixed during the review
itself. This file is honest by construction: if something is weak, it
says so.*

**State at review time:** `flutter analyze` clean · 129 tests passing ·
web release build green · iOS CI (typecheck + full device build incl.
the widget extension) green on the previous commit.

---

## 1. Fixed during this review

These were real defects found by the sweep and corrected immediately.

| Sev | Where | What |
| --- | --- | --- |
| **High** | `capture_queue_drain.dart` | Swift writes queue `createdAt` in UTC (`ISO8601DateFormatter`). Dart derived the calendar day without `.toLocal()`, so a "log 12 dollars" spoken at 9 PM in a UTC-negative timezone would be dated **tomorrow**. Now converted to device-local time before any day math. |
| **Medium** | `SiriAnswers.swift`, `LifeAssistWidgets.swift` | The freshness gate built "today's" key with a bare `DateFormatter`. On devices set to Buddhist/Japanese calendars or non-Latin digits, the key never matches Dart's Gregorian/ASCII key — Siri and widgets would say "open the app" forever. Both formatters are now pinned to `en_US_POSIX` + Gregorian. |
| **Low** | `app_shell.dart` `_publishToday` | The async today.json write chained `.then(...)` inside a synchronous try/catch; an async write failure would surface as an unhandled zone error instead of the intended silent "no fresh numbers". Now has `catchError`. |
| **Low** | `LifeAssistWidgets.swift` | The habit widget counted *any* pending queued check as "done today", including one from before midnight if the app hadn't opened. Pending records are now filtered to today. |

## 2. Open findings — CLOSED in the production-hardening pass

Every finding below was resolved (or explicitly accepted with its
guard-rail built) in the Track-2 hardening pass before App Store
submission. The original table is kept with each row's resolution.

| Sev | Where | Finding | Resolution |
| --- | --- | --- | --- |
| **Medium** | `BackgroundIntents.swift` reminder path | Siri-armed notification shape pinned to flutter_local_notifications **18.0.1**; a plugin upgrade could silently break the tap contract. | **Guard-rail built:** `test/reminder_scheduler_test.dart` locks the armed-notification shape (ids, times, payloads, full-id-space cancel), and `docs/release_ios.md` carries a 4-step re-verify checklist for any plugin bump. Self-healing drain path unchanged. |
| **Medium** | `backup_service.dart` import | Row-by-row inserts; a huge restore blocked the UI on thousands of awaits. | **Fixed:** one drift `batch.insertAll` per table inside the same transaction. |
| **Low** | `HealthBridge.swift` sleep query | Night window `start − 6h → end of day` overlapped consecutive days by 6h — evening sleep could count twice. | **Fixed:** window is now 18:00 yesterday → 18:00 today (wake-day convention) — consecutive windows are disjoint and cover the clock. |
| **Low** | `health_habit_sync.dart` | Sync ran on every app foreground, unthrottled. | **Fixed:** 5-minute in-process throttle (`throttleWindow`); the Settings connect row passes `force: true`. Cold launches always sync. Test added. |
| **Low** | `journal_screen.dart` `_dayLabel` | `DateTime.now()` froze "Today" across midnight. | **Fixed:** labels read `dayProvider` (Settings' "Last backup" row too). |
| **Low** | `EntityMirrorService` | drift `tableUpdates` subscription never cancelled. | **Fixed:** `AppShell` owns the mirror's lifecycle and calls `stop()` on unmount — clean in tests and any multi-engine future. |
| **Low** | Widgets ↔ Live Activity | `FocusTimerAttributes` single-file-two-targets confusion risk. | **Accepted as designed** — single source file, header comment; no action possible that wouldn't add real duplication. |
| **Info** | `intent-tests` CI job | Simulator job existed but RunnerTests was an empty stub. | **Fixed:** `ios/RunnerTests/RunnerTests.swift` now drives every background intent's `perform()` and the CaptureQueue contract (cents, envelope, atomic naming, notification block); the job runs on every iOS-touching `main` merge, not just manual dispatch. |
| **Info** | `AiBridge.swift` | Fresh `LanguageModelSession` per call. | **Deliberate v1 choice, stands.** Multi-turn sessions remain Stage E1 of EDGE_AI_ROADMAP.md. |

## 3. What was reviewed and held up

The load-bearing invariants, re-verified this pass:

- **Exactly-once capture.** Queue record UUID = DB row id + `insertOrIgnore`
  + delete-after-commit. Force-kill between commit and delete re-runs a
  no-op insert. Covered by tests (idempotency, malformed → failed/,
  undo tombstones, cap on the failed graveyard).
- **Money exactness.** All five money tables store integer cents; sums
  happen in `int`; the only doubles are user input and display. The v3→v4
  migration is proven against a real planted v3 file with adversarial
  floats (4.35 → 435, ten dimes → exactly 100). Duplicate-detection keys
  compare cents, identically on both sides (CSV & DB).
- **Notification ids.** Stored, passed explicitly through queue records,
  never re-derived; Swift generates random 31-bit ids. No
  `String.hashCode` reimplementation anywhere (grep-verified).
- **Manual-wins for Health.** The sync never touches a log whose source
  isn't `health`; it deletes only its own stale checks. Five tests pin
  this, including the "manual log survives below-target data" case.
- **Freshness honesty.** Siri answers, snippets, and every widget check
  `dateKey == today` before quoting a number; stale state renders as
  "open the app" — never yesterday's figures. (The calendar-pinning fix
  in §1 closes the one hole found.)
- **Privacy posture.** No analytics, no network calls in app code
  (grep: no http/dio usage outside Flutter tooling), local files only,
  privacy manifest declares data-not-collected. AI runs on-device with
  name-constrained outputs and zero silent writes.
- **Xcode project surgery.** All hand-wired pbxproj entries (six Swift
  files, privacy manifest resource, Shared group) follow the 4-entry
  pattern with unique ids; the widget target was generated by Apple's own
  `xcodeproj` library, embeds correctly, and inherits `Generated.xcconfig`
  so extension/app versions can never diverge at upload.
- **CI economics.** macOS jobs are path-filtered + concurrency-cancelled;
  the fast typecheck (~20 s) front-runs the 5-minute build. The loop has
  caught three real Swift errors to date (IntentDialog literal, Int.init
  ambiguity — and the review found nothing the CI had missed in Swift).

## 4. Test coverage map

129 tests. Where they concentrate, and where they don't:

| Area | Coverage |
| --- | --- |
| Money rules, snapshot math, cents exactness | Strong (unit + planted-file migration) |
| Capture queue drain / mirror / undo | Strong (14 bridge tests) |
| Backup export/import incl. v3 conversion | Strong |
| Health sync rules | Strong (5 tests) |
| CSV parsing | Strong |
| AI/Health/Activity channel services | Contract-level (fake channels) |
| **Widgets/App Intents Swift** | **Compile-only** — behavior needs a device; the on-device checklist in release_ios.md is the test plan |
| **Screens/widgets (Flutter UI)** | **Thin** — one shell smoke test; forms rely on repo tests underneath |

The honest gap: UI regression coverage. The repos and rules under every
screen are tested, so breakage would be visual/interactive, not
data-corrupting.

## 5. Architecture debts worth knowing about

- **Two clocks.** `dayProvider` (app "today") and raw `DateTime.now()`
  coexist; data-layer code takes explicit `now` params (good), some
  display code reads the raw clock (the journal label above). A lint or
  convention pass could enforce one idiom.
- **Settings money stays double.** Income, surplus targets, retirement
  numbers live in the key-value settings store as doubles — inputs to
  projections (estimation), not to exact sums. Documented as deliberate
  in the v4 design; revisit only if settings ever join ledger math.
- **The mirror is a contract, not a cache.** entities.json / today.json
  have version fields and dateKey gates, but no checksum. A torn write is
  prevented by tmp+rename; a *semantically* wrong write (bug in the
  publisher) would be believed by Siri until the next publish. Acceptable
  because Dart re-resolves everything at drain time — reads are
  suggestions, writes are verified.

## 6. Verdict

Ship it to TestFlight. The data paths that can destroy trust —
capture, money, migration, backup — are defended by tests and by
design (idempotency, integer cents, manual-wins, freshness gates). The
open findings are quality-of-life and edge-hardening, none data-loss.
The next structural investment should be App Intents Testing Framework
tests on the simulator job, which converts the on-device checklist into
CI.
