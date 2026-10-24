# Work reaches main and the live harness without a person carrying it: live sync, visible parking, sessions merge

*(2026-10-24, interactive session with Michael; findings in `findings-and-research/2026-10-24-system-resource-audit.md`
and the 2026-10-24 review of the stalled harness-improvement runs)*

- **Finding:** on 2026-10-24 the live checkout was 109 commits behind `origin/main`, so E1–E4 (merged as PR #10) never
  ran, and 14 ledger commits the driver had made on it were never pushed. Nobody but Michael could move it: sessions
  were told never to pull or merge, and the driver keeps committing the ledger there, so it drifted further every
  run. Three queued harness runs (retro fixes, tmux/queue hygiene, n8n events) had been moved into `queue/held/` by
  hand on 2026-10-21/22 to wait for PRs. The runner never looks there and `harness queue list` showed an empty queue,
  so the runs sat for three days with nothing saying so. Findings and specs ended on branches in `.claude/worktrees/`,
  one of them uncommitted.
- **Choice:**
  - **`lib/sync.sh`.** It levels the checkout that holds the ledger with origin. It fetches, rebases the unpushed
    ledger commits onto `origin/main` (they were never shared, so nothing published is rewritten) and pushes without
    force, or fast-forwards.
    - It acts only when the checkout is on `MAIN_BRANCH`, no rebase or merge is going, no tracked file is modified,
      and every local-only commit touches nothing but `ledger/`. Anything else is someone's work: it logs why and
      leaves it alone.
    - **When it runs:** the queue runner calls it before a start with no driver alive (`LIVE_SYNC=1`, the default),
      and `harness sync` calls it by hand.
    - **Bash reads scripts as it runs them**, so a checkout must not move under a live driver. For the same reason the
      runner's body is one `{ … }` block, parsed whole before it runs.
  - **Parking is a command, not a hand-moved file.** `harness queue park <n> [<why>]` writes the reason beside the
    entry. `queue list` shows parked entries and their reasons, the runner logs how many it skipped, and `unpark`
    renumbers the entry to the end of the queue so it can't collide with what was added meanwhile.
  - **`CLAUDE.md`:** a session working on this repo merges its own PR when the suite is green (never force, never
    rewriting `main`), and a finding or spec counts as finished only once it is merged.
- **Rejected:**
  - **A merge commit instead of a rebase for the ledger commits.** It adds a merge on every sync; a rebase of
    never-pushed commits is the same content without that noise.
  - **Syncing while runs are alive.** Bash reads scripts incrementally, and a rewrite can corrupt a running driver.
    With `MAX_PARALLEL_RUNS=2` the idle moments come often enough.
  - **Making the driver push the ledger at the end of each run.** The run's own checkout is the one being driven;
    the runner's idle moment is the only safe point.
  - **Reading `held/` entries automatically when their blocker clears.** "Parked on purpose" carries no machine-
    checkable condition, so the reason is shown and a person or session unparks the entry.
