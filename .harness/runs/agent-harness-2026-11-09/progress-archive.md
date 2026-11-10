<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-09` (agent-harness)

What this file is: the run's journal, newest entry first, rendered by the harness from `entries.jsonl` for your phone. Each entry is one session (coding, verify, review, retro) and says what it did, what it tried that failed, and what it found.

The run builds `docs/specs/2026-11-08-memory-reviewer.md` in full under the brief of 2026-11-09 22:45: milestone R1 (the memory reviewer: one read-only Opus session at the run's end that answers four questions about every curator operation that would land, its verdict in both PR bodies, and under `MEMORY_POLICY=auto` a facts PR that merges only when the review ran and every committed op held), then R2 (the count: cost and time in the report, `harness memory`'s held/failed columns and override marks, and the `auto:` graduation line: window 8, 10 ops, 90 % held, at most one override). Three features per milestone, the review last in each; R2 starts after R1 merges.

How to read the feature list: `feature_list.json` in this directory is in priority order; a session takes the first feature whose `passes` is false and whose `after` all pass. Each feature's `steps` are what a verifier re-runs; the last is always the suite green.

How to steer: edit `INBOX.md` on this branch from the GitHub app. Its first line `status: run|pause|stop` controls the run; an answer to a question goes under `## Answers`. The harness pulls it before every session.

Defaults the spec marks *default* are taken without asking (the brief says so) and recorded marked *default* in `journal/decisions/2026-11-09-memory-reviewer.md` (R1) and `journal/decisions/2026-11-09-memory-graduation.md` (R2).

### 2026-11-10 02:52 · verify R2 · passes

