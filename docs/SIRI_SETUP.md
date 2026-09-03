# Siri & Shortcuts setup

Voice-first capture is the app's flagship bet. The Dart side — the
**capture bus** — is fully wired: any `lifeassist://capture?...` URL
opens the matching sheet, prefilled, from cold start or warm. Siri
support rides that rail.

## What already works with zero setup

- **Android**: long-press the launcher icon → Expense / Step / Idea / Time
  shortcuts (`android/app/src/main/res/xml/shortcuts.xml`). Any automation
  app (e.g. Tasker) can fire `lifeassist://capture?...` VIEW intents too.
- **iOS (Shortcuts app, no Xcode work)**: create a shortcut with the
  "Open URL" action pointing at, say,
  `lifeassist://capture?type=expense&amount=20&text=groceries`, name it
  "Log twenty dollars for groceries", and Siri will run it by name.

## The native App Intents — no setup needed anymore

`ios/Runner/LifeAssistIntents.swift` is wired into the Runner target in
`project.pbxproj` and compiles with every build (deployment target is
iOS 17). No Xcode step. App Shortcuts register automatically on first
launch; foreground intents need no entitlement or capability. Grab a
build from the **iOS** workflow artifact — see
[release_ios.md](release_ios.md).

Phrases that work immediately after install:

- "Log an expense in Life Assist"
- "Log time in Life Assist"
- "Log my step in Life Assist"
- "Park an idea in Life Assist"
- "Add a reminder in Life Assist"

Siri collects the missing parameter by voice ("How much was it?"), the
app opens on the right tab with the sheet prefilled, and one tap saves.
The confirmation tap is deliberate — see the honesty
principles (voice never invents an outcome or a category).

## Background capture and beyond

The advanced integration — logging without opening the app, typed
entities, iOS 27 Siri AI alignment, on-device Foundation Models — ships
in `ios/Runner/` (`BackgroundIntents.swift`, `EntityStore.swift`,
`SiriAnswers.swift`, `AiBridge.swift`). Background intents need no App
Group: they write into the app's own sandbox. The original sketch below
is kept because it explains the constraints that shaped that design:

- An **App Group** shared container with a small pending-capture queue
  (JSON file or SQLite separate from the drift DB — the extension must
  never write the app's database).
- Background `AppIntent`s (`openAppWhenRun = false`) that append to the
  queue and speak a confirmation.
- The Flutter side drains the queue at the end of `bootstrap()` and on
  app-resume.
- Siri-created reminders arm `UNUserNotificationCenter` directly from
  Swift using the same notification-id derivation as
  `SeedService.notificationIdFor` / `ReminderScheduler.weekdayIdFor` —
  the per-id cancellation work those classes do is what makes this safe.

## Android parity (Phase C)

Static shortcuts are done. Optional next step: Google Assistant App
Actions (`actions.xml` + capability shims). The deep-link scheme is
already the interface, so no Dart changes are needed.
