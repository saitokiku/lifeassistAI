# Scoring rules

Every formula below is implemented in `lib/core/utils/score_utils.dart`
and `lib/core/utils/money_math.dart`, and unit-tested in
`test/score_utils_test.dart`, `test/money_rules_test.dart` and
`test/streak_math_test.dart`. If a number appears on a screen, it came
from one of these.

## Day score (0–100)

Shown on Today as a ring. Five components:

| Component | Points | Rule |
| --- | --- | --- |
| Goal hours | up to 35 | `min(goalHoursThisWeek / (weeklyTarget × weekElapsed), 1) × 35` |
| Today's step | 20 | 20 when today's daily step is logged, else 0 |
| Spending pace | up to 15 | 15 when `projectedSurplus ≥ targetSurplusLow`; otherwise `max(projectedSurplus / targetSurplusLow, 0) × 15` |
| Movement today | 15 | 15 when an exercise or meditation habit is logged today, or an exercise/meditation time block exists today |
| Recovery | up to 15 | `min(recoveryHoursThisWeek / (5 × weekElapsed), 1) × 15` |

Two things keep this honest:

**Weekly components are paced, not totalled.** `weekElapsed` is the
fraction of the week that has happened (Monday = 1/7, Sunday = 7/7).
Without it, identical behaviour would read 50/100 on Monday morning and
100/100 on Sunday night purely because more week had elapsed.

**Hidden areas cost nothing.** The Today screen's area toggles (Money,
Time, Habits) drop their component from the score *and* from the
denominator, so 100 stays reachable whatever is turned off. The money
component is also dropped when no income has been entered — there is no
money signal to score, and awarding the points anyway would hand new
users free credit the rest of the app doesn't believe in.

Where no goal target is configured, the score falls back to 10 hours a
week. The total is rounded and clamped to 0–100.

| Score | Label |
| --- | --- |
| 80–100 | On track |
| 60–79 | Steady |
| 40–59 | Slipping |
| 0–39 | Needs attention |

The ring never turns red: a quiet morning is not an emergency. Red is
reserved for genuinely critical signals, which in practice means money.

## Status bands elsewhere

**Goal hours (weekly)** — ratios, not absolutes, so the reading is fair
for a 5-hour week and a 40-hour week alike: ≥ 80% of target is *On
track*, ≥ 50% is *Behind*, below that is *Far behind*. No target set
reads as neutral.

**Recovery (weekly downtime hours)** — 0 hours is critical ("At zero"),
under 5 is *Thin*, 5 or more is *Protected*.

**Surplus** — negative is critical ("Overspent"), below your low target
is *Under target*, at or above it is *On track*.

## Money projections

```
projectedSpend   = spendSoFarThisMonth / dayOfMonth × daysInMonth
projectedSurplus = monthlyNetIncome − projectedSpend
annualSavings    = projectedSurplus × 12
```

Before day 4 the straight-line projection is blended toward what has
actually been spent, weighted by how much of the month has elapsed.
Rent lands on the 1st, and `spend / 1 × 31` turns a single $1,500 charge
into $46,500 of "projected" spending — which used to fire a critical
alert and hijack the Today screen for the first days of every month.
`MoneyMath.projectionIsMeaningful(dayOfMonth)` tells callers whether the
number can be trusted yet.

All spend sums are computed in integer cents, so a category can never be
flagged as over target by a floating-point artifact.

## Money flag rules

Each budget category stores its own flag rule — user-editable data, not
code. Categories are seeded with no rule; you choose one per category in
the editor.

| Rule | Behaviour |
| --- | --- |
| `warnOverTarget` | warning when month-to-date spend exceeds the monthly target |
| `warnOverZero` | warning on any spend at all |
| `warnOverZeroUnlessIntentional` | warning on any spend unless every transaction in the category is marked intentional |
| `criticalOverZero` | critical on any spend at all |
| `none` | never flags |

Two flags come from outside the categories: the surplus rules above, and
one warning per month for transactions left uncategorized — patterns
hide there.

## Time budget math

```
progress       = actualThisWeek / targetThisWeek   (uncapped; > 1 shows "over")
remaining      = targetThisWeek − actualThisWeek
availableToday = 24 − hoursLoggedToday             (clamped to 0–24)
```

Weeks start Monday. Goal hours and recovery hours are derived from the
semantic *kind* of each time category (`goal`, `decompress`,
`exercise`, `meditation`, …), so renaming a category never breaks
scoring.

## Streaks

A streak counts consecutive **scheduled** days logged, ending today or
the most recent scheduled day. Three rules keep the number both honest
and humane:

- Days outside a habit's weekday schedule are skipped entirely — a
  Mon/Wed/Fri habit is not broken by a Tuesday.
- Today being unlogged does not break anything. The day is still open.
- One missed scheduled day per calendar week is forgiven. It does not
  add to the count; it just does not zero it. Grace bridges a run, it
  never mints one from nothing — a dead tail still ends at 0.

## Idea cooling

`reviewDate = dateCaptured + 7 days`. A parked idea can be activated
only once today has reached its review date, or if it directly helps the
main goal right now. Everything else waits. Most ideas lose their shine
in a week; the good ones survive it.
