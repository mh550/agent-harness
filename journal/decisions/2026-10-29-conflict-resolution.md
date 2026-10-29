# Merge conflicts resolved without Michael: a sorted merge for lists first, then a resolve session, verified

*(2026-10-29, run `agent-harness-2026-10-29`, N2-02 to N2-05; spec `docs/specs/2026-10-29-unattended-night.md` §N2, plan
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
- **Choice (layer 2's bounds and fallbacks, N2-04):** a session that leaves a marker, ends `UNRESOLVED:` or fails a
  check → the merge aborted and today's path at that place, its needs card (`merge_conflict` from `rebase`,
  `main_conflict` from `sync_main`) carrying `tried` (`a resolve session (<model>, <n> min): <why it stopped>`; the
  `resolve-<m>-<main>` marker keeps it, so a later record for the same main still says it). `rebase` writes
  `conflict-<m>` for that main as `merge_one` does, so the run's end doesn't record and notify it a second time. A
  session refused by a limit is deferred, never a stop: the merge aborted, `limit_raise`, no record; `rebase` puts
  `rebase-<m>` back. In a lane's `sync_main` (the verify's merge of main) a conflict goes to `resolve` too; resolved,
  the verify runs on the merged tree; refused, `verify` returns 2 before its session (no round counted) and the lane
  loop waits for the window, then verifies again. The spec's words were "the verify goes on without main
  (`nomerge-<m>`)": that would run the verify inside the window just refused, and a hold with `nomerge-<m>` ends the
  lane `needs Michael` with no record. A main the lane's `sync_main` already tried (`main-conflict-<m>` at it) is not
  sent to a re-base by `merge_one`: it would only fail and notify again; a newer main is. A re-base whose merge went
  through clears the lane's `main_conflict` (`main_clear`). The re-base round's verify no longer runs `sync_main` (a main that moved since
  is the next re-base's, one place, one record). The record branch's `sync_main` and `slot_open`'s base conflicts keep
  today's path: the first is Michael's run configuration, the second runs in the coordinator, where a 30-minute session
  would hold up every lane. `harness continue` (fresh attempts) clears `resolves-*` and `resolve-*-*` with the rest.
- **Choice (visible, never asked about, N2-05):** a resolution is said, not asked: the caller notes `<m>: main merged in
  by a resolve session (<files>; <model>, <n> min); one verify round follows` (`rebase`) or `…; the verify goes on with
  main merged` (`sync_main`), opens no needs record and sends no `needs you`. `summary.json` gains `conflicts:
  {resolved, escalated, sessions}` (the resolution notes; the distinct milestones whose conflict went to Michael; the
  metrics rows of kind `resolve`) and, beside it, `resolutions: [{milestone, files}]`, which `report.md`'s `| Conflicts
  | … |` row (after `Flakes`) names: the plan put the files nowhere a report could read them, and `conflicts` stays the
  three counts. A milestone whose lane resolved one gets `Merged main in with a resolve session: <files>` in its PR body
  (`$STATE/resolved-<m>`).
- **Rejected:** a union driver without the three-way removal (git's built-in `merge=union` among them): it brings a
  deleted name back, and the conformance check then goes red on a name no file has. Michael for every conflict (today:
  a night with two lanes stops at the first overlap, though most resolutions keep both sides' lines). `git merge -X
  ours/theirs`: it drops one side's intent silently, and nothing checks the result. Resolving on main (a session on the
  main branch after the merge): what lands would be unverified, and main is shared with other runs. A resolve session
  without the verify round: the session runs only the tests for its files, so a resolution that breaks another part of
  the milestone would merge.
