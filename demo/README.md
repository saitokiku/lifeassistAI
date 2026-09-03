# Demo data

`life_assist_demo.json` is a full **Life Assist** backup for a fictional
customer. Import it and the app looks like someone has been living in it
for five months: a main goal with milestones, four accounts with balance
history, a hundred-odd transactions, weeks of logged time and habits, a
journal, parked ideas, and a small linked notebook.

It is a normal export — the same envelope and row shapes
`BackupService.exportJson()` writes — so it also serves as the fixture
for the import/export tests (`test/demo_backup_test.dart`).

## Use it

**In the app:** You → Settings → *Import backup*, pick the file.

Import **replaces everything** in the app's database. Export your own
data first if the device holds anything you want to keep — the app
refuses an import that carries no records, but it will happily replace
real data with demo data.

Then take the tour:

| Tab | What to point at |
| --- | --- |
| **Today** | Score ring, "Up next" (today's step isn't logged yet — tap it), the week's numbers, one-tap habit check-ins |
| **Focus** | The main goal and its why, six milestones (three done), the payoff measure with its trend, ~35 daily steps with honest worked / adjust / didn't-work reviews |
| **Money** | Projected surplus vs. the $700–$1,200 target, nine budget categories, recurring expenses landing as real transactions, four accounts with net-worth history, one uncategorized charge waiting to be filed |
| **Time** | Six weekly budgets against ~6 weeks of logged hours, the goal-vs-everything-else chart, four countdowns |
| **You** | Five operating principles, five habits with streaks, seven parked ideas at different stages of cooling, 15 journal lines, ten cross-linked notes with tags, backlinks and a graph |

Search (in **You**) covers all of it — try "card", "rent", or "sleep".

## Regenerate it before a demo

The file is dated. `scripts/generate_demo_data.py` builds every date
relative to an anchor day, so re-running it rolls the whole history
forward — this month keeps its transactions, streaks stay warm,
countdowns still count.

```bash
python3 scripts/generate_demo_data.py                  # anchored to today
python3 scripts/generate_demo_data.py --now 2026-12-24 # anchored elsewhere
python3 scripts/generate_demo_data.py --out /tmp/x.json
```

Output is deterministic for a given anchor: ids are UUIDv5 of stable
labels and every random choice is seeded, so regenerating on the same
day rewrites the identical file.

**Anchor after the 12th of the month if you can.** The Money screen
projects the month's spend in a straight line from what has been spent
so far, and rent lands on the 1st. Between roughly the 4th and the 12th
that projection reads as an overspend and the app shows a critical money
flag — true of any real user with rent and a straight-line projection,
but not what you want on screen during a demo. (Days 1–3 are fine: the
app deliberately blends the projection there.) A late-month anchor also
gives the current month a full set of transactions to show.

## The persona

Jordan, 31, take-home $4,250/month, five months into one goal: clear a
credit card and build a three-month cushion. The card is down from
$6,810 to $3,118; savings are up from $1,200 to $3,420.

Nothing is perfect, on purpose — a demo where every habit is checked and
every category is under target reads as fake. So: gaps in the habit
logs, a couple of missed daily steps, eating out running over target,
one uncategorized transaction, an idea that got killed after a week of
cooling, and a week in the journal that just says it was rough.

The numbers are internally consistent: account balances match the
snapshot history, transactions reference real categories and accounts,
recurring expenses carry the `sourceRecurringId` that materialized them,
and every amount is integer cents.

## What is *not* in the file

- **Onboarding state, theme, app lock, currency symbol.** Device-local
  preferences, not user data — they don't travel in a backup. On a fresh
  install, walk through onboarding first (skip what it offers to skip),
  then import.
- **Note links and tags.** A derived index; the app rebuilds both from
  the note text as part of the import.
- **iOS extras.** Widgets, Siri captures, Live Activity, and Apple
  Health auto-checks read live device state, not the backup.
