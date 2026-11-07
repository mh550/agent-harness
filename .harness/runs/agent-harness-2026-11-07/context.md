# Context pack for `S4-05`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (S4-04, affects S4-05): bin/harness is set -e, unlike lib/*.sh: was=$(node … exit 3) ends it silently (stop-records caught it); write x=$(…) || { (( $? == 3 )) && …; } → entries.jsonl:5
- Discovery (S4-04, affects S4-05, run): `harness queue add --continue` replacing a queued entry writes the format itself (printf in cmd_queue), raw: a multi-line option reads back as several arguments. A base-tree bug, left because this move changes no queue byte; asked below. → entries.jsonl:5
- Discovery (S4-04, affects S4-05): Node decodes argv and files as UTF-8, so a queue argument that isn't valid UTF-8 no longer keeps its bytes (U+FFFD); marked default in the decision file. → entries.jsonl:5
- Discovery (S4-04, affects S4-05): If node fails at the runner's decode, the entry goes to done/ with a failed start logged (mapfile from the file couldn't fail); recoverable by hand, no guard added. → entries.jsonl:5
- Discovery (S4-04, affects S4-05): String.replace in an edit script expands $' in the replacement text (it ate a check file once): use a function replacement when editing bash through node. → entries.jsonl:5
- Discovery (S4-03, affects S4-05): The plan said a failed verify's card takes the mode as variant; the bash's `a || b || c` stops at `a`, so the variant is empty in every mode. The bash won, the plan is corrected in place, and a unit test pins it. → entries.jsonl:4
- Discovery (S4-03, affects S4-05): Moves 2 and 3 barely shorten the bash (52 deleted, 51 added): each decision became a question plus a read of its labelled answer. S4-05's bash-removed row (150 or more) misses by more than S4-01's 90 to 110 gross estimate suggests if read net; say gross and net. → entries.jsonl:4
- Discovery (S4-03, affects S4-05): lane-done's answer is the one unlabelled line, `<code> <merge failed 0|1> <reason>`, taken whole: read would trim the space an empty need leaves in the exit file. → entries.jsonl:4
- Discovery (S4-02, affects S4-05): The helper's served set grew by checkdecide.mjs, beyond the plan's first list: with lane.mjs it will be thirteen scripts, not the twelve S4-05's architecture step says. → entries.jsonl:3
- Discovery (S4-02, affects S4-05): partialPlan's answer has no paths and guard's has no kind label: nothing in bash read them, so the plan's tables were corrected in place. → entries.jsonl:3
- Discovery (S4-01, affects S4-02, S4-05): Only literal-04 of S1's forty lies in an emptied function. In bash it was equivalent (any non-zero refuses), so partialPlan answers the refusing row and the mutant at its new home is row 8 to row 9, which the unit test must catch. → entries.jsonl:2
- Discovery (init, affects run): The milestone PR's body is composed by the harness (pr_body in lib/record.sh) from the features' descriptions and the verify entry: the brief's 'PR body for a reader with no source open' is met by the descriptions (written in that register) and by journal/decisions/2026-11-03-purity.md, which S4-05 writes the same way. → entries.jsonl:1
- Discovery (init, affects run): S1's forty mutants with their `before` line text are in findings-and-research/2026-11-03-suite-coverage/_mutants.jsonl (.id .file .line .before .after); the findings file's line numbers are the sample tree's, not today's: relocate a mutant by grep -F of its `before` text. → entries.jsonl:1
- Discovery (init, affects run): lib/check.sh, bin/harness and lib/queue.sh run outside a driver's or lane's shell, so no resident helper serves them: a pure function they call is one node spawn per call (check.sh already spawns treekey.mjs when no lane hands it the key); only lib/record.sh, lib/lane.sh and lib/driver.sh go through ask. → entries.jsonl:1
- Discovery (init, affects run): The S4 proof that no note text changed reads `note "` literals in the bash diff: a note's words moved into an .mjs would print as a removed note with no added twin. So every pure function answers a branch and its values, and every note string stays in bash (the plan feature's rule for the three builds). → entries.jsonl:1
- Discovery (init, affects run): Of the sampled mutants, three sat in lib/check.sh (andor-03, compare-08, literal-04; literal-04 survived before and lies in partial's row 8, which S4-02 moves, so it must be caught by the unit test after); none sat in lane_done, verify's verdict tail, reap, finish's maps, queue_add, entry_project, control or stop_why. → entries.jsonl:1

## What it builds on

- 2026-11-07 02:57 · S4-02 · passes: lib/check.sh's decisions moved to lib/checkdecide.mjs: redReason, cachedAnswer, partialPlan, rerunChoice, keepRed, failedNames. check.sh asks per moment by one decide() line; check_run hands the first answer through ask (served). All check: lines and notes unchanged. check.sh -72/+42; 65 unit tests, 1 check; literal-04 caught at its new home.; tests 1506 → 1572; files lib/checkdecide.mjs, lib/check.sh, lib/record.sh, lib/helper.mjs, tests/unit/checkdecide.test.mjs, … → entries.jsonl:3
- 2026-11-07 03:13 · S4-03 · passes: The lane's verify verdict and exit table, how a closed lane reads, and how a run ends are now pure functions in lib/lane.mjs, served by the helper and reached through ask. 80 unit tests. Notes, cards, exit and end reasons unchanged: both note proofs clean, 295 inputs compared old bash against new with no difference. lib/lane.sh and lib/driver.sh: 52 deleted, 51 added.; tests 1572 → 1652; files lib/lane.mjs, lib/lane.sh, lib/driver.sh, lib/helper.mjs, tests/unit/lane.test.mjs, … → entries.jsonl:4
- 2026-11-07 03:40 · S4-04 · passes: Queue format now in lib/queue.mjs (encode, decode, name, project, facts); status.mjs imports the decoder. INBOX status line now status, control, stopWhy, unstop in lib/inbox.mjs. Two push-downs moved. Notes unchanged: both proofs clean; 625 old-bash vs new-node comparisons, no difference. 57 new test names; fast tier 928/928.; tests 1652 → 1709; files lib/queue.mjs, lib/inbox.mjs, lib/status.mjs, lib/queue.sh, lib/spec.sh, … → entries.jsonl:5

## Current rules

- Supervised efforts for every project: one user-level skill, one dispatch list per effort, plain names throughout → journal/decisions/2026-11-05-supervised-efforts.md
- The suite's shape: check files named for what they test, no name part of another's, two cuts that need no replay, a tier on every line → journal/decisions/2026-11-05-suite-shape.md
- A merge survives an origin outage: bounded retries, a card past them, a tag that isn't claimed, gc holds verified work → journal/decisions/2026-11-04-origin-retries.md
- No run ends on a clock unless asked to: `HOURS` defaults to none, and the night leaves the docs → journal/decisions/2026-11-04-no-default-end-time.md
- A red verify opens a fix round, not a card: at most `MAX_FIX_ROUNDS` per milestone, each one counted → journal/decisions/2026-11-04-fix-rounds.md
- The unit tier: node evals become `node:test` files in one process, reported as the suite's PASS/FAIL lines → journal/decisions/2026-11-03-unit-tier.md
- The trim: 22 checks removed, each with the check that makes its assertions now; five gaps closed; no covered line lost → journal/decisions/2026-11-03-trim.md
- The suite's tiers: every check file declares `fast` or `slow` on line 2, and `tests/run.sh --tier` runs one tier → journal/decisions/2026-11-03-suite-tiers.md
- The trace switch: `HARNESS_XTRACE=<dir>` traces every harness process, off unless set → journal/decisions/2026-11-03-suite-coverage.md
- The resident helper: one warm node process per driver and lane answers the `.mjs` questions over a coproc → journal/decisions/2026-11-03-resident-helper.md

_87 older rules: journal/decisions._
