<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-29-2` (agent-harness)

What this file is: the run's journal, rendered by the harness from `entries.jsonl` after every session, newest entry first. Each entry says what one session did, how it verified it, what it tried that failed, and what it asks Michael.

The spec is `docs/specs/2026-10-28-reliability.md`: R1 fixes the flaky checks at their cause (tests wait on conditions, `tests/run.sh --repeat` reproduces a flake), R2 keeps a session's entry (validator as the last step, a long summary trimmed, one resume for a missing entry), R3 closes the lanes-review leftovers and adds two lint rules, R4 gives questions a place to wait in `harness needs`. R1, R2 and R3 run side by side on two lanes; R4 waits for R2.

How to read the feature list (`feature_list.json`): array order is priority; `after` names what a feature really waits on; `passes` flips only when every step holds. Plans: `docs/plans/2026-10-29-R<n>-*.md`; reviews: `docs/plans/2026-10-29-R<n>-review.md`.

To steer: edit `INBOX.md` in this directory on branch `harness/agent-harness-2026-10-29-2` (first line `status: pause` or `status: stop`; answers under `## Answers`). The harness pulls before every session. Questions sessions asked are in `harness needs <run>` once R4 lands; until then in the entries below.

### 2026-10-29 15:41 · R1-05 · passes

Both run flakers are R1-04's lane-count race. Neither reproduced unforced (10/10 green each). Forced with HARNESS_COUNT_HOLD=1 on the pre-fix driver, 28 ended 'no feature left to try' before M2 and 15's weekly run did too. Both runs now start with the hold: red before the fix (0/1), 10/10 after. Plan rows filled; decision updated in place. Merged origin/main.

- **Files:** tests/checks/15-run-4-same-but-queue-parked-debrief-tmux.sh, tests/checks/28-run-14d-harness-merge.sh, docs/plans/2026-10-29-R1-flakes.md, journal/decisions/2026-10-29-lane-count-end-check.md, tests/stub-claude.sh
- **Verified:** Before: `28-run-14d-harness-merge: 10/10 green` (91 s) and `15-run-4-same-but-queue-parked-debrief-tmux: 10/10 green` (903 s), run at the same time. Forced on the driver without `alive == 0`: 28 logged `count hold: 1 lane(s) counted, held until gone` · `no feature left to try: 2/3 passing` · `lane M1 closed (M1 verified)`; 15's weekly ended `no feature left to try` with `lane M1 closed (weekly budget (7-day window at 90%…))`. With the hold pinned and the fix reverted: 0/1 on each, only the target check failing. After: `28-run-14d-harness-merge: 10/10 green` (65 s), `15-run-4-same-but-queue-parked-debrief-tmux: 10/10 green` (653 s). Full suite after merging main: `973/973 checks passed`, check: green in 930 s. `git diff origin/main -- tests/fixtures/check-names.txt` removes 0 lines.
- **Tests:** 944 → 973
- **Dead end:** suite through check.sh as a background job with a 10 min limit — under the box's load (8-9) the full suite took 930 s; the job was killed before it reported
- **Discovery** (affects R1-06, R1-07): 15's weekly check and 28 were R1-04's coordinator race, not settle's box-wide pgrep: forced, both end 'no feature left to try' with the lane closing just after. The settle lead for 15 is ruled out.
- **Discovery** (affects R1-06): HARNESS_COUNT_HOLD=1 exported around tests/run.sh reaches every run of a check file (bin/harness passes it on), so a file can be tested forced without editing it. Revert the end-check line to see the pre-fix behaviour.
- **Discovery** (affects run): Merging origin/main brought R2 in: its stub-claude.sh header comments conflicted with R1-02's STUB_BARRIER comment. Both are kept; the suite went from 944 to 973 checks.
- *07-R1-05 · claude-opus-5-5*

### 2026-10-29 15:29 · R3-01 · passes

Wrote docs/plans/2026-10-29-R3-leftovers.md: one section per R3 item with its function, file at 53bdc66 and check file; Minor 8 quoted and found cheap (built in R3-04); unreproducible's regexes tried on every example; N1 and N2 both on origin main (2). Plan only; Gotchas: promoted the stub --resume line in place of the HARNESS_NOW one.

