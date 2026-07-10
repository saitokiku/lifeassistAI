import 'package:drift/drift.dart';

import '../../../core/storage/app_database.dart';

/// One search hit, ready to render and navigate.
class SearchHit {
  const SearchHit({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.group,
  });

  final String title;
  final String subtitle;
  final String route;
  final String group;
}

/// Case-insensitive LIKE search across everything the user has written:
/// transactions, ideas, milestones, habits, reminders, time notes, and
/// principles. Local, instant, no index needed at this scale.
class SearchRepository {
  SearchRepository(this._db);

  final AppDatabase _db;

  Future<List<SearchHit>> search(String query, {int perGroup = 5}) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final needle = '%${q.replaceAll('%', '').replaceAll('_', '')}%';

    final hits = <SearchHit>[];

    final transactions = await (_db.select(_db.transactionEntries)
          ..where((t) => t.description.like(needle))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(perGroup))
        .get();
    hits.addAll([
      for (final t in transactions)
        SearchHit(
          title: t.description.isEmpty ? 'Transaction' : t.description,
          subtitle: '${t.date} · \$${t.amount.toStringAsFixed(2)}',
          route: '/money',
          group: 'Transactions',
        ),
    ]);

    final ideas = await (_db.select(_db.parkedIdeas)
          ..where((t) => t.title.like(needle) | t.description.like(needle))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(perGroup))
        .get();
    hits.addAll([
      for (final i in ideas)
        SearchHit(
          title: i.title,
          subtitle: 'Idea · ${i.decision}',
          route: '/ideas',
          group: 'Ideas',
        ),
    ]);

    final milestones = await (_db.select(_db.goals)
          ..where((t) => t.title.like(needle))
          ..limit(perGroup))
        .get();
    hits.addAll([
      for (final m in milestones)
        SearchHit(
          title: m.title,
          subtitle: m.isDone ? 'Milestone · done' : 'Milestone',
          route: '/focus',
          group: 'Milestones',
        ),
    ]);

    final habits = await (_db.select(_db.habits)
          ..where((t) => t.name.like(needle))
          ..limit(perGroup))
        .get();
    hits.addAll([
      for (final h in habits)
        SearchHit(
          title: h.name,
          subtitle: h.isArchived ? 'Habit · archived' : 'Habit',
          route: '/habits',
          group: 'Habits',
        ),
    ]);

    final reminders = await (_db.select(_db.reminders)
          ..where((t) => t.title.like(needle) | t.message.like(needle))
          ..limit(perGroup))
        .get();
    hits.addAll([
      for (final r in reminders)
        SearchHit(
          title: r.title,
          subtitle: 'Reminder',
          route: '/reminders',
          group: 'Reminders',
        ),
    ]);

    final blocks = await (_db.select(_db.timeBlocks)
          ..where((t) => t.note.like(needle))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(perGroup))
        .get();
    hits.addAll([
      for (final b in blocks)
        SearchHit(
          title: b.note ?? 'Time entry',
          subtitle: '${b.date} · ${b.hours}h',
          route: '/time',
          group: 'Time notes',
        ),
    ]);

    final statements = await (_db.select(_db.identityStatements)
          ..where((t) => t.content.like(needle))
          ..limit(perGroup))
        .get();
    hits.addAll([
      for (final s in statements)
        SearchHit(
          title: s.content,
          subtitle: 'Principle',
          route: '/more',
          group: 'Principles',
        ),
    ]);

    return hits;
  }
}
