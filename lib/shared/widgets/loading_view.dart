import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// Centered loading indicator used while streams warm up.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}

/// Card-shaped shimmer placeholder for list screens while data warms up.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 96});

  final double height;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.elevated,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
    );
  }
}

/// A column of [SkeletonCard]s sized like a typical screen.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpace.screen),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpace.cardGap),
      itemBuilder: (_, index) => SkeletonCard(height: index == 0 ? 140 : 96),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          final dx = (_controller.value * 2 - 0.5) * bounds.width;
          return LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ).createShader(bounds.shift(Offset(dx, 0)));
        },
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Success feedback: quiet toast with a check.
void showSuccessSnack(BuildContext context, String message) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 18, color: AppColors.aligned),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textPrimaryDark),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Error feedback: human copy, never raw exceptions.
void showErrorSnack(BuildContext context, String message) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 18, color: AppColors.critical),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textPrimaryDark),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Feedback with an inline undo — the app's alternative to blocking
/// confirmations for cheap, reversible actions.
void showUndoSnack(
  BuildContext context,
  String message, {
  required VoidCallback onUndo,
}) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(
          message,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppColors.textPrimaryDark),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primaryBright,
          onPressed: onUndo,
        ),
      ),
    );
}
