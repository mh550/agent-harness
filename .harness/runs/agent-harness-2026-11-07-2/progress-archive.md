<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-07-2` (agent-harness)

What this file is: the run's journal, rendered by the harness from `entries.jsonl`, newest entry first (the 15 newest in full; every entry is in `progress-archive.md`). Each entry is one session: its feature, outcome, summary, what it tried, what it found.

The run builds the memory curator of `docs/specs/2026-11-07-memory-curator.md`, three milestones in series: **M1** a coding session's `CLAUDE.md` edit is reverted (`restrict … memory`) and facts go in the entry; **M2** an Opus `curator` session emits itemized operations (`memory-ops.json`) that the driver validates, tiers and applies on `harness-memory/<run>` behind a `memory: <run>` PR; **M3** `memlint-self` retires, `MEMORY_POLICY=pr|auto|off`, acceptance counted (`summary.memory`, the `Memory` row, `harness memory`).

How to read the feature list: `feature_list.json` is in priority order; a feature runs when it isn't passing and its `after` all pass. Each milestone's plan feature writes `docs/plans/2026-11-07-M<n>-….md`; the last feature of each milestone is its review (M1's is folded into M1-03). When every feature of a milestone passes the harness verifies it and opens its PR against `main` (`MERGE_POLICY=pr`).

How to steer: edit `INBOX.md` in this directory from the phone or `harness answer`. A line `status: stop <why>` or `status: pause` on top stops or pauses the run; answers to questions go under `## Answers`; a brief under the steering comment changes scope for the next session. Open questions are listed under the entries that asked them and in `harness needs`.

### 2026-11-07 13:30 · verify M2 · passes

