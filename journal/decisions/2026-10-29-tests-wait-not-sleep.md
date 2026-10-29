# The suite waits on a condition or a barrier, never on the clock; a flake is reproduced with --repeat and fixed at its cause

*(2026-10-29, run `agent-harness-2026-10-29-2`, R1-01 to R1-07; spec `docs/specs/2026-10-28-reliability.md` §R1, plans
`docs/plans/2026-10-29-R1-flakes.md` (the sweep and the flaker table) and `docs/plans/2026-10-29-R1-review.md`)*

- **Finding:** the 2026-10-26 to 10-29 runs lost sessions and verify rounds to checks that failed under load and passed
  alone (28, 32, 38, 44, 46, 48, 08, 15, and 45 and 47 under the full suite). The suite waited by the clock: 96 lines
  in 22 files named `sleep`, of them 29 fixed-iteration polls (`seq 20` × 0.1 s in `in_has`, `seq 150` × 0.2 s in
  `settle`, four identical `waitf` copies) and 18 orders (`sleep 1` between two writes, `sleep 0.5` so a detached job
  has started), whose limits stretch or shrink with the box's load. And a flake can be the only symptom of a real
  race: reproduced with `--repeat 10`, every named flaker but 47 was one driver race (the lanes coordinator counted a
  lane that exited before its end check, and ended the run `no feature left to try` with the next milestone ready;
  `decisions/2026-10-29-lane-count-end-check`), and 08's other two reds were the test's own orders.
- **Choice:**
  - **`wait_for <max s> <command…>`** (`tests/lib.sh`) runs the command quietly every 0.1 s until it exits 0, or
    gives up after `<max>` s by `$EPOCHREALTIME` (not counted iterations) with `wait_for: <command> still failing after
    <max> s` on stderr, exit 1. A condition with expansions is `wait_for <s> eval '<expr>'`. `in_has`, `settle`, `ran`
    and every fixed-iteration poll in `tests/checks/` are on it; limits are generous (most 30 to 120 s, a
    poll's old limit or more), since a pass costs only the time to the event.
  - **Barriers for order:** `stub_go <name>` / `stub_wait <name> [<max s>]` (files under `$T/barriers/`), and
    `STUB_BARRIER=<id>:<name>` holds that feature's first stub coding session at `<name>.held` until the check opens
    it. Where the actor is the driver, the check waits on what the driver leaves (a log line, a lock, a pid gone).
    `HARNESS_COUNT_HOLD=1` (unset everywhere but a check; `bin/harness` passes it to tmux-started runs) holds the
    coordinator between its lane count and its end check until the counted lanes exit, so a check forces the race it
    guards against every time instead of now and then.
  - **The sleep lint** (`tests/lint-sleeps.sh`, run by `75-suite-tools`'s `sleep lint: tests/checks and tests/lib.sh
    hold no bare sleep`): a line in `tests/checks/*.sh` or `tests/lib.sh` naming `sleep` that is no full-line comment
    and lacks `# sleep-ok: <why>` turns the suite red. The sleeps left are work (a live pid, a stub's slow step, a
    fixture's hang, mtime granularity) or a *negative* (nothing happened over n polls, where the actor leaves no
    trace to count), each marked; the stubs are exempt (their sleeps are the work they stand in for).
  - **`bash tests/run.sh --repeat <n> <name>…`** runs each matching file n times, `TEST_JOBS` copies at once, each from
    its own fresh state, and prints `<file>: <k>/<n> green` and the red copies' FAIL lines. A flaker gets `KEEP=1 …
    --repeat 10`, at most 30 minutes, and is fixed where the red copy's logs point (driver or test), with a check that
    is red on the code before the fix (forced, when the window is too narrow to hit by chance); else it is recorded
    `not reproduced (10/10 green)`.
- **Rejected:**
  - **Longer sleeps:** they make every pass pay the worst case, and under a heavier load they are short again; the
    flakes were races, and a longer sleep would have hidden the coordinator's end-check bug, not fixed it.
  - **`TEST_JOBS=2`** while lanes run: measured slower (about 1200 s against 857 s for two suites at once) and as
    flaky (`decisions/2026-10-29-check-timeout-25m`); less load moves the window, it doesn't close it.
  - **Quarantine** (skip a flaky check): a quarantined check stops guarding, and here the "flakes" were one real
    driver race that ended runs early (`decisions/2026-10-29-rerun-guard`: a flake is green, named and counted, and a
    repeat flaker is fix work).
  - **A lint that parses comments out of code lines:** a `#` in a string, `$#` or `#{pane…}` would fool it; a code
    line that only names sleep in a trailing comment is reworded or marked `# sleep-ok: text`.
