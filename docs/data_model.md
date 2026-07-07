# Data model

SQLite via drift. Schema in `lib/core/storage/app_database.dart`
(schemaVersion 1). IDs are UUIDv4 strings. Calendar days are stored as
`yyyy-MM-dd` text keys (timezone-safe day math); timestamps are DateTime
columns. Weeks start Monday.

## Tables

### growth_metrics → `GrowthMetric`
| Column | Type | Notes |
| --- | --- | --- |
| id | text PK | |
| name | text | |
| unit | text | users, $, signups... |
| currentValue | real | auto-refreshed to the latest entry's value |
| weeklyTarget | real | |
| isActive | bool | exactly one metric active (enforced in repository) |
| createdAt / updatedAt | datetime | |

### growth_metric_entries → `GrowthMetricEntry`
id, metricId, date (day key, unique per metric via upsert), value, note?

### daily_experiments → `DailyExperiment`
id, date (day key), hypothesis, actionTaken, result,
verdict (`kill|confirm|iterate`), notes?, createdAt, updatedAt

### budget_categories → `BudgetCategory`
id, name, monthlyTarget, flagType
(`none|warnOverTarget|warnOverZero|warnOverZeroUnlessIntentional|criticalOverZero`),
sortOrder, createdAt, updatedAt

### transaction_entries → `TransactionEntry`
id, categoryId? (null = uncategorized fog; category deletion detaches),
date (day key), amount, description, isIntentional, createdAt

### time_budgets → `TimeBudget`
id, name, kind (`sleep|job|kaizen|admin|decompress|meals|exercise|volunteering|toastmasters|meditation|other`),
weeklyTargetHours, sortOrder. The kind drives scoring; names are free.

### time_blocks → `TimeBlock`
id, budgetId (cascade-deleted with its budget), date (day key), hours, note?, createdAt

### countdowns → `Countdown`
id, title, targetDate? (day key), dynamicKey?
(`age28|endOfYear|endOfMonth|rothIraDeadline` — computed at read time), sortOrder

### habits → `Habit`
id, name, type (`boolean|numeric|duration`), unit?, sortOrder, isArchived, createdAt

### habit_logs → `HabitLog`
id, habitId, date (day key, unique per habit via upsert), value
(boolean stores 1), note?

### parked_ideas → `ParkedIdea`
id, title, description?, category?, whyTempting?, potentialValue?,
dateCaptured (day key), reviewDate (captured + 7 days),
decision (`undecided|ignore|later|integrate`),
directlyHelpsKaizenThisWeek, createdAt, updatedAt

### goals → `Goal`
id, title, description?, metricName?, currentValue, targetValue,
targetDate? (day key), createdAt, updatedAt

### freedom_targets → `FreedomTarget`
id, title, description?, targetMonthlyPassiveIncome, targetLiquidNetWorth,
currentMonthlyPassiveIncome, currentLiquidNetWorth, targetDate?, createdAt, updatedAt

### reminders → `Reminder`
id, title, message, type
(`morningCommand|kaizenExperiment|moneyCheck|nightReview|custom`),
hour, minute, enabled, notificationId (stable int for the OS scheduler),
createdAt, updatedAt

### identity_statements → `IdentityStatement`
id, content, sortOrder

### settings_entries → `SettingsEntry`
Key-value store for core numbers so they export/import with everything
else: monthlyNetIncome, targetSurplusLow/High, birthday, rothIraAnnualTarget,
rothIraContributed, brokerageBalance, savingsBalance, philosophyText.
Typed access via `SettingsRepository`.

## SharedPreferences (device-local only)

onboardingComplete, themeMode (`system|dark|light`), notificationsEnabled.
Deliberately excluded from export — they are app flags, not user data.

## Derived models (not persisted)

- `MonthlyMoneySnapshot` / `CategorySpend` / `MoneyFlag` — month rollup.
- `TimeState` / `WeeklyTimeBudgetProgress` / `ResolvedCountdown`.
- `KaizenState`, `HabitsState`/`HabitView`, `IdeasState`,
  `DashboardState`/`TodayCommand`, `FocusScoreBreakdown`.

## Export format

```json
{
  "app": "Life Dashboard",
  "schemaVersion": "1",
  "exportedAt": "ISO-8601",
  "data": { "settings": [...], "growthMetrics": [...], ",,,": "all 16 tables" }
}
```

Import replaces all tables inside a single transaction; malformed input
rolls back and leaves existing data untouched.
