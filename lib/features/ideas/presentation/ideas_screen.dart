import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/metric_card.dart';
import '../application/ideas_controller.dart';
import 'widgets/idea_capture_form.dart';
import 'widgets/idea_parking_lot_list.dart';

/// Ideas module: the anti-diffusion parking lot.
class IdeasScreen extends ConsumerWidget {
  const IdeasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ideasStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ideas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => IdeaCaptureForm.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Park idea'),
      ),
      body: state == null
          ? const LoadingView()
          : ContentWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  MetricCard(
                    title: 'Parking lot',
                    bigValue: '${state.parkedCount}',
                    supportText:
                        '${state.cooling.length} cooling · ${state.dueForReview.length} due for review · ${AppCopy.engineOneHunt}',
                  ),
                  const SizedBox(height: 4),
                  IdeaParkingLotList(state: state),
                ],
              ),
            ),
    );
  }
}
