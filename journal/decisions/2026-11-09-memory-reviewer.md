# The memory reviewer: one read-only session on what would land, four questions per operation, under the curator's deny list

*(2026-11-09, run agent-harness-2026-11-09, R1 (the session and its input by R1-01); spec
`docs/specs/2026-11-08-memory-reviewer.md` §R1; Decision 27 (a), Michael, 2026-11-08 (`docs/plans/2026-11-03-test-suite-redesign-dispatch.md`,
row F3f); journal/learning/2026-11-07-memory-curator.md §11 answer 2 (Opus for reviews); the run's brief (2026-11-09
22:45: proceed on the defaults, Q4 reads the declined rows of `ledger/memory-answers.jsonl`); the follow-up's names as
built: decisions/2026-11-08-memory-rules-pr, decisions/2026-11-08-memory-session-and-answers.)*

- **Finding:** the curator's operations pass one mechanical gate (`lib/curator.mjs` `apply`: the line's first 40
  characters are its entry's, the anchor matches one line, the cap) and then land in a PR whose only judge is Michael,
  who does not hold the project's context. PR #137 applied an anchored add that evicted a Gotcha seven check files
  depend on, under the cap; the supervisor caught it by hand with a `grep -rlF`. A verify session already has the shape
  this needs (claims given, none trusted, one evidence row per claim, the rows counted), and a read-only session with
  one output file rescued around `restrict … nothing` is the curator's own shape (`ro_rescue`).
- **Choice (R1-01):**
  - A new session role, `memory-review` (`prompts/memory-review.md`, `memory_review()` in `lib/driver.sh`), called
    from `memory_pr` between a dry apply and the landing. Model `MEMORY_REVIEW_MODEL=opus` in `lib/config.sh` beside
    `CURATOR_MODEL` (*default*: Opus, answer 2; a knob, so a project may run it on Sonnet once the falsifiers are read).
    `MAX_TURNS=40 SESSION_BUDGET_USD=3`, the curator's bound (*default*). Transcript `zz-memory-review-<HHMMSS>.jsonl`,
    one `memory review · <model> · deny …` run.log line, a `memory-review` metrics row.
  - Under the curator's deny list, the same array (*default*: `Bash(git push:*)`, `Bash(gh:*)`, nothing added; every
    other write is reverted). `CURATOR_DENY` moved from a local of `curator()` to one top-level array of
    `lib/driver.sh` that both roles read, so the reviewer's `S_DENY` can never be empty by being called from elsewhere
    (`grep -n S_DENY lib/*.sh`: the curator's and the reviewer's lines). One note says so, `memory review: session
    denied Bash(git push:*), Bash(gh:*)`; `ro_rescue <start> memory-review.json memory-review` keeps its one file and
    reverts the rest (`memory review: reverted edits (it is read-only): <paths>`).
  - **The gate first, the reviewer on what passed** (*default*): `memory_pr` runs `apply` once on a copy of
    `memory-base/` (`$SCRATCH/memory-after-facts/`, tier 1 written by apply) and writes tier 2's `ruleTexts` into a copy
    of the rules base (`$SCRATCH/memory-after-rules/`); `memreview.mjs input` turns that result into
    `memory-review-input.json`: `facts/<i>` in apply's order and `rules/<n>` with `memory-result.json`'s `<run>/<n>`
    number, each with `op`, `file`, `section`, `anchor`, `text`, `why`, `from`, `evicted`, its `base` and `after` paths
    and the gate's cap reading of its base (`{gotchas, lines}`). A rules item's `base` is `memory-rules-base/` (the
    base its commit is cut from), not `memory-base/`: the two hold the same text unless a rules PR of an earlier
    segment is open, and then the rules base is the one the cap and the anchor are counted on (*default*). The gate's
    counts and drops are noted from the dry apply, before the review; the landing is the same apply in the scratch
    worktree, deterministic, so it writes what the reviewer read. **It fails closed**: the session runs with no
    filesystem sandbox, and the apply's inputs outside the tree (`$SCRATCH/memory-ops.json`, the rules bases) are out
    of its revert's reach, so a landing whose result differs from the dry apply's, or whose tier-1 file differs from
    `memory-after-facts/`, commits nothing: `memory: the landing differs from the dry apply the reviewer read; no memory
    PR (see run.log)`, the diff in run.log (found by R1-01's review).
  - The input is committed to the record branch (`rec_commit`) before the session's start is taken: `restrict …
    nothing` reverts every uncommitted file since that start, the input and the notes before it included. An earlier
    segment's `memory-review-input.json` and `memory-review.json` are removed first, so a continue's review never sits
    beside the last one's and an identical rewrite still counts as written (at the top of `memory_pr`, so an invalid or
    empty ops file of a later segment leaves none either).
  - **Tier 3 is not reviewed** (*default*: proposals are text for Michael and land nowhere); an op the gate dropped is
    not an item and keeps the gate's reason.
  - **Skipped with nothing to review** (*default*): when the dry apply's `applied` and `rules` are both empty, no
    session and no input file, one note `memory review: nothing to review`, `memory.json`'s `reviewed: 0` and
    `review: "nothing to review"`; `memory_pr` goes on as before (no ops at all stays the curator's `curator: no
    operations`, upstream, with no review keys).
  - `memory.json` gains `reviewed` (the input's items) and `review` (`ok`, or why none: `the reviewer wrote no
    memory-review.json`, `the reviewer hit a limit`, `the review input failed (see run.log)`) whenever the curation
    reached the review; R1-02 validates the file and counts the verdicts.
  - **Q4 reads the declined rows of `ledger/memory-answers.jsonl`, read-only** (the brief's addition): the prompt names
    the file (`{{ANSWERS_FILE}}`, the ledger the driver uses), so a rule Michael declined that a curator restates under
    `## Gotchas` (tier 1, which `apply`'s answers never match) fails Q4 with `declined by Michael (<run>/<n>)`.
  - The stub (`tests/stub-claude.sh`, `# Memory review session`): `STUB_MEMORY_REVIEW=hold|evict-fails|thin|none|bad|limit`
    and `STUB_MEMORY_REVIEW_EDITS=1`; the checks are `tests/checks/memory-review.sh` (slow by the brief) and
    `tests/unit/memreview.test.mjs`. The prompt check stays in `memory-review.sh`, the curator's twin in
    `curator-run.sh` (*default*: no `memory-prompts.sh` fold).
- **Rejected:** reviewing `memory-ops.json` raw (spends the reviewer on ops the gate drops anyway, and shows it a tree
  the driver would not write: an under-cap anchored add lands as a plain add since Decision 24); reviewing tier 3; a
  deny list of the reviewer's own (two arrays can drift; the floor is one); running the review on the landing
  worktree itself (the landing must wait on the verdict under `auto`, R1-02, so the reviewer reads copies).
