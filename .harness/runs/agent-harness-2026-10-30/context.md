# Context pack for `F1-04`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (F1-03, affects F1-04, F1-06): The coordinator's opens counted live pids, so a lane exited after the reap freed its slot and admit count before its close (and any lanes-end reason) was noted; fixed with lanes_held (decisions/2026-10-30-opens-wait-for-reap). The same window exists at MAX_LANES=1 between reap and count: a lead for 46's post-R1 sightings → entries.jsonl:4
- Discovery (F1-03, affects F1-04, F1-06): HARNESS_COUNT_HOLD=1 parks the coordinator after its count until the counted lanes exit, so a check counting notes over polls on that run sees one poll: hold a run of its own → entries.jsonl:4
- Discovery (F1-03, affects run): The Gotchas section of CLAUDE.md is full: memlint counts its comment line, so 14 facts is the limit; a new one replaces one → entries.jsonl:4
- Discovery (F1-02, affects run): bash reads a script as it runs: never edit a check file while a run or --repeat of it goes on → entries.jsonl:3
- Discovery (F1-01, affects F1-02, F1-03, F1-04): The 10-29 run's harness-log.md has no flaky: line; sightings are in 10-29-2 (11 lines) and 10-29-3 (5 lines) → entries.jsonl:2
- Discovery (init, affects run): The run's spec docs/specs/2026-10-30-suite-cpu-and-flakes.md exists on no local or remote branch (git fetch --all, every ref checked); the only 2026-10-30 spec, suite-time.md (S1, S2), was built and merged by run agent-harness-2026-10-29-3 (checks 79-82). The list is planned from docs/plans/2026-10-29-suite-time.md §2 fixes, findings-and-research/2026-10-30-suite-load-curve.md and the three 10-29 run records' flaky: lines. → entries.jsonl:1
- Discovery (init, affects run): Flaker sightings since R1 (harness-log.md flaky: lines of the 10-29, 10-29-2, 10-29-3 records plus the load curve's FAIL lines): 08 five rows, 47 three, 46 three, 13 three, 28 two, 52 two, 53 one, 32/74/10/48 one each, one `whole suite` rerun (805 s) whose cause is the runner's conformance after a stopped file. → entries.jsonl:1
- Discovery (init, affects run): The suite is 1080 checks and 817 s at init on an idle box with TEST_JOBS=4; a session's full run needs a background call with a timeout of at least twice that, as the prompt's Suite line says. → entries.jsonl:1

## What it builds on

- 2026-10-30 17:09 · F1-01 · passes: Wrote docs/plans/2026-10-30-F1-flakes.md: provenance (named spec on no branch, flakes half only, CPU fixes 6-7 wait), a 12-row flaker table with sightings, R1's method, the CPU-time default for the 52/53 timing checks, the tests/run.sh whole-suite rerun mechanism and its default fix, what is left out, shared docs and the decision slug. No code changed.; tests 1080 → 1080; files docs/plans/2026-10-30-F1-flakes.md → entries.jsonl:2

## Lately in the run

- 2026-10-30 19:02 · F1-03 · passes: Reproduced 47 (9/10: M2's lane opened in M1's slot before M1's close was noted). Fixed in lib/driver.sh: the opens stop for the poll while a lane has exited unreaped (lanes_held), and the end check counts held lanes. New check on its own HARNESS_COUNT_HOLD run (uh), red then green. 46 and 48 not reproduced (10/10). Decision opens-wait-for-reap.; tests 1080 → 1081; files lib/driver.sh, tests/checks/47-lanes-two.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-30-opens-wait-for-reap.md, docs/plans/2026-10-30-F1-flakes.md, … → entries.jsonl:4
- 2026-10-30 17:47 · F1-02 · passes: 52/53/28 reproduced with --repeat 10: all 10/10 green (not reproduced). 52 and 53's best-of-3 checks now bound CPU time (user+sys, bash time) under 1000 ms plus the same call's wall under 5000 ms (a stall costs no CPU); renamed. 28 needs no fix: its sightings predate R1-05's lane-count fix. Plan rows filled.; tests 1080 → 1080; files tests/checks/52-status-json.sh, tests/checks/53-status-view.sh, tests/fixtures/check-names.txt, docs/plans/2026-10-30-F1-flakes.md → entries.jsonl:3

## Current rules

- The suite's length in every prompt: a green marker's `wall` line, and a timeout rule → journal/decisions/2026-10-30-suite-length-in-prompt.md
- A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing → journal/decisions/2026-10-30-red-marker.md
- A mapped path's change runs only its readers: `CHECK_KEY_MAP`, the `part-<key>` sidecar, the partial run, the lint → journal/decisions/2026-10-30-partial-key.md
- The coordinator opens no lane while a lane that exited is not reaped yet → journal/decisions/2026-10-30-opens-wait-for-reap.md
- The lane guard reverts against the lane's merge-base with main, in the index only → journal/decisions/2026-10-30-lane-guard-base.md
- The suite waits on a condition or a barrier, never on the clock; a flake is reproduced with --repeat and fixed at its cause → journal/decisions/2026-10-29-tests-wait-not-sleep.md
- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
- Questions wait in `harness needs` until answered: one item per question, moved forward, no push → journal/decisions/2026-10-29-questions-wait.md
- Lanes leftovers: atomic list writes, a record-only main, the finish order, two lint rules, two checks, the suite-ran note → journal/decisions/2026-10-29-lanes-leftovers.md
- The coordinator ends a run only when the lane count its opens used saw no lane → journal/decisions/2026-10-29-lane-count-end-check.md
- Entries that survive: the session checks its own, a long summary is cut and kept, one resume for a missing one → journal/decisions/2026-10-29-entries-survive.md
- A parked run's continue advice names another live run of its project and gives Michael the choice → journal/decisions/2026-10-29-continue-advice-busy-project.md

_68 older rules: journal/decisions._
