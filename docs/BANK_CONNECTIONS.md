# Bank account tracking — what's real today, and how live feeds plug in

## What ships in the app now

Real account tracking, honestly scoped to what a local-first app can do
without third-party credentials:

- **Accounts** (Money → The long game): every bank, credit card, cash
  stash, and investment pot as a first-class record. Balances update in
  two taps; every update writes a dated `BalanceSnapshot`, so net worth
  has real history (and a trend line once two snapshots exist). Credit
  balances subtract. Anything can be excluded from net worth.
- **CSV statement import** (Money → Transactions → ⋯ → Import statement):
  the actual data your bank exports becomes real transactions. The
  importer handles comma/semicolon/tab files, US and European dates and
  decimal formats, negative-debit and positive-debit conventions, skips
  deposits, and detects duplicates against what's already logged — so
  re-importing an overlapping statement is safe.
- **Recurring expenses**: rent and subscriptions land as real
  transactions on their day each month, idempotently.
- The pre-v3 manual "brokerage/savings" numbers are migrated into
  Accounts automatically (LegacyMigration v3).

This covers the daily loop: import a statement weekly or monthly, punch
in balances when you check them, and the month view, budgets, surplus
history, and net worth all run on real bank data.

## Why live feeds aren't flipped on by default

Live bank connections (Plaid, MX, Finicity, SimpleFIN, GoCardless/Nordigen,
Tink…) all require:

1. **Developer credentials** — a client id/secret issued to *you* after
   registering with the aggregator (and, for most, a billing agreement).
2. **A token-exchange server** — the OAuth-style link flow exchanges a
   public token for an access token using the *secret*, which must never
   ship inside the app binary. Even a tiny serverless function counts,
   but it must exist and it must be yours.
3. **Ongoing consent plumbing** — webhooks or polling, re-auth when banks
   rotate credentials, and (in the EU) PSD2 consent renewal.

None of that can be embedded in a local-first app without shipping
secrets or standing up infrastructure on the user's behalf, so the app
doesn't pretend to. Anything that claimed "live bank sync" out of the box
here would be either insecure or fake.

## The integration seam (when you have keys)

The schema and data flow are already shaped for a provider:

- `Accounts` has a stable id and kind; a provider integration adds a
  `provider` + `providerAccountId` mapping (new columns or a side table —
  schema v4).
- Imported transactions already carry `accountId` and a duplicate key
  (`date|amount|description`) — a feed writes through the same
  `MoneyRepository.addTransactionsBatch` path the CSV importer uses, so
  dedupe, budgets, flags, and history all work unchanged.
- Balance updates write through `AccountsRepository.setBalance`, which
  snapshots automatically.

Recommended shape for a self-hosted setup (cheapest honest option):

1. Register for **SimpleFIN Bridge** (consumer-priced, token-based, no
   server needed for read-only access) or a Plaid developer account.
2. For SimpleFIN: store the access URL in the app (Settings), fetch
   `/accounts` JSON periodically, map to `Accounts` + transaction batches.
3. For Plaid: deploy the ~50-line token-exchange function (Plaid's
   quickstart), add a "Connect bank" flow that opens Plaid Link, then
   sync via `/transactions/sync` into the same repositories.

Either path is an additive feature module (`features/money/data/feeds/`)
with no changes required to budgets, surplus math, or the UI above it.
