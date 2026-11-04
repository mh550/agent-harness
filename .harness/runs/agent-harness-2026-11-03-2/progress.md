<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-03-2` (agent-harness)

What this file is: the run's journal, newest entry first, rendered from `entries.jsonl` for Michael's phone. One milestone, **U1, the unit tier** (spec `docs/specs/2026-11-03-unit-tier.md`; phase 1 of `docs/plans/2026-11-03-test-suite-redesign.md`): the 111 `node --input-type=module` evals in the check files become `tests/unit/<module>.test.mjs` files under `node --test --test-isolation=none` (one node process), reported into `tests/run.sh` through `tests/unit/reporter.mjs` and `tests/checks/00-unit-tier.sh`, every check name unchanged (the full run's conformance line is the proof).

How to read the feature list (`feature_list.json`): six features in series, U1-01 the mechanism, U1-02 to U1-04 the move file by file, U1-05 the measurement (`findings-and-research/2026-11-03-unit-tier.md`, solo suites before and after, no other suite alive), U1-06 the review + simplify with the docs. Each feature's steps are what its verifier re-runs; `passes` flips when its session's suite is green. The milestone merges into `main` when all six pass and the verify is green.

To steer: edit `INBOX.md` on this branch (first line `status: pause` or `status: stop`; answers under `## Answers`). The harness pulls before every session.

### 2026-11-03 22:33 · U1-06 · passes

Review of U1 (Opus, one round): 0 Critical, 4 Important, 7 Minor. Fixed all 4 Important RED→GREEN (testcount.mjs CLI guard, the tier red on zero tests/no summary/stray stdout, inbox tpl read from lib/driver.sh, 2 key-order asserts) and 3 Minor; architecture.md and README.md describe the unit tier. 1163 → 1165, full run green.

