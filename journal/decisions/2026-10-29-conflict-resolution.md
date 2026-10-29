# Merge conflicts resolved without Michael: a sorted merge for lists first, then a resolve session, verified

*(2026-10-29, run `agent-harness-2026-10-29`, N2-02 and N2-03; spec `docs/specs/2026-10-29-unattended-night.md` §N2, plan
`docs/plans/2026-10-29-N2-conflict-resolution.md`)*

- **Finding:** two lanes that each add a check get a merge conflict in `tests/fixtures/check-names.txt` (one name per
  line, `LC_ALL=C` sorted, the conformance check's list): both insert a line between the same two neighbours, and git's
  line merge can't place them. Today every such conflict stops the lane and waits for Michael (`needs Michael`), though
  the answer is mechanical: both names, in order.
- **Choice (layer 1):** `lib/merge-sorted.sh`, a git merge driver for one-item-per-line sorted files: the three-way
  union (both sides' lines once each, minus every base line either side removed). A project opts a file in with
  `.gitattributes` (`<path> merge=sorted-union`; this repo: `tests/fixtures/check-names.txt`). The harness sets the
  driver as worktree-local git config (`merge_drivers`, `lib/record.sh`) in the record worktree every segment and in
  each slot at `slot_open`, so it works in the harness's checkouts and never in Michael's (his checkout falls back to
  git's text merge, as before). A side that isn't sorted exits 1 with A untouched: git reports the conflict as usual.
  - Limits: attributes are read from the merging checkout's tree, so a `.gitattributes` only main has applies once the
    lane's tree has it. A line one side removed and the other re-added is removed (the subtraction wins). `git
    merge-tree --write-tree` runs the driver too (git 2.43), so `merge_one`'s check sees the same clean merge.
- **Choice (layer 2):** a conflict layer 1 doesn't settle, in a lane, under `CONFLICTS=resolve` (the default), goes to
  one resolve session (`resolve` in `lib/resolve.sh`, `prompts/resolve.md`): `RESOLVE_MODEL` (opus), `RESOLVE_MAX_TURNS`
  60, `RESOLVE_BUDGET_USD` 5, `RESOLVE_TIMEOUT` 30m, at most `MAX_RESOLVES` (3) per milestone and one per main commit.
  It edits only the conflicted files, `git add`s them and never commits; the driver then checks no unmerged path and no
  marker is left, puts any other path back as git merged it, and commits the merge. `merge_one` no longer opens a
  `merge_conflict` record for a lane's conflict: it returns 3 (`moved-<m>`) and the lane's `rebase` merges main, runs
  the session in place of `git merge --abort`, and a resolved merge always takes the re-base's verify round (the
  disjoint suite-only path is closed to it): the verify re-checks the milestone on the merged commit, the tag moves
  there, and `merge_one` merges only a tree equal to it. `CONFLICTS=michael` keeps today's path, as do `harness merge`
  (`HARNESS_MERGE_ONLY`: no session runs from a CLI command), a conflict with no re-base round left, and one `merge_one`
  meets at the run's end (`finish`: `ended` is written, no lane can re-base, so Michael hears of it then). What the
  session did outside the conflicted files is put back from a NUL-separated `ls-files -s` snapshot (`checkout-index`, so
  a symlink stays a link); a failed session or check resets the slot to the lane's commit and removes the files it
  created; `slot_open` undoes a merge a killed lane left in progress rather than committing its markers as WIP.
- **Rejected:** a union driver without the three-way removal (git's built-in `merge=union` among them): it brings a
  deleted name back, and the conformance check then goes red on a name no file has. Michael for every conflict (today:
  a night with two lanes stops at the first overlap, though most resolutions keep both sides' lines). `git merge -X
  ours/theirs`: it drops one side's intent silently, and nothing checks the result. Resolving on main (a session on the
  main branch after the merge): what lands would be unverified, and main is shared with other runs. A resolve session
  without the verify round: the session runs only the tests for its files, so a resolution that breaks another part of
  the milestone would merge.
