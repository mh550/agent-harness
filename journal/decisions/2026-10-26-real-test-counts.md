# Real test counts: one rule per runner, proven on a fixture each; a suite with no count is said once per run

*(2026-10-26, run agent-harness-2026-10-26-2, feature F1-02; spec `docs/specs/2026-10-21-retro-fixes.md` R1, plan
`docs/plans/2026-10-26-F1-driver-cli.md` § R1 and D2, D3)*

- **Finding:** `lib/testcount.mjs` read node:test's `# pass N` and otherwise the last `N passed` in the output. That
  was never checked on real output. On cargo it took the last `test result: ok. N passed;` line, so a crate's doc-tests
  (`1 passed`) stood for the whole suite; on `go test -v` it found nothing. And a suite whose output has no count left
  the report's `tests start → end` at `? → ?` with nothing saying why.
- **Choice:**
  - **The first rule that matches wins**, in this order: node:test `^(ℹ|#) pass N`; cargo, the **sum** of every
    `test result: <word>. N passed;` line (one per test binary, doc-tests included; before the generic rule, whose
    `N passed` would take the last); jest/vitest, the `Tests:` line's `N passed` (never `Test Suites:`, whatever the
    order); go, the count of `--- PASS: ` lines (subtests, indented, count too); then the last `N passed` /
    `N tests passed` (pytest, mocha and the like).
  - **One fixture per runner** in `tests/fixtures/check-{node-test,pytest,jest,cargo,go}.txt`, line 1 a `#` comment
    saying where the text came from. node:test (node 24), pytest (9.1.1) and cargo (1.99.0) were run on this box on
    scratch tests; jest and go are not installed, so theirs are copied from the code that prints them (jest's
    `packages/jest-reporters/src/getSummary.ts`, go's `src/testing/testing.go`). One check each under
    `# ---- test counts, pure (R1)` in `tests/run.sh`; written first, cargo (`1`) and go (nothing) failed on the old code.
  - **D3 *default*: go is counted from `--- PASS` lines only**, so it needs `go test -v`; plain `go test` prints only
    `ok <pkg> <time>` and is a no-match (and is noted, below).
  - **`test count: no match in the suite's output (tests start/end stay unknown)`** in `harness-log.md` when a suite
    run in `run_init` wrote `check.out` and nothing in it matches, **once per run** (`$STATE/testcount-nomatch`, which
    outlives segments). A cached green writes no `check.out` and is not a no-match.
  - **D2 *default*: empty output is a no-match too** (the stub demo's `test ! -f BROKEN` is one), so a `? → ?` always
    has its line.
- **Rejected:**
  - **Fixtures from real runs' `check.out`** (what the spec asked): they live in `~/.local/state/harness`, which no
    session may read. Generated and documented output shows the same lines.
  - **Counting go's `ok <pkg>` lines:** those are packages, not tests.
  - **A note on every no-match:** `run_init` runs before every session and verify; one line says it.
  - **A `HARNESS_TESTS=<n>` contract** for suites no rule reads: the memory spec's §C builds it on this, not here.
