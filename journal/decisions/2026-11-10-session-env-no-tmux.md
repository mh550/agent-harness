# A session's environment carries no TMUX; a driver's hangup names itself

*(2026-11-10, after run `agent-harness-2026-11-10` died 2 min 44 s into its first coding session; fix PR "fix: a
session's environment carries no TMUX")*

## Finding

`harness start` runs the driver in a tmux pane (`tmux new-session` on the default server, bin/harness), so the driver's
environment holds `TMUX` (the server's socket, pid and index) and `TMUX_PANE`: its window's cleanup needs them
(`capture-pane -t "$TMUX_PANE"` after the driver exits). `session()` in lib/record.sh started claude through
`scope_run` with the environment as it was, so every session inherited both. The coding session of
`agent-harness-2026-11-10` cleaned up a throwaway stub run with `TMUX_TMPDIR=$T/tmux tmux kill-server` in its own
shell. tmux resolves the server from `$TMUX` before `TMUX_TMPDIR`, so that command killed the default server: the
driver's pane went away, the driver got SIGHUP (the transcript's last line reads `Hangup`), its EXIT trap ran with the
default reason, the lane's exit file read `12 lane exited unexpectedly` and `ended` read
`driver exited unexpectedly (see run.log)`, which sends Michael to run.log for a cause the log doesn't hold.

The suite knew this: tests/lib.sh unsets `TMUX` and `TMUX_PANE` before it starts its private server, and
lib/eval.sh's `run_env` strips them with `env -u`. The driver's own sessions, the service init and the project's
suite did not.

## Choice

- **`scope_run` strips them, once for everything.** Its first line is now `set -- env -u TMUX -u TMUX_PANE "$@"`, so the
  command runs without the two whether it lands in a scope or bare. It is the one path every command the driver or a
  lane hands to a project passes through: `session()` (init, coding, verify, retro, curator, memory review, entry
  resume), `run_init`'s `INIT_CMD`, and `check.sh`'s suite. A session's shell may run `tmux` against its own server
  as the suite does; the driver's server is out of its reach. Two calls don't come through it and get the same
  `env -u` on their own line: `harness debrief`'s session (bare, outside any scope; the queue runner or Michael starts
  it, inside their tmux) and `check.sh`'s unscoped fallback (no scope prefix, or no user bus).
- **The driver's environment is unchanged.** It keeps `TMUX` and `TMUX_PANE`: the pane's `after` command needs them,
  and `harness attach`, `harness gc`'s tmux step and the desk talk to that server on purpose.
- **A hangup names itself.** lib/driver.sh traps HUP: while `END_REASON` is still the default it becomes
  `the driver got a hangup (its tmux server or terminal went away); state is kept: harness continue <run>`, then
  `exit 129`, and the EXIT trap writes `ended` as it does for every end `finish` didn't name. `exit_record` opens the
  `driver_crash` card with that reason as `end_reason`: the card's headline, its title and `harness needs` carry the
  words, and `harness-log.md` gets them as a note. A guard names what it found, and its message is its repair
  instruction. `finish`'s reason, once set, stands: a hangup during the teardown doesn't rewrite a real end.
- **The driver still ends on a hangup.** Surviving one (ignoring HUP, re-parenting under `setsid`/`nohup`) is out of
  scope: the driver's windows, its log tail and the supervisor live in that tmux session, and a driver running on
  after its session is gone has no pane to capture, no attach, and a `harness gc` that can't see it. A terminal that
  goes away is a stop Michael can read, and `harness continue` picks the run up from its state.

## Rejected

- Unsetting the two in `session()` alone: the service init and the suite run project code in the same environment and
  could kill the server the same way; `scope_run` covers all three.
- Pointing the session at a private server (`TMUX_TMPDIR`) instead: `$TMUX` still wins, and a session that wants its
  own server sets `TMUX_TMPDIR` itself, as the suite does.
- Ignoring HUP in the driver (`trap '' HUP`) to survive the pane: the windows and the capture are gone, and a run that
  outlives `harness attach` and `harness gc`'s view of it is the orphan those two exist to prevent.
