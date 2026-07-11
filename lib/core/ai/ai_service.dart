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

  final String kind; // expense | time | idea | reminder | habit
  final int? amountCents;
  final double? hours;
  final String? text;
  final String? categoryName;
  final String? dateIso;

  static AiCaptureDraft? tryParse(Map<Object?, Object?> raw) {
    final kind = raw['kind'] as String?;
    if (kind == null || kind.isEmpty) return null;
    return AiCaptureDraft(
      kind: kind,
      amountCents: raw['amountCents'] as int?,
      hours: (raw['hours'] as num?)?.toDouble(),
      text: raw['text'] as String?,
      categoryName: raw['categoryName'] as String?,
      dateIso: raw['dateIso'] as String?,
    );
  }
}

class AiService {
  AiService({@visibleForTesting MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('lifeassist/ai');

  final MethodChannel _channel;

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
    final raw = await _channel.invokeListMethod<Object?>('parseCapture', {
      'text': text,
      'categoryNames': categoryNames,
      'timeBudgetNames': timeBudgetNames,
      'habitNames': habitNames,
      'todayIso': DateTime.now().toIso8601String().substring(0, 10),
    });
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
      final raw = await _channel
          .invokeListMethod<Object?>('categorizeTransactions', {
        'rows': [
          for (final r in chunk) {'id': r.id, 'description': r.description},
        ],
        'categoryNames': categoryNames,
      });
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
  Future<String?> draftWeeklyReview(String stats) =>
      _channel.invokeMethod<String>('draftWeeklyReview', {'stats': stats});

  Future<({String title, String whyTempting, String potentialValue})?>
      triageIdea(String text) async {
    final raw = await _channel
        .invokeMapMethod<Object?, Object?>('triageIdea', {'text': text});
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
