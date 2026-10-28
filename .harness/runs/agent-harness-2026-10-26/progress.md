<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-26` (agent-harness)

What this file is: the run's journal, rendered from `entries.jsonl` after every session, newest entry first (the driver's own notes are `harness-log.md`). Each entry says what one session did, what passed, what it found (discoveries) and what it needs from you (questions).

The spec is `docs/specs/2026-10-26-lanes.md` with `docs/specs/2026-10-26-suite-split.md` as its P0. Milestones: P0 the suite split (tests/lib.sh, tests/checks/ one file per section, a parallel runner, the conformance fixture, CHECK_KEY_IGNORE) · P1 lanes at MAX_LANES=1 (the record on its own branch harness/<run>, code on harness-lane/<run>/<m> in a slot, lib/lane.sh as the milestone process, the coordinator) · P2 two lanes (admission by memory and five-hour headroom, the re-base rule, slots and gc, the record PR, status and summary). P1 waits for P0, P2 for P1. Each verified milestone merges into `main` by itself.

How to read the feature list: `feature_list.json` lists features in priority order; `passes` is the session's claim, the verify entry for a milestone is what counts. Steps are the checks a verifier re-runs; the last is always a green suite. From P1 on every new check goes in a `tests/checks/` file by topic and its name into `tests/fixtures/check-names.txt`.

To steer: edit `INBOX.md` on this branch (GitHub app). Line 1 `status: pause` or `status: stop` takes effect before the next session; answers go under `## Answers`. Sessions never park on this run (the brief): they take the spec's default and record it in the decision file. After the run: set `MAX_LANES=2` in `~/.config/harness/config.sh` before the next run starts.

### 2026-10-28 01:02 · P2-07 · passes

Opus review of the P2 diff (2,106 lines): 1 Critical, 3 Important fixed red->green with 4 checks; Minor 5 fixed; the rest left in docs/plans/2026-10-26-P2-review.md. D21 overturned in place (an open record PR keeps harness/<run> from gc). Docs: README after-run steps, architecture §12 headroom rule and §15, lanes.md P2 section. Suite 598 -> 602, green.

