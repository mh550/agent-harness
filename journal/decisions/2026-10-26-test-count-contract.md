# A test-count contract: a suite's own `HARNESS_TESTS=<n>` line wins over scraping its summary

*(2026-10-26, run agent-harness-2026-10-25-memory, features M5-01 and M5-02; spec `docs/specs/2026-10-25-memory.md` M5, which
takes `docs/specs/2026-10-22-retro-followups.md` §C as written; extends decisions/2026-10-26-real-test-counts)*

- **Finding:** R1's parsers scrape a runner's human-readable summary. That breaks when a runner changes its wording or
  a project uses one that isn't listed (portfolio_site's 1115-test jest suite read as `6 → 6` before R1), and nothing
  said whether a count was scraped or missing.
- **Choice:**
  - **The contract wins:** `lib/testcount.mjs` takes the **last** whole line `HARNESS_TESTS=<n>` in the suite's output
    (a wrapper may print one after its runner's; from column 0, so a coloured or prefixed line is scraped instead,
    and a count past 2^53 is no contract: M5 review), then R1's rules in their order, then the generic `N passed`.
    `countSource(text)` returns `{ n, source }`; `testCount(text)` is its `n`, so `lib/check.sh`'s green line and
    markers are unchanged. `testcount.mjs <file> --source` prints `<n> tests · <source>`, source one of `contract`,
    `node`, `cargo`, `jest`, `go`, `generic`, `none`; with no count, `? tests · none` (*default*: `?` as the report
    prints an unknown count).
  - **Said once per run:** `run_init` notes the first suite with a `check.out`: `test count: HARNESS_TESTS contract`,
    `test count: parsed (<runner>)` (pytest and the like say `parsed (generic)`), or R1's `no match` line unchanged.
    Marker `testcount-source` holds the source; a run that already has R1's `testcount-nomatch` isn't noted again
    (*default*).
  - Fixtures: `tests/fixtures/check-jest-contract.txt` (the jest fixture plus `HARNESS_TESTS=1115`) and
    `tests/fixtures/check-agent-harness.txt` (this run's own `check.out` at init, last 30 lines, `395/395 checks
    passed`, as the feature's step says; the file is copied, not retyped). Updated in place 2026-10-27: the first
    attempt copied the scratch `check.out` after the suite had grown (474) and verify failed the step; scratch no longer
    held the init output, so the fixture is the same suite re-run on the run's start tree (`ac49ba8`).
  - **`tests-end` after every session (M5-02):** `finish()`'s two sources (the tree's green marker, else its
    `check-<key>.out`) are one function, `tests_end`, which the driver also calls after each coding session's `green`
    check. A continued run's summary showed the last segment's end until `finish`; now `harness status` (`· tests
    <start> → <end>`), `harness report` and each session's `harness-log.md` line (`· tests <n>`) show the latest tree's.
    Only a green tree has a count (its marker exists): a red one's output may count what passed, or a contract line
    printed whatever the outcome (M5 review). Mid-run, a tree with no count keeps the last known one; only `finish`
    clears it (*default*: a session that ran no full suite, or left it red, says nothing about the count). `tests-start` stays the first `run_init`'s count, never rewritten:
    report.md's cell reads `<start> → <end> (baseline at run start → end)`, `harness trends`' column
    `tests (baseline → end)`.
- **Rejected:** a structured report option (`TEST_REPORT=<path+format>`, reading `jest --json`, `pytest --report-log`
  or `go test -json`) for now: a project's check can print the contract line from its own report, with no parser per
  format in the harness. Taking the first `HARNESS_TESTS=` line instead of the last: a wrapper prints its total last.
  Rebasing `tests-start` at each `harness continue`: the run's start is the baseline Michael compares against; a
  segment's own start is in its first session's `harness-log.md` line. Running the suite after a session that didn't
  pass, to have a count for its tree: the next `run_init` runs it anyway.

Updated in place 2026-10-26: M5-02 added `tests_end` after every session and the baseline labels.
