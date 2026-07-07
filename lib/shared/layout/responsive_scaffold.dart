import 'package:flutter/material.dart';

/// Width breakpoint for switching between bottom bar and navigation rail.
const double kRailBreakpoint = 840;

/// Lays the body out with a rail on wide screens and a bottom bar on
/// compact ones. Navigation content is provided by the caller.
class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.body,
    required this.railBuilder,
    required this.bottomBarBuilder,
  });

  final Widget body;
  final WidgetBuilder railBuilder;
  final WidgetBuilder bottomBarBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kRailBreakpoint;
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                railBuilder(context),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          body: body,
          bottomNavigationBar: bottomBarBuilder(context),
        );
      },
    );
  }
}

/// Constrains page content on very wide windows so cards stay readable.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 760});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