- **Files:** lib/testcount.mjs, tests/checks/00-unit-tier.sh, tests/unit/reporter.mjs, tests/checks/33-suite-runner.sh, tests/fixtures/check-names.txt, tests/unit/inbox.test.mjs, tests/unit/metrics.test.mjs, tests/unit/entries.test.mjs, tests/unit/eval.test.mjs, journal/decisions/2026-11-03-unit-tier.md, docs/architecture.md, README.md
- **Verified:** Review at /tmp/harness/agent-harness/agent-harness-2026-11-03-2/u1-review.md. Two new 33-suite-runner checks seen red before the fix (u5 empty dir, u6 exit(0) at import, u8 console.log PASS line; u7 testcount beside a HARNESS_TESTS=5 file), green after; inbox and the key-order asserts each seen red on a wrong value. node --test tier 124/124 no ✖; subset 00-unit 33-suite 82-key-map 39-memlint 06 73 57: 201/201; full check.sh 1165/1165 in 810 s, conformance PASS.
- **Tests:** 1163 → 1165
- **Dead end:** a u7 fixture with `// HARNESS_TESTS=5` — testcount's contract regex is ^HARNESS_TESTS=<n>$ on its own line: the check passed unfixed; the line now sits alone inside a template literal
- **Discovery** (affects project): Under node --test --test-isolation=none, process.argv is [node, file1, file2, …]: a lib/*.mjs imported by a unit test needs the import.meta.url === argv[1] guard on its CLI (testcount.mjs lacked it; U1-01's 'inert' note was wrong)
- **Discovery** (affects run): A process.exit(0) in a unit test file ends node --test with rc 0 and its output unflushed; 00-unit-tier.sh now requires the reporter's `# unit tier: <n> tests` summary line and that PASS+FAIL equals n
- **Proposed change:** Kept (Minor, not fixed): #6 a unit tier stopped by TEST_FILE_TIMEOUT counts its 124 names as missing (run.sh greps only the .sh source for a cut file's names) and prints nothing until node ends; #8 needs card's 'no run is exit 1' is now the function's throw (the CLI catch is still hit by 59's `card nope`); #9 export checks are greps of `^export function`, and overlap.test.mjs's name still says node --check (an import parses it); #11 the duplicated inTZ helper in parked/view tests and the u1-/unit-metrics- tmp prefixes.
- **Proposed change:** Fixed Minor: #5 reporter.mjs usage line needs ./ (fixed), #7 a test's stray PASS/FAIL stdout line is now red via the summary count, #10 the decision says no unit test reads a CHECK_KEY_MAP path, #11 the literal U+2028 now \u2028 and eval.test.mjs's has() exact startsWith again.
- **Proposed change:** A follow-up: teach 82-key-map-lint to scan tests/unit/*.test.mjs (or map 00-unit-tier for CLAUDE.md/prompts/templates) so the no-mapped-path rule is linted, not just written.
- *06-U1-06 · claude-opus-5-5*

### 2026-11-03 22:02 · U1-05 · passes

Measured the unit tier before (ddee9e9 clone) and after: tier alone 1 node start, 0.24 s wall, 0.30 CPU-s (124 tests); the layer's remaining bash files 117 starts, 8.84 CPU-s (a miss vs <1 s); solo full suite 805.4 → 798.3 s, CPU +0.8 %. Table in findings-and-research/2026-11-03-unit-tier.md.

- **Files:** findings-and-research/2026-11-03-unit-tier.md, journal/decisions/2026-11-03-unit-tier.md
- **Verified:** strace/time -v runs with harness status RUNNING 1 each time; solo before 1141/1141, after 1163/1163, conformance PASS both; check.sh green (cached, files outside the key).
- **Tests:** 1163 → 1163
- **Dead end:** command time under systemd-run --scope — time is a shell builtin there; 'Failed to find executable'; use /usr/bin/time
- **Discovery** (affects run): systemd-run --scope needs /usr/bin/time, not `command time`
- **Discovery** (affects U1-06): 84-node-memo takes 27.6 s and 800+ node starts: it dominates any run that names every file still holding a node --input-type line
- *05-U1-05 · claude-sonnet-5-5*

### 2026-11-03 21:30 · U1-04 · passes

36 of the 38 scenario-file eval lines moved to tests/unit (new: needs, inbox, show, eval, overlap, treekey, page; extended: summary, entries, view, metrics, memlint, testcount) under their exact names; 2 kept (82 keymaplint, 84 pollu) and listed in the decision file. 11 split names added to the fixture, none removed. Full run 1163/1163, conformance PASS.

- **Files:** tests/unit/needs.test.mjs, tests/unit/inbox.test.mjs, tests/unit/show.test.mjs, tests/unit/eval.test.mjs, tests/unit/overlap.test.mjs, tests/unit/treekey.test.mjs, tests/unit/page.test.mjs, tests/unit/summary.test.mjs, tests/unit/entries.test.mjs, tests/unit/view.test.mjs, tests/unit/metrics.test.mjs, tests/unit/memlint.test.mjs, +4 more
- **Verified:** Full suite via check.sh: green in 805 s, 1163/1163, `PASS conformance: the split suite has every check the single-file suite had`; subset of all 26 touched files + 00-unit 434/434; node --test --test-isolation=none tests/unit/*.test.mjs 124/124 no ✖; eval-line count 2; fixture diff removes 0 lines; grep for CLAUDE.md|prompts/|templates/ in tests/unit prints nothing; each new/extended test file seen red on one wrong value first.
- **Tests:** 1152 → 1163
- **Discovery** (affects U1-05): Only 2 eval lines are left in tests/checks (82-key-map-lint keymaplint, 84-node-memo pollu): U1-05's after rows list just those two files beside the -pure- files
- **Discovery** (affects U1-06): U1-04 moved tests with assert.ok where the eval itself tested a predicate (endsWith, includes, <, <=): 9 lines, a U1-06 read; 81's treekey test names RULES.md for the eval's CLAUDE.md literal (default)
- **Discovery** (affects U1-06): 58's `needs list: …` keeps its name for the CLI half; the synthesize eval took a new unit name, so the name's 'nor with ended or a live driver' clause is checked only in needs.test.mjs (default; swap if the review prefers)
- **Discovery** (affects run): A bash run of 76-resolve-session prints `lib/resolve.sh: line 44: USAGE: unbound variable` to stderr while its checks pass (untouched by U1-04)
- *04-U1-04 · claude-opus-5-5*

### 2026-11-03 21:04 · U1-03 · passes

The 34 eval checks of the nine smaller -pure- files moved to tests/unit/{features,notify,parked,render,metrics,summary,deploy,backlog}.test.mjs and testcount.test.mjs under their exact names; 01 and 02 deleted; two splits gave 2 new names. 0 eval lines left in those files. Full run 1152/1152, conformance PASS.

- **Files:** tests/unit/features.test.mjs, tests/unit/notify.test.mjs, tests/unit/parked.test.mjs, tests/unit/render.test.mjs, tests/unit/metrics.test.mjs, tests/unit/summary.test.mjs, tests/unit/deploy.test.mjs, tests/unit/backlog.test.mjs, tests/unit/testcount.test.mjs, tests/checks/03-harness-parked-pure-report.sh, tests/checks/04-render-pure-sections-go.sh, tests/checks/05-metrics-pure-tokens-cache.sh, +6 more
- **Verified:** Each new/extended test file run once with a wrong expected value (sed into a zz-red copy): 3 ✖ lines each, then green; node --test --test-isolation=none tests/unit/*.test.mjs 72 pass 0 ✖; subset run 100/100 with every deleted name PASS (comm of deleted names vs PASS lines empty); fixture diff removes 0 lines; grep -c eval lines 0 in all 7 remaining files; Opus review: no Critical/Important, 3 Minor fixed (key order, file modes, headers); full run 1152/1152, conformance PASS, 804 s.
- **Tests:** 1150 → 1152
- **Dead end:** keeping 05's two resume checks as kept evals (their expected figures came from jq) — step 4 wants 0 eval lines in these files; the jq was plumbing for the expectation, read the same way in the test
- **Discovery** (affects U1-04, U1-06): summary.mjs and metrics.mjs evals lived in 11-deploy-guards: they went to summary.test.mjs and metrics.test.mjs (one file per module), not deploy.test.mjs
- **Discovery** (affects U1-04, U1-06): An eval's JSON.stringify equality checks key order; assert.deepEqual doesn't: add an Object.keys(...).join() assert where order may matter
- **Discovery** (affects U1-04, U1-06): Rewriting a check file via `> f.new && mv` drops its 100755 mode: chmod +x after, or edit in place
- *03-U1-03 · claude-opus-5-5*

### 2026-11-03 20:41 · U1-02 · passes

The 37 evals of 51-view-pure and 12-journal-pure moved to tests/unit/view.test.mjs (20), entries.test.mjs (14) and memlint.test.mjs (2) under their exact names, each compared value asserted; the CLI parts stay bash checks (3 under new names, the validate cases joined the vx check). Full run 1150/1150, conformance PASS.

- **Files:** tests/unit/view.test.mjs, tests/unit/entries.test.mjs, tests/unit/memlint.test.mjs, tests/checks/51-view-pure.sh, tests/checks/12-journal-pure-e4-entrys.sh, tests/fixtures/check-names.txt, journal/decisions/2026-11-03-unit-tier.md
- **Verified:** each test file run red on one wrong value (✖ + diff), then green; node --test --test-isolation=none tests/unit/*.test.mjs 37/37, no ✖; grep -c 'node --input-type=module' 0 in both check files; fixture diff removes 0 lines; Opus review: 0 Critical/Important, 1 Minor fixed (export grep accepts async); check.sh full: green 796 s, 1150/1150, both conformance lines PASS
- **Tests:** 1146 → 1150
- **Dead end:** test names typed from the check names as they read — two 51-view names hold a literal '\'' (bash double quotes keep it): the subset's conformance failed until the test names kept those bytes
- **Discovery** (affects U1-03, U1-04, U1-06): A check that is an eval plus a CLI run splits: the part its name describes keeps the name, the other gets a new fixture name (decisions/2026-11-03-unit-tier, default); 12-journal gained 3 bash names and 1 unit name.
- **Discovery** (affects U1-03, U1-04): An eval run under TZ=… node becomes a test that sets process.env.TZ and restores it in finally (node rereads it on assignment); tests stay synchronous so the zone can't leak.
- **Discovery** (affects U1-03, U1-04): assert.throws(fn, /re/) tests String(err) ("Error: …"): an anchored message regex needs { message: /^…/ }.
- **Discovery** (affects run): Memlint counts the Gotchas comment line: CLAUDE.md's section is at its 15-line cap now; a new line must replace one.
- **Question for Michael:** Default: a check that was an eval plus a CLI run now keeps its old name on the part the name describes and the other part gets a new fixture name (4 new names in U1-02). Keep that, or should both parts stay under one name (the CLI run spawned from the unit test)? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03-2/slot-0/journal/decisions/2026-11-03-unit-tier.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03-2/slot-0/tests/checks/12-journal-pure-e4-entrys.sh
- *02-U1-02 · claude-opus-5-5*

### 2026-11-03 20:16 · U1-01 · passes

The unit tier: tests/unit/reporter.mjs (PASS/FAIL lines, the failure indented), tests/checks/00-unit-tier.sh (one node --test process, own N/M, a no-FAIL-line guard, TEST_UNIT_DIR), testcount's eval moved to tests/unit/testcount.test.mjs under its old name, CLAUDE.md's node ≥ 22.8 and tier lines, the decision file.

- **Files:** tests/unit/reporter.mjs, tests/unit/testcount.test.mjs, tests/checks/00-unit-tier.sh, tests/checks/33-suite-runner.sh, tests/checks/79-suite-length.sh, tests/fixtures/check-names.txt, CLAUDE.md, journal/decisions/2026-11-03-unit-tier.md
- **Verified:** check.sh full run green in 792 s: 1146/1146, PASS conformance: the split suite has every check the single-file suite had (fixture 1140 -> 1145 lines, no removal); the first full run was red only on memlint (Gotchas 16 > 15, from my new line, dropped). Watched red first: 33-suite-runner 16/20, 79-suite-length 13/14. 00-unit-tier prints the testcount name once; bash -n and node --check clean; node --test tests/unit/*.test.mjs no ✖.
- **Tests:** 1141 → 1146
- **Dead end:** node --test --test-isolation=none tests/unit/ (a directory, as the spec and steps name it) — node 24 imports the directory as a module: ERR_UNSUPPORTED_DIR_IMPORT and a ✖ line; the glob tests/unit/*.test.mjs works and is what CLAUDE.md and the decision name
- **Dead end:** a Gotchas line on the unit tier being one process (console.log, shared module state) — Gotchas already held 15 lines; memlint failed 16 > 15; the decision file states the rule, so the line was dropped
- **Discovery** (affects U1-02, U1-03, U1-04, U1-05, U1-06): `node --test tests/unit/` fails on node 24.21 (ERR_UNSUPPORTED_DIR_IMPORT, prints ✖): every later step's `node --test --test-isolation=none tests/unit/ prints no ✖ line` must read `tests/unit/*.test.mjs`
- **Discovery** (affects U1-06, run): The CLAUDE.md check went in tests/checks/79-suite-length.sh (already in CHECK_KEY_MAP for CLAUDE.md), not 33-suite-runner.sh: a CLAUDE.md read there would have to join the map (82-key-map-lint).
- **Discovery** (affects U1-02, U1-03, U1-04, U1-05, U1-06): The reporter prints a non-assertion error's stack without node: frames, and a skipped test as `PASS <name> (skipped: <reason>)` (run.sh strips the suffix); decisions/2026-11-03-unit-tier has empty `## Kept evals` and `## Measured` sections for U1-02..05.
- **Proposed change:** U1-01 to U1-06 steps: `node --test --test-isolation=none tests/unit/` should read `node --test --test-isolation=none tests/unit/*.test.mjs` (the directory form is red on node 24)
- **Proposed change:** U1-01 step 1: the `grep -q 'node ≥ 22.8' CLAUDE.md` check belongs in a CHECK_KEY_MAP file for CLAUDE.md (it is in 79-suite-length.sh), not 33-suite-runner.sh
- *01-U1-01 · claude-opus-5-5*

### 2026-11-03 19:35 · init · passes

6 features, one milestone U1: U1-01 the node:test reporter, tests/checks/00-unit-tier.sh, tests/unit/ (testcount's eval first), CLAUDE.md, the decision file; U1-02 the 37 evals of 51-view-pure and 12-journal-pure; U1-03 the nine smaller -pure- files; U1-04 the scenario files' evals, kept ones listed; U1-05 the before/after table (sonnet); U1-06 review + simplify, docs.

- **Discovery** (affects U1-01, U1-03, run): Under `node --test --test-isolation=none <glob>` process.argv is [node, <glob>] (checked 2026-11-03 in /tmp): lib/testcount.mjs's CLI tail (process.argv.slice(2)) is inert on import, so no lib/ guard is needed for the move; a module that reads argv[1] would not be.
- **Discovery** (affects U1-01): A test file that throws at import gets node's own test:fail event for the file, so the reporter prints `FAIL <absolute file path>`; the `exited <rc> with no FAIL line` guard in 00-unit-tier.sh fires only for a non-zero exit with no FAIL line, e.g. `process.exit(3)` at import. U1-01's check uses process.exit for the guard line and accepts either shape for a throw.
- **Discovery** (affects U1-04): CHECK_KEY_MAP in .harness/config.sh maps CLAUDE.md to 39-memlint-m4, 37-memory-prompts-m2 and 79-suite-length, and 82-key-map-lint lints only tests/checks/*.sh: a unit test that read the repo's CLAUDE.md, prompts/ or templates/ would escape a partial run. Such an eval (37-memory-prompts-m2 has two) stays a bash check.
- **Discovery** (affects U1-05): The base commit for U1-05's before rows is `git merge-base origin/main HEAD` (ddee9e9, main at run start). The measured before row for the unit layer is findings-and-research/2026-11-03-redesign-baseline.md §5.3 (eleven -pure- files: 149 node execs, 9.35 CPU-s, 3.16 s wall, the runner and tests/lib.sh included), not the spec's 108 / 4–6 s; `tests/run.sh 01- 02-` is a substring match, so the files need their full names.
- **Discovery** (affects U1-05): At init `harness status` showed this run alone under RUNNING and the queue runner going; the full suite took 797 s at init (1141 checks), so U1-05's two solo runs are about 27 min of its session.
- **Discovery** (affects U1-01): The reporter spike (/tmp, deleted): node expands the quoted `*.test.mjs` glob itself, `--test-reporter=<path> --test-reporter-destination=stdout` prints only the reporter's lines on stdout, and the assert diff for `assert.equal(1, 2)` is `Expected values to be strictly equal:` then a blank line then `1 !== 2`, each indented two spaces by the reporter.
- **Proposed change:** CLAUDE.md `## Gotchas` is at memlint's cap of 15 entries: the init could not add the node --test argv fact (it is a run discovery instead); retire one line before the next durable gotcha.
- *00-init · claude-fable-5-1*
