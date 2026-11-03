# Context pack for `C1-03`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (C1-02, affects C1-03): F_MEMO_PID: a miss in a subshell runs node straight and keeps nothing, so a $(F …) site gains only when its parent shell already holds the key; the coordinator's idle-poll calls ($(record F unpark … "$(answers_hash)"), rebase_due in < <(…)) still start node each poll until C1-03 moves them into the current shell (Fv, a var for answers_hash) → entries.jsonl:6
- Discovery (C1-02, affects C1-03, C1-06): features.mjs now exits 70 on a throw (was node's 1): 1 is an answer the memo keeps for passes/milestone-done/evidence/lint; a new subcommand whose 1 is an answer goes in f_memo's case list → entries.jsonl:6
- Discovery (C1-02, affects C1-03, C1-04): lines with note " can't change in C1 (the step grep), so $(F summary …) inside note lines (lane.sh 387, driver.sh 498/571/581) stay subshell calls: they hit only when the shell already holds that list's summary → entries.jsonl:6
- Discovery (C1-01, affects C1-02, C1-03): bash 5.2: an F memo entry written inside $(F …), < <(…) or a pipe dies with the subshell; most answer-reading F sites are $( ). The plan's default: F model fills every alias at once (a models subcommand), Fv <var> <sub> … runs F in the current shell → entries.jsonl:5
- Discovery (C1-01, affects C1-03): An idle coordinator poll with a free slot starts node 5 times: F unpark, inbox answers, needs.mjs sweep, F milestones (rebase_due), F lanes. needs sweep is not memoizable, so C1-03's at-most-one bound needs F lanes memoized on the state inputs laneState reads (plan §4) → entries.jsonl:5
- Discovery (C1-01, affects C1-03, C1-04): treekey.mjs --names ran 0 times in file 13: the check.sh treekey merge saves nothing there; date/cat are not in the top five, so no builtin change → entries.jsonl:5
- Discovery (Q1-02, affects run): lib/spec.sh now has spec_args (a start's run id/--spec/--base), spec_new_run (resume and --brief skips) and spec_entry (a .args file, project config in a subshell); bin/harness spec_refuse and queue add use them → entries.jsonl:3
- Discovery (Q1-02, affects run): editing the worktree while a full check.sh runs can cache red-<key> for the pre-edit tree: never edit during a full run → entries.jsonl:3
- Discovery (Q1-01, affects run): a stub check that starts a new run with --spec <file> now needs the file pushed to the stub's origin/main (SPEC.md is, from suite_setup) → entries.jsonl:2
- Discovery (init, affects run): C1-04's two timed suites (about 15 min each on this box) run outside the suite command, in the session, in the background with a timeout: the full run per session comes on top, so that feature needs a session well over 40 min → entries.jsonl:1
- Discovery (init, affects run): An idle coordinator poll with one lane open and MAX_LANES=1 (the default) makes no F call at all; C1-03's idle-poll check needs MAX_LANES=2 in the stub project's .harness/config.sh so a free slot exists and F unpark, F lanes and answers_hash (inbox.mjs) run each poll → entries.jsonl:1
- Discovery (init, affects run): F unpark mutates the parked file when it unparks: C1-02 may serve a memoized unpark answer only when the stored answer was empty (no mutation); F lanes reads the state dir (verified-/needs- marks), so it is not memoizable on the list alone → entries.jsonl:1

## What it builds on

- 2026-11-03 13:55 · C1-02 · passes: lib/record.sh's F memoizes features.mjs's pure subcommands in a per-process assoc array keyed on sub + sha1 of each file arg + other args; Fv answers into a var in the current shell; models fills every alias in run_paths; answers_hash memoized on INBOX.md's hash; a throw exits 70. Busiest $(F …) sites moved to Fv. Decision Choice/Rejected written. Opus review: no Critical/Important, minors fixed.; tests 1102 → 1121; files lib/record.sh, lib/features.mjs, lib/lane.sh, lib/driver.sh, tests/checks/84-node-memo.sh, … → entries.jsonl:6

## Lately in the run

- 2026-11-03 13:05 · C1-01 · passes: Exec table: one stub harness start of file 13 under strace (402 node starts = 10.8 of 20.4 CPU-s) plus the whole file (3,139 node; lanes 1,945, driver 975, stub 48, checks 9; node 49% of 170.6 CPU-s) in the fewer-node-starts decision; plan names the memo, the subshell constraint, the poll collapse, no builtins. No code change.; tests 1102 → 1102; files journal/decisions/2026-10-31-fewer-node-starts.md, docs/plans/2026-11-03-C1-suite-cpu.md, findings-and-research/2026-11-03-exec-table/ → entries.jsonl:5
- 2026-11-03 12:48 · verify Q1 · passes: Q1-01 and Q1-02 hold: suite green (init full run, 843 s, 1102 tests), 83-spec-must-exist 18/18 re-run, bash -n clean, check names sorted, docs and decision present. → entries.jsonl:4

## Current rules

- A run never starts on a spec that isn't there: `harness start` and `queue add` refuse a spec absent from the run's base ref → journal/decisions/2026-10-31-spec-must-exist.md
- Fewer node starts: where a stub run's process starts come from, and the cuts C1 makes → journal/decisions/2026-10-31-fewer-node-starts.md
- The suite's length in every prompt: a green marker's `wall` line, and a timeout rule → journal/decisions/2026-10-30-suite-length-in-prompt.md
- A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing → journal/decisions/2026-10-30-red-marker.md
- A mapped path's change runs only its readers: `CHECK_KEY_MAP`, the `part-<key>` sidecar, the partial run, the lint → journal/decisions/2026-10-30-partial-key.md
- The coordinator opens no lane while a lane that exited is not reaped yet → journal/decisions/2026-10-30-opens-wait-for-reap.md
- The lane guard reverts against the lane's merge-base with main, in the index only → journal/decisions/2026-10-30-lane-guard-base.md
- Timing checks bound CPU time; a stopped file's missing names don't void `HARNESS_FAILED=` → journal/decisions/2026-10-30-cpu-time-bound-and-stopped-files.md
- The suite waits on a condition or a barrier, never on the clock; a flake is reproduced with --repeat and fixed at its cause → journal/decisions/2026-10-29-tests-wait-not-sleep.md
- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
- Questions wait in `harness needs` until answered: one item per question, moved forward, no push → journal/decisions/2026-10-29-questions-wait.md
- Lanes leftovers: atomic list writes, a record-only main, the finish order, two lint rules, two checks, the suite-ran note → journal/decisions/2026-10-29-lanes-leftovers.md

_71 older rules: journal/decisions._
