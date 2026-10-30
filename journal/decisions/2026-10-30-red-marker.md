# A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing

*(2026-10-29, run `agent-harness-2026-10-29-3`, S1-03; spec `docs/specs/2026-10-30-suite-time.md` fix 2, plan
`docs/plans/2026-10-30-S1-suite-time.md` §5)*

- **Finding:** a red full run wrote nothing, so the next full call on the same tree ran the suite again. Every retry
  after a post-session red paid it: `run_init` before the retry session ran 953 s (R2-01) and 993 s (R1-02) in 10-29-2
  and 824 s (N2-02) in 10-29, on a tree the harness had run twice minutes before (the first run and the rerun guard's
  rerun). The rerun guard had already answered the one question a second run could: the red was not a flake.
- **Choice:**
  - `lib/check.sh`'s full form, after a red whose runs `why` both called `exit <rc> after <s> s`, writes
    `red-<key>` beside `green-<key>` in the cache, four lines: the exit code it returns (the rerun's, when there was
    one), the first run's `HARNESS_FAILED=` names (empty without the line), `wall <s>` (the green marker's wall:
    the first run's, a whole-suite rerun's after one), the `check: RED (…) — last lines of <out>:` line as printed.
  - The full form, finding no `green-<key>` but a `red-<key>`, prints `check: RED (cached for this code tree: <names |
    whole suite>)`, then the stored RED line, appends a `cached` row to `check-runs.log` and exits with the stored
    code. It runs nothing, reruns nothing and writes no `check.out`. A marker is only ever read for its own key: any
    edit makes a new key, and the suite runs.
  - A green run removes `red-<key>` (it can't exist for a green key unless planted; a planted one must not survive).
  - The subset form (`check.sh <args>`) reads neither marker: its caller is iterating on the tree.
  - The driver honours it as it honours any red (S1-04): a retry's `run_init` on the tree the post-session run found
    red answers from the marker (`init.out` has the cached line, run.log `suite red before the session`, no third
    run); `run_init fresh` (verify, a disjoint re-base) removes `red-<key>` with `green-<key>`, so the verified tree
    always runs in full.
  - *default:* the marker doesn't store the first run's output; `check.out` and `check-<key>.out` keep it in
    scratch for the run's lifetime, and the names and RED line are what the session acts on.
  - *default:* the stored RED line keeps its scratch path (`last lines of <out>:`) as printed, though a cached answer
    after scratch is gone (a continued run) names a file that may no longer be there.
  - *default:* a red with no rerun (`CHECK_RERUN=off`, or `failed` with no names) is cached too: the project chose
    to trust one run, and the cached answer is that run's.
- **Rejected:**
  - **Caching a timeout or a cap kill:** a timeout may be the box's load and a cap kill the scope's; neither says the
    tree is red, so the next call runs (and the rerun guard skips both for the same reason).
  - **Clearing the red marker on a timer:** the tree is the same tree; nothing about it changes with time. The
    driver's `run_init fresh` (verify, disjoint re-base) removes it with `green-<key>` (S1-04), so the verified tree
    always runs in full.
  - **A red marker that stores the whole output:** a suite's output is large and lives in scratch already; the marker
    outlives scratch and needs only what the cached answer prints.
