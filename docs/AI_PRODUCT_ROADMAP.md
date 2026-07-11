# AI Product Roadmap — Life Assist

*Status: planning document. Nothing in this file is implemented, and the
app is designed to be excellent without any of it. This is the thinking we
want already written down when AI work starts.*

Life Assist is a local-first, no-account app whose core promise is
**reducing the mental load of running a life**. AI is only worth adding
where it serves that promise better than deterministic code — and it must
never undermine the app's two structural advantages: the user's data stays
on their device, and the app never pretends to know more than it does.

---

## 1. Product principles for AI

1. **AI reduces cognitive load; it never adds a system to manage.** If a
   feature needs its own settings page, prompt engineering, or babysitting,
   it fails the bar.
2. **User agency is preserved.** AI proposes; the user disposes. Nothing
   consequential (editing, deleting, rescheduling, categorizing) happens
   without explicit confirmation.
3. **Suggestions come with reasons.** Every AI suggestion shows the data it
   was based on, in one line ("You logged no downtime this week and slept
   under 7h twice").
4. **Facts and inferences are visibly different.** "You spent $340 on
   eating out" is a fact. "You tend to overspend when the week is
   stressful" is an inference and is labeled as one.
5. **No silent writes.** AI never mutates stored data on its own. Approved
   actions are written through the same repositories the UI uses, and are
   undoable like any other edit.
6. **The app works offline and with AI off.** Every AI surface has a
   non-AI fallback (usually: the deterministic version that already ships).
7. **Data minimization by default.** Only the fields a feature needs leave
   the device, only when the user has turned that feature on, and never for
   training. Money amounts, notes, and goal text are sensitive by default.
8. **No borrowed authority.** The assistant never issues medical, legal,
   tax, or financial directives; it phrases observations and options, and
   links out where professional advice belongs.
9. **Honest failure.** When the model is unsure or the context is thin, the
   feature says so rather than filling the gap with confident noise.
10. **AI is labeled only where it helps.** Deterministic logic (like the
    existing Up-next engine) is not called AI, and AI output is never
    passed off as computed fact.

---

## 2. High-value use cases

Ordered roughly by value ÷ risk. Each lists what would make it real.

### 2.1 Natural-language capture (top candidate for v1 AI)

- **User problem:** Logging is the tax the whole app runs on. Typing
  "coffee 4.50", picking a category, picking a date — that's three steps
  for a four-word thought.
- **Proposed behavior:** One capture field (extends the existing quick-add
  sheet): "coffee 4.50 yesterday", "ran 30 min", "idea: pitch the workshop
  to Sam", "step: sent 3 outreach emails, one replied — worked". The model
  parses to a typed draft (expense / time block / habit log / idea / goal
  step) shown as a prefilled form the user confirms with one tap.
- **Required data:** The typed text; the user's category names, habit
  names, and measure units (small, local context).
- **User controls:** Confirm/edit/cancel on every parse; feature can be
  switched off; falls back to the normal quick-add grid.
- **Risks / failure modes:** Wrong amounts or categories → mitigated by
  the confirm step and conservative defaults (uncategorized rather than
  guessed). Ambiguity → the draft shows what was assumed.
- **Privacy:** Sends only the capture text + entity names. No history.
- **Trigger:** User-typed, never proactive.
- **Cloud or local:** Small local model plausible; cloud gives better
  parses. Either fits behind the same interface.
- **Phase:** 1.

### 2.2 Weekly review summary

- **User problem:** The data is all there — hours, spend, steps, verdicts —
  but reading five screens to understand a week is work nobody does.
- **Proposed behavior:** A user-requested "Week in review": 5–8 sentences.
  What moved on the goal, what the verdicts say, where money and time
  actually went vs plan, one suggested emphasis for next week. Every claim
  cites its number.
- **Required data:** The week's aggregates (hours by kind, spend by
  category, steps + verdicts, habit completion). Aggregates, not raw notes,
  unless the user opts notes in.
- **User controls:** Generated on tap; nothing scheduled unless enabled;
  notes excluded by default.
