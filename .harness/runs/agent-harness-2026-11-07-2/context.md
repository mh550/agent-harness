# Context pack for `M1-02`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (M1-01, affects M1-02): All eight projects have their own ## Where things go block (facts → ## Gotchas), so a coding prompt there gets no where-things-go part: only Finish step 2 can say the new route → entries.jsonl:2
- Discovery (M1-01, affects run, M2, M3): This run's driver is the pre-M1 live checkout: M1's revert never runs here, and M2/M3 sessions see a Finish step asking for a Gotchas line while their branch's CLAUDE.md says the entry → entries.jsonl:2
- Discovery (M1-01, affects M1, M2, M3): checks-diff pairs a renamed check as replaced only when the new name sorts into the old one's hunk; elsewhere it counts as added + removed → entries.jsonl:2
- Discovery (init, affects M1): The decision file holding the rejected LLM curator (for M1-03's Updated in place line) is journal/decisions/2026-10-22-context-pack.md:35 (`Rejected: an LLM curator`); the two specs (2026-10-24-memory-model.md:161, 2026-10-25-throughput-and-memory-design.md:43) are history and stay as written (default). → entries.jsonl:1
- Discovery (init, affects M1, M2): Existing stub knobs M1 reuses: STUB_GOTCHA=<id> (a coding session adds a ## Gotchas line), STUB_PROJECT_FACT=<id> (its entry carries that fact affecting project), STUB_RESOLVE=<id> (later entries resolve STUB_ASK's question, not a fact: a fact-resolving knob is new). The stub's first-line role switch is `case $first in "# Retro")…` in tests/stub-claude.sh:163; a `# Curator session` branch goes beside it. → entries.jsonl:1
- Discovery (init, affects run): Earlier runs' coding sessions took 12–77 min (median about 30); S4's review feature took 75 min. The full suite was 640 s at init: a full-suite step gets a 1,500,000 ms timeout. → entries.jsonl:1

## What it builds on

- 2026-11-07 10:35 · M1-01 · passes: Wrote docs/plans/2026-11-07-M1-one-writer.md: M1-02 (the pack's earliest-unresolved clearing rule, no CLAUDE.md read; the prompts, parts, template, draft prompt and this repo's line rerouted) and M1-03 (restrict's memory spec via a memory_guard at the merge-base, its note, gotchas() retired), every check turned false with its replacement, 4+3 stub knobs, ≤17 names of 30.; tests 1721 → 1721; files docs/plans/2026-11-07-M1-one-writer.md → entries.jsonl:2

## Lately in the run

- 2026-11-07 10:24 · init · passes: 12 features: M1 3 (plan, pack+prompts rerouted, memory restrict spec with folded review), M2 5 (plan, lib/curator.mjs pure rules, curator role, memory_pr, review), M3 4 (plan+memlint-self retired, MEMORY_POLICY, counting+harness memory, Sonnet review). In series: M2 after M1, M3 after M2. Check budgets 30/60/35 copied from the spec.; files .harness/runs/agent-harness-2026-11-07-2/feature_list.json → entries.jsonl:1

## Current rules

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

_85 older rules: journal/decisions._
