<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-25-memory` (agent-harness)

What this file is: the harness renders it from `entries.jsonl` after every session, newest entry first (15 in full, then one line each; `progress-archive.md` has every entry). Don't edit it: write to `INBOX.md`.

The run builds `docs/specs/2026-10-25-memory.md`, M1–M6 in its order, per Michael's brief of 2026-10-26 18:54 (`brief.md`): the retro backlog first; sessions never write `ledger/`; the seed file is never imported into the real ledger; evals are written to `evals/NEXT.md`, never run.

`feature_list.json`: 23 features in priority order; `passes` flips as each is verified by its session, `after` says what each waits on (M1, M2, M5 and M6 start independently; M3 and M4 wait on M2). A milestone whose features all pass is verified by an independent session and merged into `main`. Per milestone: M1 6 · M2 3 · M3 5 · M4 2 · M5 2 · M6 5.

Steer from the GitHub app: edit `INBOX.md` on this branch. First line `status: pause` or `status: stop [why]`; answers to questions go under `## Answers` (every session reads them; a parked feature is retried once answers change). Each entry's **Question for Michael** lines are what the sessions need from you; each took the simplest reversible default meanwhile.

### 2026-10-27 01:40 · M6-05 · passes

M6 review (Opus subagent, 715-line diff): 0 Critical, 5 Important, 7 Minor; no second round. Fixed: review_diff fetches main first (lib/review.sh), the prompt asks for the counts, reviewFindings strict, found_nothing reads every entry, later attempts after a round stay on opus, the round's diff line names opus. 1 Minor left (#8). Tests 492 → 501.

- **Files:** lib/review.sh, lib/driver.sh, lib/entries.mjs, lib/summary.mjs, tests/stub-claude.sh, tests/checks/41-run-19-review-gate-m6.sh, tests/checks/42-run-20-review-gate-rounds-m6.sh, tests/fixtures/check-names.txt, docs/plans/2026-10-26-M6-review.md, docs/architecture.md, README.md, evals/NEXT.md, +2 more
- **Verified:** Red then green: `review_diff: fetches main first, so a milestone merged meanwhile drops out; the run directory is left out`, `review_diff: fails with the reason when origin has no such main branch` (I1); `review gate: a review's prompt asks for <n> Critical, <n> Important, <n> Minor in its entry summary; a build session's doesn't` (I2); `reviewFindings: reads Critical before Important in either order of word and count, never a step number or lowercase prose` (I3); `reviewSummary: a review counts as finding nothing only when every entry that gives counts reports 0 Critical, 0 Important` (I4); `review gate: after an escalation round that doesn't pass, the review's next attempt runs on opus and never escalates again` (I5/M6), `review gate: the escalation round's Review diff line names the model it runs on` (M7). Coverage (I5), green on arrival: `…no counts is noted not escalated…`, `…refused by a usage limit runs again on opus, still at no attempt`. Simplifications: kind computed once (driver), review_diff stderr dropped, stub R sonnet. bash -n on driver.sh, config.sh, review.sh, stub-claude.sh, checks 41 and 42; node --check summary.mjs, entries.mjs. Full suite via check.sh: green, 501 tests.
- **Tests:** 492 → 501
- **Dead end:** first full suite run — 500/501: `harness memlint: a project … prints the same two findings` failed once under load; alone 19/19, the rerun green 501/501. Code M6 never touched
- **Discovery** (affects run): tests/checks/39's `harness memlint: a project (or a directory in it) prints the same two findings…` failed once in a full TEST_JOBS=4 run and passed alone and on the rerun: a load flake (likely the run's memlint note vs the direct call)
- **Discovery** (affects run): review_diff now lives in lib/review.sh (sourced by the driver) and fetches MAIN_BRANCH first; a check can source it in a throwaway repo
- **Discovery** (affects run): A review's prompt now has a second {{REVIEW_DIFF}} line `Review findings: give your entry's summary this review's findings as `<n> Critical, <n> Important, <n> Minor``; reviewFindings reads only capitalised Critical/Important
- **Question for Michael:** The M6 review left Minor #8: the `passes=true` note and commit come before the gate un-passes a review for its round, and summary.json's cause doesn't say a round is pending. Worth a fix, or is the following `one round on opus` note enough?
- *24-M6-05 · claude-opus-5-5*

### 2026-10-27 01:12 · M6-04 · passes

summary.mjs: pure reviewSummary → summary.json review {cost_pct, found_nothing, reviews}, a Review share row in report.md, review_cost_pct in the ledger row; rework no longer counts the review gate's Opus round. evals/NEXT.md § 5 (pre-m6 vs m6, never run), README Evals pointer, architecture §per-run, decision default 7.

