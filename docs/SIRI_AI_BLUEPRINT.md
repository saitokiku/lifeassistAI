# Life Assist — Siri AI Blueprint (the next horizon)

*Status: adopted plan of record, successor to
[IMPROVEMENT_BLUEPRINT.md](IMPROVEMENT_BLUEPRINT.md) (fully implemented as
v3). Scope decided with the user: **iOS first**, **advanced Siri as the
centerpiece** (built for iOS 27's Siri AI), plus HealthKit auto-habits and
widgets/Live Activity. Calendar overlay and iCloud sync/backups are
explicitly out of scope for this horizon. The user has a paid Apple
Developer account and a Mac, so TestFlight and entitlement-gated features
are real targets — but every phase is designed so the code is written and
compile-verified from this Linux repo via a macOS CI loop first.*

*Execution: Phases 0–4 are implemented and CI-verified (Phase 1 ran
last, after Phase 4 — the queue/AI contracts already spoke integer
cents, so nothing froze a float format). Phase 5 (HealthBridge) and
Phase 6 (App-Group paths, widget sources, target-generator script) are
scaffolded dormant; Phase 7 store readiness (privacy manifest, bundle
id, TestFlight guide) is done. Where on-device AI goes next lives in
[EDGE_AI_ROADMAP.md](EDGE_AI_ROADMAP.md).*

---

## 1. Where we stand

v3 is a complete, trustworthy daily driver: universal main goal, honest
scoring and streaks, accounts with balance history and net worth, CSV
statement import with dedupe, recurring expenses, month/week browsing, a
focus timer, weekday-scheduled habits with per-habit reminders and a
heatmap, weekly review, chapters, app lock, global search, auto-backups —
and the **capture bus**: any `lifeassist://capture?type=…` URL opens the
matching sheet, prefilled, from cold or warm start. Five foreground App
Intents already speak that URL.

What still separates this from the *ultimate* tool:

| Gap | Why it matters |
|---|---|
| Siri still opens the app | The magic moment is logging with the phone locked, hands busy. iOS 27's Siri AI makes voice the primary input surface — for apps that expose App Intents properly. |
| The intents aren't even compiled in | `LifeAssistIntents.swift` ships in the repo but isn't wired into the Xcode target, and CI never builds iOS. |
| Siri can't see the app's nouns | "Groceries", "Deep work", "Stretch" are strings we fuzzy-match in Dart. As real AppEntities, Siri resolves them itself — and the semantic index makes them part of the user's personal context. |
| No natural-language capture | "Coffee 4.50 yesterday and two hours of deep work" should become two structured entries. The on-device Foundation Models framework does this for free, privately. |
| Money is floating-point | Every new consumer (queue records, snippets, AI drafts) would freeze the float format in. Cents-integer migration has to land **before** the bridges. |
| No presence outside the app | Widgets, Live Activities, and Control Center are how the app stays glanceable without being opened. |
| Habits are manual even when the phone knows | Apple Health already records workouts and mindful minutes; exercise/meditation habits should auto-complete (opt-in). |

## 2. The bet: iOS 27 Siri AI rides App Intents — and we already built the rail

WWDC 2026 settled the architecture question:

- The rebuilt **Siri AI** (iOS 27) integrates with third-party apps
  **exclusively through App Intents**. SiriKit is formally deprecated.
- iOS 26/27 App Intents add: **system entity/intent schemas** (Siri
  understands "log an expense" without registered phrases), **semantic
  indexing** of AppEntities (with attribution), **interactive snippets**,
  **multi-turn follow-ups**, streaming results, and an **App Intents
  Testing Framework**.
- The **Foundation Models framework** (iOS 26+) exposes the on-device
  ~3B model with `@Generable` guided generation — structured output that
  cannot leave the schema, at zero cost, offline. This is for in-app
  intelligence; Siri-routed actions stay on the App Intents rail.

Life Assist's capture bus was designed as "the future AI-input rail" in
the last blueprint. This horizon cashes that in with **three small
bridges** between the Flutter world and the iOS world:

```
┌────────────── Flutter (drift DB, all logic) ───────────────┐
│                                                            │
│  EntityMirrorService ──writes──▶ entities.json ─┐          │
│  CaptureQueueDrain  ◀──reads──  queue/pending/ ─┼─┐        │
│  AiService (Dart)   ◀──channel─ lifeassist/ai  ─┼─┼─┐      │
└─────────────────────────────────────────────────┼─┼─┼──────┘
                                                  │ │ │
┌────────────── Swift (same app process) ─────────┼─┼─┼──────┐
│  AppEntities + EntityQuery  ◀───── reads ───────┘ │ │      │
│  Background AppIntents ────── writes ─────────────┘ │      │
│  AiBridge (FoundationModels) ◀── MethodChannel ─────┘      │
└────────────────────────────────────────────────────────────┘
```

1. **Entity mirror (Dart → Swift).** A versioned `entities.json` in the
   app container, atomically rewritten (debounced) whenever budgets,
   categories, habits, or reminders change. Swift `EntityQuery`s read it
   so Siri resolves "Groceries" as a typed entity — no Flutter engine, no
   SQL against a migrating schema.
2. **Capture queue (Swift → Dart).** Background intents
   (`openAppWhenRun = false`) write one JSON file per capture into
   `queue/pending/` and Siri confirms without opening the app. Dart
   drains the queue at bootstrap and on resume; the record's UUID becomes
   the database row id, so processing is idempotent (exactly-once effect,
   at-least-once delivery).
3. **AI channel (Dart ↔ Swift).** A `lifeassist/ai` MethodChannel wraps
   the Foundation Models framework: natural-language text in, guided
   `@Generable` drafts out — constrained so the model can *only* answer
   with category/budget/habit names that actually exist.

Everything else in this horizon is consumers of those three bridges.

## 3. Design decisions (recorded, with rationale)

- **JSON mirror, not direct SQLite reads from Swift.** Reading drift's
  SQLite from Swift works mechanically but couples Swift SQL to a schema
  this very plan migrates (v4 cents). Every future migration would be a
  silent Siri-breaker. The mirror is a stable, versioned contract; a
  stale mirror only degrades Siri's suggestion list, never correctness,
  because Dart re-resolves names at drain time with the same resolver the
  capture bus already uses.
- **Not CoreSpotlight as the bridge.** Donation feeds Spotlight, but
  `EntityQuery` parameter resolution needs data in the intent process.
  Semantic indexing comes later via `IndexedEntity` conformance — a
  complement, not the bridge.
- **One file per queue record, not JSONL.** Atomic tmp+rename per record
  makes torn appends impossible; deletion is the natural ack. Filename
  `<epochMillis>-<uuid>.json` gives ordering and uniqueness.
- **Notification ids are passed explicitly, never re-derived.** Dart's
  `String.hashCode` is undocumented and version-unstable — Swift must
  never reproduce it. Swift generates a random 31-bit id, arms the
  notification itself with a **flutter_local_notifications-compatible
  request** (identifier `String(id)`, the plugin's documented `userInfo`
  shape, pinned to 18.0.1 with a comment), and passes the id through the
  queue record. Dart stores it in the reminder row's `notificationId`
  column (already the source of truth for every cancel path) and re-arms
  through the plugin on drain. Self-healing in both directions.
- **No App Group until widgets.** Background intents in the app target
  run in the app's own (headless) process and sandbox — the entire Siri
  centerpiece is entitlement-free, so unsigned CI builds stay
  sideloadable and testable. The mirror moves to the App Group container
  only in Phase 6, when a second process (the widget extension) first
  exists.
- **Deployment target 13.0 → 17.0.** App Intents needs 16; 17 adds
  interactive widgets and deletes a year of `@available` noise. iOS 17+
  covers ~95% of active iPhones in 2026. Everything newer (snippets,
  schemas, FoundationModels = 26; ControlWidget = 18) is cleanly
  type-level gated.
- **View Annotations API: skipped, honestly.** It annotates native
  SwiftUI/UIKit views; Flutter-rendered UI can't adopt it. We get
  on-screen awareness only where iOS composes it for us (snippets).
- **On-device AI only in v1.** No Private Cloud Compute — "your data
  never leaves the device" stays a one-sentence truth. PCC (zero-cost for
  Small Business Program members) is a recorded option for later.
