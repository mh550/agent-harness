<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-09` (agent-harness)

What this file is: the run's journal, newest entry first, rendered by the harness from `entries.jsonl` for your phone. Each entry is one session (coding, verify, review, retro) and says what it did, what it tried that failed, and what it found.

The run builds `docs/specs/2026-11-08-memory-reviewer.md` in full under the brief of 2026-11-09 22:45: milestone R1 (the memory reviewer: one read-only Opus session at the run's end that answers four questions about every curator operation that would land, its verdict in both PR bodies, and under `MEMORY_POLICY=auto` a facts PR that merges only when the review ran and every committed op held), then R2 (the count: cost and time in the report, `harness memory`'s held/failed columns and override marks, and the `auto:` graduation line: window 8, 10 ops, 90 % held, at most one override). Three features per milestone, the review last in each; R2 starts after R1 merges.

How to read the feature list: `feature_list.json` in this directory is in priority order; a session takes the first feature whose `passes` is false and whose `after` all pass. Each feature's `steps` are what a verifier re-runs; the last is always the suite green.

How to steer: edit `INBOX.md` on this branch from the GitHub app. Its first line `status: run|pause|stop` controls the run; an answer to a question goes under `## Answers`. The harness pulls it before every session.

Defaults the spec marks *default* are taken without asking (the brief says so) and recorded marked *default* in `journal/decisions/2026-11-09-memory-reviewer.md` (R1) and `journal/decisions/2026-11-09-memory-graduation.md` (R2).

### 2026-11-10 01:27 · verify R1 · passes

