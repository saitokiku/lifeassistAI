import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/capture/capture_launcher.dart';
import '../core/capture/capture_request.dart';
import '../core/providers.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/focus/presentation/focus_screen.dart';
import '../features/habits/presentation/habits_screen.dart';
import '../features/ideas/presentation/ideas_screen.dart';
import '../features/money/presentation/money_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/reminders/presentation/reminders_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/time/presentation/time_screen.dart';
import '../features/you/presentation/you_screen.dart';
import '../shared/layout/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(preferencesProvider);

  return GoRouter(
    initialLocation: '/today',
    redirect: (context, state) {
      // A raw lifeassist:// URI can reach the router when the engine
      // forwards a platform deep link; normalize it onto /capture.
      if (state.uri.scheme == 'lifeassist') {
        return Uri(
          path: '/capture',
          queryParameters: state.uri.queryParameters,
        ).toString();
      }
      final path = state.uri.path;
      final onboarding = path == '/onboarding';
      if (!prefs.onboardingComplete && !onboarding) return '/onboarding';
      if (prefs.onboardingComplete && onboarding) return '/today';
      // Pre-v2 locations that may live in restored navigation state.
      if (path == '/dashboard') return '/today';
      if (path == '/kaizen') return '/focus';
      if (path == '/identity') return '/more';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // The capture bus: never builds a page. Parses the request into
      // pendingCaptureProvider and lands on the owning tab; AppShell
      // opens the prefilled sheet from there.
      GoRoute(
        path: '/capture',
        redirect: (context, state) {
          final request = CaptureRequest.fromUri(state.uri);
          if (request == null) return '/today';
          ref.read(pendingCaptureProvider.notifier).state = request;
          return CaptureLauncher.tabFor(request.type);
        },
      ),
      // Indexed-stack shell: each tab keeps its scroll position and state.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(shell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/today',
              builder: (context, state) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/focus',
              builder: (context, state) => const FocusScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/money',
              builder: (context, state) => const MoneyScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/time',
              builder: (context, state) => const TimeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/more',
              builder: (context, state) => const YouScreen(),
            ),
            GoRoute(
              path: '/habits',
              builder: (context, state) => const HabitsScreen(),
            ),
            GoRoute(
              path: '/ideas',
              builder: (context, state) => const IdeasScreen(),
            ),
            GoRoute(
              path: '/reminders',
              builder: (context, state) => const RemindersScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});
