# The retro backlog: the retro proposes as data, the driver is the only writer

*Run `agent-harness-2026-10-25-memory`, feature M1-04 (rows and CLI: M1-02, M1-03). Spec
`docs/specs/2026-10-25-memory.md` § M1 (retro-followups §E). Plan `docs/plans/2026-10-26-M1-retro-backlog.md`.*

- **Finding:** each retro proposes up to three harness changes in `retro.md`'s prose, and nothing tracks them across
  runs: the same change was proposed in 6 and 8 retros (test counts, review cost) and re-argued after it was already
  specced. The debrief scanned the last 20 `retro.md` files for repeats by reading. The retro is read-only: `restrict`
  reverts every file it changes or creates, the run record included.
- **Choice:**
  - One store, `ledger/retro-backlog.jsonl`: a row per id (`id, title, first_seen {run, date}, runs_seen, status,
    spec, pr, note`), status `proposed | specced | queued | merged | dropped`, unset links `null`, a fixed key order.
    **Only the harness writes it**: the driver's `ledger()` and `harness backlog` (`set`, `import`), each under
    `flock` on `$STATE_ROOT/ledger.lock` and in a ledger commit when `LEDGER_COMMIT=1`. A session never writes `ledger/`.
  - **Proposals travel as data.** The retro may create one file, `<run dir>/retro-proposals.json` (a list of at most
    10, the prompt asks for 3, `{id, title, evidence}`, ids kebab-case). `retro()` copies it to `$HARNESS_SCRATCH`
    before `restrict` (only when it differs from the copy at the retro's start, so a continued run's old file is not
    merged twice), leaves it out of the `retro: reverted edits` note and puts it back in the run record, as it does
    `retro.md`, so the ledger's copy of the run keeps the evidence. No file: note `backlog: the retro wrote no
    retro-proposals.json`.
  - **`ledger()` merges** the scratch copy inside its `flock 9` block, before the commit, and adds the store to the
    commit's paths: a new id is appended `proposed`, first seen in this run; a known id gets the run in `runs_seen`
    once, its status, title and links unchanged. One note either way: `backlog: <a> new, <s> seen again`.
  - **A bad file is skipped whole**, as E4 skips a bad `entry.json`: not JSON, not a list, an item without an id or
    title or with a non-slug id → note `backlog: retro-proposals.json invalid: <why>`, the store untouched, the run
    finishes as usual.
- **Rejected:**
  - The retro editing the backlog itself: a session never writes `ledger/` (and `restrict` would revert it anyway;
    check `backlog run: restrict reverts a retro's edit to the backlog, and the merge still lands`).
  - Parsing proposals out of `retro.md`'s prose: fragile, and the ids would be guessed.
  - An LLM curator deduplicating proposals: a cost per run for what an id and a status do.
  - Keeping a bad file's valid items: a half-read file hides the error; the next retro proposes again.
