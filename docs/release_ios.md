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

Siri capture, entity resolution and on-device AI all work on a
sideloaded build; entitlements only enter at HealthKit and at App
Groups (widgets). Cost note: macOS runners
bill 10× minutes on private repos — the workflow is path-filtered and
cancels superseded runs; a public repo makes them free.

### On-device test checklist

- **Foreground capture**: "Hey Siri, log an expense in Life Assist" from
  a locked phone → app opens on the prefilled expense sheet.
- **Background capture**: same phrase, phone locked → Siri confirms
  WITHOUT opening the app; open later → the row exists exactly once
  (also force-kill the app right after Siri confirms, reopen, recheck).
  Create a reminder by voice, never open the app, and wait for it to
  fire.
- **Entity resolution** (iOS 27): unphrased "log twelve fifty for
  groceries…" → the right category entity resolves; the snippet's
  month-to-date total appears only when fresh; Undo removes the row;
  Spotlight surfaces budget names.
- **On-device AI** (Apple-Intelligence device): smart-capture field
  appears on Today; "coffee 4.50 yesterday and 2h deep work" → two
  chips; on a non-AI device the field is absent entirely.

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

Almost everything is pre-set in the repo; on the Mac you only add the
Team:

- **Bundle Identifier**: already `com.saitokiku.lifeassist` (in
  project.pbxproj). If you prefer a different reverse-DNS id, change it
  BEFORE the first TestFlight upload — it can never change after. The
  App Store Connect app record must use the exact same id.
- **Display name**: already "Life Assist". **Version**: pubspec.yaml
  `version: 1.0.0+1` flows into CFBundleShortVersionString/Version —
  bump the `+N` build number for every new upload.
- **Privacy manifest**: `ios/Runner/PrivacyInfo.xcprivacy` ships in the
  bundle (no tracking, no collected data, UserDefaults + file-timestamp
  required-reason declarations). Export compliance is pre-answered.
- **Signing & Capabilities**: automatic signing with team `8JXPU9UQ4Q`
  is committed on ALL targets (Runner, RunnerTests, LifeAssistWidgets) —
  a fresh clone signs and archives with no Xcode signing clicks. Just be
  signed into that Apple ID in Xcode → Settings → Accounts. (The
  extension target needs its own team; without it `flutter build ipa`
  fails with "Signing for LifeAssistWidgets requires a development
  team".) No capabilities are required for the 1.0 feature set — Siri
  App Intents need none.
- Minimum iOS version: **17.0** (set in project.pbxproj). Everything
  newer is availability-gated, so one binary serves 17 → 27: Siri AI
  entity schemas light up on 26/27, on-device AI (Foundation Models) on
  26+ Apple-Intelligence devices, semantic Spotlight on 18+.

Notifications: `flutter_local_notifications` needs no special capability
for local notifications; the app requests permission at runtime from the
Reminders screen or onboarding.

**On any `flutter_local_notifications` version bump, re-verify the
pinned contract** (Swift's `CaptureQueue.armReminder` mimics the
plugin's request shape so Siri-armed reminders can be cancelled by id):

1. `identifier` is still `String(notificationId)` and `userInfo` still
   carries `NotificationId`/`payload`/`present*` keys (compare
   `armReminder` in `ios/Runner/CaptureQueue.swift` against the
   plugin's iOS source).
2. `zonedSchedule` signature/`matchDateTimeComponents` semantics are
   unchanged (`lib/core/notifications/notification_service.dart`).
3. `flutter test test/reminder_scheduler_test.dart` — the
   armed-notification shape (ids, times, payloads) stays green.
4. On device: create a reminder by voice with the app killed, never
   open the app, and confirm it fires once (not twice) after the next
   app open re-arms it through the plugin.

### Capabilities — LIVE at launch (entitlements committed)

Both launch capabilities ship in the repo as entitlements files wired
into `project.pbxproj` via `CODE_SIGN_ENTITLEMENTS`:

- **HealthKit**: `ios/Runner/Runner.entitlements` declares
  `com.apple.developer.healthkit`, and Info.plist has
  `LAHealthKitEnabled = YES` — the Settings "Apple Health" row and
  habit health-mapping are active in this build. Read-only; both usage
  strings are in Info.plist.
- **Widgets + App Group**: the same file (and
  `ios/LifeAssistWidgets/LifeAssistWidgets.entitlements` for the
  extension) declares the App Group `group.com.saitokiku.lifeassist`
  on BOTH targets. The bridge (entities.json, today.json, capture
  queue) relocates to the shared container automatically on the Swift
  and Dart sides; old pending captures still drain from the previous
  location. (`scripts/ios/add_widget_extension.rb` regenerates the
  widget target with the entitlement if it's ever removed.)

**Mac-side, first archive after pulling this**: with automatic signing,
Xcode registers HealthKit and the App Group on the App ID by itself
when you build (signed into the team account). If signing errors
mention a capability, open Signing & Capabilities once for Runner and
LifeAssistWidgets — the capabilities are already listed from the
entitlements files — and let Xcode "register" them, then rebuild.
CI is unaffected: it builds `--no-codesign`, where entitlements are
carried but not enforced.

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

## 6. TestFlight — the full path, start to finish

One-time setup:

1. developer.apple.com → Certificates, Identifiers & Profiles →
   Identifiers → register `com.saitokiku.lifeassist` (App ID, "App"
   type; no extra capabilities needed for 1.0).
2. appstoreconnect.apple.com → My Apps → "+" → New App: platform iOS,
   name "Life Assist", primary language, the same bundle id, any SKU
   (e.g. `lifeassist-001`).

Every upload:

3. `flutter build ipa --release` (or Xcode → Product → Archive with
   "Any iOS Device (arm64)"). Output: `build/ios/ipa/*.ipa`.
4. Upload: open the `.ipa` with the **Transporter** app (App Store),
   or Xcode Organizer → Distribute App → App Store Connect. CLI:
   `xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios
   --apiKey <key> --apiIssuer <issuer>`.
5. Processing takes ~5–15 min. Export compliance is pre-answered
   (`ITSAppUsesNonExemptEncryption = NO`); the privacy manifest rides in
   the bundle, so no missing-API-declaration mail.

   **Purpose strings (ITMS-90683).** Info.plist declares nine
   `NS*UsageDescription` keys. Five (Face ID, Health-share, Camera,
   Photo-library, Location) plus Health-update and Photo-library-add
   cover every privacy-sensitive API symbol the app's own code and the
   bundled `file_picker` imaging libraries
   (DKImagePickerController/DKCamera) link, and two — Microphone and
   Speech-recognition — are genuinely used by the Capture Inbox mic
   (on-device transcription via `speech_to_text`; nothing recorded or
   uploaded). The app itself never uses
   camera/photos/location/motion/media — those are transitive symbol
   references, worded honestly as such. **Reserve keys**, held out
   because the analyzer has never demanded them and the app provably
   never calls them, but a 30-second add if a future upload ever names
   one: `NSMotionUsageDescription` (DKCamera links CoreMotion) and
   `NSAppleMusicUsageDescription` (file_picker's audio path may link
   MediaPlayer). Use the same "referenced by a bundled file-picker
   component, never used by the app" wording.
6. TestFlight tab → Internal Testing → add yourself → install from the
   TestFlight app on the phone. Siri App Shortcut phrases register on
   first launch.
7. Next build: bump `+N` in pubspec.yaml `version:`, rebuild, re-upload.

Store metadata to paste into App Store Connect — name, subtitle,
description, keywords, privacy answers — is in
[app_store_listing.md](app_store_listing.md).

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
