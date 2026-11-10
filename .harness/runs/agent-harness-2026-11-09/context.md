# Context pack for `R1`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Dead end (R1-03, 03-R1-03): STUB_MEMORY_REVIEW=hold-exit as a plain exit 1 — no result line plus exit 1 under 120 s reads as MET limit (no result after <n> s), so it never reached driver.sh's exit branch; exit 124 (the driver's timeout) does → entries.jsonl:4
- Dead end (R1-02, 02-R1-02): evict-fails on stub-cap-evict for the auto run — its only applied op is the eviction, so under auto nothing is left to commit or merge; stub-evict-two adds a held replace and a rule → entries.jsonl:3
- Dead end (R1-02, 02-R1-02): the continue check on mn after the mb and ml runs — run() resets origin main to main0, so mn's branch carried a milestone commit main lacked and memory_foreign stopped the curator; the continue now runs on the main mn ended on → entries.jsonl:3
- Dead end (R1-02, 02-R1-02): a memory-held-heads list in the run record — the second review showed a session can hide a planted line from restrict (a .gitignore) and move origin/main locally; replaced by a trailer in the driver's pushed commit and memory_base's main sha → entries.jsonl:3
- Dead end (R1-01, 01-R1-01): stub STUB_MEMORY_REVIEW_EDITS=ops rewriting the op's text outright — the text lost its (<run> <date>) suffix, validate refused the ops and the landing hit 'apply failed' instead of the guard; it now rewrites a word and stays valid → entries.jsonl:2
- Question (R1-03): Default taken (I1): under MEMORY_POLICY=auto the driver now merges a facts PR only when its one commit past main is the commit this segment pushed, so N2-02's continue (a reused PR whose body refresh failed) no longer merges the earlier commit with its own and waits for you. Keep that, or have the next segment's reviewer also read the earlier commit's diff as a carried/<sha12> item so it can merge? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/journal/decisions/2026-11-09-memory-reviewer.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/docs/plans/2026-11-09-R1-review.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/lib/record.sh → entries.jsonl:4
- Question (R1-02): Under MEMORY_POLICY=auto, should a continue whose review holds its new facts merge a reused PR that carries an earlier segment's unreviewed commit? Default taken: no (the brief's 'merges only when the review ran and every committed op held'); the spec's §5 and R1-02 step 3 said it merges. Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/lib/record.sh, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/journal/decisions/2026-11-09-memory-reviewer.md → entries.jsonl:3
- 2026-11-10 01:06 · R1-03 · passes: R1 review: 0 Critical, 3 Important, 8 Minor. Fixed: auto merges only this segment's own commit (trailer was forgeable, I1); a hook/filter-changed commit is never pushed (I2); timeout-after-file check (I3); M2 M3 M4 M7; verdicts-only spawn. M5, M6 listed. Docs, decisions, tiers row (115.4 s) level.; tests 1983 → 1985; files lib/record.sh, lib/driver.sh, lib/curator.mjs, prompts/memory-review.md, tests/stub-claude.sh, … → entries.jsonl:4
- 2026-11-10 00:30 · R1-02 · passes: memreview validate/verdicts/render, evidenceTable (renderEntry byte-identical), apply --verdicts (failed facts dropped at the write, held ones replayed and capped), body --review; ## Review in both bodies and memory.md, notes, memory.json keys; auto lands held facts only and merges only Memory-review: held commits; inputs summed around the session.; tests 1963 → 1983; files lib/memreview.mjs, lib/entries.mjs, lib/curator.mjs, lib/record.sh, lib/driver.sh, … → entries.jsonl:3
- 2026-11-09 23:40 · R1-01 · passes: memory_pr dry-applies into memory-after-facts/-rules, writes memory-review-input.json (memreview.mjs input), commits it, runs a read-only memory-review session under CURATOR_DENY (now top-level), keeps memory-review.json, then lands; nothing to review skips. A landing differing from the dry apply commits nothing (review finding). Prompt, stub, docs, decision file.; tests 1949 → 1963; files lib/memreview.mjs, lib/record.sh, lib/driver.sh, lib/prompt.sh, lib/config.sh, … → entries.jsonl:2

## Discoveries for this feature

- Discovery (R1-03, affects R2-01, R2-02, run): Under auto a facts PR merges only when its one commit past MEM_MAIN is this segment's; the Memory-review: held trailer is gone (R1-03, I1) → entries.jsonl:4
- Discovery (R1-02, affects R1-03): memory-review.sh runs 12 stub runs in 97 s alone (TEST_JOBS=1); its tiers row has both timings → entries.jsonl:3
- Discovery (R1-02, affects R1-03, R2-01, R2-02): auto merges a facts PR only when every commit past memory_base's main sha carries the Memory-review: held trailer; memory-branch.sh's hand-made mw0 now carries it → entries.jsonl:3
- Discovery (R1-02, affects R1-03): memory-review.md and memory-verdicts.json live in scratch and are written after the session; memory_sums covers ops, dry result, after texts, bases, input and answers → entries.jsonl:3
- Discovery (R1-01, affects R1-02, R1-03): A rules item's base is memory-rules-base/ (its commit's base), not memory-base/ as R1-01 step 2 words it; equal unless a rules PR is open (default, in the decision file) → entries.jsonl:2
- Discovery (R1-01, affects R1-02): memory_pr fails closed when the landing's result or a tier-1 text differs from the dry apply: R1-02's --verdicts landing under auto must compare against the dry result minus the failed ops, or that guard refuses every auto drop → entries.jsonl:2
- Discovery (R1-01, affects R1-02): memory_review() sets REVIEW_NONE (no file, limit) and copies memory-review.json unvalidated: a 'bad' file reads review: ok until R1-02's validate; stub modes none/bad/limit/thin/evict-fails exist but no check runs them yet → entries.jsonl:2
- Discovery (R1-01, affects R1-02): ro_rescue keeps files up to 64 KB: 50 ops x 4 rows with long saw lines can pass it and read as 'wrote no memory-review.json'; R1-02's row caps should bound it → entries.jsonl:2
- Discovery (R1-01, affects R1-03): memory_pr's worktree-add failure now comes after the review session (a $3 session spent before 'apply failed (no worktree …)'); accepted, rare → entries.jsonl:2
- Discovery (init, affects run): The follow-up (2026-11-08) made apply's answers a flag (--answers <file> --project <p>), not the fifth positional: the spec's 'sixth argument' for verdicts is --verdicts <file> (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): restrict … nothing reverts every uncommitted new file since <start>: memory-review-input.json must be rec_commit-ed before rstart is taken or the review's restrict deletes it (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): features.mjs lint prints review-small for R1-03 and R2-03 (two build features each); the brief asks for three features per milestone with the review last, so those two lines stand by Michael's word (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): tier-1 facts are never numbered in memory-result.json and harness memory decline refuses a tier-1 <n>: the spec's 'closed facts PR with a decline row whose tier is facts' cannot exist; R2-02 reads any declined row of the run as the reason, marked default (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1
- Discovery (init, affects run): memory-branch.sh and curator-run.sh have no row in the suite-tiers table (made after it); memory-review.sh gets one in R1-01 per the brief, re-timed in R1-03 after R1-02's runs are added (agent-harness-2026-11-09 2026-11-09) → entries.jsonl:1

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
- One full run per coding session, last: the prompt's rule and §3 order, and `Suite runs` in the report → journal/decisions/2026-10-31-one-full-run.md

_85 older rules: journal/decisions._
