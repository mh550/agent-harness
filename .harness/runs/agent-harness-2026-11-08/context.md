# Context pack for `N2-01`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (N1, affects run): docs/architecture.md:105, the prompts/curator.md component row, still describes the pre-N1 prompt: N1-04's fix is one row that names tier 2 as a diff on harness-rules/<run> Michael merges and .claude/CLAUDE.md among the files. → entries.jsonl:7
- Discovery (N1, affects run): The spec's N1-01 step 3 expects `… 1 proposals` for mp, but three-ops has no tier-3 op; the code and checks read 0 (decisions/2026-11-08-memory-rules-pr, bodies row). A verify reading the steps literally should know this. → entries.jsonl:6
- Discovery (N1-04, affects N1, run): N1-02 reworded prompts/coding.md and where-things-go*.md to name .claude/CLAUDE.md and .claude/rules/; memory-prompts and gotchas-pack (slow) assert those sentences verbatim and were red until N1-04 → entries.jsonl:5
- Discovery (N1-04, affects N2, run): A stale facts tip (an open memory: <run> PR) after main moved can still merge past the cap; the drift covers the rules side only (pre-N1 behaviour, not changed) → entries.jsonl:5
- Discovery (N1-04, affects N2-01, N2-02, N2-03): curator.mjs apply's CLI takes 4, 5 or 7 args: a 6th and 7th (the rules tip's merge-base with main, main) give the union shadow's drift; memory_base writes them to $SCRATCH/memory-rules-mb and memory-main → entries.jsonl:5
- Discovery (N1-01, affects N2-01, N2-02, N1-04): curator.mjs apply takes an optional fifth argument, the rules base directory ($SCRATCH/memory-rules-base/ from memory_base); memory_tip (facts|rules) sets TIP_NOTE instead of noting, so the caller places the note. → entries.jsonl:4
- Discovery (N1-02, affects N1-04, run): lib/prompt.sh checks only a root CLAUDE.md: a project whose memory is .claude/CLAUDE.md alone gets 'this project has no CLAUDE.md' and the harness's routing block (N1-02 review, not fixed) → entries.jsonl:3
- Discovery (init, affects N2): N2-02's stub case cannot be the spec's `ma` run as it stands: under auto `ma`'s facts PR is merged in its first segment, so a continue opens a fresh PR (`pr create` carries its body, no `pr edit`). The reused-PR path needs an open facts PR at the continue: the `mw` run's shape (hand-pushed harness-memory/<run>, PR opened with no tier-1 commit, left open) with a continue that adds one tier-1 fact. tests/stub-gh.sh's `STUB_GH_DOWN_ONLY` regex takes any named sub-command, so `edit` works without a stub change. → entries.jsonl:1
- Discovery (init, affects N1, N2): The ledger copies the whole run record to `$LEDGER/<project>/<run>/` (lib/driver.sh ledger(): `cp -r "$REC/." "$d/"`), so once N1-01 copies memory-result.json into the record, N2-03's `harness memory proposals <run>` finds it there without a new copy step. → entries.jsonl:1
- Discovery (init, affects N2): memory_pr today merges only on the push branch (a new tier-1 commit): a reused PR with nothing new runs memory_edit alone and never memory_merge. N2-02's second continue therefore carries one more new fact so the normal push path merges after the successful edit; a merge of an already-pushed head on a bare body refresh would be a new behaviour the spec does not ask for. → entries.jsonl:1
- Discovery (init, affects run): Earlier runs' coding sessions on this code took 8–41 min (the 2026-11-07-2 run: builds 9–25, reviews 37–41); N1-01 is the largest feature of this run (curator.mjs, record.sh memory_pr, summary.mjs, memory-branch.sh together) and the brief fixes four features per milestone, so it may run long. The full suite was 701 s at init: a full-suite step gets a 1,500,000 ms timeout. → entries.jsonl:1

## Promote to Gotchas

- memory-branch.sh's worktree-count check (== 14) counts one worktree per stub run in the file: a new run there bumps it (agent-harness-2026-11-08 2026-11-08) → entries.jsonl:5
- A note given before the curator session (memory_base) is reverted by its restrict with harness-log.md; give it after ro_rescue, as curator() does with RULES_NOTE (agent-harness-2026-11-08 2026-11-08) → entries.jsonl:4

