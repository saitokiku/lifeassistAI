import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../data/journal_repository.dart';

final journalRepositoryProvider = Provider<JournalRepository>(
  (ref) => JournalRepository(ref.watch(databaseProvider)),
);

/// Recent entries, newest first. Powers the journal screen and the You
/// hub caption.
final recentJournalProvider = StreamProvider<List<JournalEntry>>(
  (ref) => ref.watch(journalRepositoryProvider).watchRecent(),
);

/// Today's entries; re-created on day rollover. The evening Today card
/// uses this to say honestly whether the day is already written.
final todayJournalProvider = StreamProvider<List<JournalEntry>>((ref) {
  final today = readToday(ref);
  return ref
      .watch(journalRepositoryProvider)
      .watchForDate(AppDateUtils.dateKey(today));
});
