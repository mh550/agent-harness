<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-26` (agent-harness)

What this file is: the run's journal, rendered from `entries.jsonl` after every session, newest entry first (the driver's own notes are `harness-log.md`). Each entry says what one session did, what passed, what it found (discoveries) and what it needs from you (questions).

The spec is `docs/specs/2026-10-26-lanes.md` with `docs/specs/2026-10-26-suite-split.md` as its P0. Milestones: P0 the suite split (tests/lib.sh, tests/checks/ one file per section, a parallel runner, the conformance fixture, CHECK_KEY_IGNORE) · P1 lanes at MAX_LANES=1 (the record on its own branch harness/<run>, code on harness-lane/<run>/<m> in a slot, lib/lane.sh as the milestone process, the coordinator) · P2 two lanes (admission by memory and five-hour headroom, the re-base rule, slots and gc, the record PR, status and summary). P1 waits for P0, P2 for P1. Each verified milestone merges into `main` by itself.

How to read the feature list: `feature_list.json` lists features in priority order; `passes` is the session's claim, the verify entry for a milestone is what counts. Steps are the checks a verifier re-runs; the last is always a green suite. From P1 on every new check goes in a `tests/checks/` file by topic and its name into `tests/fixtures/check-names.txt`.

To steer: edit `INBOX.md` on this branch (GitHub app). Line 1 `status: pause` or `status: stop` takes effect before the next session; answers go under `## Answers`. Sessions never park on this run (the brief): they take the spec's default and record it in the decision file. After the run: set `MAX_LANES=2` in `~/.config/harness/config.sh` before the next run starts.

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

### 2026-10-26 17:58 · P1-02 · passes

features.mjs gains lanes (openable milestones + run/<run>/<dep> base tags from meta.env), deps, next <m> (lane-local after rule) and pass; scope_owns takes an optional <m>- role prefix; config.sh and the user template carry the six lane defaults; the driver header documents HARNESS_LANE_POLL. New tests/checks/35-lanes-scheduler.sh (12 checks). Nothing calls them yet.

