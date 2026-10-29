# Context pack for `N2-02`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Verify N2 found (N2-02 step 2): ran a base line one side removed stays removed; a line both sides added is one line; a side that fails `LC_ALL=C s; saw Ran merge-sorted.sh with O=a,b A=b,a B=a,b,c: exit 1 but A was rewritten with git merge-file conflict markers (cmp differs); removal and both-add cases hold. Step says A untouched; N2-06 review fix changed it deliberately. → entries.jsonl:15
- 2026-10-29 06:07 · N2-02 · passes: Layer 1: lib/merge-sorted.sh (three-way sorted union; an unsorted side exits 1, A untouched), .gitattributes opts check-names.txt in, merge_drivers (lib/record.sh) sets the driver as worktree config in the record worktree each segment and in slot_open; STUB_SORTED; 75-merge-sorted.sh (7 checks, ~14 s); decision started.; tests 886 → 893; files lib/merge-sorted.sh, lib/record.sh, lib/driver.sh, .gitattributes, tests/stub-claude.sh, … → entries.jsonl:10

## Discoveries for this feature

- Discovery (N2-06, affects run): open Minor review findings: resolved-<m> is written with > (sync_main's then rebase's resolution keeps only the last files in the PR body; the plan said >>); slot_open's reset after a killed resolve still commits the session's untracked files as WIP; resolve ignores S_EXIT (a timed-out session that git-added clean files is committed, the verify still gates it); a rebase refused by resolve's mem_gate (lanes-end/stop, no RESOLVE_END) exits the lane 0 'its re-base waits' not 16/14; rebase's main_clear runs before the re-base's outcome; 77's slot_open check's `! -e resolve-called` half can't fail → entries.jsonl:14
- Discovery (N2-06, affects run): merge_main <m> <resolve|""> (lib/record.sh) is the one conflict path into resolve: 0 merged (MERGE_RESOLVED when a session settled it), 1 aborted (MERGE_FILES, RESOLVE_TRIED), 2 refused → entries.jsonl:14
- Discovery (N2-01, affects N2-02, N2-03): git 2.43 merge-tree --write-tree runs a configured merge driver (attributes from the checkout's .gitattributes), so layer 1 also settles merge_one's merge-tree → entries.jsonl:9
- Discovery (N1-05, affects R1, run): 08-scope-sh-l1-02 flakes under the full suite's load (memory gate waits, the real 64M scope check), green alone: an R1 flaker beside 45-lanes-run → entries.jsonl:7
- Discovery (N1-05, affects run): review findings left open (Minor): run_init tests-start falls back to a red check.out's passes when a flake's marker is empty (suites with no N/M line); testcount --total undercounts a file killed mid-way; the debrief prints the project-wide #### flakes block once per run, not once per project; a fractional CHECK_TIMEOUT (1.5h) makes why() miss a timeout's 137 → entries.jsonl:7
- Discovery (N1-03, affects run): the live suite check.sh (projects/agent-harness, main) has no rerun yet: a full run from a session goes red on one flake until N1 merges → entries.jsonl:4
- Discovery (N1-03, affects R1, run): 47-lanes-two `lanes admission: with the five-hour window at 80 %…` and 45-lanes-run `a lane opened after the default lane…` fail under the full suite`s load, pass alone: R1 flakers → entries.jsonl:4
- Discovery (init, affects run): the suite took 604 s at init here (859 checks); each full run inside a feature costs about 10 min, so a build feature runs it twice at most → entries.jsonl:1
- Discovery (init, affects run): HARNESS_LANE is not exported anywhere today; N1-02 exports it from lib/lane.sh so flakes.jsonl rows and resolve sessions can name their lane → entries.jsonl:1
- Discovery (init, affects run): the stub project's CHECK_CMD (`test ! -f BROKEN`, tests/lib.sh) prints no HARNESS_FAILED= line, so in stub runs CHECK_RERUN=auto reruns the whole suite: the flaky note reads `flaky: whole suite` → entries.jsonl:1
- Discovery (init, affects run): scope_run clears <unit>.started and .show before each call, so check.sh can run its rerun through run() with the same unit name → entries.jsonl:1
- Discovery (init, affects run): the last run's build features took 25 to 78 min each (the lane-wiring ones the longest); N2-03 and N2-04 are the big ones here and may take two attempts → entries.jsonl:1

## What it builds on

- 2026-10-29 05:40 · N2-01 · passes: Wrote docs/plans/2026-10-29-N2-conflict-resolution.md: merge-sorted.sh + merge_drivers, resolve/resolve_ok in lib/resolve.sh (rc 0/1/2, RESOLVE_END, snapshot, checks, bounds), exact changes in sync_main, verify, rebase, merge_one(+--open) and slot_open (stays), the gate, stub flags and modes, tried, visible, checks by file. Opus review: 0 Critical, 7 Important, 5 Minor, all folded in.; tests 886 → 886; files docs/plans/2026-10-29-N2-conflict-resolution.md → entries.jsonl:9

## Lately in the run

- 2026-10-29 08:46 · verify N2 · not yet: N2-02 step 2 fails: an unsorted side now gets git merge-file markers in A (exit 1), not A untouched as the step says (deliberate N2-06 change; the step or code needs aligning). Other features hold; suite green (925). Only spot-checked 03-06 steps via files and suite. → entries.jsonl:15
- 2026-10-29 08:34 · N2-06 · passes: N2 review + simplify + docs. merge-sorted.sh: an unsorted side now gets git merge-file (markers kept; git keeps %A whatever the exit). sync_main and rebase share merge_main (lib/record.sh). report's Spend by role names resolve. architecture.md §3-§12, README, decision completed. 0 Critical, 1 Important, 7 Minor; tests 924 → 925; files lib/merge-sorted.sh, lib/record.sh, lib/lane.sh, lib/summary.mjs, tests/checks/75-merge-sorted.sh, … → entries.jsonl:14
- 2026-10-29 08:13 · N2-05 · passes: Resolutions are visible, never asked about: resolved_note (lib/resolve.sh) from rebase and sync_main; summary.mjs conflicts {resolved, escalated, sessions} plus resolutions [{milestone, files}] and report's Conflicts row after Flakes; pr_body's `Merged main in with a resolve session: <files>` from resolved-<m>. 6 new checks in 76/77; decision updated.; tests 918 → 924; files lib/resolve.sh, lib/lane.sh, lib/record.sh, lib/summary.mjs, tests/checks/76-resolve-session.sh, … → entries.jsonl:13

## Current rules

- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
- Merge conflicts resolved without Michael: a sorted merge for lists first, then a resolve session, verified → journal/decisions/2026-10-29-conflict-resolution.md
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

_57 older rules: journal/decisions._
