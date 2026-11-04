# Run resilience: merges that survive an origin outage, no default end time, a red verify fixed by a round (2026-11-04)

**Goal.** Three things run `agent-harness-2026-11-04` (D3 of `docs/plans/2026-11-03-test-suite-redesign-dispatch.md`)
and Michael's reading of it on 2026-11-04 asked for, before D4. **M1:** T2 was verified at 06:17 and never merged:
GitHub rejected every push and fetch from 06:07 to 06:18, the merge fell back to `merged later` in `run.log` only, the
lane closed `needs Michael: its merge` with no needs card and no notification, and gc removed the run at 06:19. A merge
step that fails on the origin is retried with bounded backoff; one that outlasts the retries is a note, a card and a
notification; `harness-log.md` never claims a tag the origin didn't take; gc keeps a run with verified, unmerged work;
`harness merge` works after the worktree is gone. **M2:** no run ends on a clock unless asked to: `HOURS` defaults to
none (today 8 h), `--until` stays an option, and the overnight framing leaves the docs, prompts and templates (Michael,
2026-11-04: runs go regardless of the time of day). **M3:** a verify whose full suite is red opens a fix round (a fix
feature appended to the milestone, taken by the lane's next session, then the verify again), at most `MAX_FIX_ROUNDS`
(2) per milestone, then today's `verify_red` card. A measured step toward an agentic loop: the driver decides by a
rule, no LLM decides whether to loop, and every round is counted so a later triage step (F2) can split one red into
several fix features without a format change. Three milestones in series: M1, then M2, then M3.

**Source.** `run.log` and `harness-log.md` of run `agent-harness-2026-11-04` (the lines quoted under M1 are copied from
them); the dispatch list's D3 and F1 rows; `lib/record.sh` (`merge_one` 677, `merge_milestones_` 766, `sync_record_`
828, `sync_lane` 839, `needs_you` 275, `limit_wait` 347, `clock` 378), `lib/lane.sh` (`verify` 55: the tag 123–125, the
red 113 and 133–137; `lane_done` 232–241; the deadline reads 260, 269, 276), `lib/driver.sh` (53, 348–353, 521–525,
545), `lib/config.sh` (12 `HOURS=8`, 31 `DEADLINE_AT=0`), `lib/queue.sh` (20 `UNTIL=${1:-0}`), `lib/resolve.sh` (18),
`bin/harness` (`cmd_start` 269–345, `cmd_merge` 411–419, `cmd_gc` 629–800), `lib/needs.mjs` (the 16 reasons 34–43,
`merge_refused` 223–231, `rule` 391–410), `lib/features.mjs` (`repairList` 366, `kindOf` 304, the lint 149–265),
`lib/summary.mjs` (`build` 168, `reportRows` 336–360), `lib/metrics.mjs` (`append`), `lib/memlint.mjs` (143–165),
`tests/stub-gh.sh`, `tests/checks/87-fast-gate-run.sh` (the two-tier stub suite and `STUB_SLOW_RED`),
`tests/checks/46-lanes-continue.sh` 61–70 (a `pre-receive` hook that refuses one push), `tests/checks/61-needs-git.sh`,
`tests/checks/19-run-9e-deadline-verifies.sh`; `decisions/2026-10-27-needs-record`, `decisions/2026-10-29-rerun-guard`,
`decisions/2026-11-03-fast-gate`, `decisions/2026-10-21-clock-and-bounded-init-output`, `decisions/2026-10-26-verify-before-deadline`.

**Rules.** `CLAUDE.md` binds: worktree only; never touch real runs or real state; never a real notification (the stub
curl, as every check); fakes mirror the live API (the lines below are copied from the run's logs and from git and gh as
they print them; a stub prints those lines or nothing, never a guessed one); every behaviour visible in
`harness-log.md`, `run.log` or a command's output and checked test-first in `tests/checks/` (tier by
`decisions/2026-11-03-suite-tiers`'s 30 s rule: a file timed once, `TEST_JOBS=4 bash tests/run.sh <file>`, under 30 s is
fast, else slow; its names in `tests/fixtures/check-names.txt` and, fast, `check-names-fast.txt`), a pure function's in
`tests/unit/`; `bash -n`, `node --check`; one decision file per milestone; `docs/architecture.md` and `README.md` in the
same milestone. **Proceed on the defaults written here; record them marked *default*; never park.** No LLM decides a
retry, a deadline or a loop: the driver does, by the rules below.

## Depends on

- `main` at or after PR #91 (the dispatch status of 2026-11-04-b); T2 (PR #89) is in.
- M2 after M1, M3 after M2 (each edits `lib/lane.sh`'s verify and the lane loop; M3's rounds need M2's unbounded clock
  to be worth anything). M1's first feature `after: []`, M2's `["M1"]`, M3's `["M2"]`.

---

## M1 · Merges that survive a GitHub outage

