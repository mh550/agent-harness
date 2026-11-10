# Context pack for `R1-03`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (R1-02, affects R1-03): memory-review.sh runs 12 stub runs in 97 s alone (TEST_JOBS=1); its tiers row has both timings → entries.jsonl:3
- Discovery (R1-02, affects R1-03, R2-01, R2-02): auto merges a facts PR only when every commit past memory_base's main sha carries the Memory-review: held trailer; memory-branch.sh's hand-made mw0 now carries it → entries.jsonl:3
- Discovery (R1-02, affects R1-03): memory-review.md and memory-verdicts.json live in scratch and are written after the session; memory_sums covers ops, dry result, after texts, bases, input and answers → entries.jsonl:3
- Discovery (R1-01, affects R1-02, R1-03): A rules item's base is memory-rules-base/ (its commit's base), not memory-base/ as R1-01 step 2 words it; equal unless a rules PR is open (default, in the decision file) → entries.jsonl:2
- Discovery (R1-01, affects R1-03): memory_pr's worktree-add failure now comes after the review session (a $3 session spent before 'apply failed (no worktree …)'); accepted, rare → entries.jsonl:2
- Discovery (init, affects run): The follow-up (2026-11-08) made apply's answers a flag (--answers <file> --project <p>), not the fifth positional: the spec's 'sixth argument' for verdicts is --verdicts <file> (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): restrict … nothing reverts every uncommitted new file since <start>: memory-review-input.json must be rec_commit-ed before rstart is taken or the review's restrict deletes it (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): features.mjs lint prints review-small for R1-03 and R2-03 (two build features each); the brief asks for three features per milestone with the review last, so those two lines stand by Michael's word (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): tier-1 facts are never numbered in memory-result.json and harness memory decline refuses a tier-1 <n>: the spec's 'closed facts PR with a decline row whose tier is facts' cannot exist; R2-02 reads any declined row of the run as the reason, marked default (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): memory-branch.sh and curator-run.sh have no row in the suite-tiers table (made after it); memory-review.sh gets one in R1-01 per the brief, re-timed in R1-03 after R1-02's runs are added (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1

## What it builds on

- 2026-11-09 23:40 · R1-01 · passes: memory_pr dry-applies into memory-after-facts/-rules, writes memory-review-input.json (memreview.mjs input), commits it, runs a read-only memory-review session under CURATOR_DENY (now top-level), keeps memory-review.json, then lands; nothing to review skips. A landing differing from the dry apply commits nothing (review finding). Prompt, stub, docs, decision file.; tests 1949 → 1963; files lib/memreview.mjs, lib/record.sh, lib/driver.sh, lib/prompt.sh, lib/config.sh, … → entries.jsonl:2
- 2026-11-10 00:30 · R1-02 · passes: memreview validate/verdicts/render, evidenceTable (renderEntry byte-identical), apply --verdicts (failed facts dropped at the write, held ones replayed and capped), body --review; ## Review in both bodies and memory.md, notes, memory.json keys; auto lands held facts only and merges only Memory-review: held commits; inputs summed around the session.; tests 1963 → 1983; files lib/memreview.mjs, lib/entries.mjs, lib/curator.mjs, lib/record.sh, lib/driver.sh, … → entries.jsonl:3

## Lately in the run

- 2026-11-09 23:05 · init · passes: 6 features: R1 3 (R1-01 the memory-review session and input file, R1-02 the verdict, the ## Review section and what lands by policy, R1-03 review), R2 3 (R2-01 cost and time in memory.json, the Memory row and memory.jsonl, R2-02 harness memory's columns, overrides and the auto: line, R2-03 review). R2 after R1, as the brief asks. check_budget R1 35, R2 25. → entries.jsonl:1

## Current rules

- The thin verify names its missing steps; a comment line is not a Gotcha → journal/decisions/2026-11-09-thin-verify-and-comment-lines.md
- The memory reviewer: one read-only session on what would land, four questions per operation, under the curator's deny list → journal/decisions/2026-11-09-memory-reviewer.md
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

_97 older rules: journal/decisions._
