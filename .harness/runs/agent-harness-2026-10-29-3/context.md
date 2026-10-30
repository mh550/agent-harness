# Context pack for `S2-06`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (S2-05, affects S2-06): pkv uses STUB_GOTCHA_ONLY=B (verify M1, as the feature step words it), not the plan's C (whose verify is M2's) → entries.jsonl:12
- Discovery (S2-05, affects S2-06): run_init now silences treekey --partial's stderr (a dropped map entry): check.sh's own --partial call prints it into init.out → entries.jsonl:12
- Discovery (S2-04, affects S2-06): rule (a) hits a line that only compares a CLAUDE.md string beside harness_config "$HERE/.." (81:56); the expected value moved to its own line (M0=) → entries.jsonl:11
- Discovery (S2-04, affects S2-06): the lint scans its own file: any literal root spelling ($HERE/.., $HH, ../CLAUDE.md) in 82's code or check names is a hit; write regex sources via vars() → entries.jsonl:11
- Discovery (S2-04, affects S2-05, run): this repo's map grew 79-suite-length, so the exported HARNESS_CHECK_KEY_MAP of a run started before this merge differs from the tree's: row 4a runs those trees in full until the driver reloads → entries.jsonl:11
- Discovery (S2-03, affects S2-05, S2-06): until S2-05's run_init fresh also removes part-<reduced>, a verify or rebase check on a tree differing from its reference in CLAUDE.md alone runs a partial: S2 must not merge without S2-05 → entries.jsonl:10
- Discovery (S2-03, affects S2-04, S2-06): a partial also returns 1 when .harness/config.sh is under HARNESS_CHECK_KEY_IGNORE (review finding: its map could change under an equal reduced key) - beyond the plan's table, default → entries.jsonl:10
- Discovery (S2-03, affects S2-06): a partial green writes no check-<key>.out, so scratch_done's check-last.out (lib/prompt.sh:30) can be the last full run's output on another tree; S2-06 should say it or fall back to check-partial.out → entries.jsonl:10
- Discovery (S2-03, affects S2-06): the rerun output of a partial is check-partial-rerun.out (plan default); a partial flake row has partial: [names], rerun failed|partial, names never empty → entries.jsonl:10
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

## What it builds on

- 2026-10-30 03:24 · S2-05 · passes: run_init takes key and reduced key from one treekey --partial call; fresh also removes part-<reduced>, so verify's tree runs in full. 81 gains two stub runs: pkedit (CLAUDE.md-only session: partial init, memlint alone, tests-end 2) and pkv (B passes with a Gotchas line only; verify M1's call has no arguments, part- line 1 is B's key). New stub hook STUB_GOTCHA_ONLY.; tests 1071 → 1073; files lib/record.sh, tests/checks/81-partial-key.sh, tests/stub-claude.sh, tests/fixtures/check-names.txt → entries.jsonl:12

## Lately in the run

- 2026-10-30 03:05 · S2-04 · passes: 82-key-map-lint: keymaplint (node in the check file) with rules (a)/(b), widened root expressions, file-wide aliases and six allowed forms, each with its why; fixtures in tests/fixtures/key-map-lint/. Map now CLAUDE.md:39-memlint-m4:37-memory-prompts-m2:79-suite-length; 36, 75 and 81:56 rewritten instead of joined. Decision 2026-10-30-partial-key written; S3 Updated line. 82: 6 checks.; tests 1065 → 1071; files tests/checks/82-key-map-lint.sh, tests/fixtures/key-map-lint/, .harness/config.sh, tests/checks/36-run-16-retro-backlog.sh, tests/checks/75-suite-tools.sh, … → entries.jsonl:11
- 2026-10-30 02:29 · S2-03 · passes: check.sh's full form: one treekey --partial call; a green full run writes part-<reduced>; a mapped-only diff from that tree runs just its checks (plan rows 4-11, plus row 4a's tree-map check) to check-partial.out, inherits the reference's green marker, rerun guard on its names, no marker on red, a partial row in check-runs.log. 81-partial-key: 13 checks.; tests 1052 → 1065; files lib/check.sh, tests/checks/81-partial-key.sh, tests/fixtures/check-names.txt → entries.jsonl:10

## Current rules

- The suite's length in every prompt: a green marker's `wall` line, and a timeout rule → journal/decisions/2026-10-30-suite-length-in-prompt.md
- A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing → journal/decisions/2026-10-30-red-marker.md
- A mapped path's change runs only its readers: `CHECK_KEY_MAP`, the `part-<key>` sidecar, the partial run, the lint → journal/decisions/2026-10-30-partial-key.md
- The suite waits on a condition or a barrier, never on the clock; a flake is reproduced with --repeat and fixed at its cause → journal/decisions/2026-10-29-tests-wait-not-sleep.md
- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md
- Questions wait in `harness needs` until answered: one item per question, moved forward, no push → journal/decisions/2026-10-29-questions-wait.md
- Lanes leftovers: atomic list writes, a record-only main, the finish order, two lint rules, two checks, the suite-ran note → journal/decisions/2026-10-29-lanes-leftovers.md

_71 older rules: journal/decisions._