## What it builds on

- 2026-11-08 03:26 · N1-03 · passes: curator.mjs apply checks the cap per tier-1 op (order delete, replace, anchored add, plain add; a breach drops that op alone `over the cap: …`); an anchored add appends while it fits, evicts only past the cap (`evicted`, body `(in place of: …)`, an eviction note); `refused` retired from apply, body and memory_pr. stub-cap gains a replace; decision 2026-11-08-memory-rules-pr created.; tests 1898 → 1900; files lib/curator.mjs, lib/record.sh, prompts/curator.md, tests/unit/curator.test.mjs, tests/checks/memory-branch.sh, … → entries.jsonl:2
- 2026-11-08 03:48 · N1-02 · passes: Twins guarded: restrict memory reverts CLAUDE.md, .harness/project.md, .claude/CLAUDE.md and .claude/rules (now -z, unquoted paths); curator FILES, memory_base, memory_foreign, capCheck and the prompt take .claude/CLAUDE.md; memlint lints it on its own cap plus `twin`; STUB_DOT_CLAUDE; decision row, docs, prompts.; tests 1066 → 1069; files lib/record.sh, lib/curator.mjs, lib/memlint.mjs, prompts/curator.md, prompts/coding.md, … → entries.jsonl:3
- 2026-11-08 04:25 · N1-01 · passes: Tier 2 lands on harness-rules/<run> in a `memory rules: <run>` PR the driver never merges: apply cuts texts and ruleTexts from their bases under a union cap (graft), memory_pr runs one pass per tier, auto merges facts only, bodies number rules/proposals <run>/<n> and link each other, memory.json/report/ledger/harness memory count facts and rules apart.; tests 1069 → 1072; files lib/curator.mjs, lib/record.sh, lib/driver.sh, lib/summary.mjs, lib/memlint.mjs, … → entries.jsonl:4
- 2026-11-08 22:58 · N1-04 · passes: N1 review on Opus (attempt 1): 0 Critical, 1 Important, 8 Minor. Attempt 2 fixes the verify's step-3 miss: docs/architecture.md's prompts/curator.md row now names the three target files, the per-op cap, tier 2 on harness-rules/<run> in a memory rules: <run> PR Michael merges, and tier 3 in both bodies; the review file records it.; tests 1911 → 1911; files docs/architecture.md, docs/plans/2026-11-08-N1-review.md → entries.jsonl:8

## Lately in the run

- 2026-11-08 23:26 · verify N1 · passes: All four N1 features hold. Full suite 1911/1911 (778 s), fast tier green, targeted runs 27/27, 38/38, 37/37, unit files 91/91. Every named test read against its step. N1-04's architecture row for prompts/curator.md is fixed. N1-01 step 3's `1 proposals` is 0, as the brief says. A probe confirmed the union cap holds. → entries.jsonl:9
- 2026-11-08 22:42 · verify N1 · not yet: N1-01, N1-02, N1-03 hold: full suite 1911/1911 (734 s), fast tier 1073/1073, each step's targeted run green, the unit files 91/91, code and tests read. N1-04 step 3 fails: docs/architecture.md's prompts/curator.md component row was left unchanged in N1 while the prompt gained tier 2 on harness-rules/<run> and .claude/CLAUDE.md. N1-01 step 3's `1 proposals` is 0, as the brief says. → entries.jsonl:7

## Current rules

- The tiers and the files: tier 2 is a PR, the twins are guarded, the cap is per operation → journal/decisions/2026-11-08-memory-rules-pr.md
- The memory curator: itemized operations, a tier the driver derives, a protected list that is fixed → journal/decisions/2026-11-07-memory-tiers.md
- The gate replaces the lint: `memlint-self` retired, `MEMORY_POLICY`, and the curator's acceptance counted → journal/decisions/2026-11-07-memory-policy.md
- One writer for project memory: a coding session's `CLAUDE.md` edit is reverted, a fact goes in the entry → journal/decisions/2026-11-07-memory-one-writer.md
- Supervised efforts for every project: one user-level skill, one dispatch list per effort, plain names throughout → journal/decisions/2026-11-05-supervised-efforts.md

_99 older rules: journal/decisions._
