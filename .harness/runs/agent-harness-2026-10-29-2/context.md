# Context pack for `R1-07`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (R1-06, affects R1-07, run): Every stub run is M1 (A, B) then M2 (C, after M1): any check on a run's 3/3, M2's tag or its packs can hit R1-04's lane-count race; HARNESS_COUNT_HOLD=1 on that start holds the window every time → entries.jsonl:19
- Discovery (R1-06, affects R1-07, run): pgrep in a check is box-wide (sibling copies, other lanes' suites): match this copy's process by grep -zqF "HARNESS_SCRATCH=$T/" /proc/<pid>/environ (08's init_left) → entries.jsonl:19
- Discovery (R1-06, affects R1-07): mem_gate (lib/scope.sh:127-130) checks memory, then stop, every HARNESS_MEM_POLL (1 s in tests): a check that writes both must not let a poll fall between them → entries.jsonl:19
- Discovery (R1-06, affects R1-07): A forced copy built with git archive has no .git: its 'ledger row has harness_version and harness_dirty' fails there, not on the tree → entries.jsonl:19
- Discovery (R3-02, affects R3-06, run): 13/14-run-2 pin the initializer's lint sentence ending `milestone's size doesn't call for). No output means clean.`: a new lint item goes before the review one → entries.jsonl:18
- Discovery (R3-02, affects R1-07, run): Under this box's load (~21) the full suite took 1237 s and 08-scope and 48-lanes-rebase (a non-fast-forward push to origin main) flaked once each, green on the rerun → entries.jsonl:18
- Discovery (R1-05, affects R1-06, R1-07): 15's weekly check and 28 were R1-04's coordinator race, not settle's box-wide pgrep: forced, both end 'no feature left to try' with the lane closing just after. The settle lead for 15 is ruled out. → entries.jsonl:17
- Discovery (R1-05, affects run): Merging origin/main brought R2 in: its stub-claude.sh header comments conflicted with R1-02's STUB_BARRIER comment. Both are kept; the suite went from 944 to 973 checks. → entries.jsonl:17
- Discovery (R3-01, affects R3-02, run): unreproducible flags 3 steps of this run's list (R1-02 step 4 'below 5 s', R3-01 step 3, R3-02 step 3 quoting the examples): expected, reported never applied → entries.jsonl:16
- Discovery (R2, affects run): N2 is on origin main now (grep -c ...-N[12]$ = 2; 645d87e, in R2's HEAD): the R2/R1 plans' 'needs Michael' dependency line is stale → entries.jsonl:15
- Discovery (R1-04, affects R1-05, R1-06, R1-07): HARNESS_COUNT_HOLD=1 (bin/harness passes it) holds the coordinator after its lane count until the lanes exit; logs 'count hold: …' in run.log. Use it to test whether a lanes flaker is the count/end race → entries.jsonl:13
- Discovery (R1-04, affects R1-07): 47-lanes-two (admission at 80 %) was 10/10 green after the fix; its negative sleeps remain for R1-07 to list → entries.jsonl:13
- Discovery (R2-05, affects run): Left by the review (Minor): the resume ignores a stop/lanes-end/deadline (bounded 10m, $1), and a refused resume is not fed to limit_raise → entries.jsonl:11
- Discovery (R1-03, affects R1-04, R1-05, R1-06, R1-07): wait_for <s> eval '<expr>' runs the expr in wait_for's frame: $1/$2 there are 'eval' and the expr; a helper copies its argument to a local first (gone, tended, tgone do) → entries.jsonl:10
- Discovery (R1-03, affects R1-05, R1-07): settle no longer sleeps 0.5: its pgrep pattern also matches $HERE/../bin/harness debrief (the runner's H, before it execs $HH/lib/debrief.sh), so a debrief that hasn't exec'd yet counts as running → entries.jsonl:10
- Discovery (R1-03, affects R1-06, R1-07): the negatives kept as '# sleep-ok: a negative over n polls' are 13:444, 32 (19,20,21,29,32,34), 45:39, 47 (38,51), 69:47 (after a wait_for on the runner's holding line); R1-06 decides whether 32's become counted-poll waits → entries.jsonl:10
- Discovery (R1-03, affects R1-07, run): 13-run-2-michael-sets-desk 'harness desk --list' flakes under the full suite's load (R2-02 and R1-03 each saw it once, green on the rerun); not in the plan's flaker table → entries.jsonl:10
- Discovery (R1-03, affects run): origin/main came with 16 Gotchas lines (memlint red on main itself); this lane dropped the end-reasons line when it merged main → entries.jsonl:10
- Discovery (R1-02, affects run): ## Gotchas holds 14 bullets at most: memlint counts its <!-- --> comment line among the 15 → entries.jsonl:8
- Discovery (R2-01, affects run): 39-memlint-m4 lints this worktree's CLAUDE.md: a 16th Gotchas line turns the suite red; replace a line, never add past 15 → entries.jsonl:4
- Discovery (R1-01, affects run): N2 is not on origin main (1 of N1/N2 merged): an overlap conflict between lanes needs Michael → entries.jsonl:3
- Discovery (init, affects run): N2 (conflict resolution) is not on origin main: N2-02 waits on Michael. Only N1 merged (grep -c harness-merge/...-N[12] = 1). A text conflict between two lanes needs Michael as before; each plan says so in one line. → entries.jsonl:1
- Discovery (init, affects R1): The flaker features (R1-04..06) run `bash tests/run.sh --repeat 10 <file>` directly in the session, never through the suite command: its CHECK_TIMEOUT is the whole suite's. One file's ten copies take minutes under load; the spec caps repeats at 30 min per flaker, then `not reproduced`. → entries.jsonl:1
- Discovery (init, affects run): R2 and R3 both edit lib/record.sh and prompts/coding.md; R2-02 and R3-02 both edit prompts/initializer.md. Whichever merges second takes a re-base verify round; a text conflict needs Michael (no N2). → entries.jsonl:1

## Lately in the run

- 2026-10-29 16:33 · R1-06 · passes: 32, 38 and 08's first `no user systemd` check were R1-04's lane-count race: 10/10 green unforced, red forced on the pre-fix driver. Their runs now start with HARNESS_COUNT_HOLD=1 (red 0/1 before). 08's repeat (7/10) found two test races, fixed: the gatestop run kept at 2 GB (STOP and the memory write raced the gate's poll) and a per-copy init_left for the box-wide pgrep. All 10/10 after.; tests 973 → 973; files tests/checks/32-l5-queue-runner-re.sh, tests/checks/38-run-17-gotchas-and-pack-m3.sh, tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh, docs/plans/2026-10-29-R1-flakes.md, journal/decisions/2026-10-29-lane-count-end-check.md, … → entries.jsonl:19
- 2026-10-29 16:14 · R3-02 · passes: lib/features.mjs: every list/attempts/parked write goes through writeAtomic (<file>.<pid>.tmp + renameSync; namespace import, so grep -c writeFileSync = 1). lint gains unit-collision (LANEU mapping, one finding per colliding milestone) and unreproducible (time bounds, one run's test counts, this run's check.out). initializer.md states counts as commands. 5 checks in 07, 1 in new 77-leftovers.sh.; tests 963 → 969; files lib/features.mjs, prompts/initializer.md, tests/checks/07-step-lint-pure-r3.sh, tests/checks/77-leftovers.sh, tests/fixtures/check-names.txt → entries.jsonl:18
- 2026-10-29 15:41 · R1-05 · passes: Both run flakers are R1-04's lane-count race. Neither reproduced unforced (10/10 green each). Forced with HARNESS_COUNT_HOLD=1 on the pre-fix driver, 28 ended 'no feature left to try' before M2 and 15's weekly run did too. Both runs now start with the hold: red before the fix (0/1), 10/10 after. Plan rows filled; decision updated in place. Merged origin/main.; tests 944 → 973; files tests/checks/15-run-4-same-but-queue-parked-debrief-tmux.sh, tests/checks/28-run-14d-harness-merge.sh, docs/plans/2026-10-29-R1-flakes.md, journal/decisions/2026-10-29-lane-count-end-check.md, tests/stub-claude.sh → entries.jsonl:17

## Current rules

- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
- The coordinator ends a run only when the lane count its opens used saw no lane → journal/decisions/2026-10-29-lane-count-end-check.md

_70 older rules: journal/decisions._
