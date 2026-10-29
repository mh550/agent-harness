# Prompt: run-time budget diagnosis (2026-10-29 afternoon)

Source: interactive session while `agent-harness-2026-10-29-2` was stopped/paused, between ~12:35 and ~13:30 EDT.
Michael's ask (paraphrased from the session transcript):

> "The runs are taking forever to run, but not using many tokens clearly from the cost metrics I see for the run.
> My theory is the time is being lost to the orchestrator — potentially running the full test suite on every change.
> I want to consider a more targeted approach — maybe running only the relevant tests to pass each feature, and then
> running the full suite upon reaching a checkpoint like the end of a milestone, and having an agent fix any issues
> that pop up there. Consider best practices out there to handle this issue. Don't take my word for it though — there
> could be another issue that's causing the orchestrator to be slow that I'm not considering yet."

The session read raw records before answering (four questions and a prompt):
1. What a top professional in this field would do that I'm not asking for.
2. The rawest material they would start from.
3. The specific methods and tools they would use.
4. What, other than you or me, would show the result is right.

## Findings before the diagnosis prompt was written

- `api_s` in `metrics.jsonl` is built from `duration_ms` (the session's total time), not `duration_api_ms` (model
  time). The harness has never separated model time from tool time.
- Run `-2` lanes covered ~8,600 s each; sessions sum to ~3,800–4,000 s. Some gap is the pause and the stop.
- `journalctl --user` shows R2's post-session suite (09:19:33–09:32:00) consumed 47 CPU-minutes against a theoretical
  maximum of ~28 CPU-minutes for 3.5 minutes on 8 cores — the same suite burns 1.7× more CPU under contention.
- 2 of 6 sessions were un-passed for "suite red"; one (R2-01) changed only docs and one Gotchas line.
- Two flakes logged at load ~5.3. Hypothesis: contention → slow suites → timing-miss flakes → rework → more contention.
- Unexplained gap: 09:32–09:48 before R2-01's retry; the retry's 761 s wall vs 145 s in `claude`.

## The prompt given to the investigation agent

```
Diagnose where wall-clock time goes in harness runs, then plan the fix. Do the diagnosis first; don't jump to a remedy.
Deliverables, merged to main through a PR per CLAUDE.md:
  findings-and-research/2026-10-29-run-time-budget.md  (the measurements and the analysis script used, reproducible)
  docs/plans/2026-10-29-suite-time.md                 (the plan, with predictions written before any change)
No driver or CLI changes in this task.

Hypothesis to test, not to confirm: runs are slow because of the orchestrator's suite runs, and running only the
relevant tests per feature (with the full suite at the milestone and an agent fixing what breaks there) would help.
Treat it as one candidate among several.

What a first look found (verify every point yourself):
- metrics.jsonl's api_s comes from the result's duration_ms (lib/metrics.mjs:96), i.e. the session's total time; the
  stream's duration_api_ms is dropped. Model time and tool time have never been separated.
- Run agent-harness-2026-10-29-2: lanes ran 09:12 to 11:36 (~8,600 s), but each lane's sessions add up to only
  ~3,800–4,000 s. Some of the rest is the pause from 10:32 and Michael's stop at 11:36. The journal shows R2's suite after
  its first session ran 09:19:33 to 09:32:00 and used 47 CPU-minutes, while R1's suite ran alongside it. The suite takes
  ~3.5 minutes alone, and 8 cores for 3.5 minutes can supply at most ~28 CPU-minutes, so the CPU cost itself swells
  under contention (spin-waits or polling in the checks?).
- 2 of 6 sessions were un-passed for "suite red after the session"; one (R2-01) changed only docs and a Gotchas line.
  Two flakes were logged at load ~5.3. Possible loop: contention → slow suites → flakes → un-passes → rework → more
  contention.
- Unexplained: the 09:32 to 09:48 gap before R2-01's retry, and the retry's 761 s wall time against 145 s in claude.

Start from raw material, not reports:
1. journalctl --user over each run's window: start, stop and "Consumed CPU" lines for harness-<run>-<lane>-check-* and
   the session scopes. This is the clock the harness doesn't write.
2. Committed run records in .harness/runs/<run>/ (harness-log.md, metrics.jsonl, entries.jsonl) and the commit times
   on run branches.
3. [Michael grants this read-only exception to CLAUDE.md for this task: read, never write, the stream logs under
   ~/.local/state/harness/<run>/logs/*.jsonl and the check-*.out, green-* and flakes.jsonl files of runs that are not
   alive. Delete this line to withhold it; then write the extraction script and ask Michael to run it with `! <cmd>`.]
   From the stream logs, per session: duration_ms vs duration_api_ms, and every Bash call to the suite (duration,
   cached green or full run, the tree key).

Method:
- Build a per-lane timeline for at least the last four runs, with every second assigned to one bucket: model, the
  session's suite, other session tools, the harness before the session, the harness after it, verify, waiting
  (limit, pause, needs Michael), idle. Report the shares and the largest unexplained bucket.
- Count full-suite runs per feature and the suite cache's hit rate; find what invalidates the key between the
  session's run and the harness's.
- Run a controlled load curve, only while `harness status` shows no live run (otherwise stop and say so): bash
  tests/run.sh alone and with a second copy running alongside in another worktree, at TEST_JOBS 1, 2 and 4. Record wall
  time, CPU time from /usr/bin/time, /proc/pressure/cpu and flakes. Check the spin-wait hypothesis in tests/lib.sh and
  the checks.
- Escape rate: for past features, compare changed files with which check files went red, and estimate how often a
  file-based subset would have missed a red that the full suite caught.
- Read the decisions behind every full-suite run (verify-runs-the-suite, rerun-guard, capped-suites, scoped-sessions,
  pre-session init) and state what each guards against.
- Compare against prior art: content-hash caching (Bazel), merge queues with batched full runs and bisection (the
  milestone-checkpoint idea), Meta's Predictive Test Selection (2019), Google TAP, flaky-test quarantine. Name what
  carries over to one 8-core box with 2 lanes.

The plan must:
- rank fixes by measured seconds saved per run (candidates include a box-wide suite token across lanes, no duplicate
  runs on the same tree, keying the cache so bookkeeping commits don't invalidate it, fixing spin-waits, and targeted
  tests with a full suite at the milestone);
- say for each fix which guard it weakens and what replaces that guard;
- give numeric predictions for the next real runs: non-session share of lane time, suite wall time and CPU per run,
  flakes per run, un-passes from a red suite, main green after milestone merges;
- say which project's suite profile each fix applies to (agent-harness's end-to-end suite is not dj's or hit_list's).
Mark as hypothesis any conclusion the data can't show. Don't send notifications or touch real runs.
```

Note: the prompt includes a bracketed read-only CLAUDE.md exception for state-dir stream logs. Delete that block
to limit the agent to publicly committed records only (journal scope data, `metrics.jsonl`, commit times).
