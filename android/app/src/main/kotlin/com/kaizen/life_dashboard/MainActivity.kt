package com.kaizen.life_dashboard

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    /**
     * Keeps the app's contents out of the recents thumbnail (and out of
     * screenshots and screen recordings).
     *
     * The Dart-side privacy shield in lib/core/security/app_lock.dart
     * cannot cover this on Android: the system captures the task
     * snapshot itself, outside the Flutter layer, so no widget can hide
     * it. FLAG_SECURE is the only lever — and an app holding income,
     * balances, and journal entries shouldn't leave them legible in the
     * task switcher of a borrowed phone.
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }
}
