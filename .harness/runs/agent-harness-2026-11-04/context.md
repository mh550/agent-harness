# Context pack for `T1-03`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (T1-02, affects T1-03, T1-04, T2-01): 33-suite-runner is slow now (51.7 s solo, 25.5 in lc-4-solo.out): its TEST_FILE_TIMEOUT fixtures (rt, sa-se, sf) each wait out run.sh's hardcoded 10 s KILL grace; the tier lint runs only in slow and full runs → entries.jsonl:3
- Discovery (T1-02, affects T1-03, T1-04): 84-node-memo is at the 30 s line: 29.1 and 28.2 s in the two re-timings, then 31.5, 30.3 and 31.3 s in three later fast runs; the next re-timing will likely move it → entries.jsonl:3
- Discovery (T1-02, affects T1-03, T2-02): The fast tier is now 54 files, 536 names + its conformance line (537 checks), about 151 s solo at 4 jobs; the slow tier 34 files, 645 checks, 684.6 s → entries.jsonl:3
- Discovery (T1-01, affects T1-02, T1-03): 84-node-memo timed 27.6 s alone, the closest fast file to the 30 s line: T1-02's solo re-timings should watch it, and 39-memlint-m4 (fast by the spec at 42.1 s) took 35.7 s in check.sh's rerun. → entries.jsonl:2
- Discovery (T1-01, affects run): CLAUDE.md's ## Gotchas is at its 15-line cap: 39-memlint-m4 fails a 16th line; a session adding one must replace one. → entries.jsonl:2
- Discovery (init, affects run): tests/checks/ holds four files findings-and-research/2026-10-30-suite-load-curve/lc-4-solo.out never timed: 00-unit-tier (fast by the spec's rule), 83-spec-must-exist, 84-node-memo, 85-suite-runs (T1-01 times each once and places it by the 30 s line); that output's 01-scheduler-pure and 02-notifications-pure rows now live inside 00-unit-tier (phase 1). → entries.jsonl:1
- Discovery (init, affects run): The stub project's suite is `CHECK_CMD="test ! -f BROKEN"` (tests/lib.sh suite_setup): T2-02's stub run writes its own argument-logging suite script and CHECK_FAST_CMD into $T/proj/.harness/config.sh, as 34-check-key.sh writes its config. TEST_CHECKS directories exist only in 33-suite-runner.sh and 75-suite-tools.sh: those tiny files need tier headers too. → entries.jsonl:1
- Discovery (init, affects run): 86 and 87 are the next free check-file numbers. The spec's one NN-fast-gate.sh is planned as two files: 86-fast-gate.sh (fast tier: the check.sh --fast cases with 73-check-rerun's stub suite) and 87-fast-gate-run.sh (the stub harness run; its tier by the 30 s rule, likely slow), so the check.sh cases stay in the fast tier. → entries.jsonl:1
- Discovery (init, affects run): This run's init.out (/tmp/harness/agent-harness/agent-harness-2026-11-04/init.out) has every check file's time from the harness's full 4-job run: a first look at the tier line, not a solo time; the solo times are lc-4-solo.out's and T1-02's two re-timings. → entries.jsonl:1
- Discovery (init, affects run): harness status at init: RUNNING 1 (this run), QUEUED 0; T1-02's re-timing and T1-03's six runs re-check it first (the brief: no other suite alive). → entries.jsonl:1

## What it builds on

- 2026-11-04 02:34 · T1-02 · passes: tests/run.sh checks a --tier fast run against tests/fixtures/check-names-fast.txt (536 names) and --tier slow against full minus fast; 33-suite-runner gains 6 tier-conformance checks and a 4-check fixture lint. Re-timed solo twice: 33-suite-runner over 30 s both times, so it moved to slow; 39-memlint-m4 stays fast by the spec's exception (*default*).; tests 1171 → 1181; files tests/run.sh, tests/checks/33-suite-runner.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, journal/decisions/2026-11-03-suite-tiers.md, … → entries.jsonl:3

## Lately in the run

- 2026-11-04 01:43 · T1-01 · passes: tests/run.sh reads line 2 of every check file (`# tier: fast|slow`), refuses a headerless one (`no tier header: <path>` per file, exit 2, nothing run), and gains `--tier fast|slow` (with names, with --repeat; slowest: line ends `, tier <t>`). 55 files fast, 33 slow by the 30 s rule; table and rule in journal/decisions/2026-11-03-suite-tiers.md.; tests 1165 → 1171; files tests/run.sh, tests/checks/33-suite-runner.sh, tests/checks/75-suite-tools.sh, tests/checks/*.sh (line 2 header), tests/fixtures/check-names.txt, … → entries.jsonl:2
- 2026-11-04 01:06 · init · passes: 8 features: T1 4 (runner header and --tier, fast fixture and per-tier conformance with the solo re-timing, the six timed runs, review), T2 4 (check.sh --fast and CHECK_FAST_CMD, the driver's run_init fast and green_fast with the stub run, metrics/report/prompt, review). T2-01 after T1. Spec defaults taken; nothing parked.; files .harness/runs/agent-harness-2026-11-04/feature_list.json → entries.jsonl:1

## Current rules

- The unit tier: node evals become `node:test` files in one process, reported as the suite's PASS/FAIL lines → journal/decisions/2026-11-03-unit-tier.md
- The suite's tiers: every check file declares `fast` or `slow` on line 2, and `tests/run.sh --tier` runs one tier → journal/decisions/2026-11-03-suite-tiers.md
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

_74 older rules: journal/decisions._
