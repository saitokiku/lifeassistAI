import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';

/// Persistence for tracked accounts and their balance history.
///
/// Every balance write also upserts a dated snapshot (one per account per
/// day), so net worth has a real history instead of a single mutable
/// number.
class AccountsRepository {
  AccountsRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  Stream<List<Account>> watchAccounts() => (_db.select(_db.accounts)
        ..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.createdAt),
        ]))
      .watch();

  Future<List<Account>> getAccounts() => _db.select(_db.accounts).get();

  Future<Account> createAccount({
    required String name,
    required String kind,
    required double balance,
    bool includeInNetWorth = true,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final existing = await _db.select(_db.accounts).get();
    final account = Account(
      id: _uuid.v4(),
      name: name,
      kind: kind,
      balance: balance,
      includeInNetWorth: includeInNetWorth,
      sortOrder: existing.length,
      createdAt: at,
      updatedAt: at,
    );
    await _db.transaction(() async {
      await _db.into(_db.accounts).insert(account);
      await _upsertSnapshot(account.id, balance, at);
    });
    return account;
  }

  /// Updates metadata and, when the balance moved, records today's
  /// snapshot too.
  Future<void> updateAccount(Account account,
      {required bool balanceChanged, DateTime? now}) async {
    final at = now ?? DateTime.now();
    await _db.transaction(() async {
      await _db.update(_db.accounts).replace(account.copyWith(updatedAt: at));
      if (balanceChanged) {
        await _upsertSnapshot(account.id, account.balance, at);
      }
    });
  }

  /// The common quick action: set a new balance, snapshot it.
  Future<void> setBalance(String accountId, double balance,
      {DateTime? now}) async {
    final at = now ?? DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.accounts)..where((t) => t.id.equals(accountId)))
          .write(AccountsCompanion(
        balance: Value(balance),
        updatedAt: Value(at),
      ));
      await _upsertSnapshot(accountId, balance, at);
    });
  }

  Future<void> deleteAccount(String id) => _db.transaction(() async {
        await (_db.delete(_db.balanceSnapshots)
              ..where((t) => t.accountId.equals(id)))
            .go();
        // Transactions keep their rows; they just lose the account link.
        await (_db.update(_db.transactionEntries)
              ..where((t) => t.accountId.equals(id)))
            .write(const TransactionEntriesCompanion(
          accountId: Value(null),
        ));
        await (_db.delete(_db.accounts)..where((t) => t.id.equals(id))).go();
      });

  /// Snapshots for the trailing [sinceDays], oldest first, all accounts.
  Stream<List<BalanceSnapshot>> watchRecentSnapshots(
      {required DateTime today, int sinceDays = 190}) {
    final from =
        AppDateUtils.dateKey(today.subtract(Duration(days: sinceDays)));
    return (_db.select(_db.balanceSnapshots)
          ..where((t) => t.date.isBiggerOrEqualValue(from))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  Future<void> _upsertSnapshot(
      String accountId, double balance, DateTime at) async {
    final dateKey = AppDateUtils.dateKey(at);
    final existing = await (_db.select(_db.balanceSnapshots)
          ..where((t) => t.accountId.equals(accountId) & t.date.equals(dateKey)))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.balanceSnapshots)
            ..where((t) => t.id.equals(existing.id)))
          .write(BalanceSnapshotsCompanion(balance: Value(balance)));
    } else {
      await _db.into(_db.balanceSnapshots).insert(BalanceSnapshot(
            id: _uuid.v4(),
            accountId: accountId,
            date: dateKey,
            balance: balance,
          ));
    }
  }
}
