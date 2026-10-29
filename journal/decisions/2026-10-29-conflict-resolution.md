# Merge conflicts resolved without Michael: a sorted merge for lists first

*(2026-10-29, run `agent-harness-2026-10-29`, N2-02; spec `docs/specs/2026-10-29-unattended-night.md` §N2, plan
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
- **Rejected:** a union driver without the three-way removal (git's built-in `merge=union` among them): it brings a
  deleted name back, and the conformance check then goes red on a name no file has.
