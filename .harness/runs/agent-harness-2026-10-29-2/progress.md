<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-10-29-2` (agent-harness)

What this file is: the run's journal, rendered by the harness from `entries.jsonl` after every session, newest entry first. Each entry says what one session did, how it verified it, what it tried that failed, and what it asks Michael.

The spec is `docs/specs/2026-10-28-reliability.md`: R1 fixes the flaky checks at their cause (tests wait on conditions, `tests/run.sh --repeat` reproduces a flake), R2 keeps a session's entry (validator as the last step, a long summary trimmed, one resume for a missing entry), R3 closes the lanes-review leftovers and adds two lint rules, R4 gives questions a place to wait in `harness needs`. R1, R2 and R3 run side by side on two lanes; R4 waits for R2.

How to read the feature list (`feature_list.json`): array order is priority; `after` names what a feature really waits on; `passes` flips only when every step holds. Plans: `docs/plans/2026-10-29-R<n>-*.md`; reviews: `docs/plans/2026-10-29-R<n>-review.md`.

To steer: edit `INBOX.md` in this directory on branch `harness/agent-harness-2026-10-29-2` (first line `status: pause` or `status: stop`; answers under `## Answers`). The harness pulls before every session. Questions sessions asked are in `harness needs <run>` once R4 lands; until then in the entries below.

### 2026-10-29 20:20 · R3-02 · passes

Attempt 2: the build from attempt 1 is unchanged. Verify R3 failed it only on the suite step: 39-memlint-m4 was red because Gotchas had 16 lines, and R3-01 has since fixed that. Rechecked every step: writeFileSync count 1, node --check ok, the N/M line is in initializer.md, 07 and 77 green (23/23), check-names sorted, memlint clean, full suite green (993).

- **Verified:** grep -c writeFileSync lib/features.mjs = 1; node --check lib/features.mjs; bash tests/run.sh 07-step-lint-pure-r3 77-leftovers: 23/23 checks passed; node lib/memlint.mjs . prints nothing; lib/check.sh: green, 993 tests (cached for this tree)
- **Tests:** 993 → 993
- *22-R3-02 · claude-opus-5-5*

### 2026-10-29 20:18 · R3-01 · passes

Verify R3 was red only on 39-memlint-m4: the R3 resolve kept both its {{X}} line and main's stub --resume line, so Gotchas had 16 lines. Dropped the stub --resume line (76-entries-survive checks that shape); memlint prints nothing. The plan file's steps 1-4 hold (spot-checked: sections, Minor 8 quote, unreproducible examples, N2 = 2 on origin main).

- **Files:** CLAUDE.md
- **Verified:** node lib/memlint.mjs . prints nothing (was CLAUDE.md:80 gotchas: 16 lines); lib/check.sh full suite green in 1014 s, 993 tests, 0 FAIL
- **Tests:** 993 → 993
- **Discovery** (affects run): A resolve that keeps both sides' Gotchas lines can push the section past 15 (the comment line counts): drop one in the resolve, or 39-memlint-m4 goes red
- **Resolved:** stub --resume of an unknown id swaps session_id but leaves 00000000-… in the result's errors[] (the CLI names the id)
- **Proposed change:** The resolve prompt could say: after keeping both sides of a ## Gotchas conflict, run node lib/memlint.mjs . (39-memlint-m4 lints the worktree's CLAUDE.md)
- *20-R3-01 · claude-opus-5-5*

### 2026-10-29 19:56 · R4-03 · passes

journal_ (lib/record.sh) now opens one question item per question of the entry it ingests (questions_: the filled text, asker, line, feature for coding), notes '<id>: <n> question(s) for Michael recorded (harness needs)' and sweeps at once when the entry has resolved. Stub learns STUB_ASK_TWO and STUB_ASK_AGAIN. 78 gains 5 stub-run checks.

- **Files:** lib/record.sh, tests/stub-claude.sh, tests/checks/78-needs-questions.sh, tests/fixtures/check-names.txt
- **Verified:** the 5 new checks failed before the change (7/12 in 78), 12/12 after; 38, 58, 59, 63 green (64/64); bash -n lib/record.sh tests/stub-claude.sh; full suite via lib/check.sh
- **Tests:** 984 → 989
- **Discovery** (affects R4-04, R4-05): 78's needs_fixture runs (q-*) are runs of proj: the stub runs rm them first, or a stub question of the same text (ASK_TWO's cache one is the fixture default) moves their item forward
- **Discovery** (affects R4-04): 78 runs four stub runs (qa ASK_TWO, qr ASK+AGAIN+RESOLVE=A, qm1/qm2 ASK=A), ~70 s; R4-04's no-notification check can reuse qa's curl.log instead of a fifth run
- **Proposed change:** R4-03 step 3 says STUB_RESOLVE=B; the check uses STUB_ASK=A STUB_ASK_AGAIN=B STUB_RESOLVE=A (A's second session, after M1's verify un-passes it, is the later entry), as the R4 plan's Proposed changes says. Its 'one open item with seen 2' is asserted on the one question item of that run (seen 2, in done/ by the end).
- *18-R4-03 · claude-opus-5-5*

### 2026-10-29 19:43 · verify R3 · not yet

