# Merging the memory run into lanes: main's driver changes in their lane-era homes, the review round per lane

*(2026-10-27, a merge session on run agent-harness-2026-10-26 (P1, lanes) after P1-04, before the run continues; main at
c721f66: the memory run's M1–M6. Spec `docs/specs/2026-10-26-lanes.md`, decisions/2026-10-26-lanes)*

- **Finding:** main's driver-side work (M1-04/05 retro backlog, M3-02 gotchas note, M3-04 verify pack, M4-02 memlint,
  M5-01/02 test-count source and `tests_end`, M6-02/03/05 review gate) was written against the single-loop
  `lib/driver.sh`. P1-03/P1-04 moved the coding loop into `lib/lane.sh` and the shared helpers into `lib/record.sh`,
  so most of main's edits had no place to land, and two that git auto-merged into the coordinator's `retro`/`ledger`
  were half there (`ledger` used `paths` with no definition; `retro` declared `backlog` and never set it).
- **Choice:**
  - Each change lives where its code runs now: `gotchas`, `tests_end`, `context [<cap>]` and the `testcount-source`
    note in `run_init` in `lib/record.sh`; the review gate, the escalation round, the `gotchas` call, `tests_end`
    after every session, the `· tests <n>` note suffix and the verify pack cap in `lib/lane.sh`; `memlint_check`,
    the retro's backlog and proposals, `ledger`'s backlog merge and `finish`'s `tests_end final` in `lib/driver.sh`.
  - **The pending escalation round is the lane's:** `state/lanes/<m>/review-escalate`, not main's
    `state/review-escalate`. A run-wide file would let any open lane (or the next one to open) run another milestone's
    review in its own slot, on its own branch. The lane dir survives a lane's exit and a continue, as main's file
    survived a limit wait. The once-marker `review-escalated-<id>` stays run-wide: feature ids are unique.
  - `review_diff` runs in the slot, so a review is sized by its lane's diff against main (this milestone and the
    dependencies main lacks), not by the whole run branch.
  - The findings read (`entries.mjs findings`) takes the record (`$REC`): after the take-back the slot has no copy.
  - **The pack reads the slot's project memory:** `entries.mjs pack <run dir> <feature> [<cap> [<worktree>]]`, and
    `context` passes its cwd. M3/M3-04 read `## Gotchas` and the decisions store from the worktree holding the run dir;
    under lanes that is the record worktree, whose `CLAUDE.md` is main's at the last `sync_main`, so a fact a lane's
    session had already written under `## Gotchas` stayed listed under `Promote to Gotchas` (found by
    `tests/checks/38`). Without the argument (eval probes, checks) the old rule stands.
  - `finish` counts tests in the last lane's slot (as P1-04 did), now through `tests_end final`: a red tree has none.
    The last lane's `init.out`, `check.out` and `check-*.out` are copied into the run's scratch before that count, so
    a tree cached under an older, empty marker reads that lane's output.
  - **A pending round is work the run has left** (the merge review's finding 1): `F lanes` opens a lane whose
    `lanes/<m>/review-escalate` is non-empty, even with the review at `MAX_ATTEMPTS` (the round takes no attempt), and
    `finish` counts it with `F next` for the automatic continuation. Before this, a lane that exited between the
    un-pass and the round (session cap, stop, deadline, refused sessions) never reopened under `--keep-attempts`, and
    the run ended `no feature left to try` with the round owed. Check: 42's `rcap`.
  - **Known limit, memlint lints the record worktree** (finding 2): `memlint_check` runs in the coordinator on `RWT`,
    which is main's tree at the last `sync_main` plus the record, so a lane's 16th `## Gotchas` line or an oversized
    `CLAUDE.md` is noted only once its milestone merges, by a later segment. Notes only, never a stop, so nothing
    is lost but time.
- **Rejected:**
  - Keeping the run-wide `review-escalate`: the wrong lane under `MAX_LANES` > 1, and at 1 a lane that exits with a
    round pending could hand it to the next milestone's lane.
  - Re-creating the old functions in `lib/driver.sh` beside the lanes: dead code the coordinator never reaches.
  - For now, linting each lane's tree too (`memlint_check <worktree>` in `lib/record.sh`, the coordinator's call on
    `RWT` and one in `lib/lane.sh` on `$SLOT`, noted `memlint (<m>): …`): a new behaviour with its own checks (the
    suite's stub lint ignores its argument), not part of a merge; worth it if lanes run long before they merge.
