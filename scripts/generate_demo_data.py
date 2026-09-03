#!/usr/bin/env python3
"""Builds the demo backup file — a fictional customer's Life Assist data.

The output is a normal `Life Assist` JSON export: the same envelope
(`app` / `schemaVersion` / `exportedAt` / `data`) and the same per-table
row shapes `BackupService.exportJson()` writes, so Settings -> Import
restores it like any real backup.

Why a generator instead of a checked-in-and-forgotten file: a demo has
to look *current*. Every date here is relative to "now", so re-running
this before a demo moves the whole history forward — this month keeps
its transactions, the streaks stay warm, the countdowns still count.

    python3 scripts/generate_demo_data.py     # -> demo/life_assist_demo.json
    python3 scripts/generate_demo_data.py --now 2026-12-24
    python3 scripts/generate_demo_data.py --out /tmp/other.json

Output is deterministic for a given `--now`: ids are UUIDv5 of stable
labels and every random choice comes from a seeded generator, so
regenerating on the same day produces a byte-identical file.

The persona: Jordan, ~31, take-home $4,250/mo, seven months into paying
off a credit card and building a cushion. Ordinary numbers, ordinary
slip-ups — one category over target this month, a few missed habit
days — because a demo where everything is perfect reads as fake.
"""

from __future__ import annotations

import argparse
import json
import random
import uuid
from datetime import date, datetime, timedelta
from pathlib import Path

# The envelope the importer checks (BackupService / AppConstants).
APP_NAME = 'Life Assist'
SCHEMA_VERSION = '7'

# Stable id namespace so regenerating never reshuffles ids.
NS = uuid.uuid5(uuid.NAMESPACE_URL, 'https://lifeassist.app/demo')

# Notification ids are block-aligned: base = slot * 8, slot 0 reserved.
SLOT_SIZE = 8

DAY = 'yyyy-MM-dd'  # documentation only; see day_key()


def uid(label: str) -> str:
    """Deterministic id for a logical row."""
    return str(uuid.uuid5(NS, label))


def day_key(d: date) -> str:
    return d.isoformat()


def month_key(d: date) -> str:
    return f'{d.year:04d}-{d.month:02d}'


def stamp(d: date, hour: int = 9, minute: int = 0) -> str:
    """A DateTime column value. Drift parses ISO strings on import."""
    return datetime(d.year, d.month, d.day, hour, minute).strftime(
        '%Y-%m-%dT%H:%M:%S.000'
    )


def cents(dollars: float) -> int:
    return int(round(dollars * 100))


def monday_of(d: date) -> date:
    return d - timedelta(days=d.weekday())


def month_start(d: date) -> date:
    return d.replace(day=1)


def add_months(d: date, months: int) -> date:
    month = d.month - 1 + months
    year = d.year + month // 12
    month = month % 12 + 1
    day = min(d.day, days_in_month(year, month))
    return date(year, month, day)


def days_in_month(year: int, month: int) -> int:
    if month == 12:
        return 31
    return (date(year, month + 1, 1) - timedelta(days=1)).day