Full suite RED: 39-memlint-m4 fails (memlint on this worktree prints `CLAUDE.md:80 gotchas: 16 lines, over 15`; the merge resolve kept both Gotchas lines). Every feature ends on the suite step, so all six fail. Other steps spot-checked hold.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| R3-01 | 1 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-01 | 2 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-01 | 3 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-01 | 4 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-01 | 5 | bash tests/run.sh (init full run + rerun of 39-memlint-m4); node lib/memlint.mjs . | 39-memlint-m4: 18/19, FAIL store lookup check; memlint prints CLAUDE.md:80 gotchas: 16 lines, over 15 | no |
| R3-02 | 1 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-02 | 2 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-02 | 3 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-02 | 4 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-02 | 5 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-02 | 6 | bash tests/run.sh (init full run + rerun of 39-memlint-m4); node lib/memlint.mjs . | 39-memlint-m4: 18/19, FAIL store lookup check; memlint prints CLAUDE.md:80 gotchas: 16 lines, over 15 | no |
| R3-03 | 1 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-03 | 2 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-03 | 3 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-03 | 4 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-03 | 5 | bash tests/run.sh (init full run + rerun of 39-memlint-m4); node lib/memlint.mjs . | 39-memlint-m4: 18/19, FAIL store lookup check; memlint prints CLAUDE.md:80 gotchas: 16 lines, over 15 | no |
| R3-04 | 1 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-04 | 2 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-04 | 3 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-04 | 4 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-04 | 5 | bash tests/run.sh (init full run + rerun of 39-memlint-m4); node lib/memlint.mjs . | 39-memlint-m4: 18/19, FAIL store lookup check; memlint prints CLAUDE.md:80 gotchas: 16 lines, over 15 | no |
| R3-05 | 1 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-05 | 2 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-05 | 3 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-05 | 4 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-05 | 5 | bash tests/run.sh (init full run + rerun of 39-memlint-m4); node lib/memlint.mjs . | 39-memlint-m4: 18/19, FAIL store lookup check; memlint prints CLAUDE.md:80 gotchas: 16 lines, over 15 | no |
| R3-06 | 1 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-06 | 2 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-06 | 3 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-06 | 4 | grep/node --check/bash -n spot checks; subset bash tests/run.sh 07-step-lint-pure-r3 77-leftovers 49-lanes-slots | files/greps present (writeFileSync count 1, docs/plans and decision files exist, README mentions, bash -n ok); subset suites 9/9 and 34/34 pass | yes |
| R3-06 | 5 | bash tests/run.sh (init full run + rerun of 39-memlint-m4); node lib/memlint.mjs . | 39-memlint-m4: 18/19, FAIL store lookup check; memlint prints CLAUDE.md:80 gotchas: 16 lines, over 15 | no |

- *194129-verify-R3 · claude-sonnet-5-5*

### 2026-10-29 19:24 · resolve R3 · passes

CLAUDE.md Gotchas: the lane added a line on {{X}} placeholders above {{SECTIONS}} in prompt templates (R3-04); main added one on stub --resume of an unknown id leaving 00000000-… in errors[] (R1-06). Independent facts, so both lines are kept, in their place; the section is at 15 lines, inside its limit. Doc-only, so no suite subset applies.

- **Files:** CLAUDE.md
- *192411-resolve-R3 · claude-opus-5-5*

### 2026-10-29 19:24 · R3-06 · passes

R3 review: 0 Critical, 2 Important, 7 Minor. Fixed: 58 read docs/specs (key-ignored) → fixture + guard check in 34; ignored_only's pathspec checked (77) and moved to treekey.mjs --pathspec, output not a pathspec list re-bases; cached rows in the suite-ran check; run_init's key once; writeAtomic cleanup. Decision lanes-leftovers, two in-place lines, architecture §4/§6/§12, README.

