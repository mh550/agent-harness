# Context pack for `R1-01`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (init, affects run): The follow-up (2026-11-08) made apply's answers a flag (--answers <file> --project <p>), not the fifth positional: the spec's 'sixth argument' for verdicts is --verdicts <file> (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): restrict … nothing reverts every uncommitted new file since <start>: memory-review-input.json must be rec_commit-ed before rstart is taken or the review's restrict deletes it (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): features.mjs lint prints review-small for R1-03 and R2-03 (two build features each); the brief asks for three features per milestone with the review last, so those two lines stand by Michael's word (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): tier-1 facts are never numbered in memory-result.json and harness memory decline refuses a tier-1 <n>: the spec's 'closed facts PR with a decline row whose tier is facts' cannot exist; R2-02 reads any declined row of the run as the reason, marked default (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): memory-branch.sh and curator-run.sh have no row in the suite-tiers table (made after it); memory-review.sh gets one in R1-01 per the brief, re-timed in R1-03 after R1-02's runs are added (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1

## Lately in the run

- 2026-11-09 23:05 · init · passes: 6 features: R1 3 (R1-01 the memory-review session and input file, R1-02 the verdict, the ## Review section and what lands by policy, R1-03 review), R2 3 (R2-01 cost and time in memory.json, the Memory row and memory.jsonl, R2-02 harness memory's columns, overrides and the auto: line, R2-03 review). R2 after R1, as the brief asks. check_budget R1 35, R2 25. → entries.jsonl:1

## Current rules

- The thin verify names its missing steps; a comment line is not a Gotcha → journal/decisions/2026-11-09-thin-verify-and-comment-lines.md
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

_96 older rules: journal/decisions._
