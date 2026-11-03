# Test runners small teams use now for a bash-plus-node project: a cited survey (2026-11-03)

Phase 0.3 of `docs/specs/2026-11-03-test-suite-redesign.md`. Primary sources only (project docs, READMEs, release
pages), each opened and read on 2026-11-03; no listicles. The reader's situation: 86 bash check files (`check "<name>"
'<expr>'`, 1,101 names, one process per file under `tests/run.sh`), 108 `node --input-type=module -e` evals as the unit
layer, node 24.21 on the one box, the repo rule "node ≥ 20 standard library only, no npm packages".

## Summary table

| runner | start-up model | assertions | reporting | parallelism | filtering | adoption cost here | how a session runs a subset |
|---|---|---|---|---|---|---|---|
| **`node --test`** (`node:test`, built in) | one child process per test file by default (`--test-isolation=process`); `--test-isolation=none` (v22.8.0) imports every file into the runner process and runs top-level tests one at a time: **one process for the whole unit tier** | `node:assert/strict`: `deepStrictEqual`, `throws`, `rejects`, `match`, `partialDeepStrictEqual` (v22.13); `+ actual - expected` diff in strict mode; snapshots (`--test-update-snapshots`, stable v22.13) | `spec` (default), `tap`, `dot`, `junit`, `lcov`; a custom reporter is a ~15-line `.mjs` streaming `test:pass`/`test:fail`, so `PASS <name>` per test is trivial | files: `--test-concurrency` (default cores − 1, ignored under `isolation=none`); in a file: `test({ concurrency })`, default serial | `--test-name-pattern`, `--test-skip-pattern` (v22.1), `--test-only`, globs, `--test-shard i/n`, `--test-rerun-failures <file>` (v24.7) | **zero install**; coverage (`--experimental-test-coverage`, V8, JS only) still Experimental; the CLAUDE.md floor rises to 22.8 for `isolation=none` | `node --test tests/unit/features.test.mjs` · `node --test --test-name-pattern "gc"` |
| **Vitest 5.1.0** (2026-11-02) | a Vite server in the main process; each file in a worker from a pool (`forks` default, `threads`, `vmThreads`, `vmForks`); `isolate: false` reuses one worker's module state across files ("the fastest option if tests tolerate shared state"); workers stay warm *between* runs only in watch mode | chai + Jest-compatible `expect`, `toMatchSnapshot`, `toMatchInlineSnapshot`, configurable diff | default, tree, verbose (one line per test), dot, json, junit, tap, tap-flat, html, minimal/agent, github-actions | files in parallel (`maxWorkers`), `describe.concurrent`/`test.concurrent` (`maxConcurrency` 5), `--shard` | path substring, `-t` regex, `file:line`, `--changed [since]`, `vitest related <files>`, `--bail` | **breaks "no npm"**: `vitest` + 13 deps + peer `vite` (rolldown, lightningcss, postcss) in a `node_modules` per worktree (six worktrees on this box today), a lockfile and registry access; Node ≥ 22.12; coverage needs `@vitest/coverage-v8` | `npx vitest run gc -t "prunes" --reporter=tap-flat` |
| **bats-core 1.14.0** (2026-07-21) | one bash process per `@test`; a file is evaluated n+1 times; no daemon or warm process; `--jobs N` needs GNU parallel | `run` + `$status`/`$output`/`$lines`; `assert_*` from bats-assert (needs bats-support; three helper repos to vendor) | pretty, tap, tap13, junit; `--report-formatter` + `--output <dir>`; TAP is one line per test | `--jobs N` across and within files (each switchable off) | `--filter <regex>`, `--filter-tags`, `--filter-status failed` (all 1.8.0, 2022-09-15); `BATS_TEST_TIMEOUT` | rewrite 86 files into `@test` blocks; vendor three helper repos; `@test` is not shell-lint friendly; the same process-per-test model this suite already has, with fewer features than `tests/run.sh` (no per-file timeout group kill, no conformance) | `bats -f 'gc' tests/checks/` · `bats --filter-status failed tests/checks/` |
| **`cargo test`** (bundled) | one libtest binary per target, targets run serially; tests in a binary are threads of one process; stdout captured | `assert!`/`assert_eq!` (prints left/right), `#[should_panic]`, `Result`-returning tests | libtest text, one `test name ... ok` line; no JUnit/JSON stated | `-- --test-threads=N`; no sharding flag | name substring; `-- --ignored`; no rerun-failed flag | rustup + a Cargo project; tests build in the `test` profile (inherits `dev`, incremental) | `cargo test hash` · `cargo test -- --test-threads=1` |
| **cargo-nextest 0.9.151** (2026-11-02) | builds with `cargo test --no-run`, lists tests per binary, runs **each test in its own process**, in parallel; reuses the built binaries | the same libtest assertions | one line per test (`PASS`/`FAIL`/`SLOW [time] name`), JUnit via `[profile.<p>.junit]`, libtest-json experimental | `-j N` (default num-cpus), `--partition hash:m/n` | substrings, `-E 'test(x) & package(y)'` filtersets, `--run-ignored`, `--rerun`/`-R`, `--retries N`, per-test timeouts in `.config/nextest.toml` | one extra binary (`cargo install cargo-nextest --locked`, Rust ≥ 1.91, or a prebuilt musl tarball) | `cargo nextest run -E 'test(/^hash::/)'` · `cargo nextest run -R` |

