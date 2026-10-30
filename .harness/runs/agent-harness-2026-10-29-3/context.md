# Context pack for `S2-05`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (S2-04, affects S2-05, run): this repo's map grew 79-suite-length, so the exported HARNESS_CHECK_KEY_MAP of a run started before this merge differs from the tree's: row 4a runs those trees in full until the driver reloads → entries.jsonl:11
- Discovery (S2-03, affects S2-05, S2-06): until S2-05's run_init fresh also removes part-<reduced>, a verify or rebase check on a tree differing from its reference in CLAUDE.md alone runs a partial: S2 must not merge without S2-05 → entries.jsonl:10
- Discovery (S2-02, affects S2-03, S2-05): treekey.mjs's bare call never parses HARNESS_CHECK_KEY_MAP (no stderr); only --partial and --names print the dropped-entry lines → entries.jsonl:9
- Discovery (S2-01, affects S2-05): The verify's own full green rewrites part-<reduced>, so S2-05 step 2's 'no part- sidecar afterwards' is read as: its line 1 is the verified tree's key. S2-05 needs a new stub hook STUB_GOTCHA_ONLY=<id> (a pass whose only change is the Gotchas line) → entries.jsonl:8
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

- 2026-10-30 03:05 · S2-04 · passes: 82-key-map-lint: keymaplint (node in the check file) with rules (a)/(b), widened root expressions, file-wide aliases and six allowed forms, each with its why; fixtures in tests/fixtures/key-map-lint/. Map now CLAUDE.md:39-memlint-m4:37-memory-prompts-m2:79-suite-length; 36, 75 and 81:56 rewritten instead of joined. Decision 2026-10-30-partial-key written; S3 Updated line. 82: 6 checks.; tests 1065 → 1071; files tests/checks/82-key-map-lint.sh, tests/fixtures/key-map-lint/, .harness/config.sh, tests/checks/36-run-16-retro-backlog.sh, tests/checks/75-suite-tools.sh, … → entries.jsonl:11

## Lately in the run

- 2026-10-30 02:29 · S2-03 · passes: check.sh's full form: one treekey --partial call; a green full run writes part-<reduced>; a mapped-only diff from that tree runs just its checks (plan rows 4-11, plus row 4a's tree-map check) to check-partial.out, inherits the reference's green marker, rerun guard on its names, no marker on red, a partial row in check-runs.log. 81-partial-key: 13 checks.; tests 1052 → 1065; files lib/check.sh, tests/checks/81-partial-key.sh, tests/fixtures/check-names.txt → entries.jsonl:10
- 2026-10-30 01:35 · S2-02 · passes: treekey.mjs is now exported pure functions (ignoreList, parseMap, treeKey, partialKeys, mapNames) behind a CLI guard; adds --partial (full key, reduced key, <blob> <path> lines) and --names (plan §1 default); bare call and --pathspec unchanged (key as live). CHECK_KEY_MAP: config default empty, this repo maps CLAUDE.md to 39/37, prompt_env exports it, template comment. 81-partial-key: 8 checks.; tests 1044 → 1052; files lib/treekey.mjs, lib/config.sh, lib/prompt.sh, .harness/config.sh, templates/project/config.sh, … → entries.jsonl:9

## Current rules

- The suite's length in every prompt: a green marker's `wall` line, and a timeout rule → journal/decisions/2026-10-30-suite-length-in-prompt.md
- A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing → journal/decisions/2026-10-30-red-marker.md
- A mapped path's change runs only its readers: `CHECK_KEY_MAP`, the `part-<key>` sidecar, the partial run, the lint → journal/decisions/2026-10-30-partial-key.md
- The suite waits on a condition or a barrier, never on the clock; a flake is reproduced with --repeat and fixed at its cause → journal/decisions/2026-10-29-tests-wait-not-sleep.md
- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
- Questions wait in `harness needs` until answered: one item per question, moved forward, no push → journal/decisions/2026-10-29-questions-wait.md
- Lanes leftovers: atomic list writes, a record-only main, the finish order, two lint rules, two checks, the suite-ran note → journal/decisions/2026-10-29-lanes-leftovers.md
- The coordinator ends a run only when the lane count its opens used saw no lane → journal/decisions/2026-10-29-lane-count-end-check.md
- Entries that survive: the session checks its own, a long summary is cut and kept, one resume for a missing one → journal/decisions/2026-10-29-entries-survive.md
- A parked run's continue advice names another live run of its project and gives Michael the choice → journal/decisions/2026-10-29-continue-advice-busy-project.md
- Merge conflicts resolved without Michael: a sorted merge for lists first, then a resolve session, verified → journal/decisions/2026-10-29-conflict-resolution.md
- This repo's suite gets a 25-minute check timeout; TEST_JOBS stays at its default → journal/decisions/2026-10-29-check-timeout-25m.md

_66 older rules: journal/decisions._
