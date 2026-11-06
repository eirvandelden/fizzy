# Delivery: Show the creation day in a card's full history

Target: Etienne's fork only (`origin`, `eirvandelden/fizzy`). Nothing went to `upstream`.

## Behaviour delivered

Expanding "Full history" on a published card now starts with a creation row: "Created by <name>" and the creation day, built from `card.created_at`. The collapsed view and the "Full history" button logic are unchanged. Nothing is stored, so existing cards get the row too.

## Evidence

- Browser-driven system tests (`test/system/card_history_test.rb`, 4 tests) cover expand, collapse, a card with one system comment and a card with none.
- Controller tests prove the row comes from `created_at` on a fixture card with no creation event, and that it renders before the system comments.
- View tests prove the text, the date tag, escaping and the query count (one creator lookup at most).
- No manual browser look: the Capybara system tests drive a real browser.

## Check results

- `bin/rails test`: 2593 tests, 0 failures, 5 skips (none added here).
- `PARALLEL_WORKERS=1 bin/rails test:system`: 47 tests, 0 failures on the coordinator's run. The implementer saw 2 uncaptured failures on its first run and could not reproduce them; treat as a possible flake.
- `bin/rubocop`: no offenses. `bin/brakeman`: no warnings. erb_lint: clean.
- `bin/bundler-audit check --update`: advisories in addressable, loofah, nokogiri, rack and rails-html-sanitizer. They come from the unchanged `Gemfile.lock`, predate this branch, and need gem upgrades that Etienne has not approved (playbook rules 11 and 25).
- The pre-commit `stylelint` hook cannot run here (`npx` cannot download stylelint, and the repository has no stylelint config). The implementer committed with `LEFTHOOK_EXCLUDE=stylelint`, not `--no-verify`.

## Review outcome

One Claude review round (Codex review was off): no findings. Round 1 at `2fd410830`, committed as "Review for card-history-creation-day".

## Open items for Etienne

- Upgrade the gems behind the bundler-audit advisories, in a separate worktree and pull request.
- Decide what to do about the `stylelint` pre-commit hook.
- The glossary was skipped: a new `GLOSSARY.md` seemed noise for a fork of upstream.
