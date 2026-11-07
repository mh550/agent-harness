# Context pack for `S4-02`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (S4-01, affects S4-02): Two checks count treekey.mjs starts (partial-key 'one treekey start', resident-helper-ask's check_run pair), so treekey.mjs stays its own question: check.sh asks checkdecide.mjs before as a second one, and check_run hands that answer in HARNESS_CHECK_BEFORE through ask, so a lane's call starts no more node. checkdecide.mjs joins SERVED too. → entries.jsonl:2
- Discovery (S4-01, affects S4-02, S4-03, S4-04): bash read fails at end of file on a last line with no newline, so closedLane must answer 'lane exited unexpectedly' for an exit file with no final newline; rule 4 of the plan lists the others (read's trim, [[:space:]] against \s, [[:alnum:]], ${w:0:200}). → entries.jsonl:2
- Discovery (S4-01, affects S4-02, S4-05): Only literal-04 of S1's forty lies in an emptied function. In bash it was equivalent (any non-zero refuses), so partialPlan answers the refusing row and the mutant at its new home is row 8 to row 9, which the unit test must catch. → entries.jsonl:2
- Discovery (init, affects run): The milestone PR's body is composed by the harness (pr_body in lib/record.sh) from the features' descriptions and the verify entry: the brief's 'PR body for a reader with no source open' is met by the descriptions (written in that register) and by journal/decisions/2026-11-03-purity.md, which S4-05 writes the same way. → entries.jsonl:1
- Discovery (init, affects run): S1's forty mutants with their `before` line text are in findings-and-research/2026-11-03-suite-coverage/_mutants.jsonl (.id .file .line .before .after); the findings file's line numbers are the sample tree's, not today's: relocate a mutant by grep -F of its `before` text. → entries.jsonl:1
- Discovery (init, affects run): lib/check.sh, bin/harness and lib/queue.sh run outside a driver's or lane's shell, so no resident helper serves them: a pure function they call is one node spawn per call (check.sh already spawns treekey.mjs when no lane hands it the key); only lib/record.sh, lib/lane.sh and lib/driver.sh go through ask. → entries.jsonl:1
- Discovery (init, affects run): The S4 proof that no note text changed reads `note "` literals in the bash diff: a note's words moved into an .mjs would print as a removed note with no added twin. So every pure function answers a branch and its values, and every note string stays in bash (the plan feature's rule for the three builds). → entries.jsonl:1
- Discovery (init, affects run): Of the sampled mutants, three sat in lib/check.sh (andor-03, compare-08, literal-04; literal-04 survived before and lies in partial's row 8, which S4-02 moves, so it must be caught by the unit test after); none sat in lane_done, verify's verdict tail, reap, finish's maps, queue_add, entry_project, control or stop_why. → entries.jsonl:1

## What it builds on

- 2026-11-07 02:44 · S4-01 · passes: The plan of the purity moves (docs/plans/2026-11-07-S4-purity.md) and the decision file's skeleton (journal/decisions/2026-11-03-purity.md): three builds, each function's inputs, answer and branches, the note rule, the one mutant moved (literal-04), two push-downs, and the Decision 16 (b) table: 4 stub start lines of 65 read could go; none is removed.; tests 1506 → 1506; files docs/plans/2026-11-07-S4-purity.md, journal/decisions/2026-11-03-purity.md → entries.jsonl:2

## Lately in the run

- 2026-11-07 02:32 · init · passes: 5 features, one milestone S4 (the purity moves): S4-01 plan (docs/plans/2026-11-07-S4-purity.md, the decision file's skeleton); S4-02 lib/check.sh's cache and rerun decisions → lib/checkdecide.mjs; S4-03 the lane's verdict and exit table and how a run ends → lib/lane.mjs; S4-04 the queue entry format → lib/queue.mjs and INBOX status → inbox.mjs; S4-05 review, proofs, mutants, Predictions, docs. → entries.jsonl:1

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
