# harness gc stops the units a killed driver left; harness status shows what a running run holds

*(2026-10-25, run agent-harness-2026-10-25-lifecycle, feature L2-05; spec `docs/specs/2026-10-25-resource-lifecycle.md`
§L2 items 4–5, plan `docs/plans/2026-10-25-L2-run-services.md` §7)*

- **Finding:** a SIGKILL (the OOM killer, `kill -9`, a reboot of the tmux server) runs no EXIT trap, so the driver's
  `services_down` never runs: `harness-<run>-svc` keeps the init's servers and a session's `harness-<run>-s<n>` may keep
  `claude` working for nobody until `SESSION_TIMEOUT`. Only the next `run_init` of that run stopped the svc unit, and
  a run that is never continued never has one. Nothing showed what a running run holds either.
- **Choice:**
  - `harness gc <project>`, **first** (the plan put it after the branch passes; a review found a fetch that fails
    offline or a prunable worktree ends gc under `set -e` before it, and a worktree could be removed while a killed
    run's session still worked in it), lists `systemctl --user list-units 'harness-*' --plain --no-legend`
    (column 1 only) and matches each unit to a run with `scope_owns <run> <unit>`: the unit must equal
    `$(scope_unit <run>)-<role>.scope` with `<role>` one of `s<n>`, `check-<pid>`, `svc`, rebuilt from every state dir's
    id, never parsed out of the unit name (so `demo` never claims `demo-x`'s `harness-demo-x-svc`).
  - A unit is stopped (`scope_stop`) when one of the runs it can belong to is this project's and none of them has a
    live `driver.pid`. **Not "has `ended`"**, as the spec says: the driver removes `ended` at start and only `finish` and
    the trap write it, so the SIGKILL this step is for leaves a dead `driver.pid` and no `ended`. The line says which:
    `+ stopped <unit> (<run> ended)` or `(<run>: driver gone)`; `--dry-run` prints `would: systemctl --user stop <unit>
    (…)`. gc's own lines, not `act`'s, which would print the raw argv.
  - Every project's runs are candidates, since two ids can reduce to one prefix (`a.b`, `a-b`): a live one anywhere
    keeps the unit. A unit only another project's runs own is skipped silently (that project's gc owns it); one no run
    on this box owns prints `? <unit>: no run on this box owns it (systemctl --user stop <unit> by hand)` and is never
    stopped (the suite's `harness-test-*` probes match no role).
    Updated in place 2026-10-28: the `?` line is for unowned units only, with the command (decisions/2026-10-27-gc-foreign-units).
  - `harness status` prints under a `running` run one line per unit, `    harness-<run>-<role> · MemoryCurrent <n> MB`
    (`list-units 'harness-<run>-*'`, filtered by `scope_owns`, then `show -p MemoryCurrent`, rounded as `scope_peak`
    rounds). `[not set]` (gone between the two calls), no user bus or an ended run: no line, and an ended run calls no
    `systemctl`. **D1 *default*:** no `scope_available` probe first (the plan's §7.2): a failing `list-units` already
    gives nothing, and the probe would start a transient scope on every `harness status`.
  - The stub `systemctl` now answers `MemoryCurrent` from `tests/fixtures/systemctl-show-current{,-gone}.txt` and lists
    units in the `--description` shape (`systemctl-list-units-described.txt`), both captured on this box.
- **Rejected:**
  - **A systemd timer or a watcher** that stops a dead driver's units: one more unit to install by hand and keep
    alive, for a case gc and the next `run_init` already cover; L4 runs gc from the queue runner, which makes it
    routine.
  - **`ExitType`/`BindsTo=` the driver** (units that die with their driver): the driver is no unit (it runs in tmux),
    and the svc scope must outlive a session by design.
  - **Parsing the run id out of the unit name:** `scope_unit` maps `.` to `-` and run ids may hold `-`, so the name
    alone can't say where the id ends; rebuilding from the state dirs can.
  - **Stopping only runs with `ended`:** misses exactly the SIGKILLed driver (above).
