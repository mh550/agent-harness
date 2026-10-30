# Context pack for `R3-03`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Dead end (R3-03, 11-R3-03): STUB_MAIN_TOUCH=A:.harness/runs/other/x.md (step 1 as written) — the lane merges main in before its verify (sync_main), so merge_one never sees a moved main: green at HEAD. verify-M1:<path> lands it after the verify and is red at HEAD (M1 re-based) → entries.jsonl:20
- Verify R3 found (R3-03 step 5): ran bash tests/run.sh (init full run + rerun of 39-memlint-m4); node lib/memlint.mjs .; saw 39-memlint-m4: 18/19, FAIL store lookup check; memlint prints CLAUDE.md:80 gotchas: 16 lines, over 15 → entries.jsonl:29
- 2026-10-29 16:52 · R3-03 · passes: merge_one: ignored_only lets a main moved only in cache-ignored paths merge as verified, no re-base, noted once per main. finish: ledger and scratch_done after record_pr, plus a 'ledger notes' commit. run_init pins tests-start and testcount-source only from a green suite, read from the tree's marker or check-<key>.out (never a stale check.out). STUB_FIX_BROKEN; 3 checks in 77-leftovers.; tests 969 → 972; files lib/record.sh, lib/driver.sh, tests/stub-claude.sh, tests/checks/77-leftovers.sh, tests/fixtures/check-names.txt → entries.jsonl:20

## Discoveries for this feature

- Discovery (R3-01, affects run): A resolve that keeps both sides' Gotchas lines can push the section past 15 (the comment line counts): drop one in the resolve, or 39-memlint-m4 goes red → entries.jsonl:31
- Discovery (R3-06, affects run): The suite must read nothing under CHECK_KEY_IGNORE paths (34's guard): a merge now skips its re-base on them; copy a spec's shape into tests/fixtures instead → entries.jsonl:27
- Discovery (R3-06, affects run): lib/treekey.mjs --pathspec prints the key's pathspecs; ignored_only (lib/record.sh) uses them and takes only output starting with '.' → entries.jsonl:27
- Discovery (R3-06, affects run): Promote item 'tests/lib.sh now holds tended, held…' still not on R3's branch (R1 not on origin main): left for a session with R1 in → entries.jsonl:27
- Discovery (R3-06, affects run): 40-run-18-test-counts-m5 'a continued run refreshes tests-end' flaked once in a full run (green on the rerun) → entries.jsonl:27
- Discovery (R3-05, affects run): Promote item 'tests/lib.sh now holds tended, held…' does not hold on R3's branch (R1-07's lib.sh is not merged here; 47/48/49/76/77-resolve define held and ats themselves): left for a session on a branch with R1 in → entries.jsonl:24
- Discovery (R3-04, affects R3-06, run): 08-scope flaked twice in this session's full runs (gatestop memory gate; M2's lane never started, 2/3 passing): R1-06's fixes (HARNESS_COUNT_HOLD, gatestop at 2 GB) are not on this lane's base → entries.jsonl:22
- Discovery (R1-07, affects run): The coordinator's opens skip a milestone whose lanes/<m>/pid is still there (exited, unreaped); HARNESS_COUNT_HOLD leaves state/count-hold while holding, so a check can act inside the window → entries.jsonl:21
- Discovery (R1-07, affects run): 13-run-2-michael-sets-desk (harness desk --list) not reproduced: --repeat 10 was 10/10 green, 718 s → entries.jsonl:21
- Discovery (R3-03, affects R3-05, run): To test a main that moved after a milestone's verify, use STUB_MAIN_TOUCH=verify-<m>:<path>: a touch in a coding session is merged into the lane before the verify → entries.jsonl:20
- Discovery (R1-06, affects R1-07, run): Every stub run is M1 (A, B) then M2 (C, after M1): any check on a run's 3/3, M2's tag or its packs can hit R1-04's lane-count race; HARNESS_COUNT_HOLD=1 on that start holds the window every time → entries.jsonl:19
- Discovery (R1-06, affects R1-07, run): pgrep in a check is box-wide (sibling copies, other lanes' suites): match this copy's process by grep -zqF "HARNESS_SCRATCH=$T/" /proc/<pid>/environ (08's init_left) → entries.jsonl:19
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

## What it builds on

- 2026-10-29 20:18 · R3-01 · passes: Verify R3 was red only on 39-memlint-m4: the R3 resolve kept both its {{X}} line and main's stub --resume line, so Gotchas had 16 lines. Dropped the stub --resume line (76-entries-survive checks that shape); memlint prints nothing. The plan file's steps 1-4 hold (spot-checked: sections, Minor 8 quote, unreproducible examples, N2 = 2 on origin main).; tests 993 → 993; files CLAUDE.md → entries.jsonl:31

_2 items left out at 8192 bytes: entries.jsonl has them all._
