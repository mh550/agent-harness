<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-09` (agent-harness)

What this file is: the run's journal, newest entry first, rendered by the harness from `entries.jsonl` for your phone. Each entry is one session (coding, verify, review, retro) and says what it did, what it tried that failed, and what it found.

The run builds `docs/specs/2026-11-08-memory-reviewer.md` in full under the brief of 2026-11-09 22:45: milestone R1 (the memory reviewer: one read-only Opus session at the run's end that answers four questions about every curator operation that would land, its verdict in both PR bodies, and under `MEMORY_POLICY=auto` a facts PR that merges only when the review ran and every committed op held), then R2 (the count: cost and time in the report, `harness memory`'s held/failed columns and override marks, and the `auto:` graduation line: window 8, 10 ops, 90 % held, at most one override). Three features per milestone, the review last in each; R2 starts after R1 merges.

How to read the feature list: `feature_list.json` in this directory is in priority order; a session takes the first feature whose `passes` is false and whose `after` all pass. Each feature's `steps` are what a verifier re-runs; the last is always the suite green.

How to steer: edit `INBOX.md` on this branch from the GitHub app. Its first line `status: run|pause|stop` controls the run; an answer to a question goes under `## Answers`. The harness pulls it before every session.

Defaults the spec marks *default* are taken without asking (the brief says so) and recorded marked *default* in `journal/decisions/2026-11-09-memory-reviewer.md` (R1) and `journal/decisions/2026-11-09-memory-graduation.md` (R2).

### 2026-11-09 23:40 · R1-01 · passes

memory_pr dry-applies into memory-after-facts/-rules, writes memory-review-input.json (memreview.mjs input), commits it, runs a read-only memory-review session under CURATOR_DENY (now top-level), keeps memory-review.json, then lands; nothing to review skips. A landing differing from the dry apply commits nothing (review finding). Prompt, stub, docs, decision file.

- **Files:** lib/memreview.mjs, lib/record.sh, lib/driver.sh, lib/prompt.sh, lib/config.sh, lib/curator.mjs, prompts/memory-review.md, tests/stub-claude.sh, tests/checks/memory-review.sh, tests/unit/memreview.test.mjs, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, +7 more
- **Verified:** unit memreview 4/4; bash tests/run.sh memory-review curator-run memory-branch 57/57; gotchas-pack + resident-helper-run 28/28; memory-review alone (TEST_JOBS=1) 23.8 s, 10/10; the landing check watched red with its guard off; check.sh --fast green, 1105 tests.
- **Tests:** 1949 → 1963
- **Dead end:** stub STUB_MEMORY_REVIEW_EDITS=ops rewriting the op's text outright — the text lost its (<run> <date>) suffix, validate refused the ops and the landing hit 'apply failed' instead of the guard; it now rewrites a word and stays valid
- **Discovery** (affects R1-02, R1-03): A rules item's base is memory-rules-base/ (its commit's base), not memory-base/ as R1-01 step 2 words it; equal unless a rules PR is open (default, in the decision file)
- **Discovery** (affects R1-02): memory_pr fails closed when the landing's result or a tier-1 text differs from the dry apply: R1-02's --verdicts landing under auto must compare against the dry result minus the failed ops, or that guard refuses every auto drop
- **Discovery** (affects R1-02): memory_review() sets REVIEW_NONE (no file, limit) and copies memory-review.json unvalidated: a 'bad' file reads review: ok until R1-02's validate; stub modes none/bad/limit/thin/evict-fails exist but no check runs them yet
- **Discovery** (affects R2-01): lib/summary.mjs's run.log parser knows no 'memory review · ' / ' memory-review exit' lines and reportRows' roles lack memory-review: the reviewer's wall counts as driver time until R2-01
- **Discovery** (affects R1-02): ro_rescue keeps files up to 64 KB: 50 ops x 4 rows with long saw lines can pass it and read as 'wrote no memory-review.json'; R1-02's row caps should bound it
- **Discovery** (affects R1-03): memory_pr's worktree-add failure now comes after the review session (a $3 session spent before 'apply failed (no worktree …)'); accepted, rare
- **Proposed change:** R1-01 step 2 should say a rules item's base is under memory-rules-base/ (the rules base), as built.
- **Proposed change:** R1-01 step 3's `lib/prompt.sh <state dir> memory-review x` needs a feature of the run's list: the check uses A.
- *01-R1-01 · claude-opus-5-5*

### 2026-11-09 23:05 · init · passes

6 features: R1 3 (R1-01 the memory-review session and input file, R1-02 the verdict, the ## Review section and what lands by policy, R1-03 review), R2 3 (R2-01 cost and time in memory.json, the Memory row and memory.jsonl, R2-02 harness memory's columns, overrides and the auto: line, R2-03 review). R2 after R1, as the brief asks. check_budget R1 35, R2 25.

- **Discovery** (affects run): The follow-up (2026-11-08) made apply's answers a flag (--answers <file> --project <p>), not the fifth positional: the spec's 'sixth argument' for verdicts is --verdicts <file> (agent-harness-2026-11-09 2026-11-09)
- **Discovery** (affects run): restrict … nothing reverts every uncommitted new file since <start>: memory-review-input.json must be rec_commit-ed before rstart is taken or the review's restrict deletes it (agent-harness-2026-11-09 2026-11-09)
- **Discovery** (affects run): features.mjs lint prints review-small for R1-03 and R2-03 (two build features each); the brief asks for three features per milestone with the review last, so those two lines stand by Michael's word (agent-harness-2026-11-09 2026-11-09)
- **Discovery** (affects run): tier-1 facts are never numbered in memory-result.json and harness memory decline refuses a tier-1 <n>: the spec's 'closed facts PR with a decline row whose tier is facts' cannot exist; R2-02 reads any declined row of the run as the reason, marked default (agent-harness-2026-11-09 2026-11-09)
- **Discovery** (affects run): memory-branch.sh and curator-run.sh have no row in the suite-tiers table (made after it); memory-review.sh gets one in R1-01 per the brief, re-timed in R1-03 after R1-02's runs are added (agent-harness-2026-11-09 2026-11-09)
- *00-init · claude-fable-5-1*
