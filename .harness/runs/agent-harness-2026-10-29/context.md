# Context pack for `N1-03`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (N1-02, affects N1-03, N1-04): tests/lib.sh's suite_setup now unsets HARNESS_CHECK_RERUN and HARNESS_LANE, so a session's own values never reach a check; a stub run gets CHECK_RERUN=auto from lib/config.sh → entries.jsonl:3
- Discovery (N1-02, affects N1-03): a rerun-red's RED line names check-rerun.out, not check.out: a stub run's red now leaves $SCRATCH/lanes/<m>/check-rerun.out (N1-03's invariant check can rely on it) → entries.jsonl:3
- Discovery (N1-02, affects N1): the first full suite after this change printed HARNESS_FAILED=15-run-4-same-but-queue-parked-debrief-tmux 39-memlint-m4 on a real red: the line works on the real suite → entries.jsonl:3
- Discovery (N1-01, affects N1-03): run_init writes tests-start from check.out, which after a rerun-green is the red run (its passes, not the total); take it from the marker first, as tests_end does → entries.jsonl:2
- Discovery (init, affects run): the suite took 604 s at init here (859 checks); each full run inside a feature costs about 10 min, so a build feature runs it twice at most → entries.jsonl:1
- Discovery (init, affects run): HARNESS_LANE is not exported anywhere today; N1-02 exports it from lib/lane.sh so flakes.jsonl rows and resolve sessions can name their lane → entries.jsonl:1
- Discovery (init, affects run): the stub project's CHECK_CMD (`test ! -f BROKEN`, tests/lib.sh) prints no HARNESS_FAILED= line, so in stub runs CHECK_RERUN=auto reruns the whole suite: the flaky note reads `flaky: whole suite` → entries.jsonl:1
- Discovery (init, affects run): scope_run clears <unit>.started and .show before each call, so check.sh can run its rerun through run() with the same unit name → entries.jsonl:1
- Discovery (init, affects run): the last run's build features took 25 to 78 min each (the lane-wiring ones the longest); N2-03 and N2-04 are the big ones here and may take two attempts → entries.jsonl:1

## What it builds on

- 2026-10-29 02:15 · N1-02 · passes: check.sh's full form reruns a red once by CHECK_RERUN (auto/failed/suite/off): never after a timeout or cap kill; check-rerun.out; green rerun → 'green after a rerun (flaky: …)', marker = first run's total (testcount --total), a flakes.jsonl row. tests/run.sh prints HARNESS_FAILED=<files> unless a failure is outside them. Config, prompt_env, HARNESS_LANE, template, decision.; tests 859 → 875; files lib/check.sh, lib/testcount.mjs, tests/run.sh, lib/config.sh, lib/prompt.sh, … → entries.jsonl:3

## Lately in the run

- 2026-10-29 01:46 · N1-01 · passes: Wrote docs/plans/2026-10-29-N1-rerun-guard.md: the rerun's place and rules in lib/check.sh (CHECK_RERUN table, never-rerun exits, marker from the first run's total via testcount --total), the HARNESS_FAILED= guard in tests/run.sh, the flakes.jsonl row, flakes_note's sites and lock, summary/report/debrief, every new check name by file, docs.; tests 859 → 859; files docs/plans/2026-10-29-N1-rerun-guard.md → entries.jsonl:2
- 2026-10-29 01:40 · init · passes: 11 features: N1 5 (plan, 3 build, review), N2 6 (plan, 4 build, review); in series, N2 after N1 as the spec asks. First N1-01 (plan), N1-02 (HARNESS_FAILED= and the check.sh rerun), N1-03 (flakes_note and the invariant). → entries.jsonl:1

## Current rules

- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
- This repo's suite gets a 25-minute check timeout; TEST_JOBS stays at its default → journal/decisions/2026-10-29-check-timeout-25m.md
- `harness show`: where a run's work is, from local refs, one change counted once → journal/decisions/2026-10-28-show.md
- A plain start or continue queues behind a live run of its project; overlaps are named, never held → journal/decisions/2026-10-27-same-project-starts.md
- The review gate: a milestone review's model by its measured diff, one Opus round after a Sonnet finding → journal/decisions/2026-10-27-review-gate.md
- A finished run keeps its record after gc: report reads worktree → state → ledger → journal/decisions/2026-10-27-record-after-gc.md
- Read views: one formatter, `lib/view.mjs`, that every read view renders through → journal/decisions/2026-10-27-read-views.md
- Questions where Michael sees them: one INBOX parser, the steering comment repaired → journal/decisions/2026-10-27-question-locations.md
- Project names: one resolver takes a path or a bare name → journal/decisions/2026-10-27-project-names.md
- Merging the memory run into lanes: main's driver changes in their lane-era homes, the review round per lane → journal/decisions/2026-10-27-p1-main-merge.md
- What waits on Michael: one needs record per item, swept by its reason's rule → journal/decisions/2026-10-27-needs-record.md
- Lane branches go when their PR merges; gc reaps lane branches, leftover slots and a killed run's lane units → journal/decisions/2026-10-27-lane-branches-and-slots.md
- gc's foreign units: another project's are silent, an unowned one is said with its command → journal/decisions/2026-10-27-gc-foreign-units.md

_55 older rules: journal/decisions._
