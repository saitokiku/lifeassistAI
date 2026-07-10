import 'package:drift/drift.dart';

import '../../../core/constants/default_targets.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/settings_keys.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/user_settings.dart';

/// Reads/writes the key-value settings table as a typed UserSettings.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Stream<UserSettings> watchSettings() =>
      _db.select(_db.settingsEntries).watch().map(_fromRows);

  Future<UserSettings> getSettings() async =>
      _fromRows(await _db.select(_db.settingsEntries).get());

  UserSettings _fromRows(List<SettingsEntry> rows) {
    final map = {for (final r in rows) r.key: r.value};
    double parse(String key, double fallback) =>
        double.tryParse(map[key] ?? '') ?? fallback;

    DateTime? birthday;
    final rawBirthday = map[SettingsKeys.birthday];
    if (rawBirthday != null && rawBirthday.isNotEmpty) {
      birthday = DateTime.tryParse(rawBirthday);
    }

    return UserSettings(
      displayName: map[SettingsKeys.displayName]?.trim() ?? '',
      monthlyNetIncome:
          parse(SettingsKeys.monthlyNetIncome, DefaultTargets.monthlyNetIncome),
      targetSurplusLow:
          parse(SettingsKeys.targetSurplusLow, DefaultTargets.targetSurplusLow),
      targetSurplusHigh: parse(
          SettingsKeys.targetSurplusHigh, DefaultTargets.targetSurplusHigh),
      birthday: birthday,
      retirementAnnualTarget: parse(SettingsKeys.retirementAnnualTarget,
          DefaultTargets.retirementAnnualTarget),
      retirementContributed: parse(SettingsKeys.retirementContributed, 0),
      brokerageBalance: parse(SettingsKeys.brokerageBalance, 0),
      savingsBalance: parse(SettingsKeys.savingsBalance, 0),
      philosophyText: map[SettingsKeys.philosophyText] ?? '',
      dashboardAreas: DashboardArea.parseList(map[SettingsKeys.dashboardAreas]),
      lastBackupAt: DateTime.tryParse(map[SettingsKeys.lastBackupAt] ?? ''),
    );
  }

  Future<void> setValue(String key, String value) =>
      _db.into(_db.settingsEntries).insertOnConflictUpdate(
            SettingsEntry(key: key, value: value),
          );

  Future<void> setNumber(String key, double value) =>
      setValue(key, value.toString());

  // --- Monthly income snapshots ---------------------------------------------
  // Surplus history reads the income that applied to each month instead of
  // retro-applying today's number to the past.

  /// `yyyy-MM`, zero-padded so string comparison equals date comparison.
  static String monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  /// Sets the configured income and snapshots it for the current month.
  Future<void> setMonthlyNetIncome(double value, {DateTime? now}) async {
    await setNumber(SettingsKeys.monthlyNetIncome, value);
    await setNumber(
      '${SettingsKeys.incomeForMonthPrefix}${monthKey(now ?? DateTime.now())}',
      value,
    );
  }

  /// Snapshots the current income for this month if no snapshot exists yet.
  /// Called every launch; check-before-write keeps re-runs write-free.
  Future<void> ensureIncomeSnapshot({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final key = '${SettingsKeys.incomeForMonthPrefix}${monthKey(at)}';
    final existing = await (_db.select(_db.settingsEntries)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    if (existing != null) return;
    final settings = await getSettings();
    if (settings.monthlyNetIncome <= 0) return; // nothing to snapshot yet
    await setValue(key, settings.monthlyNetIncome.toString());
  }

  /// Month key (`yyyy-MM`) → income snapshot for that month.
  Stream<Map<String, double>> watchIncomeSnapshots() =>
      (_db.select(_db.settingsEntries)
            ..where(
                (t) => t.key.like('${SettingsKeys.incomeForMonthPrefix}%')))
          .watch()
          .map((rows) => {
                for (final r in rows)
                  r.key.substring(SettingsKeys.incomeForMonthPrefix.length):
                      double.tryParse(r.value) ?? 0,
              });

  /// The snapshot that applied to [month]: the nearest one at or before it.
  /// Falls back to [fallback] (the configured income) when none exists.
  static double incomeForMonth(
    Map<String, double> snapshots,
    DateTime month,
    double fallback,
  ) {
    final key = monthKey(month);
    String? best;
    for (final k in snapshots.keys) {
      if (k.compareTo(key) <= 0 && (best == null || k.compareTo(best) > 0)) {
        best = k;
      }
    }
    return best == null ? fallback : snapshots[best]!;
  }

  Future<void> setBirthday(DateTime? birthday) => setValue(
        SettingsKeys.birthday,
        birthday == null ? '' : AppDateUtils.dateKey(birthday),
      );

  Future<void> removeValue(String key) =>
      (_db.delete(_db.settingsEntries)..where((t) => t.key.equals(key))).go();
}
