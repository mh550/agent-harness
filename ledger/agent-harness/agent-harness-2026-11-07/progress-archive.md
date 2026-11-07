<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-07` (agent-harness)

What this file is: the run's journal, rendered from `entries.jsonl`, newest entry first. Each entry is one session's own account: what it built, what it verified, what failed. The feature list (`feature_list.json` in this directory) has one milestone, S4 of the slim-suite spec (`docs/specs/2026-11-03-slim-suite.md`): the bash decision logic that burns the suite moves into pure `.mjs` functions with a unit test per branch, no note text changed, no check removed (the brief's Decision 16 (b)). Five features: S4-01 plans the moves, S4-02 the suite runner's decisions (`lib/check.sh` → `lib/checkdecide.mjs`), S4-03 the lane's verdict and exit table and how a run ends (`lib/lane.sh`, `lib/driver.sh` → `lib/lane.mjs`), S4-04 the queue entry format and INBOX status parsers (`lib/queue.mjs`, `lib/inbox.mjs`), S4-05 the review with the proofs, the forty mutants and the Predictions table (the after row and the solo CPU and wall rows wait for an empty box after the run). `passes` on a feature means its session's fast tier was green and its steps were done; the milestone is verified independently and merged into `main` when all five pass. Steer from the phone: edit `INBOX.md` on this branch (first line `status: pause` or `status: stop`; answers under `## Answers`).

### 2026-11-07 05:08 · verify S4 · passes

