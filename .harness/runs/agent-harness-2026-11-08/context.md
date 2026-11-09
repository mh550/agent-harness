# Context pack for `N2-03`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (N2-02, affects N2-03, N2-04): mw now runs with STUB_FACTS=A,B,C and two continues (fact-b under STUB_GH_DOWN_ONLY=edit, fact-c with gh up) right after its check; the curator's pr edit is the run end's first, before record_pr's → entries.jsonl:11
- Discovery (N2-01, affects N2-02, N2-03, N2-04): stub argv records: $STUB_DIR/argv/<n>-<kind>.args, one arg per line, the -p prompt as <prompt>, then PWD= and HARNESS_RUN_ID= lines; filter a run's files with grep -lx HARNESS_RUN_ID=<run> → entries.jsonl:10
- Discovery (N2-01, affects N2-02, N2-03): curator-run.sh's proj has no ## Gotchas: a run there lands no tier-1 op unless origin main is seeded first (its cd run seeds Code rules and Gotchas) → entries.jsonl:10
- Discovery (N1, affects run): docs/architecture.md:105, the prompts/curator.md component row, still describes the pre-N1 prompt: N1-04's fix is one row that names tier 2 as a diff on harness-rules/<run> Michael merges and .claude/CLAUDE.md among the files. → entries.jsonl:7
- Discovery (N1, affects run): The spec's N1-01 step 3 expects `… 1 proposals` for mp, but three-ops has no tier-3 op; the code and checks read 0 (decisions/2026-11-08-memory-rules-pr, bodies row). A verify reading the steps literally should know this. → entries.jsonl:6
- Discovery (N1-04, affects N1, run): N1-02 reworded prompts/coding.md and where-things-go*.md to name .claude/CLAUDE.md and .claude/rules/; memory-prompts and gotchas-pack (slow) assert those sentences verbatim and were red until N1-04 → entries.jsonl:5
- Discovery (N1-04, affects N2, run): A stale facts tip (an open memory: <run> PR) after main moved can still merge past the cap; the drift covers the rules side only (pre-N1 behaviour, not changed) → entries.jsonl:5
- Discovery (N1-04, affects N2-01, N2-02, N2-03): curator.mjs apply's CLI takes 4, 5 or 7 args: a 6th and 7th (the rules tip's merge-base with main, main) give the union shadow's drift; memory_base writes them to $SCRATCH/memory-rules-mb and memory-main → entries.jsonl:5
- Discovery (N1-04, affects N2-03): Under RULES_STOP memory_pr moves the tier-2 ops to dropped ('the rules half stopped; its note says why') and renumbers the proposals from 1 → entries.jsonl:5
- Discovery (N1-01, affects N2-03, N1-04): The <run>/<n> numbering restarts at 1 every segment, and a reused rules PR's body appends the earlier segment's memory.md: two `### 1 ·` headings in one PR after a continue. N2-03's verb must say which segment (or offset n by the run's earlier max) (N1-01 review, not fixed). → entries.jsonl:4
- Discovery (N1-01, affects N2-03, N1-04): memory.json counts this segment only: a continue with no new tier-2 op rewrites the rules PR's memory.jsonl row (by url) to rules 0, sections [], as the facts row already does for applied (N1-01 review, not fixed). → entries.jsonl:4
- Discovery (N1-02, affects N1-04, run): lib/prompt.sh checks only a root CLAUDE.md: a project whose memory is .claude/CLAUDE.md alone gets 'this project has no CLAUDE.md' and the harness's routing block (N1-02 review, not fixed) → entries.jsonl:3
- Discovery (init, affects N2): N2-02's stub case cannot be the spec's `ma` run as it stands: under auto `ma`'s facts PR is merged in its first segment, so a continue opens a fresh PR (`pr create` carries its body, no `pr edit`). The reused-PR path needs an open facts PR at the continue: the `mw` run's shape (hand-pushed harness-memory/<run>, PR opened with no tier-1 commit, left open) with a continue that adds one tier-1 fact. tests/stub-gh.sh's `STUB_GH_DOWN_ONLY` regex takes any named sub-command, so `edit` works without a stub change. → entries.jsonl:1
- Discovery (init, affects N1, N2): The ledger copies the whole run record to `$LEDGER/<project>/<run>/` (lib/driver.sh ledger(): `cp -r "$REC/." "$d/"`), so once N1-01 copies memory-result.json into the record, N2-03's `harness memory proposals <run>` finds it there without a new copy step. → entries.jsonl:1
- Discovery (init, affects N2): memory_pr today merges only on the push branch (a new tier-1 commit): a reused PR with nothing new runs memory_edit alone and never memory_merge. N2-02's second continue therefore carries one more new fact so the normal push path merges after the successful edit; a merge of an already-pushed head on a bare body refresh would be a new behaviour the spec does not ask for. → entries.jsonl:1
- Discovery (init, affects run): Earlier runs' coding sessions on this code took 8–41 min (the 2026-11-07-2 run: builds 9–25, reviews 37–41); N1-01 is the largest feature of this run (curator.mjs, record.sh memory_pr, summary.mjs, memory-branch.sh together) and the brief fixes four features per milestone, so it may run long. The full suite was 701 s at init: a full-suite step gets a 1,500,000 ms timeout. → entries.jsonl:1

