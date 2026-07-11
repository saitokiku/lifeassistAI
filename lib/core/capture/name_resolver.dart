/// Case-insensitive spoken-name → id resolution ("groceries" → category id).
/// Exact match first, then unique prefix, then unique contains; null when
/// ambiguous or unknown so callers fall back to "unprefilled" rather than
/// guessing. Shared by the capture bus and the Siri queue drain.
String? resolveByName(String? spoken, Map<String, String> idToName) {
  if (spoken == null || spoken.trim().isEmpty) return null;
  final needle = spoken.trim().toLowerCase();
  String? exact, prefix, contains;
  var prefixCount = 0, containsCount = 0;
  for (final entry in idToName.entries) {
    final name = entry.value.toLowerCase();
    if (name == needle) {
      exact = entry.key;
      break;
    }
    if (name.startsWith(needle)) {
      prefix = entry.key;
      prefixCount++;
    } else if (name.contains(needle)) {
      contains = entry.key;
      containsCount++;
    }
  }
  if (exact != null) return exact;
  if (prefixCount == 1) return prefix;
  if (prefixCount == 0 && containsCount == 1) return contains;
  return null;
}
