<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-29` (agent-harness)

What this file is: the run's journal, rendered by the harness, newest entry first. Spec: `docs/specs/2026-10-29-unattended-night.md`. Two milestones in series: **N1** the rerun guard (a red suite is rerun once; a flake is green, named and counted; a real red stays red) and **N2** merge conflicts resolved without you (a sorted merge driver for lists, a resolve session for the rest, the verify gate, then the merge). Feature ids: `N1-01`…`N1-05`, `N2-01`…`N2-06`; `feature_list.json` in this directory holds each one's steps and `passes`. Each entry below says what a session did, what it tried and what it found; a verify entry has one evidence row per step. Steer from your phone: edit `INBOX.md` on this branch (`status: pause` or `status: stop` on line 1; answers under `## Answers`). The harness-log (`harness-log.md`) has the driver's notes: `flaky:` lines and `resolve session` lines are this run's own new behaviour once N1 and N2 land.

### 2026-10-29 07:46 · N2-04 · passes

Layer 2 fallbacks: stub STUB_MERGE_RESOLVE markers/stray/give-up, STUB_RESOLVE_LIMIT, STUB_MAIN_TOUCH=resolve-<m>; sync_main resolves in a lane (verify defers on a refusal, skips sync_main in rebase mode); needs cards' tried; rebase records conflict-<m>; 77-resolve-fallbacks (12). Opus review: 0 Critical, 2 Important, 1 Minor, all fixed.

- **Files:** lib/record.sh, lib/lane.sh, lib/resolve.sh, lib/needs.mjs, bin/harness, tests/stub-claude.sh, tests/checks/77-resolve-fallbacks.sh, tests/checks/59-needs-cards.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-29-conflict-resolution.md
- **Verified:** check.sh: green in 660 s, 918 tests; 77-resolve-fallbacks 12/12 in 107.7 s; 76/75/61/48/59 green; 77 against the old record.sh+lane.sh failed 6/11, the rsg check failed before the merge_one guard (2 needs-you posts, a second merge lane)
- **Tests:** 905 → 918
- **Dead end:** asserting `lane M2 closed (M2 verified; its re-base waits)` in the refused run — a lane whose re-base waits closes with no such note; the check counts two `lane M2 opened` lines instead
- **Dead end:** inspecting the slot after a stub run for MERGE_HEAD — finish removes the slots; the e2e checks compare origin's lane branch with the tag, and a unit on resolve alone checks MERGE_HEAD and HEAD
- **Discovery** (affects N2-05, N2-06): resolve's tried is stored in the resolve-<m>-<main> marker, so a later record for the same main (resolve_ok: already ran) keeps tried; MAX_RESOLVES sets tried to `its <n> resolve session(s) used`
- **Discovery** (affects N2-05, N2-06): rebase writes conflict-<m> before rebase_fail: without it the run's-end merge_one re-opened merge_conflict, dropping tried and the rebase variant, and notified twice
- **Discovery** (affects N2-06): merge_one's resolve branch returns 1 when main-conflict-<m> is this main (the lane's sync_main already tried it); rebase calls main_clear once its merge went through
- **Discovery** (affects N2-05): stub resolve sessions report 0 min (S_WALL 0): a check on tried's minutes matches [0-9]+
- **Discovery** (affects N2-05, N2-06): a unit calling resolve() needs USAGE and REC set (weekly gate, metrics row) or it dies under set -u mid-function
- **Proposed change:** N2-04 step 3's `in sync_main the verify goes on without main (nomerge-<m>)` was built as the plan says instead: verify returns 2 before its session and the lane loop waits, then verifies again (a hold with nomerge-<m> would end the lane needs Michael with no record); recorded in the decision file
- **Proposed change:** N2-06's docs should name the main-conflict-<m> guard in merge_one and rebase's conflict-<m>/main_clear (§5, §7)
- *10-N2-04 · claude-opus-5-5*

### 2026-10-29 07:04 · N2-03 · passes

Layer 2 happy path: lib/resolve.sh (resolve_ok, resolve: snapshot, session on RESOLVE_*, journal, metrics row, checks, NUL-safe restore, commit), prompts/resolve.md, CONFLICTS/RESOLVE_*/MAX_RESOLVES, stub # Resolve session (both) and STUB_CONFLICT; merge_one returns 3 in a lane, rebase resolves then verifies; 76-resolve-session (12 checks). Opus review: 1 Critical, 3 Important, 7 Minor, all fixed.

