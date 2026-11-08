# Context pack for `N1-01`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (N1-02, affects N1-04, run): lib/prompt.sh checks only a root CLAUDE.md: a project whose memory is .claude/CLAUDE.md alone gets 'this project has no CLAUDE.md' and the harness's routing block (N1-02 review, not fixed) → entries.jsonl:3
- Discovery (N1-03, affects N1-01): N1-01's tier-2 union shadow can reuse apply's per-op step: capCheck(file, text, next, maxLines) after each write, a breach dropping that op alone; apply iterates op indices sorted by ORDER, so `keep` (built in op order) is unchanged. → entries.jsonl:2
- Discovery (N1-03, affects N1-01, N1-04): An anchored add whose anchor matches no line now lands as a plain add when the append fits the cap (tier 1 only); a replace or delete with no match is still dropped naming the anchor. → entries.jsonl:2
- Discovery (init, affects N1): N1 runs N1-03 (per-op cap) before N1-02 and N1-01 on purpose: N1-01's union shadow reuses the per-op capCheck, and N1-03 retires `refused` so N1-01's two-pass memory_pr never carries the refusal branch. The ids are the spec's section names; the array order is the dependency order. → entries.jsonl:1
- Discovery (init, affects N1, N2): The ledger copies the whole run record to `$LEDGER/<project>/<run>/` (lib/driver.sh ledger(): `cp -r "$REC/." "$d/"`), so once N1-01 copies memory-result.json into the record, N2-03's `harness memory proposals <run>` finds it there without a new copy step. → entries.jsonl:1
- Discovery (init, affects run): Earlier runs' coding sessions on this code took 8–41 min (the 2026-11-07-2 run: builds 9–25, reviews 37–41); N1-01 is the largest feature of this run (curator.mjs, record.sh memory_pr, summary.mjs, memory-branch.sh together) and the brief fixes four features per milestone, so it may run long. The full suite was 701 s at init: a full-suite step gets a 1,500,000 ms timeout. → entries.jsonl:1
- Discovery (init, affects N1): The brief adds one behaviour to N1-03 beyond the spec: an add that carries an anchor while ## Gotchas is under 15 and the file under 120 lines is applied as a plain add (no eviction), and the PR body (and a harness-log note, a default) name the evicted line of a real eviction as `(in place of: …)`. The `me` run at 15 Gotchas still evicts; a new unit test covers the under-cap case. → entries.jsonl:1

## Promote to Gotchas

- memory-branch.sh's last check counts registered worktrees (12 since N1-02's md run): a new run in that file bumps it (agent-harness-2026-11-08 2026-11-08) → entries.jsonl:3

## What it builds on

- 2026-11-08 03:48 · N1-02 · passes: Twins guarded: restrict memory reverts CLAUDE.md, .harness/project.md, .claude/CLAUDE.md and .claude/rules (now -z, unquoted paths); curator FILES, memory_base, memory_foreign, capCheck and the prompt take .claude/CLAUDE.md; memlint lints it on its own cap plus `twin`; STUB_DOT_CLAUDE; decision row, docs, prompts.; tests 1066 → 1069; files lib/record.sh, lib/curator.mjs, lib/memlint.mjs, prompts/curator.md, prompts/coding.md, … → entries.jsonl:3

## Lately in the run

- 2026-11-08 03:26 · N1-03 · passes: curator.mjs apply checks the cap per tier-1 op (order delete, replace, anchored add, plain add; a breach drops that op alone `over the cap: …`); an anchored add appends while it fits, evicts only past the cap (`evicted`, body `(in place of: …)`, an eviction note); `refused` retired from apply, body and memory_pr. stub-cap gains a replace; decision 2026-11-08-memory-rules-pr created.; tests 1898 → 1900; files lib/curator.mjs, lib/record.sh, prompts/curator.md, tests/unit/curator.test.mjs, tests/checks/memory-branch.sh, … → entries.jsonl:2
- 2026-11-08 03:11 · init · passes: 8 features: N1 4 (per-op cap N1-03, twin guard N1-02, rules PR N1-01, Opus review N1-04), N2 4 (deny list N2-01, auto merge only with its body N2-02, accept/decline verbs N2-03, Opus review N2-04). N2 after N1; N1 ordered by dependency: N1-03, N1-02, N1-01. Check budgets 50/30 from the spec. Every spec default taken; no question. → entries.jsonl:1

## Current rules

- The tiers and the files: tier 2 is a PR, the twins are guarded, the cap is per operation → journal/decisions/2026-11-08-memory-rules-pr.md
- The memory curator: itemized operations, a tier the driver derives, a protected list that is fixed → journal/decisions/2026-11-07-memory-tiers.md
- The gate replaces the lint: `memlint-self` retired, `MEMORY_POLICY`, and the curator's acceptance counted → journal/decisions/2026-11-07-memory-policy.md
- One writer for project memory: a coding session's `CLAUDE.md` edit is reverted, a fact goes in the entry → journal/decisions/2026-11-07-memory-one-writer.md
- Supervised efforts for every project: one user-level skill, one dispatch list per effort, plain names throughout → journal/decisions/2026-11-05-supervised-efforts.md
- The suite's shape: check files named for what they test, no name part of another's, two cuts that need no replay, a tier on every line → journal/decisions/2026-11-05-suite-shape.md
- A merge survives an origin outage: bounded retries, a card past them, a tag that isn't claimed, gc holds verified work → journal/decisions/2026-11-04-origin-retries.md
- No run ends on a clock unless asked to: `HOURS` defaults to none, and the night leaves the docs → journal/decisions/2026-11-04-no-default-end-time.md
- A red verify opens a fix round, not a card: at most `MAX_FIX_ROUNDS` per milestone, each one counted → journal/decisions/2026-11-04-fix-rounds.md
- The unit tier: node evals become `node:test` files in one process, reported as the suite's PASS/FAIL lines → journal/decisions/2026-11-03-unit-tier.md
- The trim: 22 checks removed, each with the check that makes its assertions now; five gaps closed; no covered line lost → journal/decisions/2026-11-03-trim.md
- The suite's tiers: every check file declares `fast` or `slow` on line 2, and `tests/run.sh --tier` runs one tier → journal/decisions/2026-11-03-suite-tiers.md

_92 older rules: journal/decisions._
