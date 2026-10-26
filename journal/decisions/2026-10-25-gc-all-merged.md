# harness gc --all-merged deletes every merged branch; every pass lists by prefix

*(2026-10-25, run agent-harness-2026-10-25-lifecycle, feature L4-01; spec `docs/specs/2026-10-25-resource-lifecycle.md`
§L4 item 1, plan `docs/plans/2026-10-25-L4-gc.md` §1)*

- **Finding:** with `--all-merged`, `cmd_gc` swapped its pattern for `*` and listed `refs/heads/*` and
  `refs/remotes/origin/*`. In a `git for-each-ref` pattern a `*` doesn't cross a `/`: on git 2.43 `refs/heads/*` lists
  `flat` and `main` and misses `harness/a` and `spec/b` (the trailing-slash prefix `refs/heads/` lists all four). Then
  `(( all )) && break` ended the loop after that one pass, so the `harness/*` and `harness-merge/*` passes never ran
  either: `--all-merged` collected *less* than plain gc. Reproduced first in the suite: with merged `spec/x`,
  `docs/y`, `harness/z`, `harness-merge/w` and `flat` pushed, `--all-merged` deleted `flat` only.
- **Choice:** the branch passes are one loop over prefixes, `harness/` and `harness-merge/`, plus the bare prefix
  (`refs/heads/`, `refs/remotes/origin/`: every branch) under `--all-merged`; every pass runs, and a branch an earlier
  pass already handled is skipped (so a `--dry-run` prints each `would:` once). The record-only-tails pass lists
  `refs/heads/harness/` too. Unchanged: merged means an ancestor of `origin/main`, a local delete is `branch -d` (it
  refuses anything unmerged), and `main` and the checkout's current branch are never deleted (nor `origin/HEAD`).
  - **A failed step no longer ends gc.** The suite's first run of the new check found a second bug: `branch -d` measures
    "merged" against the branch's upstream, or HEAD when it has none, while gc measures against `origin/main`. A
    branch with no upstream in a checkout whose `main` is behind `origin/main` (any project checkout nobody pulled) is
    refused, and that refusal, the last command of an `&&` list, ended gc under `set -e` before every later pass.
    `act` now prints `! failed: <argv>` (git's own error above it) and gc goes on. **D1 *default*:** `-d` stays, so
    such a branch is kept locally (its origin copy still goes); Michael may prefer
    `git update-ref -d refs/heads/<b> <sha>` after the `origin/main` check (as safe, never refused).
- **Rejected:**
  - **A `**` pattern** (`refs/heads/**`): `for-each-ref` patterns are `fnmatch` with `WM_PATHNAME` on a full
    refname; whether `**` crosses `/` there depends on git's wildmatch rules per version, and a trailing-slash prefix
    is the documented way to list a hierarchy. A prefix can't miss a level.
  - **Keeping the `break`** with a single `''` pass under `--all-merged`: it would work, but the review asked for one
    loop where every pass runs; the extra passes cost a `for-each-ref` each and make the plain passes the same code.
