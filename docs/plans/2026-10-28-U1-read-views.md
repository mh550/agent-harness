# U1 · The formatter, `harness status`, `harness queue list`: plan

Lanes state: P1 and P2 of run agent-harness-2026-10-26 are on `origin/main` (PRs #40 and #41; `lib/lane.sh` and
`lib/record.sh` exist), so every driver site is named by function and file (`sync_main`, `merge_one`, `needs_you`,
`notify_park` in lib/record.sh; `verify` in lib/lane.sh; `finish` and the EXIT trap in lib/driver.sh; `cmd_status`,
`cmd_queue`, `cmd_parked` in bin/harness), never by a line number.

Spec: `docs/specs/2026-10-27-status-ux.md`, *The output contract*, §U1 items 1–9 and its checks, *Before → after*
(`harness status`, `harness status <run>`, `harness queue list`), *Defaults for open questions* 1–8 and 12. Features
U1-02 to U1-06 build, U1-07 reviews; this file is U1-01. Nothing here changes code: the suite is as the init left it
(602 checks, green).

## 1. What reads these views today (and must keep working)

| Reader | Call | What it relies on |
|---|---|---|
| `lib/debrief.sh` `run_context` | `N=3 "$H" status "$RUN_ID" 2>&1 \| head -c 3000` | any text; the block exists |
| `lib/debrief.sh` (top) | `N=1 "$H" status "$(basename "$d")" 2>&1 \| head -1` | line 1 names the run and its state |
| `lib/debrief.sh` (top) | `"$H" queue list 2>&1 \| head -n 60 \| cut -c1-400` | any text |
| `prompts/supervisor.md` | `harness status {{RUN_ID}}`, `N=20 harness status {{RUN_ID}}` | alive/paused, passing, log lines |
| `prompts/desk.md`, `skills/harness-answer/SKILL.md` | `harness status <run>` ("running or ended, and why") | the state and the end reason in words |
| `prompts/project-catchup.md` | `harness status` "for this project's runs" | becomes `harness status --project <p>` (U1-04) |
| `lib/parked.mjs` text | "continue once harness status shows it ended" | the word `ended`/the class in the card |

`cmd_status` today: one loop over `$STATE_ROOT/*/*/`, a headline per run (`<run> (<project>) · <state> · port <p> ·
<x/y passing>[ · tests a → b]`), the lane lines and unit lines of a running run (P2-06), `tail -n ${N:-3} run.log`.
`cmd_queue list`: `paste -sd' '` of each `.args`, `entry_kind`'s mark at the end, parked entries cut at 200
characters with `why:`, `running:`, `recent:` with `runner.log`'s last 5 lines.

## 2. `lib/view.mjs` (U1-02)

Pure exported functions, no dependencies, no I/O except the CLI at the bottom (as in `parked.mjs`). Usage header:
`// The one formatter every read view renders through (decisions/2026-10-27-read-views). No dependencies.`

### 2.1 API: one signature and one contract each

