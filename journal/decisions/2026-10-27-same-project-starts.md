# A plain start or continue queues behind a live run of its project; overlaps are named, never held

*(2026-10-28, run agent-harness-2026-10-28, feature U3-05, completed in U3-06; spec `docs/specs/2026-10-27-status-ux.md`
§U3 item 5 and default 11, plan `docs/plans/2026-10-28-U3-show-and-fixes.md` §5 and §6)*

- **Finding:** the runner holds a queued entry while its project has a live run
  (decisions/2026-10-21-queue-one-run-per-project), but `harness start <project>` and `harness continue <run>` by
  hand went past that rule whenever `MAX_PARALLEL_RUNS` had room: two runs on one repo, two sets of branches from one
  `main` (bug e). Done in `cmd_start` alone, a `continue` would already have reset attempts, cleared markers and
  removed `ended`, leaving a run that reads as crashed while it waits. Two runs of different nights can also touch the
  same files without either being live: an ended run's unmerged branch.
- **Choice:** `project_busy <project> [<except run>]` (bin/harness): the first other run under `$STATE_ROOT/<project>/`
  whose driver is `alive` or which has a `lane_live` lane. Without `--now` and not `--foreground`, `cmd_start` (before
  the `MAX_PARALLEL_RUNS` branch, with or without a run id, after the run id's own refusals) queues the argument list
  that branch writes, prints `<R> is running on <project>: queued (the runner starts it when that run ends; --now
  starts it anyway)`, writes `queued behind <R>: <entry>` to `runner.log` and ensures the runner. `cmd_continue` does
  the same before it changes any state, through `queue add --continue` (so a queued entry for the run is replaced
  the same way, `--keep-attempts` kept, an automatic one stays automatic). `--now`, `--foreground` (`harness merge`)
  and the runner's starts (which pass `--now`) are unchanged. Nothing has started, so no record: the message and the
  `runner.log` line are its trace, and the run's own first `harness-log.md` line once it starts. A given run id is
  queued only after its own refusals (already running, a shared tmux name), and an `auto_id` id is checked as before. A
  queued continue stores `--until` as `--until-epoch` and `--brief-file` as its text, as a start does. The runner's
  `busy_projects` (lib/queue.sh) counts a live lane too, and with no driver alive it waits for an entry held by a lane
  instead of ending `queue empty`: otherwise it would start, at once, the entry queued behind that lane. `lib/overlap.mjs`
  (pure): `named(text, tracked)` takes every backticked span and every path-shaped word (one `/` at least; trailing
  `.,:;)` and a `:<line>` stripped) and keeps the tracked paths they equal; a word ending in `/` or holding a glob
  (`*`, `<`, `>`) names the directory before its first glob segment as `dir/` when that directory has **two or more
  segments** and holds a tracked file; a word without `/` names only a top-level tracked file, and only in backticks;
  nothing under `.harness/runs/`; HTML tags (`<br>`, `<code>`) are blanked, and trailing `*`s go when that leaves a
  tracked file (`**lib/x.sh**`; `dir/6*` stays a glob). `overlap(a, b)`: the sorted intersection (a `dir/` meets the files under it, which
  are reported). U3-06 wires it: overlaps warn and record on both runs and never hold a start.
- **Rejected:** the check in `cmd_start` alone (a continue would change its state first); holding a start on an
  overlap (default 11: an ended run's unmerged branch must not block a night); comparing whole spec texts (no file
  names, no signal); `tests/`- or `lib/`-level directories (every run would overlap); a bare directory word without
  `/` at its end (`docs/plans` is in most specs and every run writes there).
