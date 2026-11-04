# A merge survives an origin outage: bounded retries, a card past them, a tag that isn't claimed, gc holds verified work

*(2026-11-04, F1 M1 by hand: `docs/plans/2026-11-04-f1-by-hand.md`; spec `docs/specs/2026-11-04-run-resilience.md` M1.
M1-01 built by run `agent-harness-2026-11-04-2` (`a956311`), M1-02 to M1-04 in Michael's hand session. Reviewed by one
clean-context Opus reader of the diff.)*

## Finding

Run `agent-harness-2026-11-04`: T2 was verified at 06:17 and never merged. From 06:07:42 every push of the record branch
failed (`push of harness/agent-harness-2026-11-04 failed`, `run.log` only). At 06:17:54 GitHub rejected the tag:

```
 ! [remote rejected] run/agent-harness-2026-11-04/T2 -> run/agent-harness-2026-11-04/T2 (failure)
```

while `harness-log.md` said `T2 verified and tagged run/agent-harness-2026-11-04/T2`. `merge_one`'s fetch failed at
06:18:01, :04 and :10 (`T2: fetch of main failed; merged later`, `run.log` only), `lane_done` fell through to
`lane T2 closed (T2 needs Michael: its merge)` with no needs record and no notification, GitHub was back by 06:18:41, and
at 06:19 the queue runner's gc removed the run. On a throwaway run after it, `harness merge` then died asking for
`--spec`, and with one set on `ENOENT … feature_list.json`.

The review of this milestone added three facts. gh's commonest refusal has no `GraphQL:` in it (gh 2.45's binary:
`%s Pull request #%d is not mergeable: %s.`, with `the base branch policy prohibits the merge`). Nothing bounded one try:
git has no timeout of its own, so an origin that takes a connection and never answers held the merge or the record lock
for good. And `CONFLICTS=michael`'s conflict reached `lane_done`'s last branch with its card already open.

## Choice

**1. `origin_try <m> <what> <command…>`** in `lib/record.sh` runs one origin step of a merge with `ORIGIN_WAITS`
(*default* `5 15 30 60 120`: six tries, 230 s of waits; `HARNESS_ORIGIN_WAITS` in tests). Each failed try is a `run.log`
line, a success after one a note. It wraps `merge_one`'s fetch of main, the push of `harness-merge/<run>-<m>`, opening
and merging the PR, the proposed milestone's fetch, every push of the tag, and `harness merge`'s fetch of a missing tag.
**A refusal is one try** (`ORIGIN_REFUSED=1`): a `GraphQL:` line, `is not mergeable: ` and any `[remote rejected] …
declined`. The spec named `GraphQL:` and `(pre-receive hook declined)`; this reads the word, so GitHub's other hook
wordings need no string guessed here. It goes to `merge_refused`, whose card gains a no-PR form (a declined push, a
refused PR). `(failure)`, `(non-fast-forward)` and everything else are retried.

