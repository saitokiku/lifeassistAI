# Life Assist — Improvement Blueprint

*Status: **implemented** (v3). Tier 0, Tier 1, and Tier 2 shipped in full; Tier 3 shipped
the Siri flagship as Phase A (capture bus, done in Dart) + Phase B v1 (App Intents Swift
sources — see [SIRI_SETUP.md](SIRI_SETUP.md) for the one-time Xcode step) + Phase C
(Android shortcuts). Real bank-account tracking shipped as accounts + balance history +
CSV statement import + recurring expenses; live aggregator feeds are documented as an
integration seam in [BANK_CONNECTIONS.md](BANK_CONNECTIONS.md) because they require the
user's own API keys and token server. Still open from Tier 3: journal/notes (weekly
review covers the core need), calendar overlay, encrypted sync, and the cents-integer
money migration. The file references below describe the pre-implementation code and
remain useful as the rationale record.*

*Original preface: adopted plan of record for what comes after the v2 revamp. Everything
in this document was verified against the code on `claude/life-assist-redesign-105upu` —
each finding carries a file reference so implementation sessions don't have to re-audit.
Release mechanics live in [roadmap.md](roadmap.md); AI work stays deferred and scoped in
[AI_PRODUCT_ROADMAP.md](AI_PRODUCT_ROADMAP.md).*

---

## 1. North Star

"Better" means three things, in order:

