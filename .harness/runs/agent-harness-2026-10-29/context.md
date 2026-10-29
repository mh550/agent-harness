# Context pack for `N1-05`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (N1-04, affects N1-05): tests/fixtures/summary-report.json predates the lanes and review keys: build() produces keys it lacks, so compare it as a subset → entries.jsonl:6
- Discovery (N1-04, affects N1-05): the debrief's flakes block reads $LEDGER/<basename of PROJECT_DIR>, as rec_dir does; the check runs debrief --dry-run with its own HARNESS_LEDGER so the stub runs' ledgered summaries don't count → entries.jsonl:6
- Discovery (N1-03, affects N1-04, N1-05): flakes_note notes an empty load as `load ?`; its message is built in jq, one call per flakes_note → entries.jsonl:4
- Discovery (N1-03, affects run): the live suite check.sh (projects/agent-harness, main) has no rerun yet: a full run from a session goes red on one flake until N1 merges → entries.jsonl:4
- Discovery (N1-03, affects R1, run): 47-lanes-two `lanes admission: with the five-hour window at 80 %…` and 45-lanes-run `a lane opened after the default lane…` fail under the full suite`s load, pass alone: R1 flakers → entries.jsonl:4
- Discovery (N1-02, affects N1-05): why() gained a third argument (the run's own seconds, for the timeout test) so a rerun's 137 isn't called a timeout by the two runs' summed time; N1-05's fold should keep it → entries.jsonl:3
- Discovery (N1-02, affects N1): the first full suite after this change printed HARNESS_FAILED=15-run-4-same-but-queue-parked-debrief-tmux 39-memlint-m4 on a real red: the line works on the real suite → entries.jsonl:3
- Discovery (init, affects run): the suite took 604 s at init here (859 checks); each full run inside a feature costs about 10 min, so a build feature runs it twice at most → entries.jsonl:1
- Discovery (init, affects run): HARNESS_LANE is not exported anywhere today; N1-02 exports it from lib/lane.sh so flakes.jsonl rows and resolve sessions can name their lane → entries.jsonl:1
- Discovery (init, affects run): the stub project's CHECK_CMD (`test ! -f BROKEN`, tests/lib.sh) prints no HARNESS_FAILED= line, so in stub runs CHECK_RERUN=auto reruns the whole suite: the flaky note reads `flaky: whole suite` → entries.jsonl:1
- Discovery (init, affects run): scope_run clears <unit>.started and .show before each call, so check.sh can run its rerun through run() with the same unit name → entries.jsonl:1
- Discovery (init, affects run): the last run's build features took 25 to 78 min each (the lane-wiring ones the longest); N2-03 and N2-04 are the big ones here and may take two attempts → entries.jsonl:1

## What it builds on

- 2026-10-29 04:02 · N1-04 · passes: summary.mjs: flakes {count, names} from <state>/green/flakes.jsonl (tolerant reader, whole suite for no names), a Flakes row after Tests in report.md and the TTY card (n · name ×k, 0, none for older summaries), flakers() + `summary.mjs flakers <ledger>/<project>` for the debrief's #### flakes block after report.md. 4 new checks in 74-flakes-run; docs and decision updated.; tests 881 → 885; files lib/summary.mjs, lib/debrief.sh, tests/checks/74-flakes-run.sh, tests/fixtures/check-names.txt, docs/architecture.md, … → entries.jsonl:6

## Lately in the run

- 2026-10-29 03:45 · N1-03 · passes: Attempt 1's code (cfb23fc) verified: flakes_note in lib/record.sh, called after the un-pass check, verify, disjoint re-base and in finish before run ended; run_init's tests-start from the marker after a rerun. 74-flakes-run 6/6; full suite green on this tree at init (881 tests, 622 s, no rerun).; tests 881 → 881; files lib/record.sh, lib/lane.sh, lib/driver.sh, tests/checks/74-flakes-run.sh, tests/fixtures/check-names.txt, … → entries.jsonl:5
- 2026-10-29 03:33 · N1-03 · not yet: flakes_note (lib/record.sh) notes each new green/flakes.jsonl row once (`flaky: <names|whole suite> (red, then green on a rerun; load <1-min>)`, offset in flakes-noted, locked) after the un-pass check, verify, disjoint re-base and before run ended; run_init takes tests-start from the marker after a rerun. 74-flakes-run 6/6. Not passed: no full suite came out green (one load flake each run).; tests 875 → 881; files lib/record.sh, lib/lane.sh, lib/driver.sh, tests/checks/74-flakes-run.sh, tests/fixtures/check-names.txt, … → entries.jsonl:4

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
