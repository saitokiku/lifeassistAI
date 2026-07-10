import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../utils/date_utils.dart';
import 'app_database.dart';
import 'settings_keys.dart';

/// Rewrites pre-v3 data into the current shape.
///
/// v2 ("Kaizen era" → universal main goal):
/// 1. Rewrites legacy enum values stored in rows (`kaizen` → `goal`,
///    `kaizenExperiment` → `dailyAction`).
/// 2. If the database contains Kaizen-era activity but no main goal yet,
///    creates one named "Kaizen" — preserving the original owner's goal as
///    real user data instead of a product concept.
///
/// v3 (accounts):
/// 3. Turns the legacy manual balance settings (brokerage/savings) into
///    tracked Account rows with an opening balance snapshot.
///
/// Idempotent and cheap; runs after seeding on launch (gated by a data
/// revision flag in bootstrap) and unconditionally after a backup import,
/// which may restore an older envelope.
class LegacyMigration {
  LegacyMigration(this._db);

  final AppDatabase _db;

  static const String legacyGoalTitle = 'Kaizen';

  Future<void> run({DateTime? now}) async {
    final at = now ?? DateTime.now();
    await _db.transaction(() async {
      await _rewriteLegacyKinds();
      await _deriveMainGoal(at);
      await _deriveAccounts(at);
    });
  }

  Future<void> _rewriteLegacyKinds() async {
    // Check-before-write: keep re-runs (every import) free of writes.
    final legacyBudget = await (_db.select(_db.timeBudgets)
          ..where((t) => t.kind.equals('kaizen'))
          ..limit(1))
        .get();
    if (legacyBudget.isNotEmpty) {
      await (_db.update(_db.timeBudgets)
            ..where((t) => t.kind.equals('kaizen')))
          .write(const TimeBudgetsCompanion(kind: Value('goal')));
    }
    final legacyReminder = await (_db.select(_db.reminders)
          ..where((t) => t.type.equals('kaizenExperiment'))
          ..limit(1))
        .get();
    if (legacyReminder.isNotEmpty) {
      await (_db.update(_db.reminders)
            ..where((t) => t.type.equals('kaizenExperiment')))
          .write(const RemindersCompanion(type: Value('dailyAction')));
    }
  }

  /// A v1 database always carried Kaizen artifacts (a growth metric was
  /// seeded on first launch), so their presence + no main goal means this
  /// is an upgrade, not a fresh install.
  Future<void> _deriveMainGoal(DateTime at) async {
    final existing = await (_db.select(_db.mainGoals)..limit(1)).get();
    if (existing.isNotEmpty) return;

    final metrics = await (_db.select(_db.growthMetrics)..limit(1)).get();
    final experiments =
        await (_db.select(_db.dailyExperiments)..limit(1)).get();
    if (metrics.isEmpty && experiments.isEmpty) return;

    await _db.into(_db.mainGoals).insert(MainGoal(
          id: const Uuid().v4(),
          title: legacyGoalTitle,
          why: '',
          targetDate: null,
          status: 'active',
          createdAt: at,
          updatedAt: at,
          completedAt: null,
        ));
  }

  /// Pre-v3, brokerage/savings lived as two bare settings numbers. Promote
  /// non-zero balances to real Account rows (the KV values stay behind,
  /// frozen, so older backups remain readable).
  Future<void> _deriveAccounts(DateTime at) async {
    final existing = await (_db.select(_db.accounts)..limit(1)).get();
    if (existing.isNotEmpty) return;

    final rows = await _db.select(_db.settingsEntries).get();
    final map = {for (final r in rows) r.key: r.value};
    final legacy = <(String, String, double)>[
      ('Brokerage', 'investment',
          double.tryParse(map[SettingsKeys.brokerageBalance] ?? '') ?? 0),
      ('Savings', 'savings',
          double.tryParse(map[SettingsKeys.savingsBalance] ?? '') ?? 0),
    ];

    var order = 0;
    for (final (name, kind, balance) in legacy) {
      if (balance == 0) continue;
      final id = const Uuid().v4();
      await _db.into(_db.accounts).insert(Account(
            id: id,
            name: name,
            kind: kind,
            balance: balance,
            includeInNetWorth: true,
            sortOrder: order++,
            createdAt: at,
            updatedAt: at,
          ));
      await _db.into(_db.balanceSnapshots).insert(BalanceSnapshot(
            id: const Uuid().v4(),
            accountId: id,
            date: AppDateUtils.dateKey(at),
            balance: balance,
          ));
    }
  }
}
