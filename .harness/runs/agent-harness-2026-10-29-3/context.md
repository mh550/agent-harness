# Context pack for `S1-02`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (S1-01, affects S1-02): two existing checks cat a whole green marker and go red once it has a wall line: 08-scope-sh…:525 and 73-check-rerun.sh:34; switch them to sed -n 1p → entries.jsonl:2
- Discovery (S1-01, affects S1-02): $(cat) of a marker with an empty line 1 (the stub's test ! -f BROKEN suite prints no count) gives \nwall 0, which skips the testcount fallback and writes \nwall into tests-start: the real reason for read -r → entries.jsonl:2
- Discovery (S1-01, affects S1-02): the stub-run markers' walls are all 0: 79 pins suite_length by rewriting markers and rendering with the command form lib/prompt.sh <state> coding <id> → entries.jsonl:2
- Discovery (S1-01, affects S1-02): a planted one-line green before the first suite: a run.env INIT_CMD writes it to $HARNESS_CHECK_CACHE/green-<treekey> (the init runs before run_init takes the key; load_config exports the cache) → entries.jsonl:2
- Discovery (init, affects run): the stub project's suite in tests/lib.sh is `test ! -f BROKEN`, which counts nothing: the stub-run checks of S1-04 and S2-05 set CHECK_CMD in the run's config to a counting, argument-recording suite as 73-check-rerun.sh's rr-suite.sh → entries.jsonl:1
- Discovery (init, affects run): rendered prompts live in the run's state dir as prompt-<kind>.md (08-scope-sh checks grep $HARNESS_STATE/proj/<run>/prompt-coding.md) and per session under logs/*-<id>.prompt.md: 79-suite-length.sh reads them there → entries.jsonl:1
- Discovery (init, affects run): the spec's `prompt()` is lib/prompt.sh's prompt_render (prompt_vars/prompt_env/prompt_render); HARNESS_SUITE_LENGTH belongs with the other per-render variables set on the render line, and {{SUITE_LENGTH}} in parts/run.md is under {{SECTIONS}} → entries.jsonl:1
- Discovery (init, affects run): the init suite was green after a rerun: 47-lanes-two flaked (one flakes.jsonl row); a red there in a session is a known flake, not necessarily the session's → entries.jsonl:1
- Discovery (init, affects run): no .harness/runs/agent-harness-2026-10-29-2 directory is in this tree (only its ledger line): the 10-29-2 numbers the spec cites are the spec's, not re-derivable here → entries.jsonl:1

## What it builds on

- 2026-10-29 21:53 · S1-01 · passes: Wrote docs/plans/2026-10-30-S1-suite-time.md: the three marker readers (check.sh:67, run_init record.sh:461, tests_end record.sh:488) and their read -r, the wall line, suite_length in prompt_render, the red-<key> lines and placement, the driver's fresh rm, the checks of 34/79/80 with a counting run.env CHECK_CMD and STUB_PLANT_MARKERS, both decision files. No code changed.; tests 1016 → 1016; files docs/plans/2026-10-30-S1-suite-time.md → entries.jsonl:2

## Lately in the run

- 2026-10-29 21:47 · init · passes: 11 features: S1 5 (plan, fix 3 the wall line and prompt Suite line, fix 2 red-<key> in check.sh, fix 2 in the driver, review+docs), S2 6 (plan, CHECK_KEY_MAP and treekey --partial, the partial run in check.sh, the lint, the driver and verify invariant, review+docs). S2 after S1, in series, as the spec says.; files .harness/runs/agent-harness-2026-10-29-3/feature_list.json → entries.jsonl:1

## Current rules

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
- A plain start or continue queues behind a live run of its project; overlaps are named, never held → journal/decisions/2026-10-27-same-project-starts.md
- The review gate: a milestone review's model by its measured diff, one Opus round after a Sonnet finding → journal/decisions/2026-10-27-review-gate.md

_63 older rules: journal/decisions._
