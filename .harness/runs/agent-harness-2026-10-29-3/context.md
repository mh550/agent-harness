# Context pack for `S2-02`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (S2-01, affects S2-02, S2-04): tests/run.sh matches check names by substring: a map name must be the full stem (75-suite-tools, not 75: 75-merge-sorted shares it) → entries.jsonl:8
- Discovery (S1-05, affects S2, run): run_init now writes init-failed in the lane dir (driver: state dir) while an init fails; the next run_init drops the tree's red-<key> before its suite → entries.jsonl:6
- Discovery (S1-05, affects S2, run): the cached red answer no longer prints the stored RED line verbatim: its `— last lines of …:` tail is replaced with check-<key>.out's or `its output is gone from scratch` → entries.jsonl:6
- Discovery (S1-05, affects S2, run): suite_length reads every green marker (cwd tree's, then newest) before any red one → entries.jsonl:6
- Discovery (S1-04, affects S1-05, run): the retry's init output is best read from its session prompt ($STATE/logs/<nn>-<id>.prompt.md, ## Init output): init.out in scratch is overwritten by every later run_init, KEEP_SCRATCH or not → entries.jsonl:5
- Discovery (S1-03, affects S1-05, run): 10-harness-eval-run-e2 flaked (probe prompt vs prompt-coding.md): its noinit() kept S1-02s `Suite: last full run <s> s` line, which differs between renders; it now drops it like Clock. Any check comparing two rendered prompts below # This session must too → entries.jsonl:4
- Discovery (init, affects run): the stub project's suite in tests/lib.sh is `test ! -f BROKEN`, which counts nothing: the stub-run checks of S1-04 and S2-05 set CHECK_CMD in the run's config to a counting, argument-recording suite as 73-check-rerun.sh's rr-suite.sh → entries.jsonl:1
- Discovery (init, affects run): rendered prompts live in the run's state dir as prompt-<kind>.md (08-scope-sh checks grep $HARNESS_STATE/proj/<run>/prompt-coding.md) and per session under logs/*-<id>.prompt.md: 79-suite-length.sh reads them there → entries.jsonl:1
- Discovery (init, affects run): the spec's `prompt()` is lib/prompt.sh's prompt_render (prompt_vars/prompt_env/prompt_render); HARNESS_SUITE_LENGTH belongs with the other per-render variables set on the render line, and {{SUITE_LENGTH}} in parts/run.md is under {{SECTIONS}} → entries.jsonl:1
- Discovery (init, affects run): the init suite was green after a rerun: 47-lanes-two flaked (one flakes.jsonl row); a red there in a session is a known flake, not necessarily the session's → entries.jsonl:1
- Discovery (init, affects run): no .harness/runs/agent-harness-2026-10-29-2 directory is in this tree (only its ledger line): the 10-29-2 numbers the spec cites are the spec's, not re-derivable here → entries.jsonl:1

## What it builds on

- 2026-10-30 01:19 · S2-01 · passes: Wrote docs/plans/2026-10-30-S2-partial-key.md: treekey.mjs's exported functions and --partial (plus a --names mode, default), parseMap's drops, the part-<reduced> sidecar, check.sh's partial path as a numbered table (rows 0-11 + 4a), what a partial green/red writes, the lint's rules and allow-list with today's finds, the checks, decision and S3 line. No code changed.; tests 1044 → 1044; files docs/plans/2026-10-30-S2-partial-key.md → entries.jsonl:8

## Lately in the run

- 2026-10-30 01:02 · verify S1 · passes: All five S1 features hold: full suite green (1044 tests), subsets 34/39/73/79/80 re-run green, greps and docs confirmed. Note: S1-04 step 3 literal diff scope also includes S1-05 review fix I1. → entries.jsonl:7
- 2026-10-30 00:46 · S1-05 · passes: S1 review: 0 Critical, 3 Important, 5 Minor. Fixed, each red first: I1 run_init keeps no red-<key> around a failed init; I2 the cached red shows check-<key>.out or says it is gone; I3 suite_length reads every green wall before a red; M1 no red cached for codes ≥128; M2 atomic marker writes; M3 green_count in record.sh; M4. Docs: architecture §3/§4/§7/prompt, README.; tests 1039 → 1044; files lib/check.sh, lib/record.sh, lib/prompt.sh, tests/checks/79-suite-length.sh, tests/checks/80-red-marker.sh, … → entries.jsonl:6

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