- **Files:** docs/plans/2026-10-29-R3-leftovers.md, CLAUDE.md
- **Verified:** grep -cE '...-N[12]$' on origin/main = 2; the unreproducible patterns run in node against 9 match / 13 no-match examples (all as the table says) and this run's list (3 steps flagged); Minor 8 lines copied from lib/lane.sh at HEAD; memlint subset 19/19; full suite via check.sh
- **Tests:** 963 → 963
- **Discovery** (affects R3-02): grep -c 'writeFileSync' lib/features.mjs counts the import line too: R3-02 must drop it from the named import (namespace import for the helper) or the step prints 2
- **Discovery** (affects R3-05): slots live at $T/wt/proj/lanes/<run>/slot-<k>, not <run>-slots/slot-1; gc --dry-run names only a lane branch already merged into origin/main: put the check in 49's sp block before its gc
- **Discovery** (affects R3-03): The ignored-paths merge note must contain neither 're-base' nor 'moved since' (R3-03 step 1 greps both absent): plan gives '<m>: main changed only in ignored paths (<paths>); merged as verified'
- **Discovery** (affects R3-03): finish: ledger reads $SCRATCH/retro-proposals.json, so ledger and scratch_done move together after record_pr; the backlog note then misses main's copy
- **Discovery** (affects R3-04, R3-06): Minor 8 at HEAD: one rec_commit follows the passes note and the gate, so no run ends between them; the move sets passed=false for an escalated review (its first metrics row turns false)
- **Discovery** (affects R3-02, run): unreproducible flags 3 steps of this run's list (R1-02 step 4 'below 5 s', R3-01 step 3, R3-02 step 3 quoting the examples): expected, reported never applied
- **Resolved:** Discovery (init, affects run): N2 (conflict resolution) is not on origin main: N2-02 waits on Michael. Only N1 merged (grep -c harness-merge/...-N[12] = 1). A text conflict between two lanes needs Michael as before; each plan says so in one line. → entries.jsonl:1
- **Resolved:** Discovery (R1-01, affects run): N2 is not on origin main (1 of N1/N2 merged): an overlap conflict between lanes needs Michael → entries.jsonl:3
- **Proposed change:** R3-05 step 1 should name the slot path $T/wt/proj/lanes/<run>/slot-1 (slot_gc's layout), not $T/wt/proj/<run>-slots/slot-1, and a lane branch merged into main (gc names no unmerged one)
- **Proposed change:** R3-02 step 1's grep should be 'writeFileSync(' (the call), or the plan's namespace import is required for it to print 1
- **Proposed change:** A 'review round pending' cause in summary.mjs (a lanes/*/review-escalate file at the end) would give Minor 8's summary.json effect; not in R3's scope
- *08-R3-01 · claude-opus-5-5*

### 2026-10-29 14:56 · verify R2 · passes

All 28 steps of R2-01..05 hold. Suite 963/963 (full, this tree), subsets 76/12/05/16/18/25 52/52. Re-ran by hand: ingest trim (400 with …), stub init/--resume/unknown id, resumeRow vs jq, own stub runs good/bad/edits/limit/long-summary (resume argv, own scope s3, 10m, entry-resume row, session count equal), finding 1 RED at 3654c5c.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| R2-01 | 1 | grep sections/terms in docs/plans/2026-10-29-R2-entries.md | sections entry check, trim, background-work rule, resume, stubs, Checks (76's names); HARNESS_ENTRY_CHECK in prompt_env, {{ENTRY_CHECK}} in 3 prompts, journalEntry cut 399+… = 400 code points, note 'cut to 400 and kept' | yes |
| R2-01 | 2 | read §The resume | entry_resume in lib/record.sh (called from journal before the ingest, same exit-1 test, outside the lock: reasoned move from journal_), MET limit, --resume flags, turns 8, timeout 10m, budget cost+1, scope s<n>, <nn>-<id>.resume.jsonl, restrict, both notes, entry-resume row, 0.0031→0.0055→0.0058 | yes |
| R2-01 | 3 | read §The stubs | init line with session_id, --resume (unknown-id.out lines 1/2, exit 1), STUB_NO_ENTRY, STUB_RESUME_ENTRY=good\|bad\|good-edits, $STUB_DIR/resume.log | yes |
| R2-01 | 4 | read dependency line; git log --oneline origin/main \| grep -cE '...-N[12]$' | plan states 1 (N1 only) and a lane conflict needs Michael; today the count is 2 (N2 merged 11:19, in HEAD): the line was right when written | yes |
| R2-01 | 5 | check.sh (full, cache cleared by harness) + check.sh rerun | 963/963 checks passed in 965 s at 08b5edf; check.sh now 'green (cached for this code tree, 963 tests)'; my subset 76/12/05/16/18/25: 52/52 | yes |
| R2-02 | 1 | grep lib/prompt.sh + prompts; lib/prompt.sh <state> coding\|verify\|initializer A in my stub run | prompt.sh:51 exports HARNESS_ENTRY_CHECK; each rendered prompt has 'node …/lib/entries.mjs validate <run directory>/entry.json …', no literal {{ENTRY_CHECK}}; check 76 'renders as lib/entries.mjs validate' green | yes |
| R2-02 | 2 | grep background prompts/{coding,verify,initializer}.md | each: 'Never end your turn while a background task or subagent is still running: wait for it, or stop it and say so in your entry'; 76 check greps it, green | yes |
| R2-02 | 3 | node lib/entries.mjs ingest on a 410-char summary entry, then with outcome maybe; 12 checks | exit 0 'trimmed summary 410', summary 400 code points ending … (399+…), dead_ends 1, questions 1, no minimal; maybe → exit 3, minimal 'invalid: outcome: "maybe"…'; 12's trim/maybe/header/validate-exit checks green (😀 padding) | yes |
| R2-02 | 4 | own stub run STUB_LONG_SUMMARY=A | harness-log '· A: entry.json summary 410 characters; cut to 400 and kept'; A's entry minimal null, summary length 400; no resume.log | yes |
| R2-02 | 5 | check-names grep for 76/12/05 names; bash -n prompt.sh record.sh stub-claude.sh; node --check entries.mjs | every name listed, file LC_ALL=C sorted, 29 added lines; syntax ok | yes |
| R2-02 | 6 | check.sh (full, cache cleared by harness) + check.sh rerun | 963/963 checks passed in 965 s at 08b5edf; check.sh now 'green (cached for this code tree, 963 tests)'; my subset 76/12/05/16/18/25: 52/52 | yes |
| R2-03 | 1 | stub run directly on a coding prompt (STUB_NO_ENTRY=A) | first line init, session_id c3a40d6f-… matches ^[0-9a-f-]{36}$, built from first.jsonl's init line (cwd, session_id replaced) | yes |
| R2-03 | 2 | stub --resume <that id> and --resume 11111111-… | known: same session_id, total_cost 0.25 → 0.25240851 = 0.25 + (resumed − first); unknown: stderr 'No conversation found…', error_during_execution line, exit 1; argv in stub/resume.log | yes |
| R2-03 | 3 | same direct run; read stub header lines 56-62 | no run/entry.json with STUB_NO_ENTRY=A; header documents STUB_NO_ENTRY, STUB_RESUME_ENTRY good\|bad\|good-edits (and good-overreach); good-edits writes resumed.txt (stub:341) | yes |
| R2-03 | 4 | node lib/metrics.mjs session-id first.jsonl; resumeRow on fixtures vs jq | session-id = jq's ef525536-…; first→resumed cost 0.00240851 = jq diff; resumed→under-cap 0.00028224 > 0 = jq diff; 05's 3 checks green | yes |
| R2-03 | 5 | check-names + bash -n tests/stub-claude.sh + node --check lib/metrics.mjs | all listed; ok | yes |
| R2-03 | 6 | check.sh (full, cache cleared by harness) + check.sh rerun | 963/963 checks passed in 965 s at 08b5edf; check.sh now 'green (cached for this code tree, 963 tests)'; my subset 76/12/05/16/18/25: 52/52 | yes |
| R2-04 | 1 | cat prompts/entry-resume.md; grep lib/config.sh | prompt: errors (It is missing. / The entry check printed:), write entry.json and nothing else, run {{ENTRY_CHECK}}, end; config.sh:14 ENTRY_RESUME_TURNS=8 ENTRY_RESUME_TIMEOUT=10m ENTRY_RESUME_BUDGET_USD=1 | yes |
| R2-04 | 2 | read entry_resume; own stub run vgood: resume.log, systemd stub log | coding/verify/init, validate exit 1, not MET limit; argv '--model claude-sonnet-5-5 --permission-mode auto --strict-mcp-config --max-turns 8 --max-budget-usd 1.25 … --resume <sid>'; own unit harness-vgood-M1-s3 under 'timeout -k 30s 10m'; 01-A.resume.jsonl; edits dropped + restrict when HEAD moved; ingest after | yes |
| R2-04 | 3 | own stub run STUB_NO_ENTRY=A STUB_RESUME_ENTRY=good vs plain | 1 --resume line with 01-A.jsonl's init sid; 01-A.resume.jsonl beside it; entry dead_ends 1, minimal null; note 'A: entry.json written on a resume'; 1 entry-resume row cost 0.00240851 = 0.25240851−0.25; summary.json sessions.total 7 = plain's 7 | yes |
| R2-04 | 4 | own stub runs bad, good-edits, STUB_LIMIT_MIDWAY (16's scenario) | bad: minimal 'invalid: not JSON…', note '…still invalid (not JSON: …) after one resume; recorded a minimal entry'; edits: resumed.txt in no commit of origin or proj (git log --all), entry written; limit: 'hit a limit', no resume.log | yes |
| R2-04 | 5 | check-names grep; bash -n lib/record.sh lib/config.sh | all 76 names listed; ok | yes |
| R2-04 | 6 | check.sh (full, cache cleared by harness) + check.sh rerun | 963/963 checks passed in 965 s at 08b5edf; check.sh now 'green (cached for this code tree, 963 tests)'; my subset 76/12/05/16/18/25: 52/52 | yes |
| R2-05 | 1 | read docs/plans/2026-10-29-R2-review.md; R2.diff in scratch (710 lines); replayed finding 1 at 3654c5c vs HEAD | one Opus round on R2.diff, 0 Critical, 3 Important all fixed with checks; resumeRow without result line: −0.0031115 at 3654c5c, 0 now (RED→GREEN real) | yes |
| R2-05 | 2 | read ## Simplifications | 6 rows: 3 applied, 3 left, each with why | yes |
| R2-05 | 3 | cat journal/decisions/2026-10-29-entries-survive.md | title, provenance, finding, choice, rejected: dropping the 400 cap, resuming more than once, resuming a refused session, writing the entry from the transcript by code | yes |
| R2-05 | 4 | grep docs/architecture.md §4 (Where state lives) + §5 (life of a run); README Steering | §4 entry row: trim, resume, minimal; metrics row: entry-resume; transcripts: .resume.jsonl; §5: ENTRY_CHECK, no background work, one resume; README 'Entries:' bullet under ## Steering: check, cut to 400, one resume, entry-resume row | yes |
| R2-05 | 5 | check.sh (full, cache cleared by harness) + check.sh rerun | 963/963 checks passed in 965 s at 08b5edf; check.sh now 'green (cached for this code tree, 963 tests)'; my subset 76/12/05/16/18/25: 52/52 | yes |

- **Discovery** (affects run): N2 is on origin main now (grep -c ...-N[12]$ = 2; 645d87e, in R2's HEAD): the R2/R1 plans' 'needs Michael' dependency line is stale
- **Discovery** (affects project): stub --resume of an unknown id substitutes session_id but leaves the fixture's 00000000-… id in the result line's errors[] (the real CLI names the asked id there)
- *145027-verify-R2 · claude-opus-5-5*

### 2026-10-29 14:50 · verify R2 · passes

All five R2 features hold: full suite green (963 tests), 76-entries-survive 18/18, journal and metrics subsets green, plan, review, decision, architecture and README present as the steps state.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| R2-01 | 1 | ls/grep docs/plans/2026-10-29-R2-entries.md sections | plan exists with entry check, trim, background, resume, stubs, check names | yes |
| R2-01 | 2 | grep resume section | resume section names flags, budget, row | yes |
| R2-01 | 3 | grep stub section | stub section lists behaviours | yes |
| R2-01 | 4 | grep dependency line; git log origin/main \| grep -c N[12] | dependency line states N2 absent at init (1); origin now shows 2, historical | yes |
| R2-01 | 5 | check.sh init run | green, 963 tests | yes |
| R2-02 | 1 | grep ENTRY_CHECK lib/prompt.sh prompts/*.md; tests/run.sh 76-entries | HARNESS_ENTRY_CHECK exported, three prompts render validate; PASS | yes |
| R2-02 | 2 | grep background prompts; check in 76 | background rule in all three; PASS | yes |
| R2-02 | 3 | tests/run.sh 12-journal (trim, maybe checks) | 12-journal 20/20 incl. 410-char trim to 400 with dead_ends, outcome maybe minimal | yes |
| R2-02 | 4 | tests/run.sh 76-entries (STUB_LONG_SUMMARY check) | 76 18/18 PASS incl. long summary note, no minimal | yes |
| R2-02 | 5 | bash -n; node --check; check-names | syntax ok; conformance in suite green | yes |
| R2-02 | 6 | init suite run | green | yes |
| R2-03 | 1 | tests/run.sh 76-entries | init line session id check PASS | yes |
| R2-03 | 2 | tests/run.sh 76-entries | unknown-id and cumulative cost checks PASS | yes |
| R2-03 | 3 | tests/run.sh 76-entries STUB_NO_ENTRY check | STUB_NO_ENTRY check PASS | yes |
| R2-03 | 4 | tests/run.sh 05-metrics | 05-metrics 7/7 PASS | yes |
| R2-03 | 5 | check-names; bash -n; node --check | syntax ok | yes |
| R2-03 | 6 | init suite | green | yes |
| R2-04 | 1 | cat prompts/entry-resume.md; grep lib/config.sh | file exists, defaults 8/10m/1 | yes |
| R2-04 | 2 | tests/run.sh 76-entries; read entry_resume checks | 18/18 PASS | yes |
| R2-04 | 3 | 76 rgood checks: resume.log, dead_ends, metrics row, summary count | PASS | yes |
| R2-04 | 4 | 76 rbad, rlimit, redits checks | PASS | yes |
| R2-04 | 5 | bash -n; suite | ok, green | yes |
| R2-05 | 1 | read docs/plans/2026-10-29-R2-review.md | 0 Critical, 3 Important fixed RED to GREEN | yes |
| R2-05 | 2 | read Simplifications table | table present | yes |
| R2-05 | 3 | read journal/decisions/2026-10-29-entries-survive.md rejected list | four rejected alternatives present | yes |
| R2-05 | 4 | grep architecture.md/README.md for trim and resume | §4/§5 and README describe trim, resume, entry-resume row | yes |
| R2-05 | 5 | init suite | green | yes |

- *144745-verify-R2 · claude-sonnet-5-5*

### 2026-10-29 14:32 · R1-04 · passes

The lanes flakes (44, 46, 48, and 45's also-seen) were one coordinator race in lib/driver.sh: a lane exiting between the lane count and the end check ended the run 'no feature left to try' with M2 ready. Fixed: the end check also needs alive == 0. Its own check in 45 forces the window (HARNESS_COUNT_HOLD=1, tests only). Decision file; plan table rows filled.

- **Files:** lib/driver.sh, bin/harness, tests/checks/45-lanes-run.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-29-lane-count-end-check.md, docs/plans/2026-10-29-R1-flakes.md, docs/architecture.md
- **Verified:** Before: '44-lanes-record: 10/10 green' (93 s; 16/16 at TEST_JOBS=8), '46-lanes-continue: 9/10 green' (copy 7: lc log 'M1 merged' · 'no feature left to try: 2/3 passing' · 'lane M1 closed'), '48-lanes-rebase: 10/10 green'. Forced pre-fix (HARNESS_COUNT_HOLD=1): 44 0/1 with 'fatal: Not a valid object name harness-lane/rec/M2', 46 0/1 (7 FAIL incl. pr-held), 48 0/1, 45 ld run ends early. After: '44-lanes-record: 10/10 green', '46-lanes-continue: 10/10 green', '48-lanes-rebase: 10/10 green', '45-lanes-run: 10/10 green', '47-lanes-two: 10/10 green'; forced 1/1 each. New check red before the fix, green after. check-names diff: added lines only. Suite: check: green in 813 s, 944 tests.
- **Tests:** 943 → 944
- **Dead end:** reproducing 44 by load alone (--repeat 10, then 16 copies at TEST_JOBS=8) — green every time; the window is a few lines wide, so it took a barrier (HARNESS_COUNT_HOLD) to land the exit in it
- **Discovery** (affects R1-05, R1-06, R1-07): HARNESS_COUNT_HOLD=1 (bin/harness passes it) holds the coordinator after its lane count until the lanes exit; logs 'count hold: …' in run.log. Use it to test whether a lanes flaker is the count/end race
- **Discovery** (affects R1-05): 28-run-14d-harness-merge (harness merge path) and 48's MERGE_POLICY=pr check ended early with the window forced before the fix; 28 may be this race too: try it forced first
- **Discovery** (affects R1-07): 47-lanes-two (admission at 80 %) was 10/10 green after the fix; its negative sleeps remain for R1-07 to list
- **Proposed change:** R1-07's README/architecture §7 pass could mention HARNESS_COUNT_HOLD beside HARNESS_RECORD_DELAY as the suite's driver-side test hooks
- *05-R1-04 · claude-opus-5-5*

### 2026-10-29 14:31 · resolve R2 · passes

CLAUDE.md Gotchas: lane reworded the stub-runs line and added the 399+… cut fact; main added the merge-driver %A and HARNESS_HOME facts. Kept the reword and both main facts. To stay at memlint's 15 (comment counts, as both sides meant), dropped the 399 line (R2's ingest trim covers it) and the end-reasons line (check 51 enforces it; it stored a count).

- **Files:** CLAUDE.md
- *142907-resolve-R2 · claude-opus-5-5*

### 2026-10-29 14:29 · R2-05 · passes

0 Critical, 3 Important, 8 Minor. One Opus round on R2.diff. Fixed RED→GREEN: a result-less resume's negative cost (resumeRow), a list an init's resume writes now removed, untested resume paths (stub good-overreach, STUB_INIT_NO_LIST, STUB_NO_INIT_LINE); 6 Minors fixed, 2 left. Decision entries-survive; architecture §4/§5, README.

- **Files:** docs/plans/2026-10-29-R2-review.md, journal/decisions/2026-10-29-entries-survive.md, docs/architecture.md, README.md, lib/metrics.mjs, lib/record.sh, lib/entries.mjs, lib/summary.mjs, lib/show.mjs, tests/stub-claude.sh, tests/checks/76-entries-survive.sh, tests/checks/05-metrics-pure-tokens-cache.sh, +4 more
- **Verified:** Each new check watched red first (05 result-less resume, 76 init list, 12 capwhy, 68 show label, 76 tokens on a kept run: 30 vs 28), then green; subsets 05/12/68/76 green; full check.sh twice: green, 915 tests, each after a rerun of load flakes in files R2 never touched (52, 28; then 08, 47, 28).
- **Tests:** 908 → 915
- **Dead end:** the resume setting A's passes to true in the stub — A's session had already passed, so cmp saw no change and no restore note; the stub toggles it
- **Dead end:** committing resumed.txt in the overreach mode — check redits greps git log --all for resumed.txt across every run of the file; the overreach mode commits overreach.txt
- **Discovery** (affects R2): A verify session's resume has no stub run of its own: entry_resume is the same path for verify, checked for coding and init only
- **Discovery** (affects run): Left by the review (Minor): the resume ignores a stop/lanes-end/deadline (bounded 10m, $1), and a refused resume is not fed to limit_raise
- **Proposed change:** R2-05 step 1's diff command leaves out docs/: fine for a code review, but the plan and docs are then reviewed by no one
- *04-R2-05 · claude-opus-5-5*

### 2026-10-29 13:33 · R1-03 · passes

tests/lint-sleeps.sh lists each sleep line lacking '# sleep-ok:' (default tests/checks/*.sh + tests/lib.sh; stubs exempt), 3 checks in 75-suite-tools. Swept 23 files: every counted poll and waitf copy is wait_for; orders wait on a trace; negatives, live pids and slow work keep a marked sleep. Merged origin/main and swept its new 75-78 too; Gotchas back to 15.

- **Files:** tests/lint-sleeps.sh, tests/lib.sh, tests/checks/75-suite-tools.sh, tests/fixtures/check-names.txt, tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh, tests/checks/13-run-2-michael-sets-desk.sh, tests/checks/15-run-4-same-but-queue-parked-debrief-tmux.sh, tests/checks/32-l5-queue-runner-re.sh, tests/checks/47-lanes-two.sh, tests/checks/48-lanes-rebase.sh, tests/checks/49-lanes-slots.sh, tests/checks/73-check-rerun.sh, +1 more
- **Verified:** the 3 lint checks watched failing (6/9 in 75-suite-tools before lint-sleeps.sh existed), then green; bash tests/lint-sleeps.sh on the tree: no output, rc 0 (on tests/stub-claude.sh: rc 1, so its exemption is the default's scope); bash tests/run.sh 08-scope: 125/125; 39-memlint: 19/19; full suite via lib/check.sh: green after a rerun, 943 tests (first pass: FAIL harness desk --list in 13, the same flake R2-02 saw before this sweep); git diff origin/main -- check-names.txt: added lines only; bash -n on every touched file; grep -c 'seq 20\|seq 150' tests/lib.sh = 0.
- **Tests:** 892 → 943
- **Dead end:** a python block editor where an empty replacement was an empty block — its regex ran across blocks and mangled 15 and 32 (restored with git checkout, redone)
- **Discovery** (affects R1-04, R1-05, R1-06, R1-07): wait_for <s> eval '<expr>' runs the expr in wait_for's frame: $1/$2 there are 'eval' and the expr; a helper copies its argument to a local first (gone, tended, tgone do)
- **Discovery** (affects R1-05, R1-07): settle no longer sleeps 0.5: its pgrep pattern also matches $HERE/../bin/harness debrief (the runner's H, before it execs $HH/lib/debrief.sh), so a debrief that hasn't exec'd yet counts as running
- **Discovery** (affects R1-06, R1-07): the negatives kept as '# sleep-ok: a negative over n polls' are 13:444, 32 (19,20,21,29,32,34), 45:39, 47 (38,51), 69:47 (after a wait_for on the runner's holding line); R1-06 decides whether 32's become counted-poll waits
- **Discovery** (affects R1-07, run): 13-run-2-michael-sets-desk 'harness desk --list' flakes under the full suite's load (R2-02 and R1-03 each saw it once, green on the rerun); not in the plan's flaker table
- **Discovery** (affects run): origin/main came with 16 Gotchas lines (memlint red on main itself); this lane dropped the end-reasons line when it merged main
- **Resolved:** the end-reasons check greps literal finish/END_REASON/lane_exit 13 reasons in lib/driver.sh and lib/lane.sh: a new one needs a line in end-reasons.txt (dropped from a full Gotchas section: the check's own failure names the fix)
- **Proposed change:** R1-03 step 4 should compare with the merge base (git diff origin/main...HEAD): origin/main moves while a lane works, and a plain diff then shows main's new names as removals
- *03-R1-03 · claude-opus-5-5*

### 2026-10-29 13:27 · R2-04 · passes

entry_resume (lib/record.sh), from journal before the ingest, outside the lock: a coding/verify/init session left with no valid entry and not refused is resumed once through session() (S_RESUME/S_TURNS/S_TIMEOUT/S_BUDGET); then list/INBOX restored, edits dropped, restrict, an entry-resume metrics row. prompts/entry-resume.md, config defaults; summary.mjs and metrics summary count it as cost only.

- **Files:** lib/record.sh, lib/config.sh, lib/prompt.sh, lib/summary.mjs, lib/metrics.mjs, prompts/entry-resume.md, tests/checks/76-entries-survive.sh, tests/checks/05-metrics-pure-tokens-cache.sh, tests/checks/25-run-13b-bs-entry.sh, tests/fixtures/check-names.txt
- **Verified:** 8 new checks: 7 in 76 (5 red before record.sh, the summary-count one red until summary.mjs; 14/14 after) and 1 in 05 (red on HEAD metrics.mjs); bash tests/run.sh 908/908; lib/check.sh on the final tree: green after a rerun (flaky: 32-l5-queue-runner-re, the named MAX_PARALLEL_RUNS check), 908 tests
- **Tests:** 900 → 908
- **Dead end:** a 16th Gotchas line (entry_resume resumes any unrefused session…) — memlint counts 15 already (grep '^- ' says 14): 39-memlint-m4 went red; dropped it
- **Discovery** (affects R2-05): entry_resume declares S_EXIT/S_WALL/S_PEAK/S_NOTES/S_UNIT local just before its session(): the callers' MET limit/append after journal still read the session's own figures
- **Discovery** (affects R2-05): Check 25 now greps 'B: entry.json still invalid (not JSON: .*) after one resume; recorded a minimal entry'. The PARKED and STUB_OOM stub paths are resumed too (note 'still missing after one resume'); no check was red on it, so the stub's PARKED paths still write no entry
- **Discovery** (affects R2-05): summary.mjs: entry-resume rows are out of `all` (sessions, per-feature counts, tokens, time) and in cost.total, by_role and by_model; metrics.mjs summary's session counts skip them, its cost and by-kind keep them
- **Discovery** (affects R2-05): The resume's restrict only runs when HEAD moved: otherwise its WIP commit would commit the initializer's entry.json into the record branch
- **Proposed change:** R2-05's review could weigh making the stub's two PARKED: paths write an outcome-parked entry, as a real session would, so stub runs stop resuming them
- *02-R2-04 · claude-opus-5-5*

### 2026-10-29 12:50 · R1-02 · passes

Attempt 2 of R1-02: the code from c319ca4 was right; the suite was red only on 39-memlint-m4, because the Gotchas line the first attempt added made 16 non-blank lines (the section's comment line counts). Dropped that line (its fact is now a run discovery). Every step re-checked.

- **Files:** CLAUDE.md
- **Verified:** node lib/memlint.mjs . prints nothing; tests/run.sh 75-suite memlint-m4: 25/25; check.sh green for this tree (892 tests); grep -c 'seq 20\|seq 150' tests/lib.sh = 0; bash -n on lib.sh/run.sh/stub-claude.sh; check-names.txt LC_ALL=C sorted
- **Tests:** 892 → 892
- **Dead end:** a 15th Gotchas bullet (attempt 1) — memlint counts every non-blank line under ## Gotchas, the <!-- --> comment too, so 14 bullets is the cap
- **Discovery** (affects run): ## Gotchas holds 14 bullets at most: memlint counts its <!-- --> comment line among the 15
- **Discovery** (affects R1-03, R1-04, R1-05, R1-06): settle (tests/lib.sh:83) pgreps debriefs box-wide and file 08's `sleep 31` too: a sibling check file or a --repeat copy matches them (R1-04..06 flakers)
- **Proposed change:** The coding prompt's '15 lines at most' should say the Gotchas comment counts, i.e. 14 bullets, or memlint should skip the comment line
- *01-R1-02 · claude-opus-5-5*

### 2026-10-29 10:48 · R2-03 · passes

Stub: each headless session prints first.jsonl's init line with a fresh session_id (kept in $STUB_DIR/sessions/<id>); --resume logs argv to resume.log, answers an unknown id as unknown-id.out (exit 1), a known one with resumed.jsonl and cumulative cost/modelUsage. STUB_NO_ENTRY, STUB_RESUME_ENTRY=good|bad|good-edits. metrics.mjs: sessionId, resumeRow, session-id, cost, append-resume. 7 checks.

- **Files:** tests/stub-claude.sh, lib/metrics.mjs, tests/checks/05-metrics-pure-tokens-cache.sh, tests/checks/76-entries-survive.sh, tests/fixtures/check-names.txt
- **Verified:** 7 new checks watched failing (5/12), then green; lib/check.sh: green after a rerun, 900 tests (899/900 first pass: 08 memory gate stop-during-wait, a 60s timing check on a box running 4x slow, green on rerun); manual stub runs: good/good-edits entries validate 0, bad 1, resumed.txt only for good-edits; chained resumes stay cumulative and append-resume on stub transcripts gives 2 in, 3 out, 15121 read, 11278 write
- **Tests:** 893 → 900
- **Discovery** (affects R2-04): Stub resume is the '# Entry resume' prompt plus --resume <id>; Feature:/Kind: lines under '# This session' give id and kind. The stub has metrics.mjs cost and append-resume <session> <resume> <metrics> <run> <feature> <model> <role> [wall exit peak lane] ready for entry_resume.
- **Discovery** (affects R2-04): 76's direct stub runs use STUB_DIR=$T/direct/stub, so $T/resume.log stays absent for R2-04's 'refused → no resume.log' check.
- **Discovery** (affects R2-04): A stub resume with no STUB_DIR, or of a session whose sessions/<id> file is empty (a refused one), starts from cost 0 and resumed.jsonl's model with zeroed tokens.
- *06-R2-03 · claude-opus-5-5*

### 2026-10-29 10:23 · R2-02 · passes

Entry check: prompt_env exports HARNESS_ENTRY_CHECK; the coding, verify and init prompts end by running it and forbid ending on background work. entries.mjs: onlyCaps, the header's own '<n> characters (at most 2000)', validate exit 2 on caps only; journalEntry cuts summary/header to 399+… and keeps the entry, ingest prints 'trimmed summary <n>', journal_ notes it. STUB_LONG_SUMMARY. 7 checks.

- **Files:** lib/entries.mjs, lib/prompt.sh, lib/record.sh, prompts/coding.md, prompts/verify.md, prompts/initializer.md, tests/stub-claude.sh, tests/checks/12-journal-pure-e4-entrys.sh, tests/checks/76-entries-survive.sh, tests/fixtures/check-names.txt
- **Verified:** Watched 6 of the 7 new checks fail first (the outcome-maybe one guards behaviour that already held); then bash tests/run.sh 12-journal 76-entries 25-run: 23/23; full suite via lib/check.sh: green after a rerun, 893 tests (the first run 892/893: FAIL harness desk --list in 13-run-2-michael-sets-desk, unrelated, green on the rerun); bash -n on prompt.sh record.sh stub-claude.sh, node --check entries.mjs.
- **Tests:** 886 → 893
- **Discovery** (affects R2-03, R2-04): 76-entries-survive.sh exists now with a STUB_LONG_SUMMARY run (run id longsum) whose state dir the prompt checks render from; R2-03/R2-04 append to it and must reset main between stub runs
- **Discovery** (affects R2-04): entries.mjs exports onlyCaps(errs) and validate's CLI exits 2 when only caps fail: entry_resume (R2-04) resumes only on exit 1, as the plan says
- **Resolved:** settle (tests/lib.sh:74, copy at 15:177) pgreps every debrief of this checkout and 08:239 pgreps `sleep 31` box-wide: another file or a --repeat copy matches them; a cross-file wait under load, first lead for 15 and 08
- **Proposed change:** R2-02 step 3 says 'the summary is 400 code points plus …'; built as the plan says (399 code points + …, 400 in all), since 401 fails validate and readEntries would drop the line. The step should read '400 code points in all, ending …'.
- *05-R2-02 · claude-opus-5-5*

### 2026-10-29 10:16 · R1-02 · passes

tests/lib.sh gains wait_for (clock-bounded 0.1 s poll), stub_wait/stub_go; in_has, settle's poll and ran run on wait_for. stub-claude.sh learns STUB_BARRIER=<id>:<name>. tests/run.sh --repeat <n> <name>… runs n fresh copies per file, prints <file>: k/n green and red copies' FAIL lines. Six checks in 75-suite-tools.sh, watched failing first.

- **Files:** tests/lib.sh, tests/run.sh, tests/stub-claude.sh, tests/checks/75-suite-tools.sh, tests/fixtures/check-names.txt, CLAUDE.md
- **Verified:** 75-suite-tools: 0/6 before the code, 6/6 after; bash tests/run.sh --repeat 3 17-run-8-thin-verify printed 3/3 green (15.6 s); --repeat x prints the usage, exit 2; full suite via check.sh green, 892 tests in 803 s (box loaded by the other lanes); grep -c 'seq 20\|seq 150' tests/lib.sh = 0; bash -n on the four shell files
- **Tests:** 886 → 892
- **Discovery** (affects R1-03): wait_for evals in its own frame: an eval'd condition sees the caller's locals (ran's s), so wait_for's locals are _wf_*; settle keeps its sleep 0.5 and the 15 copies of settle/ran stay for R1-03's sweep
- **Discovery** (affects R1-03): lib.sh's `seq 200` (status_stubs' long brief) matched step 1's grep; it is now {1..200}, same output
- **Discovery** (affects R1-04, R1-05, R1-06): --repeat keys each copy <file>.c<i> in run.sh's $out; it prints no per-copy PASS lines, only the per-file count, red copies' FAIL lines (copy <i>: …) and the wall time; KEEP=1 adds `copy <i> kept: <T>`
- **Proposed change:** The plan's STUB_BARRIER check (`suite tools: STUB_BARRIER holds that feature's first coding session until stub_go`) is in 75-suite-tools.sh though R1-02's steps don't name it; the step list could.
- *04-R1-02 · claude-opus-5-5*

### 2026-10-29 10:01 · R2-01 · passes

Attempt 1's plan (docs/plans/2026-10-29-R2-entries.md) holds every step; the suite was red only because its new Gotchas line made CLAUDE.md's ## Gotchas 16 lines, which 39-memlint-m4 fails. Dropped the narrowest line (brief.md move); memlint on the worktree prints nothing; full suite green, 886 tests.

- **Files:** CLAUDE.md
- **Verified:** node lib/memlint.mjs . prints nothing; tests/run.sh memlint 19/19; plan grepped for each step's names (HARNESS_ENTRY_CHECK, entry_resume, ENTRY_RESUME_*, .resume.jsonl, 0.0031/0.0055/0.0058, STUB_NO_ENTRY, STUB_RESUME_ENTRY, resume.log, 76-entries-survive, N2 line = 1); full suite via check.sh green in 648 s, 886 tests
- **Tests:** 886 → 886
- **Dead end:** attempt 1 adding a 16th Gotchas line — memlint caps ## Gotchas at 15 and the suite lints this worktree
- **Discovery** (affects run): 39-memlint-m4 lints this worktree's CLAUDE.md: a 16th Gotchas line turns the suite red; replace a line, never add past 15
- **Resolved:** the driver moves <state>/brief.md into the record's brief.md and empties it at start: a run's briefs are both files (agent-harness-2026-10-28 2026-10-28)
- *03-R2-01 · claude-opus-5-5*

### 2026-10-29 09:58 · R1-01 · passes

Wrote docs/plans/2026-10-29-R1-flakes.md: the four tools (wait_for, stub_wait/stub_go + STUB_BARRIER, the sleep lint, --repeat) with signatures, output and named checks in 75-suite-tools.sh; the flaker table (8 rows, cause not yet, 44's missing lane branch first) with code leads; all 96 sleep lines in 22 files marked poll/order/work/text.

- **Files:** docs/plans/2026-10-29-R1-flakes.md
- **Verified:** grep -c sleep tests/checks/*.sh tests/lib.sh: 22 files, 96 lines, each in the sweep table (marks tallied 29 poll + 16 order + 36 work + 15 text = 96); N2 grep on origin/main prints 1 (N1 only, e9fb31e); flaker names copied from tests/fixtures/check-names.txt; suite green, 886 checks (check.sh). Final tree equals the cached green tree (docs/plans is outside the key); memlint clean.
- **Tests:** 886 → 886
- **Dead end:** a 16th Gotchas line (pgrep -f is box-wide) — memlint caps Gotchas at 15 (39-memlint-m4 red); the fact stays in the plan and this entry
- **Discovery** (affects R1-05, R1-06, project): settle (tests/lib.sh:74, copy at 15:177) pgreps every debrief of this checkout and 08:239 pgreps `sleep 31` box-wide: another file or a --repeat copy matches them; a cross-file wait under load, first lead for 15 and 08
- **Discovery** (affects R1-02, R1-03): waitf is defined identically in 32, 47, 48, 49; settle and ran are copied in file 15 (175-178, 263): the sweep removes the copies, calls become wait_for <s> eval '<expr>'
- **Discovery** (affects R1-03, R1-06): seven sleeps are negatives (nothing happens over n polls: 13:444, 32:29/32/34, 45:39, 47:39/52); they wait for the actor's nth poll when it leaves a trace, else keep sleep-ok; 32's three are its likely flake
- **Discovery** (affects R1-04): 44's --base check needs harness-lane/rec/M2 on origin (C parks in M2): leads are sync_lane (record.sh:569), lane_branch_gone (527-538) and the slot sweep's never-pushed-litter rule (726)
- **Discovery** (affects run): N2 is not on origin main (1 of N1/N2 merged): an overlap conflict between lanes needs Michael
- **Discovery** (affects R1-04): this session's full suite (with a Gotchas line added) failed 47 `lanes admission: … 80 %` and 45 `lanes run: MAX_LANES=1 …` (two checks) under load; both green on the rerun: 45 and 47 flake today
- **Proposed change:** R1-02: add a check for STUB_BARRIER (the plan names it: `suite tools: STUB_BARRIER holds that feature's first coding session until stub_go`); the steps list none for it
- **Proposed change:** R1-04: 45-lanes-run and 47-lanes-two also flaked under load on 2026-10-29 (not in the spec's list); give each --repeat 10 if the budget allows, as the plan's Also seen says
- *01-R1-01 · claude-opus-5-5*

## Older entries (in full in progress-archive.md)

- 2026-10-29 09:19 · R2-01 · passes · Wrote docs/plans/2026-10-29-R2-entries.md: the entry check, the trim (399 + … so readEntries keeps i… ([in full](progress-archive.md))
- 2026-10-29 09:12 · init · passes · 23 features: R1 7 (plan, wait_for/barriers/--repeat, sleep lint, three flaker groups, review), R2 5 … ([in full](progress-archive.md))
