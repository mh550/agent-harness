# The re-base rule: main moved under a verified lane, disjoint files re-run the suite, overlapping ones re-verify

*(2026-10-27, run agent-harness-2026-10-26, feature P2-03; spec `docs/specs/2026-10-26-lanes.md` §P2 item 2, plan
`docs/plans/2026-10-26-P2-two-lanes.md` §3, its D3)*

- **Finding:** with two lanes, one lane's milestone often lands on `main` while the other is verifying. Then the
  verified tag no longer satisfies the merge invariant (`git merge-tree --write-tree origin/main <tag>` is not the
  tag's tree), and before this `merge_one` stopped: `<m> verified, but main moved since; not merged (needs Michael)`.
  With `MAX_LANES=2` that would be most second milestones of a night, each one a morning job for Michael that the
  harness can do itself.
- **Choice:**
  - `merge_one` returns 3 (`main moved`) with no note, once per main commit (`moved-<m>`), never for a milestone that
    needs Michael; `--open` (a dependency not merged yet) skips the test, since main moves again when it lands.
    `merge_milestones` writes `state/rebase-<m>` and skips any milestone whose lane is alive (that lane merges its own).
  - The lane itself (after its verify) or, once its lane has closed, a **merge lane** (`LANE_MERGE=1`: the slot checked
    out at the tag, only the re-base and the merge) runs `rebase <m>` outside the merge lock: main merged into the
    verified commit (a conflict: `<m> conflicts with main; not merged (needs Michael)`); `git diff --name-only <tag>..HEAD`
    (what main brought in) against `git diff --name-only <base>..<tag>` (the milestone's own, base = the merge base).
  - **Disjoint** (`LANE_REBASE=suite`, the default): `run_init fresh` runs the suite in full on the merged tree in the
    lane's check scope (`lanes/<m>/rebase-check.out` keeps its output); green, `git tag -f -a run/<run>/<m>` at the
    merged commit, pushed with `--force` to that tag ref only (the old commit stays reachable from the lane branch and
    its PR), `<m> re-based on main <sha>: <n> files, disjoint, suite green; re-tagged`, then the merge, which the
    invariant now admits. Red: the slot back at the verified commit, nothing pushed, needs Michael.
  - **Overlapping**, or `LANE_REBASE=verify` in every case: one verify round on the merged tree (`verify <m> rebase`:
    no attempt granted on a failure, escalation kept, the clock `re-base verify round <r> of <MAX_REBASE_ROUNDS>`),
    `MAX_REBASE_ROUNDS` (1) per milestone; a hold moves the tag the same way. Over the rounds: needs Michael. A round
    a usage limit refused gives its round back and leaves `rebase-<m>` for a merge lane after the window. A round
    that doesn't hold un-verifies the milestone: `verified-<m>` and the tag go (locally and on the origin), so the old
    tag can never merge and a later verify tags afresh.
  - The deadline's one verify merges without re-basing: a `rebase-<m>` it leaves waits for the next segment.
  - At most 3 re-bases per lane process (`main moved during 3 re-bases; not merged (needs Michael)`).
  - `harness merge <run>` (any `MERGE_POLICY`) clears `moved-*`, merges, then opens a merge lane for each
    `rebase-<m>` in list order until none is new (a dependent's appears once its dependency merged), and closes the
    slots. `finish` notes a `rebase-<m>` left over: `<m> verified, but main moved since; harness merge <run> re-bases and
    merges it`. `harness continue` clears `rebase-rounds-*` and `moved-*` with the other per-try markers.
  - P1's Minor 7: `verify` removes `nomerge-<m>` at its start, so a clean later verify merges.
  - Checks: `tests/checks/48-lanes-rebase.sh` (disjoint, the invariant, the forced tag the only rewritten ref on the
    origin, overlapping, `LANE_REBASE=verify`, rounds used, a failed round, `harness merge` under `pr`).
- **Rejected:**
  - **Always re-verify** (every re-base a verify session): files main brought in that the milestone never touched
    can't change what its steps check beyond what the suite catches; a session per second lane doubles the verify
    cost of a two-lane night for that. Kept as `LANE_REBASE=verify` for a project where it matters.
  - **Never re-run** (re-tag the merged commit as it is): two clean diffs can still break each other (an import, a
    renamed helper); the merged tree would land unchecked, against the invariant that what lands is what was checked.
  - **Merge without a check** (let the PR merge the old tag onto the moved main): what lands on main would be a tree
    nobody ran, and the invariant check in `merge_one` exists to refuse exactly that.
