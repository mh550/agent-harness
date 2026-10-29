# Context pack for `R4-03`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (R4-02, affects R4-03, R4-04): needs_fixture question (tests/lib.sh) puts every fixture run under one project proj: an open of the same text in another run moves it forward; give each its own NF_Q=<text> → entries.jsonl:26
- Discovery (R4-02, affects R4-03): journal_ must pass the question as entries.jsonl stores it (filled): the sweep compares card.question.text with resolved items as pack does, and a pack-cut resolved copied from the filled words would not match the unfilled text → entries.jsonl:26
- Discovery (R4-02, affects R4-03): An open with no line= is never resolved by the sweep (no later to tell): journal_ must pass line=<entries.jsonl line> → entries.jsonl:26
- Discovery (R4-01, affects R4-03): In a default stub run only A (verify un-passes it) and C (BROKEN first) get a second coding session: STUB_RESOLVE=A, not B, resolves STUB_ASK=A's question after STUB_ASK_AGAIN=B → entries.jsonl:25
- Discovery (R4-01, affects R4-02, R4-03): entries.jsonl questions carry the fill ' Files (harness, from the session): <abs paths>': a key over the raw first 80 characters would differ per run for a short question; questionKey cuts it (entries.mjs unfilled, to export) → entries.jsonl:25
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

## Lately in the run

- 2026-10-29 19:22 · R4-02 · passes: needs.mjs has the question reason: questionKey (fill and Files: lines cut, folded, 80 code points), open refreshes in the run (exit 3) or moves an open item forward from a sibling run (seen +1, asked_in, old in its done/), a warn card, the sweep resolves on a later entry's resolved (entries.mjs resolvedBy, shared with pack).; tests 976 → 984; files lib/needs.mjs, lib/entries.mjs, tests/checks/78-needs-questions.sh, tests/lib.sh, tests/checks/58-needs-record.sh, … → entries.jsonl:26
- 2026-10-29 18:52 · R4-01 · passes: Wrote docs/plans/2026-10-29-R4-questions.md: the question reason, a key that drops the harness's Files fill (worktree paths differ per run), refresh, the move forward through sibling state dirs, card and sweep rule (resolvedBy shared with pack), journal_'s questions_ after the ingest, readers, the skill step, 17 check names, needs_fixture question, STUB_ASK_TWO/AGAIN. No code changed.; tests 976 → 976; files docs/plans/2026-10-29-R4-questions.md → entries.jsonl:25
- 2026-10-29 18:35 · R3-05 · passes: Two checks, no lib/bin change: 49's sp block runs gc --dry-run with a clean leftover slot (lanes/sp/slot-1) and the merged harness-lane/sp/M1 on origin (one would: line each, both kept; the real gc then removes the slot). 77 starts two merge_milestones M1 at once on one state and clone: one note, one pr merge. Both green at once; each fails when what it guards is broken.; tests 976 → 978; files tests/checks/49-lanes-slots.sh, tests/checks/77-leftovers.sh, tests/fixtures/check-names.txt, CLAUDE.md → entries.jsonl:24

## Current rules

- The suite waits on a condition or a barrier, never on the clock; a flake is reproduced with --repeat and fixed at its cause → journal/decisions/2026-10-29-tests-wait-not-sleep.md
- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
- The coordinator ends a run only when the lane count its opens used saw no lane → journal/decisions/2026-10-29-lane-count-end-check.md

_70 older rules: journal/decisions._
