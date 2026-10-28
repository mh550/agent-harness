# Read views: one formatter, `lib/view.mjs`, that every read view renders through

*(2026-10-28, run agent-harness-2026-10-28, feature U1-02; spec `docs/specs/2026-10-27-status-ux.md` *The output
contract* and §U1, plan `docs/plans/2026-10-28-U1-read-views.md` §2 and §7. Started by U1-02 (the formatter); U1-03
to U1-06 add their views' choices, U1-07 completes it.)*

- **Finding:** each read command formats on its own (`cmd_status`'s `printf`s, `cmd_queue list`'s `paste -sd' '`,
  `parked.mjs`'s padded labels): nothing keeps a line inside the terminal, held queue entries are cut mid-word at 200
  characters, `⏸`-style glyphs render two columns wide in many terminals, and the views look different from one
  another. On a phone over ssh (60 columns) the 105-line `harness status` wrapped into noise.
- **Choice:** `lib/view.mjs`, pure exported functions with unit checks (`tests/checks/51-view-pure.sh`), node
  built-ins only; bash views pipe tab-separated rows into `node lib/view.mjs table|card|section`.
  - **Environment:** width from `COLUMNS` (a whole number ≥ 40), else a TTY's columns, else 100; narrow below 72.
    Colour only on a TTY with `NO_COLOR` unset and `TERM` not `dumb`; `HARNESS_COLOR=always|never` and
    `HARNESS_TTY=1|0` override (the checks), `always` even under `NO_COLOR`. Unicode glyphs when the first set of
    `LC_ALL`, `LC_CTYPE`, `LANG` names UTF-8, whether or not on a TTY; `HARNESS_GLYPHS` overrides.
    `HARNESS_NOW` fixes the clock.
  - **Glyphs:** a fixed set of single-column, text-presentation code points (`● ✓ ✗ ■ ‖ ⚠ ○ · ─ …`), each with an
    ASCII form (`* + x # = ! o - - ...`); `‖` for paused, never `⏸`. An unknown glyph or style name throws.
  - **Tables:** ids (`cut: false`) are never cut; the flex column takes what the others leave and is cut with the
    cut glyph. Narrow, or when the flex would get under its `min` (default 10), the flex value moves to an indented
    second line. **(*default*)** A row whose ids are too wide to share a line with the right-aligned columns puts
    those on a line of their own, right-aligned; a line still too wide breaks at its column gaps first, and only an
    id wider than the whole width is folded at the width (as the terminal would show it), never cut, so no line
    exceeds the width and every character of the id is there. Tabs and newlines in a cell become spaces.
  - **Sections:** `TITLE <count> · <hint> ───…` to the width. **(*default*)** A section with count 0 is the bare
    line, without the rule, as the spec's examples print `QUEUED 0 · runner off`.
  - **Cards:** an 11-wide label column (wider for a longer label), values word-wrapped with a hanging indent of 13,
    a word wider than the room broken after its `/`s, a value's newlines starting new lines; verbatim `lines` at 4,
    cut; a `url` field, or a URL inside a value too wide for the room, on its own line at 2, never cut.
  - **End classes:** `endClass(reason)` by prefix over the `ended` file's text (its ` · <date>` stamp dropped):
    `done` exactly; `blocked on `/`waiting on Michael` waiting; `stopped by Michael`, `session cap (`, `deadline`,
    `weekly budget (`, `usage limit (`, `merge only` stopped; anything else failed, never a crash.
    `tests/fixtures/end-reasons.txt` holds every reason, and a check fails when the driver gains a literal `finish`
    reason, `END_REASON` or run-ending `lane_exit` the fixture lacks.
- **Rejected:** `column(1)` or an npm table/colour package (CLAUDE.md: node built-ins only; `column` knows nothing of
  display width or ANSI); wrapping table cells (a row stays one scan line; a card shows the whole value); cutting
  ids (a printed command must paste); emoji glyphs (two columns, font-dependent).