- **Files:** docs/plans/2026-10-29-R3-review.md, journal/decisions/2026-10-29-lanes-leftovers.md, journal/decisions/2026-10-27-review-gate.md, journal/decisions/2026-10-26-test-count-contract.md, docs/architecture.md, README.md, lib/record.sh, lib/treekey.mjs, lib/features.mjs, lib/driver.sh, tests/checks/34-check-key.sh, tests/checks/48-lanes-rebase.sh, +5 more
- **Verified:** Full suite: check: green in 1007 s, 980 tests (first full run red on 48-lanes-rebase, fixed; 40-run-18 flaked once, green on rerun). New checks seen red: 34 guard on 58; 77 ignored_only on a copy without literal and on an old treekey; 77 suite-ran 2x on a lane.sh without the cached filter.
- **Tests:** 978 → 980
- **Dead end:** ignored_only calling treekey.mjs --pathspec with no output check — a sourced shell with the live (older) HARNESS_HOME got a tree key back, a pathspec matching nothing, so a real main move read as ignored (48 red)
- **Discovery** (affects run): The suite must read nothing under CHECK_KEY_IGNORE paths (34's guard): a merge now skips its re-base on them; copy a spec's shape into tests/fixtures instead
- **Discovery** (affects run): lib/treekey.mjs --pathspec prints the key's pathspecs; ignored_only (lib/record.sh) uses them and takes only output starting with '.'
- **Discovery** (affects run): Promote item 'tests/lib.sh now holds tended, held…' still not on R3's branch (R1 not on origin main): left for a session with R1 in
- **Discovery** (affects run): 40-run-18-test-counts-m5 'a continued run refreshes tests-end' flaked once in a full run (green on the rerun)
- **Proposed change:** prompts/initializer.md still has folded reviews say 'an Opus subagent reviews the diff' while coding.md sends reviews to the session's own model: align the initializer's wording (pinned by 13/14-run-2 prefix checks, so a deliberate edit)
- *15-R3-06 · claude-opus-5-5*

### 2026-10-29 19:22 · R4-02 · passes

needs.mjs has the question reason: questionKey (fill and Files: lines cut, folded, 80 code points), open refreshes in the run (exit 3) or moves an open item forward from a sibling run (seen +1, asked_in, old in its done/), a warn card, the sweep resolves on a later entry's resolved (entries.mjs resolvedBy, shared with pack).

- **Files:** lib/needs.mjs, lib/entries.mjs, tests/checks/78-needs-questions.sh, tests/lib.sh, tests/checks/58-needs-record.sh, tests/checks/59-needs-cards.sh, tests/fixtures/needs/question.json, tests/fixtures/check-names.txt
- **Verified:** bash tests/run.sh 78-needs: 9/9 checks, each watched red first (0/7, then the 2 review fixes red); full suite via lib/check.sh green in 1006 s, 984 checks; node --check lib/needs.mjs lib/entries.mjs; 12 and 38 (pack resolved) green after the resolvedBy refactor
- **Tests:** 976 → 984
- **Discovery** (affects R4-03, R4-04): needs_fixture question (tests/lib.sh) puts every fixture run under one project proj: an open of the same text in another run moves it forward; give each its own NF_Q=<text>
- **Discovery** (affects R4-03): journal_ must pass the question as entries.jsonl stores it (filled): the sweep compares card.question.text with resolved items as pack does, and a pack-cut resolved copied from the filled words would not match the unfilled text
- **Discovery** (affects R4-03): An open with no line= is never resolved by the sweep (no later to tell): journal_ must pass line=<entries.jsonl line>
- **Discovery** (affects R4-04): A question item counts in harness status NEEDS YOU until R4-04 splits it out; nothing opens one before R4-03
- **Question for Michael:** The question key is the first 80 characters (R4-02 step 1). The review found two different questions with a shared preamble get one key: the memory run's M1-01 "Defaults taken in the plan (to be recorded in journal/decisions/2026-10-26-retro-backlog.md by M1-04): …" questions collide, so the second refreshes over the first and one resolved closes both. Default kept: 80 characters as specified. Should the key be a hash of the whole folded text instead (the move forward still works; a reworded question is then a new item)? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-2/slot-0/lib/needs.mjs:62, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29-2/slot-0/docs/plans/2026-10-29-R4-questions.md
- **Proposed change:** R4-05 review: the notification body and needs.md never show the asked row (record() builds body at seen 1); harmless while no question notifies, but needs.md could carry asked N times
- **Proposed change:** R4-05 review: a moved-forward run's needs.md (in the old run's record) stays stale until its next open, sweep or done (plan §2.4 accepts it)
- *17-R4-02 · claude-opus-5-5*

### 2026-10-29 18:52 · R4-01 · passes

Wrote docs/plans/2026-10-29-R4-questions.md: the question reason, a key that drops the harness's Files fill (worktree paths differ per run), refresh, the move forward through sibling state dirs, card and sweep rule (resolvedBy shared with pack), journal_'s questions_ after the ingest, readers, the skill step, 17 check names, needs_fixture question, STUB_ASK_TWO/AGAIN. No code changed.

