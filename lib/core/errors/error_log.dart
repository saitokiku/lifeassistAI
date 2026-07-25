import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One recorded failure.
@immutable
class LoggedError {
  const LoggedError({
    required this.at,
    required this.where,
    required this.message,
  });

  final DateTime at;

  /// Short call-site label, e.g. `habits.toggle` or `backup.import`.
  final String where;

  /// The cause, as reported. Never contains user content — see
  /// [ErrorLog.record].
  final String message;

  String get line =>
      '${at.toIso8601String().split('.').first}  $where  $message';
}

/// An in-memory ring of recent failures, so the app can say *what* went
/// wrong instead of only *that* something did.
///
/// The app has ~100 `catch (_)` sites that collapse every cause into one
/// friendly sentence, and exactly one `debugPrint` in release code. That
/// is invisible-by-construction: no analytics (deliberately), no crash
/// reporter, no log — so no defect could ever be observed, reported, or
/// diagnosed. This is the smallest honest fix that keeps the privacy
/// stance intact:
///
/// * **On-device only.** Nothing is transmitted. There is no uploader.
/// * **Memory only.** The ring dies with the process; nothing is
///   written to disk to be recovered later.
/// * **Causes, not content.** Callers pass exception text, never user
///   data. [record] additionally truncates.
///
/// Settings → Data → Diagnostics shows the ring and offers to copy it,
/// so a user reporting a problem can paste something useful.
class ErrorLog {
  ErrorLog._();

  static final ErrorLog instance = ErrorLog._();

  /// Recent enough to diagnose a session, small enough to stay cheap.
  static const int capacity = 50;

  /// Guards against a runaway message dominating the ring.
  static const int maxMessageLength = 300;

  final Queue<LoggedError> _entries = Queue<LoggedError>();

  /// Newest first.
  List<LoggedError> get entries => _entries.toList().reversed.toList();

  bool get isEmpty => _entries.isEmpty;

  void clear() => _entries.clear();

  /// Records [error] against a short [where] label. Safe to call from
  /// any catch block; never throws.
  void record(String where, Object? error, {DateTime? at}) {
    try {
      var message = error?.toString() ?? 'unknown';
      if (message.length > maxMessageLength) {
        message = '${message.substring(0, maxMessageLength)}…';
      }
      _entries.addLast(LoggedError(
        at: at ?? DateTime.now(),
        where: where,
        message: message,
      ));
      while (_entries.length > capacity) {
        _entries.removeFirst();
      }
      if (kDebugMode) debugPrint('[$where] $message');
    } catch (_) {
      // Logging must never be the thing that breaks.
    }
  }

  /// The whole ring as pasteable text.
  String asText() => entries.map((e) => e.line).join('\n');
}

/// Convenience for catch blocks: `catch (e) { logError('where', e); }`.
void logError(String where, Object? error) =>
    ErrorLog.instance.record(where, error);

final errorLogProvider = Provider<ErrorLog>((ref) => ErrorLog.instance);