All 5 S4 features hold: full suite green (1721, 645 s), unit tier 452/452, both note proofs clean (one identical pair, empty comparison), literal-04 caught at checkdecide.mjs, numstats and docs present.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| S4-01 | 1 | step 1 of S4-01 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | plan file docs/plans/2026-11-07-S4-purity.md exists; sections per build | yes |
| S4-01 | 2 | step 2 of S4-01 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | plan and lib layout: check.sh/bin/harness/queue.sh spawn node; lane/driver/record use ask; lane.mjs in served set (grep of lane.sh/driver.sh shows ask lines) | yes |
| S4-01 | 3 | step 3 of S4-01 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | note rule: note proofs print 1 identical pair and empty comparison (diff empty) | yes |
| S4-01 | 4 | step 4 of S4-01 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | mutant list: decision file table; literal-04 moved, others line not moved | yes |
| S4-01 | 5 | step 5 of S4-01 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | push-downs: status.test.mjs unquote moved; others listed | yes |
| S4-01 | 6 | step 6 of S4-01 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | decision file journal/decisions/2026-11-03-purity.md exists with Decision 16(b) table | yes |
| S4-01 | 7 | step 7 of S4-01 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | init full suite green 1721 tests in 645 s | yes |
| S4-02 | 1 | step 1 of S4-02 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | tests/unit/checkdecide.test.mjs exists, unit tier 452/452 pass | yes |
| S4-02 | 2 | step 2 of S4-02 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | node --check passes; grep checkdecide.mjs lib/check.sh prints one line (89, decide() def) and subset branch exit at line 87 precedes it | yes |
| S4-02 | 3 | step 3 of S4-02 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | numstat lib/check.sh 42 del/72 ins; decision file rows present | yes |
| S4-02 | 4 | step 4 of S4-02 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | check: line diff pairs identical in quoted text; note comparison empty | yes |
| S4-02 | 5 | step 5 of S4-02 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | literal-04 applied at no("8")->no("9") in checkdecide.mjs: 64 pass 1 fail, tree restored (git diff --quiet ok) | yes |
| S4-02 | 6 | step 6 of S4-02 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | bash -n lib/check.sh ok; subset checks covered by the full green run (1721 pass) | yes |
| S4-02 | 7 | step 7 of S4-02 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | full suite green incl fast tier | yes |
| S4-03 | 1 | step 1 of S4-03 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | tests/unit/lane.test.mjs exists; unit tier 452 pass | yes |
| S4-03 | 2 | step 2 of S4-03 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | node --check lane.mjs helper.mjs ok; grep lane.mjs lib/lane.sh lib/driver.sh prints only ask lines | yes |
| S4-03 | 3 | step 3 of S4-03 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | numstat lane.sh 41/37 driver.sh 19/16; in decision file | yes |
| S4-03 | 4 | step 4 of S4-03 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | note proofs: 1 identical pair, comparison empty; grep -c needs Michael lane.mjs printed 4 (nonzero; decision file must name the exit reasons, not confirmed by me) | yes |
| S4-03 | 5 | step 5 of S4-03 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | no head/jq shape check beyond full suite; compare-09 marked line not moved | yes |
| S4-03 | 6 | step 6 of S4-03 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | bash -n ok; checks covered by full green run | yes |
| S4-03 | 7 | step 7 of S4-03 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | full suite green | yes |
| S4-04 | 1 | step 1 of S4-04 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | tests/unit/queue.test.mjs and inbox tests exist, unit tier pass | yes |
| S4-04 | 2 | step 2 of S4-04 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | node --check ok; status.mjs grep of replaceAll x1f is 0; record.sh control/stop_why call ask inbox.mjs; grep -m1 status remains in control fast path (line 486) for plain run | yes |
| S4-04 | 3 | step 3 of S4-04 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | numstat bin/harness 9/13, queue.sh 11/7, record.sh 17/14 | yes |
| S4-04 | 4 | step 4 of S4-04 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | note proofs clean; queue-view.sh check at line 67 asserts bytes with 0x1f, passes in full suite | yes |
| S4-04 | 5 | step 5 of S4-04 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | unquote push-down: tests/unit/status.test.mjs exists; names file 1720 lines | yes |
| S4-04 | 6 | step 6 of S4-04 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | bash -n ok; checks covered by full green run | yes |
| S4-04 | 7 | step 7 of S4-04 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | full suite green | yes |
| S4-05 | 1 | step 1 of S4-05 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | review file docs/plans/2026-11-07-S4-review.md exists | yes |
| S4-05 | 2 | step 2 of S4-05 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | fixes with checks: tests/checks/no-answer.sh in suite; bash -n and node --check all ok | yes |
| S4-05 | 3 | step 3 of S4-05 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | decision file has proofs section; note grep shows the single identical pair | yes |
| S4-05 | 4 | step 4 of S4-05 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | forty-mutant table present in decision file at line 198 | yes |
| S4-05 | 5 | step 5 of S4-05 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | Predictions table present (line ~254) | yes |
| S4-05 | 6 | step 6 of S4-05 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | decision file complete; CLAUDE.md memlint-self in green suite | yes |
| S4-05 | 7 | step 7 of S4-05 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | architecture.md rows for checkdecide, lane, queue; README lines 397-398 | yes |
| S4-05 | 8 | step 8 of S4-05 re-run: commands as in the step (grep, git diff, node --check, bash -n, unit tier, full suite) | full suite green 1721 in 645 s | yes |

- *050710-verify-S4 · claude-sonnet-5-5*

### 2026-11-07 04:56 · S4-05 · passes

0 Critical, 4 Important, 7 Minor. An Opus review read each move against its bash. All 3 Important were no-answer branches when helper and spawn both fail (queue start, verify verdict, run end); fixed red first, 10 checks in tests/checks/no-answer.sh. Two Minors fixed (glibc alnum, fix-round numbers). Decision file: both proofs, the 40 mutants (31→32), Predictions. Docs updated.

