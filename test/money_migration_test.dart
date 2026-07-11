import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/core/utils/money.dart';
import 'package:life_dashboard/features/money/domain/monthly_money_snapshot.dart';
import 'package:life_dashboard/features/settings/data/backup_service.dart';

/// Schema v4 turns every stored dollar double into integer cents. These
/// tests prove the three paths that matter: a real v3 database file
/// migrates with values exact to the cent, a v3 JSON backup imports the
/// same way, and sums can no longer drift (ten dimes are exactly a
/// dollar).
///
/// The planted amounts are chosen to be adversarial in binary floating
/// point: 4.35 * 100 is 434.99999999999994 as a double, so truncation
/// would lose a cent — only correct rounding gets 435.
void main() {
  group('v3 database file → v4 migration', () {
    late Directory tmp;
    late File dbFile;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('lifeassist_migration');
      dbFile = File('${tmp.path}/app.db');
    });

    tearDown(() => tmp.delete(recursive: true));

    test('converts money to cents, creates journal, keeps indexes',
        () async {
      await _plantV3Database(dbFile);

      final db = AppDatabase(DatabaseConnection(NativeDatabase(dbFile)));
      addTearDown(db.close);

      final txs = await db.select(db.transactionEntries).get();
      expect(txs, hasLength(12));
      final byId = {for (final t in txs) t.id: t};
      expect(byId['dust']!.amountCents, 435); // 4.35 — the hard case
      expect(byId['big']!.amountCents, 123456); // 1234.56
      for (var i = 0; i < 10; i++) {
        expect(byId['dime-$i']!.amountCents, 10);
      }
      // Non-money columns ride through the table rebuild untouched.
      expect(byId['dust']!.categoryId, 'cat-g');
      expect(byId['dust']!.isIntentional, isTrue);
      expect(byId['dust']!.date, '2026-07-04');

      final cat = await db.select(db.budgetCategories).getSingle();
      expect(cat.monthlyTargetCents, 25800); // 258.0
      expect(cat.flagType, 'warnOverTarget');

      final account = await db.select(db.accounts).getSingle();
      expect(account.balanceCents, 250075); // 2500.75

      final snapshot = await db.select(db.balanceSnapshots).getSingle();
      expect(snapshot.balanceCents, 250075);

      final recurring =
          await db.select(db.recurringTransactions).getSingle();
      expect(recurring.amountCents, 1599); // 15.99
      expect(recurring.dayOfMonth, 1);

      // The journal arrived with v4.
      await db.into(db.journalEntries).insert(JournalEntry(
            id: 'j1',
            date: '2026-07-10',
            content: 'Migration day.',
            createdAt: DateTime(2026, 7, 10),
            updatedAt: DateTime(2026, 7, 10),
          ));
      expect(await db.select(db.journalEntries).get(), hasLength(1));

      // Rebuilt tables got their indexes back.
      final indexes = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index' "
              "AND name IN ('idx_transactions_date', "
              "'idx_balance_snapshots_account', 'idx_journal_entries_date')")
          .get();
      expect(indexes, hasLength(3));
    });
  });

  group('v3 backup import', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    });

    tearDown(() async {
      await db.close();
    });

    test('dollar doubles convert to cents on the way in', () async {
      const v3Backup = '''
{
  "app": "Life Assist",
  "schemaVersion": "3",
  "data": {
    "budgetCategories": [
      {"id": "cat-g", "name": "Groceries", "monthlyTarget": 258.0,
       "flagType": "warnOverTarget", "sortOrder": 0,
       "createdAt": 1750000000000, "updatedAt": 1750000000000}
    ],
    "transactions": [
      {"id": "t1", "categoryId": "cat-g", "date": "2026-07-04",
       "amount": 4.35, "description": "farmers market",
       "isIntentional": false, "createdAt": 1750000000000}
    ],
    "recurringTransactions": [
      {"id": "r1", "categoryId": null, "amount": 15.99,
       "description": "music", "dayOfMonth": 1, "isIntentional": true,
       "active": true, "lastMaterializedMonth": null,
       "createdAt": 1750000000000}
    ],
    "accounts": [
      {"id": "a1", "name": "Checking", "kind": "checking",
       "balance": 2500.75, "includeInNetWorth": true, "sortOrder": 0,
       "createdAt": 1750000000000, "updatedAt": 1750000000000}
    ],
    "balanceSnapshots": [
      {"id": "s1", "accountId": "a1", "date": "2026-07-01",
       "balance": 2500.75}
    ]
  }
}
''';
      final result = await BackupService(db).importJson(v3Backup);
      expect(result.isSuccess, isTrue, reason: result.errorOrNull);

      final tx = await db.select(db.transactionEntries).getSingle();
      expect(tx.amountCents, 435);
      expect(tx.description, 'farmers market');

      expect(
        (await db.select(db.budgetCategories).getSingle())
            .monthlyTargetCents,
        25800,
      );
      expect(
        (await db.select(db.recurringTransactions).getSingle()).amountCents,
        1599,
      );
      expect((await db.select(db.accounts).getSingle()).balanceCents, 250075);
      expect(
        (await db.select(db.balanceSnapshots).getSingle()).balanceCents,
        250075,
      );
    });
  });

  group('exactness', () {
    test('centsFromAmount rounds representation dust correctly', () {
      expect(centsFromAmount(4.35), 435);
      expect(centsFromAmount(0.1), 10);
      expect(centsFromAmount(1234.56), 123456);
      expect(centsFromAmount(0), 0);
      expect(amountFromCents(435), closeTo(4.35, 1e-9));
    });

    test('ten dimes are exactly a dollar in the monthly snapshot', () {
      // The float bug this migration kills: 0.1 summed ten times is
      // 0.9999999999999999. In cents it is exactly 100.
      final now = DateTime(2026, 7, 10);
      final cat = BudgetCategory(
        id: 'c',
        name: 'Coffee',
        monthlyTargetCents: 100,
        flagType: 'warnOverTarget',
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );
      final snapshot = MonthlyMoneySnapshot.compute(
        now: now,
        monthlyNetIncome: 5000,
        targetSurplusLow: 1000,
        targetSurplusHigh: 2000,
        categories: [cat],
        monthTransactions: [
          for (var i = 0; i < 10; i++)
            TransactionEntry(
              id: 'dime-$i',
              categoryId: 'c',
              date: '2026-07-05',
              amountCents: centsFromAmount(0.1),
              description: 'dime',
              isIntentional: false,
              createdAt: now,
            ),
        ],
        retirementAnnualTarget: 0,
        retirementContributed: 0,
        brokerageBalance: 0,
        savingsBalance: 0,
      );

      expect(snapshot.spendCentsSoFar, 100);
      expect(snapshot.categorySpends.single.spentCents, 100);
      // Exactly at target is not over target — no float dust flag.
      expect(
        snapshot.flags.where((f) => f.categoryId == 'c'),
        isEmpty,
      );
    });
  });
}

