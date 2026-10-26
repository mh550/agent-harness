# The queue runner re-reads its config each poll: `MAX_PARALLEL_RUNS` applies without a restart

*(2026-10-26, run agent-harness-2026-10-25-lifecycle, feature L5-01; spec `docs/specs/2026-10-25-resource-lifecycle.md`
§L5, which takes H2 of `docs/specs/2026-10-22-tmux-and-queue-hygiene.md` as written)*

- **Finding:** `lib/queue.sh` sourced the config once, at start-up, and read `MAX_PARALLEL_RUNS` (and, through
  `weekly_over`, `WEEKLY_STOP_AT`) from that snapshot for the whole night. Widening or narrowing parallelism meant
  restarting the runner, and a clean `harness queue stop` triggers a debrief: there was no quiet way to change it.
- **Choice:** at the top of every loop iteration the runner re-runs `harness_config /nonexistent` (the same call as at
  start-up; it resets every key to its default, then re-sources the layers, so it is idempotent) and logs
  `MAX_PARALLEL_RUNS <old> → <new> (config reloaded)` in `runner.log` when the value changed. Raising it lets the next
  poll start more; lowering it only gates *starting* (the loop never stops a run), so running runs finish and an entry
  waits until fewer than the new value are alive. `WEEKLY_STOP_AT` and the rest of the config are fresh each poll
  too. `HARNESS_QUEUE_POLL` stays as set at start-up (an env var, not config).
  - *default:* a value that is no plain whole number (`^(0|[1-9][0-9]*)$` fails: `2x`, or `08`, which bash reads as
    octal) keeps the previous one and is logged once (`MAX_PARALLEL_RUNS=<v> in the config is not a whole number:
    keeping <n>`): bash's `(( a >= 2x ))` fails, and the loop would fall through and start a run past the limit. An
    empty value counts as 0 in bash arithmetic and would hold every start without a word; the guard catches it too.
    Not caught: a file sourced while an editor has it truncated falls back to the default (1) for that poll; both
    changes are logged and no run is stopped (review of L5-01).
- **Rejected:**
  - **A SIGHUP handler:** needs a signal sent by hand (the runner lives in tmux `h-queue`; its pid in
    `queue/runner.pid`), a trap that can fire mid-`sleep` or mid-start, and a second way to get the config wrong. One
    `source` per poll costs nothing at a 30 s poll.
  - **Re-reading in `harness start` only:** `harness start` already reads the config, but the runner decides whether
    to call it; the snapshot in the runner is what blocks the second run, so only the runner re-reading fixes it.