- **Files:** docs/plans/2026-10-29-R4-questions.md
- **Verified:** check.sh green (cached, 976 tests; docs/plans is outside the key); R2 merged: grep -c harness-merge/agent-harness-2026-10-29-2-R2 on origin/main = 1
- **Tests:** 976 → 976
- **Discovery** (affects R4-02): Adding a reason turns 58 (REASONS table literal, '15 reasons' in its name) and 59 (one fixture per reason in tests/fixtures/needs, FILLED's parked-only .question) red: plan §2.6 lists the edits
- **Discovery** (affects R4-03): In a default stub run only A (verify un-passes it) and C (BROKEN first) get a second coding session: STUB_RESOLVE=A, not B, resolves STUB_ASK=A's question after STUB_ASK_AGAIN=B
- **Discovery** (affects R4-02, R4-03): entries.jsonl questions carry the fill ' Files (harness, from the session): <abs paths>': a key over the raw first 80 characters would differ per run for a short question; questionKey cuts it (entries.mjs unfilled, to export)
- **Discovery** (affects R4-04): status line stays 'NEEDS YOU <n> · harness needs' (53 pins it): with questions it reads 'NEEDS YOU 1 · 3 questions · harness needs'
- **Resolved:** tests/lib.sh now holds tended, held (clears vwait-* too), ats and debriefs: a check file must not redefine them differently
- **Proposed change:** R4-03 step 3: use STUB_ASK=A STUB_ASK_AGAIN=B STUB_RESOLVE=A (A's second session after M1's verify is later than B's entry); STUB_RESOLVE=B names B's question and B has no later session
- **Proposed change:** R4-04 step 2: the status line is 'NEEDS YOU 1 · 3 questions · harness needs' (the hint stays); the check matches the prefix
- *16-R4-01 · claude-opus-5-5*

### 2026-10-29 18:35 · R3-05 · passes

Two checks, no lib/bin change: 49's sp block runs gc --dry-run with a clean leftover slot (lanes/sp/slot-1) and the merged harness-lane/sp/M1 on origin (one would: line each, both kept; the real gc then removes the slot). 77 starts two merge_milestones M1 at once on one state and clone: one note, one pr merge. Both green at once; each fails when what it guards is broken.

- **Files:** tests/checks/49-lanes-slots.sh, tests/checks/77-leftovers.sh, tests/fixtures/check-names.txt, CLAUDE.md
- **Verified:** bash tests/run.sh 77-left 49-lanes: 19/19. Mutations, reverted: rm_wt's dry branch also removing the worktree → 'FAIL gc --dry-run names a leftover slot…' (8/11); merge_milestones without flock 8 → 'FAIL merge_milestones: two at once merge M1 once…' (7/8), green again with it. Full suite via lib/check.sh: green in 956 s, 978 tests, no rerun.
- **Tests:** 976 → 978
- **Dead end:** the first concurrent check counted '· M1 merged into main' lines only — without the lock it still passed: the second call lost git's ref lock on the harness-merge push and noted 'push of harness-merge/mm-M1 failed'; the check now requires the merged note to be the log's one line
- **Discovery** (affects R3-06): No bug: gc --dry-run's slot and lane-branch passes print would: lines only, and merge.lock serializes two merge_milestones (the second finds merged-M1 silently)
- **Discovery** (affects R3-06): Without merge.lock two merge_milestones on one clone race on the harness-merge push (ref lock) or note 'already there': the lock is what keeps the note single
- **Discovery** (affects run): Promote item 'tests/lib.sh now holds tended, held…' does not hold on R3's branch (R1-07's lib.sh is not merged here; 47/48/49/76/77-resolve define held and ats themselves): left for a session on a branch with R1 in
- **Resolved:** A {{X}} above {{SECTIONS}} in a prompt template turns 08/13/14/15's byte-identical-prefix check red once two sessions' values differ: session values go under This session
- **Proposed change:** R3-05 step 1 names $T/wt/proj/<run>-slots/slot-1; slots live at $T/wt/proj/lanes/<run>/slot-<k> (the check uses lanes/sp/slot-1, as the R3 plan says)
- **Proposed change:** Gotchas: the 'stub --resume of an unknown id…' line was replaced by the {{SECTIONS}} line (the section was at 15 with its comment)
- *14-R3-05 · claude-opus-5-5*

### 2026-10-29 18:33 · verify R1 · passes

All 7 R1 features hold. Suite green (one rerun for 46 flake); --repeat 10 gave 10/10 green on 44, 46, 48, 15, 28, 32, 38, 08; lint exits 0; docs, plan, review and decision present. Note: N2 is now on origin main (count 2), plan line says 1 as of init.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| R1-01 | 1 | read the file/doc named in the step; grep/bash -n/lint | present and matches: plan, review with Simplifications, decision with rejected list, arch §7 row, README --repeat line, lint-sleeps exits 0, seq grep 0, bash -n ok | yes |
| R1-01 | 2 | read the file/doc named in the step; grep/bash -n/lint | present and matches: plan, review with Simplifications, decision with rejected list, arch §7 row, README --repeat line, lint-sleeps exits 0, seq grep 0, bash -n ok | yes |
| R1-01 | 3 | read the file/doc named in the step; grep/bash -n/lint | present and matches: plan, review with Simplifications, decision with rejected list, arch §7 row, README --repeat line, lint-sleeps exits 0, seq grep 0, bash -n ok | yes |
| R1-01 | 4 | read the file/doc named in the step; grep/bash -n/lint | present and matches: plan, review with Simplifications, decision with rejected list, arch §7 row, README --repeat line, lint-sleeps exits 0, seq grep 0, bash -n ok | yes |
| R1-01 | 5 | harness init full suite (check.sh) | green after a rerun (46-lanes-continue flaked once), 976 tests; 46 then 10/10 green under --repeat | yes |
| R1-02 | 1 | read the file/doc named in the step; grep/bash -n/lint | present and matches: plan, review with Simplifications, decision with rejected list, arch §7 row, README --repeat line, lint-sleeps exits 0, seq grep 0, bash -n ok | yes |
| R1-02 | 2 | read the file/doc named in the step; grep/bash -n/lint | present and matches: plan, review with Simplifications, decision with rejected list, arch §7 row, README --repeat line, lint-sleeps exits 0, seq grep 0, bash -n ok | yes |
| R1-02 | 3 | read the file/doc named in the step; grep/bash -n/lint | present and matches: plan, review with Simplifications, decision with rejected list, arch §7 row, README --repeat line, lint-sleeps exits 0, seq grep 0, bash -n ok | yes |
| R1-02 | 4 | read the file/doc named in the step; grep/bash -n/lint | present and matches: plan, review with Simplifications, decision with rejected list, arch §7 row, README --repeat line, lint-sleeps exits 0, seq grep 0, bash -n ok | yes |
| R1-02 | 5 | git diff origin/main -- tests/fixtures/check-names.txt \| grep "^-[^-]" | no removed lines | yes |
| R1-02 | 6 | harness init full suite (check.sh) | green after a rerun (46-lanes-continue flaked once), 976 tests; 46 then 10/10 green under --repeat | yes |
| R1-03 | 1 | read the file/doc named in the step; grep/bash -n/lint | present and matches: plan, review with Simplifications, decision with rejected list, arch §7 row, README --repeat line, lint-sleeps exits 0, seq grep 0, bash -n ok | yes |
| R1-03 | 2 | read the file/doc named in the step; grep/bash -n/lint | present and matches: plan, review with Simplifications, decision with rejected list, arch §7 row, README --repeat line, lint-sleeps exits 0, seq grep 0, bash -n ok | yes |
| R1-03 | 3 | read the file/doc named in the step; grep/bash -n/lint | present and matches: plan, review with Simplifications, decision with rejected list, arch §7 row, README --repeat line, lint-sleeps exits 0, seq grep 0, bash -n ok | yes |
| R1-03 | 4 | git diff origin/main -- tests/fixtures/check-names.txt \| grep "^-[^-]" | no removed lines | yes |
| R1-03 | 5 | harness init full suite (check.sh) | green after a rerun (46-lanes-continue flaked once), 976 tests; 46 then 10/10 green under --repeat | yes |
| R1-04 | 1 | bash tests/run.sh --repeat 10 <files>; read plan table rows | --repeat 10 44, 46, 48: 10/10 green each; table rows carry cause, fix, before → after | yes |
| R1-04 | 2 | read plan table and decision, repeat runs above | --repeat 10 44, 46, 48: 10/10 green each; fix in lib/driver.sh:542-563 (alive==0 and lanes_open==0) with forced check in 45; hold env documented | yes |
| R1-04 | 3 | read plan table and decision, repeat runs above | --repeat 10 44, 46, 48: 10/10 green each; fix in lib/driver.sh:542-563 (alive==0 and lanes_open==0) with forced check in 45; hold env documented | yes |
| R1-04 | 4 | bash tests/run.sh --repeat 10 <files>; read plan table rows | --repeat 10 44, 46, 48: 10/10 green each; table rows carry cause, fix, before → after | yes |
| R1-04 | 5 | git diff origin/main -- tests/fixtures/check-names.txt \| grep "^-[^-]" | no removed lines | yes |
| R1-04 | 6 | harness init full suite (check.sh) | green after a rerun (46-lanes-continue flaked once), 976 tests; 46 then 10/10 green under --repeat | yes |
| R1-05 | 1 | bash tests/run.sh --repeat 10 <files>; read plan table rows | --repeat 10 15 and 28: 10/10 green each; table rows carry cause, fix, before → after | yes |
| R1-05 | 2 | read plan table and decision, repeat runs above | --repeat 10 15 and 28: 10/10 green each; fix in lib/driver.sh:542-563 (alive==0 and lanes_open==0) with forced check in 45; hold env documented | yes |
| R1-05 | 3 | read plan table and decision, repeat runs above | --repeat 10 15 and 28: 10/10 green each; fix in lib/driver.sh:542-563 (alive==0 and lanes_open==0) with forced check in 45; hold env documented | yes |
| R1-05 | 4 | bash tests/run.sh --repeat 10 <files>; read plan table rows | --repeat 10 15 and 28: 10/10 green each; table rows carry cause, fix, before → after | yes |
| R1-05 | 5 | harness init full suite (check.sh) | green after a rerun (46-lanes-continue flaked once), 976 tests; 46 then 10/10 green under --repeat | yes |
| R1-06 | 1 | bash tests/run.sh --repeat 10 <files>; read plan table rows | --repeat 10 32, 38, 08: 10/10 green each; table rows carry cause, fix, before → after | yes |
| R1-06 | 2 | read plan table and decision, repeat runs above | --repeat 10 32, 38, 08: 10/10 green each; fix in lib/driver.sh:542-563 (alive==0 and lanes_open==0) with forced check in 45; hold env documented | yes |
| R1-06 | 3 | read plan table and decision, repeat runs above | --repeat 10 32, 38, 08: 10/10 green each; fix in lib/driver.sh:542-563 (alive==0 and lanes_open==0) with forced check in 45; hold env documented | yes |
| R1-06 | 4 | bash tests/run.sh --repeat 10 <files>; read plan table rows | --repeat 10 32, 38, 08: 10/10 green each; table rows carry cause, fix, before → after | yes |
| R1-06 | 5 | harness init full suite (check.sh) | green after a rerun (46-lanes-continue flaked once), 976 tests; 46 then 10/10 green under --repeat | yes |
| R1-07 | 1 | read the file/doc named in the step; grep/bash -n/lint | present and matches: plan, review with Simplifications, decision with rejected list, arch §7 row, README --repeat line, lint-sleeps exits 0, seq grep 0, bash -n ok | yes |
| R1-07 | 2 | read the file/doc named in the step; grep/bash -n/lint | present and matches: plan, review with Simplifications, decision with rejected list, arch §7 row, README --repeat line, lint-sleeps exits 0, seq grep 0, bash -n ok | yes |
| R1-07 | 3 | read the file/doc named in the step; grep/bash -n/lint | present and matches: plan, review with Simplifications, decision with rejected list, arch §7 row, README --repeat line, lint-sleeps exits 0, seq grep 0, bash -n ok | yes |
| R1-07 | 4 | read the file/doc named in the step; grep/bash -n/lint | present and matches: plan, review with Simplifications, decision with rejected list, arch §7 row, README --repeat line, lint-sleeps exits 0, seq grep 0, bash -n ok | yes |
| R1-07 | 5 | read the file/doc named in the step; grep/bash -n/lint | present and matches: plan, review with Simplifications, decision with rejected list, arch §7 row, README --repeat line, lint-sleeps exits 0, seq grep 0, bash -n ok | yes |
| R1-07 | 6 | harness init full suite (check.sh) | green after a rerun (46-lanes-continue flaked once), 976 tests; 46 then 10/10 green under --repeat | yes |

- *174535-verify-R1 · claude-sonnet-5-5*

### 2026-10-29 18:10 · R3-04 · passes

check.sh appends <epoch.µs> <full|subset|cached> <s> to $HARNESS_SCRATCH/check-runs.log; lane.sh stamps around session coding and notes '<id>: suite ran <n>x (<s> s) in the session'. Reviews go to subagents on the session's model ({{MODEL}}, HARNESS_MODEL; prompt.sh fills the feature's). The review gate un-passes before the record flip, row and passes= note. 4 checks.

