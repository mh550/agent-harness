# harness gc runs unattended, so it holds its own guards: run worktrees only, git's refusal kept, the default branch kept

*(2026-10-26, run agent-harness-2026-10-25-lifecycle, feature L4-05; the L4 review `docs/plans/2026-10-25-L4-review.md`
#1 to #7, #10, #11; spec `docs/specs/2026-10-25-resource-lifecycle.md` §L4)*

- **Finding:** L4 made gc run every night from the queue runner with `--all-merged --deps`
  (decisions/2026-10-25-runner-gc) and made its removal forceful (`worktree remove --force`, then `rm -rf`;
  decisions/2026-10-25-gc-removal-finishes). The guards that used to stop a bad removal were git's (a plain
  `remove` refuses a dirty or locked tree) and Michael's timing (he ran gc by hand). Without them, the review found:
  any merged, clean worktree under `$WT_ROOT` went, Michael's own session worktrees included; a locked worktree was
  `rm -rf`'d after git refused it; `status.showUntrackedFiles=no` made a tree with untracked work look clean; a
  listed worktree with no directory, or a `du` on an unreadable directory, ended gc under `set -e`; `--all-merged`
  deleted a merged `production`/`trunk` branch and the remote branch of a running run; and the runner's gc could wait
  forever on a git prompt, holding the debrief.
- **Choice:**
  - gc removes only a **run's worktree** (branch `harness/<run>`, the only kind the harness makes); a merged, clean
    worktree on any other branch prints `keeps <wt>: not a run worktree (branch <b>)`.
  - **Clean** is `git status --porcelain --untracked-files=normal` empty; a status that fails is not clean.
  - Removal is `worktree remove --force`, `worktree prune`, then `rm -rf` **only when git no longer lists the
    worktree**; a refusal (locked) stays and is said: `! could not remove <wt>: <git's line>`.
  - A listed worktree whose directory is gone is skipped; `git -C` failures and a failing `du` skip or count
    partially, never end gc.
  - The branch passes never delete `main`, **the origin's default branch** (`refs/remotes/origin/HEAD`) or a
    **running run's branch**, locally or on the origin; they list `%(refname:lstrip=2)` and test full refs. A local
    branch checked out in a worktree is skipped (`-d` refuses it anyway). Under `--all-merged` the one prefix is the
    bare one (the others are inside it).
  - The runner runs gc as `GIT_TERMINAL_PROMPT=0 timeout -k 10s "${HARNESS_GC_TIMEOUT:-10m}" harness gc …`; a
    timeout is `gc <p> failed (exit 124)` and the debrief starts.
- **Rejected:**
  - **A run worktree is one whose state dir's `meta.env` names it** (the `--deps` rule): stricter, but a run whose
    state dir is gone (moved, a hand-made `harness/` worktree) would then keep its merged worktree forever; the
    branch prefix is what the harness itself makes, and Michael's sessions never use it.
  - **`--force-with-lease` on the remote delete:** closes a push-between-fetch-and-delete race, but Michael's settings
    deny force-push forms, and the one writer gc can know of, a running run, is now skipped.
  - **A `GC_KEEP_BRANCHES` setting now:** asked instead (the review's question); `main` and the default branch are
    the protections every project needs.
  - **Leaving `--all-merged` out of the runner:** the spec asks for it (B8: merged `spec/…` and `docs/…` branches pile
    up); the default-branch guard covers the deploy-branch case seen so far.
