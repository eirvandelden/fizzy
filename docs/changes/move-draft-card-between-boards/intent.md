# Intent: Move a draft card between boards

Author: Etienne van Delden de la Haije. Status: accepted. Type: bugfix. Delivery: autonomous. Codex review: no.

## Problem

Etienne presses "Create card", then switches the card to another board. Production raises `ActiveRecord::RecordNotUnique: UNIQUE constraint failed: cards.board_id, cards.creator_id` and the move fails.

The cause: the production SQLite database has a partial unique index, `index_cards_on_board_creator_drafted`, on `cards(board_id, creator_id) WHERE status = 'drafted'`. It allows one draft per user per board. A move fails when the user already has a draft on the target board. The index is in no migration and no commit. It is only in the uncommitted `db/schema_sqlite.rb` dump of the live database. Upstream `basecamp/fizzy` has no such index.

## Proposed outcome

A draft card moves to any board the user can access, including a board where the user already has a draft. Behaviour matches upstream.

## Affected users and systems

- Every user who creates a card and changes its board.
- The production SQLite database at tasks.vandelden.family, and any local database that carries the index.
- `Card#move_to` and `Cards::BoardsController#update` behave correctly once the index is gone; the intent does not change them.

## Constraints

- Match upstream code as much as possible (Etienne's preference).
- The fix is one migration that drops the index with `if_exists: true`, so it is safe on databases that never had it. Approved permission: this one index-dropping migration. No gems, no table or column drops.
- No deploy. Etienne approves and runs any deploy himself (playbook rule 13).
- The uncommitted drift in `db/schema_sqlite.rb` and `db/cable_schema.rb` stays out of the commit (playbook rule 21).
- Rule 3: a bug-fix regression test is written first and fails before the fix. The committed schema has no such index, so the test must create the index itself to reproduce the production state.

## In scope

- A migration that drops `index_cards_on_board_creator_drafted`.
- A regression test: a draft card moves to a board where the same user already has a draft.

## Out of scope

- The fork-only retry in `User::Accessor#draft_new_card_in` and `resync_cards_count_for`.
- The fork-only change to `Card#assign_number`. It probably works around SQLite having no row locks.
- Any guard against two simultaneous "create card" requests making two drafts. Upstream accepts that risk.
- Deploying the migration.
- Finding out who or what created the index.

## Acceptance criteria

- A user with a draft on board A and a draft on board B moves the draft from A to B. The move succeeds and both drafts exist on board B.
- A user with one draft on board A moves it to board B, which has no draft of theirs. The move still succeeds.
- Running the migration on a database without the index does not raise.
- Running the migration on a database with the index removes it.

## Decisions

- Match upstream and remove the index instead of reworking `move_to` — "I would rather have as much as possible upstream code".
- Keep the other fork-only changes out of this fix — they probably work around SQLite, which has no row locks; review them on a separate branch.
- Autonomous delivery without a Codex review — chosen at intake, no reason given.

## Open questions

None.
