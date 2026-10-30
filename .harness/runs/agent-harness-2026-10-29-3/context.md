# Context pack for `S2-04`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (S2-03, affects S2-04, S2-06): a partial also returns 1 when .harness/config.sh is under HARNESS_CHECK_KEY_IGNORE (review finding: its map could change under an equal reduced key) - beyond the plan's table, default → entries.jsonl:10
- Discovery (S2-02, affects S2-04): the config check in 81 matches this repo's map as CLAUDE.md:39-memlint-m4:37-memory-prompts-m2* so S2-04 can extend it without editing the check → entries.jsonl:9
- Discovery (S2-01, affects S2-04): The spec's lint rule (a) ('a variable set to it on that line') misses 79-suite-length.sh:87, which reads "$HH/CLAUDE.md" (HH from tests/lib.sh:87 or its own line 6): the plan widens root expressions to $HH, $HARNESS_HOME, $(cd "<R>" && pwd) and file-wide aliases, and 79 joins the map → entries.jsonl:8
- Discovery (S2-01, affects S2-04): 13-run-2-michael-sets-desk.sh:386 (`== "PWD=$HH"`) is a rule (b) hit unless the allow-list gets a sixth form, a `== "...<root>"` string compare (plan default); 13 takes ~205 s, too dear to map → entries.jsonl:8
- Discovery (S2-01, affects S2-02, S2-04): tests/run.sh matches check names by substring: a map name must be the full stem (75-suite-tools, not 75: 75-merge-sorted shares it) → entries.jsonl:8
- Discovery (S2-01, affects S2-04): 82-key-map-lint's negative fixtures go in tests/fixtures/key-map-lint/, not inline: inline they'd be hits on 82's own lines → entries.jsonl:8
- Discovery (S2-01, affects S2-04, S2-06): Lint escapes the review found and the plan closes: $(readlink -f "<R>") and $(cd "<R>" && pwd) are root expressions (not allowed forms); git -C "<R>" is allowed only with log/rev-parse/cat-file/worktree/ls-files; ../<basename> is a hit; the lint can't see reads by lib/ or tests/*.sh, so a map entry must be a file only check-file lines read → entries.jsonl:8
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

## Promote to Gotchas

- check.sh's partial path needs the tree's own .harness/config.sh CHECK_KEY_MAP to equal HARNESS_CHECK_KEY_MAP (row 4a, whitespace collapsed): a stub repo or run testing a partial commits the map there → entries.jsonl:10

## What it builds on

- 2026-10-30 02:29 · S2-03 · passes: check.sh's full form: one treekey --partial call; a green full run writes part-<reduced>; a mapped-only diff from that tree runs just its checks (plan rows 4-11, plus row 4a's tree-map check) to check-partial.out, inherits the reference's green marker, rerun guard on its names, no marker on red, a partial row in check-runs.log. 81-partial-key: 13 checks.; tests 1052 → 1065; files lib/check.sh, tests/checks/81-partial-key.sh, tests/fixtures/check-names.txt → entries.jsonl:10

## Lately in the run

- 2026-10-30 01:35 · S2-02 · passes: treekey.mjs is now exported pure functions (ignoreList, parseMap, treeKey, partialKeys, mapNames) behind a CLI guard; adds --partial (full key, reduced key, <blob> <path> lines) and --names (plan §1 default); bare call and --pathspec unchanged (key as live). CHECK_KEY_MAP: config default empty, this repo maps CLAUDE.md to 39/37, prompt_env exports it, template comment. 81-partial-key: 8 checks.; tests 1044 → 1052; files lib/treekey.mjs, lib/config.sh, lib/prompt.sh, .harness/config.sh, templates/project/config.sh, … → entries.jsonl:9
- 2026-10-30 01:19 · S2-01 · passes: Wrote docs/plans/2026-10-30-S2-partial-key.md: treekey.mjs's exported functions and --partial (plus a --names mode, default), parseMap's drops, the part-<reduced> sidecar, check.sh's partial path as a numbered table (rows 0-11 + 4a), what a partial green/red writes, the lint's rules and allow-list with today's finds, the checks, decision and S3 line. No code changed.; tests 1044 → 1044; files docs/plans/2026-10-30-S2-partial-key.md → entries.jsonl:8

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

_67 older rules: journal/decisions._
