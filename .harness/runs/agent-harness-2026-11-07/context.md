# Context pack for `S4-04`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (S4-01, affects S4-03, S4-04): The second note proof compares from note " to the END of the line, so a line holding a note keeps its trailing code byte for byte: the three end-block lines keep ends+=(…), so runEnd answers lists and bash still builds the reason. → entries.jsonl:2
- Discovery (S4-01, affects S4-04): spec_entry in lib/spec.sh is a fifth queue decoder the feature list doesn't name; the plan moves it with S4-04 (default). No check holds a 0x1f byte today: grep -rl x1f tests/checks tests/unit prints nothing. → entries.jsonl:2
- Discovery (S4-01, affects S4-02, S4-03, S4-04): bash read fails at end of file on a last line with no newline, so closedLane must answer 'lane exited unexpectedly' for an exit file with no final newline; rule 4 of the plan lists the others (read's trim, [[:space:]] against \s, [[:alnum:]], ${w:0:200}). → entries.jsonl:2
- Discovery (init, affects run): The milestone PR's body is composed by the harness (pr_body in lib/record.sh) from the features' descriptions and the verify entry: the brief's 'PR body for a reader with no source open' is met by the descriptions (written in that register) and by journal/decisions/2026-11-03-purity.md, which S4-05 writes the same way. → entries.jsonl:1
- Discovery (init, affects run): S1's forty mutants with their `before` line text are in findings-and-research/2026-11-03-suite-coverage/_mutants.jsonl (.id .file .line .before .after); the findings file's line numbers are the sample tree's, not today's: relocate a mutant by grep -F of its `before` text. → entries.jsonl:1
- Discovery (init, affects run): lib/check.sh, bin/harness and lib/queue.sh run outside a driver's or lane's shell, so no resident helper serves them: a pure function they call is one node spawn per call (check.sh already spawns treekey.mjs when no lane hands it the key); only lib/record.sh, lib/lane.sh and lib/driver.sh go through ask. → entries.jsonl:1
- Discovery (init, affects run): The S4 proof that no note text changed reads `note "` literals in the bash diff: a note's words moved into an .mjs would print as a removed note with no added twin. So every pure function answers a branch and its values, and every note string stays in bash (the plan feature's rule for the three builds). → entries.jsonl:1
- Discovery (init, affects run): Of the sampled mutants, three sat in lib/check.sh (andor-03, compare-08, literal-04; literal-04 survived before and lies in partial's row 8, which S4-02 moves, so it must be caught by the unit test after); none sat in lane_done, verify's verdict tail, reap, finish's maps, queue_add, entry_project, control or stop_why. → entries.jsonl:1

## What it builds on

- 2026-11-07 02:44 · S4-01 · passes: The plan of the purity moves (docs/plans/2026-11-07-S4-purity.md) and the decision file's skeleton (journal/decisions/2026-11-03-purity.md): three builds, each function's inputs, answer and branches, the note rule, the one mutant moved (literal-04), two push-downs, and the Decision 16 (b) table: 4 stub start lines of 65 read could go; none is removed.; tests 1506 → 1506; files docs/plans/2026-11-07-S4-purity.md, journal/decisions/2026-11-03-purity.md → entries.jsonl:2

## Lately in the run

- 2026-11-07 03:13 · S4-03 · passes: The lane's verify verdict and exit table, how a closed lane reads, and how a run ends are now pure functions in lib/lane.mjs, served by the helper and reached through ask. 80 unit tests. Notes, cards, exit and end reasons unchanged: both note proofs clean, 295 inputs compared old bash against new with no difference. lib/lane.sh and lib/driver.sh: 52 deleted, 51 added.; tests 1572 → 1652; files lib/lane.mjs, lib/lane.sh, lib/driver.sh, lib/helper.mjs, tests/unit/lane.test.mjs, … → entries.jsonl:4
- 2026-11-07 02:57 · S4-02 · passes: lib/check.sh's decisions moved to lib/checkdecide.mjs: redReason, cachedAnswer, partialPlan, rerunChoice, keepRed, failedNames. check.sh asks per moment by one decide() line; check_run hands the first answer through ask (served). All check: lines and notes unchanged. check.sh -72/+42; 65 unit tests, 1 check; literal-04 caught at its new home.; tests 1506 → 1572; files lib/checkdecide.mjs, lib/check.sh, lib/record.sh, lib/helper.mjs, tests/unit/checkdecide.test.mjs, … → entries.jsonl:3

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
- The purity moves: the bash decision tables become pure functions with a unit test per branch; no note text changes → journal/decisions/2026-11-03-purity.md
- The fast gate: `check.sh --fast` runs the fast tier, marks `fast-<key>`, and a fast-green is never read as a green → journal/decisions/2026-11-03-fast-gate.md

_85 older rules: journal/decisions._