- **Voice never invents data.** Unknown category → saved uncategorized
  with the spoken name preserved. AI drafts render as chips the user
  confirms — zero silent writes. Failures throw honest Siri errors with a
  foreground continuation, never fake success.
- **The new Xcode *target* (widgets) is scripted, not hand-written.**
  Hand-editing 4 pbxproj entries into an existing target is low-risk and
  we do it freely; hand-writing a whole `PBXNativeTarget` graph blind
  from Linux is not. Phase 6 commits an `xcodeproj`-gem script that a
  macOS CI job runs, builds, and returns the verified patch.

## 4. The phases

**The cut line:** Phases 0–4 are fully implementable and CI-verifiable
from this Linux repo, entitlement-free, sideloadable with a free Apple
ID — and they contain the entire Siri centerpiece. Phase 5 is
Linux-writable with device-side provisioning friction. Phase 6 needs the
scripted-target CI loop and realistically the paid account. Phase 7 is
store mechanics.

### Phase 0 — iOS enablement + the CI loop
Wire `LifeAssistIntents.swift` into the Runner target (4-entry pbxproj
edit), raise the deployment target to 17.0, add
`ITSAppUsesNonExemptEncryption`, and create `.github/workflows/ios.yml`:
a fast `swiftc -typecheck` job, then `flutter build ios --no-codesign`
packaged as an **unsigned `LifeAssist.ipa` artifact** (sideload via
AltStore/SideStore; TestFlight path documented in `release_ios.md`).
Triggers are path-filtered (`ios/**`, pubspec) + manual + `ios-v*` tags —
macOS minutes bill 10× on private repos, so the loop stays bounded.
**Accept:** CI green with artifact; on a phone, "Log an expense in Life
Assist" opens the prefilled sheet.
**User:** install the artifact (or run once from Xcode); say the phrase.

