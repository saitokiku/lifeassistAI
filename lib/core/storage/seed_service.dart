import 'package:uuid/uuid.dart';

import '../constants/default_targets.dart';
import '../constants/reminder_templates.dart';
import '../utils/date_utils.dart';
import 'app_database.dart';
import 'settings_keys.dart';

/// Seeds default records on first launch. Every seeded row becomes a real,
/// user-editable database record — nothing here is read at display time.
/// Idempotent: each section only seeds when its table is empty, so a reset
/// or partial import doesn't duplicate rows.
class SeedService {
  SeedService(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  static int notificationIdFor(String uuid) => uuid.hashCode & 0x7fffffff;

  Future<void> seedIfNeeded({DateTime? now}) async {
    final at = now ?? DateTime.now();
    await _db.transaction(() async {
      await _seedSettings();
      await _seedBudgetCategories(at);
      await _seedTimeBudgets();
      await _seedHabits(at);
      await _seedReminders(at);
      await _seedCountdowns(at);
      await _seedIdentity();
      await _seedFreedomTarget(at);
      await _seedGrowthMetric(at);
    });
  }

  Future<void> _seedSettings() async {
    final existing = await _db.select(_db.settingsEntries).get();
    final keys = existing.map((e) => e.key).toSet();
    Future<void> put(String key, String value) async {
      if (!keys.contains(key)) {
        await _db
            .into(_db.settingsEntries)
            .insert(SettingsEntry(key: key, value: value));
      }
    }

    await put(SettingsKeys.monthlyNetIncome,
        DefaultTargets.monthlyNetIncome.toString());
    await put(SettingsKeys.targetSurplusLow,
        DefaultTargets.targetSurplusLow.toString());
    await put(SettingsKeys.targetSurplusHigh,
        DefaultTargets.targetSurplusHigh.toString());
    await put(SettingsKeys.rothIraAnnualTarget,
        DefaultTargets.rothIraAnnualTarget.toString());
    await put(SettingsKeys.rothIraContributed, '0');
    await put(SettingsKeys.brokerageBalance, '0');
    await put(SettingsKeys.savingsBalance, '0');
    await put(SettingsKeys.philosophyText,
        'Money = scoreboard · Curiosity = engine · Freedom = goal');
  }

  Future<void> _seedBudgetCategories(DateTime at) async {
    final count = await _db.select(_db.budgetCategories).get();
    if (count.isNotEmpty) return;
    var order = 0;
    for (final (name, target, flag) in DefaultTargets.budgetCategories) {
      await _db.into(_db.budgetCategories).insert(BudgetCategory(
            id: _uuid.v4(),
            name: name,
            monthlyTarget: target,
            flagType: flag,
            sortOrder: order++,
            createdAt: at,
            updatedAt: at,
          ));
    }
  }

  Future<void> _seedTimeBudgets() async {
    final count = await _db.select(_db.timeBudgets).get();
    if (count.isNotEmpty) return;
    var order = 0;
    for (final (name, kind, hours) in DefaultTargets.weeklyTimeBudgets) {
      await _db.into(_db.timeBudgets).insert(TimeBudget(
            id: _uuid.v4(),
            name: name,
            kind: kind,
            weeklyTargetHours: hours,
            sortOrder: order++,
          ));
    }
  }

  Future<void> _seedHabits(DateTime at) async {
    final count = await _db.select(_db.habits).get();
    if (count.isNotEmpty) return;
    var order = 0;
    for (final (name, type, unit) in DefaultTargets.habits) {
      await _db.into(_db.habits).insert(Habit(
            id: _uuid.v4(),
            name: name,
            type: type,
            unit: unit,
            sortOrder: order++,
            isArchived: false,
            createdAt: at,
          ));
    }
  }

  Future<void> _seedReminders(DateTime at) async {
    final count = await _db.select(_db.reminders).get();
    if (count.isNotEmpty) return;
    for (final (title, type, hour, minute) in DefaultTargets.reminders) {
      final id = _uuid.v4();
      await _db.into(_db.reminders).insert(Reminder(
            id: id,
            title: title,
            message: ReminderTemplates.defaultMessageFor(type),
            type: type,
            hour: hour,
            minute: minute,
            enabled: true,
            notificationId: notificationIdFor(id),
            createdAt: at,
            updatedAt: at,
          ));
    }
  }

  Future<void> _seedCountdowns(DateTime at) async {
    final count = await _db.select(_db.countdowns).get();
    if (count.isNotEmpty) return;
    final entries = <(String, String?, String?)>[
      ('Age 28 lock-in', null, 'age28'),
      ('End of current year', null, 'endOfYear'),
      ('End of current month', null, 'endOfMonth'),
      ('Roth IRA contribution deadline', null, 'rothIraDeadline'),
      (
        'Lease renewal',
        AppDateUtils.dateKey(DateTime(at.year + 1, at.month, 1)),
        null
      ),
      (
        'Kaizen milestone deadline',
        AppDateUtils.dateKey(AppDateUtils.dateOnly(at).add(const Duration(days: 90))),
        null
      ),
    ];
    var order = 0;
    for (final (title, date, key) in entries) {
      await _db.into(_db.countdowns).insert(Countdown(
            id: _uuid.v4(),
            title: title,
            targetDate: date,
            dynamicKey: key,
            sortOrder: order++,
          ));
    }
  }

  Future<void> _seedIdentity() async {
    final count = await _db.select(_db.identityStatements).get();
    if (count.isNotEmpty) return;
    var order = 0;
    for (final statement in DefaultTargets.identityStatements) {
      await _db.into(_db.identityStatements).insert(IdentityStatement(
            id: _uuid.v4(),
            content: statement,
            sortOrder: order++,
          ));
    }
  }

  Future<void> _seedFreedomTarget(DateTime at) async {
    final count = await _db.select(_db.freedomTargets).get();
    if (count.isNotEmpty) return;
    await _db.into(_db.freedomTargets).insert(FreedomTarget(
          id: _uuid.v4(),
          title: DefaultTargets.defaultFreedomTargetTitle,
          description: DefaultTargets.defaultFreedomTargetDescription,
          targetMonthlyPassiveIncome:
              DefaultTargets.defaultTargetMonthlyPassiveIncome,
          targetLiquidNetWorth: DefaultTargets.defaultTargetLiquidNetWorth,
          currentMonthlyPassiveIncome: 0,
          currentLiquidNetWorth: 0,
          targetDate: null,
          createdAt: at,
          updatedAt: at,
        ));
  }

  Future<void> _seedGrowthMetric(DateTime at) async {
    final count = await _db.select(_db.growthMetrics).get();
    if (count.isNotEmpty) return;
    await _db.into(_db.growthMetrics).insert(GrowthMetric(
          id: _uuid.v4(),
          name: DefaultTargets.defaultGrowthMetricName,
          unit: DefaultTargets.defaultGrowthMetricUnit,
          currentValue: 0,
          weeklyTarget: DefaultTargets.defaultGrowthMetricWeeklyTarget,
          isActive: true,
          createdAt: at,
          updatedAt: at,
        ));
  }
}
