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
      monthlyNetIncome: parse(
          SettingsKeys.monthlyNetIncome, DefaultTargets.monthlyNetIncome),
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
      dashboardAreas:
          DashboardArea.parseList(map[SettingsKeys.dashboardAreas]),
    );
  }

  Future<void> setValue(String key, String value) =>
      _db.into(_db.settingsEntries).insertOnConflictUpdate(
            SettingsEntry(key: key, value: value),
          );

  Future<void> setNumber(String key, double value) =>
      setValue(key, value.toString());

  Future<void> setBirthday(DateTime? birthday) => setValue(
        SettingsKeys.birthday,
        birthday == null ? '' : AppDateUtils.dateKey(birthday),
      );

  Future<void> removeValue(String key) =>
      (_db.delete(_db.settingsEntries)..where((t) => t.key.equals(key))).go();
}