**One try is bounded too** (not in the spec; the reviewer's finding against its own falsifier): `origin_t` is `timeout
-k 5 ORIGIN_TRY_TIMEOUT` (*default* 120 s; `HARNESS_ORIGIN_TRY_TIMEOUT` in tests) around the origin commands of a run's own
path, retried or not: `sync_record_`, `sync_lane`, `sync_main`, `slot_open`, `lane_branch_gone`, the record PR's `gh` calls. So
a hung origin is a failed try, and a step's worst case is 6 × 120 + 230 = 950 s, not 230 s. The CLI's own fetches (`harness
start`'s spec check, `harness merge`'s worktree, gc's, which the runner bounds with `HARNESS_GC_TIMEOUT`) and the desk's and
eval's pushes stay as they were: Michael is at the terminal, or another timeout is.

**2. Past the retries: a note, a card, a notification.** `merge_failed` sets `needs-<m>`, the lane's exit words
`its merge (origin unreachable at <what>)` and the marker `merge-failed-<m>` holding `<what>`, notes `<m>: merge failed at
<what> after <n> tries over <s> s; merged later: harness merge <run>`, opens the 17th reason, `merge_failed` (the item carries
`what`, `tries`, `secs`, `tag_local`, `head`), and sends the needs-you notification, once per `<what>` while the marker
holds it (`harness merge` always says so, and starts no desk). `lane_done` gains `refused-<m>` (`merge refused`) and
`conflict-<m>` (`conflicts with main`; not in the spec, see the finding), and its last `else` opens `merge_failed` with
`what=unknown` before it closes (*default*: fail-closed; its headline is `<m>: its merge stopped with no reason recorded`,
since "origin unreachable" would be a guess). `nomerge-<m>` with no `main-conflict-<m>` (the merge never started: no
conflicted file, `sync_main` records nothing) closes the lane 0, `<m> verified; main did not merge into its lane; its merge
is tried again`: nothing needs Michael yet, and a card with `needs-<m>` would block the re-base that fixes it.

**The marker's life differs from the spec's words.** The spec clears it "on its next success past that step"; a fetch that
works and a main that moved would then leave a verified milestone with no card. `merge_settled` clears it, and the
`needs-<m>` it set, only when the merge lands, or another card or waiting state speaks for it. So the sweep's `merge-failed-<m>
gone` never means a merge went through (that is `merged-<m>`: `milestone merged`); its words are `origin back`, not the spec's
`merge went through`. `finish` sweeps again after its merge, and `harness merge` sweeps after `ended` is written so a
run-level item isn't read as `run continued`.

A `gh pr merge` that fails while its commit is on main is merged: its answer was lost (M1-01's discovery).

**3. The tag: `verified and tagged` only when origin took it.** `tag_push` sets `tag-local-<m>` first (a lane killed in
the retries keeps it) and clears it on success. On failure the note is `<m> verified; tag run/<run>/<m> is local only (push
failed <n> times over <s> s; see run.log)`. `merge_one` pushes a local tag after its fetch and before the branch (the spec's
"first", read against its own `od2`, which expects the failure at the fetch), forced, the local one being the verified one,
and notes `<m>: tag … reached origin`. A *refused* tag holds no merge up: a rule on `run/*` tags is no reason to keep work off
main. `rebase`'s two re-tags carry the same words. A tag that couldn't be made is `<m> verified; tag … could not be made`.

**4. The push streaks.** `sync_record_` and `sync_lane` keep their `run.log` line per failure and add one note at a streak's
start and one at its end (`push-failing`, `lane-push-failing-<m>`: `<epoch> <failures>`; *default*: the lane's has the same
two notes). A streak note on the record is committed at once, and its end pushed: left over, it would keep gc from the worktree.

**5. gc keeps verified, unmerged work; `harness merge` works without the worktree.** `unmerged_of`: `verified-<m>`, no
`merged-<m>`, the tag not an ancestor of `origin/main`. It keeps the worktree and `harness/<run>`, `keeps <wt>: <m> verified,
not merged (harness merge <run>)`, and gc's sweep leaves its items. Lane and merge branches need no hold, which narrows the
spec's "every branch": only one fully in main is ever deleted, so an unmerged milestone's stays and a merged sibling's goes
(`49-lanes-slots`'s rule). A tag on main releases the run; so does a tag gone here and on origin, and `MERGE_POLICY=off` never
holds (there `harness merge` merges nothing). Under `MERGE_POLICY=pr` a proposed milestone is verified and unmerged, so its
worktree now stays until its PR merges (the runner's gc removed it before; `72-u3-review` read that and now reads this).

`merge_worktree` under `HARNESS_MERGE_ONLY`: no spec asked. The local `harness/<run>` when origin's doesn't hold it, which
differs from the spec: the outage ate its pushes and resetting to origin would drop the record's last commits, so the line reads
`(from harness/<run>; harness merge)`. Else origin's, else a new branch from `origin/main`. The record, if absent, from
`origin/main` first (*default*), else the ledger, committed `HARNESS: record restored from <main|the ledger>` and noted. With
none: `harness merge <run>: no record for <run> (not on …, origin/main or <ledger>/<project>/<run>)`, exit 1, the worktree
gone, and the branch too if this call made it. A missing tag comes from origin; gone there too, `<m>: tag … is gone; not
merged`, exit 0.

## Rejected

- **An unbounded retry:** a run would hang on a dead origin.
- **Retrying a refusal:** a decision, not an outage: four minutes for nothing and a wrong "unreachable" card.
- **A card per failed try:** one per step per milestone, refreshed, as every reason.
- **gc keeping every verified run for good:** a tag on main releases it.
- **`harness merge` rebuilding the record from the lane branch:** a lane never carries the record
  (`decisions/2026-10-30-lane-guard-base`).
- **A card for a run that ends with its re-base pending** (`<m> verified, but main moved since`, the reviewer's fourth
  Important): it predates this, isn't about origin, gc now protects the work, and a card would be a false alarm on a run that
  auto-continues. Left for Michael to decide.

## Left, each failing on the safe side

- A PR squash- or rebase-merged by hand leaves its tag off main: gc holds the run until `harness merge` (which lands an empty
  merge) or the tag is deleted. A milestone Michael abandons: the same way out.
- A worktree and `harness/<run>` both removed by hand: `rule`'s `run removed` hides the card from `harness needs`, and a
  `harness continue` resolves it; `harness merge` still works.
- A fetch that loses `refs/remotes/origin/main`'s lock to another lane's retries and notes `origin unreachable`: a wrong
  cause on a line that also counts real outages.
- gh's transient `GraphQL:` errors count as refusals, by the spec's rule.
