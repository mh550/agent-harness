# Context pack for `F1-02`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (F1-01, affects F1-02): The load curve's best-of-3 walls for 53/52: 274-326 ms idle, 443-474 ms at 8 jobs solo, 487-556 ms at 4 paired, 972-1367 ms only at 8 paired (lc-*.out 'best of 3:' lines) → entries.jsonl:2
- Discovery (F1-01, affects F1-02, F1-03, F1-04): The 10-29 run's harness-log.md has no flaky: line; sightings are in 10-29-2 (11 lines) and 10-29-3 (5 lines) → entries.jsonl:2
- Discovery (init, affects run): The run's spec docs/specs/2026-10-30-suite-cpu-and-flakes.md exists on no local or remote branch (git fetch --all, every ref checked); the only 2026-10-30 spec, suite-time.md (S1, S2), was built and merged by run agent-harness-2026-10-29-3 (checks 79-82). The list is planned from docs/plans/2026-10-29-suite-time.md §2 fixes, findings-and-research/2026-10-30-suite-load-curve.md and the three 10-29 run records' flaky: lines. → entries.jsonl:1
- Discovery (init, affects run): Flaker sightings since R1 (harness-log.md flaky: lines of the 10-29, 10-29-2, 10-29-3 records plus the load curve's FAIL lines): 08 five rows, 47 three, 46 three, 13 three, 28 two, 52 two, 53 one, 32/74/10/48 one each, one `whole suite` rerun (805 s) whose cause is the runner's conformance after a stopped file. → entries.jsonl:1
- Discovery (init, affects run): The suite is 1080 checks and 817 s at init on an idle box with TEST_JOBS=4; a session's full run needs a background call with a timeout of at least twice that, as the prompt's Suite line says. → entries.jsonl:1

## What it builds on

- 2026-10-30 17:09 · F1-01 · passes: Wrote docs/plans/2026-10-30-F1-flakes.md: provenance (named spec on no branch, flakes half only, CPU fixes 6-7 wait), a 12-row flaker table with sightings, R1's method, the CPU-time default for the 52/53 timing checks, the tests/run.sh whole-suite rerun mechanism and its default fix, what is left out, shared docs and the decision slug. No code changed.; tests 1080 → 1080; files docs/plans/2026-10-30-F1-flakes.md → entries.jsonl:2

## Lately in the run

- 2026-10-30 17:05 · init · passes: 6 features: F1 6 (1 plan, 4 build, 1 review): the flakes half of the run's title, planned from the plan's fixes and the run records because the named spec docs/specs/2026-10-30-suite-cpu-and-flakes.md is on no branch; the CPU half (plan fixes 6 and 7) waits for the spec. → entries.jsonl:1

## Current rules

- The suite's length in every prompt: a green marker's `wall` line, and a timeout rule → journal/decisions/2026-10-30-suite-length-in-prompt.md
- A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing → journal/decisions/2026-10-30-red-marker.md
- A mapped path's change runs only its readers: `CHECK_KEY_MAP`, the `part-<key>` sidecar, the partial run, the lint → journal/decisions/2026-10-30-partial-key.md
- The lane guard reverts against the lane's merge-base with main, in the index only → journal/decisions/2026-10-30-lane-guard-base.md
- The suite waits on a condition or a barrier, never on the clock; a flake is reproduced with --repeat and fixed at its cause → journal/decisions/2026-10-29-tests-wait-not-sleep.md
- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
- Questions wait in `harness needs` until answered: one item per question, moved forward, no push → journal/decisions/2026-10-29-questions-wait.md
- Lanes leftovers: atomic list writes, a record-only main, the finish order, two lint rules, two checks, the suite-ran note → journal/decisions/2026-10-29-lanes-leftovers.md
- The coordinator ends a run only when the lane count its opens used saw no lane → journal/decisions/2026-10-29-lane-count-end-check.md
- Entries that survive: the session checks its own, a long summary is cut and kept, one resume for a missing one → journal/decisions/2026-10-29-entries-survive.md
- A parked run's continue advice names another live run of its project and gives Michael the choice → journal/decisions/2026-10-29-continue-advice-busy-project.md
- Merge conflicts resolved without Michael: a sorted merge for lists first, then a resolve session, verified → journal/decisions/2026-10-29-conflict-resolution.md

_67 older rules: journal/decisions._
