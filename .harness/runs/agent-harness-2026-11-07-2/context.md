# Context pack for `M2-03`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (M2-02, affects M2-03, M2-04, M2-05): Built step order differs from the plan: file, section (0 or 2+ headings drop), from, gate for every op first; then the dedupe among survivors; then tier 3 → proposal; anchor; already there. An unstated tier-3 op is dropped 'not stated by …', never proposed. → entries.jsonl:7
- Discovery (M2-02, affects M2-03, M2-04): The gate needs the op text to be the stated item whole or cut ≥ 40 chars (suffix aside): M2-04's stub-three-ops ops must copy STUB_FACTS' texts verbatim; a STUB_PROPOSE string passes only in a tier-2 section (a Gotchas op with it: 'not stated by entries.jsonl:<n> as a project fact'). → entries.jsonl:7
- Discovery (M2-02, affects M2-03, M2-04): Anchors match by factKey after the list marker and the (<run> <date>) suffix are cut: an anchor under 40 chars must be the whole line (a short prefix matches nothing). → entries.jsonl:7
- Discovery (M2-02, affects M2-03, M2-04): The stub fixtures (stub-three-ops, stub-cap, stub-cap-evict, stub-mixed, stub-continue) were left to M2-03/M2-04, whose checks and knobs fill their placeholders. → entries.jsonl:7
- Discovery (M2-01, affects M2-03): In finish the retro's notes, retro.md, retro-proposals.json and metrics row are uncommitted: curator() must rec_commit before taking cstart, or its restrict reverts them → entries.jsonl:6
- Discovery (M2-01, affects M2-03): session() notes S_NOTES itself for every kind but retro (lib/record.sh:570): curator must join that exception, or its notes land before the restrict and are reverted → entries.jsonl:6
- Discovery (M2-01, affects M2-03, M3): tests/lib.sh base config must set MEMORY_POLICY=off (RETRO=1 is on in every stub run): a default-on curator moves counts in many check files → entries.jsonl:6
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

- restrict commits the dirty tree, then reverts all since its base: a read-only role run after another in finish must rec_commit first (agent-harness-2026-11-07-2 2026-11-07) → entries.jsonl:6
- From M1 on a coding session's CLAUDE.md/.harness/project.md edit is reverted by memory_guard: a check needing a CLAUDE.md-only session tree must map another file (README.md:readme) → entries.jsonl:4
- A prompt line containing `## Where things go` counts as the block in memory-prompts' grep -c: name it 'Where things go' bare (agent-harness-2026-11-07-2 2026-11-07) → entries.jsonl:3

## What it builds on

- 2026-11-07 11:45 · M2-02 · passes: lib/curator.mjs (validate, tierOf, matchAnchor, capCheck, apply, body, main validate|apply|body); factKey/factText/resolvedText exported from entries.mjs; sectionEntries/headingLines (fence-aware) in memlint.mjs; prompts/curator.md; 22 unit tests on headings.txt and three harm fixtures. Opus review: 2 Important, 6 Minor, fixed red→green.; tests 938 → 960; files lib/curator.mjs, lib/entries.mjs, lib/memlint.mjs, prompts/curator.md, tests/unit/curator.test.mjs, … → entries.jsonl:7

## Lately in the run

- 2026-11-07 11:27 · M2-01 · passes: Wrote docs/plans/2026-11-07-M2-curator.md: memory-ops.json's shape and validator, the tier rule and fixed protected list, anchor/gate/duplicate/cap steps, the bucket arithmetic, curator() in finish, memory_base/memory_pr, prompts/curator.md drafted, stub knobs, 40 of 60 planned names; tests/fixtures/memory/headings.txt (64 lines); the memory-tiers decision skeleton.; tests 938 → 938; files docs/plans/2026-11-07-M2-curator.md, journal/decisions/2026-11-07-memory-tiers.md, tests/fixtures/memory/headings.txt → entries.jsonl:6
- 2026-11-07 11:11 · verify M1 · passes: All 20 steps of M1-01..03 hold: full suite green (1728), subset runs pass (477/477, 31/31), prompts/pack/memory spec/docs/decision verified by reading code and tests. → entries.jsonl:5

## Current rules

- The memory curator: itemized operations, a tier the driver derives, a protected list that is fixed → journal/decisions/2026-11-07-memory-tiers.md
- One writer for project memory: a coding session's `CLAUDE.md` edit is reverted, a fact goes in the entry → journal/decisions/2026-11-07-memory-one-writer.md
- Supervised efforts for every project: one user-level skill, one dispatch list per effort, plain names throughout → journal/decisions/2026-11-05-supervised-efforts.md
- The suite's shape: check files named for what they test, no name part of another's, two cuts that need no replay, a tier on every line → journal/decisions/2026-11-05-suite-shape.md
- A merge survives an origin outage: bounded retries, a card past them, a tag that isn't claimed, gc holds verified work → journal/decisions/2026-11-04-origin-retries.md
- No run ends on a clock unless asked to: `HOURS` defaults to none, and the night leaves the docs → journal/decisions/2026-11-04-no-default-end-time.md

_93 older rules: journal/decisions._
