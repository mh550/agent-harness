# The memory reviewer: one read-only session on what would land, four questions per operation, under the curator's deny list

*(2026-11-09, run agent-harness-2026-11-09, R1 (the session and its input by R1-01, the verdict and what lands by R1-02, the review's fixes by R1-03); spec
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
    memory-review.json`, `the reviewer hit a limit`, `the review input failed (see run.log)`, and since R1-03 `the landing differs from the dry apply`) whenever the curation
    reached the review; R1-02 validates the file and counts the verdicts.
  - **Q4 reads the declined rows of `ledger/memory-answers.jsonl`, read-only** (the brief's addition): the prompt names
    the file (`{{ANSWERS_FILE}}`, the ledger the driver uses), so a rule Michael declined that a curator restates under
    `## Gotchas` (tier 1, which `apply`'s answers never match) fails Q4 with `declined by Michael (<run>/<n>)`.
  - The stub (`tests/stub-claude.sh`, `# Memory review session`): `STUB_MEMORY_REVIEW=hold|evict-fails|thin|none|bad|limit`
    and `STUB_MEMORY_REVIEW_EDITS=1`; the checks are `tests/checks/memory-review.sh` (slow by the brief) and
    `tests/unit/memreview.test.mjs`. The prompt check stays in `memory-review.sh`, the curator's twin in
    `curator-run.sh` (*default*: no `memory-prompts.sh` fold).
- **Choice (R1-02):**
  - **The verdict.** `memreview.mjs validate` refuses `memory-review.json` whole with its first reason, naming the row
    (an id not in the input, a `q` outside 1–4, a non-string `ran`/`saw`, a non-boolean `holds`, a doubled `(id, q)`,
    more than four rows per item): `memory review: none (memory-review.json invalid: <reason>)`. `verdicts`: an op holds
    on four holding rows; it fails on its first failing row by `q` (`<saw> (q<n>)`), as `review too thin (<k> of 4
    rows)` with fewer than four, as `not reviewed` with none. **Thin is a fail, not an escalation** (*default*: Opus is
    already the review model, and under `pr` a fail leaves the op in front of Michael). Cells are cut to
    `entries.mjs` `ROW_MAX` (200) where they are rendered and in the reason; the prompt asks for at most 200
    characters, so 50 ops × 4 rows (about 92 KB) stay under the 256 KB `ro_rescue` takes for this role (64 KB at first: found by R1-03's review).
  - **One table renderer**: `entries.mjs` `evidenceTable(rows, [first, second])`, used by `renderEntry` (Feature, Step;
    its output byte-identical, a unit test on its hash) and `render` (Op, Q). `## Review` goes after the body's head in
    both PR bodies and `memory.md`; over `BODY_MAX` its table is cut first, whole, with a line saying so, and its
    one-line verdicts never (*default*: whole, not row by row; memory.md and memory-review.json keep every row).
  - **What lands, by policy** (*default*): under `pr` every op the gate applied lands, failed ones included, marked in
    `## Review` (the diff stays the curator's, and R2's override count has something to read). Under `auto` the landing
    is `apply … --verdicts`: a failed tier-1 op is **dropped at its write, never removed from the input list**, after
    every other step ran on the full list and on the texts the dry run wrote (the duplicate-key choice, the cap, each
    later op's anchor), so no op the reviewer did not see can take its place; the held ones are written again on the
    base in order and capped there (a failed delete that made room makes the add after it the 16th: dropped, `over the
    cap once the review's failed ops were dropped: …`). A fact with no verdict is dropped as `not reviewed`. The
    landing first runs plain (R1-01's guard against the dry apply), then again with the verdicts, and a result other
    than the dry one minus held-or-failed facts (rules, proposals, ruleTexts and the gate's drops unchanged) commits
    nothing. A review drop counts in `failed`, never in `dropped` (the gate's meaning); `applied` stays the gate's count.
    Every facts op failed: `memory PR: none (no tier-1 change after the review)`.
  - **The rules PR carries every op with the verdict under every policy and is never merged** (`apply` never drops a
    tier-2 op by verdict; follow-up invariant 3).
  - **No review, no merge** (*default*; invariant 3): no file, an invalid file, `MET limit`, a non-zero exit (a timeout's
    too) → `## Review` `none: <why>`, every op lands as under `pr`, and under `auto` `memory_merge` is not called:
    `memory PR: no review (<why>); not merged (MEMORY_POLICY=auto), left open · <url>`. A continue's review runs again
    on what is new, but **the reused PR merges only when its one commit past main is this segment's own**: the range
    counts from the main sha `memory_base` fetched, never a ref, and anything else on `harness-memory/<run>` (an earlier
    segment's commit, or one a session pushed with the driver's subject and paths) leaves the PR open, `memory PR:
    <sha12> on harness-memory/<run> is not this segment's commit; not merged …`; a git error reads as not merged.
    *Default*, the brief's rule over the spec's §5, which had the continue merge the earlier segment's unreviewed
    commit with the new one (found by R1-02's review; asked in the entry). The PR then waits for Michael. Updated in
    place 2026-11-10 (R1-03's review, I1): R1-02 had the driver write a `Memory-review: held` trailer into a held facts
    commit and merge a range whose every commit carried it; any session can push (the deny list is a prefix rule, and
    coding sessions carry none), so the trailer vouched for nothing, and `memory_foreign` checks only the subject, the
    paths and one parent. The cost: N2-02's continue that refreshed a failed body no longer merges the earlier commit
    with its own (decisions/2026-11-08-memory-session-and-answers, updated). Rejected: a list of held heads in the run
    record (a session can hide a planted line from `restrict` with a `.gitignore`), `origin/<main>` as the range's
    start (a session can move a local ref), the trailer (above), and an earlier commit's diff put to this segment's
    reviewer as a `carried/<sha12>` item (a second input shape for a case Michael's merge already settles).
  - **The reviewer cannot move what lands from outside the tree**: it runs with no filesystem sandbox, so the sums of
    every file the landing reads or compares against (the ops, the dry result and its texts, the bases, the input,
    `ledger/memory-answers.jsonl`) are taken before its session and compared after it; a change commits nothing, the
    same note as R1-01's guard (found by R1-02's review: rewriting the ops and the dry result together passed it).
  - In the `--verdicts` replay a held add already in its section once a failed replace kept its line is dropped, and a
    replay whose held facts would take the union of both PRs past the cap lands no fact at all (fail closed).
  - `memory.json` gains `held`, `failed` and `merged_by` (`driver` when `memory_merge` merged it); the report's `Memory`
    row ends `· review <h> held · <f> failed` or `· review none (<why>)`, nothing for an older file. `prompts/curator.md`
    says a reviewer checks every op and that a `replace` keeping the subject beats an eviction.
- **Choice (R1-03, the milestone's review: 0 Critical, 3 Important, 8 Minor; `docs/plans/2026-11-09-R1-review.md`):**
  - **The commit is the text the landing wrote** (I2): the reviewer, like the curator, runs with no filesystem
    sandbox and can write a hook, a filter or an attribute into the shared git dir, which acts after the landing's
    texts were compared with what it read. `memory_pass` takes each file's raw blob (`git hash-object --no-filters`)
    before `git add` and compares the commit's blobs with them; a difference pushes nothing, `<memory PR|memory rules
    PR>: the commit differs from the text the landing wrote (a git hook or filter?); not pushed (see run.log)`. A
    project whose own attributes normalise these files (an `eol` rule on CRLF text) fails closed the same way
    (*default*). Not closed by any check of the driver's: code a session plants in `$HARNESS_HOME` or a git config's
    command hooks (`core.fsmonitor`); the boundary there is the deny list, the prompt and `restrict`.
  - No review counts a timeout: a session cut by the driver's timeout (exit 124) after writing a valid file is
    `the reviewer failed (exit 124)` (I3, a check of the branch that had none; `STUB_MEMORY_REVIEW=hold-exit`).
  - The sums guard's refusal reads `review: "the landing differs from the dry apply"` in `memory.json`, not `ok`
    (M2). `ro_rescue` takes a size: 256 KB for `memory-review.json` (M3). A fact the review dropped is a failed one in
    the bodies too: never in the head's `dropped` count nor under `## Dropped` (M4). The prompt names
    `memory-rules-base/` as a `rules/*` item's base (M7).
  - Not fixed (Minor, in the review file with why): Q3's cap read on the base alone while the gate also evicts for
    the union of both PRs (M5: fails closed, needs a union reading in the input); a CLI that exits 0 on max turns
    (M6: unconfirmed, and no captured transcript to copy a fake from).
  - **Checks.** R1 adds 38 names to `tests/fixtures/check-names.txt` and removes 2 (+36 net) against the budget of 35:
    the review's two (the hook check, the body's dropped count) are the overrun. Removed, each with its successor
    (decisions/2026-11-03-trim's rule): `curator: its run.log line comes after the retro's, its notes before the record
    PR's` → `curator: its run.log line comes after the retro's, its notes and then the memory review's before the
    record PR's` (R1-01); `memory PR: the next segment refreshes the reused PR's body and merges it at the commit it
    pushed` → `memory PR: under auto the next segment refreshes the reused PR's body and leaves it open: the earlier
    segments' commits on it are not its own, a held trailer on one included` (R1-03). R1-02's `memory review: with no
    review (no file, an invalid file, a limit) …`, never on main, became `… (no file, an invalid file, a limit, a
    timeout after a valid file) …`.
- **Rejected:** reviewing `memory-ops.json` raw (spends the reviewer on ops the gate drops anyway, and shows it a tree
  the driver would not write: an under-cap anchored add lands as a plain add since Decision 24); reviewing tier 3; a
  deny list of the reviewer's own (two arrays can drift; the floor is one); running the review on the landing
  worktree itself (the landing must wait on the verdict under `auto`, R1-02, so the reviewer reads copies). R1-02: thin as an escalation to a stronger model (Opus is the review model); failed ops
  dropped under `pr` too (the PR would be the reviewer's, not the curator's, and nothing would be left to override); a
  failed op removed from the list before `apply` (the duplicate-key loser or an op the cap dropped could land in its
  place, unseen); tier 3 reviewed (it lands nowhere); dropping failed rules by verdict (the rules PR is Michael's).
