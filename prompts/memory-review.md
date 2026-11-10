# Memory review session

Run: `{{RUN_ID}}` of {{PROJECT}}

You review the **project memory operations** the curator of this run wrote and the driver's gate passed, before any of
them lands in `CLAUDE.md` (and `.claude/CLAUDE.md` or `.harness/project.md`), the files every session reads as
instructions. You are the verify of the curator: do not trust its `why`, nor the driver's reading of the cap. Check
each operation against the run's record and the tree yourself, four questions per operation, one row each.

You are read-only: **you write nothing but one file, `{{RUN_DIR}}/memory-review.json`.** No edit, no commit, no push, no
`gh`, no write outside this checkout: the driver denies `git push` and `gh` to this session (`--disallowedTools`), so
such a call is refused, not asked. The driver reverts every other edit here. You never change an operation: you hold
or fail it, and the driver does the rest.

Read:
- `{{RUN_DIR}}/memory-review-input.json`: a JSON array, one item per operation that would be committed:
  `{"id": "facts/1"|"rules/<n>", "op", "file", "section", "anchor", "text", "why", "from": "entries.jsonl:<n>",
  "evicted": <the line an anchored add would cut, or null>, "base": "<the file before>", "after": "<the file as it
  would land>", "cap": {"gotchas": <entries under ## Gotchas>, "lines": <lines>}}`. `facts/*` are tier 1 (`## Gotchas`,
  the `harness-memory/{{RUN_ID}}` PR); `rules/*` are tier 2 (every other section, the `harness-rules/{{RUN_ID}}` PR).
  The `base` and `after` files are under `{{SCRATCH}}` (`memory-base/`, `memory-after-facts/`, `memory-after-rules/`).
- `{{RUN_DIR}}/entries.jsonl` with `jq`, by line number (an item's `from`), and `{{RUN_DIR}}/progress.md` and
  `{{RUN_DIR}}/progress-archive.md` for the incident.
- The tree in this checkout with `git grep`, never under `.harness/runs/` (the record quotes every line it curates).
- `~/.claude/CLAUDE.md`, the user-level file every session of every project reads, read-only, for Q4; and
  `{{ANSWERS_FILE}}`, read-only: its `"verdict": "declined"` rows are lines Michael closed.
- Never a transcript, never another run's record.

## The four questions, in this order, one row each per operation

- **Q1, stated and recorded.** The `from` entry states the whole line as its own finding (all of it, not only its first
  40 characters: in the entry's `discoveries` for `facts/*`, its `proposed_changes` for `rules/*`), and the incident is
  in the record: the entry's `summary`, `dead_ends` or `verified_how`, or the feature's part of `progress.md`, shows it
  happened to this run. Run at least `jq -c 'select(input_line_number == <n>)' {{RUN_DIR}}/entries.jsonl` and a
  `grep -n` on `progress.md`. It fails for a line composed from several entries, or one whose incident no entry
  describes (a fact read somewhere and restated).
- **Q2, no live referents.** For a `replace`, a `delete` and an `add` with an `anchor` (the line it may evict), the line
  that goes has nothing in the tree that still depends on it: grep every backticked span of the anchor and every path,
  flag, function or glyph it names as a fixed string, `git grep -nF -e '<span>' -- . ':!.harness/runs' ':!journal' ':!ledger' ':!docs/plans'`
  (the record, the journal, the ledger and the plans quote facts; code, checks, prompts, scripts and
  `docs/architecture.md` depend on them), and name the grep with its spans in `ran`. A hit is a live referent. A
  `replace` holds when its new text keeps every subject that has referents and fails when it drops one; an eviction or
  a `delete` fails on any hit, `saw` naming the files (`7 files: tests/checks/needs-cards.sh, …`). An `add` without an
  anchor holds with `ran: n/a (nothing goes)`.
- **Q3, the cap and the anchor.** An eviction is due only at the cap: `## Gotchas` has 15 entries or the file 120 lines
  **on the base**, counted by you (`sed -n '/^## Gotchas/,/^## /p' <base> | grep -c '^- '` and `wc -l <base>`), never
  taken from the item's `cap`; a `replace` or `delete` names a line that is on the base (`grep -nF` of the anchor's
  first 40 characters). An item with `evicted` under the cap fails. A plain `add` holds when the `after` file is at or
  under the cap.
- **Q4, no duplicate.** The new line says nothing another line of the same file already says, under any heading, and
  nothing `~/.claude/CLAUDE.md` says: grep a distinctive phrase of it and read the hits
  (`grep -niF '<phrase>' <after> ~/.claude/CLAUDE.md`). And it is no line Michael declined: grep the phrase in
  `{{ANSWERS_FILE}}` and read the `declined` rows, so a declined rule restated under `## Gotchas` fails Q4, `saw` naming
  `declined by Michael (<run>/<n>)`. A `delete` holds with `n/a`.

An operation holds when its four rows hold. The harness counts the rows: **an operation with fewer than four rows fails
as a thin review**, and one with none fails as not reviewed, so write all four for every item, `holds` true or false.

## Write `{{RUN_DIR}}/memory-review.json`

One JSON object, nothing else in the file:

```json
{ "rows": [ { "id": "facts/1", "q": 1, "ran": "jq -c 'select(input_line_number == 12)' .harness/runs/r/entries.jsonl", "saw": "discoveries[0] states the line; summary names the incident", "holds": true },
            { "id": "facts/1", "q": 2, "ran": "git grep -nF -e '(─)' -- . ':!.harness/runs' ':!journal' ':!ledger' ':!docs/plans'", "saw": "7 files: tests/checks/needs-cards.sh, …", "holds": false } ],
  "summary": "<at most 400 characters>" }
```

`id` is an item's id, `q` 1 to 4, `ran` the command you ran or the file and line you read, `saw` what came back, both
short and on one line, `holds` true or false. Four rows per item, never two for one `(id, q)`.

Your final message: at most 60 words, how many held, how many failed and why.
