# Sessions and suites run in capped transient systemd user scopes, through one helper

*(2026-10-25, run agent-harness-2026-10-25-lifecycle, feature L1-02; spec `docs/specs/2026-10-25-resource-lifecycle.md`
§L1 items 1–2, plan `docs/plans/2026-10-25-L1-capped-sessions.md` §1–§2, §12 D1–D2; the OOM finding of 2026-10-24 in
`findings-and-research/2026-10-24-system-resource-audit.md`)*

- **Finding:** a session is `timeout "$SESSION_TIMEOUT" "$CLAUDE" -p …` and a suite a bare `bash -c "$cmd"`: wall time
  only, no memory limit, and nothing stops what a session backgrounded. On 2026-10-24 one red-phase `deepEqual` diff
  grew to 6.5–9.6 GB four times and the kernel killed codium, claude-desktop and python instead. Probing the real
  commands on this box (systemd 255) showed three things the spec didn't say:
  - a scope whose processes have all exited is gone at once under `--collect`: `show` then prints
    `MemoryPeak=[not set]`, so the peak can't be read after the command returns;
  - a transient scope's default `OOMPolicy=stop` stops the whole scope on an OOM kill, so anything around the command
    dies with SIGTERM (exit 143) and nothing is recorded;
  - `MemoryHigh` close under `MemoryMax` (48M/64M, no swap) throttled a 256 MB allocation for over two minutes without
    a kill; `MemoryMax=64M` alone killed it with 137 in under 100 ms.
- **Choice:**
  - **One helper, `lib/scope.sh`**, sourced by the driver (L1-03) and `check.sh` (L1-05). `scope_run <unit> <high>
    <max> <cmd…>` runs `systemd-run --user --scope --collect --quiet --unit=<unit> [-p MemoryHigh=<high>]
    -p MemoryMax=<max> -p MemorySwapMax=${SESSION_SWAP_MAX:-1G} -p OOMPolicy=continue` around the command and returns
    its exit code; an empty `<high>` leaves `MemoryHigh` out. `scope_stop` stops `<unit>.scope` (exit 5, "not loaded",
    counts as done); `scope_peak` prints the peak in whole MB; `scope_left` the tasks the command left; `scope_capped`
    whether the peak reached the cap. The commands are `${HARNESS_SYSTEMD_RUN:-systemd-run}` and
    `${HARNESS_SYSTEMCTL:-systemctl}`, so the suite drives stubs whose output copies the real captures.
  - **D1 *default*: the peak is read from inside the scope.** A wrapper bash is the scope's first process: it runs the
    command, then writes `systemctl --user show -p MemoryPeak,ControlGroup,TasksCurrent` to
    `<scratch>/scopes/<unit>.show` while it still holds the scope. Values are parsed by key (systemd prints its own
    order). TasksCurrent counts the wrapper and its `systemctl`, so leftovers = TasksCurrent − 2.
  - **D2 *default*: `OOMPolicy=continue` on every harness scope**, so a cap kill takes only its victim; the wrapper
    records `MemoryPeak` = the cap and passes 137 on.
  - **The probe, cached per process.** `scope_available` runs `systemd-run --user --scope --quiet true` once and keeps
    the answer in `SCOPE_OK`; without a user bus everything runs bare, as before. If `systemd-run` fails after a good
    probe (the wrapper's `.started` marker is missing), `scope_run` says so on stderr and runs the command bare. The
    wrapper writes the marker before it runs anything and exits 254 when it can't, so a missing marker always means
    the command never ran: a session is never run twice (found by the L1-02 review: an unwritable scratch dir ran
    it once in the scope and again bare). Any systemd-run failure (a bus gone, a unit name still held, a property
    systemd rejects) runs uncapped with that line rather than not at all.
  - **Unit names** are `harness-<run>-<role>[-<n>]`, every character of the run id outside `[A-Za-z0-9_-]` replaced by
    `-` (`scope_unit`). `.` is legal in a unit name, but a dotted run id would make `harness-<run>-*` globs match
    another run's units.
  - **The suite starts one real scope** (spec Rules): `harness-test-<pid>-oom`, `MemoryMax=64M`, no `MemoryHigh`, no
    swap, under an outer `timeout 30s`, stopped in its own check; it shows the kill is 137 and the peak is the cap.
- **Rejected:**
  - **Reading `memory.peak` from `/sys/fs/cgroup`** after the command: the scope is gone by then, and the cgroup path
    can't be stubbed.
  - **A `RemainAfterExit` service instead of a scope**: the session's stdin, stdout and exit code would go through the
    journal instead of the caller.
  - **Keeping `OOMPolicy=stop`**: the record dies with the scope.
  - **`ulimit -v`** for the cap: it limits address space, not memory (node reserves far more than it uses), and covers
    only one process tree, not what a session backgrounds.
  - **Keeping `.` in unit names**: legal, but it blurs the per-run globs that L2's `gc` and status rely on.

## Sessions in their scopes, stopped after they return (L1-03)

*(2026-10-25, same run, feature L1-03; plan §3, §7, §8.1, §12 D3–D4)*

- **Finding:** a session's `timeout "$SESSION_TIMEOUT" claude …` sends SIGTERM to claude alone; a dev server, a
  watcher or a `sleep` it backgrounded lives on after the session, holding memory and ports into the next one. And an
  exit 137 with no result under 120 s read as environmental (`no result after <n> s`), so a session killed at its
  cap would have given its attempt back and the feature retried for ever at the same size.
- **Choice:**
  - `session()` (all four kinds) runs `scope_run harness-<run>-s<n> $SESSION_MEMORY_HIGH $SESSION_MEMORY_MAX timeout
    -k 30s $SESSION_TIMEOUT claude …`; `<n>` comes from `state/scope-seq`, bumped per session of any kind, so a resumed
    segment never reuses a unit a crashed one left. Defaults `SESSION_MEMORY_HIGH=5G SESSION_MEMORY_MAX=6G
    SESSION_SWAP_MAX=1G` (the spec's). **D3 *default*:** `timeout -k 30s` sits inside the scope, around claude (outside
    it would signal the wrapper, not claude).
  - **Stop after return.** When claude returns, the driver reads the peak and the task count the wrapper recorded, then
    `systemctl --user stop`s the scope: whatever the session left running is killed with it, and noted
    `<kind> session left <n> process(es) running; stopped with its scope` when there was any.
  - **D4 *default*: exit 137 is the feature's attempt**, like 124 (`environmental()` returns null for both). A 137 whose
    peak reached `SESSION_MEMORY_MAX` is noted `<who>: the session hit its memory cap (<SESSION_MEMORY_MAX>)`; the peak
    alone isn't enough (page cache counts in `MemoryPeak`), so the note needs both.
  - The probe runs once per driver process (one segment), right after the configuration loads; when it fails the
    segment notes `no user systemd: sessions and suites run uncapped` once and every session runs the same `timeout -k
    30s …` line bare.
  - **`--description=<unit>`** on every scope (found by the L1-03 review, checked on this box): without it systemd
    describes the unit by its whole command line, so each session's full prompt went to the user journal and into
    every `systemctl status` and `list-units` line.
- **Rejected:**
  - **Killing by pid** (claude's process group, or the pids the session started): a session's children can leave the
    group (`setsid`, a daemonising server, tmux), and pids are reused; the cgroup is the one set that holds everything
    the session started, and stopping the scope kills it whole.
  - **Stopping the scope before reading it:** the record (peak, tasks left) would go with it.
  - **Keeping 137 environmental:** a feature too big for 6G would never spend an attempt.
