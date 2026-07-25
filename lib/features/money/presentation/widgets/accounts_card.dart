import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/quick_update_sheet.dart';
import '../../application/accounts_controller.dart';
import '../../domain/account_kind.dart';
import '../../../../core/utils/money.dart';
import 'account_editor.dart';

/// Tracked accounts and their net worth. Tap a row to punch in a fresh
/// balance (each update snapshots history); the pencil edits details.
class AccountsCard extends ConsumerWidget {
  const AccountsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accounts = ref.watch(accountsProvider).valueOrNull;
    final netWorth = ref.watch(netWorthProvider);
    final history = ref.watch(netWorthHistoryProvider) ?? const [];

    if (accounts == null) return const SizedBox.shrink();

    if (accounts.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Track your accounts', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpace.sm),
            Text(
              'Add each bank, card, and investment account once. Update '
              'balances when you check them — the app keeps the history '
              'and the net-worth math.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            FilledButton(
              onPressed: () => AccountEditor.show(context),
              child: const Text('Add an account'),
            ),
          ],
        ),
      );
    }

    final trendDelta = history.length >= 2
        ? history.last.total - history.first.total
        : null;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.lg,
        AppSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NET WORTH',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.brandLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      netWorth == null
                          ? '—'
                          : Formatters.moneySigned(netWorth),
                      style: theme.textTheme.headlineMedium,
                    ),
                    if (trendDelta != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${trendDelta >= 0 ? '+' : '−'}'
                        '${Formatters.moneyExact(trendDelta.abs())} over '
                        '${_spanLabel(history.length)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: trendDelta >= 0
                              ? AppColors.aligned
                              : AppColors.watch,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => AccountEditor.show(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          for (final (i, account) in accounts.indexed) ...[
            if (i > 0)
              const Divider(height: 1, indent: 40 + AppSpace.md),
            _AccountRow(account: account),
          ],
        ],
      ),
    );
  }

  String _spanLabel(int weeklyPoints) {
    final weeks = weeklyPoints - 1;
    if (weeks < 5) return '$weeks week${weeks == 1 ? '' : 's'}';
    final months = (weeks / 4.345).round();
    return '$months month${months == 1 ? '' : 's'}';
  }
}

class _AccountRow extends ConsumerWidget {
  const _AccountRow({required this.account});

  final Account account;

  Future<void> _updateBalance(BuildContext context, WidgetRef ref) {
    final controller = ref.read(accountsControllerProvider);
    return QuickUpdateSheet.show(
      context,
      title: account.name,
      subtitle: 'Current balance. Each update keeps a dated snapshot.',
      label: 'Balance',
      initialValue: amountFromCents(account.balanceCents),
      suffixText: r'$',
      validator: (v) => Validators.number(v, label: 'Balance'),
      onSave: (value) => controller.setBalance(account.id, value),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final kind = AccountKind.parse(account.kind);
    final excluded = !account.includeInNetWorth;

    return InkWell(
      onTap: () => _updateBalance(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primaryTint,
                borderRadius: BorderRadius.circular(AppRadius.chip + 2),
              ),
              child: Icon(kind.icon, size: 20, color: scheme.brandLabel),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    excluded
                        ? '${kind.label} · not in net worth'
                        : kind.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Text(
              kind.countsNegative
                  ? '−${Formatters.moneyExact(amountFromCents(account.balanceCents))}'
                  : Formatters.moneyExact(amountFromCents(account.balanceCents)),
              style: theme.textTheme.numberBody.copyWith(
                color: kind.countsNegative
                    ? AppColors.watch
                    : scheme.onSurface,
              ),
            ),
            IconButton(
              tooltip: 'Edit account',
              visualDensity: VisualDensity.compact,
              onPressed: () => AccountEditor.show(context, account: account),
              icon: Icon(
                Icons.edit_outlined,
                size: 16,
                color: scheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
