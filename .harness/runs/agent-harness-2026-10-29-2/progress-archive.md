<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-29-2` (agent-harness)

What this file is: the run's journal, rendered by the harness from `entries.jsonl` after every session, newest entry first. Each entry says what one session did, how it verified it, what it tried that failed, and what it asks Michael.

The spec is `docs/specs/2026-10-28-reliability.md`: R1 fixes the flaky checks at their cause (tests wait on conditions, `tests/run.sh --repeat` reproduces a flake), R2 keeps a session's entry (validator as the last step, a long summary trimmed, one resume for a missing entry), R3 closes the lanes-review leftovers and adds two lint rules, R4 gives questions a place to wait in `harness needs`. R1, R2 and R3 run side by side on two lanes; R4 waits for R2.

How to read the feature list (`feature_list.json`): array order is priority; `after` names what a feature really waits on; `passes` flips only when every step holds. Plans: `docs/plans/2026-10-29-R<n>-*.md`; reviews: `docs/plans/2026-10-29-R<n>-review.md`.

To steer: edit `INBOX.md` in this directory on branch `harness/agent-harness-2026-10-29-2` (first line `status: pause` or `status: stop`; answers under `## Answers`). The harness pulls before every session. Questions sessions asked are in `harness needs <run>` once R4 lands; until then in the entries below.

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

### 2026-10-29 09:19 · R2-01 · passes

Wrote docs/plans/2026-10-29-R2-entries.md: the entry check, the trim (399 + … so readEntries keeps it), the background rule, the resume (entry_resume in record.sh, decided before the ingest, outside the record lock, reusing session() with S_RESUME/S_TURNS/S_TIMEOUT/S_BUDGET), metrics resumeRow, the stubs, 76-entries-survive.sh's check names. N2 not on main.

- **Files:** docs/plans/2026-10-29-R2-entries.md, CLAUDE.md
- **Verified:** Each plan fact checked in code: ingest appends before exit 3; journal_ runs under record's flock; validate rejects a 401-char summary (node); metrics limit refuses the LIMIT_MIDWAY shape (rc 0); fixture costs and modelUsage by jq; N1/N2 grep = 1. Suite green, 886 (cached, plan-only tree).
- **Tests:** 886 → 886
- **Discovery** (affects R2-04): The resume must be decided before the ingest (ingest appends the minimal line before exit 3) and outside record's lock (journal_ holds it; a 10m resume would stall the other lane): entry_resume runs in journal(), not journal_.
- **Discovery** (affects R2-02): A trimmed summary of 400 + … (401) fails validate and readEntries drops it: cut to 399 + … as minimal() does.
- **Discovery** (affects R2-02): validate's header message is the same for a long string and a non-string; R2-02 gives a long one 'header: <n> characters (at most 2000)' and validate exits 2 when only caps fail.
- **Discovery** (affects R2-03, R2-04): summary.mjs counts unmatched metrics rows as sessions; entry-resume rows must be filtered out of sessions and kept in cost (summary.mjs and metrics.mjs summary).
- **Discovery** (affects R2-04): restrict commits a WIP first, so resumed.txt would be in history: drop the resume's uncommitted edits (checkout + clean outside .harness/runs) before restrict.
- **Discovery** (affects R2-04): Check 25 (STUB_BAD_ENTRY=B) gets resumed after R2-04; its note becomes 'still invalid (...) after one resume'. STUB_PARK/STUB_INBOX_IN_COMMENT write no entry and will be resumed too.
- **Proposed change:** R2-01 step 2 says the resume is called from journal_ after an ingest exit 3; the plan calls entry_resume from journal before the ingest on the same condition (validate exit 1, not refused), because the ingest has appended the minimal line by exit 3 and journal_ holds the record lock.
- **Proposed change:** R2-02 step 3 says the cut summary is '400 code points plus …' (401): readEntries would drop it; it should read '400 code points, … last' (399 + …).
- **Proposed change:** R2-03 needs two small CLI additions the steps don't name: metrics.mjs cost <transcript> (the resume's budget) and metrics.mjs append-resume (the row).
- *02-R2-01 · claude-opus-5-5*

### 2026-10-29 09:12 · init · passes

23 features: R1 7 (plan, wait_for/barriers/--repeat, sleep lint, three flaker groups, review), R2 5 (plan, entry check + trim, stub + metrics, the one resume, review), R3 6 (plan, features.mjs writes + two lint rules, merge/finish/test-count, suite-ran note + reviewer model, two lanes checks, review), R4 5 (plan, question items, ingest wiring, readers + skill, review). N1 merged, N2 not.

- **Files:** .harness/runs/agent-harness-2026-10-29-2/feature_list.json
- **Verified:** node lib/features.mjs lint on the list prints nothing (6 no-anchor findings fixed); jq parses it; 23 features, every passes false; milestones R1, R2, R3 first features after [], R4 after [R2].
- **Discovery** (affects run): N2 (conflict resolution) is not on origin main: N2-02 waits on Michael. Only N1 merged (grep -c harness-merge/...-N[12] = 1). A text conflict between two lanes needs Michael as before; each plan says so in one line.
- **Discovery** (affects R1): The flaker features (R1-04..06) run `bash tests/run.sh --repeat 10 <file>` directly in the session, never through the suite command: its CHECK_TIMEOUT is the whole suite's. One file's ten copies take minutes under load; the spec caps repeats at 30 min per flaker, then `not reproduced`.
- **Discovery** (affects R3): lib/entries.mjs already writes progress.md atomically (writeAtomic); R3-02's atomic writes concern lib/features.mjs only.
- **Discovery** (affects run): R2 and R3 both edit lib/record.sh and prompts/coding.md; R2-02 and R3-02 both edit prompts/initializer.md. Whichever merges second takes a re-base verify round; a text conflict needs Michael (no N2).
- *00-init · claude-fable-5-1*
