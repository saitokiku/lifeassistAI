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

## 2. Open findings (acknowledged, not fixed)

Ranked by the damage they could do. None blocks TestFlight.

| Sev | Where | Finding | Why it's still open |
| --- | --- | --- | --- |
| **Medium** | `BackgroundIntents.swift` reminder path | A Siri-created reminder arms a notification whose `userInfo`/identifier shape is pinned to flutter_local_notifications **18.0.1**. A plugin upgrade could silently change that contract; the failure mode is a reminder that fires but taps dead. | Pinned by comment at the arming site and in pubspec; needs a checklist item on any plugin bump. The self-healing path (armed:false → Dart re-arms at drain) bounds the damage to "fires late". |
| **Medium** | `backup_service.dart` import | Row-by-row inserts inside one transaction. Fine at personal scale (thousands of rows); a 100k-row import would take tens of seconds with the UI blocked on the spinner. | Real usage is personal-scale; batching is a mechanical change when it matters. |
| **Low** | `HealthBridge.swift` sleep query | The "night that ends today" is approximated as `start − 6h → end of day`. A sleep session starting before 6 PM yesterday (shift workers) partially escapes the window. | Good enough for the auto-check use case; HKAnchoredObjectQuery with proper session grouping is the eventual fix. |
| **Low** | `health_habit_sync.dart` | Sync runs on every app foreground (2 days × mapped habits worth of HealthKit queries). No throttle. | Queries are statistics-level and cheap; add a 5-minute debounce if battery data ever says otherwise. |
| **Low** | `journal_screen.dart` `_dayLabel` | Uses `DateTime.now()` directly instead of the app's `dayProvider` clock, so a screen left open across midnight labels yesterday "Today" until rebuilt. | Cosmetic; every other surface uses the ticking clock. |
| **Low** | `EntityMirrorService` | The drift `tableUpdates` subscription is never cancelled — the service lives exactly as long as the app process, which is true on mobile but would leak in a hypothetical multi-engine embedding. | By design for now; documented here so it isn't re-discovered. |
| **Low** | Widgets ↔ Live Activity | `FocusTimerAttributes` exists as one file compiled into two targets. If someone edits the struct in Xcode's widget context and the file diverges semantically from what Runner expects, activities silently stop rendering. | Single source file (not a copy) makes true divergence impossible; the risk is only conceptual confusion, noted in the file header. |
| **Info** | `intent-tests` CI job | The opt-in simulator job assumes RunnerTests contains App Intents tests; none are written yet. Dispatching it today builds and runs an empty suite. | Placeholder for the App Intents Testing Framework work; harmless. |
| **Info** | `AiBridge.swift` | A fresh `LanguageModelSession` per call — correct for guardrails (no context bleed) but pays warm-up per request. Multi-turn sessions are Stage E1 of EDGE_AI_ROADMAP.md. | Deliberate v1 choice. |

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
