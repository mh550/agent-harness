# gc's foreign units: another project's are silent, an unowned one is said with its command

*(2026-10-28, run agent-harness-2026-10-28, feature U3-03; spec `docs/specs/2026-10-27-status-ux.md` §U3 (bug d),
plan `docs/plans/2026-10-28-U3-show-and-fixes.md` §3)*

- **Finding:** `cmd_gc`'s unit step (decisions/2026-10-25-gc-orphan-units) printed `? <unit> (no run of this project)`
  for every `harness-*` unit none of this project's runs owned: each live run of another project put its units on
  every gc's output, the end-of-queue gc in `runner.log` included, as if something were wrong. The line said nothing
  about what to do.
- **Choice:** the loop still collects every run on the box (`$STATE_ROOT/*/*`) that `scope_owns` the unit. No owner
  at all → `? <unit>: no run on this box owns it (systemctl --user stop <unit> by hand)` (the same under `--dry-run`),
  never stopped. Owners, none of this project → skipped silently, live or ended: that project's gc stops them. An owner
  of this project → the rule as before (a live owner of any project keeps it; else `would:`, `+ stopped` or `! could
  not stop`).
- **Visible:** gc's own output (`runner.log`'s `gc <project>:` lines for the runner's gc).
- **Rejected:** stopping an unowned unit (nobody can say what it is: a run whose state dir was removed by hand, a
  session of Michael's that borrowed the prefix); stopping another project's ended run's units from this gc (they are
  that project's, and its gc runs in the same queue drain).
