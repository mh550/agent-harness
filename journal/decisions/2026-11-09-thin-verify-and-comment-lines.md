# The thin verify names its missing steps; a comment line is not a Gotcha

*(2026-11-09, a session on `main` for two fixes in one PR; the cases: run `agent-harness-2026-11-08` (its record under
`.harness/runs/agent-harness-2026-11-08/`: `harness-log.md` 05:39, `progress-archive.md`'s two `verify N1` entries,
`retro-proposals.json`), PR #137 (`memory: agent-harness-2026-11-07-3`, the first memory PR) and PR #148 (which took the
comment line out of this repo's `## Gotchas`); the retro proposal `verify-evidence-rows`, in the `retro-proposals.json`
of eleven runs from `agent-harness-2026-10-28` to `agent-harness-2026-11-08`; `docs/specs/2026-11-08-memory-reviewer.md`'s
provenance row on PR #137, corrected here.)*

- **Finding:**
  - *The thin verify.* `verify N1` ended `evidence still short of the steps (N1-03 6/7; N1-02 6/7; N1-01 7/8) after opus;
    not verified (needs Michael)` although every step held: the verifier folded each feature's last step (the fast tier)
    into the row before it (`bash tests/run.sh memory-branch; bash tests/run.sh --tier fast` as one row), on Sonnet and
    on Opus alike. The note said only the counts, so Michael opened `progress.md` and counted; the card said `evidence too
    thin`; and the escalated round's prompt was the first round's prompt on a stronger model, told nothing of what fell
    short, so it fell short the same way. Ten retros before this run's had proposed `verify-evidence-rows` (per-step
    rows that can be audited) and this run's retro made it eleven.
  - *The comment line.* `templates/project/CLAUDE.md` opens `## Gotchas` with `<!-- At most 15 lines, one fact each,
    edited in place … -->` (this repo's `CLAUDE.md` did too, until PR #148). `sectionEntries` in `lib/memlint.mjs`
    counted it as an entry, so `memlint` said `gotchas: 16 lines, over 15` on `main` with 15 facts (every segment of run
    `agent-harness-2026-11-08` noted it), the curator's `capCheck` saw an over-cap section and dropped every add, and
    PR #137's one `add` evicted a line at 14 facts plus the comment: **at the cap by the curator's count (15 of 15), not
    under it**, where `docs/specs/2026-11-08-memory-reviewer.md` had said `14 of 15`. The eviction was the rule working
    on a wrong count, not a rule breach.
- **Choice:**
  - `evidence` (`lib/features.mjs`) reads each row's step cell and returns, per feature, `rows`, `steps` and `missing`
    (the step numbers no row names); `shortfall` turns that into the note's words, `N1-03 6/7: step 7 has no row`
    (`steps 6 and 7 have no row` for several), one entry per short feature, `; `-joined. **The rule is unchanged**: a
    feature is short when it has fewer rows than steps; two rows for one step still count as two, and a row whose step
    cell is no number counts as a row and names no step (*default*). Both notes (`evidence short of the steps (…);
    re-running on …` and `evidence still short … after …`) carry it, and the lane passes it to the card as `short=`:
    the `verify_thin` card's why ends `only the evidence is short: N1-03 6/7: step 7 has no row.` (*default*: the
    headline stays `not verified: evidence too thin`, the notification's title and body as before).
  - The escalated round is told what to repair: `verify()` keeps the first round's shortfall and renders it as
    `{{THIN}}` into a section `## The round before this one` under *This session* (`{{?THIN}}` lines, so the first
    round's prompt has no such section and the shared prefix above `{{SECTIONS}}` is untouched). `prompts/verify.md`
    also says, in step 4, that a step that runs the suite or the fast tier gets its own row, never folded into the row
    before it, and that a step whose wording is wrong still gets its row, `holds` true or false with the reason.
  - This answers the retro proposal `verify-evidence-rows`: the per-step rows were always written (`entries.jsonl`'s
    `evidence`), what was missing was the harness saying which steps had none. The backlog row is the supervisor's to
    close.
  - An HTML comment on one line (`^\s*<!--.*-->\s*$`, `COMMENT_LINE`) outside a code fence is no entry in
    `sectionEntries`: 15 facts and the comment are at the cap, not over; `gotchasDiff` ignores it; the curator's
    `capCheck` counts it as nothing, so an add at 14 facts lands and an anchored add at 15 evicts rather than drops.
    An add into a section whose only line is the comment lands under the comment, not between it and the heading
    (`write` in `lib/curator.mjs`). An opener without its close on the same line stays a line (*default*: a multi-line
    comment is rare in a memory file and a rule for it would need to pair openers and closers across entries). The
    template keeps its comment. The spec's provenance row now says `15 of 15 lines by the curator's count (14 facts and
    the comment line)`.
  - The stub's thin round (`STUB_THIN_VERIFY`) now writes every row but each feature's last step's, the shape of the
    case, and keeps each verify round's prompt in the run's scratch (`verify-<m>-<n>.prompt.md`), since two stub rounds
    in one second share the driver's `logs/<HHMMSS>-verify-<m>.prompt.md` name.
- **Rejected:**
  - Counting a folded row as two rows when its `ran` names two commands: the verifier's entry would then pass on a
    guess about its prose, and `holds` would stand for two steps at once. The row per step is the contract; the fix is
    to say which step is missing.
  - Reading `step` numbers to make the rule "a row per step number" (so two rows for step 1 and none for step 2 would be
    thin even at the count): a stricter rule than the one the runs were measured under, and not what the case needed.
  - Dropping the comment from the template instead of ignoring it in the count: the comment is the one line that tells
    a reader the section's rule, and every project initialized from the template already has it.
