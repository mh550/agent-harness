# `harness eval run` stops starting tasks at EVAL_BUDGET_USD and past WEEKLY_STOP_AT; `--repeat N` runs each task N times

*(2026-10-21, E2-04 of run agent-harness-2026-10-21-measure; plan `docs/plans/2026-10-21-E2-evals.md` §3.6–3.7;
builds on `decisions/2026-10-21-eval-run-isolation`)*

- **Finding:** an eval is real sessions on Michael's plan: a set of ten tasks costs about $75, and the replays share
  the plan's 7-day window with his real runs. Nothing capped the eval as a whole, and one sample per task can't tell a
  harness change from noise.
- **Choice:** `EVAL_BUDGET_USD=10` among `lib/config.sh`'s defaults: a safety cap, which a command sets from the
  estimate (`EVAL_BUDGET_USD=80 harness eval run …`; the environment beats the user config). Before each task the eval
  sums the result dir's `summary.json` costs (`eval.mjs spent`, `<task>/` and `<task>/r<N>/`); at or over the cap it
  starts nothing more. A running task is never cut (each session keeps `SESSION_BUDGET_USD`), so the overshoot is at
  most one task. Before anything is created the eval runs `weekly_over` on the real state root's `USAGE_7D`; past
  `WEEKLY_STOP_AT` it prints the window's message and exits 1 with no tmp or results dir. Before each further task it
  checks that file and the eval's own `$E/state/USAGE_7D` (its sessions write it), and copies a later real
  `LIMIT_UNTIL` into `$E/state/` so the eval's driver waits out a limit a real run hit. `eval.json` gains
  `repeat`, `budget {cap, spent, not_started, text}` and `weekly` (the message, when the window stopped it), and the
  last line printed is `budget: $<spent> of $<cap>; <n> tasks not started`. Not starting a task exits 1 (an
  incomplete eval isn't a result to compare). `--repeat N` (N > 1) runs repeat-major (r1 of every task, then r2 …) so a
  stop leaves whole repeats; each repeat is a fresh clone and run `eval-<task>-r<N>` into `<task>/r<N>/`.
  *Default for Michael:* `EVAL_BUDGET_USD=0` starts nothing (it is a cap, not an on/off switch like
  `WEEKLY_STOP_AT=0`).
- **Rejected:** cutting a running task at the cap (kills a session mid-commit and leaves a half-run task that compare
  would misread); task-major repeats (a stop would leave some tasks with two samples and others with none).