- **Files:** lib/driver.sh, lib/lane.sh, lib/record.sh, bin/harness, tests/checks/44-lanes-record.sh, tests/checks/47-lanes-two.sh, tests/checks/48-lanes-rebase.sh, tests/checks/50-lanes-record-pr.sh, tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh, tests/fixtures/check-names.txt, docs/plans/2026-10-26-P2-review.md, journal/decisions/2026-10-26-lanes.md, +2 more
- **Verified:** each new check failed first (trap: driver.pid gone/ended written; pack_and_copy: got the other pack; merge_one: 'again 1'; gc: harness/rq deleted, 10/11), then passed; bash tests/run.sh 602/602 in 474 s (TEST_JOBS=4); bash -n on 20 P2 shell files, node --check on the .mjs
- **Tests:** 598 → 602
- **Dead end:** inserting new names into check-names.txt with sed at a nearby line — broke its C sort order, so the runner's comm reported dozens missing/new; re-sort with LC_ALL=C sort -u
- **Discovery** (affects run): A bash '&' child killed before its exec runs the parent's EXIT trap (200/200 here): lane_wait's sleep ran the driver's trap (lanes TERMed, driver.pid removed mid-run). Both traps now start with [[ $BASHPID == "$$" ]] || exit 0; any new trap needs the same guard
- **Discovery** (affects run): The flakes in 45, 47 (u5) and 50 trace to review findings 1 and 5 (both fixed); 08's memory-gate stop check flaked once under 4 jobs (its 30 s wait for the note), now 120 s
- **Discovery** (affects run): gc now keeps harness/<run> while state/record-pr names a PR gh calls OPEN (or gh can't answer): one gh call per record-only branch with that marker
- **Question for Michael:** D21 is overturned (gc now keeps a record branch with an open record PR, as the review found deleting it closes the PR left for you under pr). Keep it that way?
- **Proposed change:** A feature for the brief's '<id>: suite ran <n>x (<s> s) in the session' note: planned in P2-06 (plan §6) but never built; no feature's steps named it
- **Proposed change:** Next milestone: review Minors 6 (features.mjs writes via temp file + rename), 8 (merge_one ignoring .harness/runs/ in its tree test), 9 (ledger after record_pr), 10 (milestone-id lint for scope_unit collisions), 12 (--dry-run and merge-lock checks), 15 (one fetch retry helper)
- *09-P2-07 · claude-opus-5-5*

### 2026-10-27 23:51 · P2-06 · passes

harness status prints one line per open lane (feature · session · port · slot · its units with MemoryCurrent; lanes/<m>/now from lane.sh); summary.json gains lanes {max_open, lane_hours, wall_hours} (pure laneSpans over run.log) and report.md a Lanes row; initializer.md and run.md say how lanes share files and slots. 594 → 598 checks. 0 Critical, 0 Important, 4 Minor (3 fixed).

- **Files:** bin/harness, lib/lane.sh, lib/driver.sh, lib/summary.mjs, prompts/initializer.md, prompts/parts/run.md, tests/checks/43-lanes-scheduler.sh, tests/checks/47-lanes-two.sh, tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh, tests/fixtures/check-names.txt, docs/architecture.md, README.md
- **Verified:** new checks watched red first (43: 14/16), then green: 43 16/16, 47 13/13 (status-two.out: 'lane M1 · A · session 1 · port 7950 · slot 0 · MemoryCurrent harness-two-M1-s2 50 MB' and M2 on 7951 slot 1), 08 125/125; full suite 598/598 green in 471 s (TEST_JOBS=4) on the second run; the first was 597/598: 50-lanes-record-pr's first check failed once, passed alone (10/10) and in the rerun; node --check lib/summary.mjs, bash -n bin/harness lib/lane.sh lib/driver.sh.
- **Tests:** 594 → 598
- **Dead end:** ${us:+MemoryCurrent $us}${us:-no units} in the lane line — ${us:-…} expands to $us when set, so the units printed twice; the first 47 run went red on it
- **Discovery** (affects P2-07): harness status folds a lane's units into its lane line: 08's status check now expects 'lane M1 · A · session 1 · … · MemoryCurrent harness-termed-M1-s<n> 50 MB' instead of a bare unit line; the run's own units keep the old line
- **Discovery** (affects P2-07, run): Review Minor left: two milestone ids that clean to the same unit name (M1-x and M1.x) collide in scope_unit, so status gives one lane all the units; a features lint rule rejecting such ids would close it
- **Discovery** (affects run): tests/run.sh subset output isn't kept by check.sh: run 'KEEP=1 bash tests/run.sh <file> > scratch/x.out' to read a failing check's files
- **Discovery** (affects P2-07, run): 50-lanes-record-pr's 'under auto finish opens <run>: run record' failed once under a full run (597/598) while the file's other 9 checks passed; it passed alone and in the next full run: a load flake in P2-05's check (likely its exact 'pr merge' count of 3), not reproduced
- **Proposed change:** P2-07 (decisions and docs) could add the lane line and summary.lanes to docs/architecture.md §4/§12 prose; this session updated the lane state row, summary §2 and README's status row only
- *08-P2-06 · claude-opus-5-5*

### 2026-10-27 23:21 · P2-05 · passes

The record PR: finish's last step (record_pr) opens '<run>: run record' from harness/<run> (reusing the open one, body refreshed), merged under auto, left under pr, none with RECORD_PR=off; never if the branch has non-record changes main lacks. The v2 closer spares it. Stub gh mirrors --json/-q. Suite 584 -> 594 green.

- **Files:** lib/driver.sh, tests/stub-gh.sh, tests/lib.sh, tests/checks/50-lanes-record-pr.sh, tests/fixtures/check-names.txt, docs/architecture.md, README.md, journal/decisions/2026-10-26-lanes.md
- **Verified:** check.sh: green in 475 s, 594 tests (bash tests/run.sh 592/592 before the review fixes, 470 s). 50-lanes-record-pr.sh 10/10; 8/8 red before record_pr existed; the v2-closer check and the --base guard check each go red with their guard removed. bash -n on lib/driver.sh bin/harness lib/queue.sh and the touched test files.
- **Tests:** 584 → 594
- **Dead end:** asserting the ledger's entries.jsonl has 3 lines (one per feature) — the journal has an entry per session (codings, verifies, retro): 6; the check compares the ledger's copy with main's instead
- **Discovery** (affects P2-07, run): Under MERGE_POLICY=pr (or a refused auto merge) the end-of-queue gc --all-merged --deps deletes the record-only harness/<run> (record_only, unchanged per the spec), which closes the record PR left for Michael the same night. Kept as D21 default; question below.
- **Discovery** (affects P2-07): A merged record PR moves main with .harness/runs/<run>/ only, yet merge_one's tree test counts it: a verified milestone still unmerged (waiting on a dependency, or pr-held until harness merge) then re-bases (a full suite run, one of its 3 re-bases). Another run's record PR does the same to a parallel run's lanes. Correct, but costly; P2-07 may ignore .harness/runs/ in that comparison.
- **Discovery** (affects P2-07): The ledger copy is taken before record_pr, so the 'record PR merged/opened' note is in harness-log.md on harness/<run> (and run.log) but not in the ledger or main's copy.
- **Discovery** (affects run): stub-gh.sh now refuses pr create for a head with an open PR, refuses pr merge --match-head-commit when the head moved, closes one PR per pr close, and keeps titles (prs/pr-N.title, pr-N.closed), as gh does.
- **Discovery** (affects run): One full run had 45-lanes-run's default-lane check fail (593/594); it passed alone twice, in four parallel copies and in the next full run (594/594): a load flake, not reproduced.
- **Discovery** (affects run): 50-lanes-record-pr.sh costs ~52 s of slot time (five stub runs and two continues); suite wall 475 s at TEST_JOBS=4 (measured, not a gate).
- **Question for Michael:** Under MERGE_POLICY=pr the end-of-queue gc deletes harness/<run> (record_only) and so closes the record PR left for you the same night (D21 default, decisions/2026-10-26-lanes). Keep that, or should gc keep a record branch while its record PR is open (one gh pr view per candidate branch in gc)?
- **Proposed change:** P2-05 step 3 says 'a check in the gc file': the end-of-queue gc check is in tests/checks/50-lanes-record-pr.sh, where the merged record PR's state is built (as P2-04 put its gc checks in 49); no file is named for gc alone (08 and 13 are the two largest).
- *07-P2-05 · claude-opus-5-5*

### 2026-10-27 22:44 · P2-04 · passes

Merged lane branches now go when their PR merges (lane_branch_gone: origin at once, local at reap; only what the tag or main holds, only from this run's slots). harness gc gains the harness-lane/ pass, removes leftover slots of runs with no live driver or lane, covers slots under --deps, and treats a live lane as running. P1 Minors 8 and 11 fixed.

- **Files:** lib/record.sh, lib/driver.sh, bin/harness, tests/stub-claude.sh, tests/checks/49-lanes-slots.sh, tests/fixtures/check-names.txt, docs/architecture.md, README.md, journal/decisions/2026-10-27-lane-branches-and-slots.md
- **Verified:** tests/checks/49-lanes-slots.sh 10/10 (red first: 7 of 9 failed before the code; dropping the running() lane mapping turns the live-run check red); full suite via check.sh green, 584 tests in 457 s; bash -n bin/harness lib/lane.sh lib/driver.sh lib/record.sh. An Opus review found 2 Important (deletion without an ancestry guard, detaching a non-slot checkout) and Minors 3, 5, 7: all fixed and covered by the lane_branch_gone check.
- **Tests:** 574 → 584
- **Dead end:** gk/gd scenarios after sr merged into main — the stub's work-A.txt then equals main's, A's commit is empty and nothing is pushed; the file resets origin main to its first commit before gk
- **Discovery** (affects P2-06, P2-07): A lane branch is not pushed at lane open, only after its first session (sync_lane): a check that needs it on origin while held must push it itself
- **Discovery** (affects run): 49-lanes-slots.sh costs ~42 s of slot time (five stub runs); suite 457 s at TEST_JOBS=4 (measured, not a gate)
- **Discovery** (affects P2-07): Left for P2-07 (review Minors not fixed): lanes_orphans compares STATE as an exact string (a differently spelled path to the same dir would miss an orphan); gc's slot removal doesn't check that the unit pass's scope_stop succeeded (a session could still run in a clean slot); no --dry-run check for slots or lane branches
- **Proposed change:** P2-04 step 3's gc check sits in 49-lanes-slots.sh, as the plan §7 says, not in 08 or 13
- *06-P2-04 · claude-opus-5-5*

### 2026-10-27 22:14 · P2-03 · passes

The re-base rule: merge_one returns 3 when main moved; the lane (or a LANE_MERGE merge lane, coordinator or harness merge) merges main into the verified commit; disjoint files: full suite, tag forced to the merged commit, merge; overlapping or LANE_REBASE=verify: one verify round. Review's 5 findings fixed. Suite 566 -> 574, green.

- **Files:** lib/lane.sh, lib/record.sh, lib/driver.sh, bin/harness, tests/stub-claude.sh, tests/checks/48-lanes-rebase.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-26-lane-rebase-disjoint.md, docs/architecture.md, README.md
- **Verified:** tests/checks/48-lanes-rebase.sh 8/8: rb (disjoint: note, uncached check: green in lanes/M2/rebase-check.out, merged, git -C origin.git diff --quiet run/rb/M2 main, origin reflog shows only refs/tags/run/rb/M2 rewritten), ro (overlapping (shared.txt), two verify M2 sessions, 're-base verify round 1 of 1' in its prompt), rv (LANE_REBASE=verify), rr (MAX_REBASE_ROUNDS=0 needs Michael), rf (failed round removes tag; watched red with the fix disabled), rp (MERGE_POLICY=pr, harness merge re-bases M1 then M2). Full suite via check.sh: green, 574 tests, 437 s. bash -n on every touched shell file.
- **Tests:** 566 → 574
- **Dead end:** reading the origin's reflog after resetting main between runs — update-ref of main is itself a logged non-fast-forward; the rewritten refs are now read before the reset
- **Discovery** (affects P2-04, P2-07): merge_milestones_ now skips a milestone whose lane is alive (other than the caller's own, by pid == $$): the coordinator's reap never merges a lane's milestone under it; lane_alive moved from driver.sh to record.sh
- **Discovery** (affects P2-07): A re-base verify round that fails removes verified-<m> and the tag run/<run>/<m> locally and on origin (else the old tag would merge or block a later tag -a); lane_done checks needs-<m> before waits-<m> (waits-<m> is never cleared)
- **Discovery** (affects run): 48-lanes-rebase.sh costs ~77 s of slot time (six stub runs); each run resets origin main with update-ref so the stub's work files are new
- **Discovery** (affects P2-05, P2-07): harness merge clears moved-* (one more re-base per main); harness continue also clears rebase-rounds-* and moved-*; harness merge clears a stale lanes-end before its merge lanes
- **Proposed change:** P2-03 step 1's note reads '<n> files' even for 1 file ('1 files'); kept as the spec wrote it
- *05-P2-03 · claude-opus-5-5*

### 2026-10-27 21:41 · P2-02 · passes

Two lanes on: admit (memory reserve, five-hour window, once-per-kind waiting note), a port per lane (port_alloc_ under the record and port locks), a merge lock, lanes-end + exit 16, atomic rec_count, USAGE_5H, sliced limit/mem waits, TEST_FILE_TIMEOUT. Clamp gone. Tests 555 -> 566.

- **Files:** lib/driver.sh, lib/lane.sh, lib/record.sh, lib/scope.sh, lib/config.sh, lib/metrics.mjs, lib/notify.sh, bin/harness, tests/run.sh, tests/lib.sh, tests/stub-claude.sh, tests/checks/47-lanes-two.sh, +8 more
- **Verified:** check.sh: green in 414 s, 566 tests. 47-lanes-two 11/11 (two lanes at once, ports 7950/7951 and in prompts, both merged, done; memory wait noted once then opens on fixture swap; 5-hour 80% wait noted once; session cap -> other lane 'the run is ending'; stop in a limit wait ends within a slice). 33: TEST_FILE_TIMEOUT=2s file -> one FAIL line, under 20 s. The new checks ran red first (47 aborted, 33 timeout FAIL). bash -n all shell files, node --check lib/metrics.mjs. Opus review: 1 Important + 6 Minor, all fixed.
- **Tests:** 555 → 566
- **Dead end:** the plan's two-lane run releasing both lanes together — whichever lane verifies before the other merges finds main moved (needs P2-03's re-base); the check releases C first and M1 after M2 merged
- **Dead end:** worktree add -B from origin/<b> and push -u in lanes — git locks .git/config without waiting: slot 1's open failed (could not lock config file) while M1 pushed with -u; now --no-track and no -u
- **Dead end:** mem_gate checking stop/lanes-end after its sleep — a stop arriving with memory back lost the 'available after' note (file 08 red); the check now comes before each sleep
- **Discovery** (affects P2-04): Concurrent git writers in one repo: .git/config fails instead of waiting (fixed for lanes: --no-track, no -u). P2-04's branch deletion at merge (branch -D writes config) must run while other lanes push; check it under two lanes.
- **Discovery** (affects P2-03): merge_one's fetch of main can collide with another lane's sync_main fetch (ref lock); it now retries once and logs, and merges on the next reap.
- **Discovery** (affects run): Suite wall time 414 s at TEST_JOBS=4 (was ~256 s before P2-02); 47-lanes-two is ~110 s of slot time (its limit-wait check sleeps one 60 s slice). Measured, not a gate. The first full run here had 5 failures in 08, 13 and 32 that passed on rerun alone and in the next full run (load flakes, not reproduced).
- **Discovery** (affects P2-06, P2-07): admit lives in lib/scope.sh (beside mem_available_gb) so it is unit-checkable; port_taken moved from bin/harness to lib/config.sh; both runs and lanes allocate under $STATE_ROOT/port.lock.
- **Discovery** (affects P2-03, P2-06): stub hold-coding now also touches held-<run>-<id> and releases on release-<run>-<id>: a check can choose which lane goes first.
- **Question for Michael:** D16-D18 in journal/decisions/2026-10-26-lanes.md are defaults: slot 0 keeps the run's port; a run's end reaches lanes through lanes-end and exit 16; slots --no-track and lane pushes without -u. Keep them?
- **Question for Michael:** LANE_RESERVE_GB=4 and LANE_OPEN_BELOW_5H=70 stay as specced (decisions/2026-10-26-parallel-runs-headroom). Change either before your first night at MAX_LANES=2?
- **Proposed change:** P2-02 step 3 should say 'under the record lock and the box-wide port lock' (plan D2).
- **Proposed change:** The P2 plan's 'two' scenario should release C before A: two lanes verifying at once is P2-03's re-base case, not P2-02's.
- *04-P2-02 · claude-opus-5-5*

### 2026-10-27 20:56 · P2-01 · passes

P2-01 passes. The plan is in commit `2a5ad34` (`docs/plans/2026-10-26-P2-two-lanes.md`) and pushed. The suite is green at 555 tests: this was a cache hit, which is valid because the plan file is outside the cache key and no code changed. An Opus reviewer checked the plan against the code and found 7 Important and 9 Minor problems. I confirmed the key ones and fixed all of them in the plan. The bi…

- **Files:** docs/plans/2026-10-26-P2-two-lanes.md
- *03-P2-01 · claude-opus-5-5 · recorded by the harness: entry.json invalid: summary: 413 characters (at most 400)*

### 2026-10-27 20:26 · verify P1 · passes

All 6 P1 features hold. Own full run: 555/555 (init run had one flaky file, 15-run-4, 78/78 on rerun alone and in full). bash -n/node --check clean; grep tainted|held in driver.sh = 0; docs, decision, review file, config defaults present.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| P1-01 | 1 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-01 | 2 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-01 | 3 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-01 | 4 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-01 | 5 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-01 | 6 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-02 | 1 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-02 | 2 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-02 | 3 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-02 | 4 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-02 | 5 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-02 | 6 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-03 | 1 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-03 | 2 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-03 | 3 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-03 | 4 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-03 | 5 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-03 | 6 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-03 | 7 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-04 | 1 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-04 | 2 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-04 | 3 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-04 | 4 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-04 | 5 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-04 | 6 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-05 | 1 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-05 | 2 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-05 | 3 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-05 | 4 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-06 | 1 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-06 | 2 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-06 | 3 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-06 | 4 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |
| P1-06 | 5 | read the step, checked the files/greps named, and the tests/checks/3x-lanes-*.sh and 46-lanes-continue.sh checks covering it in the full suite (bash tests/run.sh) | artifact present as written (lib/lane.sh, lib/record.sh, record() flock helper, config defaults, scope regex, decision file, architecture/README, review table); suite 555/555 incl. the lanes checks and conformance | yes |

- *201549-verify-P1 · claude-sonnet-5-5*

### 2026-10-27 20:09 · P1-06 · passes

Opus review of the P1 diff (3,541 lines): 5 Important fixed, each with a check red then green (--base continue refusal, record commits staging only the record, lane-aware F blocked, later lanes on the default lane's code, MAX_LANES>1 runs 1 until P2), 2 simplifications applied. Decision file, architecture §4/§12/§15 and README updated.

- **Files:** bin/harness, lib/record.sh, lib/driver.sh, lib/lane.sh, lib/features.mjs, tests/stub-claude.sh, tests/checks/43-lanes-scheduler.sh, tests/checks/44-lanes-record.sh, tests/checks/45-lanes-run.sh, tests/checks/46-lanes-continue.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-26-lanes.md, +3 more
- **Verified:** bash tests/run.sh lanes: 47/50 with the 4 new checks before the fixes (the --base one red after adding a second continue), 50/50 after; 45 10/11 then 11/11 for the default-lane check; full suite via check.sh green in 403 s, 555 tests; bash -n / node --check on every P1-touched file
- **Tests:** 550 → 555
- **Dead end:** the --base check with one continue after main moved — it passed before the fix: the refusal needs a segment that merged the moved main, so the check runs two continues
- **Discovery** (affects P2, run): D15: until P2, MAX_LANES above 1 is noted ('MAX_LANES=<n>: one lane at a time until P2 …') and runs 1: lanes shared the run's one port, a lane's verify and the coordinator's reap could merge one milestone twice, and LANE_END stopped no other lane. P2 must lift the clamp in lib/driver.sh with per-lane ports, a merge lock, LANE_END stopping the other lanes, and rec_count read under the lock.
- **Discovery** (affects P2): Review Minors left for P2 (docs/plans/2026-10-26-P1-review.md): nomerge-<m> never cleared (lane.sh:54), lanes_orphans matches pid by cmdline only, continue calls legacy_refuse twice, slot_close/lanes_term branch deletions and TERMs not in harness-log.md, F lanes' unused base-tags field.
- **Discovery** (affects P2, run): record commits (rec_commit) now stage .harness/runs/<run>/ only; driver start/merge-only/journal/initializer-done commits go through it. The initializer's WIP commit_all stays whole-tree so restrict can revert its code edits (D3).
- **Discovery** (affects P2): STUB_DEFAULT_FEATURE=1 in tests/stub-claude.sh prepends feature Z with no milestone (the default lane) to the stub list.
- **Question for Michael:** D15: MAX_LANES above 1 runs 1 until P2 merges (your config's 2 is noted and ignored meanwhile). OK, or should P1 not merge before P2?
- *02-P1-06 · claude-opus-5-5*

### 2026-10-27 19:25 · P1-05 · passes

harness continue reopens a lane from the newer of the box's and origin's branch (both merged if diverged); refuses a legacy run (code beyond its base) with three ways forward, exit 1, run.log + high-priority notification; under pr a dependent's PR waits (noted once), harness merge lands proposed milestones in order. 11 checks in 46-lanes-continue.sh.

- **Files:** lib/record.sh, bin/harness, tests/checks/46-lanes-continue.sh, tests/fixtures/check-names.txt, README.md, docs/architecture.md, journal/decisions/2026-10-26-lanes.md
- **Verified:** tests/checks/46-lanes-continue.sh 11/11 (6 of the first 8 red before the code; the 3 added after review red with their fix undone); full suite via check.sh: green in 383 s, 550 tests; bash -n on bin/harness lib/driver.sh lib/lane.sh lib/record.sh
- **Tests:** 539 → 550
- **Dead end:** slot_open as P1-03 left it (local lane branch first) — a stale local branch after Michael pushed to origin made every lane push non-fast-forward; the stub's own push failed and the sessions read as usage limits
- **Discovery** (affects P2, run): Under MERGE_POLICY=pr a proposed milestone merged by Michael on GitHub was never seen as merged by the driver, so anything depending on it waited forever; merge_milestones now notes '<m> merged into main (by its PR)' when the tag is on main.
- **Discovery** (affects P2): The legacy test is merge-tree of the run's base (origin/main or BASE_REF) and HEAD, diffed outside .harness/runs/, not the plan's merge-base diff; a --base run would otherwise be refused.
- **Discovery** (affects run): Once P1 merges, an automatic continuation of agent-harness-2026-10-26 run by the P1 driver is refused (this branch carries code main lacks): the refusal now reaches Michael as a high-priority notification.
- **Question for Michael:** D13 default: the legacy refusal goes to stderr, run.log and a high-priority notification, not to harness-log.md (the CLI never writes the record). Want a harness-log note too?
- **Question for Michael:** D14 default: when the box's and origin's lane branch diverged, origin's is merged into the box's (a conflict is needs Michael). OK, or should origin's always win?
- **Proposed change:** P1-05 step 4 says NN-lanes-continue.sh; the plan's §10 named it 38-lanes-continue.sh, but 38 is taken: it is 46-lanes-continue.sh
- *01-P1-05 · claude-opus-5-5*

### 2026-10-27 17:11 · P1-04 · passes

The lanes code (bda683c, merged with main by Michael) was already in place; the suite was red on one check: eval probes rendered the probe prompt with the run's scratch, the lane's session had $SCRATCH/lanes/<m>. lib/prompt.sh's command mode now names the lane's scratch and port as it already did its slot and branch. Every step re-verified; suite 538 → 539/539 green.

- **Files:** lib/prompt.sh
- **Verified:** bash tests/run.sh 10-harness: 12/13 before (diff: scratch line …/eval-t2 vs …/eval-t2/lanes/E), 13/13 after; full suite via check.sh: green in 373 s, 539/539, the 9 lanes run/pause/stop checks in 45-lanes-run.sh pass; bash -n lib/lane.sh lib/driver.sh lib/prompt.sh
- **Tests:** 538 → 539
- **Dead end:** rerunning file 10 with the fix uncommitted — harness eval runs the driver from a committed ref (a worktree at HEAD), so an uncommitted fix in lib/ isn't what it tests: commit first
- **Discovery** (affects P1-05, P1-06, P2): lib/prompt.sh's command mode (eval probes) must mirror every per-lane value lane.sh sets (WT, branch, port, scratch); a new per-lane value in lane.sh needs the same line there, or file 10's probe check goes red
- **Question for Michael:** P1-04's D9-D12 defaults (journal/decisions/2026-10-26-lanes.md) are still open from the earlier attempt: keep them?
- *01-P1-04 · claude-opus-5-5*

### 2026-10-27 00:06 · P1-04 · passes

lib/lane.sh runs one milestone as its own process (exit 0/10-15, reason in state/lanes/<m>/exit); lib/driver.sh is the coordinator (poll, reap, open under MAX_LANES, end reasons, finish waits for lanes, removes slots). Shared code moved to lib/record.sh. Per-lane units, scratch, prompt files; metrics rows carry lane. Opus review: 5 fixes. Suite 423 → 432, green.

- **Files:** lib/lane.sh, lib/driver.sh, lib/record.sh, lib/metrics.mjs, tests/checks/37-lanes-run.sh, tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh, tests/checks/36-lanes-record.sh, tests/stub-claude.sh, tests/lib.sh, tests/fixtures/check-names.txt, docs/architecture.md, journal/decisions/2026-10-26-lanes.md
- **Verified:** check.sh: green in 256 s, 432/432 (TEST_JOBS=4). New 37-lanes-run.sh 9/9; 3 of its first 4 checks fail on HEAD's code, the verify-snapshot check failed before its fix. bash -n on lane.sh driver.sh record.sh and the touched tests; node --check metrics.mjs.
- **Tests:** 423 → 432
- **Dead end:** setting BRANCH to the lane branch in the lane process — gh_url then linked notifications to the lane branch; BRANCH stays the record's, HARNESS_BRANCH names the lane
- **Dead end:** deleting every lane branch with nothing beyond main at finish — a parked lane's pushed branch is what 36's --base check (and a continue) reads; only never-pushed ones go (D11)
- **Discovery** (affects P1-05, P2): A lane's normal close leaves its services up (plan D4): its EXIT trap tears them down only when it dies without an exit line. finish and the coordinator's pause and long limit waits stop what closed lanes left (lanes_services_down).
- **Discovery** (affects P2): The coordinator syncs the record (fetch, push) only when it may open a lane or while paused (D9); lanes sync before each session. P2's multi-lane admission must keep that rate in mind.
- **Discovery** (affects run): The MAX_REPAIRS streak is per lane process now, not run-wide.
- **Discovery** (affects run): Suite: 432 checks, 256 s wall at TEST_JOBS=4 (was 423 in ~231 s); 37-lanes-run.sh adds ~35 s of slot time.
- **Question for Michael:** D9-D12 in journal/decisions/2026-10-26-lanes.md are defaults: record sync only when a lane may open, a crashed lane needs Michael, never-pushed empty lane branches deleted at finish, unit numbers from scope-seq. Keep them?
- **Proposed change:** P1-04 step 1: 'n from $STATE/sessions' names the log file; the unit number is scope-seq (plan D7/decision D12), so a verify and a coding unit never share a name
- **Proposed change:** P1-04 step 1: 'its EXIT trap runs services_down for the lane's scope' holds when the lane dies (TERM, crash); a lane that closes normally leaves them for the next lane or finish (plan §6, D4)
- *02-P1-04 · claude-opus-5-5*

### 2026-10-26 23:07 · P1-03 · passes

Reviewed ce11cdf with Opus in the foreground and fixed what it found. slot_open now checks out the right branch after another lane's failed open, marks a slot that can't be checked out needs-<m> instead of letting the loop spin, and keeps ~ global excludes. A passed default lane no longer blocks later lanes. entry.json is taken back under the record lock. Weak checks strengthened.

- **Files:** lib/record.sh, lib/features.mjs, lib/driver.sh, tests/checks/36-lanes-record.sh, tests/checks/35-lanes-scheduler.sh, tests/checks/13-run-2-michael-sets-desk.sh, tests/fixtures/check-names.txt, docs/architecture.md, journal/decisions/2026-10-26-lanes.md
- **Verified:** The three new slot_open checks fail on the old record.sh (10/13) and pass on the fix (13/13). The 35-lanes default-lane check went red, then green. Files 13 and 36 together: 79/79. Full suite (lib/check.sh): green in 295 s, 423 tests. grep -c tainted|held lib/driver.sh = 0.
- **Tests:** 419 → 423
- **Dead end:** making laneDeps drop a passed default lane alone — lanes() still listed a complete default lane as a candidate for verify, which never happens; lanes() now never offers a complete default lane
- **Discovery** (affects P1-04, P1-06, run): Lane branches harness-lane/<run>/<m> match neither deploy guard (Vercel harness/**, Netlify harness/*), so a guarded project such as portfolio_site gets a preview deploy on every sync_lane push. Not fixed here: extending the guard changes the existing deploy checks' text and needs a change to portfolio_site's main (D8).
- **Discovery** (affects P1-04, P1-05): The default lane (features with no milestone) is never verified, so its code stays on harness-lane/<run>/default and never reaches main. Before lanes, the next milestone's tainted tag carried it (D7).
- **Discovery** (affects P1-04): Record writes in the record worktree outside record(): the INBOX/brief creation, commit_all of RWT at start/finish, summary.json, report.md, retro.md. Only desk.sh's note competes in P1. P1-04's lane processes make that real. desk.sh's note writes even when its 10 s flock times out.
- **Discovery** (affects P1-06): lane_guard's restrict reverts a forced-add modification of a record tracked at the slot's base (status M) with git checkout <base>, overwriting the copy before F repair reads it. This is rare: it needs a pre-lanes record on main and a session that runs git add -f.
- **Discovery** (affects P1-04): Sessions get --settings and .mcp.json from the record worktree ($WT), while the -f test is relative to the slot. A lane that changes either file gets the stale record-worktree copy.
- **Question for Michael:** D7: should the default lane (features with no milestone) be verified and merged like a milestone, or merged into the next lane's base? Today its code never reaches main.
- **Question for Michael:** D8: should the deploy guards cover harness-lane/** too? Then portfolio_site's vercel.json on main needs "harness-lane/**": false, which you would merge.
- **Proposed change:** P1-04 or P1-06: extend the deploy guards to harness-lane/** (deploy.mjs vercelGuarded/addVercelGuard, NETLIFY_IGNORE, deploy.sh messages) and update the deploy checks' text
- *01-P1-03 · claude-opus-5-5*

### 2026-10-26 18:53 · P1-03 · not yet

The decision file is in place (D1–D6 defaults recorded). I'm waiting for the review before fixing anything or flipping `passes`.

- *06-P1-03 · claude-opus-5-5 · recorded by the harness: entry.json missing*

### 2026-10-26 18:38 · P1-03 · not yet

The Opus review of the P1-03 diff is still running. I'll wait for its findings before I fix anything, rerun the suite, write `entry.json` and flip `passes`.

- **Files:** bin/harness, docs/architecture.md, journal/decisions/2026-10-26-lanes.md, lib/desk.sh, lib/driver.sh, lib/eval.sh, lib/features.mjs, lib/prompt.sh, lib/record.sh, tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh, tests/checks/13-run-2-michael-sets-desk.sh, tests/checks/14-run-2b-stop-records.sh, +7 more
- *05-P1-03 · claude-opus-5-5 · recorded by the harness: entry.json missing*

## Older entries (in full in progress-archive.md)

- 2026-10-26 17:58 · P1-02 · passes · features.mjs gains lanes (openable milestones + run/<run>/<dep> base tags from meta.env), deps, next… ([in full](progress-archive.md))
- 2026-10-26 17:25 · P1-01 · passes · Wrote docs/plans/2026-10-26-P1-lanes-serial.md: every driver.sh function mapped to lib/record.sh, li… ([in full](progress-archive.md))
- 2026-10-26 16:51 · verify P0 · passes · All four P0 features hold: init full suite 395/395 (206 s), subset runs work, split/runner/key/docs/… ([in full](progress-archive.md))
- 2026-10-26 16:44 · P0-04 · passes · Opus review of the P0 diff: 0 Critical, 2 Important, 4 Minor (docs/plans/2026-10-26-P0-review.md). F… ([in full](progress-archive.md))
- 2026-10-26 16:24 · P0-02 · passes · Runner code was already in place; under the new rule (a time is measured and recorded, not a gate) I… ([in full](progress-archive.md))
- 2026-10-26 08:30 · P0-03 · passes · CHECK_KEY_IGNORE (default .harness/runs docs/plans; this repo adds docs/specs journal findings-and-r… ([in full](progress-archive.md))
- 2026-10-26 08:15 · P0-02 · not yet · Steps 1-4, 6, 7 hold; step 5 (<150 s) can't be met inside a suite split. Measured: per-file slot tim… ([in full](progress-archive.md))
- 2026-10-26 07:35 · P0-02 · not yet · Runner runs TEST_JOBS files (default 4 here) as background jobs, largest first; output whole per fil… ([in full](progress-archive.md))
- 2026-10-26 06:44 · P0-01 · passes · tests/run.sh is now a runner over 25 tests/checks/*.sh files: 24 cut byte for byte from the single f… ([in full](progress-archive.md))
- 2026-10-26 05:50 · init · passes · 17 features: P0 4 (suite split S1-S3 + review; S4 left out), P1 6 (plan, pure scheduler, record bran… ([in full](progress-archive.md))
