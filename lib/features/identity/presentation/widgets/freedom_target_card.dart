import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_number_field.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/progress_bar_card.dart';
import '../../application/identity_controller.dart';
import '../../domain/freedom_target.dart';

/// Freedom target with progress and an inline editor.
class FreedomTargetCard extends ConsumerWidget {
  const FreedomTargetCard({super.key, required this.target});

  final FreedomTarget? target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = target;
    if (t == null) {
      return MetricCard(
        title: 'Freedom target',
        supportText: AppCopy.freedomGoal,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () => _showEditor(context, ref, null),
            child: const Text('Set freedom target'),
          ),
        ),
      );
    }

    return MetricCard(
      title: t.title,
      supportText: t.description ?? AppCopy.freedomGoal,
      trailing: TextButton(
        onPressed: () => _showEditor(context, ref, t),
        child: const Text('Edit'),
      ),
      child: Column(
        children: [
          LabeledProgressBar(
            progress: t.passiveIncomeProgress,
            color: AppColors.primary,
            leading:
                'Passive income · ${Formatters.money(t.currentMonthlyPassiveIncome)} / ${Formatters.money(t.targetMonthlyPassiveIncome)}/mo',
            trailing: Formatters.percent(t.passiveIncomeProgress),
          ),
          const SizedBox(height: 10),
          LabeledProgressBar(
            progress: t.netWorthProgress,
            color: AppColors.aligned,
            leading:
                'Liquid net worth · ${Formatters.money(t.currentLiquidNetWorth)} / ${Formatters.money(t.targetLiquidNetWorth)}',
            trailing: Formatters.percent(t.netWorthProgress),
          ),
        ],
      ),
    );
  }

  void _showEditor(BuildContext context, WidgetRef ref, FreedomTarget? t) {
    final title = TextEditingController(text: t?.title ?? 'Freedom number');
    final description = TextEditingController(text: t?.description ?? '');
    final passiveTarget = TextEditingController(
        text: t?.targetMonthlyPassiveIncome.toString() ?? '');
    final passiveCurrent = TextEditingController(
        text: t?.currentMonthlyPassiveIncome.toString() ?? '0');
    final worthTarget =
        TextEditingController(text: t?.targetLiquidNetWorth.toString() ?? '');
    final worthCurrent =
        TextEditingController(text: t?.currentLiquidNetWorth.toString() ?? '0');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Freedom target',
                    style: Theme.of(sheetContext).textTheme.titleMedium),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Title',
                  controller: title,
                  validator: (v) => Validators.required(v, label: 'Title'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                    label: 'Description', controller: description, maxLines: 2),
                const SizedBox(height: 12),
                AppNumberField(
                  label: 'Target monthly passive income',
                  controller: passiveTarget,
                  validator: (v) =>
                      Validators.nonNegativeNumber(v, label: 'Target'),
                ),
                const SizedBox(height: 12),
                AppNumberField(
                  label: 'Current monthly passive income',
                  controller: passiveCurrent,
                  validator: (v) =>
                      Validators.nonNegativeNumber(v, label: 'Current'),
                ),
                const SizedBox(height: 12),
                AppNumberField(
                  label: 'Target liquid net worth',
                  controller: worthTarget,
                  validator: (v) =>
                      Validators.nonNegativeNumber(v, label: 'Target'),
                ),
                const SizedBox(height: 12),
                AppNumberField(
                  label: 'Current liquid net worth',
                  controller: worthCurrent,
                  validator: (v) =>
                      Validators.nonNegativeNumber(v, label: 'Current'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final controller = ref.read(identityControllerProvider);
                    final navigator = Navigator.of(sheetContext);
                    final desc = description.text.trim().isEmpty
                        ? null
                        : description.text.trim();
                    if (t == null) {
                      await controller.createFreedomTarget(
                        title: title.text.trim(),
                        description: desc,
                        targetMonthlyPassiveIncome:
                            Validators.parseNumber(passiveTarget.text),
                        targetLiquidNetWorth:
                            Validators.parseNumber(worthTarget.text),
                      );
                    } else {
                      await controller.updateFreedomTarget(t.copyWith(
                        title: title.text.trim(),
                        description: Value(desc),
                        targetMonthlyPassiveIncome:
                            Validators.parseNumber(passiveTarget.text),
                        currentMonthlyPassiveIncome:
                            Validators.parseNumber(passiveCurrent.text),
                        targetLiquidNetWorth:
                            Validators.parseNumber(worthTarget.text),
                        currentLiquidNetWorth:
                            Validators.parseNumber(worthCurrent.text),
                      ));
                    }
                    navigator.pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
