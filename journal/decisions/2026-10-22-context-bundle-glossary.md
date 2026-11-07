# The context bundle: the debrief's gatherer, a glossary by code, context.json beside it, written before the event

*(2026-11-07, A2-02 to A2-04 of run agent-harness-2026-11-07-3; spec `docs/specs/2026-10-22-n8n-events.md` §A2 and its
Contracts (v1, fixed: n8n-home's `docs/specs/2026-10-22-harness-reporter.md` §4.3, its `lib/intake.js` contextPaths and
`lib/card.js`); plan `docs/plans/2026-11-07-A2-context-bundle.md`. The file keeps the spec's name, which n8n-home cites)*

- **Finding:** A1's routed events went out with `context: null`, and n8n-home's intake refuses a debrief without a
  context string, so the debrief route always fell back to ntfy. n8n needs what the debrief already gathers (a run's
  end, needs, report, INBOX), and a card needs the IDs it names (`D24`, `N1-01`, `M8`, `D-H1`) explained: a model
  reading the bundle can't guess what a decision number means, and a guessed meaning is worse than none.
- **Choice:**
  - **The bundle's place and shape.** `lib/context.sh` (the debrief's gatherer, moved byte for byte; lib/debrief.sh
    sources it) writes `<out>/context.md` (the gatherer's markdown, then `## Glossary`) and `<out>/context.json` (the
    spec's keys in its order: `v id generated_at scope{runs since} runs[{run project ended running features
    paths{record worktree state report inbox progress} summary parked[{feature why question}] open_questions}]
    glossary[{id kind text source}] unresolved`), both from one `lib/context.mjs bundle` call so they never disagree,
    and no JSON is built in bash. `harness context <run-id> | --since <ts> [--out <dir>]` runs it by hand, read-only;
    `<out>` defaults to `<STATE_ROOT>/events/<uuid>/`.
  - **The glossary by code** (`lib/glossary.mjs`), from what the project already keeps: the run's `feature_list.json`
    (features, milestones) and the decisions store and docs (table rows `| D24 | … |`, headings `# M9`, `### D-H1 · …`
    in CLAUDE.md, README.md, docs/\*\*/\*.md, journal/decisions.md and the titles of journal/decisions/\*.md), every match
    newest file first, `source` as `<path>:<line>`; an ID nothing resolves is listed in `unresolved`, never guessed.
    It has no store of its own: it is re-derived each time.
  - **The hook** (lib/notify.sh `notify_event`): a routed event builds its bundle first, at `events/<id>/` with the
    event's own id (`notify.mjs event id=…`), so `context` names a `context.json` that exists when n8n reads it, and
    `event.json` lands beside it. A run's event bundles `RUN_ID`; the debrief's bundles every run since its `SINCE`
    (`notify … since=`). A bundle that fails (or times out) is the note `context bundle failed for <kind>; event sent
    without it` and a null `context`; the event is still sent. `HARNESS_CONTEXT` replaces the bundle command in tests.
  - *default*: **30-day retention, on write.** A bundle written in `<STATE_ROOT>/events/` removes every other
    `events/<dir>/` with no file modified in the last 30 days (the real clock), and says `events: removed <n> bundle(s)
    older than 30 days` (stdout; the hook notes it in the run). A `--out` elsewhere prunes nothing.
  - *default*: **the bundle is synchronous**, capped at 60 s (`timeout`) before the 5 s POST: a slow bundle costs at
    most that and a note.
  - *default*: `parked[].why` is the session's PARKED reason from the state dir's `parked.json` (else the needs card's
    headline): the needs item has no `why` of its own (read from a real `harness needs parked --json`). `question` is
    the INBOX ask at the card's line, else the card's question text. `open_questions` come from the files progress.md is
    rendered from, not progress.md: the INBOX's open asks (above `## Answers`, outside the steering comment, 600 chars
    each), then the open question items' text not among them; 12 at most.
  - *default*: newest file by mtime (ties by path); the docs root is the run's worktree when it is a checkout, else
    its project's; the run's own feature and milestone ids are matched exactly even when the spec's regexes miss
    their shape (`N1F-01`); the debrief's own context gains the glossary section; the id is the kernel's uuid.
- **Rejected:** a glossary written by the model (it would guess what it can't look up, and costs a session); a
  glossary store of its own (one more thing to keep in step with the decisions and the feature list, which already
  say it); a bundle n8n builds by calling harness commands (n8n would need shell access to this box and the harness's
  CLI as a contract; the files are the contract); an asynchronous bundle (the event could name a path not yet
  written).
