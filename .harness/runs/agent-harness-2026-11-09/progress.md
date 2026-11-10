<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-09` (agent-harness)

What this file is: the run's journal, newest entry first, rendered by the harness from `entries.jsonl` for your phone. Each entry is one session (coding, verify, review, retro) and says what it did, what it tried that failed, and what it found.

The run builds `docs/specs/2026-11-08-memory-reviewer.md` in full under the brief of 2026-11-09 22:45: milestone R1 (the memory reviewer: one read-only Opus session at the run's end that answers four questions about every curator operation that would land, its verdict in both PR bodies, and under `MEMORY_POLICY=auto` a facts PR that merges only when the review ran and every committed op held), then R2 (the count: cost and time in the report, `harness memory`'s held/failed columns and override marks, and the `auto:` graduation line: window 8, 10 ops, 90 % held, at most one override). Three features per milestone, the review last in each; R2 starts after R1 merges.

How to read the feature list: `feature_list.json` in this directory is in priority order; a session takes the first feature whose `passes` is false and whose `after` all pass. Each feature's `steps` are what a verifier re-runs; the last is always the suite green.

How to steer: edit `INBOX.md` on this branch from the GitHub app. Its first line `status: run|pause|stop` controls the run; an answer to a question goes under `## Answers`. The harness pulls it before every session.

Defaults the spec marks *default* are taken without asking (the brief says so) and recorded marked *default* in `journal/decisions/2026-11-09-memory-reviewer.md` (R1) and `journal/decisions/2026-11-09-memory-graduation.md` (R2).

### 2026-11-09 23:05 · init · passes

6 features: R1 3 (R1-01 the memory-review session and input file, R1-02 the verdict, the ## Review section and what lands by policy, R1-03 review), R2 3 (R2-01 cost and time in memory.json, the Memory row and memory.jsonl, R2-02 harness memory's columns, overrides and the auto: line, R2-03 review). R2 after R1, as the brief asks. check_budget R1 35, R2 25.

- **Discovery** (affects run): The follow-up (2026-11-08) made apply's answers a flag (--answers <file> --project <p>), not the fifth positional: the spec's 'sixth argument' for verdicts is --verdicts <file> (agent-harness-2026-11-09 2026-11-09)
- **Discovery** (affects run): restrict … nothing reverts every uncommitted new file since <start>: memory-review-input.json must be rec_commit-ed before rstart is taken or the review's restrict deletes it (agent-harness-2026-11-09 2026-11-09)
- **Discovery** (affects run): features.mjs lint prints review-small for R1-03 and R2-03 (two build features each); the brief asks for three features per milestone with the review last, so those two lines stand by Michael's word (agent-harness-2026-11-09 2026-11-09)
- **Discovery** (affects run): tier-1 facts are never numbered in memory-result.json and harness memory decline refuses a tier-1 <n>: the spec's 'closed facts PR with a decline row whose tier is facts' cannot exist; R2-02 reads any declined row of the run as the reason, marked default (agent-harness-2026-11-09 2026-11-09)
- **Discovery** (affects run): memory-branch.sh and curator-run.sh have no row in the suite-tiers table (made after it); memory-review.sh gets one in R1-01 per the brief, re-timed in R1-03 after R1-02's runs are added (agent-harness-2026-11-09 2026-11-09)
- *00-init · claude-fable-5-1*
