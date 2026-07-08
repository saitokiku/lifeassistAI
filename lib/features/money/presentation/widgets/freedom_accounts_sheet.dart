import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../application/money_controller.dart';
import '../../domain/monthly_money_snapshot.dart';
import 'money_field.dart';
import 'money_snacks.dart';

/// Edit the manual balances: Roth IRA target and contributions, brokerage,
/// savings.
class FreedomAccountsSheet extends ConsumerStatefulWidget {
  const FreedomAccountsSheet({super.key, required this.snapshot});

  final MonthlyMoneySnapshot snapshot;

  static Future<void> show(
    BuildContext context, {
    required MonthlyMoneySnapshot snapshot,
  }) =>
      showAppSheet<void>(
        context,
        builder: (_) => FreedomAccountsSheet(snapshot: snapshot),
      );

  @override
  ConsumerState<FreedomAccountsSheet> createState() =>
      _FreedomAccountsSheetState();
}

class _FreedomAccountsSheetState extends ConsumerState<FreedomAccountsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _target = TextEditingController(
      text: Formatters.number(widget.snapshot.rothIraAnnualTarget,
          maxDecimals: 2));
  late final _contributed = TextEditingController(
      text: Formatters.number(widget.snapshot.rothIraContributed,
          maxDecimals: 2));
  late final _brokerage = TextEditingController(
      text: Formatters.number(widget.snapshot.brokerageBalance,
          maxDecimals: 2));
  late final _savings = TextEditingController(
      text:
          Formatters.number(widget.snapshot.savingsBalance, maxDecimals: 2));

  @override
  void dispose() {
    _target.dispose();
    _contributed.dispose();
    _brokerage.dispose();
    _savings.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(moneyControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await controller.setRothIra(
        annualTarget: Validators.parseNumber(_target.text),
        contributed: Validators.parseNumber(_contributed.text),
      );
      await controller.setBalances(
        brokerage: Validators.parseNumber(_brokerage.text),
        savings: Validators.parseNumber(_savings.text),
      );
    } catch (_) {
      // Stay open so nothing typed is lost.
      showFailedSnack(messenger, "That didn't save. Try again.");
      return;
    }
    Haptics.medium();
    navigator.pop();
    showSavedSnack(messenger, 'Saved.');
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Freedom accounts',
      subtitle: 'Manual balances. A monthly nudge keeps them honest.',
      footer: AppSheetButton(label: 'Save', onPressed: _save),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoneyField(
                label: 'Roth IRA annual target',
                controller: _target,
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Target'),
              ),
              const SizedBox(height: AppSpace.md),
              MoneyField(
                label: 'Roth IRA contributed this year',
                controller: _contributed,
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Contributed'),
              ),
              const SizedBox(height: AppSpace.md),
              MoneyField(
                label: 'Brokerage balance',
                controller: _brokerage,
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Balance'),
              ),
              const SizedBox(height: AppSpace.md),
              MoneyField(
                label: 'Savings balance',
                controller: _savings,
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Balance'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
