# Context pack for `R3-03`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (R3-02, affects R3-06, run): 13/14-run-2 pin the initializer's lint sentence ending `milestone's size doesn't call for). No output means clean.`: a new lint item goes before the review one → entries.jsonl:18
- Discovery (R3-02, affects R1-07, run): Under this box's load (~21) the full suite took 1237 s and 08-scope and 48-lanes-rebase (a non-fast-forward push to origin main) flaked once each, green on the rerun → entries.jsonl:18
- Discovery (R1-05, affects run): Merging origin/main brought R2 in: its stub-claude.sh header comments conflicted with R1-02's STUB_BARRIER comment. Both are kept; the suite went from 944 to 973 checks. → entries.jsonl:17
- Discovery (R3-01, affects R3-03): The ignored-paths merge note must contain neither 're-base' nor 'moved since' (R3-03 step 1 greps both absent): plan gives '<m>: main changed only in ignored paths (<paths>); merged as verified' → entries.jsonl:16
- Discovery (R3-01, affects R3-03): finish: ledger reads $SCRATCH/retro-proposals.json, so ledger and scratch_done move together after record_pr; the backlog note then misses main's copy → entries.jsonl:16
- Discovery (R3-01, affects R3-02, run): unreproducible flags 3 steps of this run's list (R1-02 step 4 'below 5 s', R3-01 step 3, R3-02 step 3 quoting the examples): expected, reported never applied → entries.jsonl:16
- Discovery (R2, affects run): N2 is on origin main now (grep -c ...-N[12]$ = 2; 645d87e, in R2's HEAD): the R2/R1 plans' 'needs Michael' dependency line is stale → entries.jsonl:15
- Discovery (R2-05, affects run): Left by the review (Minor): the resume ignores a stop/lanes-end/deadline (bounded 10m, $1), and a refused resume is not fed to limit_raise → entries.jsonl:11
- Discovery (R1-03, affects R1-07, run): 13-run-2-michael-sets-desk 'harness desk --list' flakes under the full suite's load (R2-02 and R1-03 each saw it once, green on the rerun); not in the plan's flaker table → entries.jsonl:10
- Discovery (R1-03, affects run): origin/main came with 16 Gotchas lines (memlint red on main itself); this lane dropped the end-reasons line when it merged main → entries.jsonl:10
- Discovery (R1-02, affects run): ## Gotchas holds 14 bullets at most: memlint counts its <!-- --> comment line among the 15 → entries.jsonl:8
- Discovery (R2-01, affects run): 39-memlint-m4 lints this worktree's CLAUDE.md: a 16th Gotchas line turns the suite red; replace a line, never add past 15 → entries.jsonl:4
- Discovery (R1-01, affects run): N2 is not on origin main (1 of N1/N2 merged): an overlap conflict between lanes needs Michael → entries.jsonl:3
- Discovery (init, affects run): N2 (conflict resolution) is not on origin main: N2-02 waits on Michael. Only N1 merged (grep -c harness-merge/...-N[12] = 1). A text conflict between two lanes needs Michael as before; each plan says so in one line. → entries.jsonl:1
- Discovery (init, affects R3): lib/entries.mjs already writes progress.md atomically (writeAtomic); R3-02's atomic writes concern lib/features.mjs only. → entries.jsonl:1
- Discovery (init, affects run): R2 and R3 both edit lib/record.sh and prompts/coding.md; R2-02 and R3-02 both edit prompts/initializer.md. Whichever merges second takes a re-base verify round; a text conflict needs Michael (no N2). → entries.jsonl:1

## Promote to Gotchas

- stub --resume of an unknown id substitutes session_id but leaves the fixture's 00000000-… id in the result line's errors[] (the real CLI names the asked id there) → entries.jsonl:15

## What it builds on

- 2026-10-29 15:29 · R3-01 · passes: Wrote docs/plans/2026-10-29-R3-leftovers.md: one section per R3 item with its function, file at 53bdc66 and check file; Minor 8 quoted and found cheap (built in R3-04); unreproducible's regexes tried on every example; N1 and N2 both on origin main (2). Plan only; Gotchas: promoted the stub --resume line in place of the HARNESS_NOW one.; tests 963 → 963; files docs/plans/2026-10-29-R3-leftovers.md, CLAUDE.md → entries.jsonl:16

## Lately in the run

- 2026-10-29 16:14 · R3-02 · passes: lib/features.mjs: every list/attempts/parked write goes through writeAtomic (<file>.<pid>.tmp + renameSync; namespace import, so grep -c writeFileSync = 1). lint gains unit-collision (LANEU mapping, one finding per colliding milestone) and unreproducible (time bounds, one run's test counts, this run's check.out). initializer.md states counts as commands. 5 checks in 07, 1 in new 77-leftovers.sh.; tests 963 → 969; files lib/features.mjs, prompts/initializer.md, tests/checks/07-step-lint-pure-r3.sh, tests/checks/77-leftovers.sh, tests/fixtures/check-names.txt → entries.jsonl:18
- 2026-10-29 15:41 · R1-05 · passes: Both run flakers are R1-04's lane-count race. Neither reproduced unforced (10/10 green each). Forced with HARNESS_COUNT_HOLD=1 on the pre-fix driver, 28 ended 'no feature left to try' before M2 and 15's weekly run did too. Both runs now start with the hold: red before the fix (0/1), 10/10 after. Plan rows filled; decision updated in place. Merged origin/main.; tests 944 → 973; files tests/checks/15-run-4-same-but-queue-parked-debrief-tmux.sh, tests/checks/28-run-14d-harness-merge.sh, docs/plans/2026-10-29-R1-flakes.md, journal/decisions/2026-10-29-lane-count-end-check.md, tests/stub-claude.sh → entries.jsonl:17

## Current rules

- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
- Entries that survive: the session checks its own, a long summary is cut and kept, one resume for a missing one → journal/decisions/2026-10-29-entries-survive.md
- A parked run's continue advice names another live run of its project and gives Michael the choice → journal/decisions/2026-10-29-continue-advice-busy-project.md
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

_58 older rules: journal/decisions._
