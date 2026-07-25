import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/formatters.dart';

/// Humanized day labels: 'Today', 'Yesterday', '3 days ago', then calendar
/// dates. Keeps raw ISO keys out of user-facing copy.
String relativeDayLabel(DateTime date, DateTime today) {
  final d = AppDateUtils.dateOnly(date);
  final t = AppDateUtils.dateOnly(today);
  final days = AppDateUtils.daysBetween(d, t);
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  return d.year == t.year ? Formatters.shortDate(d) : Formatters.fullDate(d);
}
