/// Money policy (schema v4): amounts are stored and summed as integer
/// cents. Doubles appear only at the edges — user input (a parsed text
/// field) and display (formatters take dollars) — and each edge converts
/// exactly once through these helpers. Never sum doubles.
library;

/// `4.35` → `435`. Exact for any two-decimal amount a user can type;
/// rounding covers binary-representation dust (4.35 * 100 = 434.99…).
int centsFromAmount(num amount) => (amount * 100).round();

/// `435` → `4.35`, for display and form prefills. The result is within
/// half an ulp of the true value, so formatting to two decimals always
/// prints the cents back verbatim.
double amountFromCents(int cents) => cents / 100.0;