- **Risks:** Moralizing tone; hallucinated causality ("you overspent
  because you skipped meditation"). Mitigation: template the claims to
  cite computed numbers, keep inferences clearly hedged, tone-check against
  the app's voice (calm, never scolding).
- **Phase:** 2.

### 2.3 Goal decomposition (milestone drafting)

- **User problem:** "Publish my novel" is a goal; the blank milestone list
  is where momentum dies.
- **Proposed behavior:** On the Focus tab, "Suggest milestones" drafts
  4–7 concrete milestones (with rough ordering and optional measures) from
  the goal title + why + timeframe. The user edits/deletes freely; nothing
  is saved until accepted.
- **Required data:** Goal title, why, target date. Nothing else.
- **Risks:** Generic plans; wrong domain assumptions. Mitigation: show as
  editable drafts, never auto-save, ask one clarifying question when the
  goal is ambiguous.
- **Phase:** 1–2 (small surface, high perceived value).

### 2.4 Daily brief ("morning plan" upgrade)

- **User problem:** The morning reminder currently shows a rotating static
  line. The user still has to assemble "what does today look like?"
- **Proposed behavior:** An opt-in brief when opening the app in the
  morning (or in the notification): yesterday's step outcome, today's
  best next action, one money/time signal if any is off pace. Three
  sentences maximum.
- **Required data:** Same aggregates the Today screen already computes.
- **Risks:** Notification fatigue; repetitive content. Mitigation: skip
  the brief when there's nothing new to say (deterministic gate).
- **Phase:** 2 (in-app), 3 (proactive notification).

### 2.5 Blocker and pattern detection

- **User problem:** Recurring blockers hide in the daily-step verdicts
  ("didn't work" clusters, missed-day patterns, ideas that keep
  resurfacing).
- **Proposed behavior:** In the weekly review (not standalone): "Three of
  four 'didn't work' entries this month mention scheduling — mornings
  might be the wrong slot." Presented as an observation with the entries
  it came from.
- **Required data:** Step logs incl. text; explicitly opted in because
  this reads user prose.
- **Risks:** Over-pattern-matching on tiny samples. Mitigation: minimum
  data thresholds before the section appears at all.
- **Phase:** 2–3.

### 2.6 Conversational retrieval ("ask your data")

- **User problem:** "When did I last update the brokerage balance?" "How
  many hours did the goal get in March?" — answerable, but only by digging.
- **Proposed behavior:** A question box that translates questions into
  local queries and answers with numbers + a link to the source screen.
  Tool-calling over local repositories; the model never sees the whole
  database, only query results.
- **Risks:** Wrong query → wrong answer stated confidently. Mitigation:
  show the interpreted question ("Hours on 'Kaizen' between Mar 1–31")
  alongside the answer.
- **Phase:** 3.

### 2.7 Plan reality-check

- **User problem:** Weekly targets that add to 190 hours; surplus targets
  above income; goal timeframes that don't match the pace of logged
  progress.
- **Proposed behavior:** Mostly **deterministic** (Phase 0): arithmetic
  contradictions are flagged by plain code. AI's only role (Phase 2+) is
  phrasing a humane renegotiation ("At the current 4 h/week, June 1 is
  unlikely — move the date, or protect two more hours?").
- **Phase:** 0 for detection, 2 for phrasing.

### Explicitly not planned

- Automatic transaction categorization without confirmation.
- AI-generated motivational content, streak "celebrations", or coaching
  personas.
- Chat as the primary interface. Life Assist is a glanceable tool; chat is
  a retrieval affordance (2.6), not the product.

---

## 3. Architecture plan

### 3.1 Layering

```
lib/core/ai/
├── ai_availability.dart      // feature-gate: off | local | cloud
├── ai_service.dart           // provider-agnostic interface
├── providers/                // one adapter per backend
│   ├── cloud_provider.dart   // e.g. Anthropic/OpenAI-compatible HTTP
│   └── local_provider.dart   // future: on-device model
├── prompts/                  // versioned prompt templates (checked in)
├── context_builder.dart      // assembles minimal, typed context windows
├── schemas/                  // structured-output schemas per use case
└── ai_log.dart               // user-visible history of AI calls
```

- **Provider abstraction:** `AiService.complete(request) → AiResult`,
  where `request` carries a prompt id + typed context and `AiResult` is
  parsed against a per-feature JSON schema. Swapping providers (or adding
  a local model) touches only `providers/`.
- **Prompt/version management:** Prompts are versioned files; every log
  entry records prompt id + version so behavior changes are diffable.
- **Structured outputs:** Every feature defines a schema (e.g.
  `CaptureDraft { type, amount?, categoryId?, date, … }`). Non-conforming
  responses are retried once, then the feature degrades to its non-AI
  fallback. No free-text is ever written to the database.
- **Tool calling:** Only for retrieval (2.6), against a fixed allowlist of
  read-only repository methods. No write tools, ever — writes go through
  the confirm-UI.
- **Context assembly:** `context_builder` produces the *minimum* typed
  context per feature (names/units for capture; weekly aggregates for
  review). One place to audit exactly what can leave the device.
- **Permission boundaries:** Three user-facing switches, all default-off:
  *AI features*, *include notes/prose*, *proactive briefs*. Each maps to a
  hard gate in `context_builder`, not just UI.

### 3.2 Operational concerns

- **Caching:** Deterministic cache key = prompt version + context hash.
  Weekly reviews and milestone drafts cache locally; capture parses don't.
- **Rate & cost controls:** Per-feature daily budgets with a visible
  counter; hard stop with a plain message, never silent truncation.
- **Retries / offline:** One retry on transient failure, then the non-AI
  fallback with an honest "AI is unavailable right now". Requests carry
  short timeouts so the UI never blocks on the network.
- **Logging without leaking:** `ai_log` stores timestamps, feature, prompt
  version, token counts, and the *result* — not the raw context. The log
  is user-visible (Settings → AI activity) and clearable.
- **Feedback:** Every AI surface has a lightweight "useful / not useful"
  toggle stored locally — the evaluation set for prompt changes.
- **Evaluation:** A fixture suite of anonymized capture strings and
  synthetic weeks, replayed against prompt changes in CI
  (`dart test test/ai/`), asserting schema validity and key fields.
- **Hallucination mitigation:** Numbers in summaries are computed by Dart
  and interpolated into the text (the model writes around them, not the
  numbers themselves) — the same pattern the deterministic Up-next engine
  uses today.
- **Safety boundaries:** System prompts pin the role ("a calm assistant
  inside a personal tracking app"), forbid prescriptive
  medical/financial/legal advice, and cap output length. User text is
  treated as data, not instructions, and prompt-injection checks are part
  of the fixture suite.
- **Keys:** No API keys in the repo or the binary. Cloud AI requires the
  user's own key (stored in platform keychain) or a proxy with anonymous
  tokens — decided per release; either way the app runs fully without one.

### 3.3 Phasing

| Phase | Scope | Ships when |
| --- | --- | --- |
| **0 — Deterministic intelligence** (no AI) | Plan reality-checks (targets vs 168h, surplus vs income, goal pace vs timeframe); smarter empty states; "week in numbers" screen assembled from existing aggregates | Anytime; no new dependencies |
| **1 — User-triggered assistance** | Natural-language capture (2.1); milestone drafting (2.3). Both behind the AI switch, both confirm-before-write | After the AI service layer + settings + log exist |
| **2 — Review & planning intelligence** | Weekly review (2.2); daily brief in-app (2.4); humane plan renegotiation (2.7); blocker surfacing inside reviews (2.5) | After Phase 1 telemetry shows parses are trusted (low edit-rate) |
| **3 — Careful proactivity** | Brief-as-notification; standing pattern detection; conversational retrieval (2.6) | Only with per-surface opt-in and a proven quiet-by-default record |

### 3.4 The smallest valuable first release

**Natural-language capture (2.1), alone.** It touches the app's highest-
frequency action, its value is felt in the first minute, its risk is
bounded by the confirm step, its context is tiny (entity names only), and
it exercises the entire architecture (service, schema, confirm flow, log,
fallback) — so everything later is an addition, not a rebuild.

---

## 4. Open questions to resolve before Phase 1

1. Key strategy: bring-your-own-key vs proxied service (and what that does
   to the "no account" promise).
2. Whether a small on-device model clears the capture-parsing quality bar
   on mid-range phones.
3. Where AI settings live so they're findable but not promoted (current
   lean: Settings → "AI features", collapsed by default).
4. What the edit-rate threshold is for calling Phase 1 "trusted enough"
   to build Phase 2.
