# Life Assist — Privacy Policy

_Last updated: July 2026._

## Summary

Life Assist is a local-first personal app. Your data stays on your
device. We don't collect it, we can't see it, and we don't sell it.

## What the app stores

Everything you enter — goals, budgets, transactions, time logs,
habits, ideas, notes, journal lines, reminders, and settings — is
stored in a local database on your device. Small app preferences
(theme, onboarding state, notification toggle) are stored in local app
preferences.

## What leaves your device

Nothing. Life Assist has:

- no user accounts and no sign-in
- no cloud storage or sync
- no third-party analytics, ads, or tracking SDKs
- no network transmission of your data by the app

## Apple Health

If you choose to connect Apple Health, the app reads only the metrics
you map to habits (steps, sleep, mindfulness, workouts) to check those
habits off. Reads are processed entirely on your device. The app never
writes to Apple Health and never transmits Health data anywhere. You
can revoke access at any time in the system Health settings.

## Siri and widgets

Siri captures ("log an expense…") and widget data are exchanged
between the app and its own extensions in the app's private container
on your device. Nothing is sent to Apple or anyone else beyond the
system's own Siri processing of your spoken request.

## Notifications

Reminders use your device's local notification system. Scheduling
happens entirely on-device. You can decline or revoke notification
permission at any time in system settings; the app keeps working.

## What this protects against — and what it doesn't

Being honest about the threat model matters more than a reassuring
sentence. "Nothing leaves your device" answers one question; here are
the others.

**Protected**

- **Remote access.** There is no server, no account, and no network
  call in the app. Nobody — including us — can request your data,
  because there is nowhere to request it from.
- **Other apps on your phone.** iOS and Android sandbox app storage;
  another app cannot read Life Assist's database.
- **A glance over your shoulder.** Turn on app lock (Settings →
  Privacy) and the app asks for Face ID / fingerprint / PIN on every
  return. An opaque cover is drawn *before* the app leaves the screen,
  so your balances and journal don't appear in the app switcher, and on
  Android the recents thumbnail and screenshots are blocked entirely.
- **Accidental loss.** A safety copy is written before "Reset
  everything" and before restoring a backup, and a rolling weekly copy
  is kept. These live in the app's private storage, not the Files app.
- **Apple Health data.** Read-only, on-device, never written back and
  never transmitted.

**Not protected**

- **Someone who can unlock your device.** App lock is a gate on the
  app, not encryption of the data. Anyone past your device passcode
  can open the app and try to authenticate, and can reach your exported
  files.
- **Your notes vault, by design.** `Files › Life Assist ›
  LifeAssistVault` is deliberately visible so Obsidian and the Files
  app can reach it — that is the feature. Anything you write in a note
  is readable by anyone with access to your unlocked device. The
  database and its backup copies are *not* in that folder.
- **Backups you export.** Settings → Export produces plain, unencrypted
  JSON so you can read and migrate it yourself. Wherever you put it
  inherits that location's protection: iCloud Drive, a shared folder, or
  a synced clipboard are all as private as those places are. Treat the
  file like a bank statement.
- **Your device backup.** The database is included in your encrypted
  iCloud/Finder device backup. The Siri/widget bridge is explicitly
  excluded from backups, but the database is not — that is what makes
  restoring a phone work.
- **Siri and lock-screen features.** For Siri to answer and widgets to
  render without opening the app, a small summary (today's score, what's
  next, month-to-date spend per budget category, habit names) is stored
  in the app's private shared container. It never leaves the device and
  is excluded from backups, but it exists so those features can work
  while the app is closed. Turning off widgets and Siri shortcuts is the
  way to opt out.
- **A compromised or jailbroken device.** No app-level measure survives
  that.

## Your control

- **Export**: Settings → Export backup produces a complete JSON copy
  of your data; Settings → Notes vault exports your notes as plain
  Markdown files. Both are yours to store anywhere.
- **Import**: restore from a JSON backup, or import Markdown notes, at
  any time.
- **Delete**: Settings → Reset everything wipes the database on
  device. Uninstalling the app also removes all locally stored data.

## Children

The app is not directed at children and collects no data from anyone.

## Changes

If a future version adds optional cloud sync or backups, this policy
will be updated first, the feature will be opt-in, and the "nothing
leaves your device" default will remain.

## Contact

Questions: mnnbht3@gmail.com