R1-01, R1-02, R1-03 hold. memory-review.sh 21/21 in 116 s alone (row: 115.4); memory-review+curator-run+memory-branch 68/68; fast tier 1116/1116; init full suite green (1986). renderEntry hash matches the base's. R1-02 step 3's continue merge is replaced by no merge, per the brief; the question is already open.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| R1-01 | 1 | read tests/checks/memory-review.sh:36-47 (mr run); TEST_JOBS=1 bash tests/run.sh memory-review | checks assert done, 1 zz-memory-review transcript, metrics memory-review row after curator, run.log/note order, argv --disallowedTools exactly the two, no other role but curator; all pass | yes |
| R1-01 | 2 | read memory-review.sh:48-65,84-90 and ran the file | ids facts/1 facts/2 rules/<n> from memory-result.json, all fields, cap {gotchas:1,lines:10}, rules base memory-rules-base (recorded default); EDITS=1 reverted, one note, record PR; proposal: no session, nothing to review, reviewed 0, no facts PR; pass | yes |
| R1-01 | 3 | cat prompts/memory-review.md; memory-review.sh:66-74 prompt check | # Memory review session; input/output files; Q1-Q4 with git grep -nF -e and 4 exclusions, cap counted on base, ~/.claude/CLAUDE.md, ANSWERS_FILE declined -> ## Gotchas fails Q4; thin rule; nothing but; denies gh; no {{; curator twin stays in curator-run.sh | yes |
| R1-01 | 4 | node --test --test-isolation=none tests/unit/memreview.test.mjs …; node lib/memreview.mjs input r.json b af ar (hand-made dirs) | 106/106 pass; input orders facts/1.. then rules/<n>, paths and cap; empty -> []; the CLI printed JSON and exited 0 for both | yes |
| R1-01 | 5 | read lib/driver.sh:262-322, lib/record.sh memory_pr, lib/config.sh:43, templates, lib/prompt.sh diff, stub diff; bash -n; node --check lib/*.mjs | memory_review: MAX_TURNS=40 $3, S_DENY=CURATOR_DENY, zz-memory-review-HHMMSS, ro_rescue (+256 KB bound from R1-03), MET row; dry apply, input committed before rstart; stub modes documented; syntax clean | yes |
| R1-01 | 6 | read journal/decisions/2026-11-09-memory-reviewer.md; grep docs/architecture.md, README.md | R1-01 rows marked *default* (Opus knob, deny list/bound, gate first, tier 3 not reviewed, skip, Q4 declined rows); arch: memreview.mjs, prompt, guard row :451, REVIEW lines :319-330, state row; README Memory reviewer paragraph | yes |
| R1-01 | 7 | TEST_JOBS=1 bash tests/run.sh memory-review (timed); grep suite-tiers.md; bash tests/run.sh memory-review curator-run memory-branch | 21/21 in 116 s (the row says 23.8 / 97.0 / 115.4); 68/68 checks passed (curator-run 14/14) | yes |
| R1-01 | 8 | bash tests/run.sh --tier fast; init full suite | 1116/1116 checks passed; init: check green in 767 s, 1986 tests, 0 FAIL | yes |
| R1-02 | 1 | read tests/unit/memreview.test.mjs:65-112; node --test | validate refuses unknown id, q 5, doubled (id,q), non-boolean holds, >12 rows, each naming the row; verdicts holds/fails (q2)/thin 3 of 4/not reviewed; render ## Review, op lines, five-column header; renderNone none: <why>; pass | yes |
| R1-02 | 2 | read the entries/curator unit test diffs; ran renderEntry(E) at merge-base f4a4bbc vs HEAD with sha256 | both babf0c2e…5de863 (the test's hash); --verdicts drop review: <reason> (<id>), duplicate-key loser stays out, landing = dry minus failed; body --review sits before Applied, table cut first, verdict lines kept; pass | yes |
| R1-02 | 3 | read memory-review.sh:75-177 and ran it (21/21) | pr/evict-fails/auto/thin/none/bad/limit/declined/rules-PR all as written. One deviation: the continue of mn reviews again but leaves the reused PR open. That follows the brief's rule (merge only when the review ran and every committed op held); a default, asked in entries.jsonl:3/4 | yes |
| R1-02 | 4 | git diff tests/checks/curator-run.sh; grep check-names*.txt; LC_ALL=C sort -c | check renamed to '…its notes and then the memory review's before the record PR's', old name gone; both fixtures sorted; 8 memreview.mjs unit names in both; +36 net vs budget 35, reason in the decision file | yes |
| R1-02 | 5 | grep -n memory_merge lib/record.sh; read memory_pr/memory_verdict, curator.mjs flags, summary.mjs test, prompts/curator.md diff, templates; bash -n; node --check | one call (:582), only under auto with REVIEW_NONE empty, AFTER_REVIEW set, body refreshed and the one commit past MEM_MAIN = fhead; --verdicts/--review flags; curator.md two sentences; templates say auto merges only when the review ran; syntax ok | yes |
| R1-02 | 6 | read the decision file's R1-02 choice and rejected lists; docs/architecture.md:571,488; README | thin is a fail, the pr/auto landing, no review → no merge, rules PR never merged, all marked *default*; rejected list as asked; policy row 'merged only when the review ran and every committed op held'; PR row names ## Review; README names the four questions | yes |
| R1-02 | 7 | read entries.jsonl:3 verified_how and dead_ends; the decision file R1-02 found-by notes | two Opus reviews of R1-02 recorded (1 Critical, 3+2 Important fixed: sums guard, answers tamper, held-only merge); the four invariants reviewed again in R1-03 review file; fixes covered by checks that pass | yes |
| R1-02 | 8 | bash tests/run.sh memory-review curator-run memory-branch | 68/68 checks passed | yes |
| R1-02 | 9 | bash tests/run.sh --tier fast; init full suite | 1116/1116 checks passed; init green 1986 tests | yes |
| R1-03 | 1 | ls /tmp/harness/agent-harness/agent-harness-2026-11-09/R1.diff; read docs/plans/2026-11-09-R1-review.md | diff file exists; review graded 0 Critical/3 Important/8 Minor, covers all five items: memory_merge guards, S_DENY grep/rescue/revert, duplicate-key test, renderEntry hash, stub vs prompt shape field by field; no second round needed | yes |
| R1-03 | 2 | read the review's Resolution; memory-review.sh mk/mx checks; memory-branch.sh mw diff; curator.test.mjs M4 test | I1 (no trailer, own commit only), I2 (hash-object compare, hook check), I3 (hold-exit 124) fixed with checks; M2 M3 M4 M7 fixed; M5 M6 listed with why; simplifications 1 and 3 applied, 2 declined with a reason | yes |
| R1-03 | 3 | grep docs/README; read the decision file's Checks part; grep suite-tiers.md:180 | docs level (policy row, guard row, state files, ## Review placement); both removed names listed with their successors; +36 vs 35 with the reason; tiers row 115.4 beside 23.8/97.0; my alone run took 116 s | yes |
| R1-03 | 4 | bash -n on 8 touched shell files; node --check lib/*.mjs; bash tests/run.sh memory-review curator-run memory-branch | no syntax errors; 68/68 checks passed | yes |
| R1-03 | 5 | bash tests/run.sh --tier fast; init full suite | 1116/1116 checks passed; full suite green in 767 s, 1986 tests | yes |

- *011920-verify-R1 · claude-opus-5-5*

### 2026-11-10 01:06 · R1-03 · passes

R1 review: 0 Critical, 3 Important, 8 Minor. Fixed: auto merges only this segment's own commit (trailer was forgeable, I1); a hook/filter-changed commit is never pushed (I2); timeout-after-file check (I3); M2 M3 M4 M7; verdicts-only spawn. M5, M6 listed. Docs, decisions, tiers row (115.4 s) level.

- **Files:** lib/record.sh, lib/driver.sh, lib/curator.mjs, prompts/memory-review.md, tests/stub-claude.sh, tests/checks/memory-review.sh, tests/checks/memory-branch.sh, tests/unit/curator.test.mjs, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, docs/plans/2026-11-09-R1-review.md, docs/architecture.md, +4 more
- **Verified:** Red first: the hook check and the timeout loop failed on the old code; the replaced mw3 check failed with HEAD's record.sh (the forged held commit merged); the curator body unit test failed. Then bash tests/run.sh memory-review curator-run memory-branch: 68/68 checks passed; memory-review alone (TEST_JOBS=1) 115.4 s, 22/22; check.sh --fast green, 1116 tests; bash -n / node --check clean.
- **Tests:** 1983 → 1985
- **Dead end:** STUB_MEMORY_REVIEW=hold-exit as a plain exit 1 — no result line plus exit 1 under 120 s reads as MET limit (no result after <n> s), so it never reached driver.sh's exit branch; exit 124 (the driver's timeout) does
- **Discovery** (affects R2-01, R2-02, run): Under auto a facts PR merges only when its one commit past MEM_MAIN is this segment's; the Memory-review: held trailer is gone (R1-03, I1)
- **Discovery** (affects R2-01, R2-02): memory.json review can read 'the landing differs from the dry apply' (the sums guard's refusal) besides ok and the no-review reasons
- **Discovery** (affects project): a stub exit 1 with no result line under 120 s reads as MET limit; only exit 124 reaches a role's failed-exit branch (agent-harness-2026-11-09 2026-11-10)
- **Question for Michael:** Default taken (I1): under MEMORY_POLICY=auto the driver now merges a facts PR only when its one commit past main is the commit this segment pushed, so N2-02's continue (a reused PR whose body refresh failed) no longer merges the earlier commit with its own and waits for you. Keep that, or have the next segment's reviewer also read the earlier commit's diff as a carried/<sha12> item so it can merge? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/journal/decisions/2026-11-09-memory-reviewer.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/docs/plans/2026-11-09-R1-review.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/lib/record.sh
- **Proposed change:** A backlog item for the review's M5: give each memory-review item the gate's union cap reading (both PRs) so Q3 does not fail an eviction the union made due
- *03-R1-03 · claude-opus-5-5*

### 2026-11-10 00:30 · R1-02 · passes

memreview validate/verdicts/render, evidenceTable (renderEntry byte-identical), apply --verdicts (failed facts dropped at the write, held ones replayed and capped), body --review; ## Review in both bodies and memory.md, notes, memory.json keys; auto lands held facts only and merges only Memory-review: held commits; inputs summed around the session.

- **Files:** lib/memreview.mjs, lib/entries.mjs, lib/curator.mjs, lib/record.sh, lib/driver.sh, lib/summary.mjs, lib/config.sh, prompts/curator.md, prompts/memory-review.md, tests/stub-claude.sh, tests/checks/memory-review.sh, tests/checks/curator-run.sh, +13 more
- **Verified:** unit: memreview 8/8, curator 39/39, entries 23/23, summary 35/35; bash tests/run.sh memory-review curator-run memory-branch 67/67; memory-review alone (TEST_JOBS=1) 97.0 s 20/20; the answers-tamper check watched red with the sums guard off; two Opus reviews (1 Critical, 3+2 Important fixed); check.sh --fast green, 1115 tests.
- **Tests:** 1963 → 1983
- **Dead end:** evict-fails on stub-cap-evict for the auto run — its only applied op is the eviction, so under auto nothing is left to commit or merge; stub-evict-two adds a held replace and a rule
- **Dead end:** the continue check on mn after the mb and ml runs — run() resets origin main to main0, so mn's branch carried a milestone commit main lacked and memory_foreign stopped the curator; the continue now runs on the main mn ended on
- **Dead end:** a memory-held-heads list in the run record — the second review showed a session can hide a planted line from restrict (a .gitignore) and move origin/main locally; replaced by a trailer in the driver's pushed commit and memory_base's main sha
- **Discovery** (affects R1-03): memory-review.sh runs 12 stub runs in 97 s alone (TEST_JOBS=1); its tiers row has both timings
- **Discovery** (affects R1-03, R2-01, R2-02): auto merges a facts PR only when every commit past memory_base's main sha carries the Memory-review: held trailer; memory-branch.sh's hand-made mw0 now carries it
- **Discovery** (affects R2-01, R2-02): memory.json's applied and dropped stay the gate's counts under auto (review drops are failed): R2-01's memory.jsonl must read failed, not applied minus dropped
- **Discovery** (affects R1-03): memory-review.md and memory-verdicts.json live in scratch and are written after the session; memory_sums covers ops, dry result, after texts, bases, input and answers
- **Question for Michael:** Under MEMORY_POLICY=auto, should a continue whose review holds its new facts merge a reused PR that carries an earlier segment's unreviewed commit? Default taken: no (the brief's 'merges only when the review ran and every committed op held'); the spec's §5 and R1-02 step 3 said it merges. Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/lib/record.sh, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-0/journal/decisions/2026-11-09-memory-reviewer.md
- **Proposed change:** R1-02 step 3: 'a harness continue of the none run … merges the reused PR' contradicts the brief's merge rule; built and checked as 'leaves the reused PR open, its earlier commit unreviewed' (memory-held-heads).
- **Proposed change:** R1-02 step 3 names stub-cap-evict for the evict-fails runs; built on a new tests/fixtures/memory/stub-evict-two.json (a held replace, the eviction, a rule) so the auto run has a held op to merge.
- **Proposed change:** R1-03 should check the review's residual gaps it named Minor: a background process a read-only session leaves running can write after restrict (every read-only role), and the fin reset's rules PR under a stale rules tip.
- *02-R1-02 · claude-opus-5-5*

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