class Builder:
    """Accumulates rows table by table, then writes the export envelope."""

    def __init__(self, today: date) -> None:
        self.today = today
        self.rng = random.Random(f'life-assist-demo:{today.isoformat()}')
        self.data: dict[str, list[dict]] = {}
        self._slot = 1

    # -- infrastructure ----------------------------------------------------

    def add(self, table: str, row: dict) -> dict:
        self.data.setdefault(table, []).append(row)
        return row

    def notification_id(self) -> int:
        """One aligned block of 8, the way NotificationIds allocates."""
        base = self._slot * SLOT_SIZE
        self._slot += 1
        return base

    def envelope(self) -> dict:
        return {
            'app': APP_NAME,
            'schemaVersion': SCHEMA_VERSION,
            'exportedAt': stamp(self.today, 7, 42),
            'data': self.data,
        }

    # -- settings ----------------------------------------------------------

    MONTHLY_INCOME = 4250.0
    BIRTHDAY = date(1994, 7, 19)

    # The card's opening balance when the goal started; today's balance is in
    # ACCOUNTS, and the difference is what the progress measure has to add
    # up to. Keeping one number here keeps that story consistent.
    CARD_OPENING_BALANCE = 6810.00

    # Months of account balance history, and so the age of the money goal.
    BALANCE_HISTORY_MONTHS = 8

    def build_settings(self) -> None:
        today = self.today
        put = lambda key, value: self.add(  # noqa: E731 - table row, not logic
            'settings', {'key': key, 'value': value}
        )
        put('displayName', 'Jordan')
        put('monthlyNetIncome', str(self.MONTHLY_INCOME))
        put('targetSurplusLow', '700.0')
        put('targetSurplusHigh', '1200.0')
        put('birthday', day_key(self.BIRTHDAY))
        # Legacy key names, kept by the app for data compatibility.
        put('rothIraAnnualTarget', '7000.0')
        put('rothIraContributed', '2450.0')
        # Pre-v3 balance settings stay frozen at 0; real balances live in
        # the accounts table (LegacyMigration only promotes non-zero ones).
        put('brokerageBalance', '0')
        put('savingsBalance', '0')
        put(
            'philosophyText',
            'Spend less than I earn, keep one promise a day, and leave room '
            'to be a person.',
        )
        put('dashboardAreas', 'money,time,habits,ideas')
        put('lastBackupAt', stamp(today - timedelta(days=2), 21, 15))

        # Income snapshots: the surplus history reads the income that
        # applied to each month, not today's number retro-applied. Jordan
        # got a raise four months ago.
        for back in range(0, 8):
            month = add_months(month_start(today), -back)
            income = self.MONTHLY_INCOME if back <= 3 else 3980.0
            put(f'incomeFor.{month_key(month)}', str(income))

    # -- focus: main goal, milestones, measure, daily steps ----------------

    def build_focus(self) -> None:
        today = self.today
        # The money goal starts where the balance history starts, so the
        # account chart, the progress measure and the milestones all
        # describe the same seven months.
        started = add_months(today, -self.BALANCE_HISTORY_MONTHS + 1)
        card_balance = next(
            balance for name, _k, balance, _n in self.ACCOUNTS if name == 'Visa'
        )
        paid_down = round(self.CARD_OPENING_BALANCE - card_balance, 2)

        self.add(
            'mainGoals',
            {
                'id': uid('main-goal:debt-free'),
                'title': 'Clear the credit card and bank 3 months of costs',
                'why': "So one bad month stops turning into a bad year. I "
                'want to stop checking the balance on Sunday nights.',
                'targetDate': day_key(add_months(today, 9)),
                'status': 'active',
                'createdAt': stamp(started, 20, 10),
                'updatedAt': stamp(today - timedelta(days=6), 19, 5),
                'completedAt': None,
            },
        )
        # A finished goal kept for history — the app never deletes past goals.
        finished = add_months(started, -1)
        self.add(
            'mainGoals',
            {
                'id': uid('main-goal:certificate'),
                'title': 'Finish the bookkeeping certificate',
                'why': 'A shot at a role that pays enough to fix the rest.',
                'targetDate': day_key(finished),
                'status': 'completed',
                'createdAt': stamp(add_months(finished, -8), 21, 0),
                'updatedAt': stamp(finished, 18, 30),
                'completedAt': stamp(finished, 18, 30),
            },
        )

        # A milestone with no measure is a plain check-off; the ones with
        # a measure show a progress bar. `paid_down` keeps the Visa
        # milestone equal to what the progress measure actually logged.
        milestones = [
            ('Save a $1,000 starter buffer', '$ saved', 1000.0, 1000.0,
             add_months(today, -3), True),
            ('Close the store card', None, 0.0, 0.0,
             add_months(today, -2), True),
            ('Move payday transfer to automatic', None, 0.0, 0.0,
             add_months(today, -4), True),
            ('Pay $4,500 off the Visa', '$ paid', paid_down, 4500.0,
             add_months(today, 3), False),
            ('90 days with no new card spending', 'days', 61.0, 90.0,
             add_months(today, 1), False),
            ('Three months of costs in savings', 'months', 1.1, 3.0,
             add_months(today, 9), False),
        ]
        for order, (title, metric, current, target, due, done) in enumerate(
            milestones
        ):
            created = add_months(started, 0) + timedelta(days=order * 3)
            self.add(
                'goals',
                {
                    'id': uid(f'milestone:{title}'),
                    'title': title,
                    'description': None,
                    'metricName': metric,
                    'currentValue': current,
                    'targetValue': target,
                    'targetDate': day_key(due),
                    'isDone': done,
                    'sortOrder': order,
                    'createdAt': stamp(created, 20, 30),
                    'updatedAt': stamp(today - timedelta(days=4), 19, 40),
                },
            )

        # The progress measure: dollars paid down, logged every Sunday.
        # The last entry lands exactly on what the card has actually come
        # down by, so the measure, the milestone and the account balance
        # all tell the same story.
        metric_id = uid('metric:debt-paid-down')
        weeks = (today - started).days // 7 + 1
        sundays = []
        for week in range(weeks, 0, -1):
            when = monday_of(today) - timedelta(days=week * 7 - 6)
            if when <= today:
                sundays.append(when)
        steps = [self.rng.choice([140, 165, 175, 180, 200, 210, 95])
                 for _ in sundays]
        scale = paid_down / sum(steps) if steps else 0
        entries = []
        running = 0.0
        for index, when in enumerate(sundays):
            running += steps[index] * scale
            value = paid_down if index == len(sundays) - 1 else round(running, 2)
            entries.append((when, value))
        for index, (when, value) in enumerate(entries):
            self.add(
                'growthMetricEntries',
                {
                    'id': uid(f'metric-entry:{when.isoformat()}'),
                    'metricId': metric_id,
                    'date': day_key(when),
                    'value': value,
                    'note': 'Extra $50 from the refund'
                    if index == len(entries) - 3
                    else None,
                },
            )
        self.add(
            'growthMetrics',
            {
                'id': metric_id,
                'name': 'Paid off the card',
                'unit': '$',
                # The repository keeps this equal to the latest entry.
                'currentValue': entries[-1][1] if entries else 0.0,
                'weeklyTarget': 175.0,
                'isActive': True,
                'createdAt': stamp(started, 20, 20),
                'updatedAt': stamp(entries[-1][0] if entries else today, 19, 0),
            },
        )

        # Daily steps, honestly reviewed. Most days logged, not today —
        # so the demo opens with something to tap.
        steps = [
            ('Move $40 to savings before I see it', 'confirm',
             'Transfer went out at 6am, never noticed it.'),
            ('Cook the thing already in the fridge', 'confirm',
             'Ate at home, saved about $18.'),
            ('Call the card company about the rate', 'iterate',
             'Hold was 40 minutes. Try the app chat instead.'),
            ('No-spend day', 'confirm', 'Easy on a work-from-home day.'),
            ('Cancel one subscription', 'confirm',
             'Dropped the second streaming service.'),
            ('Pack lunch for tomorrow', 'confirm', 'Two minutes. Held.'),
            ('Log every receipt same day', 'iterate',
             'Caught up at night instead. Do it at the register.'),
            ('Walk instead of the rideshare', 'confirm', 'Saved $11.'),
            ('Round-up transfer after payday', 'confirm', 'Another $32 in.'),
            ('Ask for the bill split at dinner', 'kill',
             'Awkward and it saved almost nothing. Just order less.'),
            ('Batch the errands into one trip', 'confirm',
             'Half a tank saved.'),
            ('Sell the old monitor', 'iterate',
             'Listed it. No bites yet — try the local group.'),
        ]
        for back in range(1, 46):
            when = self.today - timedelta(days=back)
            if self.rng.random() < 0.18:
                continue  # real logs have gaps
            title, verdict, result = steps[(back * 7) % len(steps)]
            self.add(
                'dailyExperiments',
                {
                    'id': uid(f'action:{when.isoformat()}'),
                    'date': day_key(when),
                    'hypothesis': 'One small move gets me closer this week.',
                    'actionTaken': title,
                    'result': result,
                    'verdict': verdict,
                    'notes': None,
                    'createdAt': stamp(when, 21, 5),
                    'updatedAt': stamp(when, 21, 5),
                },
            )

    # -- money -------------------------------------------------------------

    # name, monthly target, flag rule, merchants, (min, max) per purchase
    CATEGORIES = [
        ('Housing', 1210.0, 'warnOverTarget', [], (0, 0)),
        ('Groceries', 420.0, 'warnOverTarget',
         ['Aldi', 'Trader Joes', 'Safeway', 'Corner market', 'Costco run'],
         (12.0, 72.0)),
        ('Transport', 220.0, 'warnOverTarget',
         ['Shell', 'Transit card', 'Parking', 'Oil change'], (10.0, 45.0)),
        ('Eating out', 160.0, 'warnOverTarget',
         ['Cafe Luna', 'Thai place', 'Pizza night', 'Work lunch',
          'Coffee cart'], (6.0, 34.0)),
        ('Subscriptions', 65.0, 'warnOverTarget',
         ['Music', 'News app', 'Podcast app'], (2.99, 12.99)),
        ('Health', 120.0, 'none',
         ['Pharmacy', 'Copay', 'Dentist'], (15.0, 85.0)),
        ('Fun', 120.0, 'warnOverTarget',
         ['Bookstore', 'Movie', 'Climbing gym day pass', 'Board game night'],
         (9.0, 40.0)),
        ('Travel', 80.0, 'none', ['Bus home', 'Hotel deposit'], (35.0, 140.0)),
        ('Debt payoff', 700.0, 'none', [], (0, 0)),
    ]

    ACCOUNTS = [
        ('Everyday checking', 'checking', 2148.73, True),
        ('Emergency savings', 'savings', 3420.00, True),
        ('Visa', 'credit', 3118.45, True),
        ('Retirement', 'investment', 12860.22, True),
    ]

    # description, amount, day of month, category, account.
    #
    # Spread on purpose: rent on the 1st is unavoidable, but everything
    # else sits after the mid-month paycheck. The Money screen projects
    # spend in a straight line, and a month front-loaded with fixed
    # charges reads as an overspend for the first week no matter how the
    # month actually ends. See demo/README.md.
    RECURRING = [
        ('Rent', 1150.00, 1, 'Housing', 'Everyday checking'),
        ('Gym', 32.00, 3, 'Health', 'Everyday checking'),
        ('Internet', 60.00, 5, 'Housing', 'Everyday checking'),
        ('Phone', 45.00, 8, 'Subscriptions', 'Everyday checking'),
        ('Streaming bundle', 24.98, 14, 'Fun', 'Everyday checking'),
        ('Password manager', 2.99, 22, 'Subscriptions', 'Everyday checking'),
        ('Car insurance', 118.00, 24, 'Transport', 'Everyday checking'),
        ('Card payment', 700.00, 26, 'Debt payoff', 'Everyday checking'),
    ]

    def build_money(self) -> None:
        today = self.today
        opened = add_months(today, -8)

        category_ids: dict[str, str] = {}
        for order, (name, target, flag, _, _) in enumerate(self.CATEGORIES):
            cid = uid(f'category:{name}')
            category_ids[name] = cid
            self.add(
                'budgetCategories',
                {
                    'id': cid,
                    'name': name,
                    'monthlyTargetCents': cents(target),
                    'flagType': flag,
                    'sortOrder': order,
                    'createdAt': stamp(opened, 9, 0),
                    'updatedAt': stamp(add_months(today, -2), 9, 0),
                },
            )

        account_ids: dict[str, str] = {}
        for order, (name, kind, balance, in_net) in enumerate(self.ACCOUNTS):
            aid = uid(f'account:{name}')
            account_ids[name] = aid
            self.add(
                'accounts',
                {
                    'id': aid,
                    'name': name,
                    'kind': kind,
                    'balanceCents': cents(balance),
                    'includeInNetWorth': in_net,
                    'sortOrder': order,
                    'createdAt': stamp(opened, 9, 5),
                    'updatedAt': stamp(today - timedelta(days=1), 8, 20),
                },
            )

        # Balance history: savings climbing, card falling, month by month.
        # One snapshot per account per day (the schema enforces it).
        trajectories = {
            'Everyday checking': [1980, 2110, 1875, 2260, 2040, 2310, 1990,
                                  2148.73],
            'Emergency savings': [1200, 1550, 1900, 2260, 2600, 2950, 3180,
                                  3420.00],
            'Visa': [6810, 6240, 5680, 5090, 4520, 3960, 3520, 3118.45],
            'Retirement': [10420, 10880, 11150, 11640, 11980, 12210, 12540,
                           12860.22],
        }
        points = self.BALANCE_HISTORY_MONTHS
        for name, series in trajectories.items():
            for index in range(points):
                when = add_months(month_start(today), -(points - 1 - index))
                when = min(when, today)
                if index == points - 1:
                    when = today - timedelta(days=1)
                self.add(
                    'balanceSnapshots',
                    {
                        'id': uid(f'snapshot:{name}:{index}'),
                        'accountId': account_ids[name],
                        'date': day_key(when),
                        'balanceCents': cents(series[index]),
                    },
                )

        recurring_ids: dict[str, str] = {}
        for description, amount, day, category, _account in self.RECURRING:
            rid = uid(f'recurring:{description}')
            recurring_ids[description] = rid
            self.add(
                'recurringTransactions',
                {
                    'id': rid,
                    'categoryId': category_ids[category],
                    'amountCents': cents(amount),
                    'description': description,
                    'dayOfMonth': day,
                    'isIntentional': True,
                    'active': True,
                    'lastMaterializedMonth': month_key(today),
                    'createdAt': stamp(opened, 9, 10),
                },
            )

        checking = account_ids['Everyday checking']
        visa = account_ids['Visa']

        # Recurring expenses land as real transactions, one set per month.
        for back in range(3, -1, -1):
            month = add_months(month_start(today), -back)
            for description, amount, day, category, _account in self.RECURRING:
                when = month.replace(
                    day=min(day, days_in_month(month.year, month.month))
                )
                if when > today:
                    continue
                self.add(
                    'transactions',
                    {
                        'id': uid(f'tx:recurring:{description}:'
                                  f'{when.isoformat()}'),
                        'categoryId': category_ids[category],
                        'accountId': checking,
                        'sourceRecurringId': recurring_ids[description],
                        'date': day_key(when),
                        'amountCents': cents(amount),
                        'description': description,
                        'isIntentional': True,
                        'createdAt': stamp(when, 6, 5),
                    },
                )

        # Day-to-day spending for the last ~14 weeks.
        spend_pool = [
            (name, merchants, bounds)
            for name, _t, _f, merchants, bounds in self.CATEGORIES
            if merchants
        ]
        weights = [30, 12, 22, 8, 9, 12, 4]  # Groceries..Travel, rough shape
        for back in range(97, -1, -1):
            when = today - timedelta(days=back)
            count = self.rng.choices([0, 1, 2, 3], weights=[32, 42, 22, 4])[0]
            for slot in range(count):
                name, merchants, (low, high) = self.rng.choices(
                    spend_pool, weights=weights
                )[0]
                amount = round(self.rng.uniform(low, high), 2)
                # Eating out drifts over target this month on purpose: the
                # demo should show one honest flag, not a perfect month.
                if name == 'Eating out' and when >= month_start(today):
                    amount = round(amount * 1.4, 2)
                merchant = self.rng.choice(merchants)
                on_card = name in ('Groceries', 'Eating out') and (
                    self.rng.random() < 0.25
                )
                self.add(
                    'transactions',
                    {
                        'id': uid(f'tx:{when.isoformat()}:{slot}'),
                        'categoryId': category_ids[name],
                        'accountId': visa if on_card else checking,
                        'sourceRecurringId': None,
                        'date': day_key(when),
                        'amountCents': cents(amount),
                        'description': merchant,
                        'isIntentional': self.rng.random() < 0.6,
                        'createdAt': stamp(when, 12 + slot, 20),
                    },
                )

        # One uncategorized straggler — the app nudges you to file it.
        self.add(
            'transactions',
            {
                'id': uid('tx:uncategorized'),
                'categoryId': None,
                'accountId': checking,
                'sourceRecurringId': None,
                'date': day_key(today - timedelta(days=2)),
                'amountCents': cents(37.40),
                'description': 'Card ending 4412 — what was this?',
                'isIntentional': False,
                'createdAt': stamp(today - timedelta(days=2), 19, 12),
            },
        )

        self.add(
            'freedomTargets',
            {
                'id': uid('freedom:work-optional'),
                'title': 'Work optional at 55',
                'description': 'Enough coming in that the job is a choice.',
                'targetMonthlyPassiveIncome': 3200.0,
                'targetLiquidNetWorth': 480000.0,
                'currentMonthlyPassiveIncome': 41.0,
                'currentLiquidNetWorth': 15310.5,
                'targetDate': day_key(
                    self.BIRTHDAY.replace(year=self.BIRTHDAY.year + 55)
                ),
                'createdAt': stamp(add_months(today, -5), 21, 30),
                'updatedAt': stamp(add_months(today, -1), 20, 15),
            },
        )

    # -- time --------------------------------------------------------------

    TIME_BUDGETS = [
        ('Sleep', 'sleep', 56.0, (6.5, 8.3), 1.0),
        ('Work', 'job', 40.0, (7.0, 9.0), 0.0),
        ('Main goal', 'goal', 8.0, (1.0, 2.5), 0.75),
        ('Exercise', 'exercise', 4.0, (0.6, 1.4), 0.58),
        ('Downtime', 'decompress', 8.0, (0.75, 2.5), 0.8),
        ('Chores & admin', 'admin', 6.0, (0.75, 2.0), 0.6),
    ]

    def build_time(self) -> None:
        today = self.today
        budget_ids: dict[str, str] = {}
        for order, (name, kind, target, _r, _p) in enumerate(self.TIME_BUDGETS):
            bid = uid(f'budget:{name}')
            budget_ids[name] = bid
            self.add(
                'timeBudgets',
                {
                    'id': bid,
                    'name': name,
                    'kind': kind,
                    'weeklyTargetHours': target,
                    'sortOrder': order,
                },
            )

        for back in range(41, -1, -1):
            when = today - timedelta(days=back)
            weekday = when.weekday()  # 0 = Monday
            for name, _kind, _target, (low, high), chance in self.TIME_BUDGETS:
                if name == 'Work':
                    if weekday >= 5:
                        continue
                    hours = round(self.rng.uniform(low, high) * 4) / 4
                elif name == 'Sleep':
                    hours = round(self.rng.uniform(low, high) * 4) / 4
                else:
                    if self.rng.random() > chance:
                        continue
                    hours = round(self.rng.uniform(low, high) * 4) / 4
                if hours <= 0:
                    continue
                note = None
                if name == 'Main goal' and self.rng.random() < 0.25:
                    note = self.rng.choice([
                        'Budget review + moved the transfer',
                        'Called about the rate',
                        'Sorted receipts, updated categories',
                        'Read two chapters of the payoff book',
                    ])
                self.add(
                    'timeBlocks',
                    {
                        'id': uid(f'block:{name}:{when.isoformat()}'),
                        'budgetId': budget_ids[name],
                        'date': day_key(when),
                        'hours': hours,
                        'note': note,
                        'createdAt': stamp(when, 22, 0),
                    },
                )

        countdowns = [
            ('End of the year', None, 'endOfYear'),
            ('End of the month', None, 'endOfMonth'),
            ('Card paid off (target)', day_key(add_months(today, 9)), None),
            ('Lisbon trip', day_key(add_months(today, 4) + timedelta(days=5)),
             None),
        ]
        for order, (title, target, dynamic) in enumerate(countdowns):
            self.add(
                'countdowns',
                {
                    'id': uid(f'countdown:{title}'),
                    'title': title,
                    'targetDate': target,
                    'dynamicKey': dynamic,
                    'sortOrder': order,
                },
            )

    # -- you: habits, ideas, reminders, principles, journal, notes ---------

    # name, type, unit, weekdays bitmask, reminder, health metric/target,
    # adherence, value range
    HABITS = [
        ('Move for 20 minutes', 'duration', 'min', 127, (7, 15), None, None,
         0.74, (18, 45)),
        ('Read before bed', 'duration', 'min', 127, (21, 45), None, None,
         0.66, (10, 40)),
        ('In bed by 11', 'boolean', None, 127, None, None, None, 0.71, None),
        ('Walk 8k steps', 'numeric', 'steps', 127, None, 'steps', 8000.0,
         0.62, (6200, 12800)),
        ('No-spend day', 'boolean', None, 31, None, None, None, 0.55, None),
    ]

    def build_you(self) -> None:
        today = self.today
        created = add_months(today, -5)

        habit_ids: dict[str, str] = {}
        for order, habit in enumerate(self.HABITS):
            (name, kind, unit, weekdays, reminder, metric, target, _a,
             _r) = habit
            hid = uid(f'habit:{name}')
            habit_ids[name] = hid
            self.add(
                'habits',
                {
                    'id': hid,
                    'name': name,
                    'type': kind,
                    'unit': unit,
                    'weekdays': weekdays,
                    'reminderHour': reminder[0] if reminder else None,
                    'reminderMinute': reminder[1] if reminder else None,
                    'notificationId': self.notification_id(),
                    'healthMetric': metric,
                    'healthTarget': target,
                    'sortOrder': order,
                    'isArchived': False,
                    'createdAt': stamp(created, 8, 30),
                },
            )

        for back in range(59, -1, -1):
            when = today - timedelta(days=back)
            bit = 1 << when.weekday()
            for habit in self.HABITS:
                (name, kind, _u, weekdays, _rem, metric, _t, adherence,
                 value_range) = habit
                if not weekdays & bit:
                    continue
                # Today is deliberately half-done: two checks in, three to go.
                if back == 0 and name in ('Read before bed', 'In bed by 11',
                                          'No-spend day'):
                    continue
                if self.rng.random() > adherence:
                    continue
                if kind == 'boolean':
                    value = 1.0
                else:
                    low, high = value_range
                    value = float(self.rng.randint(int(low), int(high)))
                self.add(
                    'habitLogs',
                    {
                        'id': uid(f'habit-log:{name}:{when.isoformat()}'),
                        'habitId': habit_ids[name],
                        'date': day_key(when),
                        'value': value,
                        'note': None,
                        'source': 'health' if metric else 'manual',
                    },
                )

        reminders = [
            ('Morning plan', 'morningCommand',
             'One thing today. Pick it before the day picks for you.', 8, 0,
             127),
            ('Daily step', 'dailyAction',
             'What is the small move on the goal today?', 12, 30, 31),
            ('Money check', 'moneyCheck',
             'Two minutes: file receipts, check the surplus.', 18, 0, 64),
            ('Evening review', 'nightReview',
             'How did today go? One honest line.', 21, 30, 127),
        ]
        for title, kind, message, hour, minute, weekdays in reminders:
            self.add(
                'reminders',
                {
                    'id': uid(f'reminder:{title}'),
                    'title': title,
                    'message': message,
                    'type': kind,
                    'hour': hour,
                    'minute': minute,
                    'weekdays': weekdays,
                    'oneShotDate': None,
                    'enabled': title != 'Daily step',
                    'notificationId': self.notification_id(),
                    'createdAt': stamp(created, 8, 35),
                    'updatedAt': stamp(add_months(today, -1), 8, 35),
                },
            )

        principles = [
            'Do the small thing today, not the perfect thing someday.',
            "Money I don't spend is time I get back.",
            'Rest is part of the plan, not a reward for finishing it.',
            "If it isn't written down, it isn't real.",
            'Progress over streaks. Miss once, never twice.',
        ]
        for order, line in enumerate(principles):
            self.add(
                'identityStatements',
                {
                    'id': uid(f'principle:{order}'),
                    'content': line,
                    'sortOrder': order,
                },
            )

        ideas = [
            ('Sell the old monitor and camera', 'Money',
             'Cash sitting in a closet', 'Maybe $250 toward the card',
             28, 'integrate', True),
            ('Weekend food truck side gig', 'Work',
             'Feels like faster money', 'Probably $400/mo, all my weekends',
             21, 'later', False),
            ('Switch to a cheaper phone plan', 'Money',
             'Same coverage, less money', '$18/mo back', 14, 'integrate',
             True),
            ('Start a newsletter about budgeting', 'Creative',
             'I have opinions', 'Unclear. Fun, though.', 9, 'later', False),
            ('Buy the espresso machine', 'Home',
             'Cafe habit is expensive', 'Pays back in 7 months if I use it',
             5, 'undecided', False),
            ('Refinance the car', 'Money',
             'Rate dropped since I bought it', 'Maybe $40/mo', 2, 'undecided',
             True),
            ('Learn to cut my own hair', 'Home',
             'Saw a video and got confident', '$30 a month, some risk',
             1, 'undecided', False),
        ]
        for (title, category, tempting, value, days_ago, decision,
             helps) in ideas:
            captured = today - timedelta(days=days_ago)
            self.add(
                'parkedIdeas',
                {
                    'id': uid(f'idea:{title}'),
                    'title': title,
                    'description': None,
                    'category': category,
                    'whyTempting': tempting,
                    'potentialValue': value,
                    'dateCaptured': day_key(captured),
                    'reviewDate': day_key(captured + timedelta(days=7)),
                    'decision': decision,
                    'helpsMainGoal': helps,
                    'createdAt': stamp(captured, 20, 45),
                    'updatedAt': stamp(captured + timedelta(days=7), 20, 45)
                    if decision != 'undecided'
                    else stamp(captured, 20, 45),
                },
            )

        journal_lines = [
            'Paid the card down another $180. It is finally under $3,200.',
            'Skipped the takeout twice this week. Cooking is not the hard '
            'part — deciding is.',
            'Rough day at work. Did not log anything. Starting again today.',
            'The automatic transfer is the single best thing I set up.',
            'Sunday review took four minutes. I keep expecting it to hurt.',
            'Almost bought the espresso machine. Parked it instead.',
            'Walked home instead of the rideshare. Small, but it counts.',
            'Groceries came in under budget for once.',
            'Tired. In bed by 10:30 and it fixed most of it.',
            'Called about the interest rate — no luck, but I asked.',
            'First month where savings went up and the card went down.',
            'Missed two habits today. Not going to miss them tomorrow.',
            'Told a friend about the payoff plan out loud. Felt real.',
            'Bought the book instead of the gadget. Fine trade.',
            'The uncategorized transaction was a vet bill. Mystery solved.',
        ]
        for index, line in enumerate(journal_lines):
            when = today - timedelta(days=index * 4 + 1)
            self.add(
                'journalEntries',
                {
                    'id': uid(f'journal:{when.isoformat()}'),
                    'date': day_key(when),
                    'content': line,
                    'createdAt': stamp(when, 21, 40),
                    'updatedAt': stamp(when, 21, 40),
                },
            )

        reviews = [
            ('Card down $175. Ate out twice more than planned.',
             'Cook Sunday, freeze half.'),
            ('Good week. Hit goal hours three days running.',
             'Keep the morning slot for the goal.'),
            ('Slipped on sleep, everything else followed.',
             'Bed by 11, no exceptions.'),
            ('Sold nothing, saved nothing extra. Flat week.',
             'List the monitor Monday.'),
            ('Best surplus yet — $940.',
             'Send the extra straight at the card.'),
            ('Travel week. Spending was high but planned.',
             'Back to normal groceries.'),
            ('Two no-spend days. Easier than expected.',
             'Try three next week.'),
            ('Quiet week, everything held.', 'Do not change anything.'),
        ]
        for index, (reflection, emphasis) in enumerate(reviews):
            week_start = monday_of(today) - timedelta(days=(index + 1) * 7)
            self.add(
                'weeklyReviews',
                {
                    'id': uid(f'review:{week_start.isoformat()}'),
                    'weekStart': day_key(week_start),
                    'reflection': reflection,
                    'emphasis': emphasis,
                    'createdAt': stamp(week_start + timedelta(days=6), 19, 0),
                },
            )

        self.build_notes()

    # -- notes (the Zettelkasten) ------------------------------------------

    NOTES = [
        ('Debt payoff plan',
         'The whole plan on one page.\n\n'
         '1. Minimums on everything.\n'
         '2. Every spare dollar at the [[Visa card]].\n'
         '3. Keep [[Emergency fund]] at one month while paying down, then '
         'build to three.\n\n'
         'Reviewed every Sunday — see [[Sunday money review]].\n\n'
         '#money #goal'),
        ('Visa card',
         'Balance was $6,810 in the spring. Now it is under $3,200.\n\n'
         'Rate is 22.9%. Asked for a reduction, was declined once — ask '
         'again after six on-time payments.\n\n'
         'Every extra dollar here beats every dollar in savings until it is '
         'gone. See [[Debt payoff plan]].\n\n'
         '#money #debt'),
        ('Emergency fund',
         'Target: three months of costs, about $8,400.\n\n'
         'At $3,420 today. Holding at one month until the [[Visa card]] is '
         'clear, then the whole payment redirects here.\n\n'
         '#money #safety'),
        ('Sunday money review',
         'Four minutes, same order every week:\n\n'
         '- File anything uncategorized\n'
         '- Check the surplus against target\n'
         '- Move whatever is left at the card\n'
         '- Write one line in the journal\n\n'
         'Shorter than I expect it to be, every time. #ritual #money'),
        ('Groceries that actually get eaten',
         'Buying less, more often, beats one big shop I half-use.\n\n'
         'Rotation: beans, eggs, rice, whatever green is cheap, one thing '
         'I actually want.\n\n'
         'Cuts [[Eating out]] more than any rule I have tried. #food #money'),
        ('Eating out',
         'Not the enemy — the unplanned ones are.\n\n'
         'Rule: planned meals out are intentional and get marked that way. '
         'Everything else is a leak.\n\n'
         '#food #money'),
        ('Sleep is the lever',
         'Every week I sleep badly, the spending goes up and the goal hours '
         'go down. It shows in the numbers, not just my mood.\n\n'
         'Bed by 11. See [[Evening shutdown]]. #health'),
        ('Evening shutdown',
         'Dishes, phone on the charger across the room, ten pages, lights '
         'out.\n\n'
         'Twenty minutes. Protects [[Sleep is the lever]] better than any '
         'alarm. #ritual #health'),
        ('Things I stopped buying',
         'Second streaming service. Delivery fees. The gadget I wanted in '
         'March and cannot now name.\n\n'
         'Total: about $74 a month, doing nothing but leaving.\n\n'
         '#money'),
        ('Why this goal',
         'Not about the card. About never again having a $600 surprise '
         'decide my next three months.\n\n'
         'When it gets boring, this is the note to reread. '
         '#goal #motivation'),
    ]

    def build_notes(self) -> None:
        today = self.today
        for index, (title, content) in enumerate(self.NOTES):
            created = today - timedelta(days=90 - index * 8)
            updated = today - timedelta(days=max(1, 40 - index * 4))
            zettel = datetime(
                created.year, created.month, created.day, 20, 15, index
            ).strftime('%Y%m%d%H%M%S')
            self.add(
                'notes',
                {
                    'id': uid(f'note:{title}'),
                    'zettelId': zettel,
                    'title': title,
                    'content': content,
                    'isArchived': False,
                    'createdAt': stamp(created, 20, 15),
                    'updatedAt': stamp(updated, 21, 5),
                },
            )

    # -- assembly ----------------------------------------------------------

    def build(self) -> dict:
        self.build_settings()
        self.build_focus()
        self.build_money()
        self.build_time()
        self.build_you()
        return self.envelope()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--now',
        help='Anchor date (yyyy-mm-dd). Defaults to today; every other date '
        'in the file is relative to it.',
    )
    parser.add_argument(
        '--out',
        default=str(Path(__file__).resolve().parent.parent
                    / 'demo' / 'life_assist_demo.json'),
        help='Where to write the backup JSON.',
    )
    args = parser.parse_args()

    today = (
        date.fromisoformat(args.now) if args.now else date.today()
    )
    export = Builder(today).build()

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(
        json.dumps(export, indent=2, ensure_ascii=False) + '\n',
        encoding='utf-8',
    )

    rows = sum(len(v) for v in export['data'].values())
    print(f'Wrote {out} — {rows} rows across '
          f'{len(export["data"])} tables, anchored at {today}.')
    for table, values in export['data'].items():
        print(f'  {table:<24} {len(values):>5}')


if __name__ == '__main__':
    main()
