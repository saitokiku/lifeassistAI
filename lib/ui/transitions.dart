import 'package:flutter/material.dart';

/// The v2 route transition: an 8% slide-up with a fade, instead of the
/// platform defaults (Android's zoom, iOS's edge slide). Applied to
/// every platform through [ThemeData.pageTransitionsTheme] so pushed
/// routes share one motion signature on iPhone, the Fold, and web.
class InstrumentPageTransitionsBuilder extends PageTransitionsBuilder {
  const InstrumentPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final eased = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    // The page beneath dims slightly so depth reads without shadows.
    final underDim = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOut,
    );
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(eased),
        child: AnimatedBuilder(
          animation: underDim,
          builder: (context, child) => Opacity(
            opacity: 1 - underDim.value * 0.15,
            child: child,
          ),
          child: child,
        ),
      ),
    );
  }

  /// One theme entry per platform, all pointing at this builder.
  static PageTransitionsTheme get theme => const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: InstrumentPageTransitionsBuilder(),
          TargetPlatform.iOS: InstrumentPageTransitionsBuilder(),
          TargetPlatform.macOS: InstrumentPageTransitionsBuilder(),
          TargetPlatform.linux: InstrumentPageTransitionsBuilder(),
          TargetPlatform.windows: InstrumentPageTransitionsBuilder(),
          TargetPlatform.fuchsia: InstrumentPageTransitionsBuilder(),
        },
      );
}
