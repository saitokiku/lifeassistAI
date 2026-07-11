import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../capture/name_resolver.dart';
import '../constants/app_constants.dart';
import '../storage/app_database.dart';
import '../storage/seed_service.dart';
import '../utils/date_utils.dart';
import 'bridge_paths.dart';

/// Result of one drain pass, for UI feedback and notification re-syncing.
class DrainResult {
  const DrainResult({
    this.imported = 0,
    this.failed = 0,
    this.remindersChanged = false,
    this.cancelNotificationIds = const [],
  });

  final int imported;
  final int failed;
  final bool remindersChanged;

  /// Notification ids freed by undo tombstones — the caller cancels them
  /// (the drain itself owns no platform channels).
  final List<int> cancelNotificationIds;
}

/// Consumes `queue/pending/` — captures written by the Swift side (Siri
/// background intents; later widgets and controls) while the Flutter
/// engine wasn't running.
///
/// Idempotency: each record's UUID becomes the database row id and every
/// insert uses `insertOrIgnore`, so at-least-once file processing yields
/// exactly-once rows. A file is deleted only after its transaction
/// commits; a crash in between just re-runs a no-op insert next time.
///
/// Money amounts in queue records are INTEGER CENTS (`amountCents`) — the
/// contract is fixed even while the database still stores double dollars,
/// so nothing downstream ever bakes in floats.
///
/// Honesty rules carried over from the capture bus: unknown category →
/// saved uncategorized with the spoken name kept in the description;
/// unresolvable *required* references (time budget, habit) go to
/// `queue/failed/` and surface in Settings diagnostics — never guessed,
/// never silently dropped.
class CaptureQueueDrain {
  CaptureQueueDrain(this._db, this._paths);

  static const int recordVersion = 1;
  static const int failedCap = 20;

  /// The most recent pass in this process — lets the shell show one
  /// "Added from Siri" toast for a drain that ran during bootstrap.
  static DrainResult? lastResult;

  final AppDatabase _db;
  final BridgePaths _paths;

  bool _draining = false;

  Future<DrainResult> drain() async {
    if (_draining) return const DrainResult();
    _draining = true;
    try {
      final result = await _drain();
      lastResult = result;
      return result;
    } finally {
      _draining = false;
    }
  }

  Future<DrainResult> _drain() async {
    await _paths.ensureDirs();
    List<File> pendingIn(Directory dir) => !dir.existsSync()
        ? const []
        : dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList();

    // Records from before an App Group container move drain right along
    // with current ones (idempotent inserts make double-reads harmless).
    final files = [
      ...pendingIn(_paths.pendingDir),
      if (_paths.legacyPendingDir case final legacy?) ...pendingIn(legacy),
    ]..sort(
        (a, b) => a.path.split('/').last.compareTo(b.path.split('/').last),
      ); // epoch-prefixed names

    if (files.isEmpty) return const DrainResult();

    var imported = 0;
    var failed = 0;
    var remindersChanged = false;
    final cancelIds = <int>[];

    for (final file in files) {
      try {
        final record =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final v = record['v'];
        if (v is! int || v > recordVersion) {
          throw const FormatException('unknown record version');
        }
        final outcome = await _apply(record);
        switch (outcome) {
          case _Applied(:final wasReminder):
            imported++;
            remindersChanged = remindersChanged || wasReminder;
            await file.delete();
          case _Undone(:final freedNotificationIds, :final wasReminder):
            remindersChanged = remindersChanged || wasReminder;
            cancelIds.addAll(freedNotificationIds);
            await file.delete();
          case _Unresolvable(:final reason):
            failed++;
            await _moveToFailed(file, reason);
        }
      } catch (e) {
        failed++;
        await _moveToFailed(file, e.toString());
      }
    }

    return DrainResult(
      imported: imported,
      failed: failed,
      remindersChanged: remindersChanged,
      cancelNotificationIds: cancelIds,
    );
  }