/// Creates a real database file with the v3 schema and v3 (dollar
/// double) data. Only the tables the v4 migration touches — plus every
/// table a schema index points at, since the migration re-runs
/// createIndex for all of them — need to exist.
Future<void> _plantV3Database(File file) async {
  final raw = _BareDb(DatabaseConnection(NativeDatabase(file)));
  const ddl = [
    'CREATE TABLE budget_categories (id TEXT NOT NULL PRIMARY KEY, '
        'name TEXT NOT NULL, monthly_target REAL NOT NULL DEFAULT 0, '
        "flag_type TEXT NOT NULL DEFAULT 'warnOverTarget', "
        'sort_order INTEGER NOT NULL DEFAULT 0, '
        'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)',
    'CREATE TABLE transaction_entries (id TEXT NOT NULL PRIMARY KEY, '
        'category_id TEXT, account_id TEXT, source_recurring_id TEXT, '
        'date TEXT NOT NULL, amount REAL NOT NULL, '
        "description TEXT NOT NULL DEFAULT '', "
        'is_intentional INTEGER NOT NULL DEFAULT 0, '
        'created_at INTEGER NOT NULL)',
    'CREATE TABLE recurring_transactions (id TEXT NOT NULL PRIMARY KEY, '
        'category_id TEXT, amount REAL NOT NULL, '
        "description TEXT NOT NULL DEFAULT '', "
        'day_of_month INTEGER NOT NULL DEFAULT 1, '
        'is_intentional INTEGER NOT NULL DEFAULT 1, '
        'active INTEGER NOT NULL DEFAULT 1, last_materialized_month TEXT, '
        'created_at INTEGER NOT NULL)',
    'CREATE TABLE accounts (id TEXT NOT NULL PRIMARY KEY, '
        "name TEXT NOT NULL, kind TEXT NOT NULL DEFAULT 'checking', "
        'balance REAL NOT NULL DEFAULT 0, '
        'include_in_net_worth INTEGER NOT NULL DEFAULT 1, '
        'sort_order INTEGER NOT NULL DEFAULT 0, '
        'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)',
    'CREATE TABLE balance_snapshots (id TEXT NOT NULL PRIMARY KEY, '
        'account_id TEXT NOT NULL, date TEXT NOT NULL, '
        'balance REAL NOT NULL)',
    // Index-bearing tables the migration's createIndex loop touches.
    'CREATE TABLE growth_metric_entries (id TEXT NOT NULL PRIMARY KEY, '
        'metric_id TEXT NOT NULL, date TEXT NOT NULL, value REAL NOT NULL, '
        'note TEXT)',
    'CREATE TABLE daily_experiments (id TEXT NOT NULL PRIMARY KEY, '
        'date TEXT NOT NULL, hypothesis TEXT NOT NULL, '
        'action_taken TEXT NOT NULL, result TEXT NOT NULL, '
        'verdict TEXT NOT NULL, notes TEXT, created_at INTEGER NOT NULL, '
        'updated_at INTEGER NOT NULL)',
    'CREATE TABLE time_blocks (id TEXT NOT NULL PRIMARY KEY, '
        'budget_id TEXT NOT NULL, date TEXT NOT NULL, hours REAL NOT NULL, '
        'note TEXT, created_at INTEGER NOT NULL)',
    'CREATE TABLE habit_logs (id TEXT NOT NULL PRIMARY KEY, '
        'habit_id TEXT NOT NULL, date TEXT NOT NULL, '
        'value REAL NOT NULL DEFAULT 1, note TEXT)',
    'CREATE TABLE main_goals (id TEXT NOT NULL PRIMARY KEY, '
        "title TEXT NOT NULL, why TEXT NOT NULL DEFAULT '', "
        "target_date TEXT, status TEXT NOT NULL DEFAULT 'active', "
        'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, '
        'completed_at INTEGER)',
    'CREATE TABLE weekly_reviews (id TEXT NOT NULL PRIMARY KEY, '
        "week_start TEXT NOT NULL, reflection TEXT NOT NULL DEFAULT '', "
        "emphasis TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  ];
  for (final statement in ddl) {
    await raw.customStatement(statement);
  }

  const t = 1750000000; // any epoch seconds
  await raw.customStatement(
      'INSERT INTO budget_categories VALUES '
      "('cat-g', 'Groceries', 258.0, 'warnOverTarget', 0, $t, $t)");
  await raw.customStatement(
      'INSERT INTO transaction_entries VALUES '
      "('dust', 'cat-g', NULL, NULL, '2026-07-04', 4.35, 'farmers market', "
      '1, $t)');
  await raw.customStatement(
      'INSERT INTO transaction_entries VALUES '
      "('big', 'cat-g', NULL, NULL, '2026-07-05', 1234.56, 'rent', 0, $t)");
  for (var i = 0; i < 10; i++) {
    await raw.customStatement(
        'INSERT INTO transaction_entries VALUES '
        "('dime-$i', 'cat-g', NULL, NULL, '2026-07-06', 0.1, 'dime', 0, $t)");
  }
  await raw.customStatement(
      'INSERT INTO recurring_transactions VALUES '
      "('r1', NULL, 15.99, 'music', 1, 1, 1, NULL, $t)");
  await raw.customStatement(
      'INSERT INTO accounts VALUES '
      "('a1', 'Checking', 'checking', 2500.75, 1, 0, $t, $t)");
  await raw.customStatement(
      'INSERT INTO balance_snapshots VALUES '
      "('s1', 'a1', '2026-07-01', 2500.75)");
  await raw.close();
}

/// A drift database with no tables: exists purely to run raw DDL against
/// a file and leave user_version stamped at 3, so reopening the file as
/// [AppDatabase] triggers the real v3 → v4 upgrade path.
class _BareDb extends GeneratedDatabase {
  _BareDb(super.e);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  int get schemaVersion => 3;
}