- **Files:** lib/summary.mjs, tests/checks/41-run-19-review-gate-m6.sh, tests/fixtures/check-names.txt, evals/NEXT.md, README.md, docs/architecture.md, journal/decisions/2026-10-27-review-gate.md
- **Verified:** check.sh full: 492/492 (was 489). New in tests/checks/41: reviewSummary pure check and the summary/report/ledger check watched failing (missing export), then green; the reviewFindings pure check passed at once (M6-03 wrote the function). Mutation: with rounds() forced to 0 the summary check fails on rsmall's rework containing R. tests/checks/14 green unchanged; git status --porcelain -- evals/results empty.
- **Tests:** 489 → 492
- **Discovery** (affects M6-05): summary.json's review object also carries `reviews` (review features with a coding entry), the denominator of report.md's `<n> of <m> reviews found nothing` row; found_nothing reads entries.jsonl's coding entries only, the last per feature.
- **Discovery** (affects M6-05): rework subtracts per feature the harness-log notes matching `· review <id>: …; one round on ` (summary.mjs rounds()).
- **Question for Michael:** The default eval set's tasks are 1–3 features, so they may never reach a milestone review; should a review-bearing eval task be added before judging the gate (evals/NEXT.md § 5 says to fall back on the ledger's review_cost_pct otherwise)?
- *23-M6-04 · claude-opus-5-5*

### 2026-10-27 01:03 · M6-03 · passes

A Sonnet review whose entry summary (else final message) reports a Critical or Important finding is un-passed and gets one round on REVIEW_ESCALATE_MODEL before the next pick, at no attempt, once per feature; Opus reviews and 0/0 never escalate. reviewFindings + `entries.mjs findings`, stub STUB_REVIEW_FINDINGS, 3 checks, §7 row, decision file.

- **Files:** lib/driver.sh, lib/entries.mjs, tests/stub-claude.sh, tests/checks/41-run-19-review-gate-m6.sh, tests/fixtures/check-names.txt, docs/architecture.md, README.md, journal/decisions/2026-10-27-review-gate.md
- **Verified:** Three new checks in tests/checks/41 written first: 2 FAIL before the driver change (4/6), 6/6 after; rsmall: R rows sonnet then opus, note `review R: sonnet found 1 Critical, 0 Important; one round on opus`, attempts.json R=1, ended done, 2nd R prompt copy has `Review round 2 of 2 (escalated: …)` and the measured Review diff line; rnone one row, no round; rbig one opus row. Full suite via check.sh: green, 489 tests; bash -n driver/stub/check 41, node --check entries.mjs.
- **Tests:** 486 → 489
- **Discovery** (affects M6-04): reviewFindings(text) is exported from lib/entries.mjs (→ {critical, important} or null) and `node lib/entries.mjs findings <run dir> <id> <final file>` prints `<c>\t<i>` (exit 1 without counts); M6-04's summary.mjs can import it and its pure check is still to write.
- **Discovery** (affects M6-04, M6-05): Pending round is $STATE/review-escalate (`id\tc\ti\trdiff`), once-marker $STATE/review-escalated-<id>; the round skips F bump, F unbump (limit and park branches) and the diff measure, and keeps the measured Review diff line. M6-04's rework fix must subtract the `one round on` notes: rsmall's R now has two real coding rows.
- **Discovery** (affects M6-04): rsmall and rbig now run with STUB_REVIEW_FINDINGS=1,0 and a third run rnone (0,0) follows rbig in tests/checks/41; check 41 takes ~31 s.
- **Question for Michael:** prompts/coding.md §2 still tells every session (a Sonnet review session included) to send reviews to Opus subagents, so a Sonnet review saves less than its model suggests. Change that line for review features? (default: unchanged, decisions/2026-10-27-review-gate D5)
- **Proposed change:** M6-04 step 4 should say the decision file journal/decisions/2026-10-27-review-gate.md already exists (M6-03 wrote it) and only gains the two field names.
- *22-M6-03 · claude-opus-5-5*

### 2026-10-27 00:47 · M6-02 · passes

Review gate, measure and route: driver review_diff (git diff --shortstat origin/main...HEAD, run dir left out) picks sonnet under REVIEW_OPUS_LINES (400), opus at or over, notes `review <id>: <n> changed lines, …`, fills {{REVIEW_DIFF}}; config + template keys; stub STUB_REVIEW_LIST/STUB_BIG_DIFF; 3 checks in 41. Tests 483 → 486.

