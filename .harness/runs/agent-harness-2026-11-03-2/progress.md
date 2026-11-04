<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-03-2` (agent-harness)

What this file is: the run's journal, newest entry first, rendered from `entries.jsonl` for Michael's phone. One milestone, **U1, the unit tier** (spec `docs/specs/2026-11-03-unit-tier.md`; phase 1 of `docs/plans/2026-11-03-test-suite-redesign.md`): the 111 `node --input-type=module` evals in the check files become `tests/unit/<module>.test.mjs` files under `node --test --test-isolation=none` (one node process), reported into `tests/run.sh` through `tests/unit/reporter.mjs` and `tests/checks/00-unit-tier.sh`, every check name unchanged (the full run's conformance line is the proof).

How to read the feature list (`feature_list.json`): six features in series, U1-01 the mechanism, U1-02 to U1-04 the move file by file, U1-05 the measurement (`findings-and-research/2026-11-03-unit-tier.md`, solo suites before and after, no other suite alive), U1-06 the review + simplify with the docs. Each feature's steps are what its verifier re-runs; `passes` flips when its session's suite is green. The milestone merges into `main` when all six pass and the verify is green.

To steer: edit `INBOX.md` on this branch (first line `status: pause` or `status: stop`; answers under `## Answers`). The harness pulls before every session.

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