**Finding** (run `agent-harness-2026-11-04`; the times are `run.log`'s). From 06:07:42 every push of the record branch
failed: `push of harness/agent-harness-2026-11-04 failed`, in `run.log` only (`sync_record_`, `lib/record.sh` 834, a
`log`, not a `note`), with nothing to say a streak had started or ended. At 06:17:54 GitHub rejected the
tag push:

```
 ! [remote rejected] run/agent-harness-2026-11-04/T2 -> run/agent-harness-2026-11-04/T2 (failure)
```

while `harness-log.md` said `T2 verified and tagged run/agent-harness-2026-11-04/T2` (`lib/lane.sh` 123–125: the note
is unconditional; the push's failure goes to `run.log`). `merge_one`'s fetch failed at 06:18:01, 06:18:04 and 06:18:10
(`T2: fetch of main failed; merged later`: the lane's `merge_own`, then the driver's `finish` → `merge_milestones`; a
`log`, so `run.log` only, and the "later" never comes inside the run: `merge_one` 683 returns 1 after one second try).
`lane_done` (`lib/lane.sh` 232–241) found neither `merged-T2`, `needs-T2`, `rebase-T2`, `proposed-T2` nor `waits-T2` and
fell through to its last line: `lane T2 closed (T2 needs Michael: its merge)`, with no needs record (`harness needs`
showed 0) and no notification. GitHub was back by 06:18:41. At 06:19 the queue runner's `gc` removed the run (its
record branch was record-only; the T2 tag was local, the lane branch unmerged) and the sweep closed its question cards
`by sweep: run removed`. **Confirmed on a throwaway run** (the test stubs, the stub gh refusing the merge so M1 stays
verified and unmerged, then `harness gc`, then `harness merge`): `harness needs <run>` prints `NEEDS YOU 0`; after gc
the worktree and the origin's `harness/<run>` are gone and the local tags `run/<run>/M1`, `run/<run>/M2` remain (tags
are repo-wide: gc never deletes them); `harness merge <run>` reaches `cmd_start` with no worktree and dies
`harness: a new run needs --spec <files> or --brief <text> (or SPEC_FILES in .harness/config.sh)` (exit 1); with
`SPEC_FILES` set it makes a worktree from `origin/main` (`worktree <path> on harness/<run> (from origin/main)`) and the
merge-only driver dies on `ENOENT … .harness/runs/<run>/feature_list.json` (the record is neither on the branch, which
gc deleted, nor on main under `RECORD_PR=off`); the ledger copy `<ledger>/<project>/<run>/feature_list.json` exists.
The same throwaway shows today's refused merge closes its lane with the same words, `lane M1 closed (M1 needs Michael:
its merge)`: `lane_done` reads no `refused-<m>` either.

**Choice.**

1. **`origin_try` (`lib/record.sh`): every origin command of a merge, retried with bounded backoff.** `origin_try <m>
   <what> <command…>` runs the command with stderr appended to `run.log`; on failure it waits the next of
   `ORIGIN_WAITS` (*default* `"5 15 30 60 120"`: five waits, six tries, 230 s in all; `lib/config.sh`, documented in
   `templates/user/config.sh`; `HARNESS_ORIGIN_WAITS` overrides it for tests, as `HARNESS_LIMIT_SLEEP` does the limit
   sleep) and tries again; each failed try is one `run.log` line, `<m>: <what> failed (try <k> of <n>; next in <s> s)`;
   a success after a failure is one note, `<m>: <what> succeeded on try <k> (origin unreachable for <s> s)`; the last
   failure returns the command's exit and sets `ORIGIN_TRIES=<n> ORIGIN_SECS=<s>` for the caller's note. It replaces
   `merge_one`'s one-second second fetch (683) and wraps, in `merge_one`: the fetch of main (`fetch of main`), the
   branch push (`push of harness-merge/<run>-<m>`), `gh pr view`/`gh pr create` (`opening its PR`), `gh pr merge`
   (`merging its PR`); in `merge_milestones_`: the proposed milestone's fetch (774); in `verify` (`lib/lane.sh` 124):
   the tag push (`push of tag run/<run>/<m>`); in `rebase` (204, 120): the re-tag's forced tag push. A GitHub
   **refusal** is not retried: `gh pr merge`'s exit with a `GraphQL:` line on stderr (the shape the stub's
   `--match-head-commit` refusal copies from live gh: `GraphQL: Head branch was modified. Review and try the merge
   again. (mergePullRequest)`) goes to today's `merge_refused` path at once; so does a `! [remote rejected] …
   (pre-receive hook declined)` push (a branch rule). Every other failure (a non-zero exit without those lines: a
   refused connection, a 5xx, `(failure)`) is retried. The lane's `sync_lane` and the coordinator's `sync_record_` are
   not wrapped (they run before every session and at every note: their own cadence is the retry; item 3 says it).
2. **Past the retries: a note, a card, a notification.** `merge_one` returns 1 as today, but first: `touch
   needs-<m>`, `printf '%s' "its merge (origin unreachable at <what>)" > lanes/<m>/need` when `LDIR` is set (the lane's
   exit words), the marker `merge-failed-<m>` holding `<what>`, the note `<m>: merge failed at <what> after <n> tries
   over <s> s; merged later: harness merge <run>`, a needs record of the **new reason `merge_failed`** (subject `<m>`,
   `kind needs_michael`, `block`, `high`; fields `what`, `tries`, `secs`, `tag_local` (item 4), `head`; `headline`
   `<m>: merge failed at <what> (origin unreachable)`; `why` names `origin_try` in `lib/record.sh` and the step; `where`
   `run.log` and the lane branch; options: wait and `harness merge <run>` (recommended), merge the PR by hand when one
   was opened; `commands` `[harness merge <run>]`), then `needs_you` (the record's title `[<run>] <m> needs you`, click
   `needs.md`). Once per `<what>` per milestone while the marker holds it (a `finish` merge after a lane's says nothing
   new). Its sweep rule (`needs.mjs` `rule`): `merged-<m>` → `milestone merged`; `merge-failed-<m>` gone → `merge went
   through`; else kept. `merge_one` clears the marker on its next success past that step. `lane_done` gains two
   branches before its last: `refused-<m>` → `<m> needs Michael: merge refused` (today's card exists); and its last
   `else` opens a `merge_failed` record with `what=unknown` and `needs_you` before `lane_exit 12 "<m> needs Michael:
   its merge"`, so **a lane never closes "needs Michael" without a card** (*default*: fail-closed; the branch should be
   unreachable, and the check in item 6 asserts it across every run of its file). The run-end path is the same code
   (`finish` → `merge_milestones` → `merge_one`), so a run that ends while origin is down ends with the card and the
   notification too (the end notification goes out after it, through ntfy, which is not GitHub).
3. **The tag: "verified and tagged" only when origin took it.** `verify` (`lib/lane.sh` 123–125) tags locally as
   today, then pushes the tag through `origin_try`; on success the note stays `<m> verified and tagged run/<run>/<m>`;
   on failure past the retries the note is `<m> verified; tag run/<run>/<m> is local only (push failed <n> times over
   <s> s; see run.log)` and the marker `tag-local-<m>` is set. `merge_one` pushes the tag first (`origin_try … push of
   tag …`) while `tag-local-<m>` exists and clears it on success, so a merge after the outage carries the tag to origin
   before the branch; `rebase`'s re-tag does the same. The local tag is what `harness merge` merges from (item 5).
