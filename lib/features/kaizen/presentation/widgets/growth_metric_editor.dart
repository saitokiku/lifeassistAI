import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_number_field.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/kaizen_controller.dart';

/// Create or edit a growth metric. Shown as a modal bottom sheet.
class GrowthMetricEditor extends ConsumerStatefulWidget {
  const GrowthMetricEditor({super.key, this.metric});

  final GrowthMetric? metric;

  static Future<void> show(BuildContext context, {GrowthMetric? metric}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => GrowthMetricEditor(metric: metric),
      );

  @override
  ConsumerState<GrowthMetricEditor> createState() => _GrowthMetricEditorState();
}

class _GrowthMetricEditorState extends ConsumerState<GrowthMetricEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.metric?.name ?? '');
  late final _unit = TextEditingController(text: widget.metric?.unit ?? '');
  late final _target = TextEditingController(
      text: widget.metric == null ? '' : widget.metric!.weeklyTarget.toString());
  late bool _makeActive = widget.metric?.isActive ?? false;

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(kaizenControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      if (widget.metric == null) {
        await controller.createMetric(
          name: _name.text.trim(),
          unit: _unit.text.trim(),
          weeklyTarget: Validators.parseNumber(_target.text),
          makeActive: _makeActive,
        );
      } else {
        await controller.updateMetric(widget.metric!.copyWith(
          name: _name.text.trim(),
          unit: _unit.text.trim(),
          weeklyTarget: Validators.parseNumber(_target.text),
        ));
        if (_makeActive && !widget.metric!.isActive) {
          await controller.setActiveMetric(widget.metric!.id);
        }
      }
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(widget.metric == null ? 'Metric created.' : 'Metric updated.'),
      ));
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save metric.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.metric == null ? 'New growth metric' : 'Edit growth metric',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Name',
              controller: _name,
              validator: (v) => Validators.required(v, label: 'Name'),
              autofocus: widget.metric == null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Unit (users, \$, signups...)',
              controller: _unit,
              validator: (v) => Validators.required(v, label: 'Unit'),
            ),
            const SizedBox(height: 12),
            AppNumberField(
              label: 'Weekly target',
              controller: _target,
              validator: (v) => Validators.nonNegativeNumber(v, label: 'Target'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active metric'),
              subtitle: const Text('Only one metric is the hunt at a time.'),
              value: _makeActive,
              onChanged: (v) => setState(() => _makeActive = v),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
