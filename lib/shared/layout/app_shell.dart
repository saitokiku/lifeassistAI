import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capture/capture_launcher.dart';
import '../../core/capture/capture_request.dart';
import '../../ui/console_tab_bar.dart';
import '../../core/health/health_habit_sync.dart';
import '../../core/native/capture_queue_drain.dart';
import '../../core/native/entity_mirror_service.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../features/dashboard/application/dashboard_controller.dart';
import '../../features/habits/application/habits_controller.dart';
import '../../features/reminders/application/reminders_controller.dart';
import '../../features/settings/data/auto_backup_service.dart';
import '../../features/settings/data/backup_service.dart';
import 'adaptive_navigation.dart';
import 'responsive_scaffold.dart';

/// Shell around every top-level screen: rail on wide, bottom bar on compact.
///
/// Compact shows five tabs (Today · Focus · Money · Time · You) backed by
/// an indexed stack, so each tab keeps its scroll position and state.
///
/// The shell is also the capture bus terminal: deep links, app shortcuts,
/// and notification taps all funnel into [pendingCaptureProvider] /
/// [pendingRouteProvider], and this widget — which always has a live
/// context above the tabs — opens the matching sheet or route.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  StreamSubscription<Uri>? _linkSub;

  /// Captured at init so dispose() can unhook without touching ref.
  NotificationService? _notifications;

  /// The bootstrap-started mirror; the shell owns stopping it so its
  /// drift subscription is cancelled when the tree unmounts (tests,
  /// engine teardown) instead of living past the UI.
  EntityMirrorService? _mirror;

  /// The engine's deep-link navigation and the app_links stream can both
  /// deliver the same URI; remember the last one briefly to fire once.
  Uri? _lastUri;
  DateTime _lastUriAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    try {
      _mirror = ref.read(entityMirrorProvider);
    } catch (_) {
      // Web / tests without the bootstrap override: nothing to stop.
    }
    _wireCaptureSources();
    // The router's /capture redirect may have parked a request before this
    // widget existed (cold-start deep link) — drain it on first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _drainPending();
      _announceBootstrapDrain();
      // Weekly local safety copy; never blocks and never throws.
      AutoBackupService(
        BackupService(ref.read(databaseProvider)),
        ref.read(preferencesProvider),
      ).maybeRun();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning to the foreground covers "Siri captured while the app was
    // backgrounded" — including the Siri-overlay-over-the-app case.
    if (state == AppLifecycleState.resumed) _drainCaptureQueue();
  }

  /// Bootstrap already drained (and re-armed reminders) before runApp;
  /// this just voices the result once the UI exists.
  void _announceBootstrapDrain() {
    final result = CaptureQueueDrain.lastResult;
    if (result == null || !mounted) return;
    CaptureQueueDrain.lastResult = null;
    _toastDrain(result);
  }

  Future<void> _drainCaptureQueue() async {
    if (kIsWeb) return;
    _syncHealthHabits();
    final DrainResult result;
    try {
      result = await ref.read(captureQueueDrainProvider).drain();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    if (result.cancelNotificationIds.isNotEmpty) {
      await ref
          .read(notificationServiceProvider)
          .cancelMany(result.cancelNotificationIds);
    }
    if (result.remindersChanged) {
      await ref.read(remindersControllerProvider).resyncNow();
    }
    if (mounted) _toastDrain(result);
  }

  /// Fire-and-forget: mapped habits pick up today's Health numbers on
  /// every foreground. No-op unless the build has HealthKit enabled and
  /// at least one habit is mapped; drift streams surface any change.
  void _syncHealthHabits() {
    if (kIsWeb) return;
    try {
      unawaited(
        ref.read(healthHabitSyncProvider).sync().catchError((_) => 0),
      );
    } catch (_) {
      // Provider unavailable (tests without overrides): nothing to sync.
    }
  }

  void _toastDrain(DrainResult result) {
    if (result.imported <= 0) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 3),
      content: Text(
        result.imported == 1
            ? 'Added 1 capture from Siri.'
            : 'Added ${result.imported} captures from Siri.',
      ),
    ));
  }

  Future<void> _wireCaptureSources() async {
    final notifications = ref.read(notificationServiceProvider);
    _notifications = notifications;
    // Notification taps while the app runs (or is backgrounded).
    notifications.onTap = _handlePayload;
    // Deep links; the stream also emits the link that launched the app.
    if (!kIsWeb) {
      _linkSub = AppLinks().uriLinkStream.listen(_handleUri, onError: (_) {});
    }
    // Notification that cold-started the app.
    final payload = await notifications.launchPayload();
    if (payload != null && payload.isNotEmpty) _handlePayload(payload);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _todayDebounce?.cancel();
    _linkSub?.cancel();
    _notifications?.onTap = null;
    unawaited(_mirror?.stop());
    super.dispose();
  }

  /// Notification payloads: `route:/money` navigates; anything else is
  /// tried as a capture URI.
  void _handlePayload(String payload) {
    if (payload.startsWith('route:')) {
      ref.read(pendingRouteProvider.notifier).state =
          payload.substring('route:'.length);
      return;
    }
    final uri = Uri.tryParse(payload);
    if (uri != null) _handleUri(uri);
  }

  void _handleUri(Uri uri) {
    final now = DateTime.now();
    if (uri == _lastUri &&
        now.difference(_lastUriAt) < const Duration(seconds: 2)) {
      return; // duplicate delivery of the same link
    }
    _lastUri = uri;
    _lastUriAt = now;
    final request = CaptureRequest.fromUri(uri);
    if (request != null) {
      ref.read(pendingCaptureProvider.notifier).state = request;
    }
  }

  void _drainPending() {
    if (!mounted) return;
    final capture = ref.read(pendingCaptureProvider);
    if (capture != null) {
      ref.read(pendingCaptureProvider.notifier).state = null;
      CaptureLauncher.open(context, ref, capture);
    }
    final route = ref.read(pendingRouteProvider);
    if (route != null) {
      ref.read(pendingRouteProvider.notifier).state = null;
      context.go(route);
    }
  }

  /// Publishes "today" aggregates for Siri answers (GetUpNext, budget
  /// status, snippet math). Debounced; a failed write is just no fresh
  /// numbers — Swift says "open the app" instead of quoting stale ones.
  Timer? _todayDebounce;
  void _publishToday() {
    if (kIsWeb) return;
    _todayDebounce?.cancel();
    _todayDebounce = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      final state = ref.read(dashboardStateProvider);
      if (state == null) return;
      final timer = ref.read(preferencesProvider).runningTimer;
      final habits = ref.read(habitsStateProvider);
      try {
        ref.read(entityMirrorProvider).writeToday({
          'dateKey': AppDateUtils.dateKey(DateTime.now()),
          'monthKey': '${DateTime.now().year}-'
              '${DateTime.now().month.toString().padLeft(2, '0')}',
          'score': state.showScore ? state.focusScore.total : null,
          'upNext': state.upNextSpoken,
          'habitsDueToday': habits == null
              ? null
              : [
                  for (final h in habits.habits)
                    if (h.dueToday && !h.habit.isArchived)
                      {
                        'id': h.habit.id,
                        'name': h.habit.name,
                        'done': h.doneToday,
                      },
                ],
          'timerStartedAt': timer?.startedAt.toIso8601String(),
          'monthSpendCentsByCategory': {
            for (final cs in state.money.snapshot.categorySpends)
              cs.category.id: cs.spentCents,
          },
        }).then<void>((_) => _pokeWidgets()).catchError((_) {
          // A failed write just means no fresh numbers to speak/render.
        });
      } catch (_) {
        // Mirror unavailable (web/tests): nothing to publish.
      }
    });
  }

  /// Fresh today.json on disk — ask iOS to re-read the widget timelines.
  /// Silently means nothing everywhere else.
  void _pokeWidgets() {
    if (kIsWeb) return;
    const MethodChannel('lifeassist/paths')
        .invokeMethod('todayPublished')
        .catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pendingCaptureProvider, (previous, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _drainPending());
    });
    ref.listen(pendingRouteProvider, (previous, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _drainPending());
    });
    ref.listen(dashboardStateProvider, (previous, next) {
      if (next != null) _publishToday();
    });

    return ResponsiveScaffold(
      body: widget.shell,
      railBuilder: (context) => _buildRail(context),
      bottomBarBuilder: (context) => _buildBottomBar(context),
    );
  }

  Widget _buildRail(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = AppDestinations.railIndexForLocation(location);

    return ConsoleRail(
      destinations: [
        for (final (i, d) in AppDestinations.rail.indexed)
          ConsoleDestination(branchIndex: i, label: d.label, icon: d.icon),
      ],
      selectedIndex: selectedIndex,
      onSelect: (index) => context.go(AppDestinations.rail[index].route),
      onCapture: () => CaptureLauncher.quickAdd(context, ref),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return ConsoleTabBar(
      currentBranch: widget.shell.currentIndex,
      onSelect: (branch) {
        // Re-tapping the active tab pops that branch back to its root.
        widget.shell.goBranch(
          branch,
          initialLocation: branch == widget.shell.currentIndex,
        );
      },
      onCapture: () => CaptureLauncher.quickAdd(context, ref),
    );
  }
}