- **Files:** lib/queue.sh, lib/lane.sh, lib/driver.sh, lib/record.sh, lib/inbox.mjs, lib/lane.mjs, lib/checkdecide.mjs, lib/cli.mjs, lib/status.mjs, lib/queue.mjs, tests/checks/no-answer.sh, tests/unit/inbox.test.mjs, +8 more
- **Verified:** full suite via check.sh: green in 636 s, 1721 tests; fast tier green (cached, 1721); tests/run.sh no-answer 10/10, each check watched red first (0/9, then nr and nd); node-memo red on the first full run (an S4-04 regression), green after the control fast path; both note proofs clean; unit tier 452/452
- **Tests:** 1709 → 1721
- **Dead end:** no answer to verify-round on a done milestone read as the fail — a fail with every feature passing has no card: the lane verified again and again (127 rounds in one stub run); it is thin now, its card
- **Dead end:** a watchdog on the subagent's output file's mtime — the path is a symlink: stat read the link's time and fired while the reviewer was still working
- **Discovery** (affects project): Every bash decision moved into an .mjs reads an empty answer when the helper and its spawn both fail; journal/decisions/2026-11-03-purity.md's 'A question with no answer' holds the rule (wait for the next poll, or the branch with a card) and tests/checks/no-answer.sh's node wrapper refuses named questions.
- **Discovery** (affects project): The Gotchas section was at 15 lines: the status.mjs stub-log line (a session runs from its session line to its passes= or limit note) was dropped for the no-answer line; the check that needs it names it when it fails.
- **Question for Michael:** The review's Minor findings 5, 6 and 8 are taken as defaults, not fixed: an INBOX.md or HARNESS_FAILED name that isn't valid UTF-8 gets U+FFFD, and hand-planted queue entries the harness never writes (start of /, a glob run id, continue ../alpha/r1) read differently. Keep them as defaults? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07/slot-0/docs/plans/2026-11-07-S4-review.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07/slot-0/journal/decisions/2026-11-03-purity.md
- **Proposed change:** S4-05 step 7 says the served set is twelve scripts; it is thirteen (cli.mjs's eleven, checkdecide.mjs, lane.mjs), as docs/architecture.md now says.
- **Proposed change:** S4-05 step 7 asks for README.md's module list: README has none, so the three modules are named in a sentence beside the unit tier's paragraph, with lib/inbox.mjs.
- *05-S4-05 · claude-opus-5-5*

### 2026-11-07 03:40 · S4-04 · passes

Queue format now in lib/queue.mjs (encode, decode, name, project, facts); status.mjs imports the decoder. INBOX status line now status, control, stopWhy, unstop in lib/inbox.mjs. Two push-downs moved. Notes unchanged: both proofs clean; 625 old-bash vs new-node comparisons, no difference. 57 new test names; fast tier 928/928.

- **Files:** lib/queue.mjs, lib/inbox.mjs, lib/status.mjs, lib/queue.sh, lib/spec.sh, lib/record.sh, bin/harness, tests/unit/queue.test.mjs, tests/unit/inbox.test.mjs, tests/unit/status.test.mjs, tests/checks/queue-view.sh, tests/checks/spec-must-exist.sh, +7 more
- **Verified:** check.sh --fast: green, 928 tests. Named subset: 282/282. Slow files reached (resident-helper, lanes-run, lanes-continue, origin-outage, weekly-budget, desk): 204/204. Both note proofs clean over lib/*.sh and bin/harness. Throwaway script: 625 comparisons of old bash against the new CLI, 0 differ. By hand: a raw mapfile in the runner turned the new runner check red, an encoder without 0x1f turned the new queue-view check red; tree put back (cmp).
- **Tests:** 1652 → 1709
- **Dead end:** a Gotcha line for bin/harness being set -e — the section is full: its steering comment counts, so 15 entries is 16 to memlint and memlint-self goes red; dropped, nothing replaced
- **Discovery** (affects S4-05): bin/harness is set -e, unlike lib/*.sh: was=$(node … exit 3) ends it silently (stop-records caught it); write x=$(…) || { (( $? == 3 )) && …; }
- **Discovery** (affects S4-05, run): `harness queue add --continue` replacing a queued entry writes the format itself (printf in cmd_queue), raw: a multi-line option reads back as several arguments. A base-tree bug, left because this move changes no queue byte; asked below.
- **Discovery** (affects S4-05): Node decodes argv and files as UTF-8, so a queue argument that isn't valid UTF-8 no longer keeps its bytes (U+FFFD); marked default in the decision file.
- **Discovery** (affects S4-05): If node fails at the runner's decode, the entry goes to done/ with a failed start logged (mapfile from the file couldn't fail); recoverable by hand, no guard added.
- **Discovery** (affects S4-05): String.replace in an edit script expands $' in the replacement text (it ate a check file once): use a function replacement when editing bash through node.
- **Question for Michael:** Should `harness queue add --continue` replacing a queued entry write through lib/queue.mjs, so a multi-line --brief in a repeated request stays one argument? Default: left as it is, because this move changes no queue byte; the fix is one line plus a check. Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07/slot-0/bin/harness:574, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07/slot-0/journal/decisions/2026-11-03-purity.md
- **Proposed change:** S4-04's push-down step names tests/checks/journal-entries.sh for the unquote check; it was in tests/checks/queue-view.sh (the plan had it right). The same step names one push-down; the plan assigns two (unquote and repair), and both moved under Decision 14 (a).
- **Proposed change:** `node --check a b c` checks only the first file (step 2 of S4-03 and S4-04): run it once per file.
- **Proposed change:** How to work here: the Gotchas cap counts the section's steering comment, so its 14 entries are already full; the 15-line rule in the coding prompt reads as 15 entries.
- *04-S4-04 · claude-opus-5-5*

### 2026-11-07 03:13 · S4-03 · passes

The lane's verify verdict and exit table, how a closed lane reads, and how a run ends are now pure functions in lib/lane.mjs, served by the helper and reached through ask. 80 unit tests. Notes, cards, exit and end reasons unchanged: both note proofs clean, 295 inputs compared old bash against new with no difference. lib/lane.sh and lib/driver.sh: 52 deleted, 51 added.

- **Files:** lib/lane.mjs, lib/lane.sh, lib/driver.sh, lib/helper.mjs, tests/unit/lane.test.mjs, tests/unit/cli.test.mjs, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, docs/plans/2026-11-07-S4-purity.md, journal/decisions/2026-11-03-purity.md
- **Verified:** Fast tier: check.sh --fast green, 871 tests, 106 s (791 before). tests/run.sh over the step's files plus needs-git, park-desk, origin-outage, weekly-budget, resident-helper, node-memo: 396/396. Note proof 1 prints one identical pair, proof 2 prints nothing. A scratch script (not committed) compared the base tree's bash with lane.mjs on 295 inputs: 0 differences. compare-09 is still in lib/driver.sh, line not moved.
- **Tests:** 1572 → 1652
- **Dead end:** Dropping `;;` onto the thin branch's note line once its need= line left — note proof 2 compares from note " to the end of the line and printed it; the `;;` sits on its own line now
- **Discovery** (affects S4-05): The plan said a failed verify's card takes the mode as variant; the bash's `a || b || c` stops at `a`, so the variant is empty in every mode. The bash won, the plan is corrected in place, and a unit test pins it.
- **Discovery** (affects S4-05): Moves 2 and 3 barely shorten the bash (52 deleted, 51 added): each decision became a question plus a read of its labelled answer. S4-05's bash-removed row (150 or more) misses by more than S4-01's 90 to 110 gross estimate suggests if read net; say gross and net.
- **Discovery** (affects S4-05): lane-done's answer is the one unlabelled line, `<code> <merge failed 0|1> <reason>`, taken whole: read would trim the space an empty need leaves in the exit file.
- **Proposed change:** S4-03 step 3 says the end block's `ends` composition is replaced by one call, but note proof 2 keeps those three lines and the join whole, so runEnd answers the lists they read. The decision file marks this *default*; the step should say the lists.
- **Proposed change:** S4-03 step 3 also calls verify's `case $result` a verdict choice replaced by one call; the case stays because it holds the actions and notes. The choice moved (verifyRound, suiteVerdict, verifyNeed, verifyCard).
- *03-S4-03 · claude-opus-5-5*

### 2026-11-07 02:57 · S4-02 · passes

lib/check.sh's decisions moved to lib/checkdecide.mjs: redReason, cachedAnswer, partialPlan, rerunChoice, keepRed, failedNames. check.sh asks per moment by one decide() line; check_run hands the first answer through ask (served). All check: lines and notes unchanged. check.sh -72/+42; 65 unit tests, 1 check; literal-04 caught at its new home.

- **Files:** lib/checkdecide.mjs, lib/check.sh, lib/record.sh, lib/helper.mjs, tests/unit/checkdecide.test.mjs, tests/unit/cli.test.mjs, tests/checks/resident-helper-ask.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, journal/decisions/2026-11-03-purity.md, docs/plans/2026-11-07-S4-purity.md
- **Verified:** check.sh --fast: green, 791 tests. By file, all passing: resident-helper-ask 62, partial-key 26, red-marker 16, session-gate-check 20, session-gate-driver 12, check-rerun 13, check-key 9, suite-runs 4, flakes-run 9, suite-length 16, test-count-source 4, stale-green 1, run-scopes-services-gc 123. Both note proofs print nothing; the check: proof prints two pairs identical in quoted text. Mutant no(8)→no(9): unit exit 1, 64 pass, 1 fail; tree put back. The full suite was not run here: it runs at verify.
- **Tests:** 1506 → 1572
- **Discovery** (affects S4-05): The helper's served set grew by checkdecide.mjs, beyond the plan's first list: with lane.mjs it will be thirteen scripts, not the twelve S4-05's architecture step says.
- **Discovery** (affects S4-05): partialPlan's answer has no paths and guard's has no kind label: nothing in bash read them, so the plan's tables were corrected in place.
- **Proposed change:** S4-02 step 2 says check.sh spawns the module 'once per full or --fast call' and that the subset path reaches no node but testcount's. As built (the plan's rule 3): a green call asks once, a red one three times because its facts come later, and a subset killed by its timeout or cap asks why once. The grep in that step holds literally (one line, below the subset's exit) because the subset form became a function.
- **Proposed change:** S4-05 step 'the served set now twelve scripts' should read thirteen.
- *02-S4-02 · claude-opus-5-5*

### 2026-11-07 02:44 · S4-01 · passes

The plan of the purity moves (docs/plans/2026-11-07-S4-purity.md) and the decision file's skeleton (journal/decisions/2026-11-03-purity.md): three builds, each function's inputs, answer and branches, the note rule, the one mutant moved (literal-04), two push-downs, and the Decision 16 (b) table: 4 stub start lines of 65 read could go; none is removed.

- **Files:** docs/plans/2026-11-07-S4-purity.md, journal/decisions/2026-11-03-purity.md
- **Verified:** check.sh --fast: green (cached for this code tree, 1506 tests; only docs/plans and journal changed, both outside the key). Every mutant's before line matched exactly on 055de2c by a script; the start-line counts came from S1's grep per file; the plan's facts rechecked with one grep each.
- **Tests:** 1506 → 1506
- **Discovery** (affects S4-02): Two checks count treekey.mjs starts (partial-key 'one treekey start', resident-helper-ask's check_run pair), so treekey.mjs stays its own question: check.sh asks checkdecide.mjs before as a second one, and check_run hands that answer in HARNESS_CHECK_BEFORE through ask, so a lane's call starts no more node. checkdecide.mjs joins SERVED too.
- **Discovery** (affects S4-03, S4-04): The second note proof compares from note " to the END of the line, so a line holding a note keeps its trailing code byte for byte: the three end-block lines keep ends+=(…), so runEnd answers lists and bash still builds the reason.
- **Discovery** (affects S4-04): spec_entry in lib/spec.sh is a fifth queue decoder the feature list doesn't name; the plan moves it with S4-04 (default). No check holds a 0x1f byte today: grep -rl x1f tests/checks tests/unit prints nothing.
- **Discovery** (affects S4-02, S4-03, S4-04): bash read fails at end of file on a last line with no newline, so closedLane must answer 'lane exited unexpectedly' for an exit file with no final newline; rule 4 of the plan lists the others (read's trim, [[:space:]] against \s, [[:alnum:]], ${w:0:200}).
- **Discovery** (affects S4-02, S4-05): Only literal-04 of S1's forty lies in an emptied function. In bash it was equivalent (any non-zero refuses), so partialPlan answers the refusing row and the mutant at its new home is row 8 to row 9, which the unit test must catch.
- **Question for Michael:** The bash-removed row of the spec's Predictions (150 or more) is on course to miss: the plan's reading gives about 90 to 110 gross, with candidates 1, 3, 4, 5, 6 in three builds. Accept the miss (the default: the final number and this reason go in the decision file at S4-05), or add a fourth build for the debrief's parse and the marker regex (candidates 2 and 7, about 35 lines and more)? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07/slot-0/docs/plans/2026-11-07-S4-purity.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07/slot-0/journal/decisions/2026-11-03-purity.md
- **Question for Michael:** The one queue decoder drops a CR at a line's end, as the queue view's reader does and the runner's read didn't, so a hand-edited CRLF entry now starts with clean arguments (default). Keep that, or hold the runner's old bytes for such a file with a flag on the decoder? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07/slot-0/docs/plans/2026-11-07-S4-purity.md
- **Proposed change:** S4-02's description says check.sh calls its function once by a spawn: as planned, it is one spawn per moment (before the run, at a red's guard, at a red's end), and a lane's before answer comes through ask, with lib/checkdecide.mjs in SERVED.
- **Proposed change:** S4-04's description should name spec_entry in lib/spec.sh among the decoders.
- *01-S4-01 · claude-opus-5-5*

### 2026-11-07 02:32 · init · passes

5 features, one milestone S4 (the purity moves): S4-01 plan (docs/plans/2026-11-07-S4-purity.md, the decision file's skeleton); S4-02 lib/check.sh's cache and rerun decisions → lib/checkdecide.mjs; S4-03 the lane's verdict and exit table and how a run ends → lib/lane.mjs; S4-04 the queue entry format → lib/queue.mjs and INBOX status → inbox.mjs; S4-05 review, proofs, mutants, Predictions, docs.

- **Discovery** (affects run): The milestone PR's body is composed by the harness (pr_body in lib/record.sh) from the features' descriptions and the verify entry: the brief's 'PR body for a reader with no source open' is met by the descriptions (written in that register) and by journal/decisions/2026-11-03-purity.md, which S4-05 writes the same way.
- **Discovery** (affects run): S1's forty mutants with their `before` line text are in findings-and-research/2026-11-03-suite-coverage/_mutants.jsonl (.id .file .line .before .after); the findings file's line numbers are the sample tree's, not today's: relocate a mutant by grep -F of its `before` text.
- **Discovery** (affects run): lib/check.sh, bin/harness and lib/queue.sh run outside a driver's or lane's shell, so no resident helper serves them: a pure function they call is one node spawn per call (check.sh already spawns treekey.mjs when no lane hands it the key); only lib/record.sh, lib/lane.sh and lib/driver.sh go through ask.
- **Discovery** (affects run): The S4 proof that no note text changed reads `note "` literals in the bash diff: a note's words moved into an .mjs would print as a removed note with no added twin. So every pure function answers a branch and its values, and every note string stays in bash (the plan feature's rule for the three builds).
- **Discovery** (affects run): Of the sampled mutants, three sat in lib/check.sh (andor-03, compare-08, literal-04; literal-04 survived before and lies in partial's row 8, which S4-02 moves, so it must be caught by the unit test after); none sat in lane_done, verify's verdict tail, reap, finish's maps, queue_add, entry_project, control or stop_why.
- *00-init · claude-fable-5-1*