- **Files:** lib/check.sh, lib/lane.sh, lib/prompt.sh, prompts/coding.md, tests/stub-claude.sh, tests/checks/77-leftovers.sh, tests/checks/42-run-20-review-gate-rounds-m6.sh, tests/fixtures/check-names.txt
- **Verified:** tests/run.sh 77-leftovers 7/7 and 42-run-20 12/12 after watching the 4 new checks fail; full suite (lib/check.sh) green after a rerun, 976 tests: 08-scope flaked in all three full runs, a different check each time (gatestop, lane count, ledger row), green on the third run's rerun; Opus review: 0 Critical, 0 Important, 2 Minor (both fixed)
- **Tests:** 972 → 976
- **Dead end:** {{MODEL}} in §2's review sentence (the plan's wording) — §2 is the static part above {{SECTIONS}}: 08's 'two coding prompts share a byte-identical prefix' check went red (demo's A and B run on different models; decisions/2026-10-21-static-first-prompts). §2 now says 'on your own model (named under *This session*)' and the sentence with `{{MODEL}}` is a This session line
- **Dead end:** second-resolution stamps (date +%s) as the plan's awk had them — a run_init row ending in t0's second counts toward the session (>=), or a quick stub call is missed (>); rows and stamps are date +%s.%6N (a dot in any locale) with strict bounds
- **Discovery** (affects project): A {{X}} above {{SECTIONS}} in a prompt template turns 08/13/14/15's byte-identical-prefix check red once two sessions' values differ: session values go under This session
- **Discovery** (affects R3-06, run): 08-scope flaked twice in this session's full runs (gatestop memory gate; M2's lane never started, 2/3 passing): R1-06's fixes (HARNESS_COUNT_HOLD, gatestop at 2 GB) are not on this lane's base
- **Discovery** (affects R3-06): An escalated review's first metrics row, passes= note and 'HARNESS: after R' commit now say passes=false (were true)
- **Proposed change:** R3-04 step 2: the model id is in the This session review line, not §2 (static-first-prompts); R3-06's decision file should say so and add an in-place line to decisions/2026-10-21-static-first-prompts if wanted
- **Proposed change:** R3-06: architecture §4 (state: $SCRATCH/check-runs.log) and the README should name the suite ran note; summary.json has no 'review round pending' cause (plan §9)
- *13-R3-04 · claude-opus-5-5*

