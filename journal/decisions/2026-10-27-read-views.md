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
  - **Status data (U1-03):** `lib/status.mjs` builds every run, needs and queue object in one node process from
    one stdin line per run (`run_rows` in bin/harness: the pids and units only bash collects) and the files it reads
    itself; `harness status [<run>] --json` (v1) prints them, every key path listed in
    `tests/fixtures/status-json-keys.txt`. An ended run's `summary.json` (the record's, which `finish` writes; else
    the state dir's, `harness report`'s; else the ledger copy) wins for features, cost, tests and lanes, so a gc'd run
    keeps its count; the state dir's is not first, since after a continue it is an earlier segment's. `session` is the
    metrics rows plus the one running, never `$STATE/sessions` (reset each segment). **(*default*)** A run with no
    live driver and no `ended` is `crashed` (class `failed`); its NEEDS item (`driver_crash`) only when a
    `driver.pid` was left. **(*default*)** One run-level item at most, and none when a feature or milestone item
    covers the run (`waiting on Michael: B` is B's row). **(*default*)** A milestone's `needs`/`refused`/`conflict`
    marker counts only until `merged-<m>` exists. A live lane's feature at `MAX_ATTEMPTS` is on its last attempt (the
    lane bumps `attempts.json` first), not given up. **(*default*)** `max-attempts` in the state dir, else 2 (the
    config default: status reads no project config). **(*default*)** A queued `--until HH:MM` shows as the next
    such time from now, as `to_epoch` reads it when the entry starts.
  - **The default view (U1-04):** `harness status` is one screen, rendered by `status.mjs` through `view.mjs`: NEEDS
    YOU, RUNNING, QUEUED and FINISHED, always all four and in that order (an empty one is its one line), then a rule
    and a footer only when runs are hidden. **No pager**: the view is short by design (for the long one, `HARNESS_COLOR=always COLUMNS=$COLUMNS harness
    status --all | less -R`: through a pipe there is no colour and the width is 100). **Colour on a TTY only.** **The window:** FINISHED holds the runs ended in the last `24h` (`--since`, else
    `STATUS_SINCE` in the user config; a date reads `since <date>`), never fewer than the 3 newest whatever their age, never more than 10; NEEDS
    YOU is never windowed. `-v` adds each running run's lane lines (P2-06's text), its own units and the last `N`
    `run.log` lines; `N` alone implies `-v`. The three run sections share one set of column widths so they line up;
    narrow (under 72) moves the long field and the cost to an indented second line, the field cut so the cost stays.
    The footer's hints keep `-p`, offer `--since 3d` only to a shorter window, and drop a hint that doesn't fit.
    `run.log` lines lose their control bytes (a tab, an ESC) and shorten only a path that starts with the home dir. **(*default*)** RUNNING's
    *what* is `<k> lanes` with a `lane <m> · <now>` sub-row each only with two or more open lanes: a lanes-era run
    always has its one lane, and `<feature> · session <n> · <model>` says more. With `-v` the lane sub-rows are
    P2-06's full lines instead, not both. **(*default*)** QUEUED counts and shows the waiting entries; the parked ones
    are counted on the `… parked: harness queue list` line, not listed. **(*default*)** A `<run>` with `-a`,
    `--since` or `--project` is an error (they list runs).
  - **The card (U1-05):** `harness status <run>` is `status.mjs`'s `renderCard` through `view.mjs`'s `card`: line 1
    `<glyph> <run> · <project> · <state or end class> · <x/y> passing · <age>` (what the debrief's `head -1` reads),
    a rule, then `now`, `ended`, `milestones`, `lanes`, `spend`, `branch`, `worktree`, `needs you`, `units`, `next`,
    each left out when it has nothing; `-v` or `N` adds `log` last. Bash sends only that run's row, with its units.
    The lane and log lines are verbatim (P2-06's text, 47-'s check), so they keep their `·` under `LC_ALL=C`; the
    card's own text is ASCII there (`->` for `→`). **(*default*)** The age of a live run is `started <ago> ago` from
    the segment's start, of an ended one `<ago> ago` from the end; a crashed run's state word is `crashed`.
    **(*default*)** `branch` is `harness/<run> @ <short> · <a> ahead, <b> behind` from local refs (`origin/main` as
    last fetched; `GIT_OPTIONAL_LOCKS=0`, no fetch); a gone worktree is `removed by gc` when its summary outlived it,
    else `(missing)`. **(*default*)** `needs you` names `harness needs <run>`, as the spec and the default view's
    NEEDS YOU hint do; until U2's command (every open item) `harness needs` is `harness parked`, so the hint works;
    `next` is `harness attach` while running, `harness report` and (while the worktree exists) `harness continue`
    after; `harness show` joins in U3. A card's lines are cut to the width like every view's, the log tail too
    (`COLUMNS=200` for whole lines); `N=0` adds no `log` field, as `tail -n 0` printed nothing.
- **Rejected:** a pager by default (a phone over ssh, a desk and the debrief read the view as text, and the view is
  short); colour off a TTY (escape bytes in a desk's or the debrief's capture); hiding NEEDS YOU when the window is
  short (an item shows until it is resolved, whatever its age); per-command formatting code (each view drifted on its
  own: the finding); `column(1)` or an npm table/colour package (CLAUDE.md: node built-ins only; `column` knows nothing of
  display width or ANSI); wrapping table cells (a row stays one scan line; a card shows the whole value); cutting
  ids (a printed command must paste); emoji glyphs (two columns, font-dependent).
