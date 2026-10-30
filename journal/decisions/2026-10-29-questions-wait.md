# Questions wait in `harness needs` until answered: one item per question, moved forward, no push

*(2026-10-29, run `agent-harness-2026-10-29-2`, R4-01 to R4-05; spec `docs/specs/2026-10-28-reliability.md` §R4, plan
`docs/plans/2026-10-29-R4-questions.md`, review `docs/plans/2026-10-29-R4-review.md`)*

- **Finding:** sessions never park on a judgment call: they take a default and write the question in their entry's
  `questions` (each naming its files, decisions/2026-10-27-question-locations). Those questions reached the run's
  `progress.md` and the debrief, which grepped `progress.md` for "question", and nowhere else: `harness needs` held
  only stops. Eight questions from the memory run sat for days, one ("should the review session's reviewer subagent
  follow the session's model?") was asked three times, and on 2026-10-28 Michael answered seven from a hand-built
  checklist (PR #44).
- **Choice:**
  - **A `question` reason** in `lib/needs.mjs` `REASONS`: kind `needs_michael`, severity `warn`, priority `""`.
    `journal_` (`lib/record.sh`, `questions_`), after an ingest that appended the entry, opens one item per question
    of that entry (`needs_open question "<text>" asker=<id> line=<entries.jsonl line> [feature=<id>]`) and notes
    `<id>: <n> question(s) for Michael recorded (harness needs)`. The card: `<asker> asked: <first line>`, the text
    as its `question` row, a `where` row per `Files:` path and the entry's `entries.jsonl` line, the command `harness
    needs done <ref> --why "<answer>"`; nothing parsed beyond the `Files:` line (the default is in the text).
  - **One open item per question:** `key` = `question:` + `questionKey(text)` (the harness's `Files (harness, from the
    session):` fill and a trailing `Files:` line cut, whitespace folded, lower-cased, the first 80 code points; the
    fill names the run's worktree, so a key over it would differ in every run; a second question of the same entry
    with the same 80 characters, a shared preamble, is `<key>#2`, so neither refreshes the other away). Asked again in the same run: refreshed
    (`seen + 1`, `updated_at`, the card's line the newest entry's). Asked in a later run of the same project while an
    earlier run holds it open: it **moves forward** (`moveForward`): the new item has `seen` = the olds' largest + 1
    and `asked_in` = the runs in order; each old one is renamed into its own run's `needs/done/` with `asked again in
    <run>`, the only write `needs.mjs` makes into another run's state dir.
  - **Resolved by** `harness needs done <ref> --why "<answer>"`; by the sweep, when a later entry of the run lists the
    question in `resolved` (`entries.mjs resolvedBy`, the context pack's own match, decisions/2026-10-26-resolved-and-
    project-facts; `answered in <feature>'s entry`), at once from `journal_` when the new entry has a `resolved`; and
    by the `harness-answer` skill, which on Michael's yes adds `Updated in place <date>: Michael <answer>` to the
    decision file the question's `Files:` names (or, naming none, passes the answer on with `harness answer`, so the
    run's next sessions read it under `## Answers`), then runs the `done`.
  - **Readers.** `harness needs` lists them after every block item (U2's order) and counts them apart (`NEEDS YOU 1 ·
    3 questions`); `harness status` too (`NEEDS YOU 1 · 3 questions · harness needs`; a run object's `needs` is the
    non-question count, `questions` the rest; the run card's `needs you` row keeps the stops), so a question never
    makes a run look stopped or hides a stop; the debrief's `#### Questions for Michael` is built from `harness needs
    --all --json` (12 at most, then `… and <n> more`), not a grep of `progress.md`; a run with no question item ever
    (asked before this) lists its entries' questions no later entry resolves (`entries.mjs questions`). No notification: `journal_` never calls `needs_notify`.
- **Rejected:**
  - **A push per question:** the memory run alone would have sent eight in a night, each for a call already made with
    a default that lets the work go on. A push is for what stops a run; questions are read in the morning view and
    the debrief.
  - **Parking on a question:** a judgment call would stop work that a reversible default lets go on, and a night
    spent waiting costs more than a default undone the next day. Parking stays for what has no safe default (a
    secret, a sudo step, an approval the policy requires).
  - **Detecting an answer from a decision file's text:** nothing links a question to a line reliably (a question
    names files, not lines to watch, and Michael's words don't repeat the question's). The skill writes the line *and*
    runs `harness needs done`, and a later entry's `resolved` is the session's own explicit statement.
