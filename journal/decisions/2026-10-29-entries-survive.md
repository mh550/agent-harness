# Entries that survive: the session checks its own, a long summary is cut and kept, one resume for a missing one

*(2026-10-29, run `agent-harness-2026-10-29-2`, R2-01 to R2-05; spec `docs/specs/2026-10-28-reliability.md` §R2, plan
`docs/plans/2026-10-29-R2-entries.md`, review `docs/plans/2026-10-29-R2-review.md`)*

- **Finding:** a session's `entry.json` is the run's memory of it (its dead ends, discoveries and questions feed the
  next pack and `progress.md`), and any fault in it threw all of that away for a minimal entry built from git. The
  10-26 to 10-28 runs lost them two ways: a summary a few characters over 400 (`U1-05` 410, `P2-01` 413: the whole
  entry minimal for one cap), and a session that wrote none (`U1-03`; the 10-26 retro's P1-03, about 50 minutes lost,
  ended its turn on a pending background review). Sessions had no way to check an entry before they ended; the
  driver had no way to ask again.
- **Choice:**
  - **The entry check.** `prompt_env` exports `HARNESS_ENTRY_CHECK="node $HARNESS_HOME/lib/entries.mjs validate"`;
    the finish steps of `prompts/coding.md`, `verify.md` and `initializer.md` end with running `{{ENTRY_CHECK}}
    <run directory>/entry.json <id> <kind>` and fixing every line it prints. The same three say never to end the turn
    while a background task or subagent still runs (wait for it, or stop it and say so in the entry). `validate`
    exits 0 valid, 2 when every error is a cap (`onlyCaps`), 1 otherwise.
  - **The trim.** `journalEntry` (`lib/entries.mjs`): an entry whose only faults are the `summary` (400) and/or
    `header` (2000) caps is kept whole with the field cut to 399 / 1999 code points plus `…` (so it still passes
    `validate` and `readEntries` keeps it); the ingest prints `trimmed summary <n>`, and `journal_` notes `<who>:
    entry.json summary <n> characters; cut to 400 and kept`. Any other fault is minimal as before.
  - **One resume.** `entry_resume` (`lib/record.sh`), from `journal` before the ingest and outside the record lock:
    a coding, verify or init session whose entry `validate` rejects (exit 1) and that `MET limit` did not refuse is
    resumed once by its transcript's `session_id` (`claude -p <prompts/entry-resume.md> --resume <id>`, through
    `session()` with `ENTRY_RESUME_TURNS` 8, `ENTRY_RESUME_TIMEOUT` 10m, `--max-budget-usd` = the session's
    `total_cost_usd` + `ENTRY_RESUME_BUDGET_USD` 1, in its own scope unit; transcript `<nn>-<id>.resume.jsonl`).
    After it the list and `INBOX.md` are put back (one it wrote where there was none, an initializer's list, is
    removed), the tree's other edits dropped and its commits reverted (`restrict`), so it can only write
    `entry.json`. Its cost is one `entry-resume` row in `metrics.jsonl` (the cumulative figures minus the session's;
    a resume with no result line, timed out or killed, costs 0), in the run's cost and tokens and never a session
    (MAX_SESSIONS, `sessions.total`; `harness show` lists it as `entry resume`).
    Notes: `<who>: entry.json written on a resume`, or `<who>: entry.json still <why> after one resume; recorded a
    minimal entry`.
- **Rejected:**
  - **Dropping the 400 cap:** the summary is what `progress.md` shows on Michael's phone and what the pack quotes; an
    uncapped one grows every pack it is quoted in. Cutting the overflow keeps the cap's purpose and loses only the
    tail of one field.
  - **Resuming more than once:** a session that wrote no valid entry on its own and none on a bounded resume is
    unlikely to on a third try, and each try costs turns and budget; one resume, then the minimal entry, bounds it.
  - **Resuming a refused session:** a usage limit or API error that refused the session would refuse the resume too,
    and spend a call inside the limit window; the minimal entry and the limit handling already cover it.
  - **Writing the entry from the transcript by code:** the entry's worth is the session's judgement (dead ends,
    discoveries, questions); code can rebuild only what git and the final message already give, which is the minimal
    entry. The session that did the work still holds that context in its session, so asking it is the cheap source.
