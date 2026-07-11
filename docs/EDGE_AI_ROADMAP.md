# Life Assist — Edge AI Roadmap

*Forward-looking companion to [SIRI_AI_BLUEPRINT.md](SIRI_AI_BLUEPRINT.md).
That document's Phases 0–4 shipped the foundation: the Foundation Models
bridge, four AI surfaces, and the Siri App Intents rails. This one maps
where on-device ("edge") AI goes from here. Nothing below requires a
server, an account, or an API key — that is the point.*

## Ground rules (these never change)

1. **Availability-gated.** Every AI surface checks the bridge and hides
   itself completely when the model isn't there. No teasers, no "upgrade
   your phone" nags.
2. **Zero silent writes.** Model output is always a draft the user
   confirms through the same sheets manual entry uses. The database
   never changes because a model said so.
3. **No invented entities.** Category/budget/habit suggestions are
   constrained to the user's real lists (`@Guide` enumerations on the
   Swift side, name filtering on the Dart side — both shipped).
4. **Numbers only when fresh.** Anything that speaks or renders a figure
   checks the feed is from today (the `today.json` dateKey gate).
5. **On-device first.** Data leaves the phone only through an explicit,
   per-run, user-visible action — and even then only to Apple's Private
   Cloud Compute envelope (Stage E5), never to third-party clouds.

## Where we are (shipped, v4)

- `lifeassist/ai` MethodChannel → `AiBridge.swift`, fully inside
  `canImport(FoundationModels)` + iOS 26 availability gates:
  `parseCapture` (guided generation via `@Generable`/`@Guide`),
  `categorizeTransactions` (chunked ≤20, name-constrained),
  `draftWeeklyReview`, `triageIdea`.
- Surfaces: smart-capture field on Today, "Suggest categories" in CSV
  import, "Draft from the numbers" in Weekly Review, "Expand" in idea
  capture.
- The assistant's "hands": five background App Intents (log expense,
  log time, park idea, add reminder, check habit) + query intents +
  voice undo — the rails iOS 27's Siri AI drives.
- `IndexedEntity` conformance (iOS 18+) feeds the system's semantic
  index.

## Stage E1 — deepen Foundation Models (iOS 26+)

The cheapest wins sit on rails that already exist.

- **Multi-turn sessions with streaming.** Keep one
  `LanguageModelSession` per surface and stream partial generations
  (`streamResponse`) so capture chips appear as they parse instead of
  after. Session instructions embed the entity name lists and the fresh
  `today.json` — grounding without new plumbing.
- **Tool calling (FM `Tool` protocol).** Register read-only tools —
  month spend by category, budget targets, habit status — backed by the
  same mirror files Siri answers use. The model can then answer grounded
  questions ("could I afford a $400 flight this month?") by *calling*
  for exact cents instead of hallucinating arithmetic. Math computes,
  the model narrates. Writes stay impossible: no write tools exist.
- **Adapters, only if measured need.** Apple's adapter-training toolkit
  can specialize the on-device model for the capture-parse task. Gate
  this on data: locally count how often users accept vs edit drafts
  (a Settings diagnostics number, never uploaded). Few-shot prompting
  is likely enough; adapters are a maintenance tail (retrain per base-
  model update), so they must earn their keep.

## Stage E2 — semantic memory (works from iOS 17, no new deps)

- **Sentence embeddings** via `NLEmbedding`/`NLContextualEmbedding`
  (Natural Language framework) for journal entries, parked ideas, and
  transaction descriptions. At this app's scale (thousands of rows) a
  brute-force cosine scan over an on-disk float table is instant — no
  vector database, no dependency.
- Surfaces: *related lines* under a journal entry ("you wrote something
  like this in March"), duplicate detection when parking an idea ("this
  cooled once before — see verdict"), and semantic hits merged into the
  existing search sheet next to the LIKE results, clearly labeled.
- When iOS 26+ exposes better embeddings through Foundation Models,
  swap the encoder behind the same interface; the NL* floor keeps the
  feature on iOS 17–25.

## Stage E3 — speech and vision capture

- **Voice journal (iOS 26 `SpeechAnalyzer`).** Hold-to-talk on the
  journal composer; on-device transcription feeds the *existing*
  `parseCapture` pipeline, so "spent forty at the farmers market and
  slept badly" becomes an expense draft *and* a journal line — both
  confirmed, never auto-saved.
- **Receipt scan (VisionKit document recognition).** Camera → recognized
  line items → the same draft-chips confirm flow CSV import uses. One
  pipeline, three inlets (CSV, voice, camera).

## Stage E4 — proactive noticings (opt-in, statistics first)

- A weekly on-device pass (BGProcessingTask) drafts two or three
  observations from exact cents data — "Groceries pace is +18% vs your
  three-month average" — surfaced as *drafts inside Weekly Review*,
  never as unprompted pushes.
- Detection is plain statistics (z-scores over weekly category cents) —
  deterministic, testable on Linux CI. The model only phrases the
  sentence. If the model is unavailable, the raw stat still shows;
  honesty does not depend on eligibility.

## Stage E5 — Private Cloud Compute (deferred, explicit)

Jobs that genuinely exceed on-device context — a year-in-review
narrative across four thousand transactions and 300 journal lines —
can use Apple's PCC (server-class model, Apple's auditable privacy
envelope, free tier under the Small Business Program). Rules: opt-in
per run with a visible "processed by Apple's private cloud" label,
never a default, never a third-party vendor. Not scheduled; revisit
when a concrete feature needs it.

## Explicit non-goals

- No cloud-LLM vendor SDKs, keys, or accounts.
- No telemetry about AI usage leaving the device (acceptance counters
  are local diagnostics the user can see and clear).
- No auto-categorization or auto-logging without a confirm step.
- No chatbot tab — the assistant lives in Siri and small inline
  surfaces, not a text adventure inside a life dashboard.

## Constraints cheat-sheet

| Capability | Needs | Notes |
| --- | --- | --- |
| Guided generation, Tool calling | iOS 26 + Apple Intelligence device | availability-gated; ~4k-token sessions, chunk inputs (≤20 txns/call, shipped pattern) |
| `SpeechAnalyzer` | iOS 26 | on-device transcription |
| `NLEmbedding` | iOS 13+ | the semantic floor for 17–25 |
| `IndexedEntity` Spotlight | iOS 18+ | shipped |
| Adapters | offline training, ships in app | retrain per base-model release — adopt only with measured need |
| PCC | Apple Intelligence + opt-in UX | deferred (E5) |

## Sequencing

E1 → E2 → E3 → E4 → E5. E1 rides shipped rails; E2 is pure Dart + a
system framework and testable on CI; E3 reuses the draft-confirm
pipeline; E4 needs the background-task budget; E5 waits for a feature
that deserves it. Every stage lands behind the same five ground rules
at the top of this file.