### Phase 1 — cents migration + journal-lite (pure Dart)
Schema v4: all money becomes integer cents (`×100`, half-even) across
transactions, recurring, categories, accounts, snapshots; `Money` value
type; CSV import, forms, backup (export v4, import converts v3) swept.
This lands **before** any bridge freezes a float format into queue
records or snippets. Plus the last cheap blueprint hole: a
`JournalEntries` table and a lightweight journal (You tab + evening Today
entry point), searchable and backed up.
**Accept:** v3 backups import with identical totals; sums exact to the
cent; a journal entry takes <5 seconds.

### Phase 2 — Siri background capture (centerpiece, part 1)
The entity mirror and capture queue (§2, §3), five background intents
(expense, time, idea, reminder, habit check) with typed AppEntity
parameters resolved from the mirror, honest failure paths
(`queue/failed/` + a Settings diagnostics row), and Siri-armed reminders
that fire before the app is ever opened.
**Accept:** locked-phone "log 12.50 for groceries" lands exactly once
(kill-the-app double-delivery test); a Siri-created reminder fires on
time and later edits cancel/re-arm cleanly; malformed queue files surface
in diagnostics, never vanish.
**User:** on-device Siri runs; permission grant on first notification.

### Phase 3 — iOS 26/27 Siri AI alignment
Adopt system intent/entity schemas where they fit, `IndexedEntity`
conformance (semantic index, attributed), interactive confirmation
snippets (amount, resolved category, month-to-date total *only when the
mirror's aggregates are same-day fresh* — the honesty rule — plus Undo
and Open), and query intents (`GetBudgetStatus`, `GetUpNext`) for
multi-turn follow-ups. All `#available(iOS 26)`-gated; iOS 17–25 keeps
phrases + plain dialogs. The mirror gains a `today` aggregates section —
which is also the widget feed later.
**Accept:** phrase-free "log twelve fifty for groceries in Life Assist"
resolves the right entity under Siri AI; snippet totals are correct or
absent; Undo removes the row; Spotlight surfaces "Groceries budget".
**User:** iOS 27 device testing; report Siri transcript quirks.

