# Context pack for `M1`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Dead end (M1-01, 01-M1-01): the feature's literal `restrict "$sstart" memory "$id"` call in lib/lane.sh — a session that merged origin/main itself brings main's CLAUDE.md change; reverting to sstart takes main's lines out at the milestone's merge, so the plan uses the merge-base in a memory_guard beside lane_guard → entries.jsonl:2
- Question (M1-03): Should restrict's memory spec also cover .claude/CLAUDE.md, which Claude Code loads as project memory too? (default: no, the spec names CLAUDE.md and .harness/project.md only) Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-2/slot-0/lib/record.sh:365, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-2/slot-0/docs/plans/2026-11-07-M1-one-writer.md → entries.jsonl:4
- 2026-11-07 10:59 · M1-03 · passes: restrict gains a memory spec (CLAUDE.md, .harness/project.md at the root); memory_guard (merge-base base) calls it once per coding session between the WIP commit and sync_lane, one note per file; gotchas() retires. New tests/checks/memory-one-writer.sh (fast, 7 checks), stub knobs, partial-key moved to README.md:readme, decision, docs, folded review: 0 Critical, 0 Important.; tests 1723 → 1728; files lib/record.sh, lib/lane.sh, tests/checks/memory-one-writer.sh, tests/stub-claude.sh, tests/checks/gotchas-pack.sh, … → entries.jsonl:4
- 2026-11-07 10:45 · M1-02 · passes: The pack's Promote to Gotchas lists a project fact once, at its first unresolved entry, and reads no CLAUDE.md (the gotchas option and the CLI's read are gone). The coding Finish step 2, initializer paragraph, the three where-things-go parts, the template, draft-claude-md.md and this repo's CLAUDE.md send a fact to discoveries (project) and a workflow line to proposed_changes.; tests 1721 → 1723; files lib/entries.mjs, prompts/coding.md, prompts/initializer.md, prompts/parts/where-things-go.md, prompts/parts/where-things-go-readonly.md, … → entries.jsonl:3
- 2026-11-07 10:35 · M1-01 · passes: Wrote docs/plans/2026-11-07-M1-one-writer.md: M1-02 (the pack's earliest-unresolved clearing rule, no CLAUDE.md read; the prompts, parts, template, draft prompt and this repo's line rerouted) and M1-03 (restrict's memory spec via a memory_guard at the merge-base, its note, gotchas() retired), every check turned false with its replacement, 4+3 stub knobs, ≤17 names of 30.; tests 1721 → 1721; files docs/plans/2026-11-07-M1-one-writer.md → entries.jsonl:2

## Discoveries for this feature

- Discovery (M1-03, affects M2, run): This session followed the branch's CLAUDE.md (facts to the entry) and wrote no ## Gotchas line; the Promote to Gotchas item about 'Where things go' bare stays for M2's curator → entries.jsonl:4
- Discovery (M1-02, affects M1-03): gotchas-pack's facts run runs after the gotcha run, so main's CLAUDE.md already carries the fact (B's Gotchas line): the facts packs prove CLAUDE.md clears nothing → entries.jsonl:3
- Discovery (M1-02, affects M1-03): docs/architecture.md still describes the pack's Promote part as cleared by a Gotchas line (§4 Context pack): M1-03's doc pass rewrites it with the clearing rule → entries.jsonl:3
- Discovery (M1-01, affects M1-03): partial-key.sh's two driver-partial checks (pkedit, pkv) need a coding session's CLAUDE.md-only tree; the revert makes it impossible, so M1-03 moves them to README.md:readme → entries.jsonl:2
- Discovery (M1-01, affects M1-02): All eight projects have their own ## Where things go block (facts → ## Gotchas), so a coding prompt there gets no where-things-go part: only Finish step 2 can say the new route → entries.jsonl:2
- Discovery (M1-01, affects M1-03): The initializer's revert note (lib/driver.sh:513) has no check and no stub knob; M1-03 adds STUB_INIT_GOTCHA=1 → entries.jsonl:2
- Discovery (M1-01, affects run, M2, M3): This run's driver is the pre-M1 live checkout: M1's revert never runs here, and M2/M3 sessions see a Finish step asking for a Gotchas line while their branch's CLAUDE.md says the entry → entries.jsonl:2
- Discovery (M1-01, affects M1, M2, M3): checks-diff pairs a renamed check as replaced only when the new name sorts into the old one's hunk; elsewhere it counts as added + removed → entries.jsonl:2
- Discovery (init, affects M1): The decision file holding the rejected LLM curator (for M1-03's Updated in place line) is journal/decisions/2026-10-22-context-pack.md:35 (`Rejected: an LLM curator`); the two specs (2026-10-24-memory-model.md:161, 2026-10-25-throughput-and-memory-design.md:43) are history and stay as written (default). → entries.jsonl:1
- Discovery (init, affects M1, M2): Existing stub knobs M1 reuses: STUB_GOTCHA=<id> (a coding session adds a ## Gotchas line), STUB_PROJECT_FACT=<id> (its entry carries that fact affecting project), STUB_RESOLVE=<id> (later entries resolve STUB_ASK's question, not a fact: a fact-resolving knob is new). The stub's first-line role switch is `case $first in "# Retro")…` in tests/stub-claude.sh:163; a `# Curator session` branch goes beside it. → entries.jsonl:1
- Discovery (init, affects run): Earlier runs' coding sessions took 12–77 min (median about 30); S4's review feature took 75 min. The full suite was 640 s at init: a full-suite step gets a 1,500,000 ms timeout. → entries.jsonl:1

## Current rules

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
- Fewer node starts: where a stub run's process starts come from, and the cuts C1 makes → journal/decisions/2026-10-31-fewer-node-starts.md
- The suite's length in every prompt: a green marker's `wall` line, and a timeout rule → journal/decisions/2026-10-30-suite-length-in-prompt.md
- A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing → journal/decisions/2026-10-30-red-marker.md
- A mapped path's change runs only its readers: `CHECK_KEY_MAP`, the `part-<key>` sidecar, the partial run, the lint → journal/decisions/2026-10-30-partial-key.md
- The coordinator opens no lane while a lane that exited is not reaped yet → journal/decisions/2026-10-30-opens-wait-for-reap.md
- The lane guard reverts against the lane's merge-base with main, in the index only → journal/decisions/2026-10-30-lane-guard-base.md
- Timing checks bound CPU time; a stopped file's missing names don't void `HARNESS_FAILED=` → journal/decisions/2026-10-30-cpu-time-bound-and-stopped-files.md
- The suite waits on a condition or a barrier, never on the clock; a flake is reproduced with --repeat and fixed at its cause → journal/decisions/2026-10-29-tests-wait-not-sleep.md
- The rerun guard: a red full suite is rerun once; a flake is green, named and counted, never quarantined → journal/decisions/2026-10-29-rerun-guard.md

_73 older rules: journal/decisions._
