# iOS release guide

Nothing here is automatic. This walks from a fresh clone to a
TestFlight-ready build. You need a Mac with Xcode and an Apple Developer
Program membership ($99/yr) for device installs beyond 7 days and for
TestFlight/App Store.

## 1. Flutter setup

```bash
# Install Flutter stable (https://docs.flutter.dev/get-started/install/macos)
flutter doctor            # fix anything red (Xcode, CocoaPods)
cd life_dashboard
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test && flutter analyze
```

## 2. Xcode / bundle id / signing

```bash
open ios/Runner.xcworkspace
```

In Runner → Targets → Runner:

- **General → Identity**: set Bundle Identifier to
  `com.kaizen.lifedashboard` (placeholder — any reverse-DNS id you own
  works; keep it consistent forever once TestFlight sees it). Set the
  Display Name to "Life Assist".
- **Signing & Capabilities**: check "Automatically manage signing", pick
  your Team (create one by signing into Xcode → Settings → Accounts with
  your Apple ID). Xcode creates the provisioning profile.
- Minimum iOS version: Flutter's default (see `ios/Podfile`); raise only if
  needed.

Notifications: `flutter_local_notifications` needs no special capability
for local notifications; the app requests permission at runtime from the
Reminders screen or onboarding.

## 3. Run on your iPhone (development build)

1. Plug in the phone, trust the computer, enable Developer Mode
   (Settings → Privacy & Security → Developer Mode, iOS 16+).
2. `flutter devices` to confirm it's visible.
3. `./scripts/run_ios.sh <device-id>` or `flutter run -d <device-id>`.
4. First install with a free Apple ID: on the phone, Settings → General →
   VPN & Device Management → trust your developer certificate. Free-account
   builds expire after 7 days; paid accounts last a year.

## 4. Release build

```bash
./scripts/build_ios_release.sh    # flutter build ios --release
```

This produces an archive-ready build. To archive manually: Xcode →
Product → Archive (select "Any iOS Device (arm64)").

## 5. IPA

```bash
./scripts/build_ipa_release.sh    # flutter build ipa --release
```

Output: `build/ios/ipa/*.ipa` plus an `.xcarchive` under
`build/ios/archive/`. If signing fails, fix Signing & Capabilities in
Xcode first — Flutter uses the same settings.

## 6. TestFlight (later, manual)

1. appstoreconnect.apple.com → My Apps → "+" → New App. Pick the same
   bundle id, name "Life Assist", primary language, SKU.
2. Upload the build: Xcode Organizer → Distribute App → App Store Connect,
   or `xcrun altool`/Transporter with the `.ipa`.
3. Wait for processing, answer the export-compliance question (this app
   uses only standard encryption → usually "No").
4. TestFlight tab → add yourself as an internal tester → install via the
   TestFlight app.

See docs/app_store_checklist.md for the full store checklist.

## Web caveat

`drift_flutter` persists on the web only when `web/sqlite3.wasm` and
`web/drift_worker.js` are present (see drift's "Web" docs — copy both files
from the drift release assets or `dart run drift_dev make-migrations`
docs). Without them drift falls back to in-memory storage and logs a
warning. Local notifications do not exist on web; the Reminders screen
explains this in-app. iOS/Android are the primary targets.

## Android note

`flutter build apk --release` works out of the box with the generated
`android/` project (default debug signing). Reminders use inexact alarms —
no special permissions needed beyond POST_NOTIFICATIONS (requested at
runtime on Android 13+).
