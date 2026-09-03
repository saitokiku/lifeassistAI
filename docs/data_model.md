# Data model

SQLite via drift. The schema lives in `lib/core/storage/app_database.dart`
(**schemaVersion 7**); this document describes it in prose. IDs are
UUIDv4 strings. Calendar days are stored as `yyyy-MM-dd` text keys so day
math is timezone-safe; timestamps are DateTime columns. Weeks start
Monday. **Money is integer cents everywhere** — doubles appear only at
the edges, for input and display.

Migrations are automatic and tested (`test/schema_upgrade_test.dart`,
`test/money_migration_test.dart`):

| Version | Change |
| --- | --- |
| v2 | The universal main-goal system: `main_goals`, milestone columns on `goals`, legacy enum rewrites (`kaizen` time kind → `goal`, `kaizenExperiment` reminder type → `dailyAction`). |
| v3 | Accounts, balance history, recurring expenses, weekly reviews, weekday schedules. |
| v4 | Money becomes integer cents; the journal arrives. |
| v5 | Apple Health habit mappings and a source tag on every habit log. |
| v6 | Notes plus their derived link/tag index. |
| v7 | UNIQUE constraints behind the three "one row per day" invariants, and stored (not derived) notification ids. |

`LegacyMigration` performs the value-level rewrites and derives a main
goal from pre-v2 data. It also runs after every backup import, so old
export envelopes stay importable. A few stored names deliberately keep
their pre-v2 spelling for data compatibility; those are noted below.

## Focus

### main_goals → `MainGoal`
| Column | Type | Notes |
| --- | --- | --- |
| id | text PK | |
| title | text | the user's goal, in their words |
| why | text | optional motivation, defaults `''` |
| targetDate | text? | day key |
| status | text | `active\|paused\|completed\|archived` — one open goal at a time (enforced in the repository) |
| createdAt / updatedAt / completedAt? | datetime | |

### goals → `Goal` (milestones)
Milestones under the main goal. The table name predates v2, when these
were free-standing "goals".
`id, title, description?, metricName?, currentValue, targetValue`
(`> 0` = measurable milestone), `targetDate?`, `isDone`, `sortOrder`,
`createdAt`, `updatedAt`.

### growth_metrics → `GrowthMetric` (progress measures)
`id, name, unit` (pages, lbs, $, signups…), `currentValue`
(auto-refreshed to the latest entry's value), `weeklyTarget`, `isActive`
(at most one active measure), `createdAt`, `updatedAt`.

### growth_metric_entries → `GrowthMetricEntry`
`id, metricId, date, value, note?` — UNIQUE on `(metricId, date)`.

### daily_experiments → `DailyExperiment` (daily steps)
One small step toward the goal per day. The table and its verdict values
keep their pre-v2 names; the UI reads them as steps with
worked / adjust / didn't-work outcomes (`ActionVerdict` maps
`confirm | iterate | kill`).
`id, date, hypothesis, actionTaken, result, verdict, notes?, createdAt,
updatedAt`.

### weekly_reviews → `WeeklyReview`
`id, weekStart` (Monday day key), `reflection, emphasis, createdAt`.

## Money

### budget_categories → `BudgetCategory`
`id, name, monthlyTargetCents, flagType`
(`none | warnOverTarget | warnOverZero | warnOverZeroUnlessIntentional |
criticalOverZero`), `sortOrder, createdAt, updatedAt`.

### transaction_entries → `TransactionEntry`
`id, categoryId?` (null = uncategorized; deleting a category detaches
rather than deletes), `accountId?`, `sourceRecurringId?` (set when
materialized from a recurring expense — idempotence plus a trace),
`date, amountCents, description, isIntentional, createdAt`.

