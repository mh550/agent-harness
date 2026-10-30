<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-29-3` (agent-harness)

What this file is: the run's journal, newest entry first, rendered by the harness from `entries.jsonl` for Michael's phone. Spec: `docs/specs/2026-10-30-suite-time.md` (S1: the suite's wall in every prompt's Suite line and a red tree cached like a green one; S2: `CHECK_KEY_MAP`, a change to a mapped path runs only the checks that read it). Brief: S1 then S2; proceed on the spec's defaults.

How to read the feature list (`feature_list.json`): array order is priority; `after` names what a feature waits on; `passes` flips when a session's suite is green and the harness verifies the milestone before merging it into `main`. S1 is five features (S1-01 plan, S1-02 fix 3, S1-03/S1-04 fix 2, S1-05 review+docs), S2 six (S2-01 plan, S2-02 map and treekey, S2-03 the partial run, S2-04 the lint, S2-05 the driver, S2-06 review+docs); S2 starts after S1 merges.

Steer via `INBOX.md` on this branch: change its first line to `status: pause` or `status: stop`; write answers to questions under its `## Answers` heading. The harness pulls before every session.

### 2026-10-29 21:53 · S1-01 · passes

Wrote docs/plans/2026-10-30-S1-suite-time.md: the three marker readers (check.sh:67, run_init record.sh:461, tests_end record.sh:488) and their read -r, the wall line, suite_length in prompt_render, the red-<key> lines and placement, the driver's fresh rm, the checks of 34/79/80 with a counting run.env CHECK_CMD and STUB_PLANT_MARKERS, both decision files. No code changed.

- **Files:** docs/plans/2026-10-30-S1-suite-time.md
- **Verified:** lib/check.sh: green (cached for this code tree, 1016 tests); each step checked against the plan's sections §1, §5, §7, §8
- **Tests:** 1016 → 1016
- **Discovery** (affects S1-02): two existing checks cat a whole green marker and go red once it has a wall line: 08-scope-sh…:525 and 73-check-rerun.sh:34; switch them to sed -n 1p
- **Discovery** (affects S1-02): $(cat) of a marker with an empty line 1 (the stub's test ! -f BROKEN suite prints no count) gives \nwall 0, which skips the testcount fallback and writes \nwall into tests-start: the real reason for read -r
- **Discovery** (affects S1-02): the stub-run markers' walls are all 0: 79 pins suite_length by rewriting markers and rendering with the command form lib/prompt.sh <state> coding <id>
- **Discovery** (affects S1-02): a planted one-line green before the first suite: a run.env INIT_CMD writes it to $HARNESS_CHECK_CACHE/green-<treekey> (the init runs before run_init takes the key; load_config exports the cache)
- **Discovery** (affects S1-03): the red marker's write needs both whys to start 'exit ': keep the rerun's why in a variable (last) and the RED line in another (line) so it is stored as printed
- **Proposed change:** S1-04 step 2: 'both markers are gone afterwards' cannot hold, the verify's own green run writes green-<key> again; read it as red-<key> absent and green-<key> the verify's (2 tests and a wall), not the planted 99 tests
- **Proposed change:** S1-02 step 2: with a stub suite every wall is 0; the plan pins the lookup with command-form renders after rewriting markers (wall 4321, newest-mtime 77, none)
- *01-S1-01 · claude-opus-5-5*

### 2026-10-29 21:47 · init · passes

11 features: S1 5 (plan, fix 3 the wall line and prompt Suite line, fix 2 red-<key> in check.sh, fix 2 in the driver, review+docs), S2 6 (plan, CHECK_KEY_MAP and treekey --partial, the partial run in check.sh, the lint, the driver and verify invariant, review+docs). S2 after S1, in series, as the spec says.

- **Files:** .harness/runs/agent-harness-2026-10-29-3/feature_list.json
- **Verified:** node lib/features.mjs lint on the list prints nothing; the init suite was green (after a rerun of 47-lanes-two)
- **Discovery** (affects run): the stub project's suite in tests/lib.sh is `test ! -f BROKEN`, which counts nothing: the stub-run checks of S1-04 and S2-05 set CHECK_CMD in the run's config to a counting, argument-recording suite as 73-check-rerun.sh's rr-suite.sh
- **Discovery** (affects run): rendered prompts live in the run's state dir as prompt-<kind>.md (08-scope-sh checks grep $HARNESS_STATE/proj/<run>/prompt-coding.md) and per session under logs/*-<id>.prompt.md: 79-suite-length.sh reads them there
- **Discovery** (affects run): the spec's `prompt()` is lib/prompt.sh's prompt_render (prompt_vars/prompt_env/prompt_render); HARNESS_SUITE_LENGTH belongs with the other per-render variables set on the render line, and {{SUITE_LENGTH}} in parts/run.md is under {{SECTIONS}}
- **Discovery** (affects run): the init suite was green after a rerun: 47-lanes-two flaked (one flakes.jsonl row); a red there in a session is a known flake, not necessarily the session's
- **Discovery** (affects run): no .harness/runs/agent-harness-2026-10-29-2 directory is in this tree (only its ledger line): the 10-29-2 numbers the spec cites are the spec's, not re-derivable here
- *00-init · claude-fable-5-1*