### 2026-10-29 17:09 · R1-07 · passes

R1 review: 0 Critical, 2 Important, 5 Minor. Fixed: opens no longer reopen an exited unreaped lane (MAX_LANES≥2), STUB_BARRIER check proves the hold, settle waits on this copy's debriefs only, wait_for refuses fractional limits, --repeat check exact. Helpers moved to lib.sh. Decision tests-wait-not-sleep, arch §5/§7/§15, README Tests, flaker table done.

- **Files:** lib/driver.sh, tests/lib.sh, tests/stub-claude.sh, tests/checks/45-lanes-run.sh, tests/checks/75-suite-tools.sh, tests/checks/31-tmux-l3-03-when.sh, tests/checks/47-lanes-two.sh, tests/checks/48-lanes-rebase.sh, tests/checks/49-lanes-slots.sh, tests/checks/69-same-project-starts.sh, tests/checks/76-resolve-session.sh, tests/checks/77-resolve-fallbacks.sh, +7 more
- **Verified:** full suite via check.sh: green in 857 s, 976 tests; then the six files that read the docs (07 08 12 70 76 77) 200/200 after the last doc edit. Each new check seen red first: 45's forced lane-kill (M1 reopened, run done) → green (lane M1 closed (lane exited unexpectedly), needs-M1); 75's barrier, fractional wait_for and settle checks red then green. 13-run-2 --repeat 10: 10/10 green, 718 s.
- **Tests:** 973 → 976
- **Dead end:** settle check with the foreign debrief's HARNESS_STATE under $T/elsewhere — it starts with $T/ too, so the filter kept it; the foreign state must be outside $T
- **Discovery** (affects run): The coordinator's opens skip a milestone whose lanes/<m>/pid is still there (exited, unreaped); HARNESS_COUNT_HOLD leaves state/count-hold while holding, so a check can act inside the window
- **Discovery** (affects run): 13-run-2-michael-sets-desk (harness desk --list) not reproduced: --repeat 10 was 10/10 green, 718 s
- **Discovery** (affects project): tests/lib.sh now holds tended, held (clears vwait-* too), ats and debriefs: a check file must not redefine them differently
- **Proposed change:** Left from the review (Minor): HARNESS_COUNT_HOLD is unbounded and serialises lanes under MAX_LANES=2; tests-only, so left as is
- *12-R1-07 · claude-opus-5-5*

### 2026-10-29 16:52 · R3-03 · passes

merge_one: ignored_only lets a main moved only in cache-ignored paths merge as verified, no re-base, noted once per main. finish: ledger and scratch_done after record_pr, plus a 'ledger notes' commit. run_init pins tests-start and testcount-source only from a green suite, read from the tree's marker or check-<key>.out (never a stale check.out). STUB_FIX_BROKEN; 3 checks in 77-leftovers.