4. **The record branch's push streak: one note when it starts, one when it ends.** `sync_record_` (`lib/record.sh`
   828–835) keeps `log "push of harness/<run> failed"` per failure (a `run.log` line, as the incident's) and adds a
   streak: on the first failure after a success (no `push-failing` marker) it writes `push-failing` (`<epoch> 1`) and
   `sync_record` (outside the lock) notes `record branch: push of harness/<run> failed; retrying at every sync (see
   run.log)`; each further failure bumps the count in the marker; the first success after a streak removes it and
   notes `record branch: push of harness/<run> succeeded after <n> failures over <m> min`. The notes are committed with
   the next record commit, so `harness-log.md` on origin shows the streak once the push works. The lane branch's
   `sync_lane` gets the same streak under `lane-push-failing-<m>` with `lane <m>: push of harness-lane/<run>/<m>
   failed; …` (*default*: the same two notes; a lane's commits reach origin at its next session's sync, as today).
5. **gc keeps verified, unmerged work; `harness merge` works without the worktree.** `cmd_gc`: a run with a
   `verified-<m>` and no `merged-<m>` whose tag `run/<run>/<m>` is not an ancestor of `origin/main` (gc has fetched)
   keeps its worktree and every branch of the run, `keeps <wt>: <m> verified, not merged (harness merge <run>)` (a
   dry run says the same; `--all-merged` too); its needs items are not swept `run removed`. A milestone Michael merged
   by hand (the tag on main) no longer holds it. `cmd_merge` → `cmd_start` under `HARNESS_MERGE_ONLY`: no `--spec`,
   `SPEC_FILES` or `--brief` is needed (the `die` at 313 is skipped); with no worktree, one is made on `harness/<run>`
   from `origin/harness/<run>` when it exists, else from `origin/main`, `worktree <wt> on harness/<run> (from <ref>;
   harness merge)`; then, when `.harness/runs/<run>/feature_list.json` is absent from it, the record directory is
   restored from `origin/main`'s `.harness/runs/<run>/` (the record PR; *default* first) else from the ledger's
   `<ledger>/<project>/<run>/` (`ledger()` copies the whole record at finish), committed `HARNESS: record restored
   from <main|the ledger>` and noted; with none, `harness merge <run>: no record for <run> (not on harness/<run>,
   origin/main or <ledger>/<project>/<run>)`, exit 1, and the worktree it made is removed again. Each milestone's tag
   is the local `run/<run>/<m>`, fetched from origin (`git fetch origin tag run/<run>/<m>`) when it is missing locally;
   missing in both, `<m>: tag run/<run>/<m> is gone; not merged` and the next milestone. Then the merge-only block as
   today (`merge_milestones`, re-bases in merge lanes). The `merge_failed` record resolves `milestone merged` at the
   sweep `harness merge` runs.
6. **Checks (written first)**, in a new slow file `tests/checks/88-origin-outage.sh` (several stub runs). The outage
   stub: `tests/stub-git-down.sh`, a `git` wrapper put first on `PATH` for a run (as `15-run-4`'s `gcfail/git` wrapper
   is): while `$STUB_DIR/origin-down` exists, `fetch`, `push` and `ls-remote` whose remote is `origin` fail (push prints
   `tests/fixtures/git-push-rejected.txt` on stderr: the incident's line with the ref substituted, ` ! [remote rejected]
   <ref> -> <ref> (failure)`, then git's `error: failed to push some refs to '<url>'`; fetch prints nothing and exits 128:
   no guessed `fatal:` line), decrementing the file's count and removing it at 0 (`until <epoch>` as the other form);
   every other call `exec`s the real git. The stub gh gets `STUB_GH_DOWN=<n>`: `pr view`, `pr create` and `pr merge`
   fail `<n>` times with gh's own network line, captured once by the session from a real gh (`GH_HOST=localhost:1 gh pr
   view 1`, into `tests/fixtures/gh-down.txt`), never typed from memory. `STUB_REFUSE_MERGE`'s stderr becomes the real
   GraphQL line above (today's `merge refused` is a guessed line). `HARNESS_ORIGIN_WAITS="0 0 0"` in every run of the
   file (four tries per step). The checks: `origin_try` in a plain shell (`HARNESS_HOME=$HH`, `source lib/record.sh`): a
   command failing twice then succeeding → 0, two `failed (try k of 4; next in 0 s)` lines in `run.log`, one
   `succeeded on try 3` note; failing always → its exit after four tries, `ORIGIN_TRIES=4`; a `GraphQL:` stderr → one
   try. Run `od1` (origin down for three fetches at the lane's merge): `M1: fetch of main succeeded on try 4 (origin
   unreachable for <s> s)`, `M1 merged into main`, no `merge_failed` item, no `needs you` post. Run `od2` (down from the
   verify's tag push until after the run's end): `harness-log.md` has `M1 verified; tag run/od2/M1 is local only (push
   failed 4 times over <s> s; see run.log)` and no `M1 verified and tagged`; `run.log` has the fixture's ` ! [remote
   rejected] run/od2/M1 -> run/od2/M1 (failure)` line and `push of harness/od2 failed` lines; `harness-log.md` has
   exactly one `record branch: push of harness/od2 failed; retrying at every sync (see run.log)`; `M1: merge failed at
   fetch of main after 4 tries over <s> s; merged later: harness merge od2`; `needs/*.json` has `merge_failed:M1` with
   `card.commands == ["harness merge od2"]` and `what == "fetch of main"`; one stub-curl post with `Title: [od2] M1
   needs you` and `Priority: high`; `lane M1 closed (M1 needs Michael: its merge (origin unreachable at fetch of
   main))`; the end notification went out; `tag-local-M1` and `merge-failed-M1` exist. Then the flag removed and
   `harness merge od2`: the tag reaches origin (`git -C origin.git tag -l run/od2/M1`), `M1 merged into main`, the
   item in `needs/done/` resolved `milestone merged`, `record branch: push of harness/od2 succeeded after <n> failures
   over <m> min` noted. Run `od3` (od2's state before its merge): `harness gc proj` prints `keeps <wt>: M1 verified,
   not merged (harness merge od3)` and leaves `harness/od3` on origin and the worktree; then `git worktree remove
   --force <wt>` by hand (the incident's gc) and `harness merge od3` → `worktree <wt> on harness/od3 (from
   origin/harness/od3; harness merge)`, `M1 merged into main`. Run `od4` (`MERGE_POLICY=pr`, `RECORD_PR=end`: M1
   proposed, the record PR merged, the worktree and the origin's branch removed by hand): `harness merge od4` →
   `(from origin/main; harness merge)`, no restore note (main has the record), M1 merged by its PR. Run `od5` (as od3
   with `RECORD_PR=off` and the ledger copy deleted): `harness merge od5: no record for od5 (not on harness/od5,
   origin/main or <ledger>/proj/od5)`, exit 1, no worktree left; with the ledger copy present instead: `HARNESS: record
   restored from the ledger` and M1 merged. Run `od6` (`STUB_GH_DOWN=2` at `pr create`): `M1: opening its PR
   succeeded on try 3`, merged. Refusal unchanged: `STUB_REFUSE_MERGE=1` → one try, `merge_refused:M1`, `lane M1 closed
   (M1 needs Michael: merge refused)` (61-needs-git's lines updated to the real GraphQL stderr). **The invariant**, over
   every run of the file: for each `lane <m> closed (<m> needs Michael: …)` line in its `harness-log.md`, a
   `needs/*.json` or `needs/done/*.json` item of that run has `milestone == <m>` and `at` no later than the close.
   `tests/unit/needs.test.mjs`: the `merge_failed` card from `tests/fixtures/needs/merge_failed.json` (every field
   filled, the 59-needs-cards `FILLED` rule; the REASONS line and the `16 fixtures` check become 17); the sweep rule's
   three outcomes. `bash -n` on `lib/record.sh`, `lib/lane.sh`, `lib/needs.sh`, `bin/harness`, the two stubs; `node
   --check lib/needs.mjs`. Files touched: `lib/record.sh`, `lib/lane.sh`, `lib/config.sh`, `lib/needs.mjs`,
   `lib/needs.sh`, `bin/harness`, `templates/user/config.sh`, `tests/stub-git-down.sh`, `tests/stub-gh.sh`,
   `tests/fixtures/{git-push-rejected.txt,gh-down.txt,needs/merge_failed.json}`, `tests/checks/88-origin-outage.sh`,
   `tests/checks/{59-needs-cards,61-needs-git}.sh`, `tests/unit/needs.test.mjs`, the two name fixtures.
7. **Decision and docs.** `journal/decisions/2026-11-04-origin-retries.md` (finding: the incident with the lines above
   · choice: items 1–5 with every default · rejected: an unbounded retry (a run would hang on a dead origin: the waits
   bound it at 230 s); retrying `gh pr merge` on a `GraphQL:` refusal (a decision, not an outage: four minutes for
   nothing and a wrong "unreachable" note); a card per failed try (one per step per milestone, refreshed, as every
   reason); gc keeping every verified run for good (a tag on main releases it); `harness merge` rebuilding the record
   from the lane branch (the lane never carries the record: `decisions/2026-10-30-lane-guard-base`)).
   `docs/architecture.md` §3 (`record.sh`: `origin_try`; `needs.mjs`: 17 reasons), §4 (`merge-failed-<m>`,
   `tag-local-<m>`, `push-failing`, `lane-push-failing-<m>`), §7 (a `Origin retries` row: when, what, the notes), §8
   (`run/<run>/<m>`: local until pushed; `harness merge` after gc), §10 (`ORIGIN_WAITS`), §14 (the runbook row
   `Merge refused … or conflicted` gains `origin was down: harness merge <run>, worktree or not`); `README.md` *What a
   run is* (the merge's retries and the card) and the `harness merge` row of the command table.

### M1-review

Sized to the milestone: an Opus reader of the diff; hardest: every `return 1` of `merge_one` reaching a card or a
known reason (the invariant), `origin_try` never retrying a refusal, the tag's two notes never both appearing for one
verify, `cmd_merge` leaving nothing behind on `no record`, and gc's keep rule releasing a milestone merged by hand.

---

## M2 · No default end time

**Finding.** Every `harness start` or `continue` segment ends `deadline` eight hours in: `lib/config.sh` 12 `HOURS=8`,
`lib/driver.sh` 53 `DEADLINE=$(( T0 + HOURS * 3600 ))`, cut shorter by `--until` (`DEADLINE_AT`). A deadline end never
continues by itself (`lib/driver.sh` 348–353: only a session cap queues a continuation) and gives each complete,
unverified milestone one verify first (`deadline_verify`). The queue runner already has no end of its own (`lib/queue.sh`
20 `UNTIL=${1:-0}`: `--until` or none). Michael, 2026-11-04: runs go regardless of the time of day; the night is not the
unit. The docs, prompts and templates still frame a run as a night (`README.md` 33 `Queue a night's work at once`, 42
`--spec OVERNIGHT.md`, 45 `harness queue start --until 07:30 … each one stops by then`, 57 `the night's queue`, 178 and
189 `The morning after:`, 182 `after a night at two lanes`, 251 `merges that night`, 300 `the "morning session"`, 343 `the
overnight run`; `docs/architecture.md` 284 (the `deadline` end reason: `queue it for another night`), 582, 698 `a
night's spend`, 724 `a fixed-time morning session`; `CLAUDE.md` 7 `This repo runs Michael's nights`, 70 `Tonight's
scope`; `prompts/parts/where-things-go.md` 6, `prompts/parts/where-things-go-readonly.md` 6, `prompts/draft-claude-md.md`
8 and 14, `templates/project/CLAUDE.md` 22, `templates/user/config.sh` 29 `once a night`; comments `lib/queue.sh` 81
`for another night`, `lib/driver.sh` 274 `the same night`, `bin/harness` 533 `a past night's deadline`; `lib/memlint.mjs`
143–165: the `night-scope` finding `(night scope goes in the run's brief)`).

**Choice.**

1. **`HOURS` defaults to none.** `lib/config.sh` 12: `HOURS=""` (empty or `0`: no end time; a whole number: that many
   hours, as before; *default* the empty string, documented in `templates/user/config.sh` as `# HOURS=` with the rule
   and the bounds below). `lib/driver.sh` 53: `DEADLINE=0`; `HOURS` a whole number over 0 → `T0 + HOURS * 3600`;
   `DEADLINE_AT` set → it, or the earlier of the two; any other `HOURS` → `log "HOURS=<v> in the config is not a whole
   number of hours"` and exit 1 before anything runs (*default*: refuse, as a bad `MAX_PARALLEL_RUNS` is refused by
   the runner; a typo must not silently become no deadline or eight hours). `run.log`'s first line gains `· ends
   <HH:MM>` or `· no end time`. `HARNESS_DEADLINE=0` reaches the lanes.
2. **Every reader of `DEADLINE` treats 0 as none.** `lib/driver.sh` 521 and 545 (`(( DEADLINE && now >= DEADLINE ))`),
   `lib/lane.sh` 260, 269, 276, `lib/record.sh` 351 (`limit_wait` caps the wait at the deadline only when there is one:
   with `DEADLINE=0` today's line computes a negative cap and **skips the wait**, so a usage-limit window would not be
   waited for at all: the first check below fails on today's code the moment the default changes), `lib/resolve.sh` 18
   (`less than RESOLVE_TIMEOUT before the deadline` only with a deadline), `deadline_verify` (unreached without one).
   `clock()` (`lib/record.sh` 378–382): with a deadline the line is unchanged (`run 3h10m of 8h, ends 03:55`); without,
   `run 3h10m (no end time)` (*default* wording; the four copies of the check `the prompt says the time, the budget
   and the attempt` in `08`, `13`, `14`, `15` accept both forms). `AUTO_CONTINUE`'s `DEADLINE_AT` test (353) already
   reads 0 as none. The end reason `deadline` stays, for runs that set one.
3. **What still bounds a run** (the decision file and §7 say it in one table): `MAX_SESSIONS` (`auto`: 3 per feature
   + 5), `MAX_ATTEMPTS` per feature, `MAX_VERIFY_ROUNDS`, `MAX_REBASE_ROUNDS`, `MAX_RESOLVES`, M3's `MAX_FIX_ROUNDS`,
   `MAX_LIMIT_HITS` and the limit waits, `WEEKLY_STOP_AT`, `AUTO_CONTINUE_MAX`, `SESSION_TIMEOUT` and
   `SESSION_BUDGET_USD` per session, and Michael's `stop`, `pause` and `--until`. A run without a deadline ends on one
   of these; nothing else changes in when it ends.
4. **`--until` stays an option, documented as one.** `harness start --until HH:MM`, `continue --until`, `queue start
   --until` (every run it starts gets that deadline) keep their behaviour and their rows; the README's quick start no
   longer shows `--until` as the way a queue ends, and the end-reason row at `docs/architecture.md` 284 reads `the
   run's --until or HOURS time is up (none unless set)`.
5. **The framing, out of the memory the sessions read and the docs.** `README.md`: 33 `Queue work at once`, 42 a spec
   path that is not `OVERNIGHT.md`, 45 `harness queue start   # tmux h-queue; runs go one after another until the
   queue is empty (--until HH:MM: no run starts after it, and each one stops by then)`, 57 `the queue`, 178 and 189
   `After the run:`, 182 `after a run at two lanes`, 251 `merges in that run`, 300 `replaces the hand triage after a
   queue`, 343 `a harness run never does`; `docs/architecture.md` 284 (item 4), 582 (the runner's `--until` sentence
   stays, as an option), 698 `a run's spend`, 724 `a fixed-time triage session`; `CLAUDE.md` 7 `## This repo runs
   Michael's harness runs: what that means for a session working on it`, 70 `The run's scope (what to build, drop or
   do first) → the run's brief, never this file.`; the same line in `prompts/parts/where-things-go.md` 6,
   `prompts/parts/where-things-go-readonly.md` 6 (`The run's scope → the run's brief, which is Michael's.`),
   `prompts/draft-claude-md.md` 8 (`the run's scope → the run's brief`) and 14 (`Nothing about a particular run's
   scope.`), `templates/project/CLAUDE.md` 22; `templates/user/config.sh` 29 `(2 once a run at 1 shows the memory for
   it)`; the comments at `lib/queue.sh` 81 (`leaving the queue for later`), `lib/driver.sh` 274 (`a later harness
   continue`), `bin/harness` 533 (`an earlier start's deadline`). `lib/memlint.mjs`: the rule stays (the patterns
   `tonight`, `this run`, `this slice`, `as of <date>`), its check id becomes `run-scope` and its finding `"<match>"
   (run scope goes in the run's brief)` (*default*: the id is one of its words; `README.md` 107 and the memlint
   checks name the new id; the alternative, the old id with new words, is the rejected row). Specs, plans and decision
   files are history and keep their nights; `prompts/project-catchup.md` 75 and 107 (a catch-up's rule about lines
   tied to a night or run) keep `night` as a thing to delete. A lint (item 6) holds the rest.
6. **Checks (written first)**, in a new file `tests/checks/89-no-deadline.sh` (two short stub runs and shell units;
   predicted fast, timed once by the rule): `harness_config /nonexistent` with `HARNESS_CONFIG=/dev/null` → `HOURS`
   empty; a stub run `nd` with no `--until`: `run.log`'s first line ends `· no end time`, the coding prompt's line
   matches `Clock: … · run [0-9]+h[0-9]{2}m \(no end time\) · this session: …`, `ended` starts `done`, no `deadline
   reached` note; `nd` with `LIMIT_UNTIL` planted 3 s ahead before its first coding session → `usage-limit window
   (shared by all runs): waiting until <HH:MM> (0 min)` noted **before** `session 1` in `run.log` (today's code skips
   it once `DEADLINE=0`); `HOURS=1` in `run.env` → `· ends <HH:MM>` and the clock's `of 1h, ends` form; `HOURS=abc` →
   `harness start` exit 1 with `HOURS=abc in the config is not a whole number of hours`, no worktree made; `18-run-9c`'s
   past `--until-epoch` still ends `deadline` (its check unchanged); `resolve_ok` sourced with `DEADLINE=0` is not
   refused for the deadline; `lib/memlint.mjs` on a file with `tonight` prints the `run-scope` id and `(run scope goes
   in the run's brief)` (`39-memlint-m4` and `tests/unit/memlint.test.mjs` updated: the name, the text). The lint:
   `grep -rniE "\btonight\b|\bovernight\b|\bnights?\b|night's|morning after|morning session"` over `README.md`,
   `docs/architecture.md`, `CLAUDE.md`, `prompts/`, `templates/`, `lib/`, `bin/` finds only `lib/memlint.mjs`'s
   pattern line and `prompts/project-catchup.md`'s two (an allow-list in the check, by file and word). `bash -n` on
   `lib/driver.sh`, `lib/lane.sh`, `lib/record.sh`, `lib/resolve.sh`, `lib/config.sh`, `bin/harness`; `node --check
   lib/memlint.mjs`. Files touched: those, `templates/user/config.sh`, `templates/project/CLAUDE.md`, `CLAUDE.md`,
   `README.md`, `docs/architecture.md`, `prompts/parts/where-things-go*.md`, `prompts/draft-claude-md.md`,
   `lib/queue.sh` (a comment), `tests/checks/{08,13,14,15}-*.sh` (the clock regex), `tests/checks/39-memlint-m4.sh`,
   `tests/unit/memlint.test.mjs`, `tests/checks/89-no-deadline.sh`, the name fixtures.
7. **Decision and docs.** `journal/decisions/2026-11-04-no-default-end-time.md` (finding · choice: items 1–5, the
   bounds table · rejected: a longer default (any number is still a clock); ending on the five-hour window's reset
   (the limit waits already shape that); a continuation queued by a deadline end (there is no deadline to continue
   past; `--until` runs stay as they are); keeping the night words in the sessions' memory files with the lint off).
   `docs/architecture.md` §5 (the life of a run: the end reasons), §7 (a `Bounds` row listing item 3), §10 (`HOURS`,
   `ORIGIN_WAITS` beside it); `README.md` *What a run is* (how a run ends) and *Steering*; `templates/user/config.sh`.

### M2-review

Sized to the milestone: a Sonnet reader of the diff; hardest: every `DEADLINE` read (the grep in the Source list is
the inventory: none may read 0 as "now"), `limit_wait`'s cap, the clock's two forms in the four checks, and the lint's
allow-list being exactly the two files.

---

## M3 · A red verify is fixed, not parked

**Finding.** A milestone whose features all pass gets a verify session; its evidence holds (`result=hold`), then the
full suite runs on the slot's tree (`lib/lane.sh` 113: `if [[ $result == hold ]] && ! green; then result=red; fi`,
after `check.sh`'s rerun guard, so a flake is already green there) and a red stops the milestone: `needs-<m>`, the
note `verify <m>: the suite is red on the verified tree (main had nothing new: a slow-tier red the fast gate let
through); not verified (needs Michael)` (variant `own`) or `(main merged in)`, the `verify_red` card, a notification
(133–137, 159–161). Since `decisions/2026-11-03-fast-gate` a feature passes on the fast tier, so a slow-tier red is the
expected way a milestone's own mistake shows: the fix is one coding session's work, and the harness has the names
(`check-<key>.out`'s `FAIL <name>` lines and its `HARNESS_FAILED=<files>` line). Michael, 2026-11-04: fix it, measure
whether one fix per red clears it, and shape the record so a later triage (F2) can split one red into several issues.

**Choice.**

1. **The rule.** In `verify`, `result=red` with `fix-rounds-<m>` (a state counter, kept across `continue`s;
   *default*) under `MAX_FIX_ROUNDS` (`lib/config.sh`, *default* 2, in `templates/user/config.sh`) opens a fix round
   instead of the card: no `needs-<m>`, no record, no notification. At `MAX_FIX_ROUNDS` the path is today's, its note
   ending `; not verified (needs Michael) after <n> fix rounds (<ids>)`, its `verify_red` card's `why` gaining the
   rounds and their ids, its notification as today. `MAX_FIX_ROUNDS=0` is today's behaviour from the first red. A
   suite-red verify is not a verify round: `verify-rounds-<m>` is put back to what it was (the evidence held; the
   verdict was the suite's), so a milestone whose red is fixed still has its `MAX_VERIFY_ROUNDS` re-checks. A flake
   never opens a round: `green` already reran the red once (`decisions/2026-10-29-rerun-guard`) and reached `hold`.
2. **The round.** `r = fix-rounds-<m> + 1`, written. The names come from the lane's `check-<key>.out` of that run
   (`red-<key>`'s stored names when the marker exists, else the output's last `HARNESS_FAILED=` line, and every `FAIL
   <name>` line; without a `HARNESS_FAILED=` line the files are `whole suite`); its last 200 lines are copied into the
   record as `.harness/runs/<run>/fix/<m>-<r>.out` and committed. The fix feature is appended to the record's
   `feature_list.json` under the record lock by a new pure `features.mjs` command, `fix-add <list> <m> <r> <issue>
   <names…> -- <files…> -- <out> <check>` (printing the id):

   ```json
   { "id": "<m>-fix<r>", "milestone": "<m>", "kind": "fix", "issue": "all", "round": <r>,
     "after": ["<the milestone's last feature id in list order>"], "model": "<WORKER_MODEL>",
     "fix_names": ["<FAIL names>"], "fix_files": ["<HARNESS_FAILED files>"], "fix_out": ".harness/runs/<run>/fix/<m>-<r>.out",
     "description": "fix round <r> of <m>: the full suite is red on the verified tree (<k> failing: <up to 5 names>[ +n])",
     "steps": [ "`<check> <files>` exits 0 (the HARNESS_FAILED files of .harness/runs/<run>/fix/<m>-<r>.out)",
                "`<check> --fast` exits 0",
                "`<check>` exits 0 (the full suite; the harness runs it at the verify)" ],
     "passes": false }
   ```

   (`issue: "all"`: this milestone makes one issue per red; a triage session later writes one fix feature per issue
   with its own `fix_names`, the same shape. `kind: "fix"` is explicit, so `kindOf` returns it; the step lint stays
   clean on these steps, asserted. `after` the milestone's last feature so `F next` offers it only in its lane and
   nothing waits on it; `repair`'s `before.json` is snapshotted after the append, so a session's copy is judged
   against the list with the fix in it.) The note: `verify <m>: the suite is red on the verified tree (<own|main
   merged in>); fix round <r> of <MAX_FIX_ROUNDS>: <m>-fix<r> appended (<k> failing: <names>)`. `verify` returns 1;
   the lane loop's next pick is the fix feature (milestone-done is false by it).
3. **The fix session.** A coding session like any other (`prompts/coding.md`), in the lane's slot, counted against
   `MAX_SESSIONS`, `MAX_ATTEMPTS` attempts (given up → `given_up` card and the run ends as for any given-up feature).
   Its prompt gets one line under *This session* through a `{{FIX}}` slot (empty for every other feature, as
   `{{REVIEW_DIFF}}`): `Fix round <r> of <max>: the full suite is red on this milestone's verified tree; failing:
   <names>; its output: <fix_out>; your feature passes on \`<check> <files>\` and \`<check> --fast\` green, and the
   verify then runs the full suite.` `prompts/coding.md` gets a paragraph for `kind: fix` (fix the cause, never the
   check's assertion to make it pass; a check that was wrong is changed with its reason in the entry). **Its `passes`
   gate**: after the session, for `kind == fix`, `green_fix`: `"$CHECK" <fix_files>` (the subset form; the full suite
   when the files are `whole suite`) and `green_fast`, both green; a red un-passes it, `<id> un-passed: <check
   <files>|fast tier> red after the session`. Its metrics row's `role` is `fix`.
4. **The verify again, and the counting.** The fix passes → milestone-done → `verify` as today (a fresh verify
   session re-runs every step, the fix's included, the full suite on the tree): hold and green → `<m> verified and
   tagged … (after fix round <r>)`, tag, merge; red → item 1 (round `r + 1` or the card). `metrics.jsonl` rows, written
   by a new pure `metrics.mjs` command `fix-round` (`append`'s shape, no session): at the open, `{"kind": "fix_round",
   "run", "milestone", "round", "issue": "all", "feature": "<m>-fix<r>", "failed_before": [names], "files_before":
   [files], "at"}`; at the next verify's suite verdict, `{"kind": "fix_result", "run", "milestone", "round", "issue",
   "failed_after": [names, empty when green], "fixed": <failed_after is empty>, "at"}`. `summary.mjs build` adds
   `fix_rounds: { opened, fixed, by_milestone: { "<m>": { opened, fixed } } }` from those rows; `report.md` and
   `harness report` get a `Fix rounds` row after `Flakes`: `2 opened · 1 fixed (M1 1 of 1, M2 0 of 1)`, `0` for none,
   no row for a summary from before this milestone; `Spend by role` lists `fix`. The retro prompt's `{{SUMMARY}}`
   carries it. The card at the end of the rounds names the rows (`fix_result`'s `failed_after` per round) so a reader
   sees what each fix left standing.
5. **Checks (written first)**, in a new slow file `tests/checks/90-fix-rounds.sh` with `87-fast-gate-run`'s two-tier
   stub suite extended: bare red on `BROKEN`, `BROKEN-SLOW` (`FAIL t1 (BROKEN-SLOW)`, `HARNESS_FAILED=t1`) or
   `BROKEN-SLOW2` (`FAIL t3 (BROKEN-SLOW2)`, `HARNESS_FAILED=t3`); `--tier fast` red on `BROKEN` or `BROKEN-FAST`; a
   subset red only on the named file's marker (`t1` on `BROKEN-SLOW`, `t3` on `BROKEN-SLOW2`); `STUB_FLAKE_ONCE=1`:
   the first bare call after `flake-armed` exists is red (`FAIL t2`, `HARNESS_FAILED=t2`) and removes it. The stub's
   coding branch for an id matching `*-fix[0-9]*`: `STUB_FIX=rename` moves `BROKEN-SLOW` to `BROKEN-SLOW2`,
   `STUB_FIX=fix` removes both, `STUB_FIX=none` leaves them. Run `fx1` (`STUB_SLOW_RED=B STUB_FIX=fix`): B passes on
   the fast tier; the verify is red; `harness-log.md` has `verify M1: the suite is red on the verified tree (main had
   nothing new: a slow-tier red the fast gate let through); fix round 1 of 2: M1-fix1 appended (1 failing: t1)` and no
   `needs Michael`; no `needs-M1`, no `verify_red` item, no `needs you` post; `feature_list.json` has `M1-fix1` with
   `kind fix`, `issue all`, `round 1`, `after ["B"]`, `fix_names ["t1"]`, `fix_files ["t1"]`, the three steps, and `F
   lint` is clean on it; `fix/M1-1.out` is in the record with the `FAIL t1` line; the fix session's prompt has `Fix
   round 1 of 2` naming `t1` and the output path; `suite-args.log` shows `t1` then `--tier fast` after the fix
   session's line; `M1-fix1 · … · passes=true`; two `verify M1` sessions; `M1 verified and tagged run/fx1/M1 (after fix
   round 1)`, merged; `metrics.jsonl` has a `fix_round` row (`failed_before ["t1"]`) and a `fix_result` row
   (`failed_after []`, `fixed true`), the fix session's row `role fix`; `summary.json` `fix_rounds.opened 1, fixed 1`;
   `harness report fx1 --md` prints `Fix rounds | 1 opened · 1 fixed (M1 1 of 1)`; `verify-rounds-M1` is 1. Run `fx2`
   (`STUB_SLOW_RED=B STUB_FIX=rename`): round 1 (`t1`), the fix session passes its gate, the second verify is red on
   `t3`, round 2 (`fix round 2 of 2: M1-fix2 appended (1 failing: t3)`), its session renames nothing more (the stub's
   second fix session is `none`), passes its gate, the third verify is red → `verify M1: … not verified (needs Michael)
   after 2 fix rounds (M1-fix1, M1-fix2)`, `needs-M1`, the `verify_red:M1` item (`variant own`, its `why` naming both
   rounds), one `[fx2] M1 needs you` post, the run ends `waiting on Michael` as today; rows: round 1 `failed_before
   ["t1"]`, `failed_after ["t3"]`, `fixed false`; round 2 `["t3"]`, `["t3"]`, `false`; `fix_rounds.opened 2, fixed 0`;
   the report row `2 opened · 0 fixed (M1 0 of 2)`. Run `fx3` (`STUB_FLAKE_ONCE=1`, armed before the verify): `flaky:
   t2 …` noted, `M1 verified and tagged run/fx3/M1`, no fix feature, `fix_rounds.opened 0`, no `Fix rounds` value but
   `0`. Run `fx4` (`MAX_FIX_ROUNDS=0` in `run.env`, `STUB_SLOW_RED=B`): today's card at the first red, no feature
   appended. Run `fx5` (`STUB_SLOW_RED=B STUB_FIX=none`, `MAX_ATTEMPTS=1`): the fix session leaves `BROKEN-SLOW`, `M1-fix1
   un-passed: check t1 red after the session`, `given_up` item for `M1-fix1`, the run ends `blocked on M1-fix1`. The
   unit tier: `tests/unit/features.test.mjs` (`fixFeature`: the id, `after`, the steps, the description's `+n`, the
   lint clean; `repairList` with the appended feature in `before`); `tests/unit/metrics.test.mjs` (`fixRound` and
   `fixResult` rows); `tests/unit/summary.test.mjs` (`fixRounds(rows)` counts; the report row's three texts; no row
   without the key). `bash -n` on `lib/lane.sh`, `lib/record.sh`, `lib/config.sh`; `node --check` on `features.mjs`,
   `metrics.mjs`, `summary.mjs`, `prompt.sh`'s template reader. Files touched: `lib/lane.sh`, `lib/record.sh`
   (`green_fix`), `lib/config.sh`, `lib/features.mjs`, `lib/metrics.mjs`, `lib/summary.mjs`, `lib/needs.mjs` (the
   `verify_red` why), `lib/prompt.sh`, `prompts/coding.md`, `templates/user/config.sh`, `tests/stub-claude.sh`,
   `tests/checks/90-fix-rounds.sh`, the three unit files, the name fixtures.
6. **Decision and docs.** `journal/decisions/2026-11-04-fix-rounds.md` (finding · choice: items 1–4, `issue: all`,
   the two rows, the counters · rejected: letting the verifier decide to loop (the verifier is read-only and the rule
   is the driver's); an un-pass of the milestone's features (they hold; the suite is the milestone's own); fixing in
   the verify session; unlimited rounds (`MAX_FIX_ROUNDS` bounds the spend, with `MAX_SESSIONS`); a triage session now
   (F2: after the rounds' data says one fix per red is not enough)). `docs/architecture.md` §5 (the verify step: red →
   fix round → verify again), §6 (the feature-list contract: `kind fix`, `issue`, `round`, `fix_names`, `fix_files`,
   `fix_out`; the driver as the one list writer besides the initializer and repair), §4 (`fix-rounds-<m>`, `<run
   dir>/fix/`), §7 (a `Fix round` row), §10 (`MAX_FIX_ROUNDS`), §11 (the `Fix rounds` measure); `README.md` *What a run
   is* and the report's rows; `templates/user/config.sh`.

### M3-review

Sized to the milestone: an Opus reader of the diff; hardest: the rule firing only on `result=red` after the rerun
guard (never on a flake, never past the count), `verify-rounds-<m>` put back, the fix feature surviving `repair` and
`lane_guard`, `green_fix`'s two gates, the rows' pairing by milestone and round, and the card at the end naming every
round.

---

## Milestones

| M | Contents | After |
|---|---|---|
| M1 | `origin_try` and `ORIGIN_WAITS`; `merge_failed` (reason, card, sweep rule, `lane_done`'s guard); the tag's two notes and `tag-local-<m>`; the push streak notes; gc's keep rule; `harness merge` without a worktree (the record from main or the ledger); the git-down and gh-down stubs; `2026-11-04-origin-retries`; M1-review | `[]` |
| M2 | `HOURS` empty; `DEADLINE=0` in every reader; `limit_wait`'s cap; the clock's second form; `· no end time`; the refusal of a bad `HOURS`; the bounds table; the docs, prompts, templates and comments; memlint's `run-scope`; the lint; `2026-11-04-no-default-end-time`; M2-review | `["M1"]` |
| M3 | `MAX_FIX_ROUNDS`; the rule in `verify`; `fix-add`; the fix feature and its prompt line; `green_fix`; the `fix_round` and `fix_result` rows; `fix_rounds` in `summary.json` and the report row; the card after the rounds; the stub suite's third marker and `STUB_FIX`; `2026-11-04-fix-rounds`; M3-review | `["M2"]` |

Plan each as three or four features, the last the review feature (the brief's own words). The suite ends green at
every milestone (`bash tests/run.sh` at verify; the fast tier while iterating; a feature that touches `lib/driver.sh`,
`lib/lane.sh`, `lib/record.sh`, `bin/harness` or a slow check file also runs that file before its session ends).

## Predictions (for the retro and the supervisor; against the runs after this one on this repo and the others)

| Measure | now | after M1 + M2 + M3 |
|---|---|---|
| a verified milestone left unmerged by an origin failure, per run | 1 in the 3 runs of 2026-11-03/04 (T2) | **0** per 20 runs |
| `lane <m> closed (<m> needs Michael: …)` without a needs item | 1 (T2) | **0** (the invariant) |
| merge steps that `succeeded on try k` (an outage the retries covered) | – | 0–2 per 20 runs (GitHub's incidents, not ours) |
| a run's `harness-log.md` saying `verified and tagged` for a tag origin lacks | 1 (T2) | 0 |
| runs that end `deadline` without `--until` or `HOURS` | every segment past 8 h | **0** |
| runs that end `session cap`, `done`, `blocked`, `waiting` or a budget | the rest | all |
| verify reds that opened a fix round | 0 (every one a card) | every one under `MAX_FIX_ROUNDS` |
| fix rounds that cleared the red (`fixed` of `opened`) | – | **≥ 70 %** (one fix per red; under it, F2) |
| `verify_red` cards per 20 milestones | 1 (`fs`-type reds since the fast gate: T2's run had 0 of 2) | ≤ 1 |
| sessions per milestone with a red verify | n + 1 verify | n + 1 verify + 1–2 fix + 1–2 verify |
| full-suite runs per milestone | 1–2 (verify, the hold's re-check) | +1 per fix round |
| `MAX_SESSIONS` ever exceeded | 0 | 0 |

Falsifiers: a milestone verified and unmerged with no card or notification (the invariant); a retry that outlasts
its waits (a hang on a dead origin: the bound is 230 s per step); a `GraphQL:` refusal retried; a run past
`MAX_SESSIONS` or the weekly budget (M2 removed a bound it should not have); a usage-limit window not waited for
(`limit_wait`'s cap); a fix round opened on a flake (a `flaky:` note and a fix feature in one verify); a fix session
that edits a failing check's assertion to pass (the review feature reads every fix diff); fix rounds leaving the red
standing in 30 % or more of the rounds, or reds whose names span unrelated files (F2's trigger, the dispatch list's
row).

## Not in this run

The triage session (F2: a read-only session grouping a red's failures into issues, one fix feature each: the
`issue` field and the rows are its shape, nothing of it is built); retrying a lane's or the record's own push streak
beyond its cadence; a notification per retry; `harness merge` rebuilding a record from the lane branch; the deadline
verify's removal (`deadline_verify` stays for runs with a deadline); renaming `night-scope` lines in specs, plans and
decision files (history); any change to the queue runner's `--until`; the resident helper (D4), the slim suite (D6).

## After the run (Michael)

- Nothing to configure: `HOURS` and `ORIGIN_WAITS` take their defaults from `lib/config.sh`; `MAX_FIX_ROUNDS=2`. A
  project that wants a clock sets `HOURS=<n>` in its `.harness/config.sh` or starts with `--until`.
- After the next three runs on this repo (D4 onward): `grep -c "fix round" <run dir>/harness-log.md` and `jq
  .fix_rounds <run dir>/summary.json` per run against the table; `grep -c "succeeded on try" <run dir>/harness-log.md`
  (outages covered); `harness needs` after a queue's gc shows no `merge_failed` item without its run's worktree
  (gc kept it); the `Fix rounds` row in `report.md`. If `fixed` is under 70 % of `opened` over D4–D6, F2 is next.
