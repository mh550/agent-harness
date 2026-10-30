<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-29-3` (agent-harness)

What this file is: the run's journal, newest entry first, rendered by the harness from `entries.jsonl` for Michael's phone. Spec: `docs/specs/2026-10-30-suite-time.md` (S1: the suite's wall in every prompt's Suite line and a red tree cached like a green one; S2: `CHECK_KEY_MAP`, a change to a mapped path runs only the checks that read it). Brief: S1 then S2; proceed on the spec's defaults.

How to read the feature list (`feature_list.json`): array order is priority; `after` names what a feature waits on; `passes` flips when a session's suite is green and the harness verifies the milestone before merging it into `main`. S1 is five features (S1-01 plan, S1-02 fix 3, S1-03/S1-04 fix 2, S1-05 review+docs), S2 six (S2-01 plan, S2-02 map and treekey, S2-03 the partial run, S2-04 the lint, S2-05 the driver, S2-06 review+docs); S2 starts after S1 merges.

Steer via `INBOX.md` on this branch: change its first line to `status: pause` or `status: stop`; write answers to questions under its `## Answers` heading. The harness pulls before every session.

### 2026-10-30 03:24 · S2-05 · passes

run_init takes key and reduced key from one treekey --partial call; fresh also removes part-<reduced>, so verify's tree runs in full. 81 gains two stub runs: pkedit (CLAUDE.md-only session: partial init, memlint alone, tests-end 2) and pkv (B passes with a Gotchas line only; verify M1's call has no arguments, part- line 1 is B's key). New stub hook STUB_GOTCHA_ONLY.

- **Files:** lib/record.sh, tests/checks/81-partial-key.sh, tests/stub-claude.sh, tests/fixtures/check-names.txt
- **Verified:** pkv watched red before the fix (cs-pkv.log: B's key with memlint twice, no bare call), green after; bash tests/run.sh partial-key key-map-lint 29/29; git diff main -- lib/lane.sh empty; bash -n on record.sh, 81, stub-claude.sh; full suite through check.sh: green in 806 s, 1073 tests
- **Tests:** 1071 → 1073
- **Dead end:** pkedit asserting exactly two suite calls — the capped run checks its last CLAUDE.md-only tree once more (a third memlint call): the check asserts the full run first, then memlint alone on every later call
- **Discovery** (affects S2-06): pkv uses STUB_GOTCHA_ONLY=B (verify M1, as the feature step words it), not the plan's C (whose verify is M2's)
- **Discovery** (affects S2-06): run_init now silences treekey --partial's stderr (a dropped map entry): check.sh's own --partial call prints it into init.out
- *10-S2-05 · claude-opus-5-5*

### 2026-10-30 03:05 · S2-04 · passes

82-key-map-lint: keymaplint (node in the check file) with rules (a)/(b), widened root expressions, file-wide aliases and six allowed forms, each with its why; fixtures in tests/fixtures/key-map-lint/. Map now CLAUDE.md:39-memlint-m4:37-memory-prompts-m2:79-suite-length; 36, 75 and 81:56 rewritten instead of joined. Decision 2026-10-30-partial-key written; S3 Updated line. 82: 6 checks.

