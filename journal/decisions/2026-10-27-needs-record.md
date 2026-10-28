# What waits on Michael: one needs record per item, swept by its reason's rule

*(2026-10-28, run agent-harness-2026-10-28, feature U2-03; spec `docs/specs/2026-10-27-status-ux.md` §U2, plan
`docs/plans/2026-10-28-U2-needs-record.md` §1, §2, §4.1–4.3 and §7. Started by U2-03 (the record, the sweep, `harness
needs`); U2-04 adds the cards, U2-05 and U2-06 the openers, U2-07 the readers.)*

- **Finding:** what needed Michael lived in eight places with no shared shape: `parked.json`, `attempts.json`, the
  `needs-<m>`, `conflict-<m>` and `refused-<m>` markers, `lanes/<m>/need`, `ended`'s reason and a dead `driver.pid`.
  `harness parked` read two of them, `harness status` derived the rest, and nothing said when an item was dealt with.
- **Choice:**
  - One JSON file per item, `<state dir>/needs/<seq>.json`, written to a `.tmp` and renamed. Its first 13 keys are the
    n8n event v1's in order (`v id at kind project run feature title body priority click actions context`; `kind` is
    `park`, `needs_michael`, `blocked` or `limit`), so the record is the event; then `ref` (`<run>/<seq>`, what
    `harness needs done` takes), `key` (`<reason>:<subject>`), `reason`, `severity`, `milestone`, `seen`,
    `updated_at`, `card`, `resolved_at`, `resolved_by`, `resolved_why`. `seq` is one past the largest in `needs/` and
    `needs/done/`; `needs_open` (lib/needs.sh) runs under the record lock so two lanes never take one.
  - `open` with the `key` of an open item refreshes it (exit 3): `seen` +1, `updated_at`, title, body, card;
    `id`, `at` and `ref` stay. A new item exits 0.
  - The 15 reasons, their kind, severity (`block` · `warn`) and priority are `REASONS` in lib/needs.mjs (the plan's
    §2.1 table). Each has a rule `sweep` applies, moving the item to `needs/done/` (rename first, then the resolved
    fields written in place) with the rule's words: `feature unparked`, `feature passes`, `attempts reset`,
    `needs-<m> cleared`, `milestone verified`, `milestone merged`, `conflict cleared`, `refusal cleared`,
    `main merged cleanly`, `run continued` (`ended` gone). Every rule yields to `run removed`: the worktree and the
    local `harness/<run>` branch both gone.
  - **(*default*)** `list` is read-only: it applies only `run removed` in memory (a run removed by hand never shows),
    not the other rules; the sweeps the driver and `harness continue` run (U2-05) keep the files current.
  - **(*default*)** `list` adds unstored items the state implies: `driver_crash` (`<run>/crash`) for a `driver.pid`
    naming no live process with no `ended` (a SIGKILL: no trap ran), and `parked` (`<run>/parked:<id>`) for each
    `parked.json` feature that doesn't pass and has no open record (runs parked before U2, and the bridge until U2-05
    opens records). `harness needs done` on one exits 1 and says what resolves it.
  - **Cards (U2-04).** `TEMPLATES` in lib/needs.mjs holds one template per reason as data: `headline`, `cost`, `why`
    (2 to 4 sentences naming the mechanism and its file), `where` rows `{path, line, label, url}`, `options` (exactly
    one with a why: the recommended), `commands`; `card(reason, facts)` adds `blocked`, `commit`, `branch`,
    `question` and `run_state` for a park, `files_from`. A park's question is inbox.mjs's section with its line and
    the record branch's `?plain=1#L<n>` URL, its `where` the question's `Files:` paths (`files_from: question`); its
    commands are `parked.mjs commandsFor`, recomputed by `list` as of now. `main_conflict`'s why names the runs and
    milestones main gained (`mergedBy`: `<run> M1–M5 (PRs #32–#36)`, the run's own left out). A fixture per reason in
    tests/fixtures/needs/ and a check each (tests/checks/59-needs-cards.sh).
  - **(*default*)** `blocked`'s waits are computed in lib/needs.mjs (`waitsOn`: the unfinished features whose
    features.mjs `deps` reach the subject; every unfinished one for a run) when the opener passes no `waits=`, not
    by a `needs_waits` shell function (plan §4.2): one pure function, unit-checked, and the synthesized items get it
    too.
  - **(*default*)** A park's headline keeps its why (`B parked: set the gatus vars`), not the plan's bare `<id> parked`:
    status's NEEDS YOU row shows only the headline. A header too wide for the line drops `since` and the ref to a
    `ref` field and keeps the age.
  - `harness needs` renders each item as a view.mjs card (`rule: false`, `cutFront` for paths at narrow widths, each
    URL on its own line) and a footer; `harness parked` is its alias for text, `harness parked --json` keeps its
    element keys plus `ref` and `card`. A parked feature whose worktree is gone is not synthesized (nothing to answer
    there, as `harness parked` skipped it).
  - **The openers (U2-05).** The lane loop opens `parked` (its question already in the record's INBOX.md, the actions
    the park notification always had) and `given_up` (a session that leaves its feature not passing with its
    attempts used, no park and no escalation round pending) before the session's record commit; `finish` opens
    `feature_list_edits`, `initializer_failed`, `usage_limit` and `weekly_budget` after `ended` and its sweep; the
    EXIT trap opens `driver_crash` when `END_REASON` is still its default, and commits `needs.md` with its note.
    Each record's `body` is the card at 60 columns, plain (a park's: `PARKED: <why>`, the question, the card's
    blocked, where and do, the answer line); its `click` is `needs.md` on the record branch, which `open` and a
    sweep that changes it rewrite (`markdown`), so it is committed with the next record commit. The park
    notification is the record's (`needs_notify`); the others send none of their own (the run-end one carries them).
  - **Sweeps (U2-05):** the lane loop and the coordinator after their unpark (before each pick or open), `finish`,
    `harness continue` after it clears the markers and `ended` (noted in harness-log.md: no driver, so no lock), and
    `harness gc` for the runs whose worktree is gone only (a sweep re-renders `needs.md`, and a stray file in an
    ended run's worktree keeps gc from removing it). **(*default*)** `harness needs done` re-renders nothing: the
    next sweep that runs under a driver brings `needs.md` level.
  - **The git-side openers (U2-06).** `sync_main` on a conflict records the conflicted files (`git diff --name-only
    --diff-filter=U` before the abort) and main's merge subjects for them (`git log --first-parent --merges
    <merge-base>..origin/main -- <files>`: without `--first-parent` git's history simplification hides a merge that
    took a file whole from its second parent, so a path-limited `--merges` prints nothing), opens `main_conflict`
    (subject the lane, `record` on the record branch) and writes `main-conflict-<subject>` with the `origin/main`
    commit; it notifies **once per `origin/main` commit** (new: a main conflict used to be a note only), and a later
    clean merge, or main already in, removes the marker and sweeps (the milestone merged resolves it too: its lane
    may never verify again). A merge that fails without a conflicted file (a dirty tree) is a note only, as before.
    `merge_one`'s conflict on the same `origin/main` is recorded but not notified again. `merge_one` opens `merge_conflict` (the files from
    `git merge-tree --write-tree --name-only`) and clears `conflict-<m>` once the tree merges cleanly; its refusal
    opens `merge_refused` (`click` the PR). `verify`'s three needs lines open `verify_thin`, `verify_red` and
    `verify_recheck` (the failed ids, also in `blocked`; the three now wait on `needs-<m>` before `verified-<m>`, which a
    failed re-base leaves in place, and resolve on `merged-<m>`), `rebase_fail` its reason, `slot_open`'s three conflict
    notes and `slot_fail` `base_conflict` (`with` a ref `git merge` takes, the slot its worktree), and the coordinator's
    `reap` `driver_crash` for a lane that exited without a reason. `needs_you` sends the record's title, body (the
    card), click (`needs.md`, a refusal's PR) and priority, and still starts or briefs the desk, so a main conflict
    now does too.
- **Rejected:** a single `needs.json` per run (two lanes writing it race; a file per item renames atomically).
  Deriving items on every read, as status did (nothing records when an item was handled, or by whom). Sweeping in
  `harness needs` (a phone session runs it to look: it must write nothing).

Updated in place 2026-10-28: U2-04's cards replace the one-line view (the Cards bullets).
Updated in place 2026-10-28: U2-05's openers, notification body and click, and sweeps (the two U2-05 bullets).
Updated in place 2026-10-28: U2-06's git-side openers, the main-conflict notification and needs_you from the record.