- **Files:** lib/driver.sh, lib/config.sh, templates/user/config.sh, prompts/coding.md, tests/stub-claude.sh, tests/checks/41-run-19-review-gate-m6.sh, tests/fixtures/check-names.txt
- **Verified:** tests/checks/41: 3 checks watched failing (0/3) then passing (3/3); KEEP=1 run: rsmall `review R: 3 changed lines, under 400; sonnet` (R row claude-sonnet-5-5), rbig `review R: 500 changed lines, at or over 400; opus`; review_diff without origin/main returns 1 with `fatal: bad revision` (→ opus, noted); full suite via check.sh green, 486 tests; 07-step-lint file untouched and green.
- **Tests:** 483 → 486
- **Discovery** (affects M6-03, M6-04): In check 41, rbig runs after rsmall merged work-A/B/D.txt into main with the same content, so rbig's diff is big-A.txt alone (1 file, 500 lines); rsmall's is 3 files, 3 lines.
- **Discovery** (affects M6-03): The gate sits in the loop after the memory gate and before `n=$(( n + 1 ))`; `rdiff` holds the Review diff line (empty for non-review) and is passed as HARNESS_REVIEW_DIFF on the `prompt coding` line only. M6-03's escalation round must set mdl/rdiff itself and skip this block (it runs whenever F kind is review).
- **Discovery** (affects M6-03): STUB_REVIEW_FINDINGS is not built yet (M6-03 adds it); B's tamper one-liner now exits 0 when the list has no C.
- **Question for Michael:** prompts/coding.md §2 still sends reviews to Opus subagents, so a Sonnet review session that delegates saves less: should a review session's subagent follow the session's model? (Default kept: unchanged; plan D-default 5.)
- *21-M6-02 · claude-opus-5-5*

### 2026-10-27 00:38 · M6-01 · passes

Wrote docs/plans/2026-10-26-M6-review-gate.md: diff measure (git diff --shortstat origin/main...HEAD, run dir left out), model choice after the pick (sonnet <400, opus ≥400), Sonnet escalation via a pending-round state file (no attempt, once per feature), summary/ledger fields, stub flags, check 41's eight checks, evals/NEXT.md §5. Plan only; tests 483 → 483.

- **Files:** docs/plans/2026-10-26-M6-review-gate.md
- **Verified:** grep of every step's terms in the plan (17/17 present); lib/driver.sh line refs re-read (774 read, 777 gate, 779 bump, 786 session, 788 journal, 794/822 unbump); suite green, cached for the code tree, 483 tests
- **Tests:** 483 → 483
- **Discovery** (affects M6-03, M6-04): summary.mjs counts a feature with more than one real coding row as rework (summary.mjs:164): the review escalation round would mark every escalated review as rework unless M6-04 subtracts its `one round on` notes (in the plan).
- **Discovery** (affects M6-03): The escalation round must un-pass the review when deciding to escalate, else verify_ready verifies the milestone on the Sonnet verdict before the round runs; the plan does this and the escalated round is picked from $STATE/review-escalate before F next.
- **Discovery** (affects M6-02): The stub's B first session tampers with C via a node one-liner that crashes when the list has no C: STUB_REVIEW_LIST (A, B, D, R all in M1) must guard it.
- **Discovery** (affects M6-04): Pre-M6 eval tag is run/agent-harness-2026-10-25-memory/M5 (exists); M6's is .../M6 once verify M6 holds.
- **Question for Michael:** D-default (plan, Defaults 5): prompts/coding.md still tells every session, a Sonnet review included, to send reviews to Opus subagents, which eats much of the gate's saving. Should a review under REVIEW_OPUS_LINES run its reviewer subagent on Sonnet too? Default: unchanged.
- *20-M6-01 · claude-opus-5-5*

### 2026-10-27 00:29 · verify M5 · passes

M5-01 and M5-02 hold. Fixture check-agent-harness gives 395 generic; contract 1115, jest 7, pytest 4, empty none. Checks 06 and 40 pass (14/14). Init suite's one red file (13, 66 checks) passed alone on rerun: load flake.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M5-01 | 1 | node lib/testcount.mjs <fixtures> --source and plain | 1115 tests · contract; plain 1115 tests | yes |
| M5-01 | 2 | head -1 and testcount on check-jest-contract and check-agent-harness | provenance first line; 1115; 395 generic; ends 395/395 | yes |
| M5-01 | 3 | testcount --source on jest, pytest, empty file | 7 jest; 4 generic; ? none | yes |
| M5-01 | 4 | bash tests/run.sh test-counts | 40 checks 4/4 pass: contract note once, tests.start 12, parsed (node) | yes |
| M5-01 | 5 | init suite + rerun of file 13 | 482/483 at init, file 13 66/66 alone (timing flake under load) | yes |
| M5-02 | 1 | grep lib/driver.sh; check 40 | tests_end() at 569 called after each session (817) and in finish; check asserts tests-end 3 before finish | yes |
| M5-02 | 2 | tests/checks/40 continued-run check | start 3, end 5, tests-start 3 asserted and passes | yes |
| M5-02 | 3 | grep summary.mjs; check 40 report/trends check | baseline at run start → end; header tests (baseline → end); passes | yes |
| M5-02 | 4 | grep architecture, README, decision file | Markers row, README paragraph, decision with TEST_REPORT rejected all present | yes |
| M5-02 | 5 | entries.jsonl M5-02 entry | Opus review 0 Critical, 1 Important fixed, 2 Minor | yes |
| M5-02 | 6 | init suite + rerun of file 13 | all other files pass; 13 passes alone | yes |

- *002538-verify-M5 · claude-sonnet-5-5*

### 2026-10-27 00:20 · M5-01 · passes

