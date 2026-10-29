# Context pack for `R3-06`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (R3-05, affects R3-06): No bug: gc --dry-run's slot and lane-branch passes print would: lines only, and merge.lock serializes two merge_milestones (the second finds merged-M1 silently) → entries.jsonl:24
- Discovery (R3-05, affects R3-06): Without merge.lock two merge_milestones on one clone race on the harness-merge push (ref lock) or note 'already there': the lock is what keeps the note single → entries.jsonl:24
- Discovery (R3-05, affects run): Promote item 'tests/lib.sh now holds tended, held…' does not hold on R3's branch (R1-07's lib.sh is not merged here; 47/48/49/76/77-resolve define held and ats themselves): left for a session on a branch with R1 in → entries.jsonl:24
- Discovery (R3-04, affects R3-06, run): 08-scope flaked twice in this session's full runs (gatestop memory gate; M2's lane never started, 2/3 passing): R1-06's fixes (HARNESS_COUNT_HOLD, gatestop at 2 GB) are not on this lane's base → entries.jsonl:22
- Discovery (R3-04, affects R3-06): An escalated review's first metrics row, passes= note and 'HARNESS: after R' commit now say passes=false (were true) → entries.jsonl:22
- Discovery (R1-07, affects run): The coordinator's opens skip a milestone whose lanes/<m>/pid is still there (exited, unreaped); HARNESS_COUNT_HOLD leaves state/count-hold while holding, so a check can act inside the window → entries.jsonl:21
- Discovery (R1-07, affects run): 13-run-2-michael-sets-desk (harness desk --list) not reproduced: --repeat 10 was 10/10 green, 718 s → entries.jsonl:21
- Discovery (R3-03, affects R3-05, run): To test a main that moved after a milestone's verify, use STUB_MAIN_TOUCH=verify-<m>:<path>: a touch in a coding session is merged into the lane before the verify → entries.jsonl:20
- Discovery (R3-03, affects R3-06): finish now writes the ledger after record_pr: a hung gh in record_pr leaves the run without a ledger copy or runs.jsonl line (reviewer Minor 4, accepted with the plan's order) → entries.jsonl:20
- Discovery (R3-03, affects R3-06): A run whose suite is never green writes neither testcount-source nor testcount-nomatch: the report's tests are ? with no harness-log line saying why (reviewer Minor 5) → entries.jsonl:20
- Discovery (R1-06, affects R1-07, run): Every stub run is M1 (A, B) then M2 (C, after M1): any check on a run's 3/3, M2's tag or its packs can hit R1-04's lane-count race; HARNESS_COUNT_HOLD=1 on that start holds the window every time → entries.jsonl:19
- Discovery (R1-06, affects R1-07, run): pgrep in a check is box-wide (sibling copies, other lanes' suites): match this copy's process by grep -zqF "HARNESS_SCRATCH=$T/" /proc/<pid>/environ (08's init_left) → entries.jsonl:19
- Discovery (R3-02, affects R3-06, run): 13/14-run-2 pin the initializer's lint sentence ending `milestone's size doesn't call for). No output means clean.`: a new lint item goes before the review one → entries.jsonl:18
- Discovery (R3-02, affects R3-06): README/architecture lint lists don't name unit-collision or unreproducible yet: R3-06's docs item → entries.jsonl:18
- Discovery (R3-02, affects R1-07, run): Under this box's load (~21) the full suite took 1237 s and 08-scope and 48-lanes-rebase (a non-fast-forward push to origin main) flaked once each, green on the rerun → entries.jsonl:18
- Discovery (R1-05, affects run): Merging origin/main brought R2 in: its stub-claude.sh header comments conflicted with R1-02's STUB_BARRIER comment. Both are kept; the suite went from 944 to 973 checks. → entries.jsonl:17
- Discovery (R3-01, affects R3-04, R3-06): Minor 8 at HEAD: one rec_commit follows the passes note and the gate, so no run ends between them; the move sets passed=false for an escalated review (its first metrics row turns false) → entries.jsonl:16
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

- tests/lib.sh now holds tended, held (clears vwait-* too), ats and debriefs: a check file must not redefine them differently → entries.jsonl:21

## Lately in the run

- 2026-10-29 18:35 · R3-05 · passes: Two checks, no lib/bin change: 49's sp block runs gc --dry-run with a clean leftover slot (lanes/sp/slot-1) and the merged harness-lane/sp/M1 on origin (one would: line each, both kept; the real gc then removes the slot). 77 starts two merge_milestones M1 at once on one state and clone: one note, one pr merge. Both green at once; each fails when what it guards is broken.; tests 976 → 978; files tests/checks/49-lanes-slots.sh, tests/checks/77-leftovers.sh, tests/fixtures/check-names.txt, CLAUDE.md → entries.jsonl:24
- 2026-10-29 18:33 · verify R1 · passes: All 7 R1 features hold. Suite green (one rerun for 46 flake); --repeat 10 gave 10/10 green on 44, 46, 48, 15, 28, 32, 38, 08; lint exits 0; docs, plan, review and decision present. Note: N2 is now on origin main (count 2), plan line says 1 as of init. → entries.jsonl:23
- 2026-10-29 18:10 · R3-04 · passes: check.sh appends <epoch.µs> <full|subset|cached> <s> to $HARNESS_SCRATCH/check-runs.log; lane.sh stamps around session coding and notes '<id>: suite ran <n>x (<s> s) in the session'. Reviews go to subagents on the session's model ({{MODEL}}, HARNESS_MODEL; prompt.sh fills the feature's). The review gate un-passes before the record flip, row and passes= note. 4 checks.; tests 972 → 976; files lib/check.sh, lib/lane.sh, lib/prompt.sh, prompts/coding.md, tests/stub-claude.sh, … → entries.jsonl:22

## Current rules

- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md

_70 older rules: journal/decisions._
