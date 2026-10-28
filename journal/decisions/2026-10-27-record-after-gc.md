# A finished run keeps its record after gc: report reads worktree → state → ledger

*(2026-10-28, run agent-harness-2026-10-28, feature U3-03; spec `docs/specs/2026-10-27-status-ux.md` §U3 (bug b),
plan `docs/plans/2026-10-28-U3-show-and-fixes.md` §2)*

- **Finding:** `finish` wrote `summary.json` and `report.md` only into the run record in the worktree (and the ledger).
  `harness report <run>` rebuilt from the worktree or read the state's `summary.json`, which only an earlier `report`
  had written; once the end-of-queue `harness gc --all-merged` removed the worktree of a run nobody had reported, `report`
  said `## <run>: no record`, while `harness status` (`status.mjs readRun`: record → state → ledger) still showed its
  passing count from the ledger.
- **Choice:** `finish` copies the final `summary.json` and `report.md` (and `metrics.jsonl`, which report's memory
  peaks read beside `summary.json`) into the state dir after the retro's rewrite, and notes `summary.json and report.md
  kept in the state dir (harness report reads them after gc)`; a failed copy is noted (`could not keep …`) and never ends
  `finish`. `cmd_report`, per run: (1) the worktree exists → the rebuild into the state, as before; (2) else the
  state's `summary.json`; (3) else `${HARNESS_LEDGER}/<project>/<run>/summary.json` (`<project>` = the basename of
  `PROJECT_DIR`), copied into the state with its `metrics.jsonl` on that first read (reported from the ledger if the
  copy fails); (4) else `## <run>: no record (worktree removed; nothing in <state dir> or <ledger>/<project>/<run>)`,
  both paths with the home directory as `~`. A run whose state dir is gone but whose ledger copy exists
  (`<ledger>/*/<run>/summary.json`) is reported from the ledger, copied nowhere; one with neither keeps `no run '<id>'`.
- **Visible:** the note in `harness-log.md` and `run.log`; `report`'s output itself.
- **Rejected:** gc refusing to remove an unreported run's worktree (the end-of-queue gc runs unattended and would keep
  worktrees for good; the copy costs two files); reading the ledger alone after gc (`LEDGER_COMMIT=0` boxes and a
  ledger moved by hand would lose the record that the state dir still has).
