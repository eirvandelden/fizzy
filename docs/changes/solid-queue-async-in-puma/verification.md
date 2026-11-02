# Verification: Run Solid Queue in async mode inside Puma

Run on 2026-11-02, macOS, from the worktree, with `bin/rails server -p 3999` (no Thruster, no kamal-proxy).
Environment variables are the ones in `plan.md` step 2 (before) and step 5 (after).
Scratch databases: `storage/production*.sqlite3`, proven absent before the run and deleted after it.

## Guard

`ls storage/production*.sqlite3*` printed nothing before `db:prepare`.
`db:prepare` created the four production SQLite files and loaded the schema. Its seed step then aborted with "Seeding is just for development!", which is expected in production and left the schema intact.

## Before (fork mode, `WEB_CONCURRENCY=2`)

`/up` returned 200. Process tree of the pid-file master 28402:

```
  PID  PPID    RSS COMMAND
28402 28398 195264 puma 8.0.2 (tcp://0.0.0.0:3999)
28671 28402  13920 puma: cluster worker 0
28672 28402  53472 puma: cluster worker 1
28673 28402  69856 solid-queue-fork-supervisor(1.7.0): supervising 28674, 28675, 28676
28674 28673  64240 solid-queue-dispatcher(1.7.0): dispatching every 1 seconds
28675 28673  60128 solid-queue-worker(1.7.0): waiting for jobs in default,solid_queue_recurring,backend,webhooks,*
28676 28673  52288 solid-queue-scheduler(1.7.0): scheduling deliver_bundled_notifications,...
```

Seven Ruby processes, about 509 MB RSS in total. SIGTERM stopped everything cleanly, in about 30 s.

## After (async mode, `WEB_CONCURRENCY=1`, `RAILS_MAX_THREADS=10`)

`/up` returned 200. Process tree of the pid-file master 30066:

```
  PID  PPID    RSS COMMAND
30066 30060 202400 puma 8.0.2 (tcp://0.0.0.0:3999)
30233 30066  39424 puma: cluster worker 0
```

Two Ruby processes, about 242 MB RSS in total. No `solid-queue-supervisor`, `-dispatcher`, `-scheduler` or `-worker` process, and the worker has no children.
RSS on macOS shifts as memory compresses (a later sample of the master read 65 MB), so treat these as indicative. The container on Linux is the real measure.

Job enqueued from a separate `bin/rails runner`, id `850a9169-9611-4a24-ac0c-a4cbc4f084d6`. Log line, pid `30066` equals the master:

```
I, [2026-11-02T14:54:41.097012 #30066]  INFO -- : [ActiveJob] [DeleteUnusedTagsJob] [850a9169-...] Performed DeleteUnusedTagsJob (Job ID: 850a9169-...) from SolidQueue(default) in 26.33ms
```

`SolidQueue::Job#finished_at`: `2026-11-02 13:54:41.102597000 UTC`.

`SolidQueue::Process.pluck(:kind, :pid)`:

```
[["Supervisor(async)", 30066], ["Dispatcher", 30066], ["Worker", 30066], ["Scheduler", 30066]]
```

`SolidQueue::RecurringTask.pluck(:key).sort` (the 10 production keys; `Appkit::SessionExpiryJob` does not exist in this repository):

```
["auto_postpone_all_due", "cleanup_exports", "cleanup_imports", "cleanup_magic_links", "cleanup_transfers", "cleanup_webhook_deliveries", "clear_solid_queue_finished_jobs", "delete_unused_tags", "deliver_bundled_notifications", "incineration"]
```

`SolidQueue::Record.connection_pool.size`: `10`.

SIGTERM: the log shows `Release claimed jobs`, shutdown of the dispatcher, scheduler and worker, `Supervisor terminated gracefully (170.8ms)` and `Exiting`, in about 1 s. The master was gone afterwards and the process listing was empty. `SolidQueue::Process.count` afterwards: `0`.
The server's own exit status was not captured, because the shell tool launched it as a detached background job. Its graceful-shutdown log and absence from `ps` stand in for it.
A search of `tmp/verify-after.log` for `ConnectionTimeoutError`, `Exception` and `Error` found no hit.

## Checks

See the commit message and the implementation report for the test and linter output.
