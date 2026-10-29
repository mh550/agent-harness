# Context pack for `N1`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Dead end (N1-05, 06-N1-05): a Gotchas line on finish's uncached suite — the section was already at 15 lines; memlint (39-memlint-m4) fails at 16, so it was dropped → entries.jsonl:7
- Dead end (N1-04, 05-N1-04): the unit check asserting build's keys minus the fixture's are exactly flakes — summary-report.json predates lanes and review: build has those too; the check asserts fixture keys ⊆ build keys and flakes new → entries.jsonl:6
- Dead end (N1-03, 03-N1-03): the step's `$T/scratch/proj/<run>/lanes/M1/check-rerun.out exists` for the invariant — the stub's C is in lane M2, and check.sh removes check-rerun.out at the next full suite (C's second init); the check reads the `red again on a rerun of the whole suite) — last lines of …/lanes/M2/check-rerun.out:` line in logs/04-C.prompt.md instead → entries.jsonl:4
- Dead end (N1-03, 03-N1-03): a Gotchas line about that — CLAUDE.md's Gotchas already had 15 lines; memlint (39-memlint-m4) fails at 16; the fact is in 74's header comment → entries.jsonl:4
- Dead end (N1-03, 03-N1-03): run_init reading the marker on every init (an extra node treekey per init while tests-start is absent, i.e. every stub init) — 47-lanes-two`s u5 admission check failed in 3 full runs in a row; now read only when check-rerun.out is beside check.out; the next full run passed 47 but failed 45 (load flake, R1) → entries.jsonl:4
- Dead end (N1-02, 02-N1-02): a Gotchas line on HARNESS_CHECK_RERUN=off for checks reading the first RED line — ## Gotchas is already at 15 lines and memlint fails at 16; the fact is in check.sh's header and the decision instead → entries.jsonl:3
- Question (N1-05): The review (Important, triaged to a default): a check file tests/run.sh stops at TEST_FILE_TIMEOUT is named in HARNESS_FAILED=, so CHECK_RERUN=auto reruns it, at most one more TEST_FILE_TIMEOUT (10m). Keep that (default: a hang under load is the likeliest flake), or skip the rerun when a file timed out? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29/slot-0/tests/run.sh:54, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29/slot-0/journal/decisions/2026-10-29-rerun-guard.md → entries.jsonl:7
- 2026-10-29 04:56 · N1-05 · passes: Opus review of N1: finish now notes a flake on its own last suite (RED→GREEN stub run fe); a non-object flakes.jsonl row is skipped by summary and flakes_note; check.sh shares one green branch and one rerun call; arch §3/§4/§7/§10, README, decision updated. Hung-file rerun kept as a default (question). 0 Critical, 1 Important, 7 Minor; tests 885 → 886; files lib/check.sh, lib/driver.sh, lib/record.sh, lib/summary.mjs, tests/checks/74-flakes-run.sh, … → entries.jsonl:7
- 2026-10-29 04:02 · N1-04 · passes: summary.mjs: flakes {count, names} from <state>/green/flakes.jsonl (tolerant reader, whole suite for no names), a Flakes row after Tests in report.md and the TTY card (n · name ×k, 0, none for older summaries), flakers() + `summary.mjs flakers <ledger>/<project>` for the debrief's #### flakes block after report.md. 4 new checks in 74-flakes-run; docs and decision updated.; tests 881 → 885; files lib/summary.mjs, lib/debrief.sh, tests/checks/74-flakes-run.sh, tests/fixtures/check-names.txt, docs/architecture.md, … → entries.jsonl:6
- 2026-10-29 03:45 · N1-03 · passes: Attempt 1's code (cfb23fc) verified: flakes_note in lib/record.sh, called after the un-pass check, verify, disjoint re-base and in finish before run ended; run_init's tests-start from the marker after a rerun. 74-flakes-run 6/6; full suite green on this tree at init (881 tests, 622 s, no rerun).; tests 881 → 881; files lib/record.sh, lib/lane.sh, lib/driver.sh, tests/checks/74-flakes-run.sh, tests/fixtures/check-names.txt, … → entries.jsonl:5
- 2026-10-29 03:33 · N1-03 · not yet: flakes_note (lib/record.sh) notes each new green/flakes.jsonl row once (`flaky: <names|whole suite> (red, then green on a rerun; load <1-min>)`, offset in flakes-noted, locked) after the un-pass check, verify, disjoint re-base and before run ended; run_init takes tests-start from the marker after a rerun. 74-flakes-run 6/6. Not passed: no full suite came out green (one load flake each run).; tests 875 → 881; files lib/record.sh, lib/lane.sh, lib/driver.sh, tests/checks/74-flakes-run.sh, tests/fixtures/check-names.txt, … → entries.jsonl:4
- 2026-10-29 02:15 · N1-02 · passes: check.sh's full form reruns a red once by CHECK_RERUN (auto/failed/suite/off): never after a timeout or cap kill; check-rerun.out; green rerun → 'green after a rerun (flaky: …)', marker = first run's total (testcount --total), a flakes.jsonl row. tests/run.sh prints HARNESS_FAILED=<files> unless a failure is outside them. Config, prompt_env, HARNESS_LANE, template, decision.; tests 859 → 875; files lib/check.sh, lib/testcount.mjs, tests/run.sh, lib/config.sh, lib/prompt.sh, … → entries.jsonl:3
- 2026-10-29 01:46 · N1-01 · passes: Wrote docs/plans/2026-10-29-N1-rerun-guard.md: the rerun's place and rules in lib/check.sh (CHECK_RERUN table, never-rerun exits, marker from the first run's total via testcount --total), the HARNESS_FAILED= guard in tests/run.sh, the flakes.jsonl row, flakes_note's sites and lock, summary/report/debrief, every new check name by file, docs.; tests 859 → 859; files docs/plans/2026-10-29-N1-rerun-guard.md → entries.jsonl:2

## Discoveries for this feature

- Discovery (N1-05, affects R1, run): 08-scope-sh-l1-02 flakes under the full suite's load (memory gate waits, the real 64M scope check), green alone: an R1 flaker beside 45-lanes-run → entries.jsonl:7
- Discovery (N1-05, affects run): review findings left open (Minor): run_init tests-start falls back to a red check.out's passes when a flake's marker is empty (suites with no N/M line); testcount --total undercounts a file killed mid-way; the debrief prints the project-wide #### flakes block once per run, not once per project; a fractional CHECK_TIMEOUT (1.5h) makes why() miss a timeout's 137 → entries.jsonl:7
- Discovery (N1-04, affects N1-05): tests/fixtures/summary-report.json predates the lanes and review keys: build() produces keys it lacks, so compare it as a subset → entries.jsonl:6
- Discovery (N1-04, affects N1-05): the debrief's flakes block reads $LEDGER/<basename of PROJECT_DIR>, as rec_dir does; the check runs debrief --dry-run with its own HARNESS_LEDGER so the stub runs' ledgered summaries don't count → entries.jsonl:6
- Discovery (N1-03, affects N1-04, N1-05): flakes_note notes an empty load as `load ?`; its message is built in jq, one call per flakes_note → entries.jsonl:4
- Discovery (N1-03, affects N1-04): 74-flakes-run.sh has check_cmd <subject> <command>: commits a CHECK_CMD on the first main and pushes it; N1-04's stub-run checks (summary.json flakes, report's Flakes row) can read the fl and inv runs already there → entries.jsonl:4
- Discovery (N1-03, affects run): the live suite check.sh (projects/agent-harness, main) has no rerun yet: a full run from a session goes red on one flake until N1 merges → entries.jsonl:4
- Discovery (N1-03, affects R1, run): 47-lanes-two `lanes admission: with the five-hour window at 80 %…` and 45-lanes-run `a lane opened after the default lane…` fail under the full suite`s load, pass alone: R1 flakers → entries.jsonl:4
- Discovery (N1-03, affects N1-03): the next N1-03 attempt only needs one green full suite on cfb23fc (or its successor): the code and 74 are done → entries.jsonl:4
- Discovery (N1-02, affects N1-03, N1-04): tests/lib.sh's suite_setup now unsets HARNESS_CHECK_RERUN and HARNESS_LANE, so a session's own values never reach a check; a stub run gets CHECK_RERUN=auto from lib/config.sh → entries.jsonl:3
- Discovery (N1-02, affects N1-03): a rerun-red's RED line names check-rerun.out, not check.out: a stub run's red now leaves $SCRATCH/lanes/<m>/check-rerun.out (N1-03's invariant check can rely on it) → entries.jsonl:3
- Discovery (N1-02, affects N1-05): why() gained a third argument (the run's own seconds, for the timeout test) so a rerun's 137 isn't called a timeout by the two runs' summed time; N1-05's fold should keep it → entries.jsonl:3
- Discovery (N1-02, affects N1): the first full suite after this change printed HARNESS_FAILED=15-run-4-same-but-queue-parked-debrief-tmux 39-memlint-m4 on a real red: the line works on the real suite → entries.jsonl:3
- Discovery (N1-01, affects N1-02): check.sh's find deletes every check-*.out but check-<key>.out after the full run: check-rerun.out must be written after it, and rm'd before the first run → entries.jsonl:2
- Discovery (N1-01, affects N1-02): 08-scope-sh's ck() calls check.sh with exit 3 and exit 137 (short of the cap) and greps '— last lines of .../check.out': under auto they rerun; pin HARNESS_CHECK_RERUN=off in ck() → entries.jsonl:2
- Discovery (N1-01, affects N1-03): run_init writes tests-start from check.out, which after a rerun-green is the red run (its passes, not the total); take it from the marker first, as tests_end does → entries.jsonl:2
- Discovery (N1-01, affects N1-02): a rerun-green with no N/M total leaves an empty marker, and the cached line and tests_end then fall back to check-<key>.out, the red run's count: the plan removes check-<key>.out then → entries.jsonl:2
- Discovery (N1-01, affects N1-04): summary.mjs's jsonl() throws on a bad line; flakes.jsonl is appended by lanes at once, so read it tolerantly → entries.jsonl:2
- Discovery (init, affects run): the suite took 604 s at init here (859 checks); each full run inside a feature costs about 10 min, so a build feature runs it twice at most → entries.jsonl:1
- Discovery (init, affects run): HARNESS_LANE is not exported anywhere today; N1-02 exports it from lib/lane.sh so flakes.jsonl rows and resolve sessions can name their lane → entries.jsonl:1
- Discovery (init, affects run): the stub project's CHECK_CMD (`test ! -f BROKEN`, tests/lib.sh) prints no HARNESS_FAILED= line, so in stub runs CHECK_RERUN=auto reruns the whole suite: the flaky note reads `flaky: whole suite` → entries.jsonl:1
- Discovery (init, affects run): scope_run clears <unit>.started and .show before each call, so check.sh can run its rerun through run() with the same unit name → entries.jsonl:1
- Discovery (init, affects run): the last run's build features took 25 to 78 min each (the lane-wiring ones the longest); N2-03 and N2-04 are the big ones here and may take two attempts → entries.jsonl:1

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
- Where things go: one routing block in every session's prompt, unless CLAUDE.md has its own; one decisions store per project → journal/decisions/2026-10-26-where-things-go.md
- Verify runs the suite in full: the verified tree's cached green is removed first → journal/decisions/2026-10-26-verify-runs-the-suite.md
- Verify before the deadline: one session per complete milestone, then finish → journal/decisions/2026-10-26-verify-before-deadline.md
- A test-count contract: a suite's own `HARNESS_TESTS=<n>` line wins over scraping its summary → journal/decisions/2026-10-26-test-count-contract.md
- The suite is a runner over check files cut from the single file by its markers, grouped where a section reads another's state → journal/decisions/2026-10-26-suite-split.md
- A stop records why: `harness stop --why` and `status: stop <why>` → journal/decisions/2026-10-26-stop-reason.md
- Step lint: four pure rules over the feature list, reported and never applied → journal/decisions/2026-10-26-step-lint.md
- Reviews sized to the milestone: small milestones fold the review into their last build feature → journal/decisions/2026-10-26-reviews-sized-to-milestone.md
- The retro backlog: the retro proposes as data, the driver is the only writer → journal/decisions/2026-10-26-retro-backlog.md
- Resolved questions leave the pack; `project` facts wait under `Promote to Gotchas` until a Gotchas line carries them → journal/decisions/2026-10-26-resolved-and-project-facts.md
- Requested continuations run; automatic ones still skip a run Michael stopped → journal/decisions/2026-10-26-requested-continuations.md
- Real test counts: one rule per runner, proven on a fixture each; a suite with no count is said once per run → journal/decisions/2026-10-26-real-test-counts.md
- Queue numbers count parked entries; a park never overwrites one → journal/decisions/2026-10-26-queue-numbering-and-park.md
- Admission by headroom: a second lane (and later a second run) opens when the box and the plan have room for it → journal/decisions/2026-10-26-parallel-runs-headroom.md

_41 older rules: journal/decisions._
