<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-25-memory` (agent-harness)

What this file is: the harness renders it from `entries.jsonl` after every session, newest entry first (15 in full, then one line each; `progress-archive.md` has every entry). Don't edit it: write to `INBOX.md`.

The run builds `docs/specs/2026-10-25-memory.md`, M1–M6 in its order, per Michael's brief of 2026-10-26 18:54 (`brief.md`): the retro backlog first; sessions never write `ledger/`; the seed file is never imported into the real ledger; evals are written to `evals/NEXT.md`, never run.

`feature_list.json`: 23 features in priority order; `passes` flips as each is verified by its session, `after` says what each waits on (M1, M2, M5 and M6 start independently; M3 and M4 wait on M2). A milestone whose features all pass is verified by an independent session and merged into `main`. Per milestone: M1 6 · M2 3 · M3 5 · M4 2 · M5 2 · M6 5.

Steer from the GitHub app: edit `INBOX.md` on this branch. First line `status: pause` or `status: stop [why]`; answers to questions go under `## Answers` (every session reads them; a parked feature is retried once answers change). Each entry's **Question for Michael** lines are what the sessions need from you; each took the simplest reversible default meanwhile.

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

### 2026-10-26 22:07 · M3-04 · passes

context.md ends with `Current rules` (memlint currentRules/readRules: dir store by dated name, file store's D<n> headings, bullets, table rows incl. `*default*`; ≤cap/4, rest one older-rules line). Verify packs use CONTEXT_PACK_BYTES_VERIFY=16384 with failed rows first. Stub STUB_VERIFY_FAIL_ROW, 3 fixtures, decision file, arch/README. Tests 445 → 451.

- **Files:** lib/memlint.mjs, lib/entries.mjs, lib/driver.sh, lib/config.sh, templates/user/config.sh, tests/stub-claude.sh, tests/checks/12-journal-pure-e4-entrys.sh, tests/checks/38-run-17-gotchas-and-pack-m3.sh, tests/fixtures/decisions-rane.md, tests/fixtures/decisions-voice-concierge.md, tests/fixtures/decisions-dj.md, tests/fixtures/check-names.txt, +3 more
- **Verified:** check.sh green, 451 tests (256 s); new checks watched red first; readRules on the real stores gives rane 24, voice-concierge 23, dj 53 (newest D53); an Opus review fuzzed pack() 20k times with no cap breach; its Important finding (dj `| D36 *default* |` rows dropped) fixed red→green along with CRLF, undated dir files, per-file read errors, ref length
- **Tests:** 445 → 451
- **Dead end:** appending CONTEXT_PACK_BYTES=1024 to $T/proj's config after the gotcha run and pushing — that run had merged PRs into origin main, so the push was refused; pull --ff-only first
- **Dead end:** proving `items left out` at 1024 with the stub's default entries — the stub's packs stay under 864 bytes; STUB_VERIFY_FAIL_ROW's row has a long `saw`, as real rows quote output
- **Discovery** (affects M4, M3-05): memlint.mjs exports currentRules(store, input) and readRules(worktree) → [{text, ref}] newest first; M4's lint can reuse the D<n> line parser (heading, bullet with wrapped lines, table row with an optional `*default*` in the id cell).
- **Discovery** (affects M3-05, M4): Current rules leaves out unnumbered headings (voice-concierge `## LLM provider: …`) and B<n> rulings; in a pack that already stopped (most real verify packs at 8 KB did) the part is omitted whole.
- **Discovery** (affects M3-05, run): In tests/checks/38, a change to $T/proj after a stub run must `git pull -q --ff-only origin main` first: the run merged its PRs into origin main.
- **Question for Michael:** Should Current rules also list unnumbered decision headings (voice-concierge's `## LLM provider: Anthropic direct (Michael, …)`), or is numbering them M4's lint's job? Default taken: numbered only.
- **Proposed change:** M3-04 step 3's `context.md for M1:` byte count exceeding 8192 can't be observed in a stub run; the check proves the verify cap with CONTEXT_PACK_BYTES=1024 (verify pack > 1024 and ≤ 16384, harness-log count > 1024) instead
- *13-M3-04 · claude-opus-5-5*

### 2026-10-26 21:46 · M3-03 · passes

entries.mjs: `resolved` (array of strings, kept only when non-empty) drops a question a later entry names (whitespace-folded); `project` discoveries go to a coding-only `Promote to Gotchas` part (cap/8 share, long facts cut, dedup by first 40 chars) until a CLAUDE.md Gotchas line holds them. Stub flags STUB_ASK/RESOLVE/PROJECT_FACT, prompts, arch, README, decision file. Tests 439 → 445.

- **Files:** lib/entries.mjs, tests/stub-claude.sh, tests/checks/12-journal-pure-e4-entrys.sh, tests/checks/38-run-17-gotchas-and-pack-m3.sh, tests/fixtures/check-names.txt, prompts/coding.md, prompts/parts/where-things-go-readonly.md, prompts/parts/where-things-go-override.md, docs/architecture.md, README.md, journal/decisions/2026-10-26-resolved-and-project-facts.md
- **Verified:** lib/check.sh full run green, 445 tests (248 s); the 6 new checks watched failing first (the two stub-run checks and the prompt check against HEAD's entries.mjs/prompts, the long-fact case before its fix); Opus review of the diff: 1 Important fixed (a long project fact was dropped, now cut to its share)
- **Tests:** 439 → 445
- **Dead end:** Promote items as whole strings checked only against the cap/8 share — a fact over ~1000 bytes (or ~80 at cap 1024) never fit and, being filtered out of Discoveries, vanished from every coding pack; items are now cut to the share's room (≥ 32 bytes)
- **Discovery** (affects M3-04): pack() parts may carry a third element, a byte share: an item past it is counted in items left out without stopping the pack; Promote to Gotchas items are {fact, ref} objects cut to the share's room. M3-04's Current rules (cap/4) can reuse the share slot.
- **Discovery** (affects M3-04, M3-05): lib/eval.sh:134 packs from <clone>/.harness/runs/<run>, which passes the CLAUDE.md guard, so an eval probe's context.md includes Promote to Gotchas (and will include Current rules): the plan said probes read none.
- **Question for Michael:** The eval probe's context.md now reads the clone's CLAUDE.md Gotchas (it shows what the session would read). Keep that, or make probes read none as the plan said?
- **Proposed change:** M3-03 step 2 names `logs/NN-<id>.context.md`, but after STUB_RESOLVE=C's 05-C passes there is no later C coding session; the check reads the next session's pack, `logs/<hhmmss>-verify-M2.context.md`, as the plan says.
- *12-M3-03 · claude-opus-5-5*

### 2026-10-26 21:23 · M3-02 · passes

Finish step 3 in prompts/coding.md: one ## Gotchas line (≤160 chars, ends (<run> <date>), 15 max, edit in place, no rewrite). memlint.mjs gains gotchasLines/gotchasDiff (multiset; a replace is ~1) and `gotchas <before> <after>`; driver gotchas() after journal coding notes `<id>: gotchas +a ~e -d`. STUB_GOTCHA flag, arch §7 row, decision file. Tests 435 → 439.

- **Files:** prompts/coding.md, lib/memlint.mjs, lib/driver.sh, tests/stub-claude.sh, tests/checks/38-run-17-gotchas-and-pack-m3.sh, tests/fixtures/check-names.txt, docs/architecture.md, README.md, journal/decisions/2026-10-26-gotchas-in-place.md
- **Verified:** 4 new checks in tests/checks/38 written first, all 4 FAIL, then PASS; full bash tests/run.sh 439/439 (248 s) and lib/check.sh green, 439 tests; bash -n on driver.sh, stub-claude.sh, check 38; node --check memlint.mjs
- **Tests:** 435 → 439
- **Discovery** (affects M3-03, M3-04): tests/checks/38 runs one stub run `gotcha` (STUB_GOTCHA=B); M3-03/M3-04 checks can add their own runs below it. With KEEP_SCRATCH=1 the stub's sessions.log is at $T/scratch/proj/<run>/sessions.log.
- **Discovery** (affects M3-03): coding.md Finish steps are now 1 suite-verify, 2 suite, 3 Gotchas, 4 entry.json, 5 commit; the M3-03 Promote-to-Gotchas sentence belongs in step 3.
- *11-M3-02 · claude-opus-5-5*

### 2026-10-26 21:11 · M3-01 · passes

Wrote docs/plans/2026-10-26-M3-gotchas-and-pack.md: gotchasLines/gotchasDiff (+a ~e -d, a replace is one edit) and the driver's gotchas() after journal coding; resolved (exact after flattening, later entries only); Promote to Gotchas (coding packs, cap/8); Current rules (last, cap/4, three file shapes); verify cap 16384, failed rows first; stub flags; check names.

- **Files:** docs/plans/2026-10-26-M3-gotchas-and-pack.md
- **Verified:** Each step's terms checked against the plan text; line refs re-grepped (pack lib/entries.mjs:216-269, CLI :314-325, coding loop lib/driver.sh:737-745); check.sh green, 435 tests (cached: plans are outside the key).
- **Tests:** 435 → 435
- **Discovery** (affects M3-04, M4): Real decisions.md stores have three decision-line shapes: `## D7 *default*: …` headings (voice-concierge), `- **D1 · …**` bullets (rane-one-mixxx), `| D24 | … |` table rows (dj-crate-streaming); M3-04's parser and fixtures cover all three.
- **Discovery** (affects M3-03, M3-04): pack CLI must read CLAUDE.md and the decisions store only when the run dir sits at <wt>/.harness/runs/<run>; tests/checks/12 calls `pack` on $T/pk and $T/jr/legacy, whose third parent is outside the throwaway tree.
- **Discovery** (affects M3-02): Gotchas-step text cannot use {{RUN}} (no such prompt variable); the run id is on the `Run:` line under *This run*.
- **Question for Michael:** Promote to Gotchas is in coding packs only (a verify cannot write CLAUDE.md), and a project raising CONTEXT_PACK_BYTES above 16384 does not raise the verify cap: OK as defaults?
- **Proposed change:** M3-03 step 4 should also name `resolved` in prompts/coding.md, and M3-03 should write journal/decisions/<date>-resolved-and-project-facts.md (a behaviour change gets a decision file).
- **Proposed change:** M3-04 step 3's 'byte count may exceed 8192' cannot be observed in a stub run; the plan proves the verify cap with CONTEXT_PACK_BYTES=1024 (verify pack > 1024, coding packs ≤ 1024) instead.
- *10-M3-01 · claude-opus-5-5*

### 2026-10-26 21:06 · verify M2 · passes

All 3 features hold: suite green (435 tests, full run), 37-memory-prompts-m2 15/15 re-run, prompts/templates/docs/decision file read and match each step.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M2-01 | 1 | node --check lib/memlint.mjs; read checks 10-19 of 37-memory-prompts-m2 | ok; decisionsStore exported, store prints journal/decisions; dir/file/null checks PASS | yes |
| M2-01 | 2 | cat prompts/parts/where-things-go*.md | both ~7 lines under ## Where things go, {{DECISIONS}} store line, readonly sends to discoveries | yes |
| M2-01 | 3 | read prompt.sh 57-66, check at line 27/31 | appends block when no heading/no CLAUDE.md; once-each and discoveries checks PASS | yes |
| M2-01 | 4 | checks at lines 36 and 40 | heading 0 times with heading; once each with no CLAUDE.md; PASS | yes |
| M2-01 | 5 | grep check-names.txt; bash tests/run.sh memory-prompts | 15 names listed; 15/15 pass; entries.jsonl names checks | yes |
| M2-01 | 6 | init suite output | green, 435 tests | yes |
| M2-02 | 1 | grep initializer.md; routing check line 50 | old phrase absent; Gotchas/discoveries wording present; no D<n>; check PASS | yes |
| M2-02 | 2 | read coding.md, draft-claude-md.md, templates/project/* | Decisions bullet points at block; draft asks block+Gotchas, no test count; template block+empty Gotchas; commented DECISIONS= | yes |
| M2-02 | 3 | read CLAUDE.md, .harness/config.sh, node lib/memlint.mjs store . | block and empty Gotchas present; DECISIONS=journal/decisions; prints journal/decisions | yes |
| M2-02 | 4 | read decision file and M2 entry | Opus review Important finding fixed (read-only override) and recorded in decision file/entry | yes |
| M2-02 | 5 | read journal/decisions/2026-10-26-where-things-go.md | Finding/Choice/Rejected; seven projects, none set DECISIONS=; both accepted risks | yes |
| M2-02 | 6 | init suite output | green | yes |
| M2-03 | 1 | read docs/architecture.md Memory model | 6x4 table, six rules as specified | yes |
| M2-03 | 2 | grep README.md | line 63-64 name block, Gotchas 15 lines in place, DECISIONS=, append only when heading lacking | yes |
| M2-03 | 3 | grep -c Memory model docs/architecture.md | 2; Principles row cites decisions/2026-10-26-where-things-go | yes |
| M2-03 | 4 | init suite output | green | yes |

- *210433-verify-M2 · claude-sonnet-5-5*

### 2026-10-26 21:00 · M2-03 · passes

docs/architecture.md gains a Memory model section (scope × bucket table, rules 1–6) and a Principles row citing decisions/2026-10-26-where-things-go; README names the routing block, Gotchas and DECISIONS=.

- **Files:** docs/architecture.md, README.md
- **Verified:** grep -c 'Memory model' docs/architecture.md = 2; check.sh green, 435 tests
- **Tests:** 435 → 435
- *09-M2-03 · claude-sonnet-5-5*

### 2026-10-26 20:55 · M2-02 · passes

A background wait I had left running for the review was stopped at its time limit. It doesn't matter: the review had already come back and its findings were handled. M2-02 passes. The last commit is `7ec5b20`, pushed. The full suite is green, and tests went from 429 to 435.

- **Files:** .harness/config.sh, CLAUDE.md, journal/decisions/2026-10-26-where-things-go.md, lib/prompt.sh, prompts/coding.md, prompts/draft-claude-md.md, prompts/initializer.md, prompts/parts/where-things-go-override.md, templates/project/CLAUDE.md, templates/project/config.sh, tests/checks/37-memory-prompts-m2.sh, tests/fixtures/check-names.txt
- *08-M2-02 · claude-opus-5-5 · recorded by the harness: entry.json invalid: summary: 417 characters (at most 400)*

### 2026-10-26 20:21 · M2-01 · passes

lib/memlint.mjs: decisionsStore() (DECISIONS= from .harness/config.sh, else docs/decisions.md, else null), storeLine, CLI store/store-line. prompt_render appends prompts/parts/where-things-go.md (coding, initializer) or -readonly.md (verify, retro) unless CLAUDE.md has a `## Where things go` line; no CLAUDE.md gets it too. Decision file written. Tests 420 → 429.

- **Files:** lib/memlint.mjs, lib/prompt.sh, prompts/parts/where-things-go.md, prompts/parts/where-things-go-readonly.md, tests/checks/37-memory-prompts-m2.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-26-where-things-go.md, docs/architecture.md
- **Verified:** bash tests/run.sh 37-memory: 1/9 before (all of decisionsStore's checks failed on the missing memlint.mjs, and 'where things go: … carry the block once when CLAUDE.md lacks the heading', '… read-only variant …', '… with no CLAUDE.md … once each, the store from DECISIONS=' failed; the heading-present 0-times check passed vacuously), 9/9 after; read the rendered blocks of a KEEP=1 run (wt1 coding, wt3 verify, wt1 retro); node --check, bash -n; full suite via check.sh green, 429 tests incl. the check-names conformance check.
- **Tests:** 420 → 429
- **Dead end:** committing to $T/proj and pushing between stub runs — rejected: each run merges into origin main; `git pull -q --ff-only origin main` first
- **Discovery** (affects M2-02): The three-prompt checks grep -c `## Where things go`: any template line quoting that heading counts. M2-02's coding.md Decisions bullet must name the block without the `## ` prefix (e.g. 'the Where things go block below') or the counts go to 2.
- **Discovery** (affects M2-02, M2-03): journal/decisions/2026-10-26-where-things-go.md exists already with the seven-project census and both accepted risks; M2-02 edits it in place (initializer/coding/template wording) rather than creating it.
- **Discovery** (affects M3, M4): `node lib/memlint.mjs store-line <wt>` gives the block's {{DECISIONS}} phrase; decisionsStore returns {path, kind: dir|file, exists} or null. M3 and M4 import it.
- *07-M2-01 · claude-opus-5-5*

### 2026-10-26 20:10 · verify M1 · passes

All six M1 features hold. Full suite green (420 tests, init run); re-ran harness backlog list/set/import/errors against a throwaway ledger, bash -n and node --check, read plan, decision, review, README, architecture, prompts, stub and checks.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M1-01 | 1 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-01 | 2 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-01 | 3 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-01 | 4 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-01 | 5 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-02 | 1 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-02 | 2 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-02 | 3 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-02 | 4 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-02 | 5 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-02 | 6 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-02 | 7 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-03 | 1 | bin/harness backlog list/set/import/bad args with a temp HARNESS_LEDGER, LEDGER_COMMIT=0; read check names in 36-run-16 file | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-03 | 2 | bin/harness backlog list/set/import/bad args with a temp HARNESS_LEDGER, LEDGER_COMMIT=0; read check names in 36-run-16 file | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-03 | 3 | bin/harness backlog list/set/import/bad args with a temp HARNESS_LEDGER, LEDGER_COMMIT=0; read check names in 36-run-16 file | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-03 | 4 | bin/harness backlog list/set/import/bad args with a temp HARNESS_LEDGER, LEDGER_COMMIT=0; read check names in 36-run-16 file | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-03 | 5 | bin/harness backlog list/set/import/bad args with a temp HARNESS_LEDGER, LEDGER_COMMIT=0; read check names in 36-run-16 file | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-03 | 6 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-04 | 1 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-04 | 2 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-04 | 3 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-04 | 4 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-04 | 5 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-04 | 6 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-04 | 7 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-05 | 1 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-05 | 2 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-05 | 3 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-05 | 4 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-05 | 5 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-05 | 6 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-06 | 1 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-06 | 2 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-06 | 3 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-06 | 4 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |
| M1-06 | 5 | read the named file/check assertions; suite 420/420 green; bash -n and node --check | Output and file contents match the step; matching check in tests/checks/35/36 passes in the full suite | yes |

- *200939-verify-M1 · claude-sonnet-5-5*

### 2026-10-26 20:05 · M1-06 · passes

Opus review of the M1 diff (1065 lines): 0 Critical, 5 Important, 9 Minor; no second round. Fixed all 5 Important and Minor 6-8 test-first: forward-only import, one-line 200-char titles, a cap keeping every id·status, JSONL skip + {more:n}, LEDGER_COMMIT=1 run check, no symlinked proposals, unlistable store noted. Stray .tmp removed. Tests 413 → 420.

- **Files:** lib/backlog.mjs, lib/driver.sh, tests/stub-claude.sh, tests/checks/35-backlog-pure-m1.sh, tests/checks/36-run-16-retro-backlog.sh, tests/fixtures/check-names.txt, docs/plans/2026-10-26-M1-review.md, journal/decisions/2026-10-26-retro-backlog.md, docs/architecture.md, README.md, .tmp (removed)
- **Verified:** Each new check red then green: `backlog import: a re-import keeps a later status and the links the row lacks (status never moves back)`, `backlog merge: a title's newlines and control characters fold to one space, at most 200 characters`, `backlog validate: the why line of a huge bad id stays under 300 bytes`, `backlog list: past --max-bytes every row keeps its id and status, full lines first`, `backlog list --jsonl: a row too big is skipped, not the rest; a cut list ends with a {"more": n} line`, `backlog run: a symlinked retro-proposals.json is not followed, and a store that will not list is noted`; `backlog run: with LEDGER_COMMIT=1 the run's ledger commit carries retro-backlog.jsonl with its proposal` red with the paths+= line removed, green restored. bash -n on the six named files, node --check lib/backlog.mjs. check.sh green in 229 s, 420 tests.
- **Tests:** 413 → 420
- **Dead end:** noting an unlistable store before the retro session — restrict reverts harness-log.md edits made after rstart; the note is now written after restrict
- **Discovery** (affects run): Any note() written in retro() between rstart and restrict is reverted with the retro's edits: write it after restrict (as S_NOTES are).
- **Discovery** (affects M2, M3): backlog.mjs exports oneLine (whitespace and control characters folded, 200 chars): reuse it for any retro-written text that reaches a prompt.
- **Question for Michael:** Review finding 10 (left): `harness backlog set/import` can race lib/sync.sh's rebase since sync takes no ledger.lock. Add it to the backlog (e.g. `sync-ledger-lock`) or fix in a later run?
- *06-M1-06 · claude-opus-5-5*

### 2026-10-26 19:47 · M1-05 · passes

M1-05 passes, in commit `8623944`, pushed to the run branch. - **Retro:** its prompt now has a `## Backlog` section with the current backlog list and three rules: reuse an existing id, cite the status of an item already specced, queued or merged instead of re-arguing it, and make up a new id only for a new proposal. - **Debrief:** it now gets the backlog instead of the list of old `retro.md` file…

- **Files:** README.md, docs/architecture.md, journal/decisions/2026-10-26-retro-backlog.md, lib/debrief.sh, lib/driver.sh, prompts/debrief.md, prompts/retro.md, tests/checks/36-run-16-retro-backlog.sh, tests/fixtures/check-names.txt
- *05-M1-05 · claude-opus-5-5 · recorded by the harness: entry.json invalid: summary: 411 characters (at most 400)*

### 2026-10-26 19:39 · M1-04 · passes

retro() copies the retro's retro-proposals.json to scratch before restrict (skipped from the reverted note, put back in the run record); ledger() merges it under flock 9 and commits the store with the ledger. Retro prompt allows that one file; stub gains STUB_RETRO_PROPOSALS and a ledger/ edit under STUB_RETRO_EDITS; decision file. Tests 407 → 411.

- **Files:** lib/driver.sh, prompts/retro.md, tests/stub-claude.sh, tests/checks/36-run-16-retro-backlog.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-26-retro-backlog.md, docs/architecture.md, README.md
- **Verified:** 4 backlog run checks in 36-run-16-retro-backlog.sh written first, all FAIL (5/9), then 9/9; KEEP=1 run showed bk1 `backlog: 1 new, 0 seen again`, bk2 `0 new, 1 seen again` and reverted `.harness/runs/bk2/progress.md ledger/retro-backlog.jsonl retro-hack.txt`, bk3 `retro-proposals.json invalid: not JSON…`; full suite 411/411 (220 s); git status -- ledger/ empty.
- **Tests:** 407 → 411
- **Discovery** (affects M1-05, M1-06): Every run with RETRO=1 whose retro wrote no proposals now notes `backlog: the retro wrote no retro-proposals.json` (in retro(), not finish()). The backlog merge note is written after ledger()'s cp -r, so it is in the worktree harness-log.md (committed by `run end notes`) but not the ledger copy.
- **Discovery** (affects M1-05): 36-run-16-retro-backlog.sh now ends with runs bk1, bk2 (STUB_RETRO_EDITS=1), bk3 (bad) on one $T; $ST then holds one row no-retry-on-denial seen in bk1,bk2. M1-05's prompt-retro check should reseed $ST (test-counts specced) before its own run; the file takes ~39 s.
- **Discovery** (affects M1-05): prompts/retro.md `## Proposed harness changes` still says “whether an earlier retro proposed it already (say which run)” and Read still globs */*/retro.md: M1-05 swaps both for the backlog.
- *04-M1-04 · claude-opus-5-5*

### 2026-10-26 19:29 · M1-03 · passes

Added lib/backlog.sh (harness backlog [list] | set | import, writes under flock on $STATE_ROOT/ledger.lock, one `ledger: backlog …` commit of retro-backlog.jsonl alone when LEDGER_COMMIT=1 and the ledger is a git checkout), bin/harness dispatch + header, the 8-row seed file, README row and ## Retro backlog section with Michael's import command. Tests 402 → 407.

- **Files:** lib/backlog.sh, bin/harness, docs/specs/2026-10-25-memory.backlog-seed.jsonl, README.md, tests/checks/36-run-16-retro-backlog.sh, tests/fixtures/check-names.txt
- **Verified:** 5 new checks in tests/checks/36-run-16-retro-backlog.sh written first and watched failing (0/5), then 5/5; full suite via check.sh green, 407 tests in 207 s; bash -n lib/backlog.sh bin/harness; git status --porcelain -- ledger/ empty; by hand: a held ledger.lock makes set wait
- **Tests:** 402 → 407
- **Discovery** (affects M1-04, M1-06): harness backlog errors go to stderr as one line, exit 1: set's are `backlog: <why> · usage: harness backlog set …` (unknown id, bad status, missing argument or option value), an unknown subcommand or extra list argument a usage line. Import resolves the file against the caller's cwd before taking the lock; the commit message is `ledger: backlog import <basename>` / `ledger: backlog set <id> <status>`.
- **Discovery** (affects M1-04, M1-05): Seed rows carry note `proposed in N retros` for test-counts (6), review-cost (8), carry-on-past-given-up (4), null otherwise; spec is the table's text verbatim (e.g. `retro-fixes R1, this spec M5`), null for no-retry-on-denial. 36-run-16-retro-backlog.sh has one $T; M1-04's `backlog run` checks append there and its file's store already holds the 8 seed rows by its end (ST=$HARNESS_LEDGER/retro-backlog.jsonl), so they should rm or reseed it first.
- **Discovery** (affects M1-04, M1-05): README's new ## Retro backlog section already says the driver writes the backlog (M1-04's merge); docs/architecture.md §4 row and the Debrief paragraph are still M1-05's.
- *03-M1-03 · claude-opus-5-5*

### 2026-10-26 19:23 · M1-02 · passes

Added lib/backlog.mjs (pure exports STATUSES, parseRows, formatRows, validateProposals, mergeProposals, setStatus, orderRows, importRows, listLines; CLI merge/set/list/import/validate, atomic tmp+rename writes) and tests/checks/35-backlog-pure-m1.sh, 7 checks written first. Tests 395 → 402.

- **Files:** lib/backlog.mjs, tests/checks/35-backlog-pure-m1.sh, tests/fixtures/check-names.txt
- **Verified:** Red first, before lib/backlog.mjs existed, all 7 failed: 'backlog merge: a new id becomes one proposed row first seen in its run', 'backlog merge: a known id adds its run to runs_seen once, status unchanged', 'backlog validate: bad JSON, a missing id or a non-slug id exits 1 with one line, rows unchanged', 'backlog set: specced --spec flips the status and records the spec; an unknown id or status exits 1', 'backlog list: proposed first, then more runs_seen first within a status', 'backlog import: 8 rows into an empty store, then again 8 (idempotent by id)', 'backlog import: a known id takes status, spec, pr and note, keeps first_seen, unions runs_seen'. Then 7/7 (bash tests/run.sh 35-backlog); full suite via lib/check.sh green, 402 tests, conformance passing; node --check lib/backlog.mjs.
- **Tests:** 395 → 402
- **Dead end:** the list check reading the same store the set check edited — set leaves bb-once with a spec, so the line lengths and --max-bytes cut changed; the list check now reads an untouched copy (four.jsonl)
- **Discovery** (affects M1-03, M1-04): CLI output channels: merge's ok and invalid lines and validate's why line go to stdout (the driver notes `$(node lib/backlog.mjs merge …)`); set/import/usage errors go to stderr as one `backlog: <why>` line, exit 1 (usage: exit 2 for an unknown command). set on a missing store exits 1 (unknown id) and writes nothing.
- **Discovery** (affects M1-03, M1-05): list --max-bytes is a hard cap including the `… (<n> more rows)` line; list --jsonl --max-bytes stops at whole rows with no trailer. import of a known id sets spec/pr/note to the import row's values (null when absent), keeps title and first_seen; a new import row needs a title, a slug id and one of the five statuses.
- *02-M1-02 · claude-opus-5-5*

### 2026-10-26 19:16 · M1-01 · passes

Wrote docs/plans/2026-10-26-M1-retro-backlog.md: row schema and defaults, lib/backlog.mjs's exported API and CLI, harness backlog forms, retro()/finish() handling of retro-proposals.json via scratch past restrict, retro prompt Backlog section, the two debrief changes, STUB_RETRO_PROPOSALS, check names for files 35/36, the 8 seed rows, the live import steps.

- **Files:** docs/plans/2026-10-26-M1-retro-backlog.md
- **Verified:** grep of the plan for each step's names (schema, 5 statuses, 3 CLI forms, STUB_RETRO_PROPOSALS, 35/36 file names, flock 9, HARNESS_SCRATCH, lib/debrief.sh:164-165, the 8 seed ids); driver line refs re-read (retro 499-511, ledger 513-525, finish 527-569); suite green 395 (cached, plan-only tree)
- **Tests:** 395 → 395
- **Discovery** (affects M1-04): restrict also deletes retro-proposals.json; the plan has retro() copy it to $SCRATCH before restrict only when it differs from the rstart copy (a continued run's old file isn't re-merged), leave it out of the reverted-edits note, and put it back in the run record as retro.md is, so the ledger keeps the evidence
- **Discovery** (affects M1-02, M1-05): The debrief gatherer needs run ids to flag re-raised items, so it uses `backlog.mjs list --jsonl --max-bytes 6000` (ordered rows); the retro prompt uses the text list (`<id> · <status> · seen <n> · <title>…`), which carries the `test-counts · specced` prefix M1-05 greps
- **Discovery** (affects M1-03, M1-04, M1-05): `run 16` is already the parking run's label (tests/checks/13-run-2-michael-sets-desk.sh:261); the plan's checks in 36-run-16-retro-backlog.sh say `backlog run` instead
- **Question for Michael:** Defaults taken in the plan (to be recorded in journal/decisions/2026-10-26-retro-backlog.md by M1-04): unset links are null; a proposals file is all-or-nothing (≤10 items, kebab ids ≤60 chars); seed rows have first_seen {run: seed, date: 2026-10-25}, runs_seen []. Change any?
- *01-M1-01 · claude-opus-5-5*

### 2026-10-26 19:12 · init · passes

23 features: M1 6 (plan, backlog.mjs, CLI + seed, retro emits and driver merges, retro prompt + debrief, review), M2 3 (block + decisionsStore, prompts and templates with folded review, docs), M3 5 (plan, Gotchas note, resolved questions, current rules, review), M4 2 (memlint, run-start notes + CLI), M5 2 (contract, tests-end per session), M6 5 (plan, gate, escalation, summary, review).

- **Files:** .harness/runs/agent-harness-2026-10-25-memory/feature_list.json
- **Verified:** jq parses the list; `node lib/features.mjs lint` prints nothing; summary 0/23; undeclared empty; next with empty attempts is M1-01; with M1-01 given up next is M2-01 and only M1 is blocked; with M2-01 given up M3 and M4 are blocked, M5 and M6 are not.
- **Tests:** 395 → 395
- **Discovery** (affects run): R1 (decisions/2026-10-26-real-test-counts) and R2 (decisions/2026-10-26-reviews-sized-to-milestone) are both on main, so M5 and M6 keep their bases; nothing is dropped. The lanes run (P1/P2) is NOT on main: the driver is serial, so the array order is the build order (M1, M2, M3, M4, M5, M6) and `after` only keeps a stuck milestone from blocking the independent ones.
- **Discovery** (affects run): The suite is split: a new check goes in a tests/checks/NN-<slug>.sh file by topic (sourcing tests/lib.sh, suite_setup … suite_end) and its name must be added to tests/fixtures/check-names.txt in C sort order (`LC_ALL=C sort -u`), or the full run's conformance check fails. Run a subset by file-name fragment: `bash tests/run.sh backlog`. Full suite ~206 s with TEST_JOBS=4, 395 checks at init.
- **Discovery** (affects M1): restrict() in lib/driver.sh (line 87) with `nothing` (the retro) reverts EVERY file the retro changed or created, the run directory included: an added file is `git rm`'d. So retro-proposals.json must be copied from $RUN_DIR to $SCRATCH in retro() (lib/driver.sh:499-511) before `restrict "$rstart" nothing retro`, and finish() merges from the scratch copy. ledger() (line 513) holds `flock 9` on $STATE_ROOT/ledger.lock and commits only when LEDGER_COMMIT=1 and $LEDGER is a git checkout; the suite sets HARNESS_LEDGER=$T/ledger (not a git repo) and LEDGER_COMMIT=0.
- **Discovery** (affects run): Prompt variables: lib/render.mjs fills {{NAME}} from env HARNESS_NAME, empty when unset. prompt_render in lib/prompt.sh:62-78 adds prompts/parts/rules.md only when the worktree has a CLAUDE.md, and for the retro adds only that part; the M2 block must be appended for the no-CLAUDE.md case too. The retro's env is set at lib/driver.sh:502 (HARNESS_LEDGER etc.) before `prompt retro`. Rendered prompts of a stub run are at $HARNESS_STATE/proj/<run>/prompt-<kind>.md and beside each transcript as logs/NN-<id>.prompt.md.
- **Discovery** (affects run): tests/stub-claude.sh acts out sessions keyed on the prompt's first line; the retro branch is `"# Retro")` near line 154 (STUB_RETRO_EDITS writes retro-hack.txt and appends to progress.md), the coding branch near line 68 reads the feature id from the `Feature:` line under `# This session`; entry() writes entry.json by jq; new STUB_* flags are documented in the stub's header comment. The stub initializer writes a fixed 3-feature list (A, B in M1; C in M2): a review-gate check (M6) needs a flag for a list with a 3-build milestone plus a review feature.
- **Discovery** (affects M1-05): The debrief gatherer block to change for M1 is exactly lib/debrief.sh lines 164-165 (`echo; echo "## Earlier retros …"` and `ls -t "$LEDGER"/*/*/retro.md | head -20 | fence`), inside the `{ … } > "$CTX"` group; the parked n8n-events run (A2) moves that block later, so keep the change inside it. `harness debrief --dry-run` prints the context without a session (cheap in a check). The debrief session's ALLOW list (lib/debrief.sh ~line 200) would need `harness backlog list` added if the session is to run it; the gathered context makes that unnecessary.
- **Discovery** (affects M3): Context pack: lib/entries.mjs pack() (lines 193-275) has five parts in fixed priority; `entries.mjs pack <run dir> <feature> <cap>` is called by context() in lib/driver.sh:284-300 with $CONTEXT_PACK_BYTES (lib/config.sh:28, default 8192); verify() calls `context "$m"` per round. The worktree is three directories above the run dir (.harness/runs/<run>). validate() (lines 36-76) and normalize() (85-96) list the accepted entry fields: a new field (`resolved`) must be added to both or it is dropped. Existing pack checks: `context.md carries the earlier attempt's dead end` in tests/checks/13, 14, 15 (cap 8192 asserted with `wc -c`) and tests/checks/12-journal-pure-e4-entrys.sh.
- **Discovery** (affects M2, M4): On 2026-10-26 every project with a CLAUDE.md (dj-crate-streaming 105 lines, hit_list 181, n8n-home 120, pathways 49, portfolio_site 127, rane-one-mixxx 92, voice-concierge 56) already has `## Where things go` and `## Gotchas` (chunk 3 Part 2); none sets DECISIONS= in .harness/config.sh; agent-harness itself has neither heading (51 lines, and its `How to verify` line stores `395 checks`, which memlint will flag). backups, career, ideas, library, proposals and setup have no CLAUDE.md and no .harness/project.md. Record this in M2's decision file.
- **Discovery** (affects M4-01): M4 fixture sources, verified read-only in the projects' histories (reading other projects is allowed; never write there): dj-crate-streaming `git show ed75a2d^:CLAUDE.md` line 16 (`~1,870 tests, **about 11-12 minutes**`); pathways `git show 4cafb65^:.harness/project.md` lines 18-24 (`no rename tonight`, `if time looks short`; the file was removed at 4cafb65); rane-one-mixxx `git show aa88421^:docs/decisions.md` lines 3-5 (the current-rule-set header, added in 266f369) and line 110 (`**Superseded in part by D17** (2026-10-21)` with no `Updated in place`); the tidy version is `aa88421:docs/decisions.md`. Run `git -C <project dir> show <commit>:<path>` from the worktree; trim to the cited lines plus a little context; first line of each fixture names repo, commit, path.
- **Discovery** (affects M5): Test counts: lib/testcount.mjs testCount() is first-rule-wins (node, cargo, jest, go, generic); lib/check.sh writes `<n> tests` into the green marker $STATE/green/green-<key> and appends it to its green line with sed; run_init (lib/driver.sh:302-318) writes tests-start once and notes `test count: no match …` once per run via $STATE/testcount-nomatch; finish() (lines 531-535) writes tests-end from the marker or check-<key>.out. The driver loop's post-session `green` check is at line ~745 (`if F passes … && ! green`). A real agent-harness check.out for a fixture is this run's scratch /tmp/harness/agent-harness/agent-harness-2026-10-25-memory/check.out (ends `395/395 checks passed`); copy and trim it before finish deletes scratch.
- **Discovery** (affects M6): Review gate (M6): `F next` (features.mjs `next`) returns `id\tmodel\tmilestone` with the feature's own model via modelId(); the driver reads it at `IFS=$'\t' read -r id mdl milestone <<< "$next"` (~line 700) and passes $mdl to `session coding`; `F kind "$LIST" "$id"` gives the kind. The verify escalation pattern to mirror is verify() lines 398-470 (models array VERIFY_MODEL then VERIFY_ESCALATE_MODEL, note `re-running on …`). metrics.jsonl rows carry model and kind (MET append at ~line 752). evals/NEXT.md's existing sections 1-4 show the command format (`EVAL_BUDGET_USD=35 harness eval run --set default --harness <tag> --label <l>`, `harness eval compare A B`).
- **Discovery** (affects run): Decision files: journal/decisions/<YYYY-MM-DD>-<slug>.md, title line, provenance line in italics (run, feature, spec section, plan), then `- **Finding:**`, `- **Choice:**`, `- **Rejected:**` bullets (see journal/decisions/2026-10-26-real-test-counts.md). Never number one, never append to journal/decisions.md. Plans: docs/plans/<date>-<milestone>-<topic>.md, header as docs/plans/2026-10-26-F2-initializer-verify.md (`Checked against main at <sha>`, `What main already has`, one feature per item).
- **Discovery** (affects run): Lint rules (features.mjs lint) flag a path in `~` or $HOME in a step (outside-repo) and a grep whose pattern matches the step's own text when the target is progress.md, entries.jsonl, context.md or feature_list.json (self-match); harness-log.md is not a quoting file. Steps here name checks by their check name instead; a session's `proposed_changes` is where a wrong step goes.
- **Question for Michael:** M6 escalation signal: the driver reads `<n> Critical` / `<n> Important` from the review session's entry summary (else its final message). Default taken; say if you want the review to write a structured findings file instead.
- **Question for Michael:** M3 pack: `Current rules` is the last pack part at most a quarter of the cap, and a `project` discovery leaves `Promote to Gotchas` once a `## Gotchas` line shares its first 40 characters. Both defaults taken; say if you want another share or match rule.
- **Question for Michael:** M5: the structured `TEST_REPORT` option of retro-followups §C is not built (the `HARNESS_TESTS=<n>` contract line covers it: a project's check prints it from its own report). Default taken.
- **Question for Michael:** M4: memlint runs at every segment start (a continue re-lints: the project may have changed), not once per run. Default taken.
- *00-init · claude-fable-5-1*
