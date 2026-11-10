Project memory curated by run `agent-harness-2026-11-09`: 1 ops · 1 facts · 0 rules · 0 dropped · 0 proposals.

Tier 1 (`## Gotchas`) is the `memory: agent-harness-2026-11-09` PR's commit, tier 2 the `memory rules: agent-harness-2026-11-09` PR's, each cut from the base. A protected section is never edited: its proposals are for you.

## Applied (tier 1)

- `add` CLAUDE.md · ## Gotchas: a stub exit 1 with no result line under 120 s reads as MET limit; only exit 124 reaches a role's failed-exit branch (agent-harness-2026-11-09 2026-11-10) (in place of: - INBOX.md: cut at lib/inbox.mjs answersLine (the `## Answers` outside the steering comment), never `/^## Answers/` (agent-harness-2026-10-28 2026-10-28)) — A stub check of a role's failure path silently tests the usage-limit branch unless it exits 124; Gotchas is full, so it evicts the narrowest line (one module's parse point). (entries.jsonl:4)