Fixed verify's step-2 fail: tests/fixtures/check-agent-harness.txt is now the last 30 lines of the suite re-run on the run's start tree ac49ba8 (395/395, what scratch check.out held at init, since overwritten); check 06 asserts 395 · generic; decision file updated in place. Tests 483 → 483.

- **Files:** tests/fixtures/check-agent-harness.txt, tests/checks/06-test-counts-pure-r1.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-26-test-count-contract.md
- **Verified:** check 06 red at 395 before the fixture (9/10), green after (10/10); testcount --source: 1115·contract, 7·jest, 4·generic, 395·generic, empty ? tests·none; full suite via check.sh green in 378 s, 483 tests
- **Tests:** 483 → 483
- **Dead end:** git archive ac49ba8 into scratch and run the suite there — 12 eval checks need the repo's history (383/395); a full git clone checked out at ac49ba8 gives 395/395
- **Discovery** (affects run): Scratch check.out is overwritten by every suite run; a fixture meant to be 'the output at init' has to be copied at init or regenerated from the start tree in a full clone.
- *19-M5-01 · claude-opus-5-5*

### 2026-10-27 00:01 · verify M5 · not yet

M5-02 holds. M5-01 step 2 fails: tests/fixtures/check-agent-harness.txt yields 474 (ends 474/474), the step says 395 (this run's scratch check.out); the check asserts 474. Other steps hold; suite green (483).

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M5-01 | 1 | node lib/testcount.mjs on check-jest-contract/check-jest/empty with and without --source; testCount on two contract lines | 1115 tests · contract; 7 tests · jest; plain form '7 tests'; last contract line wins (9) | yes |
| M5-01 | 2 | node lib/testcount.mjs tests/fixtures/check-agent-harness.txt --source; head/tail of fixtures | contract fixture 1115 with provenance first line OK; check-agent-harness gives 474 tests · generic (31 lines, ends 474/474), step demands 395; check 06 asserts 474 | no |
| M5-01 | 3 | testcount.mjs --source on jest, pytest, empty fixtures | 7 · jest; 4 · generic; ? tests · none | yes |
| M5-01 | 4 | bash tests/run.sh 40-run-18; read lib/driver.sh:332-334 | PASS 'a suite printing HARNESS_TESTS=12 is noted once ... tests.start is 12'; notes contract/parsed/no match | yes |
| M5-01 | 5 | harness init check; tests/run.sh subsets | check green in 282 s, 483 tests | yes |
| M5-02 | 1 | grep lib/driver.sh tests_end; subset 40 | tests_end() at 569, called after sessions (817) and in finish (582); continued-run check passes | yes |
| M5-02 | 2 | bash tests/run.sh 40-run-18 | PASS 'a continued run refreshes tests-end after each session (3 → 5 before finish), tests-start stays the baseline' | yes |
| M5-02 | 3 | grep lib/summary.mjs; subset 40 and 14 | 'baseline at run start → end' (236), trends header 'tests (baseline → end)' (289); report label check PASS; 14/14 pass | yes |
| M5-02 | 4 | grep architecture.md, README.md; ls journal/decisions | Markers row says when tests-start/tests-end written; README HARNESS_TESTS paragraph; decisions/2026-10-26-test-count-contract.md with TEST_REPORT rejected | yes |
| M5-02 | 5 | read entries.jsonl:23 summary | Opus review recorded: 0 Critical, 1 Important fixed RED→GREEN, 2 Minor fixed | yes |
| M5-02 | 6 | init suite | green, 483 tests | yes |

- *000021-verify-M5 · claude-sonnet-5-5*

### 2026-10-26 23:55 · M5-02 · passes

tests_end (driver) writes tests-end after every coding session from a green tree's marker/output, not only at finish; status shows `tests 3 → 5`, the session note `· tests <n>`; report/trends labelled baseline. Opus review: 0 Critical, 1 Important fixed RED→GREEN (a red tree's count became tests-end), 2 Minor fixed (unsafe-int contract, stub set -e). Tests 480 → 483.