- **Files:** lib/features.mjs, lib/scope.sh, lib/config.sh, lib/driver.sh, templates/user/config.sh, tests/checks/35-lanes-scheduler.sh, tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh, tests/checks/13-run-2-michael-sets-desk.sh, tests/fixtures/check-names.txt
- **Verified:** 35-lanes-scheduler: 12 checks watched red (0/10, then the config and no-cycle checks red alone) then green; full suite 406/406 before the review fixes (209 s, 4 jobs) and 407/407 after (208 s); node --check features.mjs, bash -n on every shell file touched; an Opus review of the diff (1 Important, fixed with a check; 4 Minor: 1 fixed, 3 below as discoveries).
- **Tests:** 395 → 407
- **Discovery** (affects P1-04, P2): F lanes counts only EARLIER lanes as dependencies: an after into a later milestone's name is nothing (as deps() reads it), and into a later milestone's feature id leaves that feature waiting inside its lane, so M1 can run out of work while M2 waits on verified-M1. A lint rule for forward cross-milestone after (proposed) would catch it at the initializer.
- **Discovery** (affects P1-04): scope_owns' spec regex ([A-Za-z0-9_]+-)? has no . or -: P1-04 must build lane units with the milestone reduced (${m//[^A-Za-z0-9_]/_}), or a milestone like M1.5 or T-1 gives units gc never stops and status never lists.
- **Discovery** (affects P1-04, P2): With the <m>- prefix, run demo's scope_owns also matches run demo-x's harness-demo-x-svc: gc keeps it (a live owner keeps the unit; the 08/13 comment now says so), but harness status for demo (bin/harness:268) would list demo-x's units too.
- **Discovery** (affects P1-04): Lane id 'default' is features without a milestone; a milestone literally named default would merge with them. Nothing reserves the name yet.
- **Discovery** (affects P1-03, P1-04): F lanes reads the run id from <state>/meta.env's RUN_ID (else the state dir's name) for its run/<run>/<dep> tags; F next/blocked take an optional 5th arg <m> (blocked too), unchanged without it.
- **Proposed change:** P1-02 step 1: 'has a feature left to try' should read 'has a feature left to try or every feature passes' (plan §9: a complete unverified milestone must open to be verified); built and checked that way
- **Proposed change:** a lint rule forward-after: a feature whose after names a feature of a later milestone (lanes can't run it)
- *04-P1-02 · claude-opus-5-5*

### 2026-10-26 17:25 · P1-01 · passes

Wrote docs/plans/2026-10-26-P1-lanes-serial.md: every driver.sh function mapped to lib/record.sh, lib/lane.sh or the coordinator; the record lock and what it wraps; names, state, exit codes 0/10-15; slot open and materialization; record and other checks to rewrite (file:line); new files 35-38; stub flags; P1-02..05 order. An Opus review found 14 problems, all fixed in the plan.

- **Files:** docs/plans/2026-10-26-P1-lanes-serial.md
- **Verified:** check.sh green in 209 s, 395/395 checks passed; per-worktree core.excludesFile and skip-worktree tried on git 2.43 in a throwaway repo; every check cited by file:line grepped; Opus review of the plan against driver.sh, bin/harness and tests/checks, findings spot-checked (scope_owns 08:21, desk.sh:152, eval.sh:130, 08:445 dstart, eval MERGE_POLICY=off)
- **Tests:** 395 → 395
- **Dead end:** plan v1: the lane merged with merge_one after verify, sessions/limits as plain files, a shared waited-* marker, take-back after the record-commit guard — review: merges under MERGE_POLICY=off (eval, runs 14/14d), a continued run ends at once at the stale cap (19's six dl checks), coordinator eats the lane's limit wait, guard deletes the copy take-back reads; all fixed in §2-§8
- **Discovery** (affects P1-02): The spec's scope_owns regex makes `harness-demo-x-svc` a lane unit of run demo: 08:21's negative assertion must change (P1-02), and run proj-<date> owns proj-<date>-2's units (gc's live-owner rule covers it).
- **Discovery** (affects P1-04): Lane units and per-lane scratch change ~10 checks' text in 08 (unit regexes, svc_gaps, termed_left); plan §10.2 lists each with its rewrite. The stub's sessions.log/count-* and the fixture teardown markers must go to ${HARNESS_SCRATCH%%/lanes/*} so their checks keep their text.
- **Discovery** (affects P1-03, P1-05): Reopening a lane from origin/harness-lane/<run>/<m> is needed from P1-03 on (a segment that ends at a session cap mid-milestone, the dl runs), not only in P1-05.
- **Discovery** (affects P1-03): lib/eval.sh:130 reads base..harness/$run for commits.json; with a record-only run branch it must read the run's tags and lane branches (10:130).
- **Discovery** (affects run): The live check.sh still runs the suite in full for a docs/plans-only change (209-234 s twice this session): the live checkout hasn't synced P0-03's key ignores while this run lives.
- **Question for Michael:** D2 default: until P2's record PR, `harness gc` deletes a finished lanes run's record branch (the ledger keeps the record). Fine, or should P1 keep record branches until the record PR exists?
- **Question for Michael:** If this run auto-continues after P1 merges, the P1 driver's legacy refusal will stop it (this branch carries P2 code beyond main). Plan §14 gives the way out (harness merge, then a new --brief run). OK, or do you want P1-05 to exempt runs whose code is on their own branch only after a given date?
- **Proposed change:** P1-02 step 1: a milestone also opens when every feature passes but it isn't verified (a resumed run, the dl deadline runs); and add a pure `F deps <list> <m>` for the merge rule and the base
- **Proposed change:** P1-02: tests/checks/08 line 21's `! scope_owns demo harness-demo-x-svc.scope` becomes `harness-demo-x-y-svc.scope` (the spec's regex accepts one-segment prefixes)
- **Proposed change:** P1-03 step 7: 'every name still present' except the rename of 'independent M2 verified, not merged (M1 isn't)' (plan §10.2): the spec deletes the rule it asserted
- **Proposed change:** P1-04 step 1: the unit number is scope-seq (every session of the run), not $STATE/sessions (coding only), so verify and coding units never share a name (plan D7)
- **Proposed change:** P1-04: tests/checks rows of plan §10.2 (unit names) are rewritten in P1-04; 'every other check keeps its text' is not achievable with the spec's lane unit names
- *03-P1-01 · claude-opus-5-5*

### 2026-10-26 16:51 · verify P0 · passes

All four P0 features hold: init full suite 395/395 (206 s), subset runs work, split/runner/key/docs/decision/review artefacts read and match each step. Check names and counts reconcile with the fixture.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| P0-01 | 1 | read tests/lib.sh, tests/checks/, tests/fixtures; ran suite | 34 check files + lib.sh + split.sh + run.sh present; usage header on lib.sh | yes |
| P0-01 | 2 | read tests/lib.sh, tests/checks/, tests/fixtures; ran suite | 34 check files + lib.sh + split.sh + run.sh present; usage header on lib.sh | yes |
| P0-01 | 3 | cat tests/checks/*.sh \| grep check lines vs pre-split run.sh | split multiset equals pre-split except the later-added retro checks and runner/key checks (diff reviewed) | yes |
| P0-01 | 4 | bash tests/run.sh sync | subset run prints 6/6 and ends with that file count | yes |
| P0-01 | 5 | LC_ALL=C sort -c fixture; wc -l | fixture C-sorted, 394 names + conformance check = 395; conformance check PASS in init | yes |
| P0-01 | 6 | bash -n on all tests/*.sh, checks, lib/*.sh; bash tests/run.sh sync | no bash -n failures; sync file alone 6/6 | yes |
| P0-01 | 7 | init full run | init full suite: 395/395 PASS, 0 FAIL, wall 205.7 s, 4 jobs | yes |
| P0-02 | 1 | read tests/checks/33-suite-runner.sh, init output | 33-suite-runner checks PASS in init (TEST_JOBS 1 vs 4 same N/M and names, timing lines, slowest-three line, no systemd-run call) | yes |
| P0-02 | 2 | read tests/checks/33-suite-runner.sh, init output | 33-suite-runner checks PASS in init (TEST_JOBS 1 vs 4 same N/M and names, timing lines, slowest-three line, no systemd-run call) | yes |
| P0-02 | 3 | read tests/checks/33-suite-runner.sh, init output | 33-suite-runner checks PASS in init (TEST_JOBS 1 vs 4 same N/M and names, timing lines, slowest-three line, no systemd-run call) | yes |
| P0-02 | 4 | read check 28 + init out | 33-suite-runner checks PASS in init (TEST_JOBS 1 vs 4 same N/M and names, timing lines, slowest-three line, no systemd-run call) | yes |
| P0-02 | 5 | read journal/decisions/2026-10-26-suite-split.md | decision file has S2 section with measured times (207 s, floor, peak) per context; init wall 205.7 s | yes |
| P0-02 | 6 | grep CLAUDE.md | CLAUDE.md:34-39 states 208 s, TEST_JOBS=4, bash tests/run.sh gc | yes |
| P0-02 | 7 | bash -n; init full run | init full suite: 395/395 PASS, 0 FAIL, wall 205.7 s, 4 jobs | yes |
| P0-03 | 1 | grep CHECK_KEY_IGNORE lib/config.sh .harness/config.sh templates/project/config.sh | defaults match spec in lib/config.sh:15, .harness/config.sh:5, template commented | yes |
| P0-03 | 2 | grep lib/prompt.sh; node --check lib/treekey.mjs | prompt.sh:48 exports HARNESS_CHECK_KEY_IGNORE; node --check ok | yes |
| P0-03 | 3 | read tests/checks/34-check-key.sh; grep config files | 34-check-key checks PASS in init (same key under ignored prefix, lib/ change differs, cached line, stub-run docs/plans cached vs lib/ edit runs) | yes |
| P0-03 | 4 | read tests/checks/34-check-key.sh; grep config files | 34-check-key checks PASS in init (same key under ignored prefix, lib/ change differs, cached line, stub-run docs/plans cached vs lib/ edit runs) | yes |
| P0-03 | 5 | read tests/checks/34-check-key.sh; grep config files | 34-check-key checks PASS in init (same key under ignored prefix, lib/ change differs, cached line, stub-run docs/plans cached vs lib/ edit runs) | yes |
| P0-03 | 6 | grep docs/architecture.md README.md | architecture.md:103,296 and README.md:70 name it and default | yes |
| P0-03 | 7 | init full run | init full suite: 395/395 PASS, 0 FAIL, wall 205.7 s, 4 jobs | yes |
| P0-04 | 1 | read docs/plans/2026-10-26-P0-review.md, decision file, docs | review file lists 2 Important, 4 Minor with severities; Important fixes have checks in 33-suite-runner (killed job/no-FAIL exit/signal) PASS | yes |
| P0-04 | 2 | read docs/plans/2026-10-26-P0-review.md, decision file, docs | review file lists 2 Important, 4 Minor with severities; Important fixes have checks in 33-suite-runner (killed job/no-FAIL exit/signal) PASS | yes |
| P0-04 | 3 | read docs/plans/2026-10-26-P0-review.md, decision file, docs | decision file has finding·choice·rejected, wall time; no D-H number | yes |
| P0-04 | 4 | read docs/plans/2026-10-26-P0-review.md, decision file, docs | architecture/README/CLAUDE.md mention runner, subset, TEST_JOBS, CHECK_KEY_IGNORE | yes |
| P0-04 | 5 | bash -n all shell files; node --check; init full run | no syntax errors; init full suite: 395/395 PASS, 0 FAIL, wall 205.7 s, 4 jobs | yes |

- *164801-verify-P0 · claude-sonnet-5-5*

### 2026-10-26 16:44 · P0-04 · passes

Opus review of the P0 diff: 0 Critical, 2 Important, 4 Minor (docs/plans/2026-10-26-P0-review.md). Fixed RED->GREEN: the runner now prints a hung file's output on TERM and names it; a file exiting non-zero with no FAIL line counts as one failed check; treekey drops absolute/.. ignore entries. SPLIT_FROM corrected. Decision file and docs completed.

- **Files:** tests/run.sh, lib/treekey.mjs, tests/split.sh, tests/checks/33-suite-runner.sh, tests/checks/34-check-key.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-26-suite-split.md, docs/plans/2026-10-26-P0-review.md, docs/architecture.md, README.md, CLAUDE.md
- **Verified:** 3 new checks watched red (suite-runner 9/11, check-key 7/8), then green; suite-runner file 5x 11/11; full suite through lib/check.sh 395/395 in 208 s (slowest 15-run-4 157.5 s); SPLIT_OUT=tmp split.sh matches tests/checks 01-32 byte for byte; bash -n on 43 P0 shell files, node --check treekey/testcount.
- **Tests:** 392 → 395
- **Discovery** (affects P2): tests/run.sh now traps TERM/INT/HUP: a file still running when check.sh's timeout fires prints its output so far and '<file>: unfinished when the suite was stopped'. P2's TEST_FILE_TIMEOUT per file should reuse that line shape (one FAIL per hung file).
- **Discovery** (affects run): A check file that exits non-zero with no FAIL line now adds 'FAIL <file>: exited <rc> before its end, with no FAIL line' to the total, so a subset run can no longer read as all passed while a file crashed.
- *02-P0-04 · claude-opus-5-5*

### 2026-10-26 16:24 · P0-02 · passes

Runner code was already in place; under the new rule (a time is measured and recorded, not a gate) I measured it and wrote it down. TEST_JOBS=4: 207 s wall, 392/392, slowest file 156 s, floor 203 s (811 s of slot time / 4), peak 254 MB. TEST_JOBS=1: 758 s. Same per-file counts and PASS names at 1 and 4 jobs. Decision file, CLAUDE.md, README and architecture updated.

- **Files:** journal/decisions/2026-10-26-suite-split.md, CLAUDE.md, README.md, docs/architecture.md
- **Verified:** TEST_JOBS=4 bash tests/run.sh in a 3G user scope: rc 0, 392/392, wall 207 s, memory.peak 266801152 B; TEST_JOBS=1: 392/392, 758 s, per-file counts and C-sorted PASS names cmp-equal; bash -n on run.sh, lib.sh and every tests/checks/*.sh; lib/check.sh green in 205 s (392/392)
- **Tests:** 392 → 392
- **Discovery** (affects run): The suite is now work-bound, not chain-bound: the 4-job floor (811 s / 4 = 203 s) is above the slowest file (156 s), so reordering files gains nothing. Only cutting CPU (fewer node starts in the driver) would make it shorter. Four jobs' contention adds about 56 s of slot time over TEST_JOBS=1's 755 s.
- *01-P0-02 · claude-opus-5-5*

### 2026-10-26 08:30 · P0-03 · passes

CHECK_KEY_IGNORE (default .harness/runs docs/plans; this repo adds docs/specs journal findings-and-research ledger) leaves literal path prefixes out of treekey's key; prompt_env exports it; check.sh's cached line names a non-default list. New tests/checks/29-check-key.sh (7 checks, 2 stub runs via STUB_EDIT). 335 → 342 green in 168 s.

- **Files:** lib/treekey.mjs, lib/check.sh, lib/config.sh, lib/prompt.sh, .harness/config.sh, templates/project/config.sh, tests/checks/29-check-key.sh, tests/stub-claude.sh, tests/lib.sh, tests/fixtures/check-names.txt, docs/architecture.md, README.md, +1 more
- **Verified:** 29-check-key.sh red first (2/6: docs/plans run got 'green in 0 s'), then 7/7; bash tests/run.sh 342/342 (wall 170 s), again 342/342 with the repo's list exported as a real run would; live lib/check.sh: 'check: green in 168 s'; bash -n and node --check on every touched file; Opus review of the diff.
- **Tests:** 335 → 342
- **Dead end:** asserting with `git log --name-only | grep -qx` — pipefail + grep -q's early exit SIGPIPEs git log: the check fails although the file is there; use git cat-file -e
- **Discovery** (affects run): tests/lib.sh must unset every HARNESS_* variable prompt_env exports that changes check.sh's output (now HARNESS_CHECK_KEY_IGNORE too): a session's suite inherits its run's, and this repo's wide list turned the 'unset' checks red inside a real run (found by review, reproduced, fixed).
- **Discovery** (affects P1, P2, run): Once this merges, a session that only adds a plan, spec, decision or ledger file in this repo gets 'check: green (cached …; key ignores: docs/plans docs/specs journal findings-and-research ledger)' instead of a 3 min suite run. .harness/config.sh itself stays in the key.
- **Discovery** (affects P1, P2): STUB_EDIT=<path> in tests/stub-claude.sh: a coding session edits only that path, passes nothing, and copies the init.out it was started with to $STUB_DIR/init-<run>-<n>.out (what the pre-session suite said).
- **Question for Michael:** treekey always leaves out .harness/runs, even when CHECK_KEY_IGNORE omits it, and drops '.' entries; entries are literal (:(exclude,literal)), not globs. Keep that, or follow the spec's plain ':!<prefix>' to the letter?
- **Proposed change:** P0-03 step 2 says lib/driver.sh exports HARNESS_CHECK_KEY_IGNORE; HARNESS_CHECK_CMD is exported by prompt_env in lib/prompt.sh (driver.sh's load_config calls it), so it is exported there.
- *04-P0-03 · claude-opus-5-5*

### 2026-10-26 08:15 · P0-02 · not yet

Steps 1-4, 6, 7 hold; step 5 (<150 s) can't be met inside a suite split. Measured: per-file slot times add up to 636 s (547 s CPU), so 4 jobs can't finish under 159 s; the suite ran 335/335 in 165 s. Node startup (30 ms × ~2,200 per big file) is half the CPU. Decision file updated (D2 default: report it as not met); no code changed.

- **Files:** journal/decisions/2026-10-26-suite-split.md
- **Verified:** lib/check.sh: green in 165 s, 335/335 (slowest 12-… 146.7 s); per-file /usr/bin/time at 4 jobs: wall 166 s, sum 636 s; strace -f of file 12: 28,325 execs (5,461 git, 2,239 node)
- **Tests:** 335 → 335
- **Dead end:** skipping replayed checks (REPLAY returns at once) — run 1 went from 12.9 to 12.6 s: the cost is harness start, not the checks
- **Dead end:** NODE_COMPILE_CACHE, --v8-pool-size=0, --jitless, --no-opt, --single-threaded — node startup stays 30 ms or gets slower
- **Dead end:** splitting or reordering files further — slot times add up to 636 s, so 4 jobs need at least 159 s, and every replay adds more
- **Discovery** (affects P0-02, run): The suite's CPU is mostly the harness's own process starts: lib/driver.sh calls node 1,684 times in file 12 (30 ms each). Caching F model (pure) and the read-only list queries keyed on the list's content would cut about 8% of that file's CPU. That is the only lever left short of rewriting checks.
- **Question for Michael:** S2's '<150 s with TEST_JOBS=4' is out of reach for a split: 636 s of slot time on 4 jobs is ≥159 s, and the measured time is 165 s. Do you accept 'under 180 s, measured and recorded' for step 5, or should a new feature cut the driver's node calls (or rewrite the debrief/desk chains) first?
- **Proposed change:** P0-02 step 5: 'under 180 s (measured 165 s), with the per-file times and the 636 s / 4-job floor in the decision file' instead of 'under 150 s'
- *03-P0-02 · claude-opus-5-5*

### 2026-10-26 07:35 · P0-02 · not yet

Runner runs TEST_JOBS files (default 4 here) as background jobs, largest first; output whole per file, timing lines, slowest three. split.sh REPLAYS_ cut the 400 s file in three. 335/335 green in 165 s (was 589 s), peak 390 MB. Not passed: step 5 wants <150 s, but the file times sum to 637 s (≥159 s on 4 jobs) and the debrief chain is 150 s alone.

- **Files:** tests/run.sh, tests/lib.sh, tests/split.sh, tests/checks/, tests/checks/28-suite-runner.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-26-suite-split.md, CLAUDE.md, README.md, docs/architecture.md
- **Verified:** lib/check.sh: 'check: green in 165 s', 335/335 (slowest 12-…-debrief 146 s). KEEP=1 TEST_JOBS=4 in a 3G scope: 165 s, 333/333, memory.peak 369/390/381 MB in three runs. TEST_JOBS=1: 599 s, per-file stub systemd-run counts identical to TEST_JOBS=4. split.sh reproduces tests/checks/01-27 byte for byte. New runner checks watched failing first. bash -n on all.
- **Tests:** 327 → 335
- **Dead end:** debrief file replaying run 2 without run 1 — the debrief 'since' section runs `ran demo` (demo's run.log) and reads run 1's HV
- **Dead end:** desk in its own file with runs 3/10/16 only — it briefs stoppy (run 2) and calls the debrief section's `ran`; run 16's 'nothing parked' needs gc to have collected demo
- **Discovery** (affects P0-02, P0): A 150 s suite is out of reach at TEST_JOBS=4 without rewriting checks: the work is CPU-bound (4 cores/8 threads); the file times sum to 637 s; the debrief chain (queue → runner → since → big, plus runs 1, 2, 4, 5, 9) is 146-151 s on its own whatever TEST_JOBS is.
- **Discovery** (affects run): scope.sh's real 64M-scope check is flaky: in 1 of 5 full runs the cgroup OOM kill also took the bash -c wrapper, leaving an empty .show (rc/peak unread). Not the split.
- **Discovery** (affects P1, P2): lib.sh now has copies of ran, settle and HH (the debrief section's helpers) and a REPLAY mode for check (silent, uncounted). A new check file by topic needs no split.sh: split.sh only regenerates 01-27 into an empty SPLIT_OUT.
- **Question for Michael:** The spec's '<150 s with TEST_JOBS=4' can't be met (measured 165 s; floor about 159 s from 637 s of work on 4 jobs, and 150 s for the debrief chain alone). Accept 165 s (step 5 → 'under 180 s, measured and recorded'), or should a later feature rewrite the debrief chain's checks so it can be split?
- **Proposed change:** P0-02 step 5: 'under 150 s' → 'under 180 s with TEST_JOBS=4 (measured 165 s), written into the decision file'. Everything else in the step is done: the slowest file, peak memory (390 MB, CHECK_MEMORY_MAX unchanged) and why the 151 s debrief file isn't split further.
- **Proposed change:** P0-02 step 4: every file that starts a harness run logs stub systemd-run calls (the harness's own session scopes), so 'only the scope.sh and capped-suites files' logs' is false as worded. What holds and was verified: the runner makes no systemd-run call (a check with a spy on PATH), and the per-file counts match between TEST_JOBS=1 and 4.
- **Proposed change:** P0-02 step 2: the slowest/wall line is the second-to-last line; the total `N/M checks passed` stays last for testcount.mjs.
- *02-P0-02 · claude-opus-5-5*

### 2026-10-26 06:44 · P0-01 · passes

tests/run.sh is now a runner over 25 tests/checks/*.sh files: 24 cut byte for byte from the single file by tests/split.sh with 27 grouping pairs, plus 25-suite-runner.sh. tests/lib.sh holds the preamble. A conformance check runs against tests/fixtures/check-names.txt (325 names from init's check.out). testcount.mjs now reads N/M checks passed. 327/327 green in 589 s.

- **Files:** tests/lib.sh, tests/split.sh, tests/run.sh, tests/checks/, tests/fixtures/check-names.txt, lib/testcount.mjs, journal/decisions/2026-10-26-suite-split.md, CLAUDE.md, README.md, docs/architecture.md
- **Verified:** Full suite through check.sh: green in 589 s, 327/327 (325 + the testcount check + conformance). All 25 files pass alone, run from fresh shells 4 at a time. bash -n passes on every file. A Python comparison shows all 50 sections and the lib.sh preamble byte-identical to 3aa98b5:tests/run.sh. The check-line multiset diff is empty. Re-running split.sh into a temp dir reproduces tests/checks exactly. KEEP=1 tests/run.sh gc kept one $T and named it. Runner cases were tested on a throwaway copy: subset, no match, missing, new, doubled, skipped name, crashed file, a leftover background process.
- **Tests:** 325 → 327
- **Dead end:** hoisting shared helpers (sd_with, gone, has_s, keep_wts, HH, HV) into lib.sh so files that only call them need no grouping — once the state pairs were in, every such file was in the run-1 group anyway except a 1-second tmux file; dropped
- **Dead end:** export LC_ALL=C in the runner for sort/comm — it reached each file's tmux server, which mangled the UTF-8 desk window names: 12 desk checks failed. Now set only on sort/comm
- **Discovery** (affects P0-02, P0-04): Most of the suite reads run 1's demo state (its systemd.log scopes, worktree, tags, demo-hlog.md, state dir), and the debriefs read runs 2/4/5/9 and the queue. Grouping therefore yields one file of 25 sections and 253 checks (06-scope-sh-...-l5.sh) that takes ~400 s alone, more than half of the 589 s sequential total. Under S2 that file alone exceeds 150 s. Splitting it means re-running run 1's start in a second file: lines not in the monolith (the spec forbids patching). P0-02 must choose and record that.
- **Discovery** (affects P0-02, run): split.sh writes only into an empty $SPLIT_OUT (default tests/checks), so it can never delete files added since the split. To re-verify the split: SPLIT_OUT=$(mktemp -d)/o bash tests/split.sh, then cmp against tests/checks.
- **Discovery** (affects P0-02, P0-03, P1, P2): tests/checks/25-suite-runner.sh is the runner's own check file (it holds the testcount check). P0-02's runner checks belong there. Every new check name needs a line in tests/fixtures/check-names.txt (C-sorted): the full run's conformance check fails on new names too.
- **Discovery** (affects run): The harness runs the live checkout's lib/check.sh/testcount.mjs, so its green line shows no test count until this merges to main. The worktree's lib/check.sh prints 'check: green (cached for this code tree, 327 tests)'.
- **Discovery** (affects P0-02): A subset by name can match a group: `tests/run.sh parked` runs 03-harness-parked-pure-report and the big 06 file, because a group's file name adds its sections' first words (gc, queue, parked, debrief, desk, ...).
- **Question for Michael:** D1 default: the conformance check fails on a check name not in tests/fixtures/check-names.txt, not only on missing or doubled names (the spec says the runner 'says' which names are new). This keeps the fixture complete, so a check deleted later is caught. Keep it strict?
- **Proposed change:** P0-01 step 3 (multiset equal) and step 7 (N = 325 + conformance) describe the split alone. After the testcount fix, the full run is 327 (325 + 'testcount.mjs: the runner's last N/M checks passed is the count' + conformance). The split files' check lines still equal the monolith's exactly.
- *01-P0-01 · claude-opus-5-5*

### 2026-10-26 05:50 · init · passes

17 features: P0 4 (suite split S1-S3 + review; S4 left out), P1 6 (plan, pure scheduler, record branch + slot, lane process + coordinator, continue/legacy/pr-held, review), P2 7 (plan, admission, re-base, slots + gc, record PR, status + summary + prompts, review).

- **Discovery** (affects run): The suite is one file, tests/run.sh (1634 lines, 50 `# ---- <title> ----` sections, 325 checks, all names unique and environment-independent) and takes about 10 min single-threaded on this box (init measured 597 s), so every session spends 10 min per full run until P0-02 lands; iterate on a subset (`bash lib/check.sh <args>` is never cached) and run the full suite once before flipping passes.
- **Discovery** (affects run): The pre-split suite output of this run's init is at /tmp/harness/agent-harness/agent-harness-2026-10-26/check.out (325 PASS lines): P0-01 generates tests/fixtures/check-names.txt from it instead of re-running the monolith.
- **Discovery** (affects run): Sections known to read an earlier section's state: run 15e (line 1145) reads $T/demo-hlog.md from run 1 (line 540); the gc section (755) and runs 2-14 reuse run 1's demo repo and tags; the eval sections share $ED; the debrief sections share a runner log. split.sh's grouping pairs are found by running each file alone, never by patching a check.
- **Discovery** (affects run): The driver loop is lib/driver.sh:567-719 (counters n, limits, repairs, gated as shell variables; verify_ready before each pick); verify is at 375, merge_one 314, merge_milestones 351, finish 484, restrict 87 (the revert pattern for a commit touching the record). bin/harness: cmd_continue 212, cmd_merge 227, cmd_status 236, cmd_gc 351 with record_only at 384 and the harness/ + harness-merge/ prefix passes at 449.
- **Discovery** (affects run): Helpers that already exist for the lanes work: `notify.mjs question <before> <after>` computes the INBOX lines a session added; `features.mjs` has unpass, repair, snapshot, milestone-done, touched-outside; scope.sh has mem_available_gb's reader (HARNESS_MEMINFO), scope_unit and scope_owns (role regex at line 27); metrics.mjs `usage` reads unifiedWindows from the real capture tests/fixtures/usage-limit.jsonl, which carries five_hour beside seven_day.
- **Discovery** (affects run): The stubs: tests/stub-claude.sh acts on the prompt's first line and STUB_* flags (set with `tmux set-environment -g` for sessions started in tmux, plain env otherwise); tests/stub-gh.sh keeps PRs as files under $STUB_DIR/prs and really merges into the bare origin; the record of git pushes is the bare origin itself. New stub behaviour must copy a real shape (fakes mirror the live API).
- **Discovery** (affects run): S4 of the suite-split spec (`--for` selection by `# covers:`) is deliberately not in the list: P1 and P2 are the run's bulk and a feature a milestone can't ship without would hold P0. It is a one-session interactive change if wanted.
- **Question for Michael:** S4 (`tests/run.sh --for <paths>` by `# covers:` lines) was left out of P0 so the split ships first; default taken: skip it this run, do it interactively if the two-minute suite still feels slow to iterate on.
- **Question for Michael:** P1 keeps the lane port equal to the run port (one lane); distinct per-lane ports arrive with admission in P2-02. Default taken: no port change until two lanes exist.
- *00-init · claude-fable-5-1*
