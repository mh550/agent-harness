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
    whole suite>)`, then the stored RED line with its `— last lines of <out>:` tail replaced: `— last lines of
    <scratch>/check-<key>.out (this tree's first run):` and those lines when that file is still there, else `— its
    output is gone from scratch: check.sh <names> shows the failures` (`check.out` and `check-rerun.out` may by then
    be another tree's). It appends a `cached` row to `check-runs.log` and exits with the stored code (1 when line 1
    is no exit code from 1 up). It runs nothing, reruns nothing and writes no `check.out`. A marker is only ever read for its own key: any
    edit makes a new key, and the suite runs.
  - Neither run's code is a signal's (128 up: a kill the scope didn't see, a TERM): those are the box's, as a
    timeout is. Both markers are written to a temporary file and moved into place, so a concurrent reader sees a
    whole file or none.
  - A red found around a failed init isn't the tree's verdict: `run_init` whose init failed removes the `red-<key>`
    its suite wrote (note `suite red under a failed init: not cached (the next init runs it)`), and the first
    `run_init` after a failed init (`init-failed` in the lane's directory, the driver's in the state dir) removes the
    tree's `red-<key>` before its suite, so a red the session's post-session run found under the broken init runs
    again.
  - A green run removes `red-<key>` (it can't exist for a green key unless planted; a planted one must not survive).
  - The subset form (`check.sh <args>`) reads neither marker: its caller is iterating on the tree.
  - The driver honours it as it honours any red (S1-04): a retry's `run_init` on the tree the post-session run found
    red answers from the marker (`init.out` has the cached line, run.log `suite red before the session`, no third
    run); `run_init fresh` (verify, a disjoint re-base) removes `red-<key>` with `green-<key>`, so the verified tree
    always runs in full.
  - *default:* the marker doesn't store the first run's output; `check.out` and `check-<key>.out` keep it in
    scratch for the run's lifetime, and the names and RED line are what the session acts on.
  - *default:* the stored RED line keeps its scratch path (`last lines of <out>:`) as printed; the cached answer
    prints it with the tail above.
  - *default:* nothing else outside the key clears a red (a port another lane holds, a tool installed since): the
    tree's next edit, a verify or a disjoint re-base runs it. A session has no form that runs the full suite on a
    cached red tree; asked as a question.
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

Updated in place 2026-10-30 (S1-05 review, I1/I2, M1/M2): a red around a failed init isn't kept; the cached answer
shows this tree's own output or says it is gone; a signal's code isn't cached; atomic marker writes.