- **Files:** lib/driver.sh, bin/harness, lib/summary.mjs, lib/testcount.mjs, tests/stub-claude.sh, tests/checks/40-run-18-test-counts-m5.sh, tests/checks/06-test-counts-pure-r1.sh, tests/fixtures/check-names.txt, README.md, docs/architecture.md, journal/decisions/2026-10-26-test-count-contract.md
- **Verified:** full suite via check.sh: green, 483/483; tests/run.sh 40-run 4/4 (the continued-run check failed first with summary.json {start:3,end:3} mid-run, then with `C … passes=false … tests 9` for the red tree); 06-test 10/10 (the unsafe-integer case failed first); 08-scope 123/123
- **Tests:** 480 → 483
- **Dead end:** dropping `local key` from finish() when lifting tests_end — scratch_done "$key" later in finish needs it: set -u killed finish (08 scrub, 15 session-cap continuation, 36 backlog failed in the full run)
- **Dead end:** stub `for tn in ${STUB_TESTS_N//,/ }; do [[ … ]] && …; done` — unbound under set -u when unset (every stub coding session died and read as refused), and a for loop ending on a false `[[ ]] &&` returns 1 and trips set -e
- **Discovery** (affects run): In tests/checks/40 the contract run's suite ignores BROKEN, so its C merges a BROKEN file into origin main; a later run in that file whose suite tests BROKEN must `git rm` it first (the cont setup does).
- **Discovery** (affects M5, run): Review Minor left: run_init pins testcount-source from the first check.out even when that suite was red (a failed first suite notes `no match`/`parsed (jest)` for the whole run); green markers written before a contract line (or a CHECK_CMD change via run.env, not in the tree key) keep the scraped count until the tree changes.
- **Question for Michael:** Should run_init pin the run's testcount-source only from a green suite (review Minor: a red first suite fixes `no match` for the run)? Default left as M5-01 built it.
- **Proposed change:** M5-02 step 2: the check's CHECK_CMD is `echo HARNESS_TESTS=$(cat tests.n); test ! -f BROKEN` (the step's command plus a red case), so the same run also shows a red tree's count is never tests-end
- *18-M5-02 · claude-opus-5-5*

### 2026-10-26 23:18 · M5-01 · passes

testcount.mjs: a last whole-line HARNESS_TESTS=<n> wins, then R1's runners, then generic; countSource() gives {n, source}; `--source` prints `<n> tests · <source>` (`? tests · none`). run_init notes once per run `test count: HARNESS_TESTS contract` / `parsed (<runner>)` / no match (marker testcount-source). Tests 474 → 480.

- **Files:** lib/testcount.mjs, lib/driver.sh, tests/checks/06-test-counts-pure-r1.sh, tests/checks/40-run-18-test-counts-m5.sh, tests/fixtures/check-jest-contract.txt, tests/fixtures/check-agent-harness.txt, tests/fixtures/check-names.txt, journal/decisions/2026-10-26-test-count-contract.md, docs/architecture.md, README.md
- **Verified:** 6 new checks watched red (06: 5/9, 40: 0/2), then green (06 9/9, 40 2/2: a two-segment contract run notes once and summary tests.start 12; a `# pass 7` run notes parsed (node)); full suite via check.sh green in 271 s, 480 tests; bash -n driver and both check files, node --check testcount.mjs.
- **Tests:** 474 → 480
- **Dead end:** a pure check input `echo HARNESS_TESTS=8 # pass 2` on one line — node:test's rule is anchored at line start too, so it gave null; the input now has `# pass 2` on its own line
- **Discovery** (affects M5-02): decisions/2026-10-26-test-count-contract exists (the contract part, TEST_REPORT rejected); M5-02 extends it in place with the tests-end refresh and baseline label. README's `## What a project needs` already has the HARNESS_TESTS paragraph and architecture's Markers row names testcount-source; M5-02 adds when tests-start/tests-end are written.
- **Discovery** (affects M5-02): tests/checks/40-run-18-test-counts-m5.sh exists with a `sumj <run>` helper (summary.json path) and run.env CHECK_CMD overrides; M5-02's continued-run check goes there.
- **Discovery** (affects run): The live harness runs main's testcount.mjs, so this run's own logs show no contract note until M5 merges.
- **Proposed change:** M5-01 step 2: the scratch check.out now ends `474/474 checks passed` (the suite grew since init), so check-agent-harness.txt yields 474, not 395; the fixture copies the file as it is.
- *17-M5-01 · claude-opus-5-5*

### 2026-10-26 23:10 · verify M4 · passes

M4-01 and M4-02 hold: suite green (474 tests), memlint subset 19/19, fixtures re-linted by hand give the stated findings, docs and decision file present, review recorded in entries.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M4-01 | 1 | node lib/memlint.mjs <tmp worktrees>, /nonexist, header read | findings in file:line check: text form; exit 0; missing dir exit 2; 121-line CLAUDE.md gives size, 16 Gotchas gives gotchas; header lists checks | yes |
| M4-01 | 2 | head -1 of the 4 fixtures | each first line names repo, commit, path as specified | yes |
| M4-01 | 3 | lint on fixtures; bash tests/run.sh memlint | dj: derivable-count line 17; pathways: night-scope tonight; old rane: decisions D15 Superseded, none for header; tidy rane: none; no store: decisions: no store; 19/19 pass | yes |
| M4-01 | 4 | 121-line and 16-Gotchas worktrees; node --check; test 39 store-lookup check | size and gotchas findings; node --check ok; decisionsStore check passes | yes |
| M4-01 | 5 | node lib/memlint.mjs . in this worktree | no output, exit 0 | yes |
| M4-01 | 6 | init.out | green, 474 tests | yes |
| M4-02 | 1 | tests/checks/39 driver memlint check | 2 memlint notes before feature list written, run done 3/3 | yes |
| M4-02 | 2 | tests/checks/39 failing memlint check | one memlint: failed (exit 1) note, run goes on to done 3/3 | yes |
| M4-02 | 3 | tests/checks/39 harness memlint check | same two lines from $T/proj, exit 0, usage in bin/harness header | yes |
| M4-02 | 4 | grep README, architecture.md, ls journal/decisions | README line 69-73, arch §7 row line 264, §3 row line 70, decisions/2026-10-26-memlint.md exist | yes |
| M4-02 | 5 | entries.jsonl:20 summary | Opus review recorded: 0 Critical, 2 Important fixed RED to GREEN | yes |
| M4-02 | 6 | init.out | suite green 474 tests | yes |

