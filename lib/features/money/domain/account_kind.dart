import 'package:flutter/material.dart';

/// Kinds of tracked financial accounts.
enum AccountKind {
  checking,
  savings,
  credit,
  investment,
  cash,
  other;

  static AccountKind parse(String raw) => values.firstWhere(
        (k) => k.name == raw,
        orElse: () => AccountKind.other,
      );

  String get label => switch (this) {
        AccountKind.checking => 'Checking',
        AccountKind.savings => 'Savings',
        AccountKind.credit => 'Credit card',
        AccountKind.investment => 'Investment',
        AccountKind.cash => 'Cash',
        AccountKind.other => 'Other',
      };

  IconData get icon => switch (this) {
        AccountKind.checking => Icons.account_balance_outlined,
        AccountKind.savings => Icons.savings_outlined,
        AccountKind.credit => Icons.credit_card_outlined,
        AccountKind.investment => Icons.trending_up_rounded,
        AccountKind.cash => Icons.payments_outlined,
        AccountKind.other => Icons.account_balance_wallet_outlined,
      };

  /// Credit balances are owed money: they subtract from net worth.
  bool get countsNegative => this == AccountKind.credit;

  double signedBalance(double balance) =>
      countsNegative ? -balance : balance;
}
