import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dart face of the on-device Foundation Models bridge
/// (`ios/Runner/AiBridge.swift`, channel `lifeassist/ai`).
///
/// Availability is a first-class state, not an error: every AI surface in
/// the app watches [aiAvailabilityProvider] and renders NOTHING unless the
/// answer is [AiAvailability.available] — on any other device the app is
/// pixel-identical to the AI-free version. AI output is always a draft
/// the user confirms; nothing writes silently.
enum AiAvailability {
  available,
  deviceNotEligible,
  appleIntelligenceNotEnabled,
  modelNotReady,
  osTooOld,
  unsupportedPlatform;

  static AiAvailability parse(String? raw) => switch (raw) {
        'available' => AiAvailability.available,
        'deviceNotEligible' => AiAvailability.deviceNotEligible,
        'appleIntelligenceNotEnabled' =>
          AiAvailability.appleIntelligenceNotEnabled,
        'modelNotReady' => AiAvailability.modelNotReady,
        'osTooOld' => AiAvailability.osTooOld,
        _ => AiAvailability.unsupportedPlatform,
      };
}

/// One structured draft parsed from a casual utterance. Amounts are
/// integer cents by bridge contract.
class AiCaptureDraft {
  const AiCaptureDraft({
    required this.kind,
    this.amountCents,
    this.hours,
    this.text,
    this.categoryName,
    this.dateIso,
  });

  /// The only kinds the app knows how to route. `kind` arrives as a
  /// free-form model string (`@Guide` describes the vocabulary but
  /// doesn't enforce it), so anything outside this set is rejected
  /// here rather than falling through a `switch` default and quietly
  /// sending the user somewhere unrelated.
  static const kinds = {'expense', 'time', 'idea', 'reminder', 'habit'};

  final String kind; // one of [kinds]
  final int? amountCents;
  final double? hours;
  final String? text;
  final String? categoryName;

  /// `yyyy-MM-dd` when the utterance named a day ("coffee 4.50
  /// yesterday"), else null. Validated here so a malformed model date
  /// can't reach a form.
  final String? dateIso;

  static AiCaptureDraft? tryParse(Map<Object?, Object?> raw) {
    final kind = (raw['kind'] as String?)?.trim().toLowerCase();
    if (kind == null || !kinds.contains(kind)) return null;

    // Bound the numbers: a hallucinated magnitude must not reach cents
    // math or an hours field.
    final cents = raw['amountCents'] as int?;
    final hours = (raw['hours'] as num?)?.toDouble();
    final validCents =
        cents != null && cents > 0 && cents < 100000000 ? cents : null;
    final validHours = hours != null && hours.isFinite && hours > 0 &&
            hours <= 24
        ? hours
        : null;

    return AiCaptureDraft(
      kind: kind,
      amountCents: validCents,
      hours: validHours,
      text: raw['text'] as String?,
      categoryName: raw['categoryName'] as String?,
      dateIso: _validDateKey(raw['dateIso'] as String?),
    );
  }

  /// Accepts only a real `yyyy-MM-dd` within a year of today — the
  /// window any "yesterday"/"last Tuesday" phrasing can mean.
  static String? _validDateKey(String? raw, {DateTime? now}) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    final today = now ?? DateTime.now();
    final days = parsed.difference(today).inDays.abs();
    if (days > 366) return null;
    return '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
  }
}

class AiService {
  AiService({@visibleForTesting MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('lifeassist/ai');

  final MethodChannel _channel;

  /// Ceiling on any single on-device generation. The Swift side has no
  /// deadline of its own, so a stalled `session.respond` used to leave
  /// the UI spinning forever with no way out. Callers get null/empty
  /// and fall back to the deterministic path.
  static const Duration timeout = Duration(seconds: 20);

  /// Runs [work] under [timeout], turning both a stall and a platform
  /// error into [fallback]. Every generation call goes through here —
  /// these methods were the only channel calls in the app with no
  /// internal error handling, safe purely by call-site discipline.
  Future<T> _guard<T>(Future<T> Function() work, T fallback) async {
    try {
      return await work().timeout(timeout);
    } catch (_) {
      return fallback;
    }
  }

  Future<AiAvailability> availability() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return AiAvailability.unsupportedPlatform;
    }
    try {
      final raw = await _channel.invokeMethod<String>('availability');
      return AiAvailability.parse(raw);
    } catch (_) {
      return AiAvailability.unsupportedPlatform;
    }
  }

  /// "coffee 4.50 yesterday and 2h deep work" → structured drafts. The
  /// name lists constrain the model — it can only echo real names.
  Future<List<AiCaptureDraft>> parseCapture(
    String text, {
    required List<String> categoryNames,
    required List<String> timeBudgetNames,
    required List<String> habitNames,
  }) async {
    final raw = await _guard(
      () => _channel.invokeListMethod<Object?>('parseCapture', {
        'text': text,
        'categoryNames': categoryNames,
        'timeBudgetNames': timeBudgetNames,
        'habitNames': habitNames,
        'todayIso': DateTime.now().toIso8601String().substring(0, 10),
      }),
      null,
    );
    return [
      for (final item in raw ?? const [])
        if (item is Map<Object?, Object?>)
          if (AiCaptureDraft.tryParse(item) case final draft?) draft,
    ];
  }

  /// Suggests a category per imported row; only names from
  /// [categoryNames] ever come back (enforced Swift-side too).
  Future<Map<String, String>> categorizeTransactions(
    List<({String id, String description})> rows, {
    required List<String> categoryNames,
  }) async {
    if (rows.isEmpty || categoryNames.isEmpty) return const {};
    final suggestions = <String, String>{};
    // The on-device model has a small context — chunk the batch.
    for (var i = 0; i < rows.length; i += 20) {
      final chunk = rows.sublist(i, i + 20 > rows.length ? rows.length : i + 20);
      final raw = await _guard(
        () => _channel.invokeListMethod<Object?>('categorizeTransactions', {
          'rows': [
            for (final r in chunk) {'id': r.id, 'description': r.description},
          ],
          'categoryNames': categoryNames,
        }),
        null,
      );
      for (final item in raw ?? const []) {
        if (item is Map<Object?, Object?>) {
          final id = item['id'] as String?;
          final category = item['category'] as String?;
          if (id != null &&
              category != null &&
              categoryNames.contains(category)) {
            suggestions[id] = category;
          }
        }
      }
    }
    return suggestions;
  }

  /// Drafts a reflection from the week's real numbers; the user edits
  /// before anything saves.
  Future<String?> draftWeeklyReview(String stats) => _guard(
        () => _channel
            .invokeMethod<String>('draftWeeklyReview', {'stats': stats}),
        null,
      );

  Future<({String title, String whyTempting, String potentialValue})?>
      triageIdea(String text) async {
    final raw = await _guard(
      () => _channel
          .invokeMapMethod<Object?, Object?>('triageIdea', {'text': text}),
      null,
    );
    if (raw == null) return null;
    return (
      title: raw['title'] as String? ?? text,
      whyTempting: raw['whyTempting'] as String? ?? '',
      potentialValue: raw['potentialValue'] as String? ?? '',
    );
  }
}

final aiServiceProvider = Provider<AiService>((ref) => AiService());

/// Cached once per session; the UI treats anything but `available` as
/// "this feature does not exist".
final aiAvailabilityProvider = FutureProvider<AiAvailability>(
  (ref) => ref.watch(aiServiceProvider).availability(),
);