### recurring_transactions → `RecurringTransaction`
Monthly fixed costs, materialized into real transactions once per month.
`id, categoryId?, amountCents, description, dayOfMonth` (1–31, clamped to
the month's last day), `isIntentional, active, lastMaterializedMonth`
(`yyyy-MM`, the idempotence key), `createdAt`.

### accounts → `Account`
`id, name, kind` (`checking | savings | credit | investment | cash |
other`), `balanceCents, includeInNetWorth` (credit balances count
negative), `sortOrder, createdAt, updatedAt`.

### balance_snapshots → `BalanceSnapshot`
Dated balance history behind the net-worth trend.
`id, accountId, date, balanceCents` — UNIQUE on `(accountId, date)`.

### freedom_targets → `FreedomTarget` (long-term target)
`id, title, description?, targetMonthlyPassiveIncome,
targetLiquidNetWorth, currentMonthlyPassiveIncome, currentLiquidNetWorth,
targetDate?, createdAt, updatedAt`.

## Time

### time_budgets → `TimeBudget`
`id, name, kind` (`sleep | job | goal | admin | decompress | meals |
exercise | volunteering | meditation | other`), `weeklyTargetHours,
sortOrder`. The kind drives scoring; names are free text, so renaming a
category never breaks the score. Legacy rows may still carry
`kaizen`/`toastmasters` — `TimeCategoryKind.parse` maps them.

### time_blocks → `TimeBlock`
`id, budgetId` (cascade-deleted with its budget), `date, hours, note?,
createdAt`.

### countdowns → `Countdown`
`id, title, targetDate?, dynamicKey?, sortOrder`. Dynamic countdowns
compute their target at read time: `endOfYear`/`endOfMonth` are seeded,
`age28`/`rothIraDeadline` are legacy but still resolve.

## Habits, ideas, notes, and the rest

### habits → `Habit`
| Column | Notes |
| --- | --- |
| id, name, type | `boolean \| numeric \| duration` |
| unit? | for numeric and duration habits |
| weekdays | bitmask, bit 0 = Monday; 127 = every day. Streaks and "due today" respect it |
| reminderHour?, reminderMinute? | both null = no reminder |
| notificationId | stable OS id, stored rather than derived |
| healthMetric?, healthTarget? | Apple Health auto-check mapping (`steps \| sleepHours \| mindfulMinutes \| workoutMinutes`) |
| sortOrder, isArchived, createdAt | |

### habit_logs → `HabitLog`
`id, habitId, date, value` (boolean habits store 1), `note?, source`
(`manual | siri | health` — manual always wins; the Health sync never
overwrites a log a person created). UNIQUE on `(habitId, date)`.

### parked_ideas → `ParkedIdea`
`id, title, description?, category?, whyTempting?, potentialValue?,
dateCaptured, reviewDate` (captured + 7 days), `decision`
(`undecided | ignore | later | integrate`), `helpsMainGoal` (the SQL
column keeps its pre-v2 name `directly_helps_kaizen_this_week`),
`createdAt, updatedAt`.

### journal_entries → `JournalEntry`
`id, date, content, createdAt, updatedAt`. Several entries per day are
fine — capture should cost seconds, not a blank-page ritual.

### notes → `Note`
`id, zettelId` (a `yyyyMMddHHmmss` key used as a stable link target and
the exported Obsidian filename base), `title, content, isArchived,
createdAt, updatedAt`.

### note_links → `NoteLink` · note_tags → `NoteTag`
A derived index, recomputed from note text on every save and rebuilt
after every import — never exported.
`NoteLink`: `id, sourceId, targetTitle, targetId?` (null = an unresolved
"ghost" target, drawn faded in the graph). Backlinks for a note are the
rows where `targetId` is that note.
`NoteTag`: `id, noteId, tag`.

### identity_statements → `IdentityStatement`
`id, content, sortOrder`.

### reminders → `Reminder`
`id, title, message, type`
(`morningCommand | dailyAction | moneyCheck | nightReview | custom`;
legacy `kaizenExperiment` is rewritten to `dailyAction`), `hour, minute,
weekdays` (bitmask as above), `oneShotDate?` (fires once, then disables),
`enabled, notificationId, createdAt, updatedAt`.

### settings_entries → `SettingsEntry`
A key-value store for the values that must travel with a backup:
`displayName`, `monthlyNetIncome`, `targetSurplusLow`/`High`, `birthday`,
retirement target and contributions (keys keep the legacy names
`rothIraAnnualTarget`/`rothIraContributed`), `brokerageBalance`,
`savingsBalance` (frozen pre-v3 values; real balances live in
`accounts`), `philosophyText`, `dashboardAreas` (comma list of Today
modules; absent = all, `none` = none), `lastBackupAt`, and one
`incomeFor.<yyyy-MM>` snapshot per month so surplus history reads the
income that actually applied to each month. Typed access through
`SettingsRepository`.

## SharedPreferences (device-local only)

Onboarding state, theme mode, the notification toggle, app lock, the
currency symbol, live-vault mirroring, the running timer's budget and
start time, and a few one-time flags (seed revision, notification-id
scheme, discovery card dismissal, the day reminders were last armed).

Deliberately excluded from export: these are app flags, not user data.

## Derived models (not persisted)

- `MonthlyMoneySnapshot` / `CategorySpend` / `MoneyFlag` — the month rollup.
- `TimeState` / `WeeklyTimeBudgetProgress` / `ResolvedCountdown`.
- `FocusState`, `HabitsState` / `HabitView`, `IdeasState`,
  `DashboardState` / `UpNextKind`, `FocusScoreBreakdown`.

## Export format

```json
{
  "app": "Life Assist",
  "schemaVersion": "7",
  "exportedAt": "ISO-8601",
  "data": { "settings": [...], "mainGoals": [...], "…": "23 tables" }
}
```

Import replaces every table inside a single transaction. It refuses
anything that isn't one of this app's own exports, anything carrying zero
records (an import must never erase more than it restores), and anything
stamped with a schema newer than the app understands. Malformed input
rolls back and leaves existing data untouched. Older envelopes — pre-v2
field names, dollar doubles instead of cents, missing columns — are
normalized on the way in and then run through `LegacyMigration`. The note
link/tag index is rebuilt from the restored note text.

`demo/life_assist_demo.json` is a complete worked example.
