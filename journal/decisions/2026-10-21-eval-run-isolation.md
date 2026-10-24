# `harness eval run` replays a task with the ref's own driver, on throwaway clones, reaching nothing real

*(2026-10-21, E2-03 of run agent-harness-2026-10-21-measure; plan `docs/plans/2026-10-21-E2-evals.md` §3; the task
set itself is D-H35 in `journal/decisions.md`)*

- **Finding:** to judge a harness change, the same tasks must run under two harness versions with nothing else
  different, and without touching Michael's runs, state, ledger, config, project checkouts or remotes. A replay that
  ran in a real checkout, read his user config or posted a notification would be neither fair nor safe.
- **Choice:** `lib/eval.sh run` checks `--harness <ref>` (default `HEAD`) out with `git worktree add --detach` into
  `/tmp/harness-eval/<stamp>/harness` and removes it at the end (and in an EXIT trap). A ref older than 7754661
  (P1-02) is refused: its driver reads neither `HARNESS_CONFIG` nor `run.env` nor `HARNESS_CURL`. Each task
  gets a fresh `git clone --no-checkout` of its repo at `base` (the source is only read), its origin replaced by a
  local bare `origin.git`, and a pushed branch `harness/eval-<task>` that already holds the task's features as
  `feature_list.json` (`eval.mjs seed`), so `cmd_start` takes it and the driver skips the initializer. That worktree's
  `bin/harness start --foreground --no-supervisor` runs with every `HARNESS_*` root under the eval dir,
  `HARNESS_GH`/`HARNESS_CURL` set to `false` (the suite sets its logging stubs through `HARNESS_EVAL_GH`/`_CURL`, so
  `eval run: nothing reaches a remote` can fail), and the safety lines (`POLICY=build-only MERGE_POLICY=off RETRO=0
  AUTO_CONTINUE=0 DESK=0 LEDGER_COMMIT=0`, empty NTFY/NOTIFY/DESK settings, `LIVE_LOCK` in the eval dir) both as the runs' user
  config and in each run's `run.env`, which beats the project's own `.harness/config.sh`. The eval writes each run's
  port itself, from 7900 up (`cmd_start` would take the project's `BASE_PORT`, and can't see the ports real runs hold).
  Results go to `evals/results/<stamp>-<short sha>-<label>/<task>/` (`summary.json metrics.jsonl harness-log.md
  feature_list.json progress.md start.log`) with `eval.json` rewritten after every task. Before anything is created the
  set is checked (schema, `project` a single path segment, unique ids, each local repo has its `base`), so a bad
  task never costs a partial eval. A task's exit code is recorded, never fatal; the eval exits 1 if a task could not
  be cloned or seeded. Ctrl-C reaches the session's `timeout` process group late, so it stops the eval only after
  the current task (that task has no line in `eval.json`).
  *Defaults for Michael:* (1) `evals/results/*` is gitignored (untracked results would make every later run
  `+dirty`); keep one with `git add -f`. (2) Eval runs use the harness defaults, not `~/.config/harness/config.sh`;
  his `~/.claude` settings and hooks still load, with `HARNESS_EVAL=1` set so a hook can skip eval sessions.
  (3) eval runs take ports from 7900 up.
- **Rejected:** a full clone of the harness per eval (copies history; a worktree of the ref is cheap and exact);
  running in the project checkouts or with Michael's user config (A/B must share the defaults and touch nothing);
  `HARNESS_GH=false` forced in tests too (the remote check could then never fail); `git worktree prune` in the
  suite's EXIT trap (it prunes every stale worktree of the shared repo; the trap removes only its own eval
  worktrees); `BASE_PORT` in the safety lines (`cmd_start` picks the port before `run.env` is read, and a
  project's `BASE_PORT` beats the user config); committing results by default (dirties the harness version).
- *Amended 2026-10-21 (E2-08 review):* the clone is sealed at base, a missing repo is refused up front, and real runs'
  port files are skipped (`decisions/2026-10-21-eval-clone-sealed-at-base`). An interrupted eval removes its harness
  worktree, but the running session lives on under the driver's `timeout` (`docs/plans/2026-10-21-E2-review.md` R2).
