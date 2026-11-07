# Context pack for `M2-01`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (M1-03, affects M2, run): This session followed the branch's CLAUDE.md (facts to the entry) and wrote no ## Gotchas line; the Promote to Gotchas item about 'Where things go' bare stays for M2's curator → entries.jsonl:4
- Discovery (M1-03, affects M2, M3): memory_guard's base is the merge-base: an earlier unguarded CLAUDE.md edit on a lane (a run in flight at deploy) is reverted at the next coding session and noted against its feature → entries.jsonl:4
- Discovery (M1-01, affects run, M2, M3): This run's driver is the pre-M1 live checkout: M1's revert never runs here, and M2/M3 sessions see a Finish step asking for a Gotchas line while their branch's CLAUDE.md says the entry → entries.jsonl:2
- Discovery (M1-01, affects M1, M2, M3): checks-diff pairs a renamed check as replaced only when the new name sorts into the old one's hunk; elsewhere it counts as added + removed → entries.jsonl:2
- Discovery (init, affects M2): The eight projects for the tier fixture are agent-harness, dj-crate-streaming, hit_list, n8n-home, pathways, portfolio_site, rane-one-mixxx and voice-concierge (the projects directory the user CLAUDE.md names; read-only). rane's protected headings carry suffixes: `## Hardware facts (verified 2026-10-19 on Michael's desktop)`, `## Hardware and Mixxx rules (binding on every session)`. → entries.jsonl:1
- Discovery (init, affects M1, M2): Existing stub knobs M1 reuses: STUB_GOTCHA=<id> (a coding session adds a ## Gotchas line), STUB_PROJECT_FACT=<id> (its entry carries that fact affecting project), STUB_RESOLVE=<id> (later entries resolve STUB_ASK's question, not a fact: a fact-resolving knob is new). The stub's first-line role switch is `case $first in "# Retro")…` in tests/stub-claude.sh:163; a `# Curator session` branch goes beside it. → entries.jsonl:1
- Discovery (init, affects M2, M3): retro() in lib/driver.sh:228 is the template for curator(): restrict … nothing with retro-proposals.json rescued to $SCRATCH (not a symlink, at most 65536 bytes, changed since the start commit) and S_NOTES noted after the restrict. finish() calls retro, then SUM build/report, then record_pr, then ledger: the curator goes between the retro and record_pr, and memory.json must exist before the final SUM build for M3's summary.memory. → entries.jsonl:1
- Discovery (init, affects M2): Tier 2 is body-only by default: the spec says tier 2 is carried to the PR for Michael and its check wants the workflow line absent from the branch, so only tier-1 ops are committed; tier 2 and 3 appear in the PR body with their `from` (M2-01 marks it *default*; see the question). → entries.jsonl:1
- Discovery (init, affects run): Earlier runs' coding sessions took 12–77 min (median about 30); S4's review feature took 75 min. The full suite was 640 s at init: a full-suite step gets a 1,500,000 ms timeout. → entries.jsonl:1

## Promote to Gotchas

- From M1 on a coding session's CLAUDE.md/.harness/project.md edit is reverted by memory_guard: a check needing a CLAUDE.md-only session tree must map another file (README.md:readme) → entries.jsonl:4
- A prompt line containing `## Where things go` counts as the block in memory-prompts' grep -c: name it 'Where things go' bare (agent-harness-2026-11-07-2 2026-11-07) → entries.jsonl:3

## What it builds on

- 2026-11-07 10:35 · M1-01 · passes: Wrote docs/plans/2026-11-07-M1-one-writer.md: M1-02 (the pack's earliest-unresolved clearing rule, no CLAUDE.md read; the prompts, parts, template, draft prompt and this repo's line rerouted) and M1-03 (restrict's memory spec via a memory_guard at the merge-base, its note, gotchas() retired), every check turned false with its replacement, 4+3 stub knobs, ≤17 names of 30.; tests 1721 → 1721; files docs/plans/2026-11-07-M1-one-writer.md → entries.jsonl:2
- 2026-11-07 10:45 · M1-02 · passes: The pack's Promote to Gotchas lists a project fact once, at its first unresolved entry, and reads no CLAUDE.md (the gotchas option and the CLI's read are gone). The coding Finish step 2, initializer paragraph, the three where-things-go parts, the template, draft-claude-md.md and this repo's CLAUDE.md send a fact to discoveries (project) and a workflow line to proposed_changes.; tests 1721 → 1723; files lib/entries.mjs, prompts/coding.md, prompts/initializer.md, prompts/parts/where-things-go.md, prompts/parts/where-things-go-readonly.md, … → entries.jsonl:3
- 2026-11-07 10:59 · M1-03 · passes: restrict gains a memory spec (CLAUDE.md, .harness/project.md at the root); memory_guard (merge-base base) calls it once per coding session between the WIP commit and sync_lane, one note per file; gotchas() retires. New tests/checks/memory-one-writer.sh (fast, 7 checks), stub knobs, partial-key moved to README.md:readme, decision, docs, folded review: 0 Critical, 0 Important.; tests 1723 → 1728; files lib/record.sh, lib/lane.sh, tests/checks/memory-one-writer.sh, tests/stub-claude.sh, tests/checks/gotchas-pack.sh, … → entries.jsonl:4

## Lately in the run

- 2026-11-07 11:11 · verify M1 · passes: All 20 steps of M1-01..03 hold: full suite green (1728), subset runs pass (477/477, 31/31), prompts/pack/memory spec/docs/decision verified by reading code and tests. → entries.jsonl:5

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

_86 older rules: journal/decisions._