All five M2 features hold: full suite green (1775), unit 477/477, curator-run/memory-branch/lanes-record-pr/retro-backlog/verify-retro-read-only 51/51, syntax checks pass, docs/decision/review present, 47 names within budget 60.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M2-01 | 1 | grep '^#' docs/plans/2026-11-07-M2-curator.md | plan sections/skeleton present as described; budget 60 section exists | yes |
| M2-01 | 2 | read plan 'memory-ops.json' section | plan sections/skeleton present as described; budget 60 section exists | yes |
| M2-01 | 3 | wc -l tests/fixtures/memory/headings.txt; head -3 | plan sections/skeleton present as described; budget 60 section exists | yes |
| M2-01 | 4 | read plan 'Applying' section; ls tests/fixtures/memory | plan sections/skeleton present as described; budget 60 section exists | yes |
| M2-01 | 5 | read plan 'driver's flow' | plan sections/skeleton present as described; budget 60 section exists | yes |
| M2-01 | 6 | read plan prompt draft | plan sections/skeleton present as described; budget 60 section exists | yes |
| M2-01 | 7 | grep '^-' journal/decisions/2026-11-07-memory-tiers.md | plan sections/skeleton present as described; budget 60 section exists | yes |
| M2-01 | 8 | init.out: full suite | full suite green 676 s, 1775 tests | yes |
| M2-02 | 1 | node --test --test-isolation=none tests/unit/*.test.mjs | 477 tests, 477 pass, fail 0 incl. curator.mjs tests | yes |
| M2-02 | 2 | node --check lib/curator.mjs; grep -c 'slice(0, 40)' lib/curator.mjs | syntax ok; grep prints 0; exports tierOf etc present | yes |
| M2-02 | 3 | head headings.txt; ls tests/fixtures/memory | 64 lines, 3-column, source line first; harm fixtures present | yes |
| M2-02 | 4 | read prompts/curator.md; curator-run.sh:33 renders prompt-curator.md | placeholders RUN_ID/PROJECT/RUN_DIR; rendered-prompt check passes in curator-run | yes |
| M2-02 | 5 | unit run + init full suite | fail 0; suite green | yes |
| M2-03 | 1 | bash tests/run.sh curator-run | curator-run checks all PASS | yes |
| M2-03 | 2 | read lib/driver.sh:265-289,389; lib/config.sh:42,58; summary.mjs; bash -n; node --check | curator() after retro before record_pr; MEMORY_POLICY=pr, CURATOR_MODEL=opus; summary counts curator; syntax ok | yes |
| M2-03 | 3 | read tests/stub-claude.sh:433; curator-run.sh:33 | stub branch exists; prompt check passes | yes |
| M2-03 | 4 | bash tests/run.sh curator-run lanes-record-pr retro-backlog verify-retro-read-only memory-branch | 51/51 checks passed | yes |
| M2-03 | 5 | init full suite | suite green | yes |
| M2-04 | 1 | bash tests/run.sh memory-branch (file renamed from memory-pr.sh by M2-05) | 15/15 pass incl. one commit, body, record PR opens, cap refusal, anchor evict, continue reuse | yes |
| M2-04 | 2 | read lib/record.sh memory_pr/driver.sh:285; bash -n | memory_pr present, scratch worktree, never forced; syntax ok | yes |
| M2-04 | 3 | memory-branch checks on notes and memory.json | notes check PASS; memory.json counts | yes |
| M2-04 | 4 | read decision choice section | choice section records as built | yes |
| M2-04 | 5 | bash tests/run.sh memory-branch curator-run lanes-record-pr | 51/51 checks passed | yes |
| M2-04 | 6 | init full suite | suite green | yes |
| M2-05 | 1 | read docs/plans/2026-11-07-M2-review.md | three questions answered with file/line; 0 Critical, 4 Important, 6 Minor | yes |
| M2-05 | 2 | review findings table; unit 477 pass; bash -n/node --check | 4 Important fixed with tests; syntax ok | yes |
| M2-05 | 3 | read decision: Finding, Choice, Rejected, invariants, Checks | all sections present incl. rejected and two invariants | yes |
| M2-05 | 4 | grep architecture.md and README.md for curator/memory-ops/MEMORY_POLICY | §3,§4,§5,§7,§8,§10 and README paragraph present | yes |
| M2-05 | 5 | git diff base -- check-names.txt \| grep -c '^+[^+]' / '^-[^-]' | 47 added, 0 removed, within 60; reason in decision | yes |
| M2-05 | 6 | init.out | green 676 s, 1775 tests | yes |

- *132857-verify-M2 · claude-sonnet-5-5*

### 2026-11-07 13:17 · M2-05 · passes

M2 review: 0 Critical, 4 Important, 6 Minor. Fixed RED→GREEN: memory_foreign refuses a foreign harness-memory tip; quiet+cap section in the body; a reused tip without PR gets one (memory_open); a write changing a protected section's raw lines is dropped. ro_rescue shared by retro/curator; decision completed; architecture/README document the curator.

- **Files:** lib/curator.mjs, lib/record.sh, lib/driver.sh, prompts/curator.md, tests/unit/curator.test.mjs, tests/checks/memory-pr.sh, tests/checks/curator-run.sh, tests/fixtures/memory/stub-proposal.json, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, docs/plans/2026-11-07-M2-review.md, journal/decisions/2026-11-07-memory-tiers.md, +5 more
- **Verified:** Full suite 1775/1775 in 684 s (bash tests/run.sh via check.sh), after a first run red on name lint (memory-pr ⊂ memory-prompts) and the helper-note shape check, both M2 leftovers fixed; fast tier green (cached on that tree); unit curator.test.mjs 23/23; memory-branch 15/15, curator-run 8/8, retro-backlog 13/13; the I1/I3 checks and the I2/I4 unit asserts watched RED first
- **Tests:** 961 → 962
- **Dead end:** url=$(memory_open) capturing the PR URL — note → log tees to stdout, so the capture would hold the note line: memory_open sets the caller's url instead
- **Dead end:** trusting the coding sessions' fast-tier green for M2 — two slow-tier checks were red since M2-03/M2-04: the full suite found them
- **Discovery** (affects M3): A tier-3 op counts in both dropped and proposals (ops = applied + tier 2 + dropped): M3's summary.memory must not add dropped and proposed
- **Discovery** (affects M3, project): restrict covers only the session's checkout: a read-only role's push or out-of-tree write is bounded only by its permission mode; memory_foreign guards the memory branch
- **Discovery** (affects run): This session followed the branch's CLAUDE.md (facts to the entry) and wrote no ## Gotchas line, as M1-03 and M2-04 did; the Promote to Gotchas items stay for the curator
- **Discovery** (affects M3, run): tests/checks/memory-pr.sh is now memory-branch.sh: memory-pr was part of memory-prompts (name lint); resident-helper-run's helper-note grep now counts finish's retro/curator lines and the one (( rc )) SUM build
- **Question for Michael:** Should the curator session run with a deny list (Bash(git push:*), Bash(gh:*)) passed by the driver, so a push can't happen at all rather than being refused at the next base? Default: not built; memory_foreign refuses a foreign tip. Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-2/slot-1/docs/plans/2026-11-07-M2-review.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-2/slot-1/lib/record.sh
- **Proposed change:** M3: a Gotchas suffix naming another run than RUN_ID could be dropped by the gate (review M2, kept)
- **Proposed change:** M3: checks for memory_base's did-not-answer and taken-by-main paths, MERGE_POLICY=off and a failed apply/worktree add (review M5's remaining gaps)
- *08-M2-05 · claude-opus-5-5*

### 2026-11-07 12:35 · M2-04 · passes

memory_pr in lib/record.sh: ops applied in a detached $SCRATCH/memory worktree at the base, tier 1 one commit pushed to harness-memory/<run>, a memory: <run> PR left for Michael (reused on a continue, body over earlier segments), cap refusal, notes, memory.md and $STATE/memory.json; memory_base's reuse rules; STUB_FACTS, stub-gh bodies and pr edit; memory-pr.sh (13).

- **Files:** lib/record.sh, lib/driver.sh, tests/checks/memory-pr.sh, tests/stub-claude.sh, tests/stub-gh.sh, tests/fixtures/memory/stub-continue.json, tests/fixtures/memory/stub-cap.json, tests/fixtures/memory/stub-cap-evict.json, tests/fixtures/memory/README.md, tests/fixtures/check-names.txt, journal/decisions/2026-11-07-memory-tiers.md
- **Verified:** memory-pr.sh 13/13 (10 red before memory_pr except the record-PR guard; the two branch-reuse checks red on HEAD's record.sh); bash tests/run.sh memory-pr curator-run lanes-record-pr gotchas-pack needs-driver 65/65; fast tier green, 961 tests; inspected a kept run: notes, PR body, branch CLAUDE.md, memory.json, no worktree left. Opus review: 4 Important, 10 Minor; 13 fixed, 1 documented.
- **Tests:** 961 → 961
- **Dead end:** ${st:-not the run's} inside a double-quoted note — an apostrophe inside ${…:-…} in double quotes breaks bash's parse (syntax error far below); worded without it
- **Discovery** (affects M2-05): stub-mixed.json was folded into stub-cap-evict.json (the evict add plus a Live system add and an unmatched-anchor replace): one run fewer; the plan's table still names stub-mixed
- **Discovery** (affects M2-05, M3): memory_base: a tip main lacks is reused when its PR is OPEN or there is none (gh pr view's 'no pull requests found'); CLOSED or another title stops the curator with one note; a gh or origin failure is one note, no curator. A squash-merged memory PR whose branch stayed reads as not taken (documented limit)
- **Discovery** (affects M3): $STATE/memory.json is removed at the top of curator() and written by memory_pr on every path past the rescue: {ops, applied, dropped, proposed, pr} (+ invalid); absent when the curator stopped early or wrote no file
- **Discovery** (affects project): stub-gh keeps pr create's --body-file as prs/pr-N.body and has a pr edit case that rewrites it (record_pr's reuse now refreshes it too)
- **Discovery** (affects run): This session followed the branch's CLAUDE.md (facts to the entry) and wrote no ## Gotchas line, as M1-03 did; the Promote to Gotchas items stay for the curator
- **Proposed change:** M2-05's architecture/README pass should name memory.md (the body in the run record) and memory_base's reuse rules beside memory-ops.json and memory.json
- *07-M2-04 · claude-opus-5-5*

### 2026-11-07 12:10 · M2-03 · passes

curator() in lib/driver.sh: after the retro, before the summary and record_pr; MEMORY_POLICY=pr|off and CURATOR_MODEL=opus in config; memory_base and memory_pr's validate (invalid, []) in record.sh; summary.mjs counts the curator role; stub # Curator session with STUB_CURATOR_OPS/EDITS; curator-run.sh (8, slow) and 1 unit test. Opus review: 1 Important, 4 Minor; 4 fixed.

- **Files:** lib/driver.sh, lib/record.sh, lib/config.sh, lib/prompt.sh, lib/summary.mjs, lib/eval.sh, tests/checks/curator-run.sh, tests/stub-claude.sh, tests/lib.sh, tests/unit/summary.test.mjs, tests/fixtures/memory/stub-three-ops.json, tests/fixtures/check-names.txt, +1 more
- **Verified:** curator-run 8/8 watched red first (1/8, the off check vacuous); summary unit test red then green; mutant without rec_commit before cstart turns the edits check red; curator-run lanes-record-pr retro-backlog verify-retro-read-only memory-prompts 51/51; with park-desk queue-debrief stop-records eval-run 198/198; fast tier 961 green (check.sh --fast, 113 s)
- **Tests:** 960 → 961
- **Dead end:** grepping the rendered prompt for the absolute run dir — {{RUN_DIR}} renders relative (.harness/runs/<run>)
- **Discovery** (affects M2-04, M3): memory_pr ends at the validate: invalid → 'curator: memory-ops.json invalid: <why>', [] → 'curator: no operations', a non-empty valid file → nothing yet. M2-04 adds steps 2–8, memory.json (step 8) included: M2-03 writes none.
- **Discovery** (affects M2-04): memory_base is the simple form: MEM_BASE=origin/<main> after a fetch, CLAUDE.md and .harness/project.md copied to $SCRATCH/memory-base/. M2-04 adds the open memory PR's reuse (pr view harness-memory/<run>) with its continue check.
- **Discovery** (affects M2-04): tests/fixtures/memory/stub-three-ops.json exists, with the texts M2-04's STUB_FACTS must produce: 'the stub's <id> work sits in work-<id>.txt at the root ({{RUN}} {{DATE}})'. The stub fills {{LINE:<id>}} for any id the file names.
- **Discovery** (affects project, M2-04, M3): Check files that write user-config.sh from scratch (not cp base-config.sh) must carry MEMORY_POLICY=off, or their runs get a curator: the nine that exist now do. lib/eval.sh's safety() sets it too.
- **Discovery** (affects M2-05, M3): finish runs the curator only when MEMORY_POLICY != off and feature_list.json exists; it rebuilds summary.json once after the retro and the curator (rc flag), not after each one.
- **Proposed change:** M2-05's review: where-things-go-readonly.md / -override.md say '(a retro: your report)'; the curator gets those parts too and has no entry or report, so a clause for it ('the curator: memory-ops.json') would read truer. Left alone here: memory-prompts greps those parts.
- **Proposed change:** M2-05's docs: README and docs/architecture.md need MEMORY_POLICY, CURATOR_MODEL, the curator in finish's order, memory-ops.json in the run record, and the curator role in Spend by role.
- *06-M2-03 · claude-opus-5-5*

### 2026-11-07 11:45 · M2-02 · passes

lib/curator.mjs (validate, tierOf, matchAnchor, capCheck, apply, body, main validate|apply|body); factKey/factText/resolvedText exported from entries.mjs; sectionEntries/headingLines (fence-aware) in memlint.mjs; prompts/curator.md; 22 unit tests on headings.txt and three harm fixtures. Opus review: 2 Important, 6 Minor, fixed red→green.

- **Files:** lib/curator.mjs, lib/entries.mjs, lib/memlint.mjs, prompts/curator.md, tests/unit/curator.test.mjs, tests/fixtures/memory/README.md, tests/fixtures/memory/corrected.entries.jsonl, tests/fixtures/memory/corrected.ops.json, tests/fixtures/memory/unstated.entries.jsonl, tests/fixtures/memory/unstated.ops.json, tests/fixtures/memory/tool-result.entries.jsonl, tests/fixtures/memory/tool-result.ops.json, +4 more
- **Verified:** node --test --test-isolation=none tests/unit/*.test.mjs: 475/475 (curator 22/22, red first: module missing, then 7 red after the review's tests); check.sh --fast green in 113 s, 960 tests; grep -c 'slice(0, 40)' lib/curator.mjs → 0; node --check on the four .mjs.
- **Tests:** 938 → 960
- **Dead end:** the gate as factKey equality (the plan's rule) — the review showed a stated first 40 characters plus an unstated tail passes and is written; the gate now compares the whole text (a stated item or a cut of it ≥ 40 chars, suffix aside)
- **Discovery** (affects M2-03, M2-04, M2-05): Built step order differs from the plan: file, section (0 or 2+ headings drop), from, gate for every op first; then the dedupe among survivors; then tier 3 → proposal; anchor; already there. An unstated tier-3 op is dropped 'not stated by …', never proposed.
- **Discovery** (affects M2-03, M2-04): The gate needs the op text to be the stated item whole or cut ≥ 40 chars (suffix aside): M2-04's stub-three-ops ops must copy STUB_FACTS' texts verbatim; a STUB_PROPOSE string passes only in a tier-2 section (a Gotchas op with it: 'not stated by entries.jsonl:<n> as a project fact').
- **Discovery** (affects M2-03, M2-04): Anchors match by factKey after the list marker and the (<run> <date>) suffix are cut: an anchor under 40 chars must be the whole line (a short prefix matches nothing).
- **Discovery** (affects M2-04): curator.mjs apply prints {ops, applied, proposed, dropped:[{op,reason}], rederived, refused, run, files}; files lists what it wrote (none when refused); a symlinked CLAUDE.md is read as absent; it is not in lib/helper.mjs's SERVED set (it writes files): call it with node, not ask.
- **Discovery** (affects M2-03, M2-04): The stub fixtures (stub-three-ops, stub-cap, stub-cap-evict, stub-mixed, stub-continue) were left to M2-03/M2-04, whose checks and knobs fill their placeholders.
- **Question for Michael:** Default taken (journal/decisions/2026-11-07-memory-tiers.md): a proposed_changes string gates only a tier-2/3 op, never a tier-1 Gotchas commit, since how-to-work-here is yours. Keep it, or let proposals land in Gotchas too? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-2/slot-1/lib/curator.mjs, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-2/slot-1/journal/decisions/2026-11-07-memory-tiers.md
- *05-M2-02 · claude-opus-5-5*

### 2026-11-07 11:27 · M2-01 · passes

Wrote docs/plans/2026-11-07-M2-curator.md: memory-ops.json's shape and validator, the tier rule and fixed protected list, anchor/gate/duplicate/cap steps, the bucket arithmetic, curator() in finish, memory_base/memory_pr, prompts/curator.md drafted, stub knobs, 40 of 60 planned names; tests/fixtures/memory/headings.txt (64 lines); the memory-tiers decision skeleton.

- **Files:** docs/plans/2026-11-07-M2-curator.md, journal/decisions/2026-11-07-memory-tiers.md, tests/fixtures/memory/headings.txt
- **Verified:** fast tier 938/938 (check.sh --fast, 112 s); headings.txt read from the eight ~/projects/*/CLAUDE.md: 8 tier 1, 43 tier 2, 12 tier 3; an Opus reviewer checked the plan against the code (1 Critical, 5 Important, 2 Minor), all eight folded into the plan and the two strongest confirmed in lib/record.sh:366 and :570.
- **Tests:** 938 → 938
- **Dead end:** a {{SECTIONS}} line at the end of the drafted curator prompt — retro.md has none: assemble appends the parts at the end, so the draft follows retro.md
- **Discovery** (affects M2-03): In finish the retro's notes, retro.md, retro-proposals.json and metrics row are uncommitted: curator() must rec_commit before taking cstart, or its restrict reverts them
- **Discovery** (affects M2-03): session() notes S_NOTES itself for every kind but retro (lib/record.sh:570): curator must join that exception, or its notes land before the restrict and are reverted
- **Discovery** (affects M2-04): STUB_PROJECT_FACT gives every listed id one shared text (one key): M2-04's two distinct facts need the new STUB_FACTS knob
- **Discovery** (affects M2-04): stub-gh has no pr edit case and keeps no PR body: M2-04 adds prs/pr-N.body and a pr edit case (record_pr's reuse already calls pr edit, which falls through to exit 0)
- **Discovery** (affects M2-03, M3): tests/lib.sh base config must set MEMORY_POLICY=off (RETRO=1 is on in every stub run): a default-on curator moves counts in many check files
- **Discovery** (affects project): restrict commits the dirty tree, then reverts all since its base: a read-only role run after another in finish must rec_commit first (agent-harness-2026-11-07-2 2026-11-07)
- **Question for Michael:** Default taken: tier 2 (every non-Gotchas, non-protected section) is never committed; it goes in the memory PR body and the run record's memory.md as ready-to-paste text. The spec said 'one commit per tier'. Should tier 2 instead be a second commit on harness-memory/<run>? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-2/slot-1/docs/plans/2026-11-07-M2-curator.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-2/slot-1/journal/decisions/2026-11-07-memory-tiers.md
- **Question for Michael:** Default taken: the cap refuses a tier-1 commit only when the result is over 120 lines or 15 Gotchas AND grew on that measure, so hit_list (181 lines) can still take a replace or delete. Keep it, or refuse every write to an over-cap file? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-2/slot-1/docs/plans/2026-11-07-M2-curator.md
- **Proposed change:** M2-04 step 1's 'git diff --stat origin/main names CLAUDE.md alone' should use origin/main...harness-memory/<run> (three dots): MERGE_POLICY=auto in the suite's base config merges the record PR into main after the curator
- *04-M2-01 · claude-opus-5-5*

### 2026-11-07 11:11 · verify M1 · passes

All 20 steps of M1-01..03 hold: full suite green (1728), subset runs pass (477/477, 31/31), prompts/pack/memory spec/docs/decision verified by reading code and tests.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| M1-01 | 1 | read docs/plans/2026-11-07-M1-one-writer.md headings | sections M1-02 and M1-03 with files, checks, tiers | yes |
| M1-01 | 2 | read plan's turned-false list; grep fixtures for old check names | list present; old names gone from check-names.txt; gotchas note retires, decision updated in place (grep count 1) | yes |
| M1-01 | 3 | read plan 'The spec's exact shape' / Stub knobs; grep record.sh, lane.sh | memory spec shape and note words match lib/record.sh:365, memory_guard in lane.sh:451 | yes |
| M1-01 | 4 | read plan 'clearing rule'; unit tests entries.test.mjs:160-210 | rule as stated is what the unit tests assert | yes |
| M1-01 | 5 | read plan budget section; grep Updated in place 2026-11-07 in context-pack decision | budget section present; line at context-pack.md:39 | yes |
| M1-01 | 6 | full suite via init output | green in 639 s, 1728 tests | yes |
| M1-02 | 1 | read tests/unit/entries.test.mjs 160-210; bash tests/run.sh unit-tier | tests for fact listed despite gotchas arg, resolved dismiss, key dedupe, other key; unit-tier passes | yes |
| M1-02 | 2 | grep carried lib/entries.mjs; node --check | no carried.some filter; syntax ok | yes |
| M1-02 | 3 | grep -c 'under `## Gotchas`' prompts/coding.md prompts/initializer.md | 0 and 0 | yes |
| M1-02 | 4 | read where-things-go*.md, templates/project/CLAUDE.md, CLAUDE.md Where things go | all route fact to discoveries/project, workflow to proposed_changes, never CLAUDE.md | yes |
| M1-02 | 5 | read gotchas-pack.sh checks at 40,44; grep old names | replacement checks exist; old four names gone from sources and fixtures | yes |
| M1-02 | 6 | bash tests/run.sh gotchas-pack memory-prompts unit-tier | 477/477 checks passed | yes |
| M1-02 | 7 | init full suite (covers fast tier) | green, 1728 tests | yes |
| M1-03 | 1 | read tests/checks/memory-one-writer.sh (tier: fast on line 2); run it | 5 stub-run checks + 2 restrict/guard checks, pass | yes |
| M1-03 | 2 | read lib/record.sh restrict, memory_guard, lane.sh:451; bash -n | memory spec limited to two root files, called between commit and journal, note in step's words; syntax ok | yes |
| M1-03 | 3 | read plan '## M1 review' | Opus review: 0 Critical, 0 Important, 3 Minor; memory reverts only two files, no other restrict changed | yes |
| M1-03 | 4 | read decision file and context-pack Updated in place line | decision exists with finding/choice; Rejected row carries the 2026-11-07 line | yes |
| M1-03 | 5 | grep architecture.md and README.md | §7 guard row, lane/record rows and README memory-lint paragraph carry the note words | yes |
| M1-03 | 6 | bash tests/run.sh memory-one-writer verify-retro-read-only gotchas-pack lanes-run | 31/31 checks passed | yes |
| M1-03 | 7 | init full suite | green, 1728 tests | yes |

- *111002-verify-M1 · claude-sonnet-5-5*

### 2026-11-07 10:59 · M1-03 · passes

restrict gains a memory spec (CLAUDE.md, .harness/project.md at the root); memory_guard (merge-base base) calls it once per coding session between the WIP commit and sync_lane, one note per file; gotchas() retires. New tests/checks/memory-one-writer.sh (fast, 7 checks), stub knobs, partial-key moved to README.md:readme, decision, docs, folded review: 0 Critical, 0 Important.

- **Files:** lib/record.sh, lib/lane.sh, tests/checks/memory-one-writer.sh, tests/stub-claude.sh, tests/checks/gotchas-pack.sh, tests/checks/partial-key.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, prompts/coding.md, docs/architecture.md, README.md, journal/decisions/2026-11-07-memory-one-writer.md, +3 more
- **Verified:** memory-one-writer 7/7 watched failing first (0/7), then green; bash tests/run.sh memory-one-writer verify-retro-read-only gotchas-pack lanes-run: 31/31; partial-key 26/26; check.sh --fast green, 938 tests (931 before); Opus review proved memory reverts only the two files on the mem run and no other restrict call changed
- **Tests:** 1723 → 1728
- **Discovery** (affects project): From M1 on a coding session's CLAUDE.md/.harness/project.md edit is reverted by memory_guard: a check needing a CLAUDE.md-only session tree must map another file (README.md:readme)
- **Discovery** (affects M2, run): This session followed the branch's CLAUDE.md (facts to the entry) and wrote no ## Gotchas line; the Promote to Gotchas item about 'Where things go' bare stays for M2's curator
- **Discovery** (affects M2, M3): memory_guard's base is the merge-base: an earlier unguarded CLAUDE.md edit on a lane (a run in flight at deploy) is reverted at the next coding session and noted against its feature
- **Question for Michael:** Should restrict's memory spec also cover .claude/CLAUDE.md, which Claude Code loads as project memory too? (default: no, the spec names CLAUDE.md and .harness/project.md only) Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-2/slot-0/lib/record.sh:365, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-2/slot-0/docs/plans/2026-11-07-M1-one-writer.md
- **Proposed change:** The coding prompt's Finish step 2 (live driver, pre-M1) still asks for a ## Gotchas line; M2/M3 sessions of this run should follow their branch's CLAUDE.md and put facts in the entry
- *03-M1-03 · claude-opus-5-5*

### 2026-11-07 10:45 · M1-02 · passes

The pack's Promote to Gotchas lists a project fact once, at its first unresolved entry, and reads no CLAUDE.md (the gotchas option and the CLI's read are gone). The coding Finish step 2, initializer paragraph, the three where-things-go parts, the template, draft-claude-md.md and this repo's CLAUDE.md send a fact to discoveries (project) and a workflow line to proposed_changes.