  Future<_Outcome> _apply(Map<String, dynamic> record) async {
    final id = record['id'] as String?;
    final type = record['type'] as String?;
    final fields = (record['fields'] as Map?)?.cast<String, dynamic>() ?? {};
    if (id == null || id.isEmpty || type == null) {
      throw const FormatException('missing id or type');
    }
    // Swift writes ISO-8601 in UTC; convert before deriving a calendar
    // day or a 9 PM capture would date itself tomorrow.
    final createdAt = (DateTime.tryParse(record['createdAt'] as String? ?? '')
                ?? DateTime.now())
        .toLocal();
    final date = (DateTime.tryParse(fields['dateIso'] as String? ?? '') ??
            createdAt)
        .toLocal();

    switch (type) {
      case 'expense':
        final cents = fields['amountCents'];
        if (cents is! int || cents <= 0) {
          throw const FormatException('bad amountCents');
        }
        final categoryId = await _resolveCategory(
          fields['categoryId'] as String?,
          fields['categoryName'] as String?,
        );
        final spokenName = fields['categoryName'] as String?;
        final baseText = (fields['text'] as String? ?? '').trim();
        // Unknown category: keep the spoken name in the description so
        // nothing the user said is lost.
        final description = categoryId == null &&
                spokenName != null &&
                spokenName.trim().isNotEmpty &&
                !baseText.toLowerCase().contains(spokenName.toLowerCase())
            ? (baseText.isEmpty ? spokenName : '$baseText ($spokenName)')
            : baseText;
        await _db.into(_db.transactionEntries).insert(
              TransactionEntry(
                id: id,
                categoryId: categoryId,
                accountId: null,
                sourceRecurringId: null,
                date: AppDateUtils.dateKey(date),
                amountCents: cents,
                description: description,
                isIntentional: false,
                createdAt: createdAt,
              ),
              mode: InsertMode.insertOrIgnore,
            );
        return const _Applied();

      case 'time':
        final hours = (fields['hours'] as num?)?.toDouble();
        if (hours == null || hours <= 0 || hours > 24) {
          throw const FormatException('bad hours');
        }
        final budgetId = await _resolveBudget(
          fields['budgetId'] as String?,
          fields['budgetName'] as String?,
        );
        if (budgetId == null) {
          return const _Unresolvable('unknown time category');
        }
        await _db.into(_db.timeBlocks).insert(
              TimeBlock(
                id: id,
                budgetId: budgetId,
                date: AppDateUtils.dateKey(date),
                hours: hours,
                note: (fields['note'] as String?)?.trim(),
                createdAt: createdAt,
              ),
              mode: InsertMode.insertOrIgnore,
            );
        return const _Applied();

      case 'idea':
        final text = (fields['text'] as String? ?? '').trim();
        if (text.isEmpty) throw const FormatException('empty idea');
        await _db.into(_db.parkedIdeas).insert(
              ParkedIdea(
                id: id,
                title: text,
                description: null,
                category: null,
                whyTempting: null,
                potentialValue: null,
                dateCaptured: AppDateUtils.dateKey(createdAt),
                reviewDate: AppDateUtils.dateKey(createdAt
                    .add(const Duration(days: AppConstants.ideaCoolingDays))),
                decision: 'undecided',
                helpsMainGoal: false,
                createdAt: createdAt,
                updatedAt: createdAt,
              ),
              mode: InsertMode.insertOrIgnore,
            );
        return const _Applied();

      case 'reminder':
        final text = (fields['text'] as String? ?? '').trim();
        if (text.isEmpty) throw const FormatException('empty reminder');
        final notification =
            (record['notification'] as Map?)?.cast<String, dynamic>();
        final notificationId = notification?['id'] as int? ??
            SeedService.notificationIdFor(id);
        await _db.into(_db.reminders).insert(
              Reminder(
                id: id,
                title: text,
                message: '',
                type: 'custom',
                hour: fields['hour'] as int? ?? 9,
                minute: fields['minute'] as int? ?? 0,
                weekdays: 127,
                oneShotDate: (fields['oneShotDateIso'] as String?) == null
                    ? null
                    : AppDateUtils.dateKey(DateTime.parse(
                        fields['oneShotDateIso'] as String)),
                enabled: true,
                notificationId: notificationId,
                createdAt: createdAt,
                updatedAt: createdAt,
              ),
              mode: InsertMode.insertOrIgnore,
            );
        return const _Applied(wasReminder: true);

      case 'habitLog':
        final habitId = await _resolveHabit(
          fields['habitId'] as String?,
          fields['habitName'] as String?,
        );
        if (habitId == null) return const _Unresolvable('unknown habit');
        final key = AppDateUtils.dateKey(date);
        final existing = await (_db.select(_db.habitLogs)
              ..where((t) => t.habitId.equals(habitId) & t.date.equals(key)))
            .getSingleOrNull();
        if (existing == null) {
          await _db.into(_db.habitLogs).insert(
                HabitLog(
                  id: id,
                  habitId: habitId,
                  date: key,
                  value: (fields['value'] as num?)?.toDouble() ?? 1,
                  note: null,
                  source: 'siri',
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
        return const _Applied();

      case 'undo':
        return _undo(fields);

      default:
        throw FormatException('unknown type $type');
    }
  }

  /// Undo tombstone: removes the captured row (or the still-pending file)
  /// for `targetId`. Never touches anything the capture didn't create.
  Future<_Outcome> _undo(Map<String, dynamic> fields) async {
    final targetId = fields['targetId'] as String?;
    if (targetId == null || targetId.isEmpty) {
      throw const FormatException('undo without targetId');
    }

    // Not drained yet? Deleting the pending file is the whole undo.
    for (final file in _paths.pendingDir.listSync().whereType<File>()) {
      if (file.path.contains(targetId)) {
        await file.delete();
        return const _Undone();
      }
    }

    final freed = <int>[];
    var wasReminder = false;
    final reminder = await (_db.select(_db.reminders)
          ..where((t) => t.id.equals(targetId)))
        .getSingleOrNull();
    if (reminder != null) {
      freed.add(reminder.notificationId);
      wasReminder = true;
    }
    await (_db.delete(_db.transactionEntries)
          ..where((t) => t.id.equals(targetId)))
        .go();
    await (_db.delete(_db.timeBlocks)..where((t) => t.id.equals(targetId)))
        .go();
    await (_db.delete(_db.parkedIdeas)..where((t) => t.id.equals(targetId)))
        .go();
    await (_db.delete(_db.habitLogs)..where((t) => t.id.equals(targetId)))
        .go();
    await (_db.delete(_db.reminders)..where((t) => t.id.equals(targetId)))
        .go();
    return _Undone(freedNotificationIds: freed, wasReminder: wasReminder);
  }

  Future<String?> _resolveCategory(String? id, String? name) async {
    final rows = await _db.select(_db.budgetCategories).get();
    if (id != null && rows.any((c) => c.id == id)) return id;
    return resolveByName(name, {for (final c in rows) c.id: c.name});
  }

  Future<String?> _resolveBudget(String? id, String? name) async {
    final rows = await _db.select(_db.timeBudgets).get();
    if (id != null && rows.any((b) => b.id == id)) return id;
    return resolveByName(name, {for (final b in rows) b.id: b.name});
  }

  Future<String?> _resolveHabit(String? id, String? name) async {
    final rows = await (_db.select(_db.habits)
          ..where((t) => t.isArchived.equals(false)))
        .get();
    if (id != null && rows.any((h) => h.id == id)) return id;
    return resolveByName(name, {for (final h in rows) h.id: h.name});
  }

  Future<void> _moveToFailed(File file, String reason) async {
    try {
      final name = file.uri.pathSegments.last;
      // Keep the reason next to the payload for the diagnostics view.
      String contents;
      try {
        contents = await file.readAsString();
      } catch (_) {
        contents = '{}';
      }
      final annotated = File('${_paths.failedDir.path}/$name');
      await annotated.writeAsString(
        jsonEncode({'error': reason, 'raw': contents}),
        flush: true,
      );
      await file.delete();

      // Cap the graveyard: oldest out first.
      final failedFiles = _paths.failedDir
          .listSync()
          .whereType<File>()
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (var i = 0; i < failedFiles.length - failedCap; i++) {
        await failedFiles[i].delete();
      }
    } catch (_) {
      // Diagnostics must never break the drain.
    }
  }

  /// How many captures sit in `queue/failed/` (Settings diagnostics).
  static int failedCount(BridgePaths paths) {
    try {
      return paths.failedDir.listSync().whereType<File>().length;
    } catch (_) {
      return 0;
    }
  }

  /// Clears the failed graveyard (explicit user action in Settings).
  static Future<void> clearFailed(BridgePaths paths) async {
    try {
      for (final f in paths.failedDir.listSync().whereType<File>()) {
        await f.delete();
      }
    } catch (_) {}
  }
}

sealed class _Outcome {
  const _Outcome();
}

class _Applied extends _Outcome {
  const _Applied({this.wasReminder = false});
  final bool wasReminder;
}

class _Undone extends _Outcome {
  const _Undone({this.freedNotificationIds = const [], this.wasReminder = false});
  final List<int> freedNotificationIds;
  final bool wasReminder;
}

class _Unresolvable extends _Outcome {
  const _Unresolvable(this.reason);
  final String reason;
}
