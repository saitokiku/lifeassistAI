# Data model

SQLite via drift. Schema in `lib/core/storage/app_database.dart`
(**schemaVersion 7** — this document describes the v2 shape and has not
been updated since; read the table definitions in the source for the
current truth, including integer-cents money (v4), Health mappings (v5),
notes (v6), and the unique day-key indexes plus stored notification ids
(v7)). IDs are UUIDv4 strings. Calendar days are stored as
`yyyy-MM-dd` text keys (timezone-safe day math); timestamps are DateTime
columns. Weeks start Monday.

**Schema v2** introduced the universal main-goal system: the `main_goals`
table, milestone columns on `goals`, and value rewrites for legacy enums
(`kaizen` time kind → `goal`, `kaizenExperiment` reminder type →
`dailyAction`). `LegacyMigration` (in `lib/core/storage/`) performs the
rewrites and derives the original owner's "Kaizen" goal from pre-v2 data;
it also runs after backup imports so v1 envelopes stay importable. A few
stored names intentionally keep their v1 spelling for compatibility —
they are noted below.

## Tables

### main_goals → `MainGoal`
| Column | Type | Notes |
| --- | --- | --- |
| id | text PK | |
| title | text | the user's goal, in their words |
| why | text | optional motivation, defaults '' |
| targetDate | text? | day key |
| status | text | `active\|paused\|completed\|archived` — one non-archived, non-completed goal at a time (enforced in repository) |
| createdAt / updatedAt / completedAt? | datetime | |

### goals → `Goal` (milestones)
Milestones under the main goal. The table name predates v2, when these
were free-standing "goals".
id, title, description?, metricName?, currentValue, targetValue
(`> 0` = measurable milestone), targetDate? (day key), **isDone**,
**sortOrder**, createdAt, updatedAt

### growth_metrics → `GrowthMetric` (progress measures)
| Column | Type | Notes |
| --- | --- | --- |
| id | text PK | |
| name | text | |
| unit | text | pages, lbs, $, signups... |
| currentValue | real | auto-refreshed to the latest entry's value |
| weeklyTarget | real | |
| isActive | bool | at most one measure tracked (enforced in repository) |
| createdAt / updatedAt | datetime | |

### growth_metric_entries → `GrowthMetricEntry`
id, metricId, date (day key, unique per metric via upsert), value, note?

### daily_experiments → `DailyExperiment` (daily steps)
One small step toward the goal per day. Table and verdict values keep
their v1 names; the UI reads them as steps with worked/adjust/didn't-work
outcomes (`ActionVerdict` maps `confirm|iterate|kill`).
id, date (day key), hypothesis (optional in UI), actionTaken, result,
verdict (`kill|confirm|iterate`), notes?, createdAt, updatedAt

### budget_categories → `BudgetCategory`
id, name, monthlyTarget, flagType
(`none|warnOverTarget|warnOverZero|warnOverZeroUnlessIntentional|criticalOverZero`),
sortOrder, createdAt, updatedAt

### transaction_entries → `TransactionEntry`
id, categoryId? (null = uncategorized; category deletion detaches),
date (day key), amount, description, isIntentional, createdAt

### time_budgets → `TimeBudget`
id, name, kind (`sleep|job|goal|admin|decompress|meals|exercise|volunteering|meditation|other`),
weeklyTargetHours, sortOrder. The kind drives scoring; names are free.
Legacy rows may still carry `kaizen`/`toastmasters` —
`TimeCategoryKind.parse` maps them.

### time_blocks → `TimeBlock`
id, budgetId (cascade-deleted with its budget), date (day key), hours, note?, createdAt

### countdowns → `Countdown`
id, title, targetDate? (day key), dynamicKey?
(`endOfYear|endOfMonth` seeded; `age28|rothIraDeadline` legacy but still
computed at read time), sortOrder

### habits → `Habit`
id, name, type (`boolean|numeric|duration`), unit?, sortOrder, isArchived, createdAt

### habit_logs → `HabitLog`
id, habitId, date (day key, unique per habit via upsert), value
(boolean stores 1), note?

### parked_ideas → `ParkedIdea`
id, title, description?, category?, whyTempting?, potentialValue?,
dateCaptured (day key), reviewDate (captured + 7 days),
decision (`undecided|ignore|later|integrate`),
helpsMainGoal (SQL column keeps its v1 name
`directly_helps_kaizen_this_week`), createdAt, updatedAt

### freedom_targets → `FreedomTarget` (long-term target)
Shown on Money as "Long-term target".
id, title, description?, targetMonthlyPassiveIncome, targetLiquidNetWorth,
currentMonthlyPassiveIncome, currentLiquidNetWorth, targetDate?, createdAt, updatedAt

### reminders → `Reminder`
id, title, message, type
(`morningCommand|dailyAction|moneyCheck|nightReview|custom`; legacy
`kaizenExperiment` is rewritten to `dailyAction`),
hour, minute, enabled, notificationId (stable int for the OS scheduler),
createdAt, updatedAt

### identity_statements → `IdentityStatement`
id, content, sortOrder

### settings_entries → `SettingsEntry`
Key-value store for core values so they export/import with everything
else: displayName, monthlyNetIncome, targetSurplusLow/High, birthday,
retirement target/contributed (stored keys keep the legacy names
`rothIraAnnualTarget`/`rothIraContributed`), brokerageBalance,
savingsBalance, philosophyText, dashboardAreas (comma list of Today
modules; absent = all, `none` = none). Typed access via
`SettingsRepository`.

## SharedPreferences (device-local only)

onboardingComplete, themeMode (`system|dark|light`), notificationsEnabled.
Deliberately excluded from export — they are app flags, not user data.

## Derived models (not persisted)

- `MonthlyMoneySnapshot` / `CategorySpend` / `MoneyFlag` — month rollup.
- `TimeState` / `WeeklyTimeBudgetProgress` / `ResolvedCountdown`.
- `FocusState`, `HabitsState`/`HabitView`, `IdeasState`,
  `DashboardState`/`UpNextKind`, `FocusScoreBreakdown`.

## Export format

```json
{
  "app": "Life Assist",
  "schemaVersion": "2",
  "exportedAt": "ISO-8601",
  "data": { "settings": [...], "mainGoals": [...], ",,,": "all 17 tables" }
}
```

Import replaces all tables inside a single transaction; malformed input
rolls back and leaves existing data untouched. v1 envelopes (no
`mainGoals`, old JSON field names, legacy enum values) are normalized on
import and then run through `LegacyMigration`. Backups from a newer
schema than the app understands are refused with a clear message.
