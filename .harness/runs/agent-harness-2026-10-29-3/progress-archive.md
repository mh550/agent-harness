<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-29-3` (agent-harness)

What this file is: the run's journal, newest entry first, rendered by the harness from `entries.jsonl` for Michael's phone. Spec: `docs/specs/2026-10-30-suite-time.md` (S1: the suite's wall in every prompt's Suite line and a red tree cached like a green one; S2: `CHECK_KEY_MAP`, a change to a mapped path runs only the checks that read it). Brief: S1 then S2; proceed on the spec's defaults.

How to read the feature list (`feature_list.json`): array order is priority; `after` names what a feature waits on; `passes` flips when a session's suite is green and the harness verifies the milestone before merging it into `main`. S1 is five features (S1-01 plan, S1-02 fix 3, S1-03/S1-04 fix 2, S1-05 review+docs), S2 six (S2-01 plan, S2-02 map and treekey, S2-03 the partial run, S2-04 the lint, S2-05 the driver, S2-06 review+docs); S2 starts after S1 merges.

Steer via `INBOX.md` on this branch: change its first line to `status: pause` or `status: stop`; write answers to questions under its `## Answers` heading. The harness pulls before every session.

### 2026-10-29 23:42 · S1-03 · passes

check.sh full form writes red-<key> (rc, HARNESS_FAILED names, wall, RED line) after a red where both runs were `exit <rc> after`, answers the next full call on that tree from it, removes it on green; subsets read none. New 80-red-marker (8 checks); 08, 74 adapted; 10-e2 drops S1-02s wall line from its prompt compare; decisions/2026-10-30-red-marker.

- **Files:** lib/check.sh, tests/checks/80-red-marker.sh, tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh, tests/checks/74-flakes-run.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-30-red-marker.md, tests/checks/10-harness-eval-run-e2.sh
- **Verified:** 80-red-marker 1/8 before the code (the timeout/cap-kill negative passing), 8/8 after; `tests/run.sh check-rerun check-key red-marker` 32/32; the first full run went red on 08 (2 checks) and 74 (1), red again on the rerun; after fixing both, 74 and 08 green alone, then a full run green; that run flaked once on 10-harness-eval-run-e2 (the wall line, fixed); a third full run on the final tree
- **Tests:** 1028 → 1036
- **Dead end:** the full suite after the check.sh change alone — 08's ck() runs many CHECK_CMDs on one tree: after its `exit 3` every full call answered the cached red (the 124 line and the TERM check); 74's fe needed finish's suite to run on C's red tree
- **Discovery** (affects S1-04, S1-05): a green run removing a planted red-<key> is only reachable when the marker appears mid-run (the lookup answers first): 80's `plant` mode has the stub suite write it
- **Discovery** (affects S1-04, S1-05): 74-flakes-run's fe now makes C's red an `exit 124` (a timeout, never cached) so finish's suite runs; 08's ck() rm's red-* before each call. A stub run whose session leaves BROKEN now gets a cached red at the retry's run_init: S1-04's retry check sees it
- **Discovery** (affects S1-04): run_init fresh does not yet remove red-<key> (S1-04 step 3): until it does, a verify on a tree found red answers cached
- **Discovery** (affects S1-05, run): 10-harness-eval-run-e2 flaked (probe prompt vs prompt-coding.md): its noinit() kept S1-02s `Suite: last full run <s> s` line, which differs between renders; it now drops it like Clock. Any check comparing two rendered prompts below # This session must too
- *03-S1-03 · claude-opus-5-5*

### 2026-10-29 22:50 · S1-02 · passes

green-<key> is two lines (count, wall <s>); check.sh/run_init/tests_end read line 1 with read -r; prompt.sh suite_length gives SUITE_LENGTH. Deviation (default): the wall line sits under # This session in coding/initializer/verify/resolve, not run.md's Suite line (that broke 08's prefix check: walls 0 vs 1 s); run.md points there. A whole-suite rerun sets the wall. Rule, CLAUDE.md, decision.

- **Files:** lib/check.sh, lib/record.sh, lib/prompt.sh, prompts/parts/run.md, prompts/coding.md, prompts/verify.md, prompts/initializer.md, prompts/resolve.md, CLAUDE.md, journal/decisions/2026-10-30-suite-length-in-prompt.md, tests/checks/79-suite-length.sh, tests/checks/34-check-key.sh, +3 more
- **Verified:** new checks watched red (0/8 on the old code; the rerun-wall and run_init checks red with their fix reverted); 79+34+73+39-memlint green; 08/13/14/15 prefix subset 293/293; full suite green on its first run: check: green in 786 s, 1028 tests (1028/1028 checks passed). A first full run with the wall in run.md went green only after 08 flaked on 'two coding prompts share a byte-identical prefix' (prompts differed at the Suite line).
- **Tests:** 1016 → 1028
- **Dead end:** {{SUITE_LENGTH}} in prompts/parts/run.md's Suite line, as the spec and step 4 say — 08/13/14/15 require two sessions' prompts byte-identical through # This session; a per-tree wall differs per session (stub walls 0 vs 1 s flaked 08), and every real run would split the shared prefix (decisions/2026-10-21-static-first-prompts, E3-05 amendment)
- **Discovery** (affects S1-03, S1-04, S1-05): The wall is rendered as `Suite: last full run <s> s: …` under # This session of coding/initializer/verify/resolve; run.md's Suite line ends `its last full run is under *This session*)`. S1-03..05 grep that line, not run.md's.
- **Discovery** (affects S1-03, S1-05): check.sh: after a whole-suite rerun (a red with no HARNESS_FAILED names) the marker's wall is the rerun's seconds; after a named-files rerun it stays the first run's.
- **Discovery** (affects S1-05): The command form (lib/prompt.sh <state> coding <id>) keys suite_length on $WT, the record worktree, not the lane's slot, so it can show a different wall than the lane's session got (reviewer finding, left as is: the command form reads CLAUDE.md there too).
- **Discovery** (affects S1-04): 79-suite-length's planted-marker run needs `mkdir -p $HARNESS_CHECK_CACHE` in its INIT_CMD: the state's green/ doesn't exist before the first check.sh
- **Question for Michael:** S1-02 put the suite's wall under # This session (a `Suite: last full run …` line) rather than in run.md's This run Suite line, because the latter split the prompts' shared prefix that 08/13/14/15 check (default; decision file). Keep it there, or move it to run.md and relax the prefix checks to stop at the Suite line? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-0/journal/decisions/2026-10-30-suite-length-in-prompt.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-0/prompts/coding.md:132
- **Proposed change:** S1-02 step 4 should read: run.md's Suite line ends `cached per code tree; its last full run is under *This session*)` and each template's # This session block has `Suite: last full run {{SUITE_LENGTH}}`; step 5's sentence ends `(under *This session*)`. The spec's fix 3 should say the same.
- *02-S1-02 · claude-opus-5-5*

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