## Promote to Gotchas

- S_DENY is read with [[ -v S_DENY ]]: under set -u, ${#S_DENY[@]} on an unset array is an unbound-variable error (agent-harness-2026-11-08 2026-11-08) → entries.jsonl:10
- memory-branch.sh's worktree-count check (== 14) counts one worktree per stub run in the file: a new run there bumps it (agent-harness-2026-11-08 2026-11-08) → entries.jsonl:5
- A note given before the curator session (memory_base) is reverted by its restrict with harness-log.md; give it after ro_rescue, as curator() does with RULES_NOTE (agent-harness-2026-11-08 2026-11-08) → entries.jsonl:4

## What it builds on

- 2026-11-08 23:54 · N2-02 · passes: Under MEMORY_POLICY=auto a reused facts PR whose gh pr edit failed is no longer merged: memory_edit returns gh's status, memory_pass returns 1 for that case, memory_pr merges only on 0 and gives one note `memory PR: its body was not updated (see run.log); not merged (MEMORY_POLICY=auto), left open · <url>`. The next segment refreshes and merges. Docs, templates, decisions updated.; tests 1914 → 1916; files lib/record.sh, tests/checks/memory-branch.sh, tests/fixtures/check-names.txt, tests/fixtures/memory/stub-fact-b.json, tests/fixtures/memory/stub-fact-c.json, … → entries.jsonl:11

## Lately in the run

- 2026-11-08 23:41 · N2-01 · passes: The curator runs under --disallowedTools Bash(git push:*) Bash(gh:*): session() takes an S_DENY array (last on the claude -p line), curator() fixes CURATOR_DENY, logs `curator · <model> · deny …` and notes `curator: session denied …`. The stub records every headless argv in argv/<n>-<kind>.args; STUB_CURATOR_PUSH pushes unless denied. Decision file created; docs updated.; tests 1911 → 1914; files lib/record.sh, lib/driver.sh, prompts/curator.md, tests/stub-claude.sh, tests/checks/curator-run.sh, … → entries.jsonl:10
- 2026-11-08 23:26 · verify N1 · passes: All four N1 features hold. Full suite 1911/1911 (778 s), fast tier green, targeted runs 27/27, 38/38, 37/37, unit files 91/91. Every named test read against its step. N1-04's architecture row for prompts/curator.md is fixed. N1-01 step 3's `1 proposals` is 0, as the brief says. A probe confirmed the union cap holds. → entries.jsonl:9

## Current rules

- The memory session and the answers: a denied curator, an `auto` that keeps its body, answers the next curator reads → journal/decisions/2026-11-08-memory-session-and-answers.md
- The tiers and the files: tier 2 is a PR, the twins are guarded, the cap is per operation → journal/decisions/2026-11-08-memory-rules-pr.md
- The memory curator: itemized operations, a tier the driver derives, a protected list that is fixed → journal/decisions/2026-11-07-memory-tiers.md
- The gate replaces the lint: `memlint-self` retired, `MEMORY_POLICY`, and the curator's acceptance counted → journal/decisions/2026-11-07-memory-policy.md

_101 older rules: journal/decisions._