**What relaxing "no npm packages" would buy:** Vitest's warm worker pool with `isolate: false` and its `--changed`/`related`
selection (a module graph the bash suite lacks). What it costs: a `node_modules` per worktree (installed in every lane
slot and every session worktree, with registry access at install), a lockfile to keep, Node ≥ 22.12, and a second
assertion dialect beside `node:assert`. For a unit tier of ~110 tests over 20 pure modules, `node --test` with
`--test-isolation=none` is the same one-process model at zero install. **Recommendation: keep the rule;** nothing in
this plan needs a package.

## Findings with sources

### `node --test` (https://nodejs.org/api/test.html, https://nodejs.org/api/cli.html, https://nodejs.org/api/assert.html)

1. Process model. cli.html `--test-isolation=mode`: "Added in: v22.8.0 … v23.6.0: renamed from `--experimental-test-isolation`";
   "When `mode` is `'process'`, each test file is run in a separate child process. When `mode` is `'none'`, all test files run
   in the same process as the test runner. The default isolation mode is `'process'`." test.html, "Test runner execution
   model": "When process-level test isolation is disabled, each matching test file is imported into the test runner
   process. Once all test files have been loaded, the top level tests are executed with a concurrency of one."
   `--test-concurrency` (v20.10.0): "If `--test-isolation` is set to `'none'`, this flag is ignored and concurrency is one."
2. Assertions. assert.html: `deepStrictEqual` (v1.2.0), `throws`, `rejects` (v10), `match` (v13.6/v12.16),
   `partialDeepStrictEqual` (v23.4, v22.13); "In strict assertion mode, error messages for objects display a diff."
   Snapshots: test.html "Added in: v22.3.0 … v23.4.0: no longer experimental"; `--test-update-snapshots`.
3. Reporting. test.html "Test reporters": `spec` default (v23.0.0 changed the non-TTY default from `tap` to `spec`),
   `tap`, `dot`, `junit`, `lcov`; `--test-reporter` / `--test-reporter-destination` (v18.15/v19.6), "paired according
   to the order they were specified"; the custom-reporter example yields `test ${event.data.name} passed` on
   `test:pass`. `test:summary` carries `counts` and `success`. TAP version and text stability: not stated.
4. Parallelism. Within a file `test()` option `concurrency`: "If `false`, only one test runs at a time … Default:
   `false`"; concurrency is event-loop interleaving, not threads.
5. Filtering. `--test-name-pattern` (v18.11), `--test-skip-pattern` (v22.1), `--test-only` (v18.0/v16.17), `--test-shard`
   (v20.5/v18.19); patterns are JS regexes and "do not change the set of files that the test runner executes"; globs in
   double quotes; the default patterns match `**/test/**` and `*.test.{cjs,mjs,js}`, not a bare `tests/` directory.
6. Coverage. `--experimental-test-coverage` (v19.7/v18.15), "Stability: 1 - Experimental"; `--test-coverage-include/
   exclude` (v22.5); thresholds `--test-coverage-lines/branches/functions` (v22.8), exit 1 under the threshold; V8 JS
   coverage only (a bash line spawned by a test is invisible to it).
