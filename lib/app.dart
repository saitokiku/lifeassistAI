import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/security/app_lock.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/application/settings_controller.dart';
import 'routing/app_router.dart';

/// Locales the framework will localize its own widgets for. The app's
/// copy is English; these control date pickers, selection menus, and
/// semantics — so a device set to any of these gets native chrome.
const kSupportedLocales = <Locale>[
  Locale('en'), Locale('es'), Locale('fr'), Locale('de'), Locale('it'),
  Locale('pt'), Locale('nl'), Locale('sv'), Locale('da'), Locale('nb'),
  Locale('fi'), Locale('pl'), Locale('cs'), Locale('tr'), Locale('ru'),
  Locale('uk'), Locale('ar'), Locale('he'), Locale('hi'), Locale('th'),
  Locale('ja'), Locale('ko'), Locale('zh'), Locale('id'), Locale('vi'),
];

class LifeDashboardApp extends ConsumerWidget {
  const LifeDashboardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // The app's own copy is English, but the framework's widgets —
      // date pickers, text-selection menus, semantic labels — should
      // speak the device's language and use its calendar conventions.
      // Without these delegates every locale got en_US pickers, and a
      // non-Latin-script device had no localized selection controls at
      // all.
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: kSupportedLocales,
      routerConfig: router,
      builder: (context, child) =>
          AppLockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
