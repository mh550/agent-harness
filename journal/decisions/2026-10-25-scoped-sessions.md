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
