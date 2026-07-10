import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../data/accounts_repository.dart';
import '../domain/account_kind.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>(
  (ref) => AccountsRepository(ref.watch(databaseProvider)),
);

final accountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountsRepositoryProvider).watchAccounts(),
);

/// Net worth across accounts marked included: assets positive, credit
/// balances negative. Null while accounts load.
final netWorthProvider = Provider<double?>((ref) {
  final accounts = ref.watch(accountsProvider).valueOrNull;
  if (accounts == null) return null;
  var total = 0.0;
  for (final a in accounts.where((a) => a.includeInNetWorth)) {
    total += AccountKind.parse(a.kind).signedBalance(a.balance);
  }
  return total;
});

/// One point of the net-worth trend: total across included accounts using
/// each account's latest snapshot at or before the date.
class NetWorthPoint {
  const NetWorthPoint({required this.date, required this.total});

  final DateTime date;
  final double total;
}

final _recentSnapshotsProvider = StreamProvider<List<BalanceSnapshot>>((ref) {
  final today = readToday(ref);
  return ref
      .watch(accountsRepositoryProvider)
      .watchRecentSnapshots(today: today);
});

/// Weekly net-worth trend over the trailing ~6 months (oldest first).
/// Empty until at least two distinct snapshot dates exist — a single dot
/// isn't a trend.
final netWorthHistoryProvider = Provider<List<NetWorthPoint>?>((ref) {
  final today = readToday(ref);
  final accounts = ref.watch(accountsProvider).valueOrNull;
  final snapshots = ref.watch(_recentSnapshotsProvider).valueOrNull;
  if (accounts == null || snapshots == null) return null;

  final included = {
    for (final a in accounts.where((a) => a.includeInNetWorth))
      a.id: AccountKind.parse(a.kind),
  };
  if (included.isEmpty) return const [];

  // date-sorted snapshots per included account
  final byAccount = <String, List<BalanceSnapshot>>{};
  for (final s in snapshots) {
    if (included.containsKey(s.accountId)) {
      byAccount.putIfAbsent(s.accountId, () => []).add(s);
    }
  }
  if (byAccount.isEmpty) return const [];

  final distinctDates = {for (final s in snapshots) s.date};
  if (distinctDates.length < 2) return const [];

  // Weekly sampling: every Monday in range plus today.
  final firstKey = distinctDates.reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
  final first = AppDateUtils.parseDateKey(firstKey);
  final points = <NetWorthPoint>[];
  var cursor = AppDateUtils.startOfWeek(first);
  final end = AppDateUtils.dateOnly(today);
  while (!cursor.isAfter(end)) {
    points.add(NetWorthPoint(
      date: cursor,
      total: _totalAt(cursor, byAccount, included),
    ));
    cursor = cursor.add(const Duration(days: 7));
  }
  if (points.isEmpty || points.last.date != end) {
    points.add(NetWorthPoint(
      date: end,
      total: _totalAt(end, byAccount, included),
    ));
  }
  return points;
});

double _totalAt(
  DateTime date,
  Map<String, List<BalanceSnapshot>> byAccount,
  Map<String, AccountKind> kinds,
) {
  final key = AppDateUtils.dateKey(date);
  var total = 0.0;
  for (final entry in byAccount.entries) {
    BalanceSnapshot? latest;
    for (final s in entry.value) {
      if (s.date.compareTo(key) <= 0) {
        latest = s;
      } else {
        break; // snapshots arrive date-ascending
      }
    }
    if (latest != null) {
      total += kinds[entry.key]!.signedBalance(latest.balance);
    }
  }
  return total;
}

class AccountsController {
  AccountsController(this._repo);

  final AccountsRepository _repo;

  Future<Account> createAccount({
    required String name,
    required AccountKind kind,
    required double balance,
    bool includeInNetWorth = true,
  }) =>
      _repo.createAccount(
        name: name,
        kind: kind.name,
        balance: balance,
        includeInNetWorth: includeInNetWorth,
      );

  Future<void> updateAccount(Account account, {required bool balanceChanged}) =>
      _repo.updateAccount(account, balanceChanged: balanceChanged);

  Future<void> setBalance(String accountId, double balance) =>
      _repo.setBalance(accountId, balance);

  Future<void> deleteAccount(String id) => _repo.deleteAccount(id);
}

final accountsControllerProvider = Provider<AccountsController>(
  (ref) => AccountsController(ref.watch(accountsRepositoryProvider)),
);