- **Files:** lib/resolve.sh, prompts/resolve.md, lib/lane.sh, lib/record.sh, lib/config.sh, lib/entries.mjs, templates/user/config.sh, tests/stub-claude.sh, tests/checks/76-resolve-session.sh, tests/checks/61-needs-git.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-29-conflict-resolution.md
- **Verified:** 76-resolve-session 12/12 (27.8 s): rs run notes `M2: 1 files conflict with main (README.md); a resolve session`, one resolve + two verify M2 lines, M2 merged, main tree == run/rs/M2, no needs, 1 metrics row kind resolve, prompt names README.md + A/C subjects; michael run and harness merge keep merge_conflict. ended and slot_open checks watched red without their fix. Full suite via check.sh green on the final tree.
- **Tests:** 893 → 905
- **Dead end:** a stray-path restore over `git ls-files -s | awk` lines and `awk -v p=path` membership — the Opus review showed it deletes tracked paths with a blank, writes junk for quoted non-ASCII paths and writes through symlinks; replaced by -z snapshots in associative arrays and checkout-index
- **Discovery** (affects N2-04): resolve.sh already holds N2-04's failure code (resolve_ok bounds, MAX_RESOLVES note, refused deferral with RESOLVE_END, marker/UNRESOLVED/unmerged checks, stray restore, resolve_undo); N2-04 needs its stub modes and checks, the sync_main call site, the verify caller's rc 2 and needs.mjs `tried` (rebase already passes tried= only when set)
- **Discovery** (affects N2-04): the stray restore is covered by a unit check in 76 (resolve with a function session: a blank, café.txt, a symlink, a created and an added file); N2-04's stub `stray` run is the end-to-end one
- **Discovery** (affects N2-04, N2-06): merge_one keeps today's merge_conflict at the run's end ($STATE/ended, written by finish before merge_milestones and cleared at each segment start): no lane could re-base then
- **Discovery** (affects N2-06): slot_open now undoes a MERGE_HEAD left in a reused slot (a lane killed mid-resolve) with a note `<m>: its slot-<k> had a merge left in progress; undone`, before the WIP commit
- **Discovery** (affects N2-04): the marker check counts marker-like lines (diff3's ||||||| too) above what either side (:2:/:3:) already had, so a setext ======= underline isn't a false marker
- **Discovery** (affects N2-05): resolved-<m> is overwritten (>) on each successful resolve, not appended, so N2-05's PR body lists the last resolution's files once
- **Discovery** (affects N2-04): verify's `sync_main` still runs in rebase mode (the plan's skip is N2-04's); harmless in 76's runs
- **Proposed change:** N2-06's simplification list could add: resolve.sh's early `git merge --abort` exits (before the snapshot) and resolve_undo are two undo forms; one would do once sync_main calls resolve
- *09-N2-03 · claude-opus-5-5*

### 2026-10-29 06:07 · N2-02 · passes

Layer 1: lib/merge-sorted.sh (three-way sorted union; an unsorted side exits 1, A untouched), .gitattributes opts check-names.txt in, merge_drivers (lib/record.sh) sets the driver as worktree config in the record worktree each segment and in slot_open; STUB_SORTED; 75-merge-sorted.sh (7 checks, ~14 s); decision started.

- **Files:** lib/merge-sorted.sh, lib/record.sh, lib/driver.sh, .gitattributes, tests/stub-claude.sh, tests/checks/75-merge-sorted.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-29-conflict-resolution.md, CLAUDE.md
- **Verified:** 75-merge-sorted: 5/7 before the wiring (slot-config and two-lane checks red), 7/7 after; the two-lane run notes `M2 re-based on main …: overlapping (names.txt); one verify round` and main's names.txt is the four-line union; full suite via check.sh green in 624 s, 893 tests (a first full run was red only on memlint: Gotchas at 16 lines, fixed); bash -n on the touched shell files
- **Tests:** 886 → 893
- **Discovery** (affects N2-03, N2-04, N2-06): merge_drivers is called right after the driver's first sync_record (lib/driver.sh), before the resumed start's sync_main; slot_open calls it in place of its extensions.worktreeConfig line
- **Discovery** (affects N2-04, N2-06): STUB_SORTED=<file> in tests/stub-claude.sh: A adds `b A check`, C `b C check`, re-sorted, in their first coding session
- **Resolved:** the driver moves <state>/brief.md into the record's brief.md and empties it at start: a run's briefs are both files (agent-harness-2026-10-28 2026-10-28)
- *08-N2-02 · claude-opus-5-5*

### 2026-10-29 05:40 · N2-01 · passes

Wrote docs/plans/2026-10-29-N2-conflict-resolution.md: merge-sorted.sh + merge_drivers, resolve/resolve_ok in lib/resolve.sh (rc 0/1/2, RESOLVE_END, snapshot, checks, bounds), exact changes in sync_main, verify, rebase, merge_one(+--open) and slot_open (stays), the gate, stub flags and modes, tried, visible, checks by file. Opus review: 0 Critical, 7 Important, 5 Minor, all folded in.

- **Files:** docs/plans/2026-10-29-N2-conflict-resolution.md
- **Verified:** 8 required sections grep -x'd; every quoted line grep -F'd in lib/record.sh and lib/lane.sh; diff outside docs/plans empty; check.sh green (886, cached: docs/plans is a key ignore); merge-tree with a worktree-config driver tried in a throwaway repo
- **Tests:** 886 → 886
- **Discovery** (affects N2-02, N2-03): git 2.43 merge-tree --write-tree runs a configured merge driver (attributes from the checkout's .gitattributes), so layer 1 also settles merge_one's merge-tree
- **Discovery** (affects N2-02, project): git worktree add copies the current worktree's config.worktree into the new one: slots added from the record worktree inherit its --worktree driver; Michael's checkout never sees it
- **Discovery** (affects N2-03): 61-needs-git.sh's mc and mr runs hit sync_main/merge_one conflicts: with CONFLICTS=resolve as default they need CONFLICTS=michael in user-config to keep testing today's path
- **Discovery** (affects N2-04): a needs card key that is always present (even null) changes 52-status-json.sh's key-path fixture: add tried only when set
- **Discovery** (affects N2-04): verify runs sync_main in rebase mode too (lane.sh:62); the plan skips it there so a re-base round never resolves twice
- **Proposed change:** N2-04 step 3: in sync_main a refused resolve should defer the whole verify (verify returns 2, the lane loop waits for the window and verifies again), not 'the verify goes on without main (nomerge-<m>)': with nomerge-<m> a hold ends the lane with exit 12 'needs Michael' and no needs record, and its session runs inside the refused window (plan § Call sites/sync_main)
- **Proposed change:** N2-04 step 6: the stray mode also git-adds a new file (stray-added.txt), so the check covers a new stage-0 path; the restoring note names three paths
- **Proposed change:** N2-04: verify in rebase mode no longer calls sync_main (plan § Call sites), worth a step of its own
- *07-N2-01 · claude-opus-5-5*

### 2026-10-29 05:20 · verify N1 · passes

All five N1 features hold: subset 39/39 re-run, syntax checks, plan/docs/decision read, full suite green (886 tests) at init.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| N1-01 | 1 | grep ^## plan; sections | all six sections present | yes |
| N1-01 | 2 | read plan ## check.sh | names rerun point, 4 CHECK_RERUN values, 124/137 exits, subset never reruns | yes |
| N1-01 | 3 | read plan ## Checks | checks listed by 73/33/74 files | yes |
| N1-01 | 4 | read plan ## Checks stub suite | counter-file stub with HARNESS_FAILED and N/M lines described | yes |
| N1-01 | 5 | git diff --stat f0cbdc1~1 f0cbdc1 outside docs/plans | empty | yes |
| N1-01 | 6 | suite via init | green 886 tests | yes |
| N1-02 | 1 | bash tests/run.sh suite-runner; read tests/run.sh:100 | PASS red prints HARNESS_FAILED, green none; echo guarded by ! outside | yes |
| N1-02 | 2 | tests/run.sh check-rerun | 14/14: green-after-rerun line, args a b, check.out/check-rerun.out, marker total, cached | yes |
| N1-02 | 3 | check-rerun: red every time | PASS exit 1, red again on a rerun of a, no marker/row | yes |
| N1-02 | 4 | check-rerun: no-line/failed/off/suite | PASS all variants | yes |
| N1-02 | 5 | check-rerun: timeout and subset | PASS one call each | yes |
| N1-02 | 6 | check-rerun flakes row keys | PASS row keys and jq | yes |
| N1-02 | 7 | grep config.sh prompt.sh lane.sh template | CHECK_RERUN=auto, HARNESS_CHECK_RERUN export, HARNESS_LANE, template present; PASS | yes |
| N1-02 | 8 | read decision file | rerun-guard decision exists with updates | yes |
| N1-02 | 9 | bash -n; check-names | syntax ok; conformance in full suite green | yes |
| N1-02 | 10 | init suite | green | yes |
| N1-03 | 1 | grep flakes_note; 74 | record.sh defines it; lane.sh 3 sites, driver.sh finish; 74 PASS | yes |
| N1-03 | 2 | 74 flaky run | PASS flaky: whole suite note, A stays passed | yes |
| N1-03 | 3 | 74 invariant run | PASS C un-passed, no flaky line | yes |
| N1-03 | 4 | 74 flakes-noted | PASS offset equals size; no-flake run writes none | yes |
| N1-03 | 5 | bash -n | ok | yes |
| N1-03 | 6 | init suite | green | yes |
| N1-04 | 1 | 74 summary check | PASS flakes counts, fixture keys subset | yes |
| N1-04 | 2 | 74 report check | PASS Flakes row after Tests | yes |
| N1-04 | 3 | 74 run checks | PASS flakes run summary/report | yes |
| N1-04 | 4 | 74 debrief check | PASS x2 listed, single absent | yes |
| N1-04 | 5 | node --check; bash -n | ok | yes |
| N1-04 | 6 | init suite | green | yes |
| N1-05 | 1 | review diff file; entries.jsonl:7 | diff exists; entry reports 0 Critical, 1 Important, 7 Minor | yes |
| N1-05 | 2 | tests/run.sh check-rerun suite-runner flakes | 39/39 pass | yes |
| N1-05 | 3 | grep architecture.md | §3 row, §4 flakes row, §7 Rerun guard, §10 CHECK_RERUN present | yes |
| N1-05 | 4 | grep README.md | CHECK_RERUN four values and HARNESS_FAILED promise present | yes |
| N1-05 | 5 | decision file | Updated in place lines for N1-03/04/05 | yes |
| N1-05 | 6 | init suite | green 886 | yes |

- *051705-verify-N1 · claude-sonnet-5-5*

### 2026-10-29 04:56 · N1-05 · passes

Opus review of N1: finish now notes a flake on its own last suite (RED→GREEN stub run fe); a non-object flakes.jsonl row is skipped by summary and flakes_note; check.sh shares one green branch and one rerun call; arch §3/§4/§7/§10, README, decision updated. Hung-file rerun kept as a default (question). 0 Critical, 1 Important, 7 Minor

- **Files:** lib/check.sh, lib/driver.sh, lib/record.sh, lib/summary.mjs, tests/checks/74-flakes-run.sh, tests/fixtures/check-names.txt, docs/architecture.md, README.md, journal/decisions/2026-10-29-rerun-guard.md
- **Verified:** 74-flakes-run: new check failed (row counted in summary.json, no flaky: note), 11/11 after; null-row checks failed then passed; check-rerun/suite-runner/flakes 38/38 after check.sh simplification; 08/10/34/70 161/161. Full suite: live check.sh 885/886 (45-lanes-run flaked, 10/10 alone); this branch's check.sh on the real suite: `check: green after a rerun (flaky: 08-scope-…), 886 tests`.
- **Tests:** 885 → 886
- **Dead end:** a Gotchas line on finish's uncached suite — the section was already at 15 lines; memlint (39-memlint-m4) fails at 16, so it was dropped
- **Discovery** (affects R1, run): 08-scope-sh-l1-02 flakes under the full suite's load (memory gate waits, the real 64M scope check), green alone: an R1 flaker beside 45-lanes-run
- **Discovery** (affects run): review findings left open (Minor): run_init tests-start falls back to a red check.out's passes when a flake's marker is empty (suites with no N/M line); testcount --total undercounts a file killed mid-way; the debrief prints the project-wide #### flakes block once per run, not once per project; a fractional CHECK_TIMEOUT (1.5h) makes why() miss a timeout's 137
- **Question for Michael:** The review (Important, triaged to a default): a check file tests/run.sh stops at TEST_FILE_TIMEOUT is named in HARNESS_FAILED=, so CHECK_RERUN=auto reruns it, at most one more TEST_FILE_TIMEOUT (10m). Keep that (default: a hang under load is the likeliest flake), or skip the rerun when a file timed out? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29/slot-0/tests/run.sh:54, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29/slot-0/journal/decisions/2026-10-29-rerun-guard.md
- **Proposed change:** N1-05 step 3 says §7's Rerun guard row goes beside `Suite cache`, but Suite cache is a §4 row; §7 has `Suite scope`, and the row went beside that
- *06-N1-05 · claude-opus-5-5*

### 2026-10-29 04:02 · N1-04 · passes

summary.mjs: flakes {count, names} from <state>/green/flakes.jsonl (tolerant reader, whole suite for no names), a Flakes row after Tests in report.md and the TTY card (n · name ×k, 0, none for older summaries), flakers() + `summary.mjs flakers <ledger>/<project>` for the debrief's #### flakes block after report.md. 4 new checks in 74-flakes-run; docs and decision updated.

- **Files:** lib/summary.mjs, lib/debrief.sh, tests/checks/74-flakes-run.sh, tests/fixtures/check-names.txt, docs/architecture.md, README.md, journal/decisions/2026-10-29-rerun-guard.md
- **Verified:** 74-flakes-run 10/10 (4 new, watched failing first); full suite via check.sh: green in 622 s, 885 tests, no rerun; node --check lib/summary.mjs and bash -n lib/debrief.sh clean; 71-tty-views (summary-report.md fixture) unchanged and green
- **Tests:** 881 → 885
- **Dead end:** the unit check asserting build's keys minus the fixture's are exactly flakes — summary-report.json predates lanes and review: build has those too; the check asserts fixture keys ⊆ build keys and flakes new
- **Discovery** (affects N1-05): tests/fixtures/summary-report.json predates the lanes and review keys: build() produces keys it lacks, so compare it as a subset
- **Discovery** (affects N1-05): the debrief's flakes block reads $LEDGER/<basename of PROJECT_DIR>, as rec_dir does; the check runs debrief --dry-run with its own HARNESS_LEDGER so the stub runs' ledgered summaries don't count
- *05-N1-04 · claude-opus-5-5*

### 2026-10-29 03:45 · N1-03 · passes

Attempt 1's code (cfb23fc) verified: flakes_note in lib/record.sh, called after the un-pass check, verify, disjoint re-base and in finish before run ended; run_init's tests-start from the marker after a rerun. 74-flakes-run 6/6; full suite green on this tree at init (881 tests, 622 s, no rerun).

- **Files:** lib/record.sh, lib/lane.sh, lib/driver.sh, tests/checks/74-flakes-run.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-29-rerun-guard.md
- **Verified:** check.sh: green (cached for this code tree, 881 tests); check.sh flakes: 6/6; bash -n on record.sh lane.sh driver.sh clean; check-names.txt LC_ALL=C sorted with the 6 names
- **Tests:** 881 → 881
- **Proposed change:** N1-03 step 3 should read the invariant's rerun-red from the `red again on a rerun of the whole suite) — last lines of …/lanes/M2/check-rerun.out:` line in logs/04-C.prompt.md: the stub's C is in lane M2, and check.sh removes check-rerun.out at the next full suite, so `lanes/M1/check-rerun.out exists` can't hold
- *04-N1-03 · claude-opus-5-5*

### 2026-10-29 03:33 · N1-03 · not yet

flakes_note (lib/record.sh) notes each new green/flakes.jsonl row once (`flaky: <names|whole suite> (red, then green on a rerun; load <1-min>)`, offset in flakes-noted, locked) after the un-pass check, verify, disjoint re-base and before run ended; run_init takes tests-start from the marker after a rerun. 74-flakes-run 6/6. Not passed: no full suite came out green (one load flake each run).

- **Files:** lib/record.sh, lib/lane.sh, lib/driver.sh, tests/checks/74-flakes-run.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-29-rerun-guard.md
- **Verified:** bash tests/run.sh flakes: 6/6; tests-start check red (3) without the marker line, green (5) with it; flaky-run checks red before flakes_note. Full suite x5, 880/881 each time after the memlint fix: 47-lanes-two `lanes admission: … five-hour window at 80 %` red x3 (green alone x3 and under a 7-file load), then 45-lanes-run `a lane opened after the default lane…` x1.
- **Tests:** 875 → 881
- **Dead end:** the step's `$T/scratch/proj/<run>/lanes/M1/check-rerun.out exists` for the invariant — the stub's C is in lane M2, and check.sh removes check-rerun.out at the next full suite (C's second init); the check reads the `red again on a rerun of the whole suite) — last lines of …/lanes/M2/check-rerun.out:` line in logs/04-C.prompt.md instead
- **Dead end:** a Gotchas line about that — CLAUDE.md's Gotchas already had 15 lines; memlint (39-memlint-m4) fails at 16; the fact is in 74's header comment
- **Dead end:** run_init reading the marker on every init (an extra node treekey per init while tests-start is absent, i.e. every stub init) — 47-lanes-two`s u5 admission check failed in 3 full runs in a row; now read only when check-rerun.out is beside check.out; the next full run passed 47 but failed 45 (load flake, R1)
- **Discovery** (affects N1-04, N1-05): flakes_note notes an empty load as `load ?`; its message is built in jq, one call per flakes_note
- **Discovery** (affects N1-04): 74-flakes-run.sh has check_cmd <subject> <command>: commits a CHECK_CMD on the first main and pushes it; N1-04's stub-run checks (summary.json flakes, report's Flakes row) can read the fl and inv runs already there
- **Discovery** (affects run): the live suite check.sh (projects/agent-harness, main) has no rerun yet: a full run from a session goes red on one flake until N1 merges
- **Discovery** (affects R1, run): 47-lanes-two `lanes admission: with the five-hour window at 80 %…` and 45-lanes-run `a lane opened after the default lane…` fail under the full suite`s load, pass alone: R1 flakers
- **Discovery** (affects N1-03): the next N1-03 attempt only needs one green full suite on cfb23fc (or its successor): the code and 74 are done
- **Proposed change:** N1-03 step 3 should read: the rerun-red's `check: RED (…; red again on a rerun of the whole suite) — last lines of $T/scratch/proj/<run>/lanes/M2/check-rerun.out:` line is in $HARNESS_STATE/proj/<run>/logs/04-C.prompt.md (C is M2's, and check-rerun.out is removed by the next full suite)
- *03-N1-03 · claude-opus-5-5*

### 2026-10-29 02:15 · N1-02 · passes

check.sh's full form reruns a red once by CHECK_RERUN (auto/failed/suite/off): never after a timeout or cap kill; check-rerun.out; green rerun → 'green after a rerun (flaky: …)', marker = first run's total (testcount --total), a flakes.jsonl row. tests/run.sh prints HARNESS_FAILED=<files> unless a failure is outside them. Config, prompt_env, HARNESS_LANE, template, decision.

- **Files:** lib/check.sh, lib/testcount.mjs, tests/run.sh, lib/config.sh, lib/prompt.sh, lib/lane.sh, templates/user/config.sh, tests/checks/73-check-rerun.sh, tests/checks/33-suite-runner.sh, tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh, tests/lib.sh, tests/fixtures/check-names.txt, +1 more
- **Verified:** 73-check-rerun 14/14 and 33-suite-runner 14/14 written first (10 and 1 red before the code); full suite via check.sh: first run 873/875 (the known file-15 weekly-budget flake, and memlint: my Gotchas line made 16, removed), second run green 875/875 in 600 s. The first run's own output ended HARNESS_FAILED=15-run-4-… 39-memlint-m4.
- **Tests:** 859 → 875
- **Dead end:** a Gotchas line on HARNESS_CHECK_RERUN=off for checks reading the first RED line — ## Gotchas is already at 15 lines and memlint fails at 16; the fact is in check.sh's header and the decision instead
- **Discovery** (affects N1-03, N1-04): tests/lib.sh's suite_setup now unsets HARNESS_CHECK_RERUN and HARNESS_LANE, so a session's own values never reach a check; a stub run gets CHECK_RERUN=auto from lib/config.sh
- **Discovery** (affects N1-03): a rerun-red's RED line names check-rerun.out, not check.out: a stub run's red now leaves $SCRATCH/lanes/<m>/check-rerun.out (N1-03's invariant check can rely on it)
- **Discovery** (affects N1-05): why() gained a third argument (the run's own seconds, for the timeout test) so a rerun's 137 isn't called a timeout by the two runs' summed time; N1-05's fold should keep it
- **Discovery** (affects N1): the first full suite after this change printed HARNESS_FAILED=15-run-4-same-but-queue-parked-debrief-tmux 39-memlint-m4 on a real red: the line works on the real suite
- **Proposed change:** N1-05: CLAUDE.md's Gotchas is full (15/15); a line on 'a check on check.sh's first RED line sets HARNESS_CHECK_RERUN=off' would help but needs one evicted, which is Michael's call
- *02-N1-02 · claude-opus-5-5*

### 2026-10-29 01:46 · N1-01 · passes

Wrote docs/plans/2026-10-29-N1-rerun-guard.md: the rerun's place and rules in lib/check.sh (CHECK_RERUN table, never-rerun exits, marker from the first run's total via testcount --total), the HARNESS_FAILED= guard in tests/run.sh, the flakes.jsonl row, flakes_note's sites and lock, summary/report/debrief, every new check name by file, docs.

- **Files:** docs/plans/2026-10-29-N1-rerun-guard.md
- **Verified:** the six headings grep -x present; git diff --stat origin/main...HEAD outside docs/plans and the run dir is empty; check.sh: green (cached, 859 tests)
- **Tests:** 859 → 859
- **Discovery** (affects N1-02): check.sh's find deletes every check-*.out but check-<key>.out after the full run: check-rerun.out must be written after it, and rm'd before the first run
- **Discovery** (affects N1-02): 08-scope-sh's ck() calls check.sh with exit 3 and exit 137 (short of the cap) and greps '— last lines of .../check.out': under auto they rerun; pin HARNESS_CHECK_RERUN=off in ck()
- **Discovery** (affects N1-03): run_init writes tests-start from check.out, which after a rerun-green is the red run (its passes, not the total); take it from the marker first, as tests_end does
- **Discovery** (affects N1-02): a rerun-green with no N/M total leaves an empty marker, and the cached line and tests_end then fall back to check-<key>.out, the red run's count: the plan removes check-<key>.out then
- **Discovery** (affects N1-04): summary.mjs's jsonl() throws on a bad line; flakes.jsonl is appended by lanes at once, so read it tolerantly
- **Proposed change:** N1-03: add a step for run_init's tests-start after a flake (from the marker first) with its check in 74-flakes-run.sh, as the plan's §flakes.jsonl and flakes_note says
- **Proposed change:** N1-02: add 'a kill at the memory cap is never rerun' to step 5 (the plan lists the check) and the 08 ck() pin to HARNESS_CHECK_RERUN=off
- *01-N1-01 · claude-opus-5-5*

### 2026-10-29 01:40 · init · passes

11 features: N1 5 (plan, 3 build, review), N2 6 (plan, 4 build, review); in series, N2 after N1 as the spec asks. First N1-01 (plan), N1-02 (HARNESS_FAILED= and the check.sh rerun), N1-03 (flakes_note and the invariant).

- **Discovery** (affects run): the suite took 604 s at init here (859 checks); each full run inside a feature costs about 10 min, so a build feature runs it twice at most
- **Discovery** (affects run): HARNESS_LANE is not exported anywhere today; N1-02 exports it from lib/lane.sh so flakes.jsonl rows and resolve sessions can name their lane
- **Discovery** (affects run): the stub project's CHECK_CMD (`test ! -f BROKEN`, tests/lib.sh) prints no HARNESS_FAILED= line, so in stub runs CHECK_RERUN=auto reruns the whole suite: the flaky note reads `flaky: whole suite`
- **Discovery** (affects run): scope_run clears <unit>.started and .show before each call, so check.sh can run its rerun through run() with the same unit name
- **Discovery** (affects run): the last run's build features took 25 to 78 min each (the lane-wiring ones the longest); N2-03 and N2-04 are the big ones here and may take two attempts
- *00-init · claude-fable-5-1*