- **Files:** tests/checks/82-key-map-lint.sh, tests/fixtures/key-map-lint/, .harness/config.sh, tests/checks/36-run-16-retro-backlog.sh, tests/checks/75-suite-tools.sh, tests/checks/81-partial-key.sh, journal/decisions/2026-10-30-partial-key.md, journal/decisions/2026-10-26-suite-split.md, tests/fixtures/check-names.txt, CLAUDE.md
- **Verified:** watched red: on today's tree the lint named 36:20,21,30, 75:69, 79:87, 81:56 and its own lines; two mutations (no hit pushed; allowed forms not cut) turned 3 of 6 checks red each; then key-map-lint 6/6, 36 13/13, 75 11/11, 81 21/21, 39-memlint 19/19; full suite via check.sh; full suite via check.sh: green in 825 s, 1071 tests (an earlier full run on a pre-fix tree had 2 reds: memlint over the Gotchas cap, 34 on docs/specs; both fixed and rerun)
- **Tests:** 1065 → 1071
- **Dead end:** check names and JS regex sources holding a literal $HERE/.., $HH or ../CLAUDE.md — the lint scans 82 itself: those were hits on its own lines; the regex names vars through a vars() helper and the check names avoid root spellings
- **Dead end:** 36 rewritten as cd "$HERE/../docs/specs" — 34-check-key bars a check naming a path the cache key ignores (docs/specs): now cd "$HERE/../docs" and import specs/<seed>, the relative read it always was
- **Dead end:** adding the promoted Gotchas line as a 16th — memlint counts the section comment: the section was full; the needs/parked cards line was dropped for it
- **Discovery** (affects S2-06): rule (a) hits a line that only compares a CLAUDE.md string beside harness_config "$HERE/.." (81:56); the expected value moved to its own line (M0=)
- **Discovery** (affects S2-06): the lint scans its own file: any literal root spelling ($HERE/.., $HH, ../CLAUDE.md) in 82's code or check names is a hit; write regex sources via vars()
- **Discovery** (affects S2-05, run): this repo's map grew 79-suite-length, so the exported HARNESS_CHECK_KEY_MAP of a run started before this merge differs from the tree's: row 4a runs those trees in full until the driver reloads
- **Question for Michael:** 36 and 75 were rewritten (cd into docs/; bash "$HERE/lint-sleeps.sh") rather than joined to CHECK_KEY_MAP (default: ~125 s kept out of Gotchas-only runs). Keep that, or join them? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/journal/decisions/2026-10-30-partial-key.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/tests/checks/36-run-16-retro-backlog.sh:19
- **Resolved:** harness needs/parked print cards: grep ` <label to 11><value>`; HARNESS_GLYPHS=unicode for `·` `⚠` (else - !) (agent-harness-2026-10-28 2026-10-28)
- **Proposed change:** S2-04 step 1 lists readlink -f and (cd && pwd) as allowed alone; per the plan §5 they are allowed only as an alias assignment (allowed-3/5 fixtures), and step 2 should name 79 (rule a) and 81:56 among the finds
- *09-S2-04 · claude-opus-5-5*

### 2026-10-30 02:29 · S2-03 · passes

check.sh's full form: one treekey --partial call; a green full run writes part-<reduced>; a mapped-only diff from that tree runs just its checks (plan rows 4-11, plus row 4a's tree-map check) to check-partial.out, inherits the reference's green marker, rerun guard on its names, no marker on red, a partial row in check-runs.log. 81-partial-key: 13 checks.

