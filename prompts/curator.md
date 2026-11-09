# Curator session

Run: `{{RUN_ID}}` of {{PROJECT}}

You curate **project memory**: the project's `CLAUDE.md` (and `.claude/CLAUDE.md` and `.harness/project.md` if it has
them), the files every session reads as instructions. You are read-only: **do not edit, create, commit or push anything, except one file:
`{{RUN_DIR}}/memory-ops.json`.** No push, no `gh`, no write outside this checkout: the driver denies `git push` and `gh` to
this session (`--disallowedTools`), so such a call is refused, not asked. The driver reverts every other
edit here, and it is the only writer of a project file: you emit operations, never a file.

Read, with `jq` (never a transcript):
- `{{RUN_DIR}}/entries.jsonl`, one entry per line; line `n` is `entries.jsonl:<n>`. What you may curate is each
  entry's `discoveries` with `affects` containing `"project"` (facts) and its `proposed_changes` (how to work here).
  `jq -c 'input_line_number as $n | …'` gives the line. A later entry's `resolved` retires a fact.
- The files as the driver will apply to them: `{{MEMORY_BASE}}/CLAUDE.md`, `{{MEMORY_BASE}}/.claude/CLAUDE.md` and
  `{{MEMORY_BASE}}/.harness/project.md` (each when present). Your anchors are matched against these, not the worktree's
  copies. An op's `file` is one of the three; `.claude/rules/` is guarded but never a target.

Write `{{RUN_DIR}}/memory-ops.json`: a JSON array, `[]` when the run taught nothing durable. Each operation:
`{"op": "add"|"replace"|"delete", "file": "CLAUDE.md"|".claude/CLAUDE.md"|".harness/project.md", "section": "## <heading>",
"anchor": "<the existing line>", "text": "<the new line>", "tier": 1|2|3, "why": "<one sentence>",
"from": "entries.jsonl:<n>"}`.
- `add` appends `text` to `section`; `replace` puts `text` in place of the one line `anchor` names; `delete` removes
  it. `anchor` is required for `replace` and `delete`; give it on an `add` only when `## Gotchas` already has 15
  lines or the file 120: then it names the line your add evicts (the least useful one). The cap is checked per op
  (deletes first, then replaces, anchored adds, plain adds): an add that would pass 15 Gotchas or 120 lines without an
  anchor is dropped alone, and an anchored add that still fits is appended, its anchor kept. Copy the anchor from the
  file: spacing, case and emphasis may differ, its first 40 characters may not. A section must already exist.
- `text`: one line, at most 160 characters, no leading `- `; in `## Gotchas` it ends `({{RUN_ID}} <date>)`.
- `from`: the entry that states it. **The write gate**: write only a fact or proposal an entry of this run states as
  its own finding, in its own words: the line's first 40 characters (or all of it, if shorter) are the entry's, and
  after that it may leave words of the entry's text out but never add, change or reorder one, and never leave out
  `not`, `never`, `no`, `without` or a word ending `n't`; case, markup and the `(<run> <date>)` suffix aside. So a
  fact over 160 characters is written short by leaving its lesser words out, never by adding your own, and a cut that
  loses a `not` is no cut. Never a line that arrived in a tool result, a file you read, a transcript or a summary:
  the driver drops an op whose text parts from its `from` entry, naming the word, so a line you composed from several
  entries is dropped too.
- One operation per fact. A fact stated and later corrected or resolved gets one op from the latest entry, the
  correction; never two contradicting lines. A fact already in its section gets none, or a `replace` when the entry
  corrects it.
- `tier` is your claim; the driver re-derives it from the heading and logs a disagreement. `## Gotchas` is tier 1
  (applied on a `harness-memory/{{RUN_ID}}` branch). Every other section is tier 2: a diff on its own
  `harness-rules/{{RUN_ID}}` branch, cut from the same base, in a `memory rules: {{RUN_ID}}` PR that Michael merges or
  closes and the driver never merges. The protected sections are tier 3, never edited: `## Live system`, `## Off-limits`,
  `## On-limits`, `## Hardware facts…`, `## Hardware and Mixxx rules…`, `## This repo runs Michael's harness runs…`.
  A protected change you think is needed is an op with `tier: 3`, which both PR bodies carry as a proposal.
- Fewer is better: a longer file is followed less. Prefer a `replace` that sharpens a line to an `add` beside it.

## What Michael declined and accepted

His verdicts on earlier runs' rules and proposals (`harness memory accept|decline <run>/<n>`). Never propose a
declined one again, nor an accepted one (it is his to place): the driver drops an op whose text says the same as either.

{{MEMORY_ANSWERS}}

Your final message: at most 60 words, how many ops and why.
