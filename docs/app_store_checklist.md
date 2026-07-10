# App Store checklist

Work through this top-to-bottom when moving from private build →
TestFlight → App Review. Nothing is automated; each item is a manual step.

## Identity

- [ ] App name: **Life Assist** (check availability in App Store
      Connect; fall back to e.g. "Life Assist — Personal OS" if taken)
- [ ] Bundle ID: `com.kaizen.lifedashboard` (placeholder — register the
      final one at developer.apple.com → Identifiers and set it in Xcode;
      it cannot change after the first upload)
- [ ] SKU: any internal string, e.g. `life-dashboard-001`
- [ ] Primary language: English (U.S.)

## Assets

- [ ] App icon 1024×1024 (no alpha) + generated icon set
      (see `assets/app_icon/placeholder_readme.md`)
- [ ] Screenshots: 6.9" (iPhone 16 Pro Max class) and 6.5" sizes minimum;
      capture Today, Focus, Money, Time in dark mode
- [ ] Optional: iPad screenshots if iPad is enabled (rail layout already works)

## Metadata

- [ ] Subtitle (30 chars), e.g. "Operator life dashboard"
- [ ] Description (from README/product spec; no competitor names)
- [ ] Keywords: focus, dashboard, budget, time, habits, founder...
- [ ] Support URL: placeholder — `https://example.com/life-dashboard/support`
      (replace with a real page before submission; a GitHub Pages page is fine)
- [ ] Marketing URL (optional): placeholder — same host
- [ ] Category: Productivity (secondary: Finance or Lifestyle)
- [ ] Age rating questionnaire: expect 4+ (the app references budgeting
      categories like poker/weed as *spend flags*; answer the gambling and
      drug-reference questions honestly — plain text category names with
      "keep this at $0" semantics have passed review historically, but be
      prepared to rename to "Vice A/B" if flagged)

## Privacy

- [ ] Privacy policy URL (host docs/privacy_policy_draft.md somewhere public)
- [ ] App Privacy "nutrition label": **Data Not Collected** (local-first,
      no analytics, no accounts, no tracking) — only true while v1 stays
      offline; revisit if cloud sync ships
- [ ] Export compliance: standard encryption only → "No" to the custom
      crypto question (set `ITSAppUsesNonExemptEncryption = NO` in
      Info.plist to skip the per-build prompt)

## TestFlight

- [ ] Upload build (Xcode Organizer or Transporter)
- [ ] Internal testing: add your own Apple ID as internal tester (no review
      needed, 100 device limit)
- [ ] Beta App Description + feedback email
- [ ] External testing later (requires Beta App Review)

## App Review submission (public release, later)

- [ ] All metadata + screenshots final
- [ ] Review notes: explain it's a single-user local-first tool; no login,
      so no demo account needed
- [ ] Notification usage is user-initiated (permission prompt from the
      Reminders screen) — no push entitlement used
- [ ] Pricing: Free initially; revisit paid/subscription at v2.1
- [ ] Submit; typical review 1–3 days

## Post-approval

- [ ] Phased release optional
- [ ] Keep the bundle id, signing certs, and App Store Connect access
      documented somewhere safe