| Function | Contract |
|---|---|
| `context({env, isTTY, columns})` → `{width, narrow, tty, color, glyphs, now}` | the rules of §2.2 from those three inputs only; `now` = `HARNESS_NOW` (epoch s) when a whole number, else `Date.now()/1000` floored |
| `glyph(name, ctx)` → string | `name` in `running done failed stopped paused needs queued sep rule cut`; Unicode or ASCII by `ctx.glyphs`; an unknown name throws (a typo is a bug, not a blank) |
| `paint(text, style, ctx)` → string | `style` in `red yellow green cyan dim bold`; `text` unchanged when `!ctx.color`, else wrapped in SGR `\x1b[<n>m … \x1b[0m` |
| `displayWidth(s)` → number | columns `s` takes: ANSI SGR sequences 0, combining marks 0, East Asian Wide/Fullwidth 2, everything else 1 |
| `cut(s, n, ctx)` → string | `s` when `displayWidth(s) <= n`; else the longest prefix of whole code points (never half a surrogate pair, never inside an SGR sequence, an open SGR closed) that fits `n` with the cut glyph (`…` 1 column, `...` 3), then the cut glyph |
| `pad(s, n, align = "left")` → string | `s` padded with spaces to `n` display columns, `align` `left` or `right`; never cuts |
| `table(rows, columns, ctx)` → string[] | `rows`: objects; `columns`: `[{key, min, max, align, flex, cut}]` (`cut: false` for ids: never cut). Normal layout: one line per row, two spaces between columns, numbers right-aligned, the `flex` column takes `width − the rest` and is cut; no line exceeds `ctx.width`. Narrow: the `flex` column goes on a second line indented 2, cut to the width; a row whose flex value is empty has no second line. A row's `sub: [string]` lines follow it, indented 4, cut |
| `section(title, count, hint, ctx)` → string | `TITLE <count>[ · <hint>] ───…` filled with the rule glyph to `ctx.width`; `count` `null` leaves it out (`FINISHED · last 24h · 3`: the caller passes the pieces in order) |
| `rule(ctx)` → string | the rule glyph × `ctx.width` |
| `card(header, fields, ctx)` → string[] | `header` (one line, cut), a rule, then each field `{label, value, lines, url}`: `  <label padded to 11><value>` word-wrapped at spaces (and at `/` in a token longer than the room) with a hanging indent of 13; `value` may be an array (one wrapped line each); `lines`: verbatim lines after the label line, indented 4, cut, never wrapped (P2-06's lane lines, the log tail); `url`: its own line indented 2, never cut; a field with an empty value and no lines is left out |
| `ago(epoch, now)` → string | `now` under 60 s, `<m>m` under 60 min, `<h>h` under 48 h, `<d>d` under 14 d, else `<w>w`; floored; a future time is `now` |
| `when(epoch, now)` → string | `YYYY-MM-DD HH:MM (<ago> ago)` in local time; `(now)` when under a minute |
| `home(path, env)` → string | `path` with a leading `env.HOME` + `/` (or `path === HOME`) replaced by `~`; anything else unchanged |
| `duration(text)` → seconds | `<n>m` `<n>h` `<n>d` `<n>w` (whole n ≥ 1), or `YYYY-MM-DD` → seconds from that local midnight to `now` (the caller passes now; signature `duration(text, now)`); anything else throws `bad duration '<text>' (30m, 6h, 2d, 1w or YYYY-MM-DD)` |
| `endClass(reason)` → `done` · `stopped` · `waiting` · `failed` | §2.4; `null`/empty → `failed`; never throws |

Also exported (data, for the unit checks): `GLYPHS` (`{name: [unicode, ascii]}`), `END_CLASSES` (the prefix table of §2.4).

CLI (for bash views, U1-06 and later): `node lib/view.mjs table|card|section` reading tab-separated rows on stdin
(`table`: the first line is the column spec `key:min:max:align:flex`, tab-separated; `card`: `label\tvalue` lines,
the first line the header). U1 itself renders everything in `status.mjs`; the CLI exists for U2/U3's bash views and
gets one check each form.

### 2.2 Environment rules (`context`)

- **Width**: `env.COLUMNS` when it is a whole number ≥ 40; else `columns` (the caller passes
  `process.stdout.columns`) when `isTTY` and it is a number; else 100. **Narrow** when width < 72.
- **TTY**: `isTTY`, overridden by `HARNESS_TTY=1` (true) or `0` (false).
- **Colour**: on only when tty, `NO_COLOR` unset or empty, `TERM` not `dumb`. `HARNESS_COLOR=always` turns it on
  whatever else holds (TTY or not, `NO_COLOR` too: spec default 6), `never` off.
- **Glyphs**: Unicode when the first set of `LC_ALL`, `LC_CTYPE`, `LANG` matches `/utf-?8/i`; else ASCII.
  `HARNESS_GLYPHS=unicode` or `ascii` overrides. Unicode whether or not on a TTY (default 5).
- **Now**: `HARNESS_NOW=<epoch>` fixes it (the checks); used by `ago`, `when`, `duration` through `ctx.now`.

### 2.3 Glyph table (a unit check lists each against this fixed set and asserts `displayWidth` 1)

| name | running | done | failed | stopped | paused | needs | queued | sep | rule | cut |
|---|---|---|---|---|---|---|---|---|---|---|
| Unicode | `●` U+25CF | `✓` U+2713 | `✗` U+2717 | `■` U+25A0 | `‖` U+2016 | `⚠` U+26A0 | `○` U+25CB | `·` U+00B7 | `─` U+2500 | `…` U+2026 |
| ASCII | `*` | `+` | `x` | `#` | `=` | `!` | `o` | `-` | `-` | `...` |

No emoji presentation, no variation selector, no `⏸`. Colour: `failed` red, `needs` yellow, `done` green, `running`
cyan, secondary text (ages, hints, the rule) dim. The glyph and the words carry the meaning; colour only repeats it.

### 2.4 End classes (`endClass`)

The reason is the `ended` file's text before its ` · YYYY-MM-DD HH:MM:SS` stamp (`finish` and the EXIT trap write
`<reason> · <date '+%F %T'>`; checks also write a bare reason). Matched by prefix, first match wins, in this order:

| Class | Glyph | Reasons (prefix) | Written by |
|---|---|---|---|
| `done` | ✓ | `done` (exactly) | `finish "done"` (lib/driver.sh, every feature passes) |
| `waiting` | ⚠ | `blocked on `, `waiting on Michael` | `finish` at "nothing open and nothing to open" (a compound `blocked on X; waiting on Michael: Y` classes by its first part) |
| `stopped` | ■ | `stopped by Michael`, `session cap (`, `deadline`, `weekly budget (`, `usage limit (` (but not `usage limit before`), `merge only` | `stop_why` (lib/record.sh) via `finish`; `finish` for the cap, the deadline (`deadline`, `deadline (paused)`), `weekly_over` (lib/config.sh); a lane's exit 13 (`LANE_END`); `cmd_merge`'s `END_REASON="merge only"` |
| `failed` | ✗ | `no feature left to try`, `feature-list edits`, `initializer failed`, `usage limit before the feature list`, `unknown POLICY`, `driver exited unexpectedly`, and **anything else** | `finish`; the EXIT trap's default `END_REASON`; `lane_exit 12 "feature-list edits"` → `LANE_END` |