7. Watch and rerun. `--watch` stable v22.0/v20.13; `--test-rerun-failures <file>` "Added in: v24.7.0" ("the test runner
   will only run tests that have not yet passed").
8. Global setup. `--test-global-setup` "Added in: v24.0.0. Stability: 1.0 - Early development."
9. Floors per feature: `--test`, patterns, reporters, shard, concurrency, watch: 20; `isolation=none`: 22.8; skip-pattern 22.1;
   snapshots 22.3 (stable 22.13); coverage include/exclude 22.5, thresholds 22.8; global setup 24.0; rerun-failures 24.7.
   Everything is on this box's 24.21. No collection ("list only") mode exists on any page.

### Vitest (https://vitest.dev/guide/, /config/, /guide/improving-performance, /guide/cli, /guide/coverage, github.com/vitest-dev/vitest/releases)

1. `pool`: `'threads' | 'forks' | 'vmThreads' | 'vmForks'`, default `'forks'` (config/pool). improving-performance, "Test
   isolation": with default isolation "every file gets a fresh worker"; "disabling isolation will improve the speed of your
   tests"; "Prefer `isolate: false` with `threads` if the tests tolerate shared state". `fileParallelism` default true.
2. v5.1.0 published 2026-11-02; v5.0.0 (2026-09-03) "Require Node.js 22 and Vite 6.4"; guide: "Vitest requires Vite
   >=v6.4.0 and Node >=v22.12.0".
3. chai assertions plus Jest-compatible `expect`; `toMatchSnapshot`, `toMatchInlineSnapshot`, `toMatchFileSnapshot`
   (api/expect); `diff` config (config/diff).
4. Reporters (guide/reporters): default, tree, verbose ("prints every test case once it is finished"), dot, json, junit,
   tap, tap-flat, html, hanging-process, github-actions, minimal/agent ("Enabled automatically inside AI coding agents"), blob.
5. `maxWorkers` number or percent (config/maxworkers); `describe.concurrent`, `test.concurrent`, `maxConcurrency` 5.
6. Filtering (guide/filtering, guide/cli): path substring, `-t` regex, `file:line`, `--changed [since]`, `vitest related
   <files>`, `--shard`, `--bail`.
7. Coverage: providers v8 (default) and istanbul, each an extra package (`@vitest/coverage-v8`); thresholds; `--coverage`.
8. Install: `npm install -D vitest`; registry: 13 runtime deps plus peer `vite`; node_modules size not stated.
9. Watch: default `!process.env.CI && process.stdin.isTTY`, off when an AI agent is detected; nothing survives a `vitest run`.

### bats-core (https://bats-core.readthedocs.io/en/stable/, github.com/bats-core/bats-core, bats-assert, bats-support)

1. writing-tests: "Each Bats test file is evaluated n+1 times … executes each one in its own process." usage: `--jobs`
   "requires GNU parallel or shenwei356/rush"; `--no-parallelize-across-files`, `--no-parallelize-within-files`.
2. `run`, `$status`, `$output`, `$lines`; bats-assert README (v2.2.4, 2025-10-14) "has one dependency … bats-support";
   `assert_output`, `assert_line`, `assert_regex`, …
3. `--formatter pretty|tap|tap13|junit`, `--report-formatter`, `--output <dir>`, `--timing`.
4. `--filter <regex>`, `--filter-tags`, `--filter-status failed|missed` (CHANGELOG 1.8.0, 2022-09-15, which also added
   `BATS_TEST_TIMEOUT`).
5. `setup_file`/`teardown_file`; `setup_suite` (1.7.0).
6. v1.14.0, 2026-07-21 (`--errexit`; `run` honours `set -e`). Install: distro package, `brew`, `npm`, or `git clone … &&
   ./install.sh <prefix>`; helpers as git submodules.
7. gotchas page: pipes under `run` (`bats_pipe`), background tasks holding FD 3, negated statements under `-e`, `[[ ]]`
   not failing, teardown's disabled ERREXIT, `@test` not lintable.
8. No daemon, server, watch or persistent-worker mode on any page.

### `cargo test` and cargo-nextest (https://doc.rust-lang.org/cargo/commands/cargo-test.html, book ch11, https://nexte.st/docs/)

1. cargo-test: "creates a special executable by linking your code with libtest … runs all functions annotated with
   `#[test]` in multiple threads"; multiple targets "run serially"; `--jobs` "does not affect how many threads are used
   when running the tests". nextest "How nextest works": builds with `cargo test --no-run`, lists, then will "execute each
   individual test in a separate process, in parallel"; "Why process-per-test?": global state, memory corruption, "one
   test timing out should not cause others to be killed", per-test lifecycle.
2. ch11-01: `assert_eq!` prints `left`/`right`; `#[should_panic(expected = …)]`; `Result`-returning tests.
3. nextest running page: one line per test with wall time in brackets; `SLOW` over 60 s; JUnit via config; libtest-json
   experimental. Per-test overrides: `retries`, `slow-timeout`, `threads-required`, `leak-timeout`.
4. `-- --test-threads=N`; nextest `-j N` default num-cpus; `--partition hash:m/n`.
5. cargo: name substring, `-- --ignored`; nextest filtersets `-E`, `--run-ignored`, `--rerun`/`-R`, `--retries`.
6. `CARGO_TARGET_DIR` "Directory for all generated artifacts … Defaults to `target` in the root of the workspace";
   build-cache page names sccache for sharing across workspaces and does not say one target dir may be shared across
   checkouts (it works in practice: measured below in the baseline file, 0.17 s for a second checkout). `[profile.test]
   inherits = "dev"` (opt-level 0, incremental). The cargo-test command page's "enables some optimizations" line
   contradicts the profiles reference; the reference is normative. Toolchain size: not stated.
7. nextest: `cargo install cargo-nextest --locked` (Rust ≥ 1.91) or a prebuilt tarball; 0.9.151, 2026-11-02.
