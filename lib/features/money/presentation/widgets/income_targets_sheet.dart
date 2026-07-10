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

/// Edit net income and the surplus band the month is judged against.
class IncomeTargetsSheet extends ConsumerStatefulWidget {
  const IncomeTargetsSheet({super.key, required this.snapshot});

  final MonthlyMoneySnapshot snapshot;

  static Future<void> show(
    BuildContext context, {
    required MonthlyMoneySnapshot snapshot,
  }) =>
      showAppSheet<void>(
        context,
        builder: (_) => IncomeTargetsSheet(snapshot: snapshot),
      );

  @override
  ConsumerState<IncomeTargetsSheet> createState() => _IncomeTargetsSheetState();
}

class _IncomeTargetsSheetState extends ConsumerState<IncomeTargetsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _income = TextEditingController(
      text:
          Formatters.number(widget.snapshot.monthlyNetIncome, maxDecimals: 2));
  late final _low = TextEditingController(
      text:
          Formatters.number(widget.snapshot.targetSurplusLow, maxDecimals: 2));
  late final _high = TextEditingController(
      text:
          Formatters.number(widget.snapshot.targetSurplusHigh, maxDecimals: 2));

  @override
  void dispose() {
    _income.dispose();
    _low.dispose();
    _high.dispose();
    super.dispose();
  }

  String? _validateHigh(String? value) {
    final base = Validators.number(value, label: 'High target');
    if (base != null) return base;
    final low = Validators.tryParseNumber(_low.text);
    if (low != null && double.parse(value!.trim()) < low) {
      return "High target can't be under the low one.";
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(moneyControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await controller
          .setMonthlyNetIncome(Validators.parseNumber(_income.text));
      await controller.setTargetSurplus(
        low: Validators.parseNumber(_low.text),
        high: Validators.parseNumber(_high.text),
      );
    } catch (_) {
      // Stay open; nothing was thrown away.
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
      title: 'Income & targets',
      subtitle: 'The surplus band this month is judged against.',
      footer: AppSheetButton(label: 'Save', onPressed: _save),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoneyField(
                label: 'Net monthly income',
                controller: _income,
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Income'),
              ),
              const SizedBox(height: AppSpace.md),
              MoneyField(
                label: 'Low surplus target',
                controller: _low,
                validator: (v) => Validators.number(v, label: 'Low target'),
              ),
              const SizedBox(height: AppSpace.md),
              MoneyField(
                label: 'High surplus target',
                controller: _high,
                validator: _validateHigh,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
