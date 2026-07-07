# Product spec — Life Dashboard v1

## Purpose

A local-first personal life operating system for a high-novelty,
hunt-driven operator running an edtech startup (Kaizen) on top of a
6-hour/day W-2 funding base. One glance answers: *am I pointing my hours
and money at the one thing that compounds, and am I sustainable?*

Money = scoreboard. Curiosity = engine. Freedom = actual goal.

Non-goals: cloud sync, accounts, social features, gamification,
overtracking, therapy voice.

## Users

Single user (the owner). Private install via development build /
TestFlight first; App Store distribution later.

## Screens

Adaptive navigation: bottom bar on phones (Dashboard, Kaizen, Money, Time,
More), navigation rail on tablet/desktop (all nine destinations).

### 1. Dashboard

Header: "Life Dashboard" + editable philosophy line.

Cards (all live from persisted data):

- **Today's Command** — four generated directives: one Kaizen action, one
  money constraint, one recovery action, one anti-diffusion reminder.
- **Kaizen Hours This Week** — actual vs editable target (seed 42 h),
  progress bar, status green ≥ 35 / yellow 25–34.9 / red < 25.
- **Active Growth Metric** — today's value, weekly target, 7-day trend
  sparkline, buttons to add today's entry and edit the metric.
- **Daily Experiment** — logged state ("No verdict yet. One test before
  research."), verdict badge, log button, streak.
- **Monthly Surplus** — net income, month-to-date spend, projected spend,
  projected surplus, target range, status.
- **Recovery Floor** — decompress hours vs 10.5 h target; warning < 5 h,
  critical at 0. "Recovery is load-bearing."
- **Focus Integrity Score** — 0–100 ring with the five-part breakdown
  (see docs/scoring_rules.md).
- **Freedom Progress** — annual savings projection, Roth IRA progress,
  freedom target progress. "Money is the scoreboard. Freedom is the goal."

### 2. Kaizen

- Growth metrics: create/edit/delete; exactly one active at a time;
  dated entries (same-day entries replace); history list; sparkline; and a
  30/90-day metric trend line chart.
- Daily experiments: hypothesis → action → result → verdict
  (kill / confirm / iterate) + notes; edit/delete; filter by verdict;
  streak and missed-days counters.
- Fence banner: "Growth hunt first. Build hunt is fenced."

### 3. Money

- Editable net monthly income and target surplus range (seed $6,942;
  $3,200–$3,800).
- Budget categories: create/edit/delete, monthly target, flag rule
  (see scoring_rules.md). Seeded with the 12 default categories.
- Transactions: add/edit/delete, categorize, mark intentional, dated.
- Rollups: month-to-date spend, projected spend/surplus, per-category
  progress, leak flags, zero-category violations, uncategorized fog count.
- Freedom accounts: Roth IRA annual target + contributed, manual
  brokerage/savings balances.

### 4. Time

- Weekly time budgets: create/edit/delete, semantic kind, target hours.
  Seeded: Sleep 52.5, Job 30, Kaizen 42, Admin 14, Decompress 10.5,
  Meals 7, Exercise 5, Volunteering 3, Toastmasters 2, Meditation 1.5.
- Time blocks: log/edit/delete hours per category per date.
- Derived: actual vs target per category, over/under flags, remaining
  weekly hours, available time today (24 − logged today).
- Countdowns: age-28 lock-in (needs birthday; shows "Set birthday to
  activate."), end of year, end of month, Roth IRA deadline (dynamic),
  lease renewal + Kaizen milestone (fixed, editable), custom countdowns.

### 5. Habits

- Habit types: boolean, numeric, duration.
- Seeded: Weed-free, Meditation, Exercise, Sleep logged,
  Volunteering/service, Toastmasters.
- Today's checklist (tap to log/unlog; value dialog for non-boolean),
  streaks, weekly counts, editor, delete with confirmation.

### 6. Ideas (anti-diffusion)

- Capture: title, description, category, why tempting, potential value,
  "directly helps Kaizen this week" flag. Review date auto-set +7 days.
- Buckets: cooling / due for a verdict / decided.
- Decisions: undecided, ignore, later, integrate. Integrate is locked
  while cooling unless the idea directly helps Kaizen this week.

### 7. Identity

- Fixed triad + editable philosophy line.
- Operating identity statements (seeded: builder/operator; Kaizen is the
  main hunt; W-2 is the funding base; flipping is winding down; freedom is
  the goal) — add/edit/delete.
- Goals with metric, current/target values, target date, progress bars.
- Freedom target: monthly passive income + liquid net worth, current vs
  target, progress.

### 8. Reminders

- Daily local notifications; master enable with OS permission request and
  graceful denial handling; unsupported on web (explained in-app).
- Seeded: Morning command 8:00, Kaizen experiment 12:00, Money check
  18:00, Night review 22:00. All editable/deletable; custom reminders.
- Messages come from the stored text; empty message falls back to a
  rotating template per type.

### 9. Settings

Income, surplus range, birthday, philosophy text, theme
(system/dark/light), links to budget/time targets and reminders, JSON
export (clipboard + file), JSON import (replace-all with confirmation),
full reset (wipe + re-seed) with confirmation.

### Onboarding

First launch only. Steps: intro → money numbers → Kaizen target + active
metric → birthday/reminder times/notifications. Skippable at any point;
defaults are already seeded. Writes answers into the seeded records.

## Data

See docs/data_model.md. All core data in SQLite via drift; SharedPreferences
holds only onboarding-complete, theme mode, and the notifications toggle.

## Quality bar

- No fake data after seed; every displayed number derives from the DB.
- Form validation on all inputs; confirmation dialogs on all deletes and
  destructive actions; snackbars for success/failure.
- `flutter analyze` clean; `flutter test` green.
