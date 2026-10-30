# The lane guard reverts against the lane's merge-base with main, in the index only

*(2026-10-30, a session for Michael after the read-only investigation of ff2c6de; branch
`fix/2026-10-30-lane-guard-base`. Amends decisions/2026-10-26-lanes, its "a lane commit touching `.harness/runs/` is
reverted" rule.)*

- **Finding:**
  - ff2c6de (10-29 13:33, `HARNESS: reverted edits a R1-03 session may not make`) was `lane_guard "$sstart" R1-03`
    → `restrict "$sstart" runs`: every path under `.harness/runs/` that differed between the lane's HEAD before the
    session and HEAD after was put back to the start (an added one un-indexed, a changed or deleted one checked out).
    R1-03 had run `git merge origin/main` itself mid-session (f721617). That merge brought in segment 1 of
    agent-harness-2026-10-29-2's record (PR #53) and a newer record of agent-harness-2026-10-29; the guard counted
    them as the session's edits, deleted all 13 files of 29-2 and rolled 29's 13 back to their 08:49 state. PR #59
    carried that to main. The final 29-2 record PR (#63) then conflicted, and the end-of-queue gc deleted its branch
    while it was open, which closed it.
  - The same `git checkout $base` overwrote the slot's copy of the record before F repair and the claim read it; and
    the slot's excludes file hides only untracked files, so a copy that a merge made tracked shows as modified to the
    next `git add -A`.
  - gc kept an open record PR's branch only in name: `record_pr_open` asked `gh pr view --json state,title` and read
    `.url`, a field it hadn't asked for. Live gh (2.45) prints that as an empty line, so the answer was never a URL and
    the branch went. The stub gh answered every field whatever `--json` asked for, so the check of that rule passed.
- **Choice:**
  - `lane_guard` diffs `.harness/runs/` from `git merge-base HEAD origin/<main>` (the session's start only when there
    is none): whatever a merge of main brought is main's and the same at both ends. What differs is reset in the index
    only (`git reset <mb> -- .harness/runs/`) and committed; the copy on disk stays for F repair and the claim; paths of
    the run's own record tracked now are marked skip-worktree (as `materialize_` marks them); other runs' records are
    checked out as committed, so no later `git add -A` stages them again. `restrict` loses its `runs` mode.
  - A session that merged main is noted (`<id>: the session merged main into its branch itself (the driver does
    that, at verify)`: a merge since its start whose second parent is in origin/<main>'s history), and the coding
    prompt says never to merge or rebase main into the branch.
  - Defence in depth in `merge_one`: a tag whose `git diff origin/<main>...<tag> -- .harness/runs/` isn't empty is
    pushed as a commit on the tag whose `.harness/runs/` is main's (`runs_as_main`, a scratch index, no checkout;
    dated as the tag, so a retry makes the same commit), noted `<m>: the lane carried .harness/runs/ changes (…);
    merged with main's`. The tag stays the verified commit; the code merges as verified.
  - `record_pr_open` asks for `url,state,title`; the stub gh now answers only the `--json` fields asked for and prints
    a missing one as an empty line, as gh does.
  - The two records are restored from their last good commits (29-2 from #63's head 1a5d0cc, 29 from 5199dc9) in this
    branch's first commit; the ledger needed nothing, #63 stays closed.
- **Checks:** `tests/checks/44-lanes-record.sh`: `lane_guard: a session that merged main keeps main's records
  (merge-base base); its own edits are un-indexed, still on disk` (red on the old guard), `lane_guard: a session's own
  merge of main into its branch is noted`, `merge_one: a tag carrying .harness/runs/ changes merges with main's records
  (a commit on the tag, noted), the code as verified`. The existing `record PR: under pr the end-of-queue gc keeps
  harness/<run> …` (`50-lanes-record-pr.sh`) turned red with the corrected stub and green with the fix.
- **Rejected:**
  - The merge-base base for every `restrict` mode (verify, entry-resume, retro, initializer): a verify's or a resume's
    merge-base with main is before the lane's earlier features, so it would revert legitimate work.
  - Restoring the working tree too (as before): it destroyed the copy the driver reads next.
  - Moving the tag to the stripped commit in `merge_one`: the tag names what was verified.
- **Not done:**
  - The other `restrict` modes keep the session's start as their base, so a verify, resume, retro or initializer
    session that merges main itself would have that merge's changes reverted the same way. None has yet. If the
    `merged main into its branch itself` note ever fires, the follow-up is a merge-tree base: revert only what differs
    from `git merge-tree --write-tree <start> origin/<main>`, i.e. what main and the start would merge to.
  - A merge of main that makes the run's own record tracked overwrites the slot's copy at that moment (git treats an
    ignored file as expendable); the guard can't bring it back. The prompt rule is the only fence.
  - A `--base` branch that carries `.harness/runs/` changes main lacks would now have them reverted in the lane and
    at merge. No base has; a record belongs on main through its record PR only.