### Phase 4 — Foundation Models bridge (on-device AI)
`AiBridge.swift` + `lifeassist/ai` channel: `availability()`,
`parseCapture(text, context)` → guided `CaptureDraft`s (`@Guide`
constrains names to the runtime lists — the model cannot invent a
category; compound utterances yield multiple drafts),
`categorizeTransactions` (CSV import suggestions, chunked ≤20),
`draftWeeklyReview`, `triageIdea`. Dart surfaces, each invisible when
unavailable: a smart-capture field on Today (drafts → chips → the
existing prefilled sheets), "Suggest categories" in CSV import review,
"Draft reflection" in the weekly review, "Expand" in idea capture.
**Accept:** "coffee 4.50 yesterday and 2h deep work" → two correct chips
→ two confirmed rows; suggestions only ever name real categories; the app
is pixel-identical when AI is unavailable.
**User:** Apple-Intelligence-capable phone (iPhone 15 Pro+/16+), toggle on.

### Phase 5 — HealthKit auto-habits
A thin owned `NativeBridge.swift` (`lifeassist/native`):
`healthDailySummary(date)` (steps, workout minutes, mindful minutes) +
permission flow; `Runner.entitlements` (HealthKit) + usage strings;
per-habit **opt-in** mapping ("auto-complete from Health" + threshold)
writing normal, source-tagged, undoable `HabitLogs` rows.
**Accept:** a workout auto-checks the exercise habit by evening; revoking
Health access degrades silently to manual.
**User:** permission grants; HealthKit + free-signing has friction — use
the paid profile or Xcode run from the Mac.

### Phase 6 — Widgets, Live Activity, Control Center
`scripts/ios/add_widget_extension.rb` (xcodeproj gem, idempotent) run by
a manual-dispatch macOS CI job that patches the project, builds, and
uploads both the IPA and the verified pbxproj (CI is our Xcode). Widget
bundle: score ring + up-next (home), habits-due (lock screen accessory),
an interactive habit-check button (writes a `habitLog` queue record —
same idempotent drain), focus-timer **Live Activity** (Dynamic Island),
iOS 18 **ControlWidget** for quick capture. App Group entitlement added
to both targets; the mirror relocates to the group container (one-time
move, dual-path read).
**Accept:** widgets reflect the mirror after the next write; a habit
checked from the widget lands exactly once; the timer Live Activity
survives lock.
**User:** paid-account provisioning (App Groups); TestFlight build.

### Phase 7 — Store readiness
`PrivacyInfo.xcprivacy` (data-not-collected; required-reason APIs:
UserDefaults CA92.1, file-timestamp C617.1, disk-space E174.1), App Store
checklist execution (icons exist; screenshots, age rating, review notes),
TestFlight → App Store. Optional: encrypted backup codec
(AES-256-GCM + passphrase KDF) — deferred unless wanted, since iCloud
backup was scoped out.
**Accept:** automated privacy checks pass; TestFlight build approved.
**User:** App Store Connect throughout.

## 5. Deferred / out of scope (this horizon)

- **Calendar overlay (EventKit)** — user deselected.
- **iCloud Drive backups / CloudKit sync** — user deselected; real
  multi-device sync is a CRDT/conflict design and stays a recorded
  future bet.
- **Android parity** for background capture (App Actions/widgets) — the
  deep-link scheme already works there; parity work waits until iOS
  proves the shapes.
- **Apple Watch app**, **Private Cloud Compute**, **provider-swapped
  Foundation Models** (Gemini/Claude via the LanguageModel protocol) —
  recorded options, not commitments.

## 6. Verification model

Dart: the existing ubuntu CI (analyze + 96-and-growing tests) covers all
bridge logic — mirror writer, queue drain, idempotency, malformed-file
handling — because the bridges are deliberately plain files and channels.
Swift: compiled on every iOS-touching push by the macOS workflow
(typecheck + full unsigned build), optionally exercised by the App
Intents Testing Framework on an iOS 26 simulator. Behavior that only a
phone can prove (Siri dialogs, lock-screen capture, Apple Intelligence
availability) ships with a per-phase on-device checklist in
`release_ios.md`.
