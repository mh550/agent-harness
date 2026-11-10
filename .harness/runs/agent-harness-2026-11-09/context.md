# Context pack for `R2`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Dead end (R2-01, 04-R2-01): asserting memory.json review_model == "opus" — F model resolves to the full claude-… id; the check compares it with the memory-review metrics row's model → entries.jsonl:6
- Question (R2-03): R2 review M7: should `harness memory .` (or `..`) read the project's own config for revisit, as a path does? Default kept: only an argument with a / is a path. Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-1/lib/memory.sh:72, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-1/docs/plans/2026-11-09-R2-review.md → entries.jsonl:8
- Question (R2-02): Defaults recorded in decisions/2026-11-09-memory-graduation: the auto window must hold a full 8 reviewed facts PRs before earned; a review none reads unreviewed; an edited PR's override line reads 'closed against a hold' (the spec's two words); any declined row of the run exempts a closed PR of either tier; the rules tier's failed count shows in the memory: line only when one failed. Keep them? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-1/journal/decisions/2026-11-09-memory-graduation.md → entries.jsonl:7
- 2026-11-10 02:33 · R2-03 · passes: R2's review: 0 Critical, 1 Important, 8 Minor (docs/plans/2026-11-09-R2-review.md). I1 fixed: a reused PR's memory.jsonl row merges every landed segment's review (memoryMerge, segments by continuation). M1 unknown gh state never earned, M2 no $0.00 tail for R1 files, M3 per cent floored, M4 checks bullet, M5 input-failed card line, M8 docs; M7 left.; tests 1999 → 2000; files lib/summary.mjs, lib/memreview.mjs, tests/unit/summary.test.mjs, tests/unit/memreview.test.mjs, tests/checks/memory-branch.sh, … → entries.jsonl:8
- 2026-11-10 02:13 · R2-02 · passes: harness memory: held/failed columns (unreviewed for old rows or a review none), overrides (memoryOverride: merged against a fail / closed against a hold), review: tally, auto: line via graduation (8 PRs, 10 ops, 90 %, ≤1 override, revisit <80 % on auto); memreview.mjs line + heldFailed, noted once after both PR notes; fails_dropped; decision, docs.; tests 1992 → 1999; files lib/summary.mjs, lib/memreview.mjs, lib/memory.sh, lib/record.sh, bin/harness, … → entries.jsonl:7
- 2026-11-10 01:49 · R2-01 · passes: memory.json gains review_cost_usd, review_s, review_model, reviewed_ids, failed_ids (facts/2:q2; verdicts now carry q); summary carries them; Memory row ends `review 3 held · 0 failed · $0.42 · 4 min`; run.log's memory review is a session, memory-review after curator in Spend by role/Time; memory.jsonl rows per tier; over-the-curator note; STUB_MEMORY_REVIEW_COST; decision, docs.; tests 1986 → 1992; files lib/summary.mjs, lib/record.sh, lib/driver.sh, lib/memreview.mjs, tests/stub-claude.sh, … → entries.jsonl:6

## Discoveries for this feature