- **Files:** lib/entries.mjs, prompts/coding.md, prompts/initializer.md, prompts/parts/where-things-go.md, prompts/parts/where-things-go-readonly.md, prompts/parts/where-things-go-override.md, prompts/draft-claude-md.md, templates/project/CLAUDE.md, CLAUDE.md, tests/unit/entries.test.mjs, tests/checks/gotchas-pack.sh, tests/checks/memory-prompts.sh, +3 more
- **Verified:** Unit: 2 of 3 new pack tests red before the change (the third is the renamed resolved test, minus its Gotchas assertion), 21/21 after. Shell: the new checks run on the old tree (git archive HEAD + new tests): 5 of 6 FAIL; the CLAUDE.md-stays-main's one passes there too (no knob wrote CLAUDE.md before either). bash tests/run.sh gotchas-pack memory-prompts unit-tier: 478/478; suite-length 16/16; fast tier (check.sh --fast): fast green in 110 s, 931 tests.
- **Tests:** 1721 → 1723
- **Discovery** (affects project): A prompt line containing `## Where things go` counts as the block in memory-prompts' grep -c: name it 'Where things go' bare (agent-harness-2026-11-07-2 2026-11-07)
- **Discovery** (affects M1-03): gotchas-pack's facts run runs after the gotcha run, so main's CLAUDE.md already carries the fact (B's Gotchas line): the facts packs prove CLAUDE.md clears nothing
- **Discovery** (affects M1-03): docs/architecture.md still describes the pack's Promote part as cleared by a Gotchas line (§4 Context pack): M1-03's doc pass rewrites it with the clearing rule
- **Proposed change:** M1-02's clearing-rule unit test for case/backticks/spacing passes on the old code too (resolved already used key()); the step's 'watched failing' holds for the other two unit tests and five of six shell checks
- *02-M1-02 · claude-opus-5-5*

### 2026-11-07 10:35 · M1-01 · passes

Wrote docs/plans/2026-11-07-M1-one-writer.md: M1-02 (the pack's earliest-unresolved clearing rule, no CLAUDE.md read; the prompts, parts, template, draft prompt and this repo's line rerouted) and M1-03 (restrict's memory spec via a memory_guard at the merge-base, its note, gotchas() retired), every check turned false with its replacement, 4+3 stub knobs, ≤17 names of 30.

- **Files:** docs/plans/2026-11-07-M1-one-writer.md
- **Verified:** Read restrict, lane.sh 447-461, entries.mjs pack 289-296 and its CLI, the prompts and parts, all eight projects' Where things go lines; ran KEEP=1 bash tests/run.sh gotchas-pack (12/12) to read the gotcha run's session order and packs; grepped every fixture name the plan lists (each present once); check.sh --fast green (cached, 1721 tests; docs/plans is outside the key).
- **Tests:** 1721 → 1721
- **Dead end:** the feature's literal `restrict "$sstart" memory "$id"` call in lib/lane.sh — a session that merged origin/main itself brings main's CLAUDE.md change; reverting to sstart takes main's lines out at the milestone's merge, so the plan uses the merge-base in a memory_guard beside lane_guard
- **Discovery** (affects M1-03): partial-key.sh's two driver-partial checks (pkedit, pkv) need a coding session's CLAUDE.md-only tree; the revert makes it impossible, so M1-03 moves them to README.md:readme
- **Discovery** (affects M1-02): All eight projects have their own ## Where things go block (facts → ## Gotchas), so a coding prompt there gets no where-things-go part: only Finish step 2 can say the new route
- **Discovery** (affects M1-03): The initializer's revert note (lib/driver.sh:513) has no check and no stub knob; M1-03 adds STUB_INIT_GOTCHA=1
- **Discovery** (affects run, M2, M3): This run's driver is the pre-M1 live checkout: M1's revert never runs here, and M2/M3 sessions see a Finish step asking for a Gotchas line while their branch's CLAUDE.md says the entry
- **Discovery** (affects M1, M2, M3): checks-diff pairs a renamed check as replaced only when the new name sorts into the old one's hunk; elsewhere it counts as added + removed
- **Proposed change:** M1-03 step 2 should read: lib/lane.sh calls memory_guard "$sstart" "$id" (lib/record.sh, beside lane_guard: restrict <merge-base or sstart> memory <id>, one note per file), per docs/plans/2026-11-07-M1-one-writer.md
- **Proposed change:** M1-02 step 5's CLAUDE.md clause should compare against main as it was before the run (git diff --quiet <m0> main -- CLAUDE.md): origin/main after the run holds any merged edit on both sides
- *01-M1-01 · claude-opus-5-5*

### 2026-11-07 10:24 · init · passes

12 features: M1 3 (plan, pack+prompts rerouted, memory restrict spec with folded review), M2 5 (plan, lib/curator.mjs pure rules, curator role, memory_pr, review), M3 4 (plan+memlint-self retired, MEMORY_POLICY, counting+harness memory, Sonnet review). In series: M2 after M1, M3 after M2. Check budgets 30/60/35 copied from the spec.

- **Files:** .harness/runs/agent-harness-2026-11-07-2/feature_list.json
- **Discovery** (affects M1): The decision file holding the rejected LLM curator (for M1-03's Updated in place line) is journal/decisions/2026-10-22-context-pack.md:35 (`Rejected: an LLM curator`); the two specs (2026-10-24-memory-model.md:161, 2026-10-25-throughput-and-memory-design.md:43) are history and stay as written (default).
- **Discovery** (affects M2): The eight projects for the tier fixture are agent-harness, dj-crate-streaming, hit_list, n8n-home, pathways, portfolio_site, rane-one-mixxx and voice-concierge (the projects directory the user CLAUDE.md names; read-only). rane's protected headings carry suffixes: `## Hardware facts (verified 2026-10-19 on Michael's desktop)`, `## Hardware and Mixxx rules (binding on every session)`.
- **Discovery** (affects M1, M2): Existing stub knobs M1 reuses: STUB_GOTCHA=<id> (a coding session adds a ## Gotchas line), STUB_PROJECT_FACT=<id> (its entry carries that fact affecting project), STUB_RESOLVE=<id> (later entries resolve STUB_ASK's question, not a fact: a fact-resolving knob is new). The stub's first-line role switch is `case $first in "# Retro")…` in tests/stub-claude.sh:163; a `# Curator session` branch goes beside it.
- **Discovery** (affects M2, M3): retro() in lib/driver.sh:228 is the template for curator(): restrict … nothing with retro-proposals.json rescued to $SCRATCH (not a symlink, at most 65536 bytes, changed since the start commit) and S_NOTES noted after the restrict. finish() calls retro, then SUM build/report, then record_pr, then ledger: the curator goes between the retro and record_pr, and memory.json must exist before the final SUM build for M3's summary.memory.
- **Discovery** (affects M2): Tier 2 is body-only by default: the spec says tier 2 is carried to the PR for Michael and its check wants the workflow line absent from the branch, so only tier-1 ops are committed; tier 2 and 3 appear in the PR body with their `from` (M2-01 marks it *default*; see the question).
- **Discovery** (affects run): Earlier runs' coding sessions took 12–77 min (median about 30); S4's review feature took 75 min. The full suite was 640 s at init: a full-suite step gets a 1,500,000 ms timeout.
- **Question for Michael:** Tier 2 (conventions and workflow lines): the spec says `one commit per tier` and also `carried to the PR for Michael` with the workflow line `not applied`. The list takes body-only as the default (tier-1 ops are the branch's one commit; tier 2 and 3 appear in the PR body as ready-to-paste text with provenance). If you want tier-2 ops committed as a second commit on the same branch instead, say so before M2-04 starts. Files: /home/mh550/worktrees/agent-harness/agent-harness-2026-11-07-2/docs/specs/2026-11-07-memory-curator.md:107, /home/mh550/worktrees/agent-harness/agent-harness-2026-11-07-2/.harness/runs/agent-harness-2026-11-07-2/feature_list.json
- **Question for Michael:** M3-04 (the M3 review) is set to `sonnet`, as the spec's M3-review says (`a Sonnet reader`), against the initializer's default of Opus for reviews. Say `opus` if you'd rather the general rule win. Files: /home/mh550/worktrees/agent-harness/agent-harness-2026-11-07-2/docs/specs/2026-11-07-memory-curator.md:175, /home/mh550/worktrees/agent-harness/agent-harness-2026-11-07-2/.harness/runs/agent-harness-2026-11-07-2/feature_list.json
- **Proposed change:** prompts/initializer.md still tells the initializer to put a durable gotcha under ## Gotchas in CLAUDE.md, which lib/driver.sh's restrict … record then reverts; M1-02 reroutes it, as the spec says.
- *00-init · claude-fable-5-1*
