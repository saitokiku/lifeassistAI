import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_number_field.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/focus_controller.dart';
import '../../domain/growth_metric.dart';

/// Create or edit a progress measure — the number that shows the main goal
/// is actually moving.
///
/// When no measure is tracked yet, the active switch defaults ON so a first
/// measure never lands in a dead end. The currently-tracked measure shows a
/// locked switch — tracking moves by activating another measure.
class GrowthMetricEditor extends ConsumerStatefulWidget {
  const GrowthMetricEditor({super.key, this.metric});

  final GrowthMetric? metric;

  static Future<void> show(BuildContext context, {GrowthMetric? metric}) async {
    final message = await showAppSheet<String>(
      context,
      builder: (_) => GrowthMetricEditor(metric: metric),
    );
    if (message != null && context.mounted) {
      showSuccessSnack(context, message);
    }
  }

  @override
  ConsumerState<GrowthMetricEditor> createState() => _GrowthMetricEditorState();
}

class _GrowthMetricEditorState extends ConsumerState<GrowthMetricEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.metric?.name ?? '');
  late final _unit = TextEditingController(text: widget.metric?.unit ?? '');
  late final _target = TextEditingController(
    text: widget.metric == null
        ? ''
        : Formatters.number(widget.metric!.weeklyTarget),
  );
  late bool _makeActive;

  @override
  void initState() {
    super.initState();
    final hasTracked = ref.read(activeMetricProvider).valueOrNull != null;
    // First measure → default to active, never a dead end.
    _makeActive = widget.metric?.isActive ?? !hasTracked;
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(focusControllerProvider);
    final navigator = Navigator.of(context);
    final isNew = widget.metric == null;
    try {
      if (isNew) {
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
      Haptics.medium();
      navigator.pop(isNew ? 'Measure created.' : 'Saved.');
    } catch (_) {
      if (mounted) showErrorSnack(context, "That didn't save. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.metric == null;
    final isTracked = widget.metric?.isActive ?? false;

    return AppSheet(
      title: isNew ? 'New measure' : 'Edit measure',
      subtitle: 'One number that shows your goal is moving.',
      footer: AppSheetButton(label: 'Save', onPressed: _save),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Name',
                hint: 'e.g. Pages written, Pounds lost, Savings',
                controller: _name,
                validator: (v) => Validators.required(v, label: 'Name'),
                autofocus: isNew,
              ),
              const SizedBox(height: AppSpace.md),
              AppTextField(
                label: 'Unit',
                hint: r'pages, lbs, $, signups…',
                controller: _unit,
                validator: (v) => Validators.required(v, label: 'Unit'),
              ),
              const SizedBox(height: AppSpace.md),
              AppNumberField(
                label: 'Weekly target',
                controller: _target,
                validator: (v) =>
                    Validators.nonNegativeNumber(v, label: 'Target'),
              ),
              const SizedBox(height: AppSpace.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Track this measure'),
                subtitle: Text(
                  isTracked
                      ? 'Currently tracked. Activate another measure '
                          'to switch.'
                      : 'One measure is tracked at a time.',
                ),
                value: _makeActive,
                onChanged: isTracked
                    ? null
                    : (v) {
                        Haptics.select();
                        setState(() => _makeActive = v);
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
