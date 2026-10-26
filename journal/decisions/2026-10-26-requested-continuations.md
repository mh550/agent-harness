# Requested continuations run; automatic ones still skip a run Michael stopped

*(2026-10-26, run agent-harness-2026-10-26-2, feature F1-04; spec `docs/specs/2026-10-21-retro-fixes.md` R6, plan
`docs/plans/2026-10-26-F1-driver-cli.md` § R6)*

- **Finding:** every queued continuation was written `continue <run> --queued …`, and `cmd_continue` skipped any
  `--queued` one of a run whose `ended` starts with `stopped by Michael`. The guard is right for the driver's own
  continuation and the debrief's suggestion (neither may undo a stop), but it also swallowed the continuation Michael
  queued himself after stopping a run: the runner logged `skipping queued continuation of <run>: Michael stopped it`
  and started nothing, and `queue list` gave no way to tell the two apart.
- **Choice:**
  - `harness queue add --continue <run>` writes `--queued --requested`: a continuation anyone queues through the CLI
    (Michael, the desk) is a decision to resume. `cmd_continue` skips only `--queued` without `--requested`.
  - A new `--automatic` option, consumed by `queue add` and never written, leaves `--requested` out. The two automatic
    writers pass it: `finish()` after a session cap (its note now reads `continuation queued (<n> of <max>, automatic;
    it starts when the queue runs)`) and the debrief's checked `CONTINUE:` lines.
  - `harness queue list` ends a continuation entry ` (requested)` or ` (automatic)`; start entries get neither.
  - A request for a run whose automatic continuation is already queued turns that entry requested (`already queued:
    continue <run> (now requested)`), so the run starts as asked rather than one entry silently swallowing the other.
  - **The later word wins:** when the driver honours a stop (`harness stop` or the phone), it removes `--requested`
    from any queued or parked continuation of its run and notes `stop: the queued continuation <entry> is automatic
    now (the stop came after the request)`. A request queued while the run was still going, then a stop, so starts
    nothing; a request queued after the stop starts the run.
  - Parked continuations are marked in `queue list` too: whether one would start is what decides an unpark.
  - Entries queued before this change carry no mark and list as `(automatic)`: they are skipped after a stop, as
    before. A driver started before this change still calls `queue add --continue` without `--automatic` at its
    session cap, so its continuation reads `(requested)` until those drivers exit.
  - Checks (`tests/run.sh`, the queue section): `queue add --continue marks its entry --requested; --automatic … doesn't`,
    `queue list marks continuations (requested) or (automatic)`, `a requested continuation of a run Michael stopped
    starts; an automatic one is skipped (both logged)`, `the driver's continuation after a session cap is automatic`
    (run `capped`, `MAX_SESSIONS=1`), `a request for a run with an automatic continuation queued makes that one
    requested; parked entries are marked too`, and in run 2 `a stop makes a queued requested continuation of its run
    automatic (the later word wins)`; the debrief's `continuation queued: keeps attempts, …` asserts no `--requested`.
    The existing skipped-continuation setups (`stoppy`, `stoppy-o` twice) queue `--automatic`.
- **Rejected:**
  - **Dropping the guard:** the driver's and the debrief's continuations would undo Michael's stop the next time the
    queue runs.
  - **Marking the automatic ones instead (`--automatic` written, plain = requested):** entries already queued from
    before this change would then all read as requested, including the driver's; a missing mark must mean the safe,
    skipping kind.
  - **Clearing `ended` on `queue add --continue`:** the record of why the run ended would be lost before it restarts,
    and `harness status` would show the run as never ended.
