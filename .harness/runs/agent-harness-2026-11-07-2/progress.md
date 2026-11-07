<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-07-2` (agent-harness)

What this file is: the run's journal, rendered by the harness from `entries.jsonl`, newest entry first (the 15 newest in full; every entry is in `progress-archive.md`). Each entry is one session: its feature, outcome, summary, what it tried, what it found.

The run builds the memory curator of `docs/specs/2026-11-07-memory-curator.md`, three milestones in series: **M1** a coding session's `CLAUDE.md` edit is reverted (`restrict … memory`) and facts go in the entry; **M2** an Opus `curator` session emits itemized operations (`memory-ops.json`) that the driver validates, tiers and applies on `harness-memory/<run>` behind a `memory: <run>` PR; **M3** `memlint-self` retires, `MEMORY_POLICY=pr|auto|off`, acceptance counted (`summary.memory`, the `Memory` row, `harness memory`).

How to read the feature list: `feature_list.json` is in priority order; a feature runs when it isn't passing and its `after` all pass. Each milestone's plan feature writes `docs/plans/2026-11-07-M<n>-….md`; the last feature of each milestone is its review (M1's is folded into M1-03). When every feature of a milestone passes the harness verifies it and opens its PR against `main` (`MERGE_POLICY=pr`).

How to steer: edit `INBOX.md` in this directory from the phone or `harness answer`. A line `status: stop <why>` or `status: pause` on top stops or pauses the run; answers to questions go under `## Answers`; a brief under the steering comment changes scope for the next session. Open questions are listed under the entries that asked them and in `harness needs`.

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
