import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../constants/app_constants.dart';
import '../providers.dart';

/// Whether this device can gate the app behind biometrics/PIN at all.
final appLockSupportedProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) return false;
  try {
    return await LocalAuthentication().isDeviceSupported();
  } catch (_) {
    return false;
  }
});

/// Full-screen gate over the app. When the lock preference is on, the app
/// locks on cold start and every return from the background, and unlocks
/// through the OS biometric/PIN prompt. Purely device-local — the data on
/// disk is not encrypted by this, it's a shoulder-surfing gate.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _locked = false;
  bool _prompting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locked = !kIsWeb && ref.read(preferencesProvider).appLockEnabled;
    if (_locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;
    if (!ref.read(preferencesProvider).appLockEnabled) return;
    if (state == AppLifecycleState.paused && !_locked) {
      setState(() => _locked = true);
    } else if (state == AppLifecycleState.resumed && _locked && !_prompting) {
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_prompting) return;
    _prompting = true;
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock ${AppConstants.appName}',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (ok && mounted) setState(() => _locked = false);
    } catch (_) {
      // Prompt unavailable (no enrollment, transient error): stay locked;
      // the button lets the user retry.
    } finally {
      _prompting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;
    final theme = Theme.of(context);
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Material(
            color: theme.colorScheme.surface,
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 40),
                    const SizedBox(height: 16),
                    Text(AppConstants.appName,
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Locked. Unlock to continue.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _unlock,
                      child: const Text('Unlock'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
