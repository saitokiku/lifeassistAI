# App Store listing — paste-ready metadata

Copy each block into App Store Connect exactly as written (character
limits verified). Set the **Name** field below on the app's page — that
is the name users see, and it is independent of whatever working name
the App Store Connect record was created with.

## Name (30 chars max)

```
Life Assist
```

Fallback if taken: `Life Assist — Personal OS` (25) or
`Life Assist: Run Your Life` (26).

## Subtitle (30 chars max)

```
Goals, money, time & notes
```

(26 chars.)

## Promotional text (170 chars max, editable without review)

```
One quiet place to run your life: a main goal, honest money and time
numbers, habits that check themselves, and notes that link like a mind
map. No account. No cloud.
```

(168 chars.)

## Description (4000 chars max)

```
Life Assist is one quiet place to run your life — built for people who
want a single honest dashboard instead of six loud apps.

SET ONE MAIN GOAL
Name the thing you're actually working toward. Today's screen always
answers three questions: what matters now, what needs attention, and
what's the best next action. Log steps, track a weekly measure, and
close each week with a five-minute review.

MONEY, WITHOUT THE SERMON
Budgets, accounts, and recurring costs with exact-cents math. Import
bank statements from CSV. See where the month stands in one glance —
no lectures, just numbers you can trust.

TIME YOU CAN SEE
Weekly hour targets for the things that matter, one-tap logging, a
focus timer with a Live Activity on your Lock Screen, and countdowns
for the dates that define your year.

HABITS THAT CHECK THEMSELVES
Map a habit to Apple Health — steps, sleep, mindful minutes, workouts —
and it checks itself off. Your manual check always outranks the sensor,
and everything Health-related stays on your device.

NOTES THAT THINK IN LINKS
A built-in Zettelkasten: write in Markdown, connect thoughts with
[[double brackets]], tag themes with #tags, and watch an interactive
graph of your thinking grow on its own. Backlinks show every note that
points here. Export the whole vault as plain .md files — Obsidian-
compatible, visible in the Files app, yours forever.

SIRI, WIDGETS, AND YOUR LOCK SCREEN
Say "Log an expense in Life Assist" and it's saved without opening the
app. Home-Screen widgets show your day score, what's next, and one-tap
habit checks. A Control Center button starts capture instantly.

PRIVATE BY ARCHITECTURE
No account. No cloud. No analytics. No tracking. Everything lives in a
local database on your device; export a complete JSON backup or your
notes as Markdown any time. If it ever syncs, it will be opt-in — the
default stays "nothing leaves your device."

Life Assist is for operators: founders, makers, and anyone running
their life like it matters.
```

(~1,900 chars — room to grow.)

## Keywords (100 chars max, comma-separated, no spaces needed)

```
life,dashboard,goals,habits,budget,time,focus,notes,zettelkasten,mind map,journal,tracker,private
```

(98 chars.)

## What's New (first release)

```
First release: one main goal, honest money and time tracking, habits
that check themselves via Apple Health, linked Markdown notes with a
graph view, Siri capture, widgets, and a focus-timer Live Activity.
All local. All yours.
```

## Categories

- Primary: **Productivity**
- Secondary: **Lifestyle** (or Finance)

## URLs

- Support URL: host `docs/support.md` (GitHub Pages or any static
  host) — e.g. `https://<your-username>.github.io/lifeassist/support`
- Marketing URL (optional): same host, `/` landing
- Privacy Policy URL: host `docs/privacy.md` — required before
  submission

## App Review notes (paste into "Notes" box)

```
Life Assist is a single-user, local-first personal organizer. There is
no login and no server — no demo account is needed; all features work
immediately on first launch.

HealthKit: read-only. The user explicitly maps a habit to a Health
metric (steps, sleep, mindfulness, workouts) in Settings → Apple
Health; the app then checks that habit off locally. Health data is
never written, never transmitted, and never leaves the device.
NSHealthUpdateUsageDescription exists only because the authorization
API links the write symbol; the app requests read access only.

Notifications are user-initiated local notifications (reminders the
user creates); no push entitlement is used.

The camera/photo/location purpose strings exist solely because the
bundled file-picker component links those frameworks; the app itself
never requests them outside of the user choosing a file to import.
```

## Screenshots

Required: 6.9" (iPhone 16 Pro Max class). 6.5" can reuse 6.9" assets
since 2024 ASC rules; upload both if you have them.

**Automated path**: the `screenshots` job in the iOS workflow
(Actions → iOS → Run workflow → check "capture screenshots") boots an
iPhone 16 Pro Max simulator, seeds demo content, walks Today → Focus →
Money → Time → Notes → Graph in dark mode, and uploads
`AppStoreScreenshots` as a downloadable artifact.

**Manual fallback**: Simulator (iPhone 16 Pro Max, dark appearance) →
run the app → ⌘S on each screen. Capture: Today (with a goal set),
Focus, Money, Time, Notes list with a few linked notes, and the Graph.

## Age rating

Answer every questionnaire item **None** except:
- Simulated Gambling: **None** (budget categories may be user-named;
  nothing in the app simulates gambling)

Expected rating: **4+**. (Earlier builds shipped example spend-flag
categories; the seeded categories are neutral — Groceries, Rent, etc.)

## App Privacy (nutrition label)

Answer: **Data Not Collected.** Click path: App Privacy → Get Started →
"Do you or your third-party partners collect data from this app?" → **No,
we do not collect data from this app** → Publish.

This stays true with HealthKit connected: Apple defines "collect" as
transmitting off-device, and Health data never leaves the device — it is
read-only, processed locally, and never sent anywhere.

Host [privacy.md](privacy.md) and [support.md](support.md) at public URLs
before submitting (GitHub Pages serves the `/docs` folder directly) and
put both links in App Store Connect.
