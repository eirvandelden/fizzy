# Intent: Run Solid Queue in async mode inside Puma

Author: Etienne van Delden. Status: accepted (2026-10-26). Type: chore. Delivery: autonomous. Codex review: no.

## Problem

Fizzy on the Kamal host CT104 (3 cores, 12 GB, about 12 apps, 2 to 5 users per app) uses 919 MB across 7 Ruby processes. The Solid Queue Puma plugin forks a supervisor, a dispatcher, a scheduler and a worker. The supervisor, dispatcher and scheduler hold 46, 56 and 56 MB of private memory. Throughput does not matter at this user count; memory does.

## Proposed outcome

Production runs Solid Queue as threads inside the Puma process. The three forked processes disappear. Expected saving: about 160 MB for the app. Puma runs one worker, so the Puma worker memory also drops by about 195 MB.

## Affected users and systems

- The production Kamal deploy on CT104 (deployed by Etienne, not by agents).
- Background jobs, recurring tasks and mail delivery, which run in the Puma master process after this change.
- Upstream merges: `config/puma.rb` is a fork-local diff against basecamp/fizzy, so it stays minimal.

## Constraints

- Etienne approved edits to `config/deploy.yml` and `config/puma.rb` for this change (playbook rule 13). No other deploy files change.
- No new gems, no migrations.
- Settings live in `deploy.yml`, not in application code (the approach of commit 441978c88).
- Never run kamal commands. Never read secrets.
- Unrelated uncommitted files in the main checkout stay untouched.
- The README of solid_queue 1.7.0 recommends fork mode. Etienne chose async on purpose, for memory.

## In scope

- `config/puma.rb`: add `solid_queue_mode :async` directly after `plugin :solid_queue`, inside the existing `unless` block.
- `config/deploy.yml` `env.clear`: `WEB_CONCURRENCY` from 2 to 1.
- `config/deploy.yml` `env.clear`: add `RAILS_MAX_THREADS: 10`, so the shared queue database pool (default 5) covers 3 worker threads, the dispatcher, the scheduler, the heartbeat and the Puma thread. `RAILS_MAX_THREADS` is read only in `config/database.sqlite.yml`; Puma runs `threads 1, 1` and ignores it.
- Local production-like verification, with the evidence recorded.

## Out of scope

- Deploying, and any kamal command.
- Removing `JOB_CONCURRENCY` (it has no effect in async mode; keeping it is the smaller diff).
- `WEB_CONCURRENCY=0` (single mode).
- Changing `config/queue.yml`, `config/database.sqlite.yml` or the container image.
- Any change to SaaS mode.

## Acceptance criteria

- A production-like boot (`RAILS_ENV=production`, `SECRET_KEY_BASE_DUMMY=1`, scratch SQLite path, `SOLID_QUEUE_IN_PUMA=true`, `WEB_CONCURRENCY=1`) shows `ps` with one Ruby Puma master and one Puma worker, and no solid-queue-supervisor, -dispatcher, -scheduler or -worker process.
- An enqueued job runs in that boot, in the Puma master.
- The recurring tasks of `config/recurring.yml` load (including `Appkit::SessionExpiryJob` where present).
- `/up` returns 200.
- The full test suite and every linter stay green.

## Decisions

- Puma stays in cluster mode with `WEB_CONCURRENCY` 1 — Etienne chose the recommended option over single mode, to keep requests apart from jobs.
- Raise `RAILS_MAX_THREADS` to 10 in `deploy.yml` rather than editing database config — smallest diff, same approach as commit 441978c88.
- Keep `JOB_CONCURRENCY` — smaller diff.
- Delivery is autonomous, without Codex review — Etienne chose it.

## Open questions

None.