- **Files:** lib/check.sh, tests/checks/81-partial-key.sh, tests/fixtures/check-names.txt
- **Verified:** bash tests/run.sh check-rerun check-key red-marker partial-key: 59/59 then 81 21/21 after the review; mutations of rows 4a, 7 and the ignore guard each turn one 81 check red; full suite via check.sh green, 1065 tests; the final full run flaked once on 46-lanes-continue (a run stopped mid-M2 reopens its lane; no map there, so check.sh takes today's path), its rerun 12/12
- **Tests:** 1052 → 1065
- **Dead end:** testing row 7 with a hand-grown map alone — row 4a fires first; the case grows the tree's config under a stale exported map (a full run that writes the sidecar), then exports the grown map
- **Discovery** (affects S2-05, project): check.sh's partial path needs the tree's own .harness/config.sh CHECK_KEY_MAP to equal HARNESS_CHECK_KEY_MAP (row 4a, whitespace collapsed): a stub repo or run testing a partial commits the map there
- **Discovery** (affects S2-05, S2-06): until S2-05's run_init fresh also removes part-<reduced>, a verify or rebase check on a tree differing from its reference in CLAUDE.md alone runs a partial: S2 must not merge without S2-05
- **Discovery** (affects S2-04, S2-06): a partial also returns 1 when .harness/config.sh is under HARNESS_CHECK_KEY_IGNORE (review finding: its map could change under an equal reduced key) - beyond the plan's table, default
- **Discovery** (affects S2-06): a partial green writes no check-<key>.out, so scratch_done's check-last.out (lib/prompt.sh:30) can be the last full run's output on another tree; S2-06 should say it or fall back to check-partial.out
- **Discovery** (affects S2-06): the rerun output of a partial is check-partial-rerun.out (plan default); a partial flake row has partial: [names], rerun failed|partial, names never empty
- **Proposed change:** S2-06 should document check.sh's partial row 4a-bis (.harness/config.sh under CHECK_KEY_IGNORE runs in full) in docs/architecture.md and the decision file
- *08-S2-03 · claude-opus-5-5*

### 2026-10-30 01:35 · S2-02 · passes

treekey.mjs is now exported pure functions (ignoreList, parseMap, treeKey, partialKeys, mapNames) behind a CLI guard; adds --partial (full key, reduced key, <blob> <path> lines) and --names (plan §1 default); bare call and --pathspec unchanged (key as live). CHECK_KEY_MAP: config default empty, this repo maps CLAUDE.md to 39/37, prompt_env exports it, template comment. 81-partial-key: 8 checks.

- **Files:** lib/treekey.mjs, lib/config.sh, lib/prompt.sh, .harness/config.sh, templates/project/config.sh, tests/checks/81-partial-key.sh, tests/fixtures/check-names.txt
- **Verified:** 8 checks in tests/checks/81-partial-key.sh watched red (0/8) then green (8/8); bash tests/run.sh check-key partial-key 18/18; the new treekey's bare key and --pathspec equal the live one's on this tree (1780039c545a411b); node --check and bash -n clean; full suite via check.sh: green in 817 s, 1052 tests
- **Tests:** 1044 → 1052
- **Discovery** (affects S2-03): treekey.mjs --names <path>… prints the map's names for those paths (map order, a duplicate path merged into its first entry) and exits 1 with no line when a path is no kept entry's: check.sh's rows 9/10 use it
- **Discovery** (affects S2-03, S2-05): treekey.mjs's bare call never parses HARNESS_CHECK_KEY_MAP (no stderr); only --partial and --names print the dropped-entry lines
- **Discovery** (affects S2-03): 81-partial-key.sh's repo $T/pk has CLAUDE.md, README.md, lib/a.sh and docs/plans/p.md committed, CLAUDE.md already appended once (dirty) after the first checks; pk() sets HARNESS_CHECK_KEY_IGNORE='.harness/runs docs/plans'
- **Discovery** (affects S2-04): the config check in 81 matches this repo's map as CLAUDE.md:39-memlint-m4:37-memory-prompts-m2* so S2-04 can extend it without editing the check
- *07-S2-02 · claude-opus-5-5*

### 2026-10-30 01:19 · S2-01 · passes

Wrote docs/plans/2026-10-30-S2-partial-key.md: treekey.mjs's exported functions and --partial (plus a --names mode, default), parseMap's drops, the part-<reduced> sidecar, check.sh's partial path as a numbered table (rows 0-11 + 4a), what a partial green/red writes, the lint's rules and allow-list with today's finds, the checks, decision and S3 line. No code changed.

- **Files:** docs/plans/2026-10-30-S2-partial-key.md
- **Verified:** Lint rules prototyped in scratch over tests/checks with CLAUDE.md: finds 36, 37, 39, 75-suite-tools, 79 (13:386 without the == form); widened forms checked for new hits (none). Line refs checked by grep. Opus review, two reports: 1 Critical, 4 Important, 5 Minor, all folded into the plan. Suite: green, cached for this code tree, 1044 tests.
- **Tests:** 1044 → 1044
- **Discovery** (affects S2-04): The spec's lint rule (a) ('a variable set to it on that line') misses 79-suite-length.sh:87, which reads "$HH/CLAUDE.md" (HH from tests/lib.sh:87 or its own line 6): the plan widens root expressions to $HH, $HARNESS_HOME, $(cd "<R>" && pwd) and file-wide aliases, and 79 joins the map
- **Discovery** (affects S2-04): 13-run-2-michael-sets-desk.sh:386 (`== "PWD=$HH"`) is a rule (b) hit unless the allow-list gets a sixth form, a `== "...<root>"` string compare (plan default); 13 takes ~205 s, too dear to map
- **Discovery** (affects S2-03): The driver loads config once (lib/lane.sh:45; driver.sh:403 after a main merge): a session editing .harness/config.sh's map leaves HARNESS_CHECK_KEY_MAP stale, and a map from user config/run.env is linted by nothing. Plan row 4a: the tree's sourced CHECK_KEY_MAP (empty if unset) must equal the exported one, else full run; stub runs put the map in the throwaway project's .harness/config.sh
- **Discovery** (affects S2-02, S2-04): tests/run.sh matches check names by substring: a map name must be the full stem (75-suite-tools, not 75: 75-merge-sorted shares it)
- **Discovery** (affects S2-04): 82-key-map-lint's negative fixtures go in tests/fixtures/key-map-lint/, not inline: inline they'd be hits on 82's own lines
- **Discovery** (affects S2-05): The verify's own full green rewrites part-<reduced>, so S2-05 step 2's 'no part- sidecar afterwards' is read as: its line 1 is the verified tree's key. S2-05 needs a new stub hook STUB_GOTCHA_ONLY=<id> (a pass whose only change is the Gotchas line)
- **Discovery** (affects S2-04, S2-06): Lint escapes the review found and the plan closes: $(readlink -f "<R>") and $(cd "<R>" && pwd) are root expressions (not allowed forms); git -C "<R>" is allowed only with log/rev-parse/cat-file/worktree/ls-files; ../<basename> is a hit; the lint can't see reads by lib/ or tests/*.sh, so a map entry must be a file only check-file lines read
- **Question for Michael:** Default taken: the lint allows a `== "...<root>"` string compare (13:386's `PWD=$HH`) rather than mapping 13 (205 s) for it. Keep it? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/docs/plans/2026-10-30-S2-partial-key.md
- **Question for Michael:** Default taken: a partial's rerun output goes to check-partial-rerun.out, not the spec's check-rerun.out (which stays the last full run's, beside its check.out). Keep it? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/docs/plans/2026-10-30-S2-partial-key.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-1/lib/check.sh:87
- **Proposed change:** S2-04 step 2 should name 79-suite-length.sh (rule a through $HH) beside 36 and 75
- **Proposed change:** S2-05 step 2's 'no part- sidecar for that reduced key afterwards' should read 'its part-<reduced> names the verified tree' (the verify's full green rewrites it)
- **Proposed change:** S2-03 should list a case for plan row 4a (the tree's own map differs from HARNESS_CHECK_KEY_MAP: full run)
- **Proposed change:** S2-04 step 1's allow-list should match the plan's §5 (readlink -f and (cd && pwd) as root expressions allowed only in an alias assignment; git -C with five subcommands)
- *06-S2-01 · claude-opus-5-5*

### 2026-10-30 01:02 · verify S1 · passes

All five S1 features hold: full suite green (1044 tests), subsets 34/39/73/79/80 re-run green, greps and docs confirmed. Note: S1-04 step 3 literal diff scope also includes S1-05 review fix I1.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| S1-01 | 1 | re-ran/inspected step 1 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | plan exists (218 lines); readers named, matching the code (check.sh/run_init/tests_end now read -r via green_count) | yes |
| S1-01 | 2 | re-ran/inspected step 2 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | red-<key> layout and placement present in plan and implemented identically in lib/check.sh:15,129 | yes |
| S1-01 | 3 | re-ran/inspected step 3 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | check files and stub hook STUB_PLANT_MARKERS exist and run (80-red-marker 16/16) | yes |
| S1-01 | 4 | re-ran/inspected step 4 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | both decision files exist; SUITE_LENGTH sits under This session in prompts (decision-recorded deviation) | yes |
| S1-01 | 5 | re-ran/inspected step 5 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | init ran the full suite: green, 1044 tests; plan-only commit changed no code | yes |
| S1-02 | 1 | re-ran/inspected step 1 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | 34-check-key 10/10 pass: asserts 2-line marker and byte-identical cached line | yes |
| S1-02 | 2 | re-ran/inspected step 2 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | 79-suite-length 11/11 pass incl. coding/initializer prompts, tests-start/end and not-measured case | yes |
| S1-02 | 3 | re-ran/inspected step 3 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | check.sh writes printf n/wall; grep for surviving cat prints nothing | yes |
| S1-02 | 4 | re-ran/inspected step 4 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | lib/prompt.sh suite_length; Suite line sits under This session in prompts (run.md points there; decision-recorded), command form checked by 79 | yes |
| S1-02 | 5 | re-ran/inspected step 5 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | grep -c never poll it = 1; twice-its-wall sentence at coding.md:22 | yes |
| S1-02 | 6 | re-ran/inspected step 6 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | CLAUDE.md has see the run prompt; 208 s count 0; 39-memlint 11/11 | yes |
| S1-02 | 7 | re-ran/inspected step 7 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | decision file present with rejected list | yes |
| S1-02 | 8 | re-ran/inspected step 8 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | check-names.txt LC_ALL=C sorted; bash -n clean | yes |
| S1-02 | 9 | re-ran/inspected step 9 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | init full run green, 1044 tests | yes |
| S1-03 | 1 | re-ran/inspected step 1 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | 80-red-marker 16/16 pass covering the four-line red marker | yes |
| S1-03 | 2 | re-ran/inspected step 2 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | cached red/subset behaviour covered by 80, passes | yes |
| S1-03 | 3 | re-ran/inspected step 3 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | green-after, whole suite, timeout, cap kill, green removal covered by 80, passes | yes |
| S1-03 | 4 | re-ran/inspected step 4 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | check.sh write/lookup/removal present; bash -n clean; header names red-<key> | yes |
| S1-03 | 5 | re-ran/inspected step 5 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | decision file present | yes |
| S1-03 | 6 | re-ran/inspected step 6 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | names sorted; check-rerun, check-key, red-marker green (70/70 in my subset run) | yes |
| S1-03 | 7 | re-ran/inspected step 7 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | init full run green | yes |
| S1-04 | 1 | re-ran/inspected step 1 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | 80-red-marker stub-run checks with counting CHECK_CMD pass | yes |
| S1-04 | 2 | re-ran/inspected step 2 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | verify clears planted markers (STUB_PLANT_MARKERS) check passes | yes |
| S1-04 | 3 | re-ran/inspected step 3 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | run_init fresh rm of red-key present; but git diff main also holds S1-05 review fix I1 (init-failed flag, green_count); extra beyond literal only-removal-and-read-r, accepted as later mandated review work | yes |
| S1-04 | 4 | re-ran/inspected step 4 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | names sorted; bash -n clean | yes |
| S1-04 | 5 | re-ran/inspected step 5 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | init full run green | yes |
| S1-05 | 1 | re-ran/inspected step 1 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | review file S1-review.md exists: no Critical, 3 Important, 5 Minor | yes |
| S1-05 | 2 | re-ran/inspected step 2 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | Important findings fixed with checks (I1 init-failed, I2, I3 covered in 79/80 passing) | yes |
| S1-05 | 3 | re-ran/inspected step 3 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | green_count shares one read -r shape in record.sh; check.sh same | yes |
| S1-05 | 4 | re-ran/inspected step 4 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | architecture.md 4 and README 1 mention red-<key>; README names last full run | yes |
| S1-05 | 5 | re-ran/inspected step 5 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | bash -n and node --check clean; 39-memlint green | yes |
| S1-05 | 6 | re-ran/inspected step 6 (greps, bash tests/run.sh subset 34/79/80/39/73, init full-suite output) | init full run green 1044 tests | yes |

- *010027-verify-S1 · claude-sonnet-5-5*

### 2026-10-30 00:46 · S1-05 · passes

S1 review: 0 Critical, 3 Important, 5 Minor. Fixed, each red first: I1 run_init keeps no red-<key> around a failed init; I2 the cached red shows check-<key>.out or says it is gone; I3 suite_length reads every green wall before a red; M1 no red cached for codes ≥128; M2 atomic marker writes; M3 green_count in record.sh; M4. Docs: architecture §3/§4/§7/prompt, README.

- **Files:** lib/check.sh, lib/record.sh, lib/prompt.sh, tests/checks/79-suite-length.sh, tests/checks/80-red-marker.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-30-red-marker.md, journal/decisions/2026-10-30-suite-length-in-prompt.md, docs/architecture.md, README.md, tests/checks/74-flakes-run.sh
- **Verified:** Opus reviewer read $HARNESS_SCRATCH/S1.diff, findings in S1-review.md; 79+80 subset: 7 new/changed checks FAIL before the fixes, 27/27 after; 08/40/74/77/34 subset 181/181; 39-memlint 19/19; bash -n on every touched shell file; grep -c 'red-<key>': README 1, architecture 4; full suite: check: green in 806 s, 1044 tests (a first full run was red: 74 grepped the old cached tail, and a 15th Gotchas line went over memlint's 15-line cap; both fixed)
- **Tests:** 1039 → 1044
- **Dead end:** removing green-<key> too when an init failed — a green isn't harmful and carries the test count; only the red marker answers wrongly
- **Dead end:** a Gotchas line about red-<key> answering a red tree's second full call — memlint counts the section's comment line: 15 bullets is 16 lines, over its cap; dropped rather than displace one
- **Discovery** (affects S2, run): run_init now writes init-failed in the lane dir (driver: state dir) while an init fails; the next run_init drops the tree's red-<key> before its suite
- **Discovery** (affects S2, run): the cached red answer no longer prints the stored RED line verbatim: its `— last lines of …:` tail is replaced with check-<key>.out's or `its output is gone from scratch`
- **Discovery** (affects S2, run): suite_length reads every green marker (cwd tree's, then newest) before any red one
- **Question for Michael:** Review minor M5 left: 79's rw check can't tell the rerun's wall from start-to-end (a slow-first/instant-rerun inverse case would). And I1's residue: a session on a tree cached red by something outside the key (a port, a tool) has no form that runs the full suite on it; should check.sh get an escape hatch (e.g. HARNESS_CHECK_FRESH=1 skipping the red lookup), default: none? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-0/lib/check.sh:77, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-3/slot-0/journal/decisions/2026-10-30-red-marker.md
- *05-S1-05 · claude-opus-5-5*

### 2026-10-30 00:03 · S1-04 · passes

run_init fresh removes red-<key> beside green-<key> (lib/record.sh, one line), so verify's tree always runs in full. 80-red-marker gains 3 stub-run checks with a counting CHECK_CMD: the retry's init is the cached red (2 suite calls on the red tree), and STUB_PLANT_MARKERS (new stub hook) proves verify clears both markers. Decision red-marker gains the driver bullet.

- **Files:** lib/record.sh, tests/checks/80-red-marker.sh, tests/stub-claude.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-30-red-marker.md
- **Verified:** 80-red-marker: the verify check red before the record.sh line (planted red-<key> answered verify's run_init), 11/11 after; full suite via lib/check.sh: green in 793 s, 1039 tests (1036 → 1039); bash -n on record.sh, 80-red-marker.sh, stub-claude.sh clean; git diff main -- lib/record.sh is the removal line and the two read -r readers
- **Tests:** 1036 → 1039
- **Dead end:** grepping harness-log.md for `suite red before the session` — run_init writes it with log(), so it is only in $STATE/run.log; the check reads run.log
- **Discovery** (affects S1-05, run): the retry's init output is best read from its session prompt ($STATE/logs/<nn>-<id>.prompt.md, ## Init output): init.out in scratch is overwritten by every later run_init, KEEP_SCRATCH or not
- **Discovery** (affects S1-05): step 1 already held after S1-03 (the retry's run_init answers from the marker with no driver change); only the verify invariant needed the record.sh line
- **Proposed change:** S1-04 step 1 says the log has `suite red before the session`: it is run.log, not harness-log.md (a log() line, not a note)
- *04-S1-04 · claude-opus-5-5*

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