- *230904-verify-M4 · claude-sonnet-5-5*

### 2026-10-26 23:03 · M4-02 · passes

Driver notes memlint findings as `memlint: …` at every segment start (60 s, stdout only, a failure is one `memlint: failed` note, never a stop); `harness memlint <project|path>`. Opus review of M4: 0 Critical, 2 Important fixed RED→GREEN (a stack-trace failure note; a header under a ## section flagged) plus 4 Minor. Tests 469 → 474.

- **Files:** lib/driver.sh, bin/harness, lib/memlint.mjs, tests/checks/39-memlint-m4.sh, tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh, tests/fixtures/check-names.txt, README.md, docs/architecture.md, journal/decisions/2026-10-26-memlint.md
- **Verified:** tests/checks/39-memlint-m4.sh 19/19 (3 driver/CLI checks and 2 review checks watched failing first); full suite via lib/check.sh; bash -n driver.sh, bin/harness; node --check lib/memlint.mjs
- **Tests:** 469 → 474
- **Dead end:** memlint stderr merged into the findings (2>&1) — a node warning became a finding note, and a crash's note was `node:fs:483` (review); stderr now goes to $SCRATCH/memlint.err
- **Discovery** (affects run): tests/checks/08's step-lint check counted `lint: ` lines, which `memlint: ` notes also match; it now greps `· lint: `. A future note ending in `lint:` needs the same care.
- **Discovery** (affects M4, run): Review Minor left as heuristics (D-defaults in decisions/2026-10-26-memlint): `# ` lines inside code fences end the Where-things-go/Gotchas section; `this run fails` and `2 checks` are flagged; a table store's `Updated in place` on the successor row doesn't clear the superseded row; `no store` cites .harness/config.sh:1 even when absent.
- **Question for Michael:** The memlint notes repeat every segment (a continue too) until the file is tidied: keep that, or note only findings that are new since the run's last segment?
- *16-M4-02 · claude-opus-5-5*

### 2026-10-26 22:48 · M4-01 · passes

lib/memlint.mjs <worktree> lints CLAUDE.md, .harness/project.md and the decisionsStore store: size, gotchas, derivable-count, night-scope, decisions; one `<file>:<line> <check>: <text>` per line, exit 0 (2: no worktree). 6 fixtures from pre-tidy and tidy commits. This repo's CLAUDE.md lost `395 checks`. Opus review: 0 Critical/Important, 5 Minor fixed RED→GREEN. Tests 455 → 469.

- **Files:** lib/memlint.mjs, tests/checks/39-memlint-m4.sh, tests/fixtures/memlint/, tests/fixtures/check-names.txt, journal/decisions/2026-10-26-memlint.md, CLAUDE.md
- **Verified:** bash tests/run.sh 39-memlint 14/14 (11 written first and watched failing, 3 more for the review's findings, each red first); full suite via check.sh green in 312 s, 469 tests; node lib/memlint.mjs . prints nothing; node --check lib/memlint.mjs passes
- **Tests:** 455 → 469
- **Dead end:** bare `superseded` / `overturned` / `replaced by` as supersession markers (K3's list as written) — flags rane's own header (`when a decision is overturned`), voice-concierge D11 (`the rows they superseded`) and 3 of this repo's decision files (`replaced by` in prose); now passive or tagged forms only (decision D3)
- **Discovery** (affects M4-02): memlint exports lint(worktree, maxLines), lintText, lintStore, gotchasEntries; CLI `node lib/memlint.mjs <dir>` exits 0 with findings, 2 on a missing dir, 1 (stack) on an unreadable file: M4-02's `memlint: failed` note keys on non-zero exit.
- **Discovery** (affects M4-02, run): On 2026-10-26 the projects' checkouts give exactly two findings, both size: hit_list CLAUDE.md 181 lines and portfolio_site 127 (MEMLINT_LINES 120). M4-02's README line can say so.
- **Discovery** (affects run): Fixture sources were read from bare clones in the scratch dir (git clone --bare ~/projects/<p>), never by git commands in the projects' checkouts.
- **Question for Michael:** memlint defaults D1-D4 in journal/decisions/2026-10-26-memlint.md (plural counts incl. `checks`; month-name dates; passive/tagged supersession markers only; no-store reported at .harness/config.sh:1): keep them?
- **Proposed change:** M4-02: architecture §7's memlint row and README can cite the two live findings (hit_list and portfolio_site CLAUDE.md over 120 lines) as what Michael will see first
- *15-M4-01 · claude-opus-5-5*

### 2026-10-26 22:27 · verify M3 · passes

All five M3 features hold: full suite green (455), 38-run-17 12/12 and 12-journal 15/15 re-run, docs/decisions/plan present, bash -n and node --check ok.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M3-01 | 1 | re-ran/read: plan exists, defines gotchasDiff/note/driver placement (grep docs/plans/2026-10-26-M3-gotchas-and-pack.md §M3-02) | holds as described | yes |
| M3-01 | 2 | re-ran/read: plan fixes resolved field and pack drop (§M3-03 lines 87-95) | holds as described | yes |
| M3-01 | 3 | re-ran/read: plan fixes Promote to Gotchas, Current rules, VERIFY cap (§M3-03/04) | holds as described | yes |
| M3-01 | 4 | re-ran/read: plan names stub flags, check file 38, existing checks | holds as described | yes |
| M3-01 | 5 | re-ran/read: suite green: init 455 tests | holds as described | yes |
| M3-02 | 1 | re-ran/read: coding.md Finish step 3 Gotchas; check `coding prompt: the Finish step adds one Gotchas line` PASS | holds as described | yes |
| M3-02 | 2 | re-ran/read: check `gotchasDiff: added, edited, deleted and no section` PASS | holds as described | yes |
| M3-02 | 3 | re-ran/read: checks `a stub session that adds a Gotchas line is noted` and `a session that leaves CLAUDE.md alone gets no gotchas note` PASS | holds as described | yes |
| M3-02 | 4 | re-ran/read: architecture.md line 264 Gotchas row; decisions/2026-10-26-gotchas-in-place.md exists | holds as described | yes |
| M3-02 | 5 | re-ran/read: suite green | holds as described | yes |
| M3-03 | 1 | re-ran/read: check `entries.mjs: resolved is an array of strings and normalize keeps it` PASS (15/15 in 12-journal) | holds as described | yes |
| M3-03 | 2 | re-ran/read: check `a resolved question is gone from the next context.md` PASS | holds as described | yes |
| M3-03 | 3 | re-ran/read: check `a project discovery is listed under Promote to Gotchas until CLAUDE.md carries it` PASS | holds as described | yes |
| M3-03 | 4 | re-ran/read: coding.md lines 70,89,97 and where-things-go-readonly.md line 4 name project / Promote to Gotchas; check `coding and verify prompts name resolved…` PA | holds as described | yes |
| M3-03 | 5 | re-ran/read: suite green | holds as described | yes |
| M3-04 | 1 | re-ran/read: check `context.md lists the decisions store rules newest first` PASS | holds as described | yes |
| M3-04 | 2 | re-ran/read: check `CONTEXT_PACK_BYTES=1024 holds…` PASS | holds as described | yes |
| M3-04 | 3 | re-ran/read: config.sh line 30, templates/user/config.sh line 23; check `a verify pack lists failed rows before dead ends` PASS | holds as described | yes |
| M3-04 | 4 | re-ran/read: dead-end checks and 29 legacy checks pass in the full suite (455 green) | holds as described | yes |
| M3-04 | 5 | re-ran/read: architecture.md line 89 seven parts + verify cap; pack-current-rules decision exists | holds as described | yes |
| M3-04 | 6 | re-ran/read: suite green | holds as described | yes |
| M3-05 | 1 | re-ran/read: docs/plans/2026-10-26-M3-review.md records 0 Critical, 2 Important, 9 Minor | holds as described | yes |
| M3-05 | 2 | re-ran/read: Important fixes have RED/GREEN check `entries.mjs: a Gotchas line carries a fact in any case or markup…` PASS | holds as described | yes |
| M3-05 | 3 | re-ran/read: review doc exists; architecture §4/§7, decisions present | holds as described | yes |
| M3-05 | 4 | re-ran/read: bash -n and node --check all ok (run) | holds as described | yes |
| M3-05 | 5 | re-ran/read: suite green | holds as described | yes |

- *222650-verify-M3 · claude-sonnet-5-5*

### 2026-10-26 22:22 · M3-05 · passes

Opus review of the M3 diff (706a001..HEAD): 0 Critical, 2 Important, 9 Minor; no second round. Fixed both Important (a Gotchas line carries a fact in any case/markup/wrap; `resolved` dismisses a promoted fact) and 7 Minor RED→GREEN; docs and the three M3 decision files updated. Tests 451 → 455.

- **Files:** lib/entries.mjs, lib/memlint.mjs, prompts/coding.md, tests/checks/12-journal-pure-e4-entrys.sh, tests/checks/38-run-17-gotchas-and-pack-m3.sh, tests/fixtures/check-names.txt, docs/architecture.md, README.md, docs/plans/2026-10-26-M3-review.md, journal/decisions/2026-10-26-gotchas-in-place.md, journal/decisions/2026-10-26-resolved-and-project-facts.md, journal/decisions/2026-10-26-pack-current-rules.md
- **Verified:** Each new check was watched failing, then passing: `entries.mjs: a Gotchas line carries a fact in any case or markup, resolved dismisses a fact or a question as context.md shows it` (Important 1, 2; Minor 3, 4), `gotchasLines: a wrapped bullet is one line and any # or ## heading ends the section` (1, 6), `entries.mjs pack: an unreadable CLAUDE.md leaves the Gotchas out, never the pack` (5), `memlint: currentRules skips ranges written with any dash or to, and a heading never replaces a row` (7; old memlint gives d.md:13,9,5,3,1). All 7 ~/projects/*/docs/decisions.md give the same currentRules output before and after (md5). bash -n on driver.sh, prompt.sh, stub-claude.sh, checks 12 and 38; node --check on entries.mjs and memlint.mjs. Full suite: check.sh green in 257 s, 455 tests.
- **Tests:** 451 → 455
- **Discovery** (affects M4): memlint gotchasLines now joins an indented continuation line onto its bullet and ends the section at a `# ` heading too; entries.mjs pack matches a promoted fact to a Gotchas line by its first 40 characters lowercased with backticks, * and _ removed (key/loose in pack).
- **Discovery** (affects M4): currentRules: a heading never replaces a bullet or table row of the same D<n>, and D1—D6 / D1 – D6 / D1 to D6 are group headings; M4's lint can reuse the same id regex.
- **Proposed change:** The debrief (lib/debrief.sh:124) still lists questions a later entry resolved; it could skip them now that progress.md renders `Resolved:` items (review finding 4, left).
- *14-M3-05 · claude-opus-5-5*

## Older entries (in full in progress-archive.md)

- 2026-10-26 22:07 · M3-04 · passes · context.md ends with `Current rules` (memlint currentRules/readRules: dir store by dated name, file … ([in full](progress-archive.md))
- 2026-10-26 21:46 · M3-03 · passes · entries.mjs: `resolved` (array of strings, kept only when non-empty) drops a question a later entry … ([in full](progress-archive.md))
- 2026-10-26 21:23 · M3-02 · passes · Finish step 3 in prompts/coding.md: one ## Gotchas line (≤160 chars, ends (<run> <date>), 15 max, ed… ([in full](progress-archive.md))
- 2026-10-26 21:11 · M3-01 · passes · Wrote docs/plans/2026-10-26-M3-gotchas-and-pack.md: gotchasLines/gotchasDiff (+a ~e -d, a replace is… ([in full](progress-archive.md))
- 2026-10-26 21:06 · verify M2 · passes · All 3 features hold: suite green (435 tests, full run), 37-memory-prompts-m2 15/15 re-run, prompts/t… ([in full](progress-archive.md))
- 2026-10-26 21:00 · M2-03 · passes · docs/architecture.md gains a Memory model section (scope × bucket table, rules 1–6) and a Principles… ([in full](progress-archive.md))
- 2026-10-26 20:55 · M2-02 · passes · A background wait I had left running for the review was stopped at its time limit. It doesn't matter… ([in full](progress-archive.md))
- 2026-10-26 20:21 · M2-01 · passes · lib/memlint.mjs: decisionsStore() (DECISIONS= from .harness/config.sh, else docs/decisions.md, else … ([in full](progress-archive.md))
- 2026-10-26 20:10 · verify M1 · passes · All six M1 features hold. Full suite green (420 tests, init run); re-ran harness backlog list/set/im… ([in full](progress-archive.md))
- 2026-10-26 20:05 · M1-06 · passes · Opus review of the M1 diff (1065 lines): 0 Critical, 5 Important, 9 Minor; no second round. Fixed al… ([in full](progress-archive.md))
- 2026-10-26 19:47 · M1-05 · passes · M1-05 passes, in commit `8623944`, pushed to the run branch. - **Retro:** its prompt now has a `## B… ([in full](progress-archive.md))
- 2026-10-26 19:39 · M1-04 · passes · retro() copies the retro's retro-proposals.json to scratch before restrict (skipped from the reverte… ([in full](progress-archive.md))
- 2026-10-26 19:29 · M1-03 · passes · Added lib/backlog.sh (harness backlog [list] | set | import, writes under flock on $STATE_ROOT/ledge… ([in full](progress-archive.md))
- 2026-10-26 19:23 · M1-02 · passes · Added lib/backlog.mjs (pure exports STATUSES, parseRows, formatRows, validateProposals, mergeProposa… ([in full](progress-archive.md))
- 2026-10-26 19:16 · M1-01 · passes · Wrote docs/plans/2026-10-26-M1-retro-backlog.md: row schema and defaults, lib/backlog.mjs's exported… ([in full](progress-archive.md))
- 2026-10-26 19:12 · init · passes · 23 features: M1 6 (plan, backlog.mjs, CLI + seed, retro emits and driver merges, retro prompt + debr… ([in full](progress-archive.md))