- **Files:** lib/record.sh, lib/driver.sh, tests/stub-claude.sh, tests/checks/77-leftovers.sh, tests/fixtures/check-names.txt
- **Verified:** 77-leftovers 4/4 (3 new, each red at HEAD first: re-base noted, no record PR in the ledger copy, no-match note); 40, 50, 66 green; full suite via check.sh green, 972 tests, 74-flakes-run flaked once (green 3 times after); bash -n on all touched files
- **Tests:** 969 → 972
- **Dead end:** STUB_MAIN_TOUCH=A:.harness/runs/other/x.md (step 1 as written) — the lane merges main in before its verify (sync_main), so merge_one never sees a moved main: green at HEAD. verify-M1:<path> lands it after the verify and is red at HEAD (M1 re-based)
- **Discovery** (affects R3-05, run): To test a main that moved after a milestone's verify, use STUB_MAIN_TOUCH=verify-<m>:<path>: a touch in a coding session is merged into the lane before the verify
- **Discovery** (affects R3-06): finish now writes the ledger after record_pr: a hung gh in record_pr leaves the run without a ledger copy or runs.jsonl line (reviewer Minor 4, accepted with the plan's order)
- **Discovery** (affects R3-06): A run whose suite is never green writes neither testcount-source nor testcount-nomatch: the report's tests are ? with no harness-log line saying why (reviewer Minor 5)
- **Proposed change:** R3-03 step 1 should name STUB_MAIN_TOUCH=verify-M1:.harness/runs/other/x.md, not A:… (A's touch is merged into the lane before the verify)
- **Proposed change:** R3-06's decision: the ignored-paths note reads '<m>: main changed only in ignored paths (<paths>); merging as verified', once per main (STATE/ignored-<m>), since it comes before the push and PR
- *11-R3-03 · claude-opus-5-5*

### 2026-10-29 16:33 · R1-06 · passes

32, 38 and 08's first `no user systemd` check were R1-04's lane-count race: 10/10 green unforced, red forced on the pre-fix driver. Their runs now start with HARNESS_COUNT_HOLD=1 (red 0/1 before). 08's repeat (7/10) found two test races, fixed: the gatestop run kept at 2 GB (STOP and the memory write raced the gate's poll) and a per-copy init_left for the box-wide pgrep. All 10/10 after.

- **Files:** tests/checks/32-l5-queue-runner-re.sh, tests/checks/38-run-17-gotchas-and-pack-m3.sh, tests/checks/08-scope-sh-l1-02-run-capped-services-gc-scratch.sh, docs/plans/2026-10-29-R1-flakes.md, journal/decisions/2026-10-29-lane-count-end-check.md, CLAUDE.md
- **Verified:** Before (direct, KEEP=1, the three at once): `32-l5-queue-runner-re: 10/10 green` 342 s; `38-run-17-gotchas-and-pack-m3: 10/10 green` 342 s; `08-scope-sh-l1-02-run-capped-services-gc-scratch: 7/10 green` 1075 s (copies 2, 5 memory gate stop; copy 3 TERM during an init). Forced (HARNESS_COUNT_HOLD=1, end check reverted in a scratch copy): 32 FAIL `MAX_PARALLEL_RUNS 2 → 1 …` (l5a/l5b: `no feature left to try: 2/3 passing`), 38 FAIL `CONTEXT_PACK_BYTES=1024 …` (packs 01-A 02-B 03-A only), 08 FAIL `no user systemd: the run goes bare …`. Edited files on the pre-fix driver: 32 `0/1 green`, 38 `0/1 green`, 08 FAIL bare only (gatestop and initterm green with a foreign `sleep 31` loop); old 08 on the fixed driver with `sleep 2` between STOP and the cp and the foreign loop: FAIL gatestop + initterm. After: `32-l5-queue-runner-re: 10/10 green` 330 s, `38-run-17-gotchas-and-pack-m3: 10/10 green` 328 s, `08-scope-sh-l1-02-run-capped-services-gc-scratch: 10/10 green` 809 s. check.sh: green in 934 s, 973 tests; check-names.txt vs origin/main: added lines only (0 removed); lint-sleeps clean; bash -n on the three files.
- **Tests:** 973 → 973
- **Discovery** (affects R1-07, run): Every stub run is M1 (A, B) then M2 (C, after M1): any check on a run's 3/3, M2's tag or its packs can hit R1-04's lane-count race; HARNESS_COUNT_HOLD=1 on that start holds the window every time
- **Discovery** (affects R1-07, run): pgrep in a check is box-wide (sibling copies, other lanes' suites): match this copy's process by grep -zqF "HARNESS_SCRATCH=$T/" /proc/<pid>/environ (08's init_left)
- **Discovery** (affects R1-07): mem_gate (lib/scope.sh:127-130) checks memory, then stop, every HARNESS_MEM_POLL (1 s in tests): a check that writes both must not let a poll fall between them
- **Discovery** (affects R1-07): A forced copy built with git archive has no .git: its 'ledger row has harness_version and harness_dirty' fails there, not on the tree
- **Resolved:** stub --resume of an unknown id substitutes session_id but leaves the fixture's 00000000-… id in the result line's errors[] (the real CLI names the asked id there)
- **Proposed change:** R1-07: the flaker table now has every row; the race's checks share one fix (44's), so the review can name HARNESS_COUNT_HOLD=1 on a check's start as the pattern for any stub run that must reach M2
- *10-R1-06 · claude-opus-5-5*

### 2026-10-29 16:14 · R3-02 · passes

lib/features.mjs: every list/attempts/parked write goes through writeAtomic (<file>.<pid>.tmp + renameSync; namespace import, so grep -c writeFileSync = 1). lint gains unit-collision (LANEU mapping, one finding per colliding milestone) and unreproducible (time bounds, one run's test counts, this run's check.out). initializer.md states counts as commands. 5 checks in 07, 1 in new 77-leftovers.sh.

- **Files:** lib/features.mjs, prompts/initializer.md, tests/checks/07-step-lint-pure-r3.sh, tests/checks/77-leftovers.sh, tests/fixtures/check-names.txt
- **Verified:** Red first: 77's reader threw 'Unexpected end of JSON input' at HEAD's in-place write; 07's four new checks failed. Then 07 14/14, 77 1/1; full suite green after the rerun guard's one rerun (969 tests; 08-scope and 48-lanes-rebase flaked under load average ~21, wall 1237 s). features.mjs lint on this run's list: unreproducible on R1-02 step 4 (below 5 s), R3-01 step 3, R3-02 step 3, as the plan predicted. Final full run on the committed tree (a4c864c): green in 949 s, 969 tests, no rerun.
- **Tests:** 963 → 969
- **Dead end:** the plan's COUNT regex with tests?/checks? singular — it hit R1-02 step 4's command `wait_for 30 test -f <file>`; plural only now, and that string is a not-flagged case in 07
- **Dead end:** a comment on the namespace import naming writeFileSync — the step's grep -c counts lines, comments too: it printed 2
- **Discovery** (affects R3-06, run): 13/14-run-2 pin the initializer's lint sentence ending `milestone's size doesn't call for). No output means clean.`: a new lint item goes before the review one
- **Discovery** (affects R3-06): README/architecture lint lists don't name unit-collision or unreproducible yet: R3-06's docs item
- **Discovery** (affects R1-07, run): Under this box's load (~21) the full suite took 1237 s and 08-scope and 48-lanes-rebase (a non-fast-forward push to origin main) flaked once each, green on the rerun
- **Proposed change:** R3-02 step 3's not-flagged list could add `wait_for 30 test -f <file>` (a command, not a count): 07 checks it
- *09-R3-02 · claude-opus-5-5*

## Older entries (in full in progress-archive.md)

- 2026-10-29 15:41 · R1-05 · passes · Both run flakers are R1-04's lane-count race. Neither reproduced unforced (10/10 green each). Forced… ([in full](progress-archive.md))
- 2026-10-29 15:29 · R3-01 · passes · Wrote docs/plans/2026-10-29-R3-leftovers.md: one section per R3 item with its function, file at 53bd… ([in full](progress-archive.md))
- 2026-10-29 14:56 · verify R2 · passes · All 28 steps of R2-01..05 hold. Suite 963/963 (full, this tree), subsets 76/12/05/16/18/25 52/52. Re… ([in full](progress-archive.md))
- 2026-10-29 14:50 · verify R2 · passes · All five R2 features hold: full suite green (963 tests), 76-entries-survive 18/18, journal and metri… ([in full](progress-archive.md))
- 2026-10-29 14:32 · R1-04 · passes · The lanes flakes (44, 46, 48, and 45's also-seen) were one coordinator race in lib/driver.sh: a lane… ([in full](progress-archive.md))
- 2026-10-29 14:31 · resolve R2 · passes · CLAUDE.md Gotchas: lane reworded the stub-runs line and added the 399+… cut fact; main added the mer… ([in full](progress-archive.md))
- 2026-10-29 14:29 · R2-05 · passes · 0 Critical, 3 Important, 8 Minor. One Opus round on R2.diff. Fixed RED→GREEN: a result-less resume's… ([in full](progress-archive.md))
- 2026-10-29 13:33 · R1-03 · passes · tests/lint-sleeps.sh lists each sleep line lacking '# sleep-ok:' (default tests/checks/*.sh + tests/… ([in full](progress-archive.md))
- 2026-10-29 13:27 · R2-04 · passes · entry_resume (lib/record.sh), from journal before the ingest, outside the lock: a coding/verify/init… ([in full](progress-archive.md))
- 2026-10-29 12:50 · R1-02 · passes · Attempt 2 of R1-02: the code from c319ca4 was right; the suite was red only on 39-memlint-m4, becaus… ([in full](progress-archive.md))
- 2026-10-29 10:48 · R2-03 · passes · Stub: each headless session prints first.jsonl's init line with a fresh session_id (kept in $STUB_DI… ([in full](progress-archive.md))
- 2026-10-29 10:23 · R2-02 · passes · Entry check: prompt_env exports HARNESS_ENTRY_CHECK; the coding, verify and init prompts end by runn… ([in full](progress-archive.md))
- 2026-10-29 10:16 · R1-02 · passes · tests/lib.sh gains wait_for (clock-bounded 0.1 s poll), stub_wait/stub_go; in_has, settle's poll and… ([in full](progress-archive.md))
- 2026-10-29 10:01 · R2-01 · passes · Attempt 1's plan (docs/plans/2026-10-29-R2-entries.md) holds every step; the suite was red only beca… ([in full](progress-archive.md))
- 2026-10-29 09:58 · R1-01 · passes · Wrote docs/plans/2026-10-29-R1-flakes.md: the four tools (wait_for, stub_wait/stub_go + STUB_BARRIER… ([in full](progress-archive.md))
- 2026-10-29 09:19 · R2-01 · passes · Wrote docs/plans/2026-10-29-R2-entries.md: the entry check, the trim (399 + … so readEntries keeps i… ([in full](progress-archive.md))
- 2026-10-29 09:12 · init · passes · 23 features: R1 7 (plan, wait_for/barriers/--repeat, sleep lint, three flaker groups, review), R2 5 … ([in full](progress-archive.md))
