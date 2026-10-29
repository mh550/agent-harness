# Context pack for `R4-04`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (R4-03, affects R4-04, R4-05): 78's needs_fixture runs (q-*) are runs of proj: the stub runs rm them first, or a stub question of the same text (ASK_TWO's cache one is the fixture default) moves their item forward → entries.jsonl:30
- Discovery (R4-03, affects R4-04): 78 runs four stub runs (qa ASK_TWO, qr ASK+AGAIN+RESOLVE=A, qm1/qm2 ASK=A), ~70 s; R4-04's no-notification check can reuse qa's curl.log instead of a fifth run → entries.jsonl:30
- Discovery (R3-06, affects run): The suite must read nothing under CHECK_KEY_IGNORE paths (34's guard): a merge now skips its re-base on them; copy a spec's shape into tests/fixtures instead → entries.jsonl:27
- Discovery (R3-06, affects run): lib/treekey.mjs --pathspec prints the key's pathspecs; ignored_only (lib/record.sh) uses them and takes only output starting with '.' → entries.jsonl:27
- Discovery (R3-06, affects run): Promote item 'tests/lib.sh now holds tended, held…' still not on R3's branch (R1 not on origin main): left for a session with R1 in → entries.jsonl:27
- Discovery (R3-06, affects run): 40-run-18-test-counts-m5 'a continued run refreshes tests-end' flaked once in a full run (green on the rerun) → entries.jsonl:27
- Discovery (R4-02, affects R4-03, R4-04): needs_fixture question (tests/lib.sh) puts every fixture run under one project proj: an open of the same text in another run moves it forward; give each its own NF_Q=<text> → entries.jsonl:26
- Discovery (R4-02, affects R4-04): A question item counts in harness status NEEDS YOU until R4-04 splits it out; nothing opens one before R4-03 → entries.jsonl:26
- Discovery (R4-01, affects R4-04): status line stays 'NEEDS YOU <n> · harness needs' (53 pins it): with questions it reads 'NEEDS YOU 1 · 3 questions · harness needs' → entries.jsonl:25
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
- Discovery (R3-01, affects R3-02, run): unreproducible flags 3 steps of this run's list (R1-02 step 4 'below 5 s', R3-01 step 3, R3-02 step 3 quoting the examples): expected, reported never applied → entries.jsonl:16
- Discovery (R2, affects run): N2 is on origin main now (grep -c ...-N[12]$ = 2; 645d87e, in R2's HEAD): the R2/R1 plans' 'needs Michael' dependency line is stale → entries.jsonl:15
- Discovery (R2-05, affects run): Left by the review (Minor): the resume ignores a stop/lanes-end/deadline (bounded 10m, $1), and a refused resume is not fed to limit_raise → entries.jsonl:11
- Discovery (R1-03, affects R1-07, run): 13-run-2-michael-sets-desk 'harness desk --list' flakes under the full suite's load (R2-02 and R1-03 each saw it once, green on the rerun); not in the plan's flaker table → entries.jsonl:10
- Discovery (R1-03, affects run): origin/main came with 16 Gotchas lines (memlint red on main itself); this lane dropped the end-reasons line when it merged main → entries.jsonl:10
- Discovery (R1-02, affects run): ## Gotchas holds 14 bullets at most: memlint counts its <!-- --> comment line among the 15 → entries.jsonl:8
- Discovery (R2-01, affects run): 39-memlint-m4 lints this worktree's CLAUDE.md: a 16th Gotchas line turns the suite red; replace a line, never add past 15 → entries.jsonl:4
- Discovery (R1-01, affects run): N2 is not on origin main (1 of N1/N2 merged): an overlap conflict between lanes needs Michael → entries.jsonl:3
- Discovery (init, affects run): N2 (conflict resolution) is not on origin main: N2-02 waits on Michael. Only N1 merged (grep -c harness-merge/...-N[12] = 1). A text conflict between two lanes needs Michael as before; each plan says so in one line. → entries.jsonl:1
- Discovery (init, affects run): R2 and R3 both edit lib/record.sh and prompts/coding.md; R2-02 and R3-02 both edit prompts/initializer.md. Whichever merges second takes a re-base verify round; a text conflict needs Michael (no N2). → entries.jsonl:1

## What it builds on

- 2026-10-29 19:22 · R4-02 · passes: needs.mjs has the question reason: questionKey (fill and Files: lines cut, folded, 80 code points), open refreshes in the run (exit 3) or moves an open item forward from a sibling run (seen +1, asked_in, old in its done/), a warn card, the sweep resolves on a later entry's resolved (entries.mjs resolvedBy, shared with pack).; tests 976 → 984; files lib/needs.mjs, lib/entries.mjs, tests/checks/78-needs-questions.sh, tests/lib.sh, tests/checks/58-needs-record.sh, … → entries.jsonl:26

## Lately in the run

- 2026-10-29 19:56 · R4-03 · passes: journal_ (lib/record.sh) now opens one question item per question of the entry it ingests (questions_: the filled text, asker, line, feature for coding), notes '<id>: <n> question(s) for Michael recorded (harness needs)' and sweeps at once when the entry has resolved. Stub learns STUB_ASK_TWO and STUB_ASK_AGAIN. 78 gains 5 stub-run checks.; tests 984 → 989; files lib/record.sh, tests/stub-claude.sh, tests/checks/78-needs-questions.sh, tests/fixtures/check-names.txt → entries.jsonl:30
- 2026-10-29 19:43 · verify R3 · not yet: Full suite RED: 39-memlint-m4 fails (memlint on this worktree prints `CLAUDE.md:80 gotchas: 16 lines, over 15`; the merge resolve kept both Gotchas lines). Every feature ends on the suite step, so all six fail. Other steps spot-checked hold. → entries.jsonl:29

_1 items left out at 8192 bytes: entries.jsonl has them all._
