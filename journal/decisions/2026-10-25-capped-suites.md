# Suites run capped: check.sh in its own scope, under a timeout, with a RED line per kill

*(2026-10-25, run agent-harness-2026-10-25-lifecycle, feature L1-05; spec `docs/specs/2026-10-25-resource-lifecycle.md`
§L1 item 3, plan `docs/plans/2026-10-25-L1-capped-sessions.md` §3, §4, §7, §8.2, §12 D6; the OOM finding in
`findings-and-research/2026-10-24-oom-from-unbounded-test-diff.md`)*

- **Finding:** `lib/check.sh` ran the suite as a bare `bash -c "$cmd"` (the subset form the same): no memory or time
  limit. On 2026-10-24 one red-phase `deepEqual` diff grew to 6.5–9.6 GB four times, and the kernel killed codium,
  claude-desktop and python instead of the test. A session's own 6G scope (L1-03) doesn't cover it: a session's
  `check.sh` starts its own scope in `app.slice`, outside the session's. And a hung suite showed only as a session
  that never came back.
- **Choice:**
  - **Both forms run in `harness-<run>-check-<pid>`** (`<pid>` = check.sh's `$$`) through `scope_run`, `MemoryMax=
    CHECK_MEMORY_MAX` (default `3G`), `MemorySwapMax` 1G (`scope_run`'s default; `SESSION_SWAP_MAX` doesn't reach
    check.sh), `OOMPolicy=continue`, and the scope is stopped after the suite returns, so a server or watcher a test
    started goes with it. Inside it, `timeout -k 30s CHECK_TIMEOUT` (default `15m`) around `bash -c <CHECK_CMD>`.
  - **The prefix comes from `prompt_env`**: `HARNESS_SCOPE_PREFIX=harness-<sanitised run>`, `HARNESS_CHECK_MEMORY_MAX`
    and `HARNESS_CHECK_TIMEOUT`, so a session's call caps the same way as the driver's. With no prefix (check.sh run by
    hand, or the suite's own environment) or no user systemd, it runs bare, under the same timeout.
  - **D6 *default*: no `MemoryHigh` for suites**, only the cap: a runaway test dies in milliseconds instead of stalling
    under throttling (the L1-02 probe: 48M/64M throttled a 256 MB allocation for over two minutes, 64M alone killed it
    in under 100 ms).
  - **A kill reads as its cause** in check's RED line, which the session and `init.out` see: exit 124, or 137 after the
    whole `CHECK_TIMEOUT` (GNU `timeout -k` exits 137 when it had to KILL), is `check: RED (timed out after 15m, exit
    <rc> after <n> s)`; a 137 whose scope peaked at its cap (`scope_capped`, from the wrapper's record, as the session
    note does) is `check: RED (killed at its 3G memory cap, exit 137 after <n> s)`; everything else, a suite's own 137
    included, keeps `check: RED (exit <rc> after <n> s)`. A `CHECK_TIMEOUT` `dur_s` can't read (or `0`) never turns a
    137 into a timeout. A subset's output stays the caller's, so it prints only the kill lines, after it. The subset
    form stays uncached.
  - **A signal to check.sh takes the suite with it** (found by the L1-05 review). Only systemd-run's child moves into
    the check scope; check.sh stays in its caller's, so stopping a session's scope (its timeout, its cap, the stop
    after it returns) killed check.sh and left the suite running in its own scope for up to 15m, racing the driver's
    next `check.sh` over `check.out` and the port. And `timeout` puts the suite in a process group of its own, so a
    Ctrl-C in `harness start --fg` no longer reached it. So check.sh runs the suite in the background, `wait`s (which a
    trapped signal interrupts), and on TERM, INT or HUP stops the check scope (bare: TERMs `timeout`, which passes it
    on) and exits 128 + the signal. A SIGKILL can't be trapped; the timeout still bounds that suite. A background job's
    stdin is `/dev/null`, so a suite run from the driver's tmux pane can't stop on a tty read either.
  - Each call removes its scope's `.started` and `.show` on exit: `check-<pid>` names are never reused.
  - `dur_s` (in `lib/scope.sh`, planned for L1-06's memory gate too) reads the whole-number durations `timeout` takes.
- **Rejected:**
  - **`ulimit -v`**: it limits address space, not memory (node reserves far more than it uses, so a normal suite would
    fail to start), and covers one process tree only, not what a test backgrounds.
  - **Running suites inside the calling session's scope**: the driver's own checks have no session, and a session's
    6G would then be shared by claude and its suite, so the suite's runaway kills the session.
  - **Calling any 137 in a scope the cap**: a suite that passes on its own 137 (a test that `kill -9`s a child), or a
    `systemd-run` that failed after a good probe and ran the suite bare, would read as the cap.
  - **`timeout --foreground`** to keep the caller's process group: then `-k` no longer kills the suite's children, and
    bare runs would have nothing else to catch them.
