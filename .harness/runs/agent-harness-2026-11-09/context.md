# Context pack for `R2-03`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (R2-02, affects R2-03): memory.json and the facts row gain fails_dropped (true when auto's landing dropped the failed facts by verdict): a hand merge of such a PR is no override (review I2) → entries.jsonl:7
- Discovery (R2-02, affects R2-03): memreview.mjs line prints nothing for reviewed 0 (memory_json writes review 'nothing to review' there, not ok); the note goes only on the path that reaches memory_json at memory_pr's end → entries.jsonl:7
- Discovery (R2-02, affects R2-03): memory-review.sh now 120.8 s with memory-branch beside it (4 jobs); its tiers-table row (115.4) wants a re-time alone in R2-03 → entries.jsonl:7
- Discovery (R2-02, affects R2-03): harness memory <path> reads the policy via harness_config in a subshell; a bare name (no /) reads the user's config alone → entries.jsonl:7
- Discovery (R2-01, affects R2-02, R2-03): memory.json now carries reviewed_ids and failed_ids (`facts/2:q2`, a bare id when not reviewed or thin); memory.jsonl rows carry per-tier reviewed/held/failed/failed_ids, merged_by on the facts row only (rules row always null), review_cost_usd in both → entries.jsonl:6
- Discovery (R2-01, affects R2-02, R2-03): The stub curator and reviewer both cost $0.10 by default; STUB_MEMORY_REVIEW_COST sets the reviewer's (the mt run uses 2.5) → entries.jsonl:6
- Discovery (R1-03, affects R2-01, R2-02, run): Under auto a facts PR merges only when its one commit past MEM_MAIN is this segment's; the Memory-review: held trailer is gone (R1-03, I1) → entries.jsonl:4
- Discovery (init, affects run): The follow-up (2026-11-08) made apply's answers a flag (--answers <file> --project <p>), not the fifth positional: the spec's 'sixth argument' for verdicts is --verdicts <file> (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): restrict … nothing reverts every uncommitted new file since <start>: memory-review-input.json must be rec_commit-ed before rstart is taken or the review's restrict deletes it (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): features.mjs lint prints review-small for R1-03 and R2-03 (two build features each); the brief asks for three features per milestone with the review last, so those two lines stand by Michael's word (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): tier-1 facts are never numbered in memory-result.json and harness memory decline refuses a tier-1 <n>: the spec's 'closed facts PR with a decline row whose tier is facts' cannot exist; R2-02 reads any declined row of the run as the reason, marked default (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): memory-branch.sh and curator-run.sh have no row in the suite-tiers table (made after it); memory-review.sh gets one in R1-01 per the brief, re-timed in R1-03 after R1-02's runs are added (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1

## Promote to Gotchas

- a stub exit 1 with no result line under 120 s reads as MET limit; only exit 124 reaches a role's failed-exit branch (agent-harness-2026-11-09 2026-11-10) → entries.jsonl:4

## What it builds on

- 2026-11-10 01:49 · R2-01 · passes: memory.json gains review_cost_usd, review_s, review_model, reviewed_ids, failed_ids (facts/2:q2; verdicts now carry q); summary carries them; Memory row ends `review 3 held · 0 failed · $0.42 · 4 min`; run.log's memory review is a session, memory-review after curator in Spend by role/Time; memory.jsonl rows per tier; over-the-curator note; STUB_MEMORY_REVIEW_COST; decision, docs.; tests 1986 → 1992; files lib/summary.mjs, lib/record.sh, lib/driver.sh, lib/memreview.mjs, tests/stub-claude.sh, … → entries.jsonl:6
- 2026-11-10 02:13 · R2-02 · passes: harness memory: held/failed columns (unreviewed for old rows or a review none), overrides (memoryOverride: merged against a fail / closed against a hold), review: tally, auto: line via graduation (8 PRs, 10 ops, 90 %, ≤1 override, revisit <80 % on auto); memreview.mjs line + heldFailed, noted once after both PR notes; fails_dropped; decision, docs.; tests 1992 → 1999; files lib/summary.mjs, lib/memreview.mjs, lib/memory.sh, lib/record.sh, bin/harness, … → entries.jsonl:7

## Lately in the run

- 2026-11-10 01:27 · verify R1 · passes: R1-01, R1-02, R1-03 hold. memory-review.sh 21/21 in 116 s alone (row: 115.4); memory-review+curator-run+memory-branch 68/68; fast tier 1116/1116; init full suite green (1986). renderEntry hash matches the base's. R1-02 step 3's continue merge is replaced by no merge, per the brief; the question is already open. → entries.jsonl:5

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

_98 older rules: journal/decisions._
