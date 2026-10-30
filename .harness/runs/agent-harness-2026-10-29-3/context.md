# Context pack for `S1-05`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (S1-04, affects S1-05, run): the retry's init output is best read from its session prompt ($STATE/logs/<nn>-<id>.prompt.md, ## Init output): init.out in scratch is overwritten by every later run_init, KEEP_SCRATCH or not → entries.jsonl:5
- Discovery (S1-04, affects S1-05): step 1 already held after S1-03 (the retry's run_init answers from the marker with no driver change); only the verify invariant needed the record.sh line → entries.jsonl:5
- Discovery (S1-03, affects S1-04, S1-05): a green run removing a planted red-<key> is only reachable when the marker appears mid-run (the lookup answers first): 80's `plant` mode has the stub suite write it → entries.jsonl:4
- Discovery (S1-03, affects S1-04, S1-05): 74-flakes-run's fe now makes C's red an `exit 124` (a timeout, never cached) so finish's suite runs; 08's ck() rm's red-* before each call. A stub run whose session leaves BROKEN now gets a cached red at the retry's run_init: S1-04's retry check sees it → entries.jsonl:4
- Discovery (S1-03, affects S1-05, run): 10-harness-eval-run-e2 flaked (probe prompt vs prompt-coding.md): its noinit() kept S1-02s `Suite: last full run <s> s` line, which differs between renders; it now drops it like Clock. Any check comparing two rendered prompts below # This session must too → entries.jsonl:4
- Discovery (S1-02, affects S1-03, S1-04, S1-05): The wall is rendered as `Suite: last full run <s> s: …` under # This session of coding/initializer/verify/resolve; run.md's Suite line ends `its last full run is under *This session*)`. S1-03..05 grep that line, not run.md's. → entries.jsonl:3
- Discovery (S1-02, affects S1-03, S1-05): check.sh: after a whole-suite rerun (a red with no HARNESS_FAILED names) the marker's wall is the rerun's seconds; after a named-files rerun it stays the first run's. → entries.jsonl:3
- Discovery (S1-02, affects S1-05): The command form (lib/prompt.sh <state> coding <id>) keys suite_length on $WT, the record worktree, not the lane's slot, so it can show a different wall than the lane's session got (reviewer finding, left as is: the command form reads CLAUDE.md there too). → entries.jsonl:3
- Discovery (init, affects run): the stub project's suite in tests/lib.sh is `test ! -f BROKEN`, which counts nothing: the stub-run checks of S1-04 and S2-05 set CHECK_CMD in the run's config to a counting, argument-recording suite as 73-check-rerun.sh's rr-suite.sh → entries.jsonl:1
- Discovery (init, affects run): rendered prompts live in the run's state dir as prompt-<kind>.md (08-scope-sh checks grep $HARNESS_STATE/proj/<run>/prompt-coding.md) and per session under logs/*-<id>.prompt.md: 79-suite-length.sh reads them there → entries.jsonl:1
- Discovery (init, affects run): the spec's `prompt()` is lib/prompt.sh's prompt_render (prompt_vars/prompt_env/prompt_render); HARNESS_SUITE_LENGTH belongs with the other per-render variables set on the render line, and {{SUITE_LENGTH}} in parts/run.md is under {{SECTIONS}} → entries.jsonl:1
- Discovery (init, affects run): the init suite was green after a rerun: 47-lanes-two flaked (one flakes.jsonl row); a red there in a session is a known flake, not necessarily the session's → entries.jsonl:1
- Discovery (init, affects run): no .harness/runs/agent-harness-2026-10-29-2 directory is in this tree (only its ledger line): the 10-29-2 numbers the spec cites are the spec's, not re-derivable here → entries.jsonl:1

## What it builds on

- 2026-10-30 00:03 · S1-04 · passes: run_init fresh removes red-<key> beside green-<key> (lib/record.sh, one line), so verify's tree always runs in full. 80-red-marker gains 3 stub-run checks with a counting CHECK_CMD: the retry's init is the cached red (2 suite calls on the red tree), and STUB_PLANT_MARKERS (new stub hook) proves verify clears both markers. Decision red-marker gains the driver bullet.; tests 1036 → 1039; files lib/record.sh, tests/checks/80-red-marker.sh, tests/stub-claude.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-30-red-marker.md → entries.jsonl:5

## Lately in the run

- 2026-10-29 23:42 · S1-03 · passes: check.sh full form writes red-<key> (rc, HARNESS_FAILED names, wall, RED line) after a red where both runs were `exit <rc> after`, answers the next full call on that tree from it, removes it on green; subsets read none. New 80-red-marker (8 checks); 08, 74 adapted; 10-e2 drops S1-02s wall line from its prompt compare; decisions/2026-10-30-red-marker.; tests 1028 → 1036; files lib/check.sh, tests/checks/80-red-marker.sh, tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh, tests/checks/74-flakes-run.sh, tests/fixtures/check-names.txt, … → entries.jsonl:4
- 2026-10-29 22:50 · S1-02 · passes: green-<key> is two lines (count, wall <s>); check.sh/run_init/tests_end read line 1 with read -r; prompt.sh suite_length gives SUITE_LENGTH. Deviation (default): the wall line sits under # This session in coding/initializer/verify/resolve, not run.md's Suite line (that broke 08's prefix check: walls 0 vs 1 s); run.md points there. A whole-suite rerun sets the wall. Rule, CLAUDE.md, decision.; tests 1016 → 1028; files lib/check.sh, lib/record.sh, lib/prompt.sh, prompts/parts/run.md, prompts/coding.md, … → entries.jsonl:3

## Current rules

- The suite's length in every prompt: a green marker's `wall` line, and a timeout rule → journal/decisions/2026-10-30-suite-length-in-prompt.md
- A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing → journal/decisions/2026-10-30-red-marker.md
- The suite waits on a condition or a barrier, never on the clock; a flake is reproduced with --repeat and fixed at its cause → journal/decisions/2026-10-29-tests-wait-not-sleep.md
- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
- Questions wait in `harness needs` until answered: one item per question, moved forward, no push → journal/decisions/2026-10-29-questions-wait.md
- Lanes leftovers: atomic list writes, a record-only main, the finish order, two lint rules, two checks, the suite-ran note → journal/decisions/2026-10-29-lanes-leftovers.md
- The coordinator ends a run only when the lane count its opens used saw no lane → journal/decisions/2026-10-29-lane-count-end-check.md
- Entries that survive: the session checks its own, a long summary is cut and kept, one resume for a missing one → journal/decisions/2026-10-29-entries-survive.md
- A parked run's continue advice names another live run of its project and gives Michael the choice → journal/decisions/2026-10-29-continue-advice-busy-project.md
- Merge conflicts resolved without Michael: a sorted merge for lists first, then a resolve session, verified → journal/decisions/2026-10-29-conflict-resolution.md
- This repo's suite gets a 25-minute check timeout; TEST_JOBS stays at its default → journal/decisions/2026-10-29-check-timeout-25m.md
- `harness show`: where a run's work is, from local refs, one change counted once → journal/decisions/2026-10-28-show.md

_65 older rules: journal/decisions._
