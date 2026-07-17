# App Store checklist + submission runbook

State as of the production-launch build (v1.1.0). Checked items are
done in the repo or already true in App Store Connect; unchecked items
are the manual steps left, in order. The exact click-path runbook is at
the bottom.

## Identity — DONE

- [x] App Store Connect record exists: Apple ID **6789949638**, bundle
      `com.saitokiku.lifeassist` (widgets id
      `com.saitokiku.lifeassist.widgets` also registered)
- [x] Bundle id set in the Xcode project on all targets
- [x] Signing: automatic, team `8JXPU9UQ4Q`, committed for all targets
- [ ] ASC record's **Name** shows the working title "Aurgun-Eyes" — set
      the public name to **Life Assist** (App Information → Name; see
      `app_store_listing.md` for fallbacks if taken)
- [x] Primary language: English (U.S.)

## Build — DONE in repo

- [x] Version `1.1.0+5` in pubspec (flows into both targets via
      Generated.xcconfig)
- [x] App icon 1024 + full set generated (day-score ring mark)
- [x] Privacy manifest `PrivacyInfo.xcprivacy` in the bundle
- [x] Export compliance pre-answered (`ITSAppUsesNonExemptEncryption = NO`)
- [x] All seven purpose strings present + reserve keys documented
      (`release_ios.md`)
- [x] HealthKit + App Group entitlements committed on Runner + widgets;
      `LAHealthKitEnabled = true`
- [x] Widget extension target committed; Live Activity enabled

## Metadata — WRITTEN, paste from `app_store_listing.md`

- [ ] Name, subtitle, promotional text, description, keywords
- [ ] What's New
- [ ] Category: Productivity (+ Lifestyle)
- [ ] App Review notes (Health read-only explanation — paste as-is)

## Screenshots

- [ ] Run the **screenshots** job (Actions → iOS → Run workflow →
      check "Capture App Store screenshots") and download the
      `AppStoreScreenshots` artifact — or capture manually per
      `app_store_listing.md` §Screenshots
- [ ] Upload the 6.9" set (reused for 6.5")

## Privacy — answers ready

- [ ] Host `docs/privacy.md` and `docs/support.md` publicly (GitHub
      Pages: Settings → Pages → deploy from branch, `/docs` folder —
      or any static host). Put both URLs in ASC.
- [ ] App Privacy label: **Data Not Collected.** Click path: App
      Privacy → Get Started → "Do you or your third-party partners
      collect data from this app?" → **No, we do not collect data from
      this app** → Publish. This stays true with HealthKit connected:
      Apple's definition of "collect" is transmitting off-device, and
      Health data never leaves the device (read-only, local
      processing, no network).
- [ ] Age rating questionnaire: everything **None** → expect **4+**

## Runbook — from `git pull` to "Submit for Review"

On the Mac:

1. `git checkout main && git pull`
2. `flutter pub get && flutter test` (sanity; 180 tests green)
3. Open `ios/Runner.xcworkspace` once, signed into the team account —
   automatic signing registers the HealthKit capability and App Group
   from the committed entitlements. If a provisioning error names a
   capability, open Signing & Capabilities for Runner and
   LifeAssistWidgets and let Xcode fix it, then rebuild.
4. `flutter build ipa --release` → `build/ios/ipa/*.ipa`
5. Upload with **Transporter** (drag the .ipa) or Xcode Organizer.
   Processing takes ~5–15 min; no compliance emails expected.
6. In App Store Connect, while processing:
   - App Information → set Name to **Life Assist**
   - Paste every metadata block from `app_store_listing.md`
   - Upload screenshots; set the privacy label (**Data Not
     Collected**) and age rating (4+)
   - Add the privacy + support URLs
   - Pricing: Free
7. Select the processed build on the version page.
8. TestFlight first (recommended): Internal Testing → add yourself →
   install → run the on-device acceptance list below.
9. Add App Review notes from `app_store_listing.md` → **Submit for
   Review**. Typical review: 1–3 days.

## On-device acceptance (TestFlight build, before submitting)

- [ ] Notes: create two notes, `[[link]]` one to the other → backlink
      appears; graph shows the pair joined; tap a ghost → note created
- [ ] Vault: Settings → Export notes to Files → folder visible in
      Files app; edit a .md there → Re-import from Files picks it up
- [ ] Health: Settings → Apple Health → allow read → map a habit to
      steps → walk → habit checks itself (manual check still wins)
- [ ] Widgets: add the score + habit widgets; habit check from the
      widget drains exactly once into the app
- [ ] Live Activity: start the focus timer → Lock Screen shows it;
      stop → it ends
- [ ] Siri: "Log an expense in Life Assist" with the app killed →
      open later → the row exists exactly once
- [ ] Reminder by voice, never open the app → it fires
- [ ] Backup: export JSON, reset everything, import → data intact
      (including notes + rebuilt links)

## Post-approval

- [ ] Phased release optional
- [ ] Keep bundle id, team id, and ASC access documented somewhere safe
- [ ] Revisit pricing at v2