R2-01, R2-02, R2-03 hold. memory-review+memory-branch 61/61 (memory-review 121 s); fast tier 1123/1123; init full suite 2000/2000; summary+memreview units 50/50. The step's 'held 7 of 8 · 88 %' prints 87 %: R2-03's review (M3) floors the per cent, recorded in decisions/2026-11-09-memory-graduation; held as worded behaviour, question raised.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| R2-01 | 1 | read tests/unit/summary.test.mjs 'build reads the review's keys, cost, wall and model…', 'run.log's memory review line is its session…', 'memory-line writes the review's fields…'; node --test summary+memreview | 50/50 pass; asserts build keys [3,2,1,ok,driver,0.42,250,opus,…], memoryLine '… · review 2 held · 1 failed · $0.42 · 4 min', '· review none (the reviewer hit a limit)', no review key for old memory.json; Spend by role 'curator $0.10 · memory-review $0.42'; facts/rules rows [facts,2,1,1,ok,[facts/2:q2],driver,0.42],[rules,…,null,0.42] | yes |
| R2-01 | 2 | read tests/checks/memory-review.sh checks 'harness report prints the Memory row…', 'memory.jsonl's facts row and rules row…', 'a reviewer dearer than its curator…', 'a reviewer at the curator's cost…'; bash tests/run.sh memory-review memory-branch | report --md Memory row ends 'review 3 held · 0 failed · $0.10 · N min', Spend by role memory-review after curator; both ledger rows carry review fields; STUB_MEMORY_REVIEW_COST=2.5 run: one note 'memory review: cost $2.50 over the curator's $0.10' after the counts note; default run none; all PASS | yes |
| R2-01 | 3 | git diff 7322df9 -- lib/record.sh lib/driver.sh tests/stub-claude.sh; bash -n lib/record.sh tests/stub-claude.sh tests/checks/memory-review.sh; node --check lib/summary.mjs lib/metrics.mjs | memory_review sets REVIEW_COST=$(MET cost $mlog) REVIEW_S=$S_WALL REVIEW_MODEL; memory_json writes review_cost_usd/review_s/review_model (0,0,null default); memory_cost_note after memory_verdict; stub ok ${STUB_MEMORY_REVIEW_COST:-0.1} documented in header; metrics.mjs untouched; syntax checks ok | yes |
| R2-01 | 4 | cat journal/decisions/2026-11-09-memory-graduation.md; grep docs/architecture.md README.md | decision has title, provenance, finding/choice/rejected; R2-01 rows marked *Default* (Memory row tail, over-the-curator note never a stop, $3/40 turns/under-6-min bound); architecture Memory PRs row lists reviewed/held/failed/review/failed_ids/merged_by/review_cost_usd, Memory row tail at :142/:669; README harness report row names '· review 3 held · 0 failed · $0.42 · 4 min' | yes |
| R2-01 | 5 | bash tests/run.sh memory-review memory-branch; diff check-names.txt | 61/61 checks passed (memory-review 28, memory-branch 32, conformance); R2 adds 16 names, removes 2 (counted in the decision's Checks bullet), under the budget of 25 | yes |
| R2-01 | 6 | bash tests/run.sh --tier fast; init full run | 1123/1123 checks passed (wall 130 s); init check.out 2000/2000 checks passed in 771 s | yes |
| R2-02 | 1 | read tests/unit/summary.test.mjs 'memoryView: held and failed columns…', 'graduation: earned over the last 8…'; tests/unit/memreview.test.mjs 'line is the one memory: line…'; node --test | pass; f1 'override: merged against a fail', f2 driver merge none, f3/f5 'closed against a hold', f4 declined none, f6/f8 unreviewed, review: tally line; graduation earned 19 of 20, not yet at 87 %/2 overrides/9 ops, revisit at 75 % on auto; line prints 'auto: not yet (held 7 of 8 · 87 % · overrides 1 of 6 reviewed PRs · window 8)' (step says 88 %: R2-03 M3 floors the per cent, recorded in the decision); memreview line format matches | yes |
| R2-02 | 2 | read memory-review.sh 'harness memory: each PR's line carries…', '…merged unchanged over a failed op…', 'the memory: facts note… is memreview.mjs line…'; memory-branch.sh renamed check; bash tests/run.sh memory-review memory-branch | ep line 'held 1 · failed 1 · open', mb unreviewed, review: tally failed = ledger sum, project view ends 'auto: not yet (… · window 8)', no auto: without project; after pr-N.merged ep 'override: merged against a fail', ea driver merge none; note == node memreview.mjs line on record; old memory-branch name removed from check-names.txt; 61/61 PASS | yes |
| R2-02 | 3 | read lib/summary.mjs memoryOverride/graduation/memoryView, lib/memory.sh, lib/memreview.mjs line, record.sh note, bin/harness usage; bash -n lib/memory.sh lib/record.sh bin/harness tests/checks/memory-review.sh tests/checks/memory-branch.sh; node --check summary/memory/memreview | memoryOverride reads merged_by !== driver and fails_dropped; graduation sums ledger rows, states only in override; memory.sh reads MEMORY_POLICY via harness_config in a subshell and passes it; record.sh notes line once after memory_json at memory_pr's end; usage names auto: line; all syntax checks ok | yes |
| R2-02 | 4 | read graduation decision; git diff journal/decisions/2026-11-07-memory-policy.md; grep architecture/README; git diff --stat 7322df9 -- lib/notify.mjs | rule (8, 10, 90 %, one override, revisit <80 %) with why each number and rejected 5 PRs/95 %/zero overrides/hard switch; override defaults marked *default*; F3d kind and field named; memory-policy has 'Updated in place 2026-11-09' line; architecture harness memory row, auto rule, F3d sentence in the routed events row; README harness memory row and rule; notify.mjs diff empty | yes |
| R2-02 | 5 | bash tests/run.sh memory-review memory-branch | 61/61 checks passed; R2's 16 added names against budget 25 in the decision's Checks bullet | yes |
| R2-02 | 6 | bash tests/run.sh --tier fast; init full run | 1123/1123 checks passed; full suite 2000/2000 | yes |
| R2-03 | 1 | ls -la /tmp/harness/agent-harness/agent-harness-2026-11-09/R2.diff; read docs/plans/2026-11-09-R2-review.md; grep -rn 'held ·' lib/ | diff file 185 KB (02:14); review by an independent Opus read of the diff file, graded 0 Critical/1 Important/8 Minor, answers the five questions (driver merge, old rows, one renderer, ledger vs gh, removed names); grep: memreview.mjs heldFailed plus R1-02's counts note in record.sh (M6, kept by design); no Critical, so one round | yes |
| R2-03 | 2 | read the review's Resolution; tests/unit/summary.test.mjs 'memory-line on a continue's reused PR sums each landed segment's review…' and graduation unknown/floor asserts; memreview line M5 assert | I1 fixed with that unit test (sums segments 3/2/1, rerun replaces its own, unreviewed segment makes row unreviewed); M1 unknown never earned, M2 no $0.00 tail, M3 floor, M4 successors, M5 input-failed none line, M8 docs fixed; M6/M7 listed with why not; new name in both fixtures | yes |
| R2-03 | 3 | compare README/architecture text with summary.mjs/memreview.mjs output formats; read the decision's Checks bullet | harness memory row, graduation rule (87 %, floor, unknown <k>), ledger fields, F3d sentence match the code; decision lists both removed names with successors and 16 added vs budget 25 | yes |
| R2-03 | 4 | bash -n lib/record.sh lib/driver.sh lib/memory.sh bin/harness tests/stub-claude.sh tests/checks/memory-review.sh tests/checks/memory-branch.sh; node --check lib/summary.mjs lib/memreview.mjs lib/memory.mjs lib/metrics.mjs; bash tests/run.sh memory-review memory-branch | all syntax checks ok; 61/61 checks passed | yes |
| R2-03 | 5 | bash tests/run.sh --tier fast; init full run | 1123/1123 checks passed; full suite 2000/2000 in 771 s | yes |

- **Question for Michael:** R2-02 step 1 states the line 'auto: not yet (held 7 of 8 · 88 % · …)'; R2-03's review (M3) floors the per cent so it prints 87 %, recorded in decisions/2026-11-09-memory-graduation. I held the step on that recorded change. Keep the floor? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-1/lib/summary.mjs:384, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-1/journal/decisions/2026-11-09-memory-graduation.md
- *024651-verify-R2 · claude-opus-5-5*

### 2026-11-10 02:33 · R2-03 · passes

R2's review: 0 Critical, 1 Important, 8 Minor (docs/plans/2026-11-09-R2-review.md). I1 fixed: a reused PR's memory.jsonl row merges every landed segment's review (memoryMerge, segments by continuation). M1 unknown gh state never earned, M2 no $0.00 tail for R1 files, M3 per cent floored, M4 checks bullet, M5 input-failed card line, M8 docs; M7 left.

- **Files:** lib/summary.mjs, lib/memreview.mjs, tests/unit/summary.test.mjs, tests/unit/memreview.test.mjs, tests/checks/memory-branch.sh, tests/checks/memory-review.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, docs/plans/2026-11-09-R2-review.md, docs/architecture.md, README.md, journal/decisions/2026-11-09-memory-graduation.md, +1 more
- **Verified:** new unit test red first ([1,1,0] vs [3,2,1]); unit tier 587/587; bash tests/run.sh memory-review memory-branch 61/61; memory-review.sh alone 28 checks 118.7 s; check.sh --fast 1123/1123; bash -n and node --check on every touched file
- **Tests:** 1999 → 2000
- **Discovery** (affects run): memory.jsonl rows with review fields now carry segments (per continuation); memoryMerge sums landed segments, one unreviewed segment makes the row unreviewed
- **Discovery** (affects run): graduation's auto: line ends · unknown <k> and is never earned when a window PR has no gh state; a stub or unit check without gh answers sees it
- **Question for Michael:** R2 review M7: should `harness memory .` (or `..`) read the project's own config for revisit, as a path does? Default kept: only an argument with a / is a path. Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-1/lib/memory.sh:72, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-1/docs/plans/2026-11-09-R2-review.md
- **Proposed change:** A later run: take any existing directory argument of harness memory as a path (M7), with a stub check of a project config on auto reading revisit
- *06-R2-03 · claude-opus-5-5*

### 2026-11-10 02:13 · R2-02 · passes

harness memory: held/failed columns (unreviewed for old rows or a review none), overrides (memoryOverride: merged against a fail / closed against a hold), review: tally, auto: line via graduation (8 PRs, 10 ops, 90 %, ≤1 override, revisit <80 % on auto); memreview.mjs line + heldFailed, noted once after both PR notes; fails_dropped; decision, docs.

- **Files:** lib/summary.mjs, lib/memreview.mjs, lib/memory.sh, lib/record.sh, bin/harness, tests/unit/summary.test.mjs, tests/unit/memreview.test.mjs, tests/checks/memory-review.sh, tests/checks/memory-branch.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, journal/decisions/2026-11-09-memory-graduation.md, +3 more
- **Verified:** unit tier 586/586; bash tests/run.sh memory-review memory-branch 61/61 (memory-review 28/28 120.8 s, memory-branch 32/32 129.4 s); a mutation run (note removed, overrides off) turned the two new stub checks red (26/28); fast tier green 1122; git diff --stat -- lib/notify.mjs empty
- **Tests:** 1992 → 1999
- **Discovery** (affects R2-03): memory.json and the facts row gain fails_dropped (true when auto's landing dropped the failed facts by verdict): a hand merge of such a PR is no override (review I2)
- **Discovery** (affects R2-03): memreview.mjs line prints nothing for reviewed 0 (memory_json writes review 'nothing to review' there, not ok); the note goes only on the path that reaches memory_json at memory_pr's end
- **Discovery** (affects R2-03): memory-review.sh now 120.8 s with memory-branch beside it (4 jobs); its tiers-table row (115.4) wants a re-time alone in R2-03
- **Discovery** (affects R2-03): harness memory <path> reads the policy via harness_config in a subshell; a bare name (no /) reads the user's config alone
- **Question for Michael:** Defaults recorded in decisions/2026-11-09-memory-graduation: the auto window must hold a full 8 reviewed facts PRs before earned; a review none reads unreviewed; an edited PR's override line reads 'closed against a hold' (the spec's two words); any declined row of the run exempts a closed PR of either tier; the rules tier's failed count shows in the memory: line only when one failed. Keep them? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-09/slot-1/journal/decisions/2026-11-09-memory-graduation.md
- **Proposed change:** R2-03 step 1's `grep -rn 'held ·' lib/` will also show record.sh's R1-02 counts note (`memory review: N reviewed · H held · F failed`, bash): heldFailed in memreview.mjs is the one JS renderer; the bash note stays by R2-02 step 3 (R1-02's counts note stays first)
- *05-R2-02 · claude-opus-5-5*

### 2026-11-10 01:49 · R2-01 · passes

memory.json gains review_cost_usd, review_s, review_model, reviewed_ids, failed_ids (facts/2:q2; verdicts now carry q); summary carries them; Memory row ends `review 3 held · 0 failed · $0.42 · 4 min`; run.log's memory review is a session, memory-review after curator in Spend by role/Time; memory.jsonl rows per tier; over-the-curator note; STUB_MEMORY_REVIEW_COST; decision, docs.

- **Files:** lib/summary.mjs, lib/record.sh, lib/driver.sh, lib/memreview.mjs, tests/stub-claude.sh, tests/checks/memory-review.sh, tests/checks/memory-branch.sh, tests/unit/summary.test.mjs, tests/unit/memreview.test.mjs, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, journal/decisions/2026-11-09-memory-graduation.md, +3 more
- **Verified:** unit tier 582/582; bash tests/run.sh memory-review 25/25 (115.9 s, red 21/25 first); curator-run 14/14; memory-branch 32/32; check.sh --fast green, 1118 tests; bash -n and node --check clean; lib/metrics.mjs untouched (MET cost reads the transcript)
- **Tests:** 1986 → 1992
- **Dead end:** asserting memory.json review_model == "opus" — F model resolves to the full claude-… id; the check compares it with the memory-review metrics row's model
- **Discovery** (affects R2-02, R2-03): memory.json now carries reviewed_ids and failed_ids (`facts/2:q2`, a bare id when not reviewed or thin); memory.jsonl rows carry per-tier reviewed/held/failed/failed_ids, merged_by on the facts row only (rules row always null), review_cost_usd in both
- **Discovery** (affects R2-02): memreview.mjs verdicts' ops now carry q (the failing row's question, else null): R2-02's line can print `, q<n>` from it instead of parsing the reason
- **Discovery** (affects R2-02): A summary with reviewed but no reviewed_ids (a run between R1 and R2) writes ledger rows with no review fields: R2-02 reads those as unreviewed
- **Discovery** (affects R2-02, R2-03): The stub curator and reviewer both cost $0.10 by default; STUB_MEMORY_REVIEW_COST sets the reviewer's (the mt run uses 2.5)
- *04-R2-01 · claude-opus-5-5*

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
