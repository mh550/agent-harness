# Context pack for `C1-06`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (C1-05, affects run): tests/stub-claude.sh's STUB_RUN_SUITE subset (`test ! -f BROKEN x`) exits 2, which under the stub's set -e ended A's first session before its entry (a limit retry); now under set +e, so 77's sr A session completes → entries.jsonl:9
- Discovery (C1-05, affects C1-06): C1-06: the retro prompt carries {{SUITE_RUNS}} (summary.mjs suite-runs; `not counted` fallback in driver.sh retro); docs/architecture.md and README still need the Suite runs row and the two metrics fields → entries.jsonl:9
- Discovery (C1-04, affects run): C1 cut CPU only 6.7% and wall 5.9%: sys time (~36% of CPU) barely moved; next levers are metrics.mjs collapse, testcount.mjs, then git/bash forks → entries.jsonl:8
- Discovery (C1-03, affects C1-06): Lines with note " can't change in C1, so the end check's summaries and the idle poll's `for id in $(record F unpark … $(answers_hash))` line stay as they are: F poll fills the memo for summary (f_poll_seed), and unpark_warm fills answers_hash and an empty unpark in the coordinator's shell first → entries.jsonl:7
- Discovery (C1-03, affects C1-06): lanes_v (lib/record.sh) is the coordinator's F lanes, memoized on a fingerprint of laneState's reads (verified-/needs- marks, pid + /proc existence, review-escalate size, meta.env); a pid file that isn't one number is no key. C1-06 should read this key hardest → entries.jsonl:7
- Discovery (C1-03, affects C1-04, run): metrics.mjs in the lane (MET usage twice and MET limit 2-3 times per finished session log, third of the top five) is not collapsed: the plan's §4 default is the next lever if C1-04 is short of the -20 % target → entries.jsonl:7
- Discovery (C1-03, affects run): CLAUDE.md's Gotchas is at memlint's 15-line cap (39-memlint-m4 goes red at 16): a new line must replace one → entries.jsonl:7
- Discovery (C1-02, affects C1-03, C1-06): features.mjs now exits 70 on a throw (was node's 1): 1 is an answer the memo keeps for passes/milestone-done/evidence/lint; a new subcommand whose 1 is an answer goes in f_memo's case list → entries.jsonl:6
- Discovery (Q1-02, affects run): lib/spec.sh now has spec_args (a start's run id/--spec/--base), spec_new_run (resume and --brief skips) and spec_entry (a .args file, project config in a subshell); bin/harness spec_refuse and queue add use them → entries.jsonl:3
- Discovery (Q1-02, affects run): editing the worktree while a full check.sh runs can cache red-<key> for the pre-edit tree: never edit during a full run → entries.jsonl:3
- Discovery (Q1-01, affects run): a stub check that starts a new run with --spec <file> now needs the file pushed to the stub's origin/main (SPEC.md is, from suite_setup) → entries.jsonl:2
- Discovery (init, affects run): C1-04's two timed suites (about 15 min each on this box) run outside the suite command, in the session, in the background with a timeout: the full run per session comes on top, so that feature needs a session well over 40 min → entries.jsonl:1
- Discovery (init, affects run): An idle coordinator poll with one lane open and MAX_LANES=1 (the default) makes no F call at all; C1-03's idle-poll check needs MAX_LANES=2 in the stub project's .harness/config.sh so a free slot exists and F unpark, F lanes and answers_hash (inbox.mjs) run each poll → entries.jsonl:1
- Discovery (init, affects run): F unpark mutates the parked file when it unparks: C1-02 may serve a memoized unpark answer only when the stored answer was empty (no mutation); F lanes reads the state dir (verified-/needs- marks), so it is not memoizable on the list alone → entries.jsonl:1

## Promote to Gotchas

- 82-key-map-lint reads a node import string "'"$HH"'/lib/x.mjs" as a read of the repo root (CLAUDE.md): a new check file uses "'$HERE'/../lib/x.mjs" (11's form) → entries.jsonl:9

## What it builds on

- 2026-11-03 16:17 · C1-05 · passes: coding.md: one full run, last, after the final edit; TEST_JOBS=2 rule; §3 Gotchas before the suite step (step 1 names it). lane.sh passes suite_runs/suite_full to MET append; metricsRow writes them (null without the log); summary.mjs suiteRuns + Suite runs row after Flakes; retro {{SUITE_RUNS}}. Stub suite calls under set +e. Decision one-full-run. Opus review: 2 Important, fixed.; tests 1129 → 1140; files prompts/coding.md, prompts/retro.md, lib/lane.sh, lib/metrics.mjs, lib/summary.mjs, … → entries.jsonl:9

## Lately in the run

- 2026-11-03 15:17 · C1-04 · passes: Two solo timed suites. Before (d595498): wall 854.1 s, 3,361.8 CPU-s, 1102/1102. After (5a11f9d): wall 803.8 s, 3,136.1 CPU-s, 1129/1129. Spec target MISSED: CPU -6.7% (needed -20%), wall 803.8 s (bound 650). Rows in the decision file.; tests 1129 → 1129; files journal/decisions/2026-10-31-fewer-node-starts.md → entries.jsonl:8
- 2026-11-03 14:48 · C1-03 · passes: features.mjs poll answers summary/parked/blocked/next/milestone-done in one start and fills F's memo for all five; the end check and the lane loop use it. The idle poll starts node once (needs sweep): unpark_warm, unparks, lanes_v (F lanes on a laneState fingerprint). treekey --partial --names: one start. No builtins. Opus review: 2 minors, fixed.; tests 1121 → 1129; files lib/features.mjs, lib/record.sh, lib/driver.sh, lib/lane.sh, lib/check.sh, … → entries.jsonl:7

## Current rules

- A run never starts on a spec that isn't there: `harness start` and `queue add` refuse a spec absent from the run's base ref → journal/decisions/2026-10-31-spec-must-exist.md
- One full run per coding session, last: the prompt's rule and §3 order, and `Suite runs` in the report → journal/decisions/2026-10-31-one-full-run.md
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

_72 older rules: journal/decisions._
