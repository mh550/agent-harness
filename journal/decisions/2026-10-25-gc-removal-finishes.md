# harness gc's worktree removal finishes: --force on a clean tree, then rm -rf, then prune; a failure is said

*(2026-10-25, run agent-harness-2026-10-25-lifecycle, feature L4-02; spec `docs/specs/2026-10-25-resource-lifecycle.md`
§L4 item 2, plan `docs/plans/2026-10-25-L4-gc.md` §2)*

- **Finding:** R9 (2026-10-21): portfolio_site's merged worktree was clean, but held a gitignored `.next/`, and gc's
  `git worktree remove` (no `--force`) refused; the loop died there under `set -e` and no later worktree or branch
  was collected. On git 2.43 here a plain `remove` does take a tree whose only extra files are ignored, so the
  refusal had another cause (a file gc couldn't delete, say); either way one refused worktree ended gc. A directory
  git can't delete (its parent read-only, in the suite) is emptied by `remove --force`, which then fails with
  `error: failed to delete '<wt>': Permission denied`; its admin entry is gone after a `prune`.
- **Choice:** gc removes a clean, merged worktree with `git worktree remove --force` (reached only when
  `status --porcelain` is empty, so the only files `--force` loses are ignored ones: build output, never work), then
  `rm -rf` if the directory is still there (the path is always under `$WT_ROOT`, never the project's own checkout, which the loop skips by name), then `git worktree prune`. If the
  directory remains or git still lists the worktree (a locked one), gc prints `! could not remove <wt>: <why>` (the
  last line of the failing command's stderr) and goes on to the next worktree. The output is `+ git -C <p> worktree
  remove --force <wt>`, plus `+ rm -rf <wt>` when that runs; `--dry-run` prints `would: git -C <p> worktree remove
  --force <wt>` for each and removes nothing.
- **Rejected:**
  - **`git clean -fdx` in the worktree first:** two deletions where one does; it walks the whole tree (a big
    `node_modules`) only for the remove to delete it again, and it can't help with the directory itself failing.
  - **Leaving `--force` out and relying on `rm -rf` alone:** `rm -rf` leaves the admin entry until a `prune`, and
    a `remove` that refuses for a reason git knows (a locked tree) would be silently bypassed; `--force` first keeps
    git's own path the normal one.

*Amended 2026-10-26 (L4-05 review #2 to #4):* the fallback ran `rm -rf` after any refusal, the locked tree this file
meant to respect included. Now `rm -rf` runs only once git no longer lists the worktree, the `! could not remove` line
gives the first stderr line (git's reason), only `harness/<run>` worktrees are candidates, and clean counts untracked
files whatever `status.showUntrackedFiles` says: decisions/2026-10-26-gc-unattended-guards.
