# The trace switch: `HARNESS_XTRACE=<dir>` traces every harness process, off unless set

*(2026-11-05, the slim suite's S1 built by hand (`docs/plans/2026-11-05-slim-suite-by-hand.md`); spec
`docs/specs/2026-11-03-slim-suite.md` S1-01; the measurement it serves:
`findings-and-research/2026-11-03-suite-coverage.md`)*

## Finding

Nothing on the box measures which lines of bash a check runs (`kcov`, `bashcov` and `perf` are not installed, and the
spec installs nothing). bash can say it itself: `set -x` prints every command, and `PS4` can lead each with its source
file and line. Three facts shaped the switch, each seen on this tree on 2026-11-05:

- **`set -x` does not cross a process.** The spec named three places (`lib/driver.sh`, `lib/lane.sh`, `bin/harness`).
  Nine more scripts run as a process of their own (`lib/check.sh`, `queue.sh`, `debrief.sh`, `desk.sh`, `sync.sh`,
  `backlog.sh`, `eval.sh`, `merge-sorted.sh`, and `prompt.sh` as a command): traced only from the three, every line
  of theirs would read as run by no check.
- **A bare file name is not enough.** A throwaway project's `.harness/config.sh` is sourced by `lib/config.sh` and
  would trace as `config.sh:<n>`, the same as `lib/config.sh`.
- **The resident helper's start closes every descriptor above 2** (`helper_start`, `lib/record.sh`), the trace's
  among them, and bash then prints the rest of that loop on stderr: the first traced stub run had trace lines in the
  driver's output.

## Choice

- **`lib/xtrace.sh`**, sourced under one guard line, `[[ -z ${HARNESS_XTRACE:-} ]] || source "<lib>/xtrace.sh"`, as the
  first line of work in each of the twelve executable scripts (`bin/harness` and the eleven in `lib/`). With
  `HARNESS_XTRACE=<dir>` the process and its subshells append bash's own trace to `<dir>/<pid>.xtrace`, each line led
  by `+<source file>:<line>: ` (`PS4='+${BASH_SOURCE:-}:${LINENO}: '`: the full path as bash names it, the `+` once
  per nesting level), on a descriptor of its own (`BASH_XTRACEFD`), never stderr.
- **Off unless set**: without the variable nothing is opened and no shell option changes. A directory that can't be
  made or written costs the trace, never the command.
- **A traced segment says so**: the driver's first note is `trace: this segment's harness processes write every
  command they run to <dir> (HARNESS_XTRACE)`. A plain run's `harness-log.md` has no such line and is otherwise the
  same.
- **`bin/harness start` hands the variable to a tmux-started driver**, in the list of overrides it already passes (tmux
  runs its commands in its server's environment, not the caller's).
- **`helper_start` turns the trace off (`set +x`) in the helper's own subshell before it closes the descriptors**, so
  the helper still keeps no descriptor but its three and nothing reaches stderr. A no-op without the switch.
- **The suite never traces by itself.** `tests/lib.sh` drops an inherited `HARNESS_XTRACE` (a traced run's session
  running the suite would otherwise trace every stub run into the real run's directory). `TEST_XTRACE_DIR=<dir>` is the
  measurement's switch (`tests/tools/coverage.sh`): each check file's harness processes and its own shell trace to
  `<dir>/<check file>/`, and node writes its coverage to `<dir>/<check file>/v8` (`NODE_V8_COVERAGE`);
  `tests/checks/00-unit-tier.sh`, which does not source `tests/lib.sh`, sets the node half itself. The check file's own
  shell traces because about 80 check lines source a `lib/` file and call into it in the check's shell.
- **Checks**: `tests/checks/93-xtrace.sh` (fast, 20.7 s alone): a plain and a traced foreground run of one stub
  project (no trace file without the variable; the CLI, the driver, a lane and the check runner traced with it; no
  trace line in either run's output or the helper's stderr file; the traced run's `harness-log.md` is the plain
  run's plus the note, once ids, times, hashes, lengths, the port and the PR number are cut out), a tmux-started run, an unusable directory, the guard line
  in every executable script, and `TEST_XTRACE_DIR` through `tests/lib.sh` and the unit tier.

Defaults that differ from the spec: twelve scripts, not three; the full path in `PS4`, not the base name; the guard
sources one file instead of three lines in each script.

## Rejected

- **`BASH_ENV` for the measurement and no switch in the harness**: it would trace every bash the suite starts with no
  line in `lib/`, but the spec asks for a switch a real run can use, and `BASH_ENV` reaches the stubs and the project's
  own scripts too.
- **Keeping the trace's descriptor open in the helper** (skipping it in the closing loop): the helper would hold a
  fourth descriptor for its whole life, against the rule its start states.
- **A hand-through for a run the queue runner starts**: the runner's tmux command passes two variables only. A traced
  queue is nobody's need yet; a run started by the runner traces only if the runner's environment has the variable.
