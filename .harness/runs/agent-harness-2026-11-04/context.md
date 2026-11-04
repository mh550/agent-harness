# Context pack for `T2-02`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (T2-01, affects T2-02): check.sh --fast exists: T2-02 calls "$CHECK" --fast for run_init fast and green_fast; a fast red leaves no marker, so the post-session gate reruns the fast tier (about 150 s) when the pre-session one was red → entries.jsonl:7
- Discovery (T2-01, affects T2-02): run_init fresh (lib/record.sh ~584) still removes only green-, red- and part-<key>: T2-02 step 2 adds fast-<key> → entries.jsonl:7
- Discovery (T2-01, affects T2-02, T2-04): check.sh --fast <args> is a usage error (exit 2) whether or not a fast command is set → entries.jsonl:7
- Discovery (T1-04, affects T2-01, T2-02, run): tests/run.sh's full run is red when a fast file prints a name absent from check-names-fast.txt, or a fast-fixture name comes only from a slow file: moving a file's tier means moving its names in the same commit → entries.jsonl:5
- Discovery (T1-04, affects T2-01, T2-02): run.sh now rejects any --option after a name (usage, exit 2) and a second --tier; T2's check.sh --fast must pass --tier fast before names → entries.jsonl:5
- Discovery (T1-03, affects T1-04, T2-02): Fast tier files over 30 s in both runs: 39-memlint-m4 (41.5/41.2 s, spec exception) and 84-node-memo (31.5/31.5 s): 84 moves to slow at the next re-timing; fast has 537 checks, below the spec's 560-620 estimate → entries.jsonl:4
- Discovery (T1-02, affects T1-03, T2-02): The fast tier is now 54 files, 536 names + its conformance line (537 checks), about 151 s solo at 4 jobs; the slow tier 34 files, 645 checks, 684.6 s → entries.jsonl:3
- Discovery (T1-01, affects T1-02, T1-04, T2-01, T2-02): The refusal looks at every *.sh in the directory, not only the selected files: a subset or --tier run is refused too. 33-suite-runner.sh's tiny fixture files use `tiny <file> <line>…` (TIER=slow for slow), which writes the shebang and header. → entries.jsonl:2
- Discovery (T1-01, affects run): CLAUDE.md's ## Gotchas is at its 15-line cap: 39-memlint-m4 fails a 16th line; a session adding one must replace one. → entries.jsonl:2
- Discovery (init, affects run): tests/checks/ holds four files findings-and-research/2026-10-30-suite-load-curve/lc-4-solo.out never timed: 00-unit-tier (fast by the spec's rule), 83-spec-must-exist, 84-node-memo, 85-suite-runs (T1-01 times each once and places it by the 30 s line); that output's 01-scheduler-pure and 02-notifications-pure rows now live inside 00-unit-tier (phase 1). → entries.jsonl:1
- Discovery (init, affects run): The stub project's suite is `CHECK_CMD="test ! -f BROKEN"` (tests/lib.sh suite_setup): T2-02's stub run writes its own argument-logging suite script and CHECK_FAST_CMD into $T/proj/.harness/config.sh, as 34-check-key.sh writes its config. TEST_CHECKS directories exist only in 33-suite-runner.sh and 75-suite-tools.sh: those tiny files need tier headers too. → entries.jsonl:1
- Discovery (init, affects run): 86 and 87 are the next free check-file numbers. The spec's one NN-fast-gate.sh is planned as two files: 86-fast-gate.sh (fast tier: the check.sh --fast cases with 73-check-rerun's stub suite) and 87-fast-gate-run.sh (the stub harness run; its tier by the 30 s rule, likely slow), so the check.sh cases stay in the fast tier. → entries.jsonl:1
- Discovery (init, affects run): This run's init.out (/tmp/harness/agent-harness/agent-harness-2026-11-04/init.out) has every check file's time from the harness's full 4-job run: a first look at the tier line, not a solo time; the solo times are lc-4-solo.out's and T1-02's two re-timings. → entries.jsonl:1
- Discovery (init, affects run): harness status at init: RUNNING 1 (this run), QUEUED 0; T1-02's re-timing and T1-03's six runs re-check it first (the brief: no other suite alive). → entries.jsonl:1

## What it builds on

- 2026-11-04 04:33 · T2-01 · passes: lib/check.sh --fast: with HARNESS_CHECK_FAST_CMD empty it is the bare form; set, a green-/red-<key> answers first, then fast-<key>, else the fast tier runs (same scope, cap, timeout, rerun guard) to check-fast.out; green writes fast-<key> only, red no marker; flake rows get tier fast. CHECK_FAST_CMD in config/prompt_env/template, this repo sets --tier fast. decisions/2026-11-03-fast-gate.; tests 1186 → 1205; files lib/check.sh, lib/config.sh, lib/prompt.sh, templates/project/config.sh, .harness/config.sh, … → entries.jsonl:7

## Lately in the run

- 2026-11-04 04:09 · verify T1 · passes: All four T1 features hold: full suite green (1186, 795 s); my fast-tier run 151.7 s, 537/537 with conformance; headerless dir refused deterministically (exit 2); headers, fixtures, findings and docs checked. → entries.jsonl:6
- 2026-11-04 03:52 · T1-04 · passes: Review of T1: 0 Critical, 1 Important, 6 Minor. Fixed: a full run now holds check-names-fast.txt to what the fast files print (both ways); exact line-2 read, non-file *.sh refused quietly, strict option parsing, true fixture paths in hints; one header loop. README, architecture, CLAUDE.md carry --tier.; tests 1181 → 1186; files tests/run.sh, tests/checks/33-suite-runner.sh, tests/fixtures/check-names.txt, journal/decisions/2026-11-03-suite-tiers.md, README.md, … → entries.jsonl:5

## Current rules

- The unit tier: node evals become `node:test` files in one process, reported as the suite's PASS/FAIL lines → journal/decisions/2026-11-03-unit-tier.md
- The suite's tiers: every check file declares `fast` or `slow` on line 2, and `tests/run.sh --tier` runs one tier → journal/decisions/2026-11-03-suite-tiers.md
- The fast gate: `check.sh --fast` runs the fast tier, marks `fast-<key>`, and a fast-green is never read as a green → journal/decisions/2026-11-03-fast-gate.md
- A run never starts on a spec that isn't there: `harness start` and `queue add` refuse a spec absent from the run's base ref → journal/decisions/2026-10-31-spec-must-exist.md
- One full run per coding session, last: the prompt's rule and §3 order, and `Suite runs` in the report → journal/decisions/2026-10-31-one-full-run.md
- Fewer node starts: where a stub run's process starts come from, and the cuts C1 makes → journal/decisions/2026-10-31-fewer-node-starts.md
- The suite's length in every prompt: a green marker's `wall` line, and a timeout rule → journal/decisions/2026-10-30-suite-length-in-prompt.md
- A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing → journal/decisions/2026-10-30-red-marker.md
- A mapped path's change runs only its readers: `CHECK_KEY_MAP`, the `part-<key>` sidecar, the partial run, the lint → journal/decisions/2026-10-30-partial-key.md
- The coordinator opens no lane while a lane that exited is not reaped yet → journal/decisions/2026-10-30-opens-wait-for-reap.md
- The lane guard reverts against the lane's merge-base with main, in the index only → journal/decisions/2026-10-30-lane-guard-base.md
- Timing checks bound CPU time; a stopped file's missing names don't void `HARNESS_FAILED=` → journal/decisions/2026-10-30-cpu-time-bound-and-stopped-files.md

_75 older rules: journal/decisions._
