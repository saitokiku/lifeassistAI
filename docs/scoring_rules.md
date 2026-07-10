# Scoring rules

> **Historical (v1).** This document describes the original
> single-owner build. The v2 revamp made the product universal —
> see `README.md`, `docs/data_model.md`, and `docs/roadmap.md`
> for current behavior.

All formulas are implemented in `lib/core/utils/score_utils.dart` and
`lib/core/utils/money_math.dart`, and unit-tested in `test/`.

## Focus Integrity Score (0–100)

| Component | Points | Rule |
| --- | --- | --- |
| Kaizen work progress | up to 35 | `min(kaizenHoursThisWeek / kaizenWeeklyTarget, 1.0) * 35` (target defaults to 42) |
| Daily experiment | 20 | 20 if today's experiment is logged, else 0 |
| Spending pace | up to 15 | 15 if `projectedSurplus >= targetSurplusLow`, else `max(projectedSurplus / targetSurplusLow, 0) * 15` |
| Exercise/meditation today | 15 | 15 if an exercise or meditation habit is logged today **or** exercise/meditation time blocks exist today |
| Recovery protected | 15 | 15 if recovery ≥ 5 h this week; 7 if > 0 h; 0 at zero |

Total is rounded and clamped to 0–100.

Status bands:

| Score | Status |
| --- | --- |
| 80–100 | Aligned |
| 60–79 | Acceptable |
| 40–59 | Drifting |
| 0–39 | Correction needed |

## Kaizen hours status (weekly)

| Hours | Status |
| --- | --- |
| ≥ 35 | Aligned (green) |
| 25–34.9 | Watch (yellow) |
| < 25 | Drifting (red) |

## Recovery status (weekly decompress hours)

| Hours | Status |
| --- | --- |
| 0 | Critical — "Recovery floor cannot hit zero." |
| < 5 | Warning |
| ≥ 5 | Aligned (target 10.5) |

## Money projections

```
projectedSpend   = spendSoFarThisMonth / dayOfMonth * daysInMonth
                   (guard: if dayOfMonth or daysInMonth <= 0, return spendSoFar)
projectedSurplus = monthlyNetIncome - projectedSpend
annualSavings    = projectedSurplus * 12
```

Surplus status: negative → **critical**; below target-low → **watch**;
otherwise **aligned**.

## Money flag rules

Each budget category stores a flag rule (user-editable data, not code):

| Rule | Behavior | Seeded on |
| --- | --- | --- |
| `warnOverTarget` | warning when month-to-date spend > monthly target | Housing, Food, Car, Amazon ($258), Misc ($300), Subscriptions ($60), Fitness, Charity |
| `criticalOverZero` | critical when spend > $0 | Weed, Poker |
| `warnOverZero` | warning when spend > $0 | Travel |
| `warnOverZeroUnlessIntentional` | warning when spend > $0 unless every transaction is marked intentional | Restaurants/desserts |
| `none` | never flags | — |

Plus: any uncategorized transactions this month produce a warning
("Undefined misc is fog. Categorize it."), and the surplus rules above.

## Time budget math

```
progress  = actualThisWeek / targetThisWeek   (uncapped; >1 shows "over")
remaining = targetThisWeek - actualThisWeek
availableToday = 24 - hoursLoggedToday
```

Weeks start Monday. Kaizen hours and the recovery floor are derived from
the semantic *kind* of each time category (kaizen / decompress /
exercise / meditation ...), so renaming categories never breaks scoring.

## Idea cooling rule

`reviewDate = dateCaptured + 7 days`. An idea can be activated
(decision = integrate) only if it directly helps Kaizen this week **or**
today ≥ reviewDate. Everything else waits. Curiosity captured, not chased.

## Streaks

Experiment and habit streaks count consecutive logged days ending today;
if today isn't logged yet, the streak counts up to yesterday (an open day
doesn't break it). Missed days = unlogged days in the last 30.
