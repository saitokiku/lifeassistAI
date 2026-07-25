import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/core/storage/app_database.dart';
import 'package:life_dashboard/features/money/data/recurring_repository.dart';

/// The materializer must never lose a month: a user who doesn't open
/// the app (or the Money tab) for a stretch comes back to a complete
/// ledger. Before the catch-up loop, skipped months were silently
/// dropped and the marker overwrite erased the evidence.
void main() {
  late AppDatabase db;
  late RecurringRepository repo;

  setUp(() {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    repo = RecurringRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<TransactionEntry>> entries() async =>
      (await db.select(db.transactionEntries).get())
        ..sort((a, b) => a.date.compareTo(b.date));

  Future<RecurringTransaction> row() async =>
      (await db.select(db.recurringTransactions).get()).single;

  test('a new recurring starts in the current month, not history', () async {
    await repo.createRecurring(
        amount: 1200, description: 'Rent', dayOfMonth: 1);
    final created = await repo.materialize(now: DateTime(2026, 4, 15));
    expect(created, 1);
    final all = await entries();
    expect(all.single.date, '2026-04-01');
    expect(all.single.amountCents, 120000);
    expect((await row()).lastMaterializedMonth, '2026-04');
  });

  test('months missed while the app was closed are all caught up',
      () async {
    await repo.createRecurring(
        amount: 1200, description: 'Rent', dayOfMonth: 1);
    await repo.materialize(now: DateTime(2026, 4, 15));

    // The app is not opened in May or June; next launch is July 10.
    final created = await repo.materialize(now: DateTime(2026, 7, 10));
    expect(created, 3, reason: 'May, June, and July must all land');
    expect(
      (await entries()).map((t) => t.date),
      ['2026-04-01', '2026-05-01', '2026-06-01', '2026-07-01'],
    );
    expect((await row()).lastMaterializedMonth, '2026-07');
  });

  test('the current month still waits for its day', () async {
    await repo.createRecurring(
        amount: 50, description: 'Gym', dayOfMonth: 20);
    await repo.materialize(now: DateTime(2026, 6, 25)); // June lands
    final created = await repo.materialize(now: DateTime(2026, 7, 10));
    expect(created, 0, reason: 'July 20 has not arrived on July 10');
    final later = await repo.materialize(now: DateTime(2026, 7, 25));
    expect(later, 1);
    expect((await entries()).last.date, '2026-07-20');
  });

  test('day-of-month clamps to short months during catch-up', () async {
    await repo.createRecurring(
        amount: 15, description: 'Sub', dayOfMonth: 31);
    await repo.materialize(now: DateTime(2026, 1, 31)); // Jan 31
    final created = await repo.materialize(now: DateTime(2026, 3, 31));
    expect(created, 2);
    expect(
      (await entries()).map((t) => t.date),
      ['2026-01-31', '2026-02-28', '2026-03-31'],
    );
  });

  test('idempotent: a second identical call creates nothing', () async {
    await repo.createRecurring(
        amount: 1200, description: 'Rent', dayOfMonth: 1);
    await repo.materialize(now: DateTime(2026, 7, 10));
    final again = await repo.materialize(now: DateTime(2026, 7, 10));
    expect(again, 0);
    expect(await entries(), hasLength(1));
  });

  test('a regressed marker cannot double-post: the ledger is checked too',
      () async {
    // A stale editor write-back (or a concurrent call) can regress
    // lastMaterializedMonth. The per-(recurring, month) lookup on
    // sourceRecurringId must still block a duplicate.
    await repo.createRecurring(
        amount: 1200, description: 'Rent', dayOfMonth: 1);
    await repo.materialize(now: DateTime(2026, 7, 10));

    await (db.update(db.recurringTransactions))
        .write(const RecurringTransactionsCompanion(
      lastMaterializedMonth: Value(null),
    ));

    final created = await repo.materialize(now: DateTime(2026, 7, 10));
    expect(created, 0, reason: 'July already has this recurring\'s entry');
    expect(await entries(), hasLength(1));
    expect((await row()).lastMaterializedMonth, '2026-07',
        reason: 'the marker re-advances without re-posting');
  });

  test('a corrupt marker falls back to the current month only', () async {
    await repo.createRecurring(
        amount: 10, description: 'Sub', dayOfMonth: 1);
    await (db.update(db.recurringTransactions))
        .write(const RecurringTransactionsCompanion(
      lastMaterializedMonth: Value('garbage'),
    ));
    final created = await repo.materialize(now: DateTime(2026, 7, 10));
    expect(created, 1);
    expect((await entries()).single.date, '2026-07-01');
  });

  test('backfill is capped, not unbounded', () async {
    await repo.createRecurring(
        amount: 10, description: 'Sub', dayOfMonth: 1);
    await (db.update(db.recurringTransactions))
        .write(const RecurringTransactionsCompanion(
      lastMaterializedMonth: Value('2010-01'),
    ));
    final created = await repo.materialize(now: DateTime(2026, 7, 10));
    expect(created, RecurringRepository.maxCatchUpMonths);
  });

  test('inactive rows never materialize', () async {
    await repo.createRecurring(
        amount: 10, description: 'Sub', dayOfMonth: 1);
    await (db.update(db.recurringTransactions))
        .write(const RecurringTransactionsCompanion(active: Value(false)));
    expect(await repo.materialize(now: DateTime(2026, 7, 10)), 0);
    expect(await entries(), isEmpty);
  });
}
