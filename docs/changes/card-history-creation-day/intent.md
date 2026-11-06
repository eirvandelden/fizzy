# Intent: Show the creation day in a card's full history

Author: Etienne van Delden de la Haije. Status: accepted. Type: feature. Delivery: autonomous. Codex review: no.

## Problem

Someone who expands "Full history" on a card sees moves, assignments and title changes. They cannot see the day the card was created.

## Proposed outcome

Expanded history starts with a row that states who created the card and on which day. The collapsed view stays as it is today.

## Affected users and systems

Everyone who opens a card. The card view's system comments and their CSS (`app/views/cards/_messages.html.erb`, `app/assets/stylesheets/comments.css`). No stored data changes.

## Constraints

- This change is for Etienne's fork (`origin`, `eirvandelden/fizzy`) and NOT for upstream (`basecamp/fizzy`). Push only to `origin`. Open the pull request against `origin`. Never push to or open a pull request against `upstream`. `plan.md` must state this at the top.
- The row comes from the card's `created_at`, so cards that exist today get it too. No new event, no backfill.
- Drafts do not show it: history only shows on published cards.

## In scope

- A creation row at the top of the expanded history, styled like the other system rows.
- The row hides with the rest of the history when history is collapsed.

## Out of scope

- A creation date in the collapsed view.
- A new creation event or system comment record.
- API (JSON) output.

## Acceptance criteria

- Clicking "Full history" on a card shows "Created by Ana" with the creation day above the first move.
- A card with no other history has no "Full history" button, as today, and shows no creation row.
- Collapsing the history hides the creation row again.
- A card created before this change shows its creation row too.

## Decisions

- Show the creation row only when history expands — chosen over an always-visible date and over a stored creation event.
- Deliver autonomously, without a Codex review — no reason given.
- The change targets the fork, not upstream, and the plan says so clearly — requested by Etienne, no reason given.

## Open questions

None.
