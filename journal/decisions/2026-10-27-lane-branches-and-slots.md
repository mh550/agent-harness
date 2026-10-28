# Lane branches go when their PR merges; gc reaps lane branches, leftover slots and a killed run's lane units

*(2026-10-27, run agent-harness-2026-10-26, feature P2-04; spec `docs/specs/2026-10-26-lanes.md` §P2 item 3, plan
`docs/plans/2026-10-26-P2-two-lanes.md` §4)*

- **Finding:** before this a merged milestone's `harness-lane/<run>/<m>` stayed on the origin until `finish`, so a
  long night left one stale branch per merged milestone; `harness gc` knew only the `harness/` and `harness-merge/`
  prefixes, so under `pr` (merged by Michael on GitHub after the run ended) the lane branch stayed for good; and a
  SIGKILLed driver left its slots under `<worktrees>/<project>/lanes/<run>/`, which no gc pass looked at (a closed
  lane's slot can be detached, and the worktree pass skips a worktree with no branch). Worse, `gc`'s `running()`
  mapped only `harness/<run>`, so `gc --all-merged` would have deleted a live run's lane branch from the origin while it
  sat at main's commit (opened, nothing committed yet), and a driver killed while its lane works counted as not running.
- **Choice:**
  - `lane_branch_gone <m>` (lib/record.sh): on the origin at once (`merge_one`'s success, the merged-by-its-PR path);
    here once no live lane has it checked out: the lane merging its own milestone leaves the local branch to the
    coordinator's `reap`, which detaches the closed lane's slot and runs `branch -D` (once more after a second: it
    writes `.git/config`, which git locks without waiting). One note, `lane <m>: branch harness-lane/<run>/<m> deleted
    (merged)` (`; kept here` / `; kept on origin` when one side stayed). `slot_close` uses it for what is left at
    `finish`. Unverified and unmerged lane branches stay. Guards (from the review): only a tip its merged tag or
    `origin/main` holds goes (a fix Michael pushed onto the branch after the merge stays; the origin's delete is under
    `--force-with-lease` on the tip `ls-remote` saw), and only this run's slots are detached (a checkout of Michael's
    with the branch checked out keeps it).
  - `cmd_gc`: `harness-lane/` joins the branch passes (a lane branch has no upstream, so its local delete is `branch -D`
    after the same is-ancestor-of-`origin/main` test that guards `-d`); `running()` maps `harness-lane/<run>/<m>` to its
    run and counts a live lane process (`lanes/*/pid`) as running, as do the unit pass and `--deps`.
  - A slot is recognised by its path and removed (`worktree remove --force`, prune, `rm -rf` as for run worktrees) when
    its run has no live driver or lane, no queued continuation and no open desk and the slot is clean, whatever its
    branch's merge state (the branch keeps the work; `harness continue` makes the slot again). Kept slots say why. Then
    `lanes/<run>` and `lanes/` go when empty. `--deps` frees the `DEPS_DIRS` of a kept slot of an ended run.
  - `lanes_orphans` also requires `STATE=<this run's state>` in the pid's environment (P1 Minor 8); `lanes_term` notes
    each lane it TERMs, after every TERM went (P1 Minor 11). gc's live-lane test also requires the pid's command line
    to be `lib/lane.sh` (a recycled pid would keep a dead run busy for good).
- **Rejected:** deleting the local branch from inside the lane (it is checked out in the lane's own slot, and a detach
  there would race the lane's exit); keeping merged lane branches until gc (one stale branch per milestone on the
  origin all night); removing a slot only when its branch is merged (a killed run's unverified slot would stay forever,
  while its branch already holds the work); `branch -d` for lane branches (it judges by HEAD when there is no
  upstream, so it refuses in a checkout whose `main` lags).
