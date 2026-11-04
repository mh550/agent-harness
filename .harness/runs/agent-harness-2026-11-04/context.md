# Context pack for `T2-04`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (T2-03, affects T2-04): Both lengths sit under *This session*, not in run.md's Suite line as the spec wrote it: a wall changes per render and above This session splits the shared prefix (79's rule; recorded *default* in decisions/2026-11-03-fast-gate) → entries.jsonl:9
- Discovery (T2-03, affects T2-04, run): render.mjs now has line markers: a line opening {{?X}} stays only when HARNESS_X is non-empty, {{!X}} only when empty; parts/run.md holds both Suite lines that way → entries.jsonl:9
- Discovery (T2-03, affects T2-04): tests/stub-claude.sh STUB_RUN_FAST=<id>: the first coding session runs `$HARNESS_CHECK --fast` twice (one run, one cached); 87's fg run uses it on A → entries.jsonl:9
- Discovery (T2-03, affects T2-04): tests/fixtures/summary-report.json/.md now carry a suite_runs (the spec's 0.2/1.6 example); summary.test's Conflicts-after-Flakes order assertion sets suite_runs undefined → entries.jsonl:9
- Discovery (T2-02, affects T2-03, T2-04): With a fast command set, tests-end moves only on a full green (the verify's run_init fresh): between a milestone's sessions status/report show no new tests-end, by the spec's full-markers-only rule → entries.jsonl:8
- Discovery (T2-02, affects T2-04, run): The un-pass note is now `fast tier red after the session` for every project (no fast command: the whole suite is the fast tier); lib/summary.mjs redUnpass matches it and the older `suite red` note; checks 08/13/14/15/74/80 grep the new text → entries.jsonl:8
- Discovery (T2-02, affects T2-03, T2-04): tests/stub-claude.sh: STUB_SLOW_RED, STUB_FAST_RED, a `session <id> <n>` line in the run scratch's suite-args.log when it exists, and STUB_PLANT_MARKERS now plants fast-<key> too → entries.jsonl:8
- Discovery (T2-01, affects T2-03, T2-04): flakes_note (lib/record.sh ~197) and lib/summary.mjs ~116 print 'whole suite' for a flake with no names; a fast flake row (tier fast, names []) should read 'the fast tier' there → entries.jsonl:7
- Discovery (T2-01, affects T2-02, T2-04): check.sh --fast <args> is a usage error (exit 2) whether or not a fast command is set → entries.jsonl:7
- Discovery (T1-04, affects T2-01, T2-02, run): tests/run.sh's full run is red when a fast file prints a name absent from check-names-fast.txt, or a fast-fixture name comes only from a slow file: moving a file's tier means moving its names in the same commit → entries.jsonl:5
- Discovery (T1-01, affects run): CLAUDE.md's ## Gotchas is at its 15-line cap: 39-memlint-m4 fails a 16th line; a session adding one must replace one. → entries.jsonl:2
- Discovery (init, affects run): tests/checks/ holds four files findings-and-research/2026-10-30-suite-load-curve/lc-4-solo.out never timed: 00-unit-tier (fast by the spec's rule), 83-spec-must-exist, 84-node-memo, 85-suite-runs (T1-01 times each once and places it by the 30 s line); that output's 01-scheduler-pure and 02-notifications-pure rows now live inside 00-unit-tier (phase 1). → entries.jsonl:1
- Discovery (init, affects run): The stub project's suite is `CHECK_CMD="test ! -f BROKEN"` (tests/lib.sh suite_setup): T2-02's stub run writes its own argument-logging suite script and CHECK_FAST_CMD into $T/proj/.harness/config.sh, as 34-check-key.sh writes its config. TEST_CHECKS directories exist only in 33-suite-runner.sh and 75-suite-tools.sh: those tiny files need tier headers too. → entries.jsonl:1
- Discovery (init, affects run): 86 and 87 are the next free check-file numbers. The spec's one NN-fast-gate.sh is planned as two files: 86-fast-gate.sh (fast tier: the check.sh --fast cases with 73-check-rerun's stub suite) and 87-fast-gate-run.sh (the stub harness run; its tier by the 30 s rule, likely slow), so the check.sh cases stay in the fast tier. → entries.jsonl:1
- Discovery (init, affects run): This run's init.out (/tmp/harness/agent-harness/agent-harness-2026-11-04/init.out) has every check file's time from the harness's full 4-job run: a first look at the tier line, not a solo time; the solo times are lc-4-solo.out's and T1-02's two re-timings. → entries.jsonl:1
- Discovery (init, affects run): harness status at init: RUNNING 1 (this run), QUEUED 0; T1-02's re-timing and T1-03's six runs re-check it first (the brief: no other suite alive). → entries.jsonl:1

## What it builds on

- 2026-11-04 05:25 · T2-03 · passes: The gate is visible: suite_fast on the coding row, suiteRuns {sessions, full, fast, runs, full_per_session, fast_per_session} and the Suite runs row `<f> full and <k> fast per coding session (…)`; run.md names both tiers' commands; This session adds `Suite: last fast run <s> s`; coding.md's two-tier rule `run the fast tier once, last`; render.mjs {{?X}}/{{!X}} line markers.; tests 1214 → 1220; files lib/lane.sh, lib/metrics.mjs, lib/summary.mjs, lib/prompt.sh, lib/render.mjs, … → entries.jsonl:9

## Lately in the run

- 2026-11-04 04:59 · T2-02 · passes: The driver gates passes on the fast tier: run_init fast (check.sh --fast) before each coding session, green_fast after it with the note `<id> un-passed: fast tier red after the session`; run_init fresh also drops fast-<key>; tests-start/tests-end read green-<key> only. 87-fast-gate-run.sh (slow, 34 s) proves it with three stub runs.; tests 1205 → 1214; files lib/record.sh, lib/lane.sh, lib/summary.mjs, tests/checks/87-fast-gate-run.sh, tests/stub-claude.sh, … → entries.jsonl:8
- 2026-11-04 04:33 · T2-01 · passes: lib/check.sh --fast: with HARNESS_CHECK_FAST_CMD empty it is the bare form; set, a green-/red-<key> answers first, then fast-<key>, else the fast tier runs (same scope, cap, timeout, rerun guard) to check-fast.out; green writes fast-<key> only, red no marker; flake rows get tier fast. CHECK_FAST_CMD in config/prompt_env/template, this repo sets --tier fast. decisions/2026-11-03-fast-gate.; tests 1186 → 1205; files lib/check.sh, lib/config.sh, lib/prompt.sh, templates/project/config.sh, .harness/config.sh, … → entries.jsonl:7

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

_76 older rules: journal/decisions._
