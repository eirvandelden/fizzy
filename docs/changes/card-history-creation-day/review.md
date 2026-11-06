# Review: Show the creation day in a card's full history

## Round 1 — 2026-11-06T20:33Z — 2fd410830

No REVIEW.md or REVIEW.local.md at the repository root; the default Bugs, Security, Compliance and Design passes ran.

Checks: `bin/rails test` 2593 tests, 0 failures, 0 errors (5 skips, none added by this branch); `PARALLEL_WORKERS=1 bin/rails test test/system/card_history_test.rb` 4 tests green; `bin/rubocop` no offenses; `bin/brakeman` no warnings.

Compliance:
- "Full history" shows "Created by Ana" with the day above the first move → `test/system/card_history_test.rb` "full history shows the creation row first".
- A card with no other history has no button and no creation row → `test/system/card_history_test.rb` "a card with one system comment shows no full history button and no creation row" and "a card with no system comments shows no creation row".
- Collapsing hides the creation row → `test/system/card_history_test.rb` "collapsing the full history hides the creation row".
- A card created before this change shows its row → `test/controllers/cards_controller_test.rb` "show renders the creation row from the card's created_at".
- Every test in `plan.md`'s Proof exists, including the query-count tests in `test/views/cards/creation_test.rb`. No jbuilder file changed. No existing test was weakened, skipped or deleted.

Bugs: none. The `:not(.comment-by-system--creation)` selectors keep the collapsed view and the button logic on the same rows as before; the SaaS storage-limit row is unaffected.

Security: none. The creator name is escaped by ERB and a test proves it. No new parameters or queries from user input.

Design: none. No Ruby method was added, so `### Signatures` holds. No loop; the row adds at most one creator lookup, as the `Query count:` Proof line states. No glossary exists.

No findings.