`tests/fixtures/end-reasons.txt` (U1-02): one `<class>\t<reason>` line per reason above, written with the values the
code produces (`session cap (12)`, `weekly budget (7-day window at 96%, stop at 95%; resets Sat 09:00)`, `usage limit (6 sessions
refused in a row)`, `stopped by Michael`, `stopped by Michael: rebase onto main once the memory run ends (conflicts in
lib/driver.sh)`, `deadline (paused)`, `blocked on P1-04`, `waiting on Michael: B1-05`, `blocked on C; waiting on
Michael: B`, `driver exited unexpectedly (see run.log)`, `unknown POLICY`, `merge only`, …) and the spec's quoted
`ended` lines of 2026-10-27 (`done`, `stopped by Michael: rebase onto main …`, `waiting on Michael: B1-05`). Its
header comment names the sources by function (`finish`, the EXIT trap, `stop_why`, `weekly_over`, `lane_exit`). The
check: every line's reason classes as its class; `endClass("frobnicated")` is `failed`; `endClass("")` is `failed`.
The weekly-budget text is `weekly_over`'s `echo` (lib/config.sh), copied when U1-02 writes the fixture, never guessed.

## 3. `lib/status.mjs` (U1-03 builds, U1-04 to U1-06 render)

### 3.1 Input

**Stdin**, one line per run (bash's `run_rows`, §3.3), tab-separated, the first six fields fixed by the spec and a
seventh optional:

```
<run>\t<project>\t<state dir>\t<worktree>\t<record dir>\t<alive 0|1|2>[\t<units>]
```

- `project`: the state dir's parent's name (`basename "$PROJECT_DIR"`; the same as `$(basename "$(dirname "$d")")`).
- `record dir`: `<worktree>/.harness/runs/<run>` (given even when the worktree is gone: node tests existence).
- `alive`: 0 no live driver, 1 alive, 2 alive with `ended` written (in `finish`), as `cmd_parked` computes it.
- `units` (field 7): `unit=bytes,unit=bytes` from `systemctl --user list-units "$(scope_unit "$RUN_ID")-*"` filtered
  by `scope_owns` and each unit's `MemoryCurrent` (today's `cmd_status` loop moved into `run_rows`); present only
  when bash collected them (`-v`, `N`, `--json`, the card) and the run is alive. Absent → `units: []` and no unit lines.

**Arguments**: `node lib/status.mjs <view|card <run>|queue|entry <n>> [--json] [--all] [--since <d>] [--project <p>]
[--verbose <N>] [--parked] --runner <0|1> --queue <dir> --ledger <dir> --state-root <dir> --max-parallel <k>
--since-default <d>`. `--runner`: `runner_up`; `--queue`: `$Q`; `--ledger`: `${HARNESS_LEDGER:-$HARNESS_HOME/ledger}`;
`--state-root`: `$STATE_ROOT` (for `LIMIT_UNTIL`); `--max-parallel`: `MAX_PARALLEL_RUNS`; `--since-default`:
`STATUS_SINCE` (default `24h`). The last two come from `harness_config /nonexistent` in a subshell, as `cmd_queue
list` reads `MAX_PARALLEL_RUNS` today (read-only: it sources the user config and makes nothing).

**What node reads itself**, per run, each missing file tolerated (a missing `port` is `null`, a bad JSON is ignored):

