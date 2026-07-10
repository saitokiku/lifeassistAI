import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/layout/responsive_scaffold.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/stat_tile.dart';
import '../application/ideas_controller.dart';
import 'widgets/idea_capture_form.dart';
import 'widgets/idea_parking_lot_list.dart';

/// Ideas — the anti-diffusion parking lot. Shiny things get parked,
/// cooled for a week, then given one decision. Focus stays clean.
class IdeasScreen extends ConsumerWidget {
  const IdeasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // ideasStateProvider collapses loading and error into null; watching
    // the stream's AsyncValue directly keeps a dead stream from posing
    // as an eternal spinner.
    final ideasAsync = ref.watch(ideasProvider);
    final state = ref.watch(ideasStateProvider);

    final Widget body;
    if (state == null) {
      body = ideasAsync.hasError
          ? ErrorState(
              title: "The lot didn't load.",
              message: 'Your ideas are safe. Give it another try.',
              onRetry: () => ref.invalidate(ideasProvider),
            )
          : const SkeletonList();
    } else {
      body = ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.lg,
            AppSpace.screen,
            96,
          ),
          children: [
            Row(
              children: [
                const ScreenBackButton(),
                Text('Ideas', style: theme.textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              AppCopy.ideasTagline,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (state.ideas.isNotEmpty) ...[
              const SizedBox(height: AppSpace.xl),
              _LotTiles(
                due: state.dueForReview.length,
                cooling: state.cooling.length,
              ),
            ],
            IdeaParkingLotList(state: state),
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: state == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => IdeaCaptureForm.show(context),
              icon: const Icon(Icons.add),
              label: const Text('Park idea'),
            ),
      body: SafeArea(child: body),
    );
  }
}

/// The two numbers that matter: verdicts owed (actionable, watch-tinted
/// when any) and ideas still cooling.
class _LotTiles extends StatelessWidget {
  const _LotTiles({required this.due, required this.cooling});

  final int due;
  final int cooling;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpace.cardGap;
        final tileWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: tileWidth,
              child: StatTile(
                label: 'Due for verdict',
                value: '$due',
                caption: due > 0 ? 'verdicts owed' : 'all clear',
                icon: Icons.gavel_rounded,
                level: due > 0 ? StatusLevel.watch : StatusLevel.neutral,
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: StatTile(
                label: 'Cooling',
                value: '$cooling',
                caption: cooling > 0 ? 'parked, not chased' : 'none right now',
                icon: Icons.ac_unit_rounded,
                level: StatusLevel.neutral,
              ),
            ),
          ],
        );
      },
    );
  }
}
