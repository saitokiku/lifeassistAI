import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What a deep link / shortcut / notification tap wants captured.
enum CaptureType {
  expense,
  time,
  step,
  idea,
  reminder;

  static CaptureType? tryParse(String raw) {
    for (final t in values) {
      if (t.name == raw) return t;
    }
    return null;
  }
}

/// A parsed `lifeassist://capture` request. Everything is optional except
/// the type — missing fields simply leave the sheet unprefilled.
class CaptureRequest {
  const CaptureRequest({
    required this.type,
    this.amount,
    this.hours,
    this.text,
    this.category,
    this.hour,
    this.minute,
  });

  final CaptureType type;
  final double? amount;
  final double? hours;

  /// Free text: expense description, step text, idea/reminder title.
  final String? text;

  /// Spoken/typed category or budget name, resolved case-insensitively.
  final String? category;
  final int? hour;
  final int? minute;

  /// Parses `lifeassist://capture?type=expense&amount=4.5&text=coffee` and
  /// the equivalent `/capture?...` route location. Returns null when the
  /// URI isn't a capture request.
  static CaptureRequest? fromUri(Uri uri) {
    final isScheme = uri.scheme == 'lifeassist' &&
        (uri.host == 'capture' || uri.path == '/capture');
    final isRoute = uri.scheme.isEmpty && uri.path == '/capture';
    if (!isScheme && !isRoute) return null;

    final q = uri.queryParameters;
    final type = CaptureType.tryParse(q['type'] ?? '');
    if (type == null) return null;

    return CaptureRequest(
      type: type,
      amount: double.tryParse(q['amount'] ?? ''),
      hours: double.tryParse(q['hours'] ?? ''),
      text: (q['text'] ?? q['title'])?.trim().isEmpty ?? true
          ? null
          : (q['text'] ?? q['title'])!.trim(),
      category: q['category']?.trim().isEmpty ?? true
          ? null
          : q['category']!.trim(),
      hour: int.tryParse(q['hour'] ?? ''),
      minute: int.tryParse(q['minute'] ?? ''),
    );
  }
}

/// The one pending capture the shell should open, if any. Deep links,
/// shortcuts, and notification taps write here; AppShell listens, opens
/// the matching sheet, and clears it.
final pendingCaptureProvider = StateProvider<CaptureRequest?>((ref) => null);

/// A pending route navigation from a notification tap (payloads like
/// `route:/money`). AppShell listens and go()es there.
final pendingRouteProvider = StateProvider<String?>((ref) => null);
