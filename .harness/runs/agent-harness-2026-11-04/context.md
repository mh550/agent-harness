# Context pack for `T2-01`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (T1-04, affects T2-01, T2-02, run): tests/run.sh's full run is red when a fast file prints a name absent from check-names-fast.txt, or a fast-fixture name comes only from a slow file: moving a file's tier means moving its names in the same commit → entries.jsonl:5
- Discovery (T1-04, affects T2-01, T2-02): run.sh now rejects any --option after a name (usage, exit 2) and a second --tier; T2's check.sh --fast must pass --tier fast before names → entries.jsonl:5
- Discovery (T1-02, affects T1-03, T1-04, T2-01): 33-suite-runner is slow now (51.7 s solo, 25.5 in lc-4-solo.out): its TEST_FILE_TIMEOUT fixtures (rt, sa-se, sf) each wait out run.sh's hardcoded 10 s KILL grace; the tier lint runs only in slow and full runs → entries.jsonl:3
- Discovery (T1-02, affects T2-01): A --tier names subset checks new and doubled against its tier's list (--tier fast <f>: the fast fixture), so check.sh --fast's rerun (T2-01: --tier fast <files>) is checked against the fast fixture → entries.jsonl:3
- Discovery (T1-01, affects T1-02, T1-04, T2-01, T2-02): The refusal looks at every *.sh in the directory, not only the selected files: a subset or --tier run is refused too. 33-suite-runner.sh's tiny fixture files use `tiny <file> <line>…` (TIER=slow for slow), which writes the shebang and header. → entries.jsonl:2
- Discovery (T1-01, affects run): CLAUDE.md's ## Gotchas is at its 15-line cap: 39-memlint-m4 fails a 16th line; a session adding one must replace one. → entries.jsonl:2
- Discovery (init, affects run): tests/checks/ holds four files findings-and-research/2026-10-30-suite-load-curve/lc-4-solo.out never timed: 00-unit-tier (fast by the spec's rule), 83-spec-must-exist, 84-node-memo, 85-suite-runs (T1-01 times each once and places it by the 30 s line); that output's 01-scheduler-pure and 02-notifications-pure rows now live inside 00-unit-tier (phase 1). → entries.jsonl:1
- Discovery (init, affects run): The stub project's suite is `CHECK_CMD="test ! -f BROKEN"` (tests/lib.sh suite_setup): T2-02's stub run writes its own argument-logging suite script and CHECK_FAST_CMD into $T/proj/.harness/config.sh, as 34-check-key.sh writes its config. TEST_CHECKS directories exist only in 33-suite-runner.sh and 75-suite-tools.sh: those tiny files need tier headers too. → entries.jsonl:1
- Discovery (init, affects run): 86 and 87 are the next free check-file numbers. The spec's one NN-fast-gate.sh is planned as two files: 86-fast-gate.sh (fast tier: the check.sh --fast cases with 73-check-rerun's stub suite) and 87-fast-gate-run.sh (the stub harness run; its tier by the 30 s rule, likely slow), so the check.sh cases stay in the fast tier. → entries.jsonl:1
- Discovery (init, affects run): This run's init.out (/tmp/harness/agent-harness/agent-harness-2026-11-04/init.out) has every check file's time from the harness's full 4-job run: a first look at the tier line, not a solo time; the solo times are lc-4-solo.out's and T1-02's two re-timings. → entries.jsonl:1
- Discovery (init, affects run): harness status at init: RUNNING 1 (this run), QUEUED 0; T1-02's re-timing and T1-03's six runs re-check it first (the brief: no other suite alive). → entries.jsonl:1

## What it builds on

- 2026-11-04 01:43 · T1-01 · passes: tests/run.sh reads line 2 of every check file (`# tier: fast|slow`), refuses a headerless one (`no tier header: <path>` per file, exit 2, nothing run), and gains `--tier fast|slow` (with names, with --repeat; slowest: line ends `, tier <t>`). 55 files fast, 33 slow by the 30 s rule; table and rule in journal/decisions/2026-11-03-suite-tiers.md.; tests 1165 → 1171; files tests/run.sh, tests/checks/33-suite-runner.sh, tests/checks/75-suite-tools.sh, tests/checks/*.sh (line 2 header), tests/fixtures/check-names.txt, … → entries.jsonl:2
- 2026-11-04 02:34 · T1-02 · passes: tests/run.sh checks a --tier fast run against tests/fixtures/check-names-fast.txt (536 names) and --tier slow against full minus fast; 33-suite-runner gains 6 tier-conformance checks and a 4-check fixture lint. Re-timed solo twice: 33-suite-runner over 30 s both times, so it moved to slow; 39-memlint-m4 stays fast by the spec's exception (*default*).; tests 1171 → 1181; files tests/run.sh, tests/checks/33-suite-runner.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, journal/decisions/2026-11-03-suite-tiers.md, … → entries.jsonl:3
- 2026-11-04 03:29 · T1-03 · passes: Timed six solo runs at TEST_JOBS=4: fast 152.8/151.5 s (537 checks), slow 670.7/659.7 s (645), full 809.9/794.1 s (1181); all green. Fast target of 180 s met. Findings in findings-and-research/2026-11-03-suite-tiers.md.; tests 1181 → 1181; files findings-and-research/2026-11-03-suite-tiers.md → entries.jsonl:4
- 2026-11-04 03:52 · T1-04 · passes: Review of T1: 0 Critical, 1 Important, 6 Minor. Fixed: a full run now holds check-names-fast.txt to what the fast files print (both ways); exact line-2 read, non-file *.sh refused quietly, strict option parsing, true fixture paths in hints; one header loop. README, architecture, CLAUDE.md carry --tier.; tests 1181 → 1186; files tests/run.sh, tests/checks/33-suite-runner.sh, tests/fixtures/check-names.txt, journal/decisions/2026-11-03-suite-tiers.md, README.md, … → entries.jsonl:5

## Lately in the run

- 2026-11-04 04:09 · verify T1 · passes: All four T1 features hold: full suite green (1186, 795 s); my fast-tier run 151.7 s, 537/537 with conformance; headerless dir refused deterministically (exit 2); headers, fixtures, findings and docs checked. → entries.jsonl:6

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
