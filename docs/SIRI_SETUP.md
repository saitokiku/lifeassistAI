# Siri & Shortcuts setup

Voice-first capture is the app's flagship bet (see
`IMPROVEMENT_BLUEPRINT.md` §9). The Dart side — the **capture bus** — is
fully wired: any `lifeassist://capture?...` URL opens the matching sheet,
prefilled, from cold start or warm. Siri support rides that rail.

## What already works with zero setup

- **Android**: long-press the launcher icon → Expense / Step / Idea / Time
  shortcuts (`android/app/src/main/res/xml/shortcuts.xml`). Any automation
  app (e.g. Tasker) can fire `lifeassist://capture?...` VIEW intents too.
- **iOS (Shortcuts app, no Xcode work)**: create a shortcut with the
  "Open URL" action pointing at, say,
  `lifeassist://capture?type=expense&amount=20&text=groceries`, name it
  "Log twenty dollars for groceries", and Siri will run it by name.

## Enabling the native App Intents (iOS 16+)

`ios/Runner/LifeAssistIntents.swift` ships in the repo but isn't part of
the Xcode target until you add it (a codegen'd Runner project can't be
edited reliably from CI, so this is a one-time manual step):

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Drag `Runner/LifeAssistIntents.swift` into the Runner group and check
   "Runner" as the target.
3. Set the deployment target to iOS 16.0 or later (the file is
   `@available`-guarded, so 15.x builds still work — the intents just
   don't appear there).
4. Build once on a device. The App Shortcuts register automatically; no
   entitlement or capability is needed for foreground intents.

Phrases that work immediately after install:

- "Log an expense in Life Assist"
- "Log time in Life Assist"
- "Log my step in Life Assist"
- "Park an idea in Life Assist"
- "Add a reminder in Life Assist"

Siri collects the missing parameter by voice ("How much was it?"), the
app opens on the right tab with the sheet prefilled, and one tap saves.
The confirmation tap is deliberate for v1 — see the blueprint's honesty
principles (voice never invents an outcome or a category).

## Phase B v2 (background intents) — designed, not yet built

For "log it without unlocking the phone", the blueprint specifies:

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