1. **A trustworthy daily driver.** Nothing silently fails (reminders that never fire),
   nothing flatters (empty months drawn as great months), nothing punishes unfairly
   (points you can't earn, streaks that die to a single bad day). Trust is the product.
2. **Depth where the user actually lives.** Money is lived in months, time in weeks,
   habits in weekdays — the app currently only understands *now* (this month, this week,
   every day). Depth means letting the user move through time.
3. **Voice-first capture as the differentiator.** The cheapest way to log something
   should be to say it. "Hey Siri, log 20 dollars for groceries in Life Assist" is the
   flagship bet — and the infrastructure it needs (a capture bus) also powers notification
   taps, app shortcuts, home-screen widgets, and the future AI input rail.

Everything below serves one of those three.

---

## 2. Scorecard — where v2 stands

| Lens | What v2 got right | Where it still falls short |
| --- | --- | --- |
| **Philosophy** | One goal, front and center; honest empty states; forgiving copy | The loop is capture → glance → act → **nothing**: no review ritual, no goal history, completion moment unreachable (bug) |
| **UI/UX** | Coherent IA, one component library, designed dark theme, fast logging forms | Current-period-only views everywhere; a few contrast/discoverability misses; no search |
| **Logic** | Ratio-based scoring, safe migrations, undoable destructive actions | Score counts disabled areas; streaks have no grace; history charts rewrite the past with today's income |
| **Features** | Goal/milestones/steps loop, quick-add, backup import/export | No recurring transactions, no weekday scheduling, no timer, no journal, no voice |
| **Optimizations** | Local-first SQLite, indexed-stack tabs, reduced-motion support | Whole dashboard recomputes every minute; zero DB indexes; unbounded history queries; no CI |

---

## 3. The plan at a glance

Four tiers. Tier order is the recommended build order; within a tier, order is free.
Effort: S = hours, M = days, L = a week-plus.

### Tier 0 — fix now (launch blockers and trust breakers)

| # | Item | Lens | Effort | Why it can't wait |
| --- | --- | --- | --- | --- |
| 0.1 | Declare `POST_NOTIFICATIONS` in AndroidManifest (zero `uses-permission` entries today; targetSdk ≥ 33) | Logic | S | Reminders are **entirely non-functional on Android 13+** — permission request can't succeed without the declaration |
| 0.2 | Fix the vanishing completed goal: `watchCurrentGoal` filters to active/paused (`focus_repository.dart:19-23`), so the `_CompletedCard` celebration (`focus_screen.dart:208, 464-498`) is unreachable and Focus snaps to the blank "set a goal" invite | Logic/Philosophy | S | The flagship loop's payoff moment is dead code; completing a goal *feels like data loss* |
| 0.3 | Renormalize the day score to enabled areas: `focusScore` always sums money(15)+health(15)+recovery(15) even when those `DashboardArea`s are off (`score_utils.dart:59-95`, `dashboard_state.dart:34-42`) — up to 30 unearnable points | Logic | S–M | A number that can't be maxed teaches users to ignore it; the scoreboard tiles already respect areas, the score must too |
| 0.4 | Add the Android boot receiver (`RECEIVE_BOOT_COMPLETED` + `ScheduledNotificationBootReceiver`) | Logic | S | All reminders silently die on reboot until the next app open |
| 0.5 | Stop swallowing reminder scheduling failures: `_resync()` returns a `Result` that every caller discards (`reminders_controller.dart:37-92`) | Logic | S | A saved-but-never-fired reminder is the worst kind of failure — invisible |
| 0.6 | Make clipboard export opt-in: export currently copies the **entire database to the clipboard unconditionally** before the share sheet opens (`settings_screen.dart:549`) | Philosophy | S | Cloud-synced clipboards (Gboard, Universal Clipboard) can exfiltrate the user's full financial history — at odds with the local-first promise |
| 0.7 | Surplus history low-data state: months with no data render as full-height "income = surplus" bars (`money_controller.dart:104-116`) | UI/UX | S | The money view must never flatter; render gaps as gaps |
| 0.8 | Light-mode contrast: raw teal small-caps labels ≈1.9:1 on tinted cards (`up_next_card.dart:35`, `available_time_card.dart:30`, `focus_screen.dart:531`) — use `primaryDim` in light mode | UI/UX | S | WCAG failure on the two hero cards |
| 0.9 | Wrap CheckInStrip habit toggles in the same try/catch the checklist has (`check_in_strip.dart:109-128` vs `habit_checklist.dart:61-95`) | Logic | S | A failed write from Today is currently invisible |
| 0.10 | Minimal CI: GitHub Actions running `flutter analyze` + `flutter test` on push (no `.github/` exists) | Optimizations | S | Guardrail before everything below; the 8 test files already exist to run |

### Tier 1 — quick wins (each roughly a day)

| # | Item | Lens | Effort |
| --- | --- | --- | --- |
| 1.1 | Insert a **`dayProvider`** (date-only) between the per-minute `clockProvider` and its 9 `readNow()` consumers (`core/providers.dart:26-32`) — today the whole dashboard recomputes and drift streams are torn down/resubscribed **every minute** | Optimizations | S–M |
| 1.2 | Add DB **indexes** (none exist): `date` columns, `metricId`, `habitId`, `budgetId`, `categoryId`, `mainGoals.status`; bump schemaVersion | Optimizations | M |
| 1.3 | **Bound the unbounded queries**: `watchActions()` (`focus_repository.dart:254`) and `watchAllLogs()` (`habits_repository.dart:23`) load every row ever, re-materialized on every write; compute streaks from a bounded window | Optimizations | M |
| 1.4 | `autoDispose` on rolling-date family providers (`_txSinceProvider`, `_blocksSinceProvider`, `metricEntriesProvider`) — leaked live drift subscriptions accumulate per month/week today | Optimizations | S |
| 1.5 | Gate seed + legacy migration behind a version flag: `bootstrap.dart:26-29` issues ~11 queries + 2 unconditional UPDATEs on every launch | Optimizations | S |
| 1.6 | **Snapshot income per month**: surplus history applies *today's* income to all past months (`money_controller.dart:88-117`, admitted at :86) — a raise silently rewrites financial history | Logic | M |
| 1.7 | **Milestone drag-reorder** — `goals.sortOrder` exists in the schema; no `ReorderableListView` anywhere | UI/UX | S |
| 1.8 | **Ideas → Focus conversion**: the "Integrate" verdict is a dead end (`idea_review_card.dart:186-216`) — offer "Add as milestone" prefilled from the idea; group the decided pile by verdict | UI/UX | S–M |
| 1.9 | Recent-category **chips** in the transaction form instead of a dropdown (mirror `time_block_log_form.dart:279-285`) | UI/UX | S |
| 1.10 | **Streak grace day**: one missed day currently kills any streak (`daily_action.dart:24-35`, `habit_log.dart:13-24`); allow a configurable freeze — and add streak-math tests (zero exist for the app's most-loved number) | Logic/Philosophy | M |
| 1.11 | "Last backed up N days ago" nudge in Settings (export is fully manual today) | Philosophy | S |
| 1.12 | Small honesty patches: 24h/day cap on time logs (only per-entry ≤24 is checked, `time_block_log_form.dart:268`); expire the idea "helps my goal" cooling bypass (permanent today, `parked_idea.dart:24`); surface the goal's `targetDate` as a Time countdown (`countdown.dart:26-53` reads only the countdowns table) | Logic | S each |
| 1.13 | Notification **tap → deep link** (no `onDidReceiveNotificationResponse` registered, `notification_service.dart:36-49`) — lands free once the capture bus (2.1) exists | UI/UX | S* |
| 1.14 | Real **app icon** (placeholder today) | UI/UX | S |

### Tier 2 — structural (daily-driver depth)

| # | Item | Lens | Effort |
| --- | --- | --- | --- |
| 2.1 | **Capture bus** (Siri Phase A — see §9): `/capture` deep-link route + shared `CaptureLauncher` + prefill params on the four capture forms | Features | M |
| 2.2 | **Per-id notification cancellation**: `ReminderScheduler.syncAll` calls `cancelAll()` (`reminder_scheduler.dart:25`), nuking every notification the app owns — hard prerequisite for per-habit reminders *and* Siri Phase B | Logic | S |
| 2.3 | **Weekly Review ritual**: a guided end-of-week flow over data the app already has (goal steps + verdicts, hours vs targets, spend vs budget, habit completion) ending in one chosen emphasis for next week. The missing quarter of the loop; also the substrate AI Phase 2 will later narrate | Features/Philosophy | M–L |
| 2.4 | **Goal history — "Chapters"**: a past-goals screen (`watchAllGoals()` exists and is used only in tests) plus a real completion ceremony flowing out of the 0.2 fix | Features/Philosophy | M |
| 2.5 | **Money depth**: month stepper to browse/edit past months (`monthTransactionsProvider` is hard-wired to the current month, `money_controller.dart:21-25`); recurring transactions (rent/subscriptions are re-typed monthly today); transaction search/filter | Features | L |
| 2.6 | **Time depth**: past-week navigation; a start/stop **timer** that prefills the hours field; give dynamic countdown tiles a visible edit affordance (long-press-only today, `countdown_list.dart:60-65`); differentiate the two identical-looking rows that do different verbs (log vs edit — `weekly_time_budget_card.dart:105` vs `budget_manager_sheet.dart:89`) | Features/UI/UX | M–L |
| 2.7 | **Habits depth**: weekday scheduling (model is daily-only, `habit.dart`), per-habit reminder times (needs 2.2), monthly heatmap view | Features | M–L |
| 2.8 | **Reminders depth**: weekday schedules + one-shot reminders (schema stores only hour/minute — a date column also unblocks Siri "remind me Friday"), snooze action | Features | M |
| 2.9 | **Time-of-day-aware Today**: morning weighting (plan the day) vs evening weighting (close the day — review the step, check habits) in the existing Up-next engine | Philosophy | M |
| 2.10 | **Auto-backup**: rolling local export file (keep last N), building on 1.11 | Philosophy | M |
| 2.11 | **App lock** (biometric/PIN via `local_auth`) — the app holds income, balances, and net worth | Features | M |
| 2.12 | **Global search** across transactions, ideas, steps, milestones | Features | M |
| 2.13 | **List virtualization**: long lists are eager `Column`s inside screen `ListView`s — action history is worst (unbounded + eager `Dismissible` rows, `action_history_list.dart:91-137`); convert to slivers/builders, pairs with 1.3 | Optimizations | M |
| 2.14 | **Tests for the engines**: `DashboardState`/`UpNextKind` resolution and the history aggregation providers are untested | Optimizations | M |

### Tier 3 — big bets

| # | Item | Effort | Notes |
| --- | --- | --- | --- |
| 3.1 | **Siri Phase B — iOS App Intents** (flagship) | L | §9; requires 2.1 + 2.2 |
| 3.2 | Siri Phase C — Android shortcuts + App Actions | S–M | Rides the 2.1 intent-filter |
| 3.3 | Journal / notes | M–L | Candidate to fold into Weekly Review (2.3) rather than a separate surface |
| 3.4 | Calendar overlay; CSV import; encrypted sync | L each | Already scoped in roadmap.md. **CSV is blocked on a money-precision policy**: all money is stored as `double` (`app_database.dart:70` etc.) — adopt cents-integers or a documented rounding policy at aggregation boundaries first |
| 3.5 | AI phases | L | Stay per AI_PRODUCT_ROADMAP.md; the capture bus is also the AI input rail |

**Not doing (deliberately):** chat as an interface, social features, gamification beyond
streaks, cloud accounts, auto-categorization without confirmation. Focus is the feature.

---

## 4. Lens: Philosophy

Each theme: *principle → where the app violates it today → remedy*.

1. **Close the loop.** The product's rhythm is capture → glance → act → review — and the
   review quarter doesn't exist. Data is collected daily and never reflected weekly.
   → Weekly Review (2.3), time-of-day-aware Today (2.9).
2. **Forgiveness over pressure.** One missed day zeroes any streak
   (`daily_action.dart:24-35`); creating a new goal silently **archives** a paused one
   with no ceremony (`focus_repository.dart:46-53`). Life happens; the app should absorb
   it, not penalize it. → grace days (1.10), explicit archive confirmation inside the
   new-goal flow (fold into 2.4).
3. **Goals are chapters, not rows.** Completed and archived goals accumulate invisibly
   forever — the app forgets the user's history of becoming. → Chapters screen (2.4).
4. **Honor completion.** The single most emotionally important state in the app — *goal
   done* — is currently unreachable (0.2). Fix the query, then make completion a moment:
   celebration card → optional reflection → "set the next chapter."
5. **The score must be earnable.** 30 points locked behind disabled areas (0.3) makes the
   ring dishonest. Renormalize; the number must always be a fair summary of what the user
   *chose* to track.
6. **Data stewardship is a feature.** For a no-cloud app, the user's export *is* their
   safety net — today it's manual-only and leaks to the clipboard (0.6). → backup nudge
   (1.11), auto-backup (2.10), app lock (2.11).
7. **Meet the user where their hands are.** Logging is the tax everything else runs on;
   the cheapest capture is voice or one tap from the lock screen. → capture bus (2.1),
   Siri (3.1), shortcuts (3.2).

---

## 5. Lens: UI/UX

Grouped by surface; every row is verified.

**Money** — no past-month browse/edit (2.5); no recurring transactions (2.5); no
search/filter (2.5/2.12); category dropdown instead of chips (1.9); surplus chart
flatters empty months (0.7); three icon-only overflow menus missing tooltips
(`transactions_list.dart:241`, `budget_category_list.dart:146`,
`long_term_target_card.dart:75`).

**Time** — no timer (2.6); no past-week nav (2.6); long-press-only edit on dynamic
countdown tiles (2.6); identical-looking rows perform different verbs — a budget row
*logs* in one card and *edits* in another (2.6).

**Habits** — daily-only model, no weekday scheduling (2.7); no per-habit reminder (2.7);
no monthly heatmap (2.7).

**Ideas** — "Integrate" is a dead end; no path from an accepted idea to a milestone
(1.8); the decided pile lumps ignore/later/integrate together (1.8).

**Reminders** — daily-only; no weekday schedule, no one-shot, no snooze (2.8);
notification taps go nowhere (1.13).

**Cross-cutting** — light-mode teal label contrast (0.8); app icon placeholder (1.14);
no goal history (2.4); no global search (2.12); milestone reorder missing (1.7);
countdown tile value `Row` can overflow at max text scale (`countdown_list.dart:112-130`
— add ellipsis/fit guard); tablet/landscape could earn a two-column Today (later, after
2.x depth lands).

---

## 6. Lens: Logic & correctness

**Defect root causes (Tier 0):**
- 0.1/0.4/0.5 share one theme: the notification pipeline fails silently at three layers
  (manifest permission, reboot persistence, swallowed `Result`s). Fix all three together
  and add a visible "couldn't schedule" state.
- 0.2 is a query-shape bug: `status.isIn(['active','paused'])` plus a UI branch that can
  therefore never see `completed`. Either include `completed` in "current" until the user
  starts a new chapter, or route completion to a dedicated ceremony screen.
- 0.3 is a modeling gap: `FocusScoreInput` doesn't know about `DashboardArea`s. Pass the
  enabled set, zero the disabled components, renormalize the denominator.

**Rules-level fixes:** streak grace (1.10); 24h/day cap (1.12); idea-bypass expiry
(1.12); per-month income snapshots (1.6); goal target date as countdown (1.12).

**Test plan (fills the riskiest gaps):** streak/missed-day math (`DailyActionStats`,
`HabitStats`) — zero coverage today; `DashboardState`/`UpNextKind` priority resolution;
history aggregation (`monthlySurplusHistoryProvider`, `weeklyHoursHistoryProvider`);
notification scheduling (`ReminderScheduler.syncAll` against a fake plugin); form guards
(24h cap, amount validators).

---

## 7. Lens: Features

The depth features are enumerated in Tiers 2–3; the shape that matters:

- **Weekly Review (2.3)** is the highest-leverage *new* feature: it needs no new data,
  only presentation and a ritual — and it becomes the home for journal-style reflection
  (3.3) and later AI narration. Ship it before any AI.
- **Chapters (2.4)** turns the goal system from a treadmill into a biography.
- **Money/Time/Habits depth (2.5–2.7)** is what converts "nice tracker" into "daily
  driver" — the ability to look backward and to schedule forward.
- **Voice capture (§9)** is the differentiator and the only Tier-3 bet with its own
  section.

---

## 8. Lens: Optimizations

The performance ladder, in dependency order:

1. **`dayProvider` (1.1)** — collapses per-minute full-dashboard recomputation to
   once-per-day (plus real data changes). Biggest win per line changed.
2. **Indexes + bounded queries (1.2/1.3)** — year-scale readiness; today every filtered
   watch is a full-table scan and two queries load unbounded history.
3. **`autoDispose` families (1.4)** — stops the slow leak of live drift subscriptions.
4. **Virtualization (2.13)** — eager `Column`s inside `ListView`s defeat laziness; the
   action history builds every `Dismissible` row up front.
5. **Startup gating (1.5)** — removes ~11 queries + 2 writes from every cold start.

Engineering health: CI (0.10) first; the test plan (§6) rides it. Adopt a
**money-precision policy** (cents-integers or documented rounding) before CSV import
multiplies row counts (3.4).

---

## 9. Flagship: voice-first capture (Siri)

Three phases; A is cross-platform groundwork, B is the iOS bet, C is Android parity.

### Phase A — the capture bus (effort M)

One deep-link entry point that every fast path shares — Siri, notification taps, app
shortcuts, future widgets, future AI:

- **Route:** top-level `GoRoute('/capture')` beside `/onboarding` in
  `lib/routing/app_router.dart`. Its redirect parses query params into a small
  `PendingCapture` state (new provider), then forwards to the owning tab (`/money`,
  `/focus`, `/time`, `/today`). The existing onboarding guard runs first, so captures
  during first-run degrade safely.
- **Launcher:** extract the quick-add dispatch switch from
  `dashboard_screen.dart:116-137` into a shared `CaptureLauncher`; `AppShell`
  (`lib/shared/layout/app_shell.dart`) listens for a pending capture and opens the
  matching sheet — sheets then always run on a live screen context, the exact contract
  `quick_add_sheet.dart` already documents. **Must-fix while extracting:** the current
  switch silently drops the capture when providers are still null
  (`if (money == null) return;`) — fine behind a FAB, data loss from a cold-start deep
  link. Await first values instead.
- **Prefill params to add** (all forms already expose static `show()` constructors):

  | Form | Has today | Add |
  | --- | --- | --- |
  | `TransactionEntryForm.show` | `categories`, `transaction` | `initialAmount`, `initialDescription`, `initialCategoryId` + spoken-name → category resolution (case-insensitive, uncategorized fallback) |
  | `TimeBlockLogForm.show` | `budgets`, `block`, `initialBudgetId` | `initialHours`, `initialNote`, name → budget resolution |
  | `IdeaCaptureForm.show` | `idea` | `initialTitle` (already voice-shaped) |
  | `ActionLogForm.show` | `action` | `initialActionText` only — the mandatory no-default verdict stays; voice prefills text, the human taps the outcome |
  | `ReminderEditor.show` | `reminder` | `initialTitle`, `initialHour`/`minute` ("remind me Friday" additionally needs the 2.8 schema) |

- **Wiring:** add `app_links`; iOS `CFBundleURLTypes` (`lifeassist://`); Android VIEW
  intent-filter (MainActivity is already `singleTop`, so links arrive without relaunch).
  Route notification taps through the same bus (closes 1.13).

### Phase B — iOS App Intents (effort L, iOS 16+ extension target)

- **v1 — foreground intents:** Swift App Intents with App Shortcut phrases ("Log an
  expense in Life Assist", "Add an idea…", "Add a reminder…"). Parameters resolved by
  Siri dialog (amount, title, time), then the intent opens
  `lifeassist://capture?...` — the bus does the rest. Simple, reliable, ships first.
- **v2 — background intents** for unambiguous writes (expense, idea, time, reminder):
  the extension writes to an **App Group pending-capture queue** (JSON), because the
  drift database must not be written from a second process. The app drains the queue at
  the end of `bootstrap()` and on resume (`WidgetsBindingObserver`). Siri-created
  reminders arm `UNUserNotificationCenter` directly from Swift so they fire even if the
  app isn't opened — mirroring the Dart id convention (`SeedService.notificationIdFor`).
- **Hard prerequisite:** per-id cancellation (2.2). `syncAll`'s `cancelAll()` would
  silently destroy Siri-armed notifications on the next reminder edit.
- **Acceptance test:** *"Hey Siri, log 20 dollars for groceries in Life Assist"* → row
  exists with the right category + spoken confirmation, **without unlocking the phone**
  (v2), or with a one-glance prefilled sheet (v1).

### Phase C — Android parity (effort S–M)

`shortcuts.xml` static shortcuts (long-press icon → Add expense / Log a step / Park an
idea) firing VIEW intents at the same scheme — the Phase A intent-filter is the only
prerequisite. Google Assistant App Actions capabilities optional afterward.

---

## 10. Sequencing

| Release | Contents | Depends on |
| --- | --- | --- |
| **v2.1** | Tier 0 (all ten) + app-store checklist items | — |
| **v2.2** | Tier 1 + capture bus (2.1) + per-id cancellation (2.2) | 0.10 CI as guardrail |
| **v2.3** | Tier 2 depth: Weekly Review, Chapters, Money/Time/Habits/Reminders depth, auto-backup, app lock, search, virtualization, engine tests | bus → notification taps; 2.2 → habit reminders |
| **v3** | Siri Phase B + C (flagship), journal | 2.1 + 2.2 + 2.8 |
| Later | Calendar, CSV (after money-precision policy), sync, AI phases | per roadmap docs |

Dependency spine: **capture bus → notification deep-links → App Intents**;
**per-id cancellation → per-habit reminders → Siri-armed reminders**.

---

## 11. Appendix — finding → evidence pointer table

| Finding | Evidence |
| --- | --- |
| POST_NOTIFICATIONS missing | `android/app/src/main/AndroidManifest.xml` (no `uses-permission` entries) |
| Completed goal vanishes | `lib/features/focus/data/focus_repository.dart:19-23`; unreachable UI `lib/features/focus/presentation/focus_screen.dart:208,464-498` |
| Score counts disabled areas | `lib/core/utils/score_utils.dart:59-95`; `lib/features/dashboard/application/dashboard_state.dart:34-42`; tiles do it right: `widgets/scoreboard_grid.dart:39,50,63` |
| Boot receiver missing | `AndroidManifest.xml` (launcher activity only) |
| Scheduling Result discarded | `lib/features/reminders/application/reminders_controller.dart:37-92` |
| Clipboard exfiltration | `lib/features/settings/presentation/settings_screen.dart:549` |
| Surplus chart flatters gaps | `lib/features/money/application/money_controller.dart:104-116` |
| Light-mode teal contrast | `up_next_card.dart:35`, `available_time_card.dart:30`, `focus_screen.dart:531` |
| CheckInStrip unguarded writes | `lib/features/dashboard/presentation/widgets/check_in_strip.dart:109-128` |
| Minute-tick fan-out | `lib/core/providers.dart:26-32` + 9 `readNow()` call sites |
| No indexes / unbounded queries | `lib/core/storage/app_database.dart` (primary keys only); `focus_repository.dart:254`; `habits_repository.dart:23` |
| Leaked family providers | `money_controller.dart:80-83`; `time_controller.dart:67-70`; `focus_controller.dart:31-34` |
| Startup writes every launch | `lib/bootstrap.dart:26-29`; `lib/core/storage/legacy_migration.dart:36-42` |
| Eager list Columns | `action_history_list.dart:91-137`; `transactions_list.dart:108`; `time_block_history_list.dart:63` |
| Income retro-applied | `money_controller.dart:88-117` |
| Streaks: no grace | `lib/features/focus/domain/daily_action.dart:24-35`; `lib/features/habits/domain/habit_log.dart:13-24` |
| 24h cap missing | `time_block_log_form.dart:268` (per-entry only); `time_repository.dart:76-89` |
| Idea bypass permanent | `lib/features/ideas/domain/parked_idea.dart:24` |
| Goal date absent from countdowns | `lib/features/time/domain/countdown.dart:26-53` |
| Paused goal silently archived | `focus_repository.dart:46-53` |
| No goal history UI | `watchAllGoals` (`focus_repository.dart:25-27`) referenced only in tests |
| Notification tap dead | `lib/core/notifications/notification_service.dart:36-49` |
| cancelAll structural blocker | `lib/core/notifications/reminder_scheduler.dart:25` |
| Cold-start capture dropout | `lib/features/dashboard/presentation/dashboard_screen.dart:116-137` |
| Money stored as double | `app_database.dart:70` and money columns throughout |
| Countdown tile overflow risk | `lib/features/time/presentation/widgets/countdown_list.dart:112-130` |
| Missing tooltips | `transactions_list.dart:241`; `budget_category_list.dart:146`; `long_term_target_card.dart:75` |
