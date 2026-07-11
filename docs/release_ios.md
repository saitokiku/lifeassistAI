# iOS release guide

Two paths. The **fast loop needs no Mac**: CI builds a sideloadable
unsigned IPA on every iOS-touching push. The **release path** (TestFlight
/ App Store) uses your Mac and paid Apple Developer membership.

## 0. Fast loop — CI-built unsigned IPA (no Mac)

Every push touching `ios/**` (or a manual run of the **iOS** workflow in
the Actions tab) produces the artifact **`LifeAssist-unsigned-ipa`**:
`flutter build ios --release --no-codesign` packaged as
`Payload/Runner.app` → `LifeAssist-unsigned.ipa`.

1. Download the artifact from the workflow run.
2. Install via **AltStore**, **SideStore**, or **Sideloadly** — they
   re-sign with your Apple ID on install (free ID: 7-day cert; paid: 1 yr).
3. App Shortcut phrases ("Log an expense in Life Assist") register on
   first launch — no setup.

Everything in Phases 0–4 of [SIRI_AI_BLUEPRINT.md](SIRI_AI_BLUEPRINT.md)
works on a sideloaded build; entitlements only enter at HealthKit
(Phase 5) and App Groups/widgets (Phase 6). Cost note: macOS runners
bill 10× minutes on private repos — the workflow is path-filtered and
cancels superseded runs; a public repo makes them free.

### On-device test checklist (per blueprint phase)

- **Phase 0**: "Hey Siri, log an expense in Life Assist" from a locked
  phone → app opens on the prefilled expense sheet.
- **Phase 2**: same phrase, phone locked → Siri confirms WITHOUT opening
  the app; open later → the row exists exactly once (also force-kill the
  app right after Siri confirms, reopen, recheck). Create a reminder by
  voice, never open the app, and wait for it to fire.
- **Phase 3** (iOS 27): unphrased "log twelve fifty for groceries…" →
  the right category entity resolves; the snippet's month-to-date total
  appears only when fresh; Undo removes the row; Spotlight surfaces
  budget names.
- **Phase 4** (Apple-Intelligence device): smart-capture field appears on
  Today; "coffee 4.50 yesterday and 2h deep work" → two chips; on a
  non-AI device the field is absent entirely.

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
- Minimum iOS version: **17.0** (set in project.pbxproj — App Intents +
  interactive widgets floor; newer APIs are availability-gated).

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
3. Wait for processing. Export compliance is pre-answered
   (`ITSAppUsesNonExemptEncryption = NO` in Info.plist).
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
