# Context pack for `N2-05`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (N2-04, affects N2-05, N2-06): resolve's tried is stored in the resolve-<m>-<main> marker, so a later record for the same main (resolve_ok: already ran) keeps tried; MAX_RESOLVES sets tried to `its <n> resolve session(s) used` → entries.jsonl:12
- Discovery (N2-04, affects N2-05, N2-06): rebase writes conflict-<m> before rebase_fail: without it the run's-end merge_one re-opened merge_conflict, dropping tried and the rebase variant, and notified twice → entries.jsonl:12
- Discovery (N2-04, affects N2-05): stub resolve sessions report 0 min (S_WALL 0): a check on tried's minutes matches [0-9]+ → entries.jsonl:12
- Discovery (N2-04, affects N2-05, N2-06): a unit calling resolve() needs USAGE and REC set (weekly gate, metrics row) or it dies under set -u mid-function → entries.jsonl:12
- Discovery (N2-03, affects N2-05): resolved-<m> is overwritten (>) on each successful resolve, not appended, so N2-05's PR body lists the last resolution's files once → entries.jsonl:11
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

- 2026-10-29 07:46 · N2-04 · passes: Layer 2 fallbacks: stub STUB_MERGE_RESOLVE markers/stray/give-up, STUB_RESOLVE_LIMIT, STUB_MAIN_TOUCH=resolve-<m>; sync_main resolves in a lane (verify defers on a refusal, skips sync_main in rebase mode); needs cards' tried; rebase records conflict-<m>; 77-resolve-fallbacks (12). Opus review: 0 Critical, 2 Important, 1 Minor, all fixed.; tests 905 → 918; files lib/record.sh, lib/lane.sh, lib/resolve.sh, lib/needs.mjs, bin/harness, … → entries.jsonl:12

## Lately in the run

- 2026-10-29 07:04 · N2-03 · passes: Layer 2 happy path: lib/resolve.sh (resolve_ok, resolve: snapshot, session on RESOLVE_*, journal, metrics row, checks, NUL-safe restore, commit), prompts/resolve.md, CONFLICTS/RESOLVE_*/MAX_RESOLVES, stub # Resolve session (both) and STUB_CONFLICT; merge_one returns 3 in a lane, rebase resolves then verifies; 76-resolve-session (12 checks). Opus review: 1 Critical, 3 Important, 7 Minor, all fixed.; tests 893 → 905; files lib/resolve.sh, prompts/resolve.md, lib/lane.sh, lib/record.sh, lib/config.sh, … → entries.jsonl:11
- 2026-10-29 06:07 · N2-02 · passes: Layer 1: lib/merge-sorted.sh (three-way sorted union; an unsorted side exits 1, A untouched), .gitattributes opts check-names.txt in, merge_drivers (lib/record.sh) sets the driver as worktree config in the record worktree each segment and in slot_open; STUB_SORTED; 75-merge-sorted.sh (7 checks, ~14 s); decision started.; tests 886 → 893; files lib/merge-sorted.sh, lib/record.sh, lib/driver.sh, .gitattributes, tests/stub-claude.sh, … → entries.jsonl:10

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
- Lane branches go when their PR merges; gc reaps lane branches, leftover slots and a killed run's lane units → journal/decisions/2026-10-27-lane-branches-and-slots.md

_56 older rules: journal/decisions._