| Source | Path | Gives |
|---|---|---|
| `ended` | `<state>/ended` | `end_reason` (text before ` · <stamp>`), `ended_at` (the stamp; a bare reason: the file's mtime) |
| `PAUSE` | `<state>/PAUSE` | `paused` (alive runs) |
| `LIMIT_UNTIL` | `<state-root>/LIMIT_UNTIL` | `limit_wait` until `HH:MM` when > now (alive runs) |
| `port` | `<state>/port` | `port` |
| `tests-start`, `tests-end` | `<state>/…` | `tests: {start, end}` (numbers or null) |
| `run.log` | `<state>/run.log` | `started_at`: the first `run <id> on …` line's stamp (the run's start); the segment's start: the last such line; the newest `session <n> · <id> · <model>` line (feature, model id); the last `N` lines for `-v` |
| `metrics.jsonl` | `<record>/metrics.jsonl`, else `<state>/metrics.jsonl` (`cmd_report`'s copy) | `cost_usd` (sum of `cost`), session count (rows) |
| `feature_list.json` | `<record>/feature_list.json` | `features.passing/total`, the milestones, feature ids for given-up items |
| `attempts.json`, `max-attempts`, `parked.json` | `<state>/…` | NEEDS items (§3.2) |
| markers | `<state>/{verified,merged,needs,refused,conflict}-<m>`, `<state>/lanes/<m>/need` | `features.verified/merged`, NEEDS items |
| lanes | `<state>/lanes/<m>/{pid,now,port,slot}`, a pid tested with `process.kill(pid, 0)` (EPERM counts as alive, as `kill -0`) | P2-06's open lanes |
| `summary.json` | `<state>/summary.json`, else `<record>/summary.json`, else `<ledger>/<project>/<run>/summary.json` | for an ended run: `features`, `cost.total`, `tests`, `lanes`, `milestones`, `time.wall_h`, `started`, `ended_at` (the ledger copy is how a gc'd run shows `23/23`) |
| git (card only) | `git -C <worktree> rev-list --left-right --count origin/main...harness/<run>`, `rev-parse --short` | the card's `branch` field; read-only, local refs, no fetch; worktree gone → `harness/<run> (worktree removed)` |

Precedence for an ended run: `summary.json` (the first found) wins for features, cost and tests; the live files for
anything it lacks. For a running run: the live files only. The session number (spec default 3) is the metrics rows
plus 1 while a session runs (alive and the newest `session` line is after the segment start).

**Queue** (for `QUEUED`, `queue list`, `queue show`): `<queue>/*.args` and `<queue>/held/*.args` (+ `.why`), sorted
by name as the runner does; `<queue>/runner.log` (last 5 lines). An entry's project as `queue.sh`'s `entry_project`
(start → the path's basename; continue → its run's state dir's parent), held when that project has an alive run in
the stdin rows (`busy_projects`' rule: the same answer, from the same pids), naming that run.

### 3.2 The NEEDS YOU items in U1 (derived; U2 replaces the source with the records)

For each run whose worktree exists (a gc'd run has nothing left to answer, as `harness parked`):

| Item | From | `reason` · headline | `at` |
|---|---|---|---|
| parked feature | `parked.json` `id → {why, at}` | `parked` · `<id> parked: <why's first line>` | `at` |
| given-up feature | `attempts.json[id] >= max-attempts` (file, else 2), not passing, not parked | `given_up` · `<id> given up (<n> attempts)` | `attempts.json`'s mtime |
| milestone needs | `needs-<m>` | `needs_michael` · `<m> needs you: <lanes/<m>/need, else "see harness-log.md">` | the marker's mtime |
| refused merge | `refused-<m>` | `merge_refused` · `<m> merge refused` | mtime |
| conflicting merge | `conflict-<m>` | `merge_conflict` · `<m> conflicts with main` | mtime |
| run end | `ended` of class `waiting` or `failed`, **only when the run has no other item** (a `waiting on Michael: B` end is the parked B's row) | `run_end` · the end reason | `ended_at` |
| crashed | not alive, no `ended`, a `driver.pid` file left (a SIGKILL) | `driver_crash` · `driver gone without an end reason` | `run.log`'s mtime |

All U1 items are `severity: "block"` (no warn item exists before U2). Order: block first, then oldest `at` first. Never
windowed. Default (recorded): one run-level item at most, and none when a feature or milestone item covers the run.

### 3.3 Bash's side (`bin/harness`)

One helper, `run_rows <units 0|1>`, beside `cmd_status`: the loop of `cmd_parked` (`for d in "$STATE_ROOT"/*/*/`,
`[[ -f $d/meta.env ]]`, a subshell per run that sources it, `|| true` so one broken `meta.env` doesn't cut the
others off: check 15's `stoppy-o` has an empty one), printing §3.1's line; with `1` and an alive run, the units
field (the `list-units`/`scope_owns`/`show -p MemoryCurrent` loop moved out of `cmd_status`). `cmd_status`,
`cmd_queue list` and `queue show` pipe it into `status.mjs`. `cmd_parked` keeps its own loop in U1 (U2 makes it
`harness needs`).

`cmd_status [<run>] [-a|--all] [--since <d>] [-p|--project <p>] [-v] [--json]`: `N` set and a whole number implies
`-v` with `N` lines (`N=1`, `N=3`, `N=20` keep working); `-v` alone is 3 lines. A `<run>` is checked with `state_of`
(`harness: no run '<x>' (see: harness status)`, exit 1). An unknown option dies with the usage line. `--project` is
the state dir's directory name in U1 (U3-02 resolves names and paths). Units are collected for `-v`, `--json` and a
card.

### 3.4 `--json` (v1), U1-03

`harness status --json`: `{v, generated_at, since, runner: {up, max_parallel_runs}, needs: [item], running: [run],
queued: [entry], finished: [run], older}`. `since` is the window as given (`24h`, `2026-10-25`); with `--all`,
`finished` holds every ended run and `older` is 0. `harness status <run> --json`: `{v: 1, …the run object}` (the one
run object, `v` added so every `--json` document has it). Times ISO 8601 UTC; paths absolute; no colour, no glyphs.

- **run**: `run, project, state` (`running` · `paused` · `limit_wait` · `ending` · `ended` · `crashed`),
  `end_reason` (null unless ended), `end_class` (`done` · `stopped` · `waiting` · `failed` · null; `crashed` is
  `failed`), `started_at, ended_at, feature, session, model` (the full model id), `features: {passing, total,
  verified, merged}, cost_usd` (cents, 2 decimals), `tests: {start, end}, port, branch` (`harness/<run>`),
  `worktree, worktree_exists, record, state_dir, needs` (the count of its items), `lanes` (null, or `{max_open,
  lane_hours, wall_hours, open: [{milestone, now, port, slot, units: [{unit, memory_mb}]}]}`: summary.json's three
  keys, null while running, plus the open lanes), `units: [{unit, memory_mb}]` (the run's own units, not a lane's).
- **needs item**: `run, project, feature, milestone, reason, kind, severity, at, title, card: {headline}`. Each key is
  one of U2's record keys (`kind` from the spec's table: `parked` → `park`, `given_up` → `blocked`, the rest
  `needs_michael`; `title` the notification title `[<run>] <id or m> needs you`), so U2's records replace these items
  and only add keys: v1 holds.
- **queue entry**: `n, verb, project, run` (null for a start with no id), `spec` (the `--spec` value split on spaces
  and commas, as `SPEC_FILES` is, `[]` without), `brief_head` (the first 30 characters), `brief_chars`, `until` (ISO,
  from `--until`/`--until-epoch`, or null), `mark` (`requested` · `automatic` · null), `added_at` (the file's
  mtime), `held` (null or `{project, run}`), `overlap` (`[]` until U3), plus two keys the views need (an addition
  within v1): `parked` (bool) and `why` (the `.why` text or null).

**`tests/fixtures/status-json-keys.txt`** (U1-03): every key path of a document built from the full stub state
(§5.2, a lane open on the running run and `lanes` in the gc'd run's summary), one per line, sorted, from

```bash
jq -r '[paths | map(if type == "number" then "[]" else "." + . end) | join("") | ltrimstr(".")] | unique | .[]'
```

so the file reads `finished`, `finished[]`, `finished[].cost_usd`, …, `running[].lanes.open[].units[].memory_mb`,
…, `v`. Written by hand from §3.4's lists first (the check fails red), then compared; a new key is a fixture line.

## 4. The views (U1-04 to U1-06)

All through `view.mjs`; the layouts are the spec's *Before → after* blocks.

- **Default view** (U1-04): the four sections, always all four, in order, then the footer only when something is
  hidden. Columns (normal): glyph, run (`cut: false`), what (flex), passing (right), cost (`$<whole>`, right), age
  (right). Narrow: glyph, run, passing, age on the first line, *what* (and cost) on the second. `RUNNING`'s what:
  `<feature> · session <n> · <alias>` (alias: `opus`, `sonnet`, `haiku`, `fable` from the model id), `waiting for
  the usage limit until HH:MM`, `paused` (glyph `‖`), `ending` (`⚠` when it has an item), or `<k> lanes` with one
  sub-row per open lane (`lane <m> · <now>`). `-v`: under each running row, P2-06's lane lines verbatim, then its
  own units as `    <unit> · MemoryCurrent <mb> MB` (today's text), then the last N `run.log` lines, all indented 4
  and cut. `QUEUED <n> · runner going|off (harness queue start)`: the first three queue rows, `+<k> more: harness
  queue list`. `FINISHED · last <window> · <n>`: ended (and crashed) runs inside the window, newest first, at least
  the 3 newest whatever their age, at most 10. Footer: a rule, `<k> older runs: harness status --all · --since 3d ·
  one run: harness status <run>` (narrow: `<k> older runs: harness status --all`).
- **Card** (U1-05): line 1 `<glyph> <run> · <project> · <state or class> · <x/y> passing · <ago>` (`running`,
  `paused`, `waiting for the usage limit`, `ending`, else the end class word; ago since the start while running,
  since the end after; the debrief's `head -1` reads it), a rule, then fields in order: `now`, `ended` (`when(...) ·
  <full reason>`), `milestones` (`P0 ✓ merged 4/4 · P1 3/6 · P2 0/7`), `lanes` (value `<k> open`, `lines`: P2-06's
  lane lines **verbatim**, so 47-'s regexes hold), `spend` (`$69.06 · 17 sessions · 7.6 h wall · tests 419 → 430`),
  `branch`, `worktree` (`~` path or `removed by gc`), `needs you` (`⚠ <n> · <first headline>`, then `harness parked
  <run>` in U1, `harness needs <run>` from U2), `units` (running only, the run's own: `<unit> · <mb> MB`), `next`
  (`harness attach` while running; `harness report`, `harness continue` once ended; `harness show` from U3), and with
  `-v`/`N` a `log` field (`last <N> lines of run.log`) whose `lines` are the tail, so the card ends with them.
- **Queue list** (U1-06): `QUEUE <n> · runner ● going|off · MAX_PARALLEL_RUNS=<k>`, rows `<n>  <verb>  <run id or
  "<project> (new run)">[ (requested)|(automatic)]  <spec basenames> · brief "<30>…" (+<k> chars)  <age>`, a held
  entry's second line `held: <project> busy (<run>)`; `PARKED <n> (skipped; harness queue unpark <n>)` with each
  parked row and `why: <reason>`; `RUNNING <runs>`; `RECENT` (runner.log's last 5, `HH:MM` and `~` paths); a rule and
  `one entry in full: harness queue show <n>`. Empty sections are one line (`QUEUE 0 · runner off ·
  MAX_PARALLEL_RUNS=1`, `PARKED 0`). `harness queue show <n> [--parked]`: a card, one field per line: `verb`,
  `project` (path), `run`, `spec`, `brief` (word-wrapped, whole), `until`, `mark`, `why` (parked), `file` (the
  `.args` path). `queue list` numbering, marks and the `rm`/`park`/`unpark <n>` semantics unchanged.

## 5. Checks

### 5.1 Files (one per topic, from 51) and fixtures

| File | Feature | Holds |
|---|---|---|
| `tests/checks/51-view-pure.sh` | U1-02 | `view.mjs` unit checks (`node --input-type=module -e`): `context` per env combination (COLUMNS 60/80/`junk`/39, TTY or not, `NO_COLOR=1`, `TERM=dumb`, `HARNESS_COLOR=always`/`never`, `HARNESS_TTY=0/1`, `LC_ALL=C`, `LANG=en_US.UTF-8`, `HARNESS_GLYPHS`); every glyph single-column and in §2.3's set, its ASCII form; `cut` on a string of `✓`/CJK/emoji-free wide characters and an SGR string never splits a code point and ends in `…`/`...`; `table` at 40, 60, 80, 120 with 60-character ids and 300-character reasons: no line wider than the width, ids whole; `card`'s hanging indent and `url` line; `ago`/`when` against a fixed now; `duration` per form and a bad one; `endClass` over `tests/fixtures/end-reasons.txt`; the CLI forms |
| `tests/checks/52-status-json.sh` | U1-03 | `--json` parses, `v: 1`, key paths equal `status-json-keys.txt`; the gc'd run's `features` from the ledger copy; `end_class` per stub; `harness status <run> --json` is one object with `v`; `--json` writes nothing (`find -newer`, as the parked check); the text output byte for byte as before (a capture of `harness status` on the stub state taken before the change, compared) |
| `tests/checks/53-status-view.sh` | U1-04 | the four sections in order; parked and given-up under NEEDS YOU; the 3-day-old run only in the footer count; the gc'd run `23/23`; no `run.log` line without `-v`; `--all`, `--since 4d`, `--project proj2`; `COLUMNS=60`/`80`: no line wider (URLs excepted); no ESC without `HARNESS_TTY=1`, ESC with it, none with `HARNESS_TTY=1 NO_COLOR=1`; `LC_ALL=C` (with `HARNESS_GLYPHS` unset): ASCII only; `-v` shows units and N lines; under 1 s for the 30 runs (best of 3: a loaded box with `TEST_JOBS=4` must not flake it) |
| `tests/checks/54-status-card.sh` | U1-05 | line 1 has run, project, class, `x/y passing`; `N=3 harness status <run>` ends with three log lines; a running card's `now` and `units`; the gc'd run's card `worktree removed by gc`; the debrief's `--dry-run` has a `#### harness status` block per run whose first line is the card's |
| `tests/checks/55-queue-view.sh` | U1-06 | a 1,200-character brief shows 30 characters and `(+1170 chars)`, `harness queue show 1` prints it whole; a held entry names the run that holds it; a parked entry's `why:`; numbering matches `queue rm`'s; `COLUMNS=60` fits |

Every new check name gets its line in `tests/fixtures/check-names.txt`. Fixtures: `tests/fixtures/end-reasons.txt`
(U1-02, §2.4), `tests/fixtures/status-json-keys.txt` (U1-03, §3.4).

### 5.2 The stub-state helper the checks share

`status_stubs [<bulk>]` in `tests/lib.sh` (a check file calls it once after `suite_setup`), building under
`$HARNESS_STATE` and `$HARNESS_LEDGER` (`$T/ledger`) with `HARNESS_NOW` exported as a fixed epoch and every time
relative to it. Each run has a `meta.env` written by `printf 'PROJECT_DIR=%q\nWT=%q\nRUN_ID=%q\nSTATE=%q\n'` (the
line `cmd_start` writes), a `port`, a `run.log` whose `run <id> on …` and `session <n> · <id> · <model>` lines are
`log`'s format, and, where a record exists, a `feature_list.json` with milestones and a `metrics.jsonl` whose rows
come from `node lib/metrics.mjs append` on `tests/fixtures/usage-tokens.jsonl` (the real shape, never a typed row):

| Run (project) | State |
|---|---|
| `done2h` (proj) | `ended`: `done · <now − 2 h>`, list 3/3, `merged-M1` |
| `done3d` (proj) | `ended`: `done · <now − 3 d>` |
| `stopped` (proj2) | `ended`: `stopped by Michael: rebase first · <now − 5 h>`, list 1/3 |
| `running` (proj) | `driver.pid` a live `sleep` (killed by the file's EXIT trap), `session 2 · B · claude-opus-5-5`, `lanes/M1/{pid,now,port,slot}` with the same pid |
| `parked` (proj) | `ended`: `waiting on Michael: B · <now − 1 h>`, `parked.json` `{B: {why, at, answers}}` as `F park` writes it, an INBOX.md |
| `givenup` (proj2) | `ended`: `blocked on C · <now − 30 min>`, `attempts.json` `{C: 2}`, `max-attempts` 2 |
| `gcd` (proj) | `ended`: `done · <now − 1 h>`, worktree removed; `$T/ledger/proj/gcd/summary.json` built by `node lib/summary.mjs build` on a stub record 23/23 with `lanes` (then the worktree removed) |
| `bulk-01` … `bulk-<n>` (proj) | `ended`: `done · <now − 4 d − i min>`, only when `<bulk>` is given (30 for the timing check) |

The units come from the existing stubs (`HARNESS_SYSTEMCTL=tests/stub-systemctl.sh`, `STUB_MEM_CURRENT`, a
`$T/scope/<unit>.{alive,running}` pair as 08- does). **Glyph pinning**: the checks that compare view text set
`HARNESS_GLYPHS=unicode` on the command (not in `suite_setup`: an ASCII check needs it unset, and the box's locale
under the runner isn't known); a regex on a separator matches `·` only under that pin.

### 5.3 The existing checks the new text affects, and the intent-preserving rewrite of each

| Check (file) | Today it reads | Rewrite (in the feature that changes the text) |
|---|---|---|
| "ended: done; status says so" (`08-scope-sh-…`, `13-run-2-…`, `14-run-2b-…`, `15-run-4-…`) | `grep -q "ended: done" <<< "$("$H" status demo)"` | U1-05: `grep -q "^done" ended && S=$(HARNESS_GLYPHS=unicode "$H" status demo) && [[ ${S%%$'\n'*} == "✓ demo · proj · done · "* ]] && [[ $("$H" status demo --json \| jq -r .end_reason) == done ]]` (the card's class on line 1 and `--json`'s `end_reason`; the pipe into `jq` reads it whole, no SIGPIPE) |
| "harness status lists a running run's units with MemoryCurrent; an ended run's none" (`08-scope-sh-…`) | `^termed (proj) · running`, the `-x` lane line, `MemoryCurrent` count 1; ended: `^termed (proj) · ended: driver exited`, no `MemoryCurrent` | U1-05: the two captures become `HARNESS_GLYPHS=unicode "$H" status termed -v` (the `units` field and the lane lines); `^● termed · proj · running`; the lane line's `-x` regex unchanged (the card's `lanes` lines are verbatim at 4 spaces); `MemoryCurrent` count still 1 (the `units` field prints `<unit> · <mb> MB`, the lane line holds the word); ended: `^✗ termed · proj · failed` and `^  ended .*driver exited unexpectedly`, no `MemoryCurrent`, no `^  units ` line; the `list-units` count unchanged (an ended run's units are not asked for) |
| "lanes status: harness status prints one line per open lane (feature, session, port, slot, its units with MemoryCurrent), no bare line for a lane's unit" (`47-lanes-two.sh`) | `-x` regexes on `    lane M1 · …` and `    lane M2 · …`, two `^    lane ` lines, no `^    harness-two-M[12]-` line | U1-05: **text unchanged**; the capture gains `HARNESS_GLYPHS=unicode` (the lane line's `·` is P2-06's literal text, not a glyph, so even this is belt and braces). The card's `lanes` field prints the lines verbatim; its `units` field lists only units no lane line took, so the "no bare line" assertion keeps its meaning. If a lane line ever exceeds the width it is cut with `…`, which the `(, .*)?` tail still matches |
| "queue list marks continuations (requested) or (automatic)" (`15-run-4-…`) | `^  [0-9]*\. continue stopreq .*(requested)$` | U1-06: `grep -E "^ *[0-9]+  continue  stopreq \(requested\)( \|$)"` and the same for `stopauto \(automatic\)` (the mark beside the id in the row) |
| "a request for a run with an automatic continuation queued makes that one requested; parked entries are marked too" (`15-run-4-…`) | `queue list \| sed -n "/^parked/,\$p"` then `^  1\. continue stopauto .*(requested)$` | U1-06: `sed -n "/^PARKED/,\$p"` then `^ *1  continue  stopauto \(requested\)( \|$)`; the `queue add` message assertion unchanged |
| "the driver's continuation after a session cap is automatic" (`15-run-4-…`) | `continue capped .*(automatic)$` in `queue list` | U1-06: `continue  capped \(automatic\)` |
| "queue park sets an entry aside with its reason" (`15-run-4-…`) | `^parked (the runner skips`, `why: waiting on the measure PRs`, `  (empty)` | U1-06: `^PARKED 1 (skipped; harness queue unpark <n>)`, `why: waiting on the measure PRs` (kept), `^QUEUE 0 · ` (an empty section is one line) |
| "--dry-run prints the context, launches nothing" (`15-run-4-…`) | `^## harness status`, `^### stoppy (proj)`, `ended: deadline` in the debrief context | **unchanged and green through U1**: `## harness status` is the debrief's own heading, and `ended: deadline` comes from `run_context`'s `- ended: $ended` line (the `ended` file), not from `harness status`. U1-05 adds beside it (54-) that each `#### harness status` block's first line is the card's |
| "the desk prompt names the run, its commands and the never-list" (`13-run-2-…`), and "harness desk --debrief" (`13-run-2-…`), whose `! grep -q "harness parked parky" "$QP"` keeps the debrief desk's prompt free of a run's commands | `harness parked parky`, `harness status parky` in the desk prompt | **unchanged in U1** (U1 edits no desk text; `harness status parky` still names a real command, now the card). U2-07 replaces `harness parked {{RUN_ID}}` in `prompts/desk.md` with `COLUMNS=60 harness needs {{RUN_ID}}` and rewrites both: the list's `"harness parked parky"` → `"harness needs parky"`, "harness desk --debrief"'s negative → `! grep -q "harness needs parky" "$QP"` |

No other check reads `harness status` or `harness queue list` text (`grep -n '"$H" status\|queue list' tests/checks/*`
at the init's tree: the files above and `07-step-lint`'s lint string, which is data). The step lint check
in `07-step-lint-pure-r3.sh` is untouched.

## 6. Order: U1-02 to U1-07, and the suite after each

Each feature leaves every existing check green: the old `harness status <run>` text stays until U1-05 replaces it,
and the old `queue list` text until U1-06.

| Feature | Builds | Old text | Suite after |
|---|---|---|---|
| U1-02 | `lib/view.mjs`, `51-view-pure.sh`, `end-reasons.txt`; the decision file `journal/decisions/2026-10-27-read-views.md` started (finding, the formatter's choices) | untouched (nothing calls it) | 602 + 51-'s checks |
| U1-03 | `lib/status.mjs` (input, objects, NEEDS derivation, `--json`), `run_rows` in bin/harness, `status_stubs` in tests/lib.sh, `52-status-json.sh`, `status-json-keys.txt`; `harness status [<run>] --json` | `harness status` and `<run>` text byte for byte (52- compares) | + 52- |
| U1-04 | the default view (no `<run>`): sections, footer, `--all`, `--since`, `--project`, `-v`, `N`; `STATUS_SINCE` in `lib/config.sh` (default `24h`) and commented in `templates/user/config.sh`; `prompts/project-catchup.md` → `harness status --project <p>`; `53-status-view.sh` | `harness status <run>` keeps the old loop (cmd_status branches on a run argument); no existing check calls `harness status` without a run | + 53- |
| U1-05 | the card for `harness status <run>` (and `-v`, `N`), the old loop removed; the four "ended: done" checks, 08-'s units check and 47-'s capture rewritten (§5.3) in the same commit; `prompts/supervisor.md` → `harness status {{RUN_ID}} -v` (`N=20` still works); `54-status-card.sh` | replaced | + 54-, rewrites green |
| U1-06 | `queue list` and `queue show <n> [--parked]` through `status.mjs`; the four 15- queue checks rewritten (§5.3); `55-queue-view.sh` | replaced | + 55-, rewrites green |
| U1-07 | the Opus review from a diff file in scratch (`git diff origin/main...HEAD -- . ':!.harness/runs' > <scratch>/U1.diff`), Critical and Important findings fixed RED → GREEN, simplifications; `README.md` (the command table, the flags, `STATUS_SINCE`, `NO_COLOR`, `harness queue show`), `docs/architecture.md` (§3 `view.mjs` and `status.mjs`; §4 nothing new on disk; §12 the queue view), the usage header lines of `harness status` and `queue show` in bin/harness, the user config template, and the decision file complete (finding · choice · rejected: a pager by default; colour off a TTY; `column(1)` or npm table and colour packages; hiding NEEDS when the window is short; per-command formatting code) | — | green |

Every behaviour the CLI gains is a read: none writes `harness-log.md`, so there is no `note` to add (CLAUDE.md's
"visible in `harness-log.md`" is for the driver and the CLI's writes; the views write nothing, and 52- asserts that).

## 7. Decisions taken here (recorded as defaults in `2026-10-27-read-views`, U1-02 onwards)

1. A run-level NEEDS item only when the run has no feature or milestone item (§3.2): `waiting on Michael: B` is B's row.
2. A crashed run (no `ended`, a stale `driver.pid`) is `state: crashed`, class `failed`, in FINISHED by its `run.log`
   mtime, with a `driver_crash` item while its worktree exists (U2 synthesizes the same item from the record).
3. Lane liveness is tested in node (`process.kill(pid, 0)`); the driver's `alive` stays bash's (field 6), so
   `ending` (2) keeps its one definition.
4. The card's `lanes` field prints P2-06's lines verbatim, indented 4 (not hanging under the label), so its text and
   47-'s check are kept.
5. `harness status <run> --json` carries `v: 1` with the run object, so every `--json` document has it.
6. The checks pin `HARNESS_GLYPHS=unicode` per command, never globally.

## 8. Michael's after-run step

Optional: `STATUS_SINCE=48h` in `~/.config/harness/config.sh` if 24 hours is too short a memory. Then `harness status`
and `COLUMNS=60 harness status` at the terminal and from the phone; `NO_COLOR=1 harness status` if the colours are
unwanted. Nothing to install: the views are in the live checkout once it syncs.
