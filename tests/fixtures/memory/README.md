# Fixtures for lib/curator.mjs (tests/unit/curator.test.mjs), one line each

- `headings.txt`: the eight projects' `## ` headings with the tier `tierOf` gives each (M2-01, read from `~/projects/<p>/CLAUDE.md` on 2026-11-07, never edited).
- `corrected.entries.jsonl`, `corrected.ops.json`: harm case, a fact stated (`entries.jsonl:2`) then corrected (`:3`) under one key; two ops → one applied, the correction, the other dropped as a duplicate key.
- `unstated.entries.jsonl`, `unstated.ops.json`: harm case, an op whose text no entry states → dropped by the write gate.
- `tool-result.entries.jsonl`, `tool-result.ops.json`: harm case, a line from a tool's output (in the entry's `summary` and `verified_how`, not its `discoveries`), and a stated fact with an unstated tail after its first 40 characters → both dropped by the write gate.
