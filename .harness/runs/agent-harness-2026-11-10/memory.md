Project memory curated by run `agent-harness-2026-11-10`: 1 ops · 1 facts · 0 rules · 0 dropped · 0 proposals.

Tier 1 (`## Gotchas`) is the `memory: agent-harness-2026-11-10` PR's commit, tier 2 the `memory rules: agent-harness-2026-11-10` PR's, each cut from the base. A protected section is never edited: its proposals are for you.

## Review

1 reviewed · 0 held · 1 failed

- facts/1 **fails**: 4 files: docs/architecture.md:81, lib/record.sh:499, tests/unit/curator.test.mjs:215, tests/checks/no-answer.sh:5 (q2)

| Op | Q | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| facts/1 | 1 | jq -c 'select(input_line_number == 8)' entries.jsonl; grep -n docs/plans progress.md progress-archive.md | V2-03 discoveries[2] states the line (plus CHECK_KEY_IGNORE parenthetical); dead_ends: checklist read from docs/plans failed check-key lint; progress.md:34 | yes |
| facts/1 | 2 | git grep -nF -e 'tests/checks/no-answer.sh' -e 'safe branch' -e '.mjs answer may be empty' -- . ':!.harness/runs' ':!journal' ':!ledger' ':!docs/plans' | 4 files: docs/architecture.md:81, lib/record.sh:499, tests/unit/curator.test.mjs:215, tests/checks/no-answer.sh:5 | no |
| facts/1 | 3 | sed -n '/^## Gotchas/,/^## /p' memory-base/CLAUDE.md \| grep -c '^- '; wc -l; grep -nF anchor | base 15 gotchas, 97 lines: at the cap, eviction due; anchor is base line 96; after 15 gotchas, 97 lines | yes |
| facts/1 | 4 | grep -niF -e docs/plans -e docs/specs -e CHECK_KEY memory-after-facts/CLAUDE.md ~/.claude/CLAUDE.md; grep ledger/memory-answers.jsonl | only the new line 96 hits; ~/.claude/CLAUDE.md none; memory-answers.jsonl absent, no declined rows | yes |

## Applied (tier 1)

- `add` CLAUDE.md · ## Gotchas: A check may not read docs/plans or docs/specs: a doc a check keeps true lives under docs/ or tests/ (agent-harness-2026-11-10 2026-11-10) (in place of: - ask and its spawn can both fail, so an .mjs answer may be empty: give the bash a safe branch (tests/checks/no-answer.sh) (agent-harness-2026-11-07 2026-11-07)) — A check reading docs/plans or docs/specs breaks the check key; this run had to move a doc for it, and the evicted line is one module's narrow case. (entries.jsonl:8)
