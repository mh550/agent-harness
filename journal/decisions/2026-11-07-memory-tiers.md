# The memory curator: itemized operations, a tier the driver derives, a protected list that is fixed

*(2026-11-07, run agent-harness-2026-11-07-2, M2 (skeleton by M2-01; the choice completed by M2-04, rejected and the
invariants by M2-05); spec `docs/specs/2026-11-07-memory-curator.md` §M2; plan `docs/plans/2026-11-07-M2-curator.md`;
`findings-and-research/Agent Memory Field Guide.md` lines 707–736 (ACE's itemized delta updates, context collapse),
820–844 (provenance), 1031–1055 (the ETH `AGENTS.md` study), 1081–1121 (memory poisoning and the write gate).)*

- **Finding:** after M1 (decisions/2026-11-07-memory-one-writer) no session writes project memory, so a project fact
  stays in its entry and never reaches `CLAUDE.md`. The guide's answer for an LLM that maintains a memory file is a
  curator that emits **itemized operations**, never a rewritten file: "Small anchored edits can be validated, diffed
  and reverted" (ACE, 707–736). Every memory needs its provenance (820–844), a longer context file is followed less
  and costs more (1031–1055), and a line that arrived in a tool result must not be written as the agent's own finding
  (1081–1121). Where the curator may run is fixed by `record_pr`'s guard (`lib/driver.sh:288–289`): a change on
  `harness/<run>` outside `$RUN_DIR/` kills the run's record PR, so the curator must not write where the retro runs.
- **Choice:**
  - **The protected list, fixed and matched by prefix** on the heading text after `## `: `Live system`,
    `Off-limits`, `On-limits`, `Hardware facts`, `Hardware and Mixxx rules`, `This repo runs Michael's harness runs`.
    A prefix, so rane-one-mixxx's `## Hardware facts (verified 2026-10-19 on Michael's desktop)` and
    `## Hardware and Mixxx rules (binding on every session)` are protected with their suffixes. A new protected
    heading is added to this list, never inferred.
  - **The tier rule, derived by the driver** (`tierOf` in `lib/curator.mjs`) from the heading alone; the session's
    `tier` field is a claim, counted when it disagrees and never read for a decision. Tier 3 is the protected list
    (a proposal in the PR body, never applied); tier 1 is `## Gotchas` (*default*: the one fact section all eight
    projects have); tier 2 is every other heading (in the PR body, never committed, *default*). The eight projects'
    headings and their tiers: `tests/fixtures/memory/headings.txt`.
  - **The operations' shape**: `memory-ops.json`, an array of `{op, file, section, anchor, text, tier, why, from}`;
    `op` add, replace or delete; `file` `CLAUDE.md` or `.harness/project.md` (*default*); `from`
    `entries.jsonl:<n>`; a `## Gotchas` text at most 160 characters ending `(<run> <date>)` (*default*); an invalid
    file refused whole with its first reason (*default*, as the retro's proposals).
  - **Anchors** match one line of the section by the `key` normalizer of `lib/entries.mjs`, exported and imported,
    never copied (*default*); zero or two matches drop the op, naming the anchor.
  - **The write gate**: an op's text must be, by `key`, a `project` discovery or a `proposed_changes` string of the
    entry its `from` names, not resolved later (*default*); a `delete` is exempt, its anchor must exist. The gate runs
    before the protected test (M2-02), so a tier-3 proposal reaches Michael only when an entry states it, and before
    the dedupe, so among the ops of one `key` that pass it the latest `from` is kept (an op naming no entry never
    eclipses one that does). Anchors, the dedupe and "already there" compare by `key` after a leading list marker
    (`- `, `* `, `1. `) and the `(<run> <date>)` suffix are cut. *Tightened by M2-02's review:* the gate compares the
    whole text, not its `key`: the op's text (suffix aside) is the stated item's or a cut of it at least 40
    characters long (or the whole item), so no unstated tail rides on a stated first 40 characters; and a
    `proposed_changes` string (Michael's: how to work here) gates a tier-2 or tier-3 op, never a tier-1 commit
    (*default*).
  - **The file as text**: a heading inside a ``` or ~~~ fence is no heading (`sectionEntries`, `headingLines` in
    `lib/memlint.mjs`), a fenced block is one entry; a section heading that appears twice drops the op (which one is
    meant is Michael's); a CRLF file keeps its line ends; a symlinked `CLAUDE.md` or `.harness/` is no file (apply
    never reads or writes through a link); `why` is one line, and an `@login` outside a fence in the body is broken
    with a zero-width space so the PR notifies no one.
  - **The cap**: `lintText` re-run on the result; over 120 lines or 15 `## Gotchas` entries, and grown on that
    measure (*default*), refuses the tier-1 commit whole with one note. An `add` past the cap passes only with an
    anchor, the line it evicts.
  - *To be completed by M2-04, as built:* `memory_pr`, the `harness-memory/<run>` branch cut from `origin/<main>` in a
    detached scratch worktree, the one tier-1 commit, the PR body, the reuse of an open `memory: <run>` PR, the cap
    refusal, `memory.json`, `MEMORY_POLICY=pr|off` (`pr` *default*), `CURATOR_MODEL=opus` (*default*).
- **Rejected:** *to be completed by M2-05:* a rewritten file; an inferred protected set; a trusted `tier` field; a
  curator that commits tier 2; a curator that writes where the retro runs; a local or force-pushed memory branch.
  And the spec's two invariants, each with the check that proves it: (1) the curator never writes a project file;
  (2) no operation touches a protected section.
