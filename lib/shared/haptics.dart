import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One vocabulary of touch feedback for the whole app.
///
/// light  = check-ins, toggles, completions
/// select = segmented controls, choices, tab changes
/// medium = saves, verdicts, destructive confirms
///
/// Safe no-ops where haptics aren't supported (web/desktop).
class Haptics {
  Haptics._();

  static void light() => _run(HapticFeedback.lightImpact);

  static void select() => _run(HapticFeedback.selectionClick);

  static void medium() => _run(HapticFeedback.mediumImpact);

  static void _run(Future<void> Function() feedback) {
    if (kIsWeb) return;
    try {
      feedback();
    } catch (_) {
      // Haptics are a garnish — never let them throw.
    }
  }
}