- Discovery (R2-03, affects run): memory.jsonl rows with review fields now carry segments (per continuation); memoryMerge sums landed segments, one unreviewed segment makes the row unreviewed → entries.jsonl:8
- Discovery (R2-03, affects run): graduation's auto: line ends · unknown <k> and is never earned when a window PR has no gh state; a stub or unit check without gh answers sees it → entries.jsonl:8
- Discovery (R2-02, affects R2-03): memory.json and the facts row gain fails_dropped (true when auto's landing dropped the failed facts by verdict): a hand merge of such a PR is no override (review I2) → entries.jsonl:7
- Discovery (R2-02, affects R2-03): memreview.mjs line prints nothing for reviewed 0 (memory_json writes review 'nothing to review' there, not ok); the note goes only on the path that reaches memory_json at memory_pr's end → entries.jsonl:7
- Discovery (R2-02, affects R2-03): memory-review.sh now 120.8 s with memory-branch beside it (4 jobs); its tiers-table row (115.4) wants a re-time alone in R2-03 → entries.jsonl:7
- Discovery (R2-02, affects R2-03): harness memory <path> reads the policy via harness_config in a subshell; a bare name (no /) reads the user's config alone → entries.jsonl:7
- Discovery (R2-01, affects R2-02, R2-03): memory.json now carries reviewed_ids and failed_ids (`facts/2:q2`, a bare id when not reviewed or thin); memory.jsonl rows carry per-tier reviewed/held/failed/failed_ids, merged_by on the facts row only (rules row always null), review_cost_usd in both → entries.jsonl:6
- Discovery (R2-01, affects R2-02): memreview.mjs verdicts' ops now carry q (the failing row's question, else null): R2-02's line can print `, q<n>` from it instead of parsing the reason → entries.jsonl:6
- Discovery (R2-01, affects R2-02): A summary with reviewed but no reviewed_ids (a run between R1 and R2) writes ledger rows with no review fields: R2-02 reads those as unreviewed → entries.jsonl:6
- Discovery (R2-01, affects R2-02, R2-03): The stub curator and reviewer both cost $0.10 by default; STUB_MEMORY_REVIEW_COST sets the reviewer's (the mt run uses 2.5) → entries.jsonl:6
- Discovery (R1-03, affects R2-01, R2-02, run): Under auto a facts PR merges only when its one commit past MEM_MAIN is this segment's; the Memory-review: held trailer is gone (R1-03, I1) → entries.jsonl:4
- Discovery (R1-03, affects R2-01, R2-02): memory.json review can read 'the landing differs from the dry apply' (the sums guard's refusal) besides ok and the no-review reasons → entries.jsonl:4
- Discovery (R1-02, affects R1-03, R2-01, R2-02): auto merges a facts PR only when every commit past memory_base's main sha carries the Memory-review: held trailer; memory-branch.sh's hand-made mw0 now carries it → entries.jsonl:3
- Discovery (R1-02, affects R2-01, R2-02): memory.json's applied and dropped stay the gate's counts under auto (review drops are failed): R2-01's memory.jsonl must read failed, not applied minus dropped → entries.jsonl:3
- Discovery (R1-01, affects R2-01): lib/summary.mjs's run.log parser knows no 'memory review · ' / ' memory-review exit' lines and reportRows' roles lack memory-review: the reviewer's wall counts as driver time until R2-01 → entries.jsonl:2
- Discovery (init, affects run): The follow-up (2026-11-08) made apply's answers a flag (--answers <file> --project <p>), not the fifth positional: the spec's 'sixth argument' for verdicts is --verdicts <file> (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): restrict … nothing reverts every uncommitted new file since <start>: memory-review-input.json must be rec_commit-ed before rstart is taken or the review's restrict deletes it (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): features.mjs lint prints review-small for R1-03 and R2-03 (two build features each); the brief asks for three features per milestone with the review last, so those two lines stand by Michael's word (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): tier-1 facts are never numbered in memory-result.json and harness memory decline refuses a tier-1 <n>: the spec's 'closed facts PR with a decline row whose tier is facts' cannot exist; R2-02 reads any declined row of the run as the reason, marked default (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): memory-branch.sh and curator-run.sh have no row in the suite-tiers table (made after it); memory-review.sh gets one in R1-01 per the brief, re-timed in R1-03 after R1-02's runs are added (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1

## Current rules

- The thin verify names its missing steps; a comment line is not a Gotcha → journal/decisions/2026-11-09-thin-verify-and-comment-lines.md
- The memory reviewer: one read-only session on what would land, four questions per operation, under the curator's deny list → journal/decisions/2026-11-09-memory-reviewer.md
- The memory reviewer counted: its cost and time beside its verdict, the ledger's rows by tier, and the rule that earns `auto` → journal/decisions/2026-11-09-memory-graduation.md
- The curator's write gate and its prompt say one rule: words may be left out after the first 40 characters, never added → journal/decisions/2026-11-09-curator-gate-words.md
- A claim that never reached the list is named, retried once told, and given up with its reason → journal/decisions/2026-11-09-claim-gap.md
- The memory session and the answers: a denied curator, an `auto` that keeps its body, answers the next curator reads → journal/decisions/2026-11-08-memory-session-and-answers.md
- The tiers and the files: tier 2 is a PR, the twins are guarded, the cap is per operation → journal/decisions/2026-11-08-memory-rules-pr.md
- The memory curator: itemized operations, a tier the driver derives, a protected list that is fixed → journal/decisions/2026-11-07-memory-tiers.md
- The gate replaces the lint: `memlint-self` retired, `MEMORY_POLICY`, and the curator's acceptance counted → journal/decisions/2026-11-07-memory-policy.md
- One writer for project memory: a coding session's `CLAUDE.md` edit is reverted, a fact goes in the entry → journal/decisions/2026-11-07-memory-one-writer.md
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
- The check count and the check budget: every verified milestone says what it added to the suite, against a budget when the spec set one; a note, never a gate → journal/decisions/2026-11-03-check-budget.md
- A run never starts on a spec that isn't there: `harness start` and `queue add` refuse a spec absent from the run's base ref → journal/decisions/2026-10-31-spec-must-exist.md

_86 older rules: journal/decisions._
