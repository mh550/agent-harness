Milestone base: 39968f754e7d1c428d23f55a7c8ce23940341028

# P2 · An answer desk for phone sessions (plan)

Spec: `docs/specs/2026-10-19-phone-answers.md` § P2. This plan fixes the interfaces so P2-02 and P2-03 build the same
thing; P2-04 (review) diffs from the base above and writes D-H30 (`harness parked`, the skill, `DESK_URL`).

Builders: P2-02 = §1–§4 and its checks in §7 · P2-03 = §5, §6 and its checks in §7. Nothing here changes how parking,
answers or continuing work: `harness parked` only reads, the skill only runs commands that already exist.

## 1. Where the code lives

| File | What | Who |
|---|---|---|
| `lib/parked.mjs` (new) | pure helpers (§3), exported, plus a `report` CLI that reads the files bash names on stdin (same `main([cmd, …])` + `import.meta.url` idiom as `lib/notify.mjs`) | P2-02 |
| `bin/harness` | `cmd_parked` (§4), a `parked)` case, a usage-header line, and the help range `sed -n '2,34p'` → `'2,35p'` (the header grows by one line) | P2-02 |
| `tests/run.sh` | §7 | P2-02, P2-03 |
| `skills/harness-answer/SKILL.md` (new) | §5 | P2-03 |
| `templates/user/config.sh` (new) | §6 | P2-03 |
| `README.md` | the install line, `harness parked` in the commands table, `DESK_URL` under Steering (P2-03); the rest of the docs (architecture §3 and the new "Answer desk" section, D-H30, the Tests count) are P2-04's | P2-03, P2-04 |

Usage header of `lib/parked.mjs` (line 1–4, matching `lib/notify.mjs`):

```js
// What runs are waiting on Michael for, and the exact commands that answer them (`harness parked`). No dependencies.
//
//   report [--json] [--runner 0|1] [--run <id>]  → stdin: one line per run, "<run>\t<project>\t<state dir>\t<run record
//                                                   dir>\t<running 0|1>"; reads parked.json, feature_list.json, INBOX.md
```

`bin/harness` usage-header line (after `harness answer`):

```
#   harness parked [<run-id>] [--json]           what parked features wait on: why, the INBOX question, the next commands
```

## 2. What `harness parked` prints

One block per parked feature that isn't passing (what `features.mjs parked` lists: `parked.json` minus passing ids),
across every run under the state root or only `<run-id>`'s, **oldest `since` first**, blocks separated by one blank
line. For the `parky` scenario of `tests/run.sh` (no queue runner), exactly:

```
parky · proj · B
  since:    2026-10-19 01:00 (2 h ago)
  why:      set the gatus vars
  question: ### B: set the gatus vars, then answer
  running:  no
  next:     harness answer parky "…"
            harness continue parky
```

- Line 1: `<run> · <project> · <feature>` (project = `basename` of `PROJECT_DIR` from `meta.env`).
- `since`: `parked.json`'s `at` in local time, `YYYY-MM-DD HH:MM`, then the age: `(<n> min ago)` under an hour,
  `(<n> h ago)` under two days, else `(<n> d ago)` (floor). `now` is an option of the pure function (§3), so unit
  checks are deterministic (run them with `TZ=UTC`).
- `why`: `parked.json`'s `why` (the session's `PARKED:` text), one line.
- `question`: §3 `questionFor`; each line after the first indented to the value column (12 spaces). No question
  found: `question: (none in INBOX.md)`.
- `running`: `yes` or `no` (§2.1). When `yes`, the `next:` block has only the
  answer command and line `running:` reads `yes (it takes the answer before its next session)`.
- `next`: the commands of §2.1, the first after `next:`, the second on its own line in the value column.

Nothing parked: `nothing parked` (all runs) or `nothing parked in <run>` (one run); exit 0 either way.
An unknown `<run-id>`: `state_of` dies as for every other command (`harness: no run '<id>' (see: harness status)`, exit 1).

**`--json`**: a JSON array (pretty-printed, 2 spaces), same order, one object per block, exactly these fields:

```json
[
  {
    "run": "parky",
    "project": "proj",
    "feature": "B",
    "since": "2026-10-19T01:00:00.000Z",
    "why": "set the gatus vars",
    "question": "### B: set the gatus vars, then answer",
    "running": false,
    "commands": ["harness answer parky \"…\"", "harness continue parky"]
  }
]
```

`since` is the stored ISO string unchanged; `question` is `""` when none; nothing parked prints `[]`.

### 2.1 Which commands, when

| State | How it is read | `commands` |
|---|---|---|
| the run is going | `<state>/driver.pid` holds a live pid (`kill -0`): bin/harness's `alive` | `harness answer <run> "…"` only: the driver moves answers into INBOX.md before its next session and the new answers unpark the feature in the same loop (D-H26) |
| not going, a queue runner is going | `$STATE_ROOT/queue/runner.pid` holds a live pid (`kill -0`), the test `harness queue list` uses | `harness answer <run> "…"`, `harness queue add --continue <run>` (a plain `continue` would race the runner's next start for `MAX_PARALLEL_RUNS`) |
| neither | | `harness answer <run> "…"`, `harness continue <run>` |

`"…"` is literal: the placeholder for Michael's words (same text as the park notification's `Answer:` line).

## 3. `lib/parked.mjs`: pure helpers (exported)

```js
questionFor(inbox, feature)            // -> the part of INBOX.md that asks about <feature>, or ""
//   Lines above the first "## Answers" line (all lines when there is none), minus the template's head: a first line
//   "status: …" and any <!-- … --> comment (single- or multi-line). If a "### " heading in what is left names the
//   feature as a whole word (the id between non-[A-Za-z0-9_-] characters or line ends; "### B: set …" names B, "### Bx"
//   doesn't), the result is that heading and its lines up to the next "### " or the end; else all of what is left.
//   Leading/trailing blank lines dropped; "" when nothing is left. Text under "## Answers" never counts (Michael's).
commandsFor(run, { running, runner })  // -> string[] per §2.1
entriesFor({ run, project, parked, list, inbox, running, runner })
//   parked = parsed parked.json ({ <id>: { why, at, answers } }), list = parsed feature_list.json (or null), inbox =
//   INBOX.md's text (or ""). -> [{ run, project, feature, since, why, question, running, runner }] for every parked id
//   whose feature isn't passing (a missing list: every parked id), in parked.json's order.
parkedReport(entries, { json = false, now = Date.now(), run = "" } = {})
//   -> the whole output of §2 as one string ending in "\n": entries sorted by since (stable), commands from
//   commandsFor; json: the array of §2 (runner is not a JSON field). [] -> "nothing parked" / "nothing parked in <run>"
//   (or "[]").
```

The P2-02 step's one-liner holds against this: `parkedReport([{run:'r',project:'p',feature:'B',since:'2026-10-19T01:00:00Z',
why:'w',question:'q',running:false,runner:false}])` contains `harness answer r "…"` and `harness continue r`; with
`runner:true`, `harness queue add --continue r` and no `harness continue r`.

CLI `report [--json] [--runner 0|1] [--run <id>]`: reads stdin lines `<run>\t<project>\t<state dir>\t<record dir>\t<0|1>`;
for each reads `<state dir>/parked.json` (missing → `{}`), `<record dir>/feature_list.json` (missing or unparsable →
null) and `<record dir>/INBOX.md` (missing → ""), calls `entriesFor` with `running` from the line and `runner` from
the flag, concatenates, prints `parkedReport(all, { json, run })`. Read-only: no `writeFileSync`, no `mkdir` anywhere in
the module.

## 4. `cmd_parked` in `bin/harness`

```bash
cmd_parked() {   # [<run-id>] [--json]: read-only
  local want="" json=() d runner=0
  while (( $# )); do case $1 in --json) json=(--json) ;; -*) die "unknown option $1" ;; *) want=$1 ;; esac; shift; done
  [[ -n $want ]] && state_of "$want" > /dev/null
  [[ -f $Q/runner.pid ]] && kill -0 "$(cat "$Q/runner.pid")" 2> /dev/null && runner=1
  for d in "$STATE_ROOT"/*/*/; do
    [[ -f $d/meta.env ]] || continue
    [[ -n $want && $(basename "$d") != "$want" ]] && continue
    # shellcheck source=/dev/null
    ( source "$d/meta.env"
      printf '%s\t%s\t%s\t%s\t%s\n' "$RUN_ID" "$(basename "$PROJECT_DIR")" "$STATE" "$WT/.harness/runs/$RUN_ID" "$(alive "$STATE" && echo 1 || echo 0)" )
  done | node "$HARNESS_HOME/lib/parked.mjs" report "${json[@]}" --runner "$runner" --run "$want"
}
```

Dispatch: `parked) shift; cmd_parked "$@" ;;` beside `status`. It never calls `harness_config`, `mkdir` or
`queue_add` (`cmd_queue` does `mkdir -p "$Q/done"`; `parked` must not go through it).

## 5. `skills/harness-answer/SKILL.md` (P2-03)

Frontmatter, exactly these two keys:

```yaml
---
name: harness-answer
description: Use when Michael asks to "answer the harness", "what does <project> need?", or opens a session from a harness notification's "Answer with Claude". Finds what the harness waits on, checks what can be checked safely, proposes answers, and passes them on only after his yes.
---
```

Sections, in this order (headings as named; short imperative text, written for a phone-sized conversation):

1. **`## What to run first`**: `harness parked` (or `harness parked <run>`), then for each run listed
   `harness status <run>`; read the run's INBOX.md above `## Answers`
   (`~/worktrees/<project>/<run>/.harness/runs/<run>/INBOX.md`) and the newest two entries of its `progress.md` (same
   directory). Commands named in this order of use across the file: `harness parked`, `harness status <run>`,
   `harness answer <run> "<text>"`, `harness queue list`, `harness queue add --continue <run>`, `harness continue <run>`.
2. **`## What you may check`**: read-only checks, and say what was checked: files and `git log`/`git status` in the
   worktree, `docker ps`, whether a variable is set **by name only** (`grep -c '^NAME=' file`), **never a value**;
   never print or read `.env` contents, tokens, keys or other secrets; nothing with `sudo`; none of the project's live
   commands (deploys, migrations, writes to a service).
3. **`## Proposing`**: one brief: what is waiting and since when, then each open item numbered with what was checked,
   the options and a recommendation in one or two sentences. Michael answers by number ("1 yes, 2 skip").
4. **`## Acting, only after his yes`**: for each item he decided, `harness answer <run> "<his decision, in his words,
   with the item it answers>"`; read it back; then continue the run once: `harness queue list` → a runner going:
   `harness queue add --continue <run>`, else `harness continue <run>`; a run still going needs no continue (the
   `harness parked` output already says so). An ambiguous reply gets a follow-up question, not a guess.
5. **`## Never`**: never edit INBOX.md, feature lists, policies or CLAUDE.md directly; never answer without Michael's
   yes; never answer an item he didn't decide; never run a project's live commands; never `sudo`; never start,
   stop or merge runs other than the `continue` above.

README install line (P2-03, in Steering, verbatim):
`ln -s ~/projects/agent-harness/skills/harness-answer ~/.claude/skills/` (once; Michael runs it, sessions never touch
`~/.claude`).

## 6. `templates/user/config.sh` (P2-03)

The documented example of `~/.config/harness/config.sh`, commented like `templates/project/config.sh` (a header that
says what the file is, short `#` comments that say why). **Every assignment is commented out**, so sourcing the template
changes nothing. Content:

```bash
# ~/.config/harness/config.sh — your settings for every project (bash, sourced). Layers, later wins: the harness
# defaults (lib/config.sh, every setting and its default) → this file → <project>/.harness/config.sh → the run's options.
# Start from this file: mkdir -p ~/.config/harness && cp templates/user/config.sh ~/.config/harness/config.sh

# Notifications: NTFY_URL (the harness posts itself: title, priority, click, actions) or NOTIFY_CMD. NTFY_URL wins.
# NTFY_URL=https://ntfy.sh/<your private topic>
# NTFY_TOKEN=<access token>          # optional; sent as "Authorization: Bearer …", never logged
# NOTIFY_CMD='curl -s -H "Title: $HARNESS_NOTIFY_TITLE" -d "$1" https://ntfy.sh/<topic>'   # $1 = "[<run>] <message>"

# "Answer with Claude" on a park's notification opens this: your Remote Control environment's URL from the Claude app.
# DESK_URL=<the URL>                 # no "," or ";" in it (they split ntfy's Actions header)

# The desk (P3, not built yet): a Remote Control session the harness starts when a run needs you.
# DESK=0                             # 1 = start one on a park, a blocked or waiting run end, verify or a merge needing you
# DESK_MODEL=opus
```

P3-06 rewrites the last block once the desk exists. `bash -n templates/user/config.sh` passes.

## 7. Checks to add to `tests/run.sh` (names exact; write each first and watch it fail)

**P2-02** (`harness parked`), unit checks with the other `.mjs` units near the top:
- `parked.mjs: the report names the answer and continue commands` — the P2-02 step's one-liner (runner false →
  `harness answer r "…"` and `harness continue r`; runner true → `harness queue add --continue r`, no `harness continue r`;
  running true → only the answer command and `running:  yes`); `parkedReport([], {})` is `nothing parked\n` and
  `parkedReport([], {json: true})` parses to `[]`.
- `parked.mjs: the question is the feature's INBOX section` — `TZ=UTC`; an INBOX of `status: run`, the template's
  `<!-- … -->` comment, `### A: db url`, a line, `### B: set the gatus vars, then answer`, `## Answers`, `### B: an old answer`
  → `questionFor(…, "B")` is the B heading alone, `questionFor(…, "C")` is both sections (no heading names C),
  `questionFor("status: run\n\n## Answers\n", "B")` is `""`; and `since` renders as `2026-10-19 01:00 (2 h ago)` with
  `now = Date.parse("2026-10-19T03:00:00Z")`.

End-to-end, after `one notification per run end` and **before** `"$H" answer parky "gatus vars set"` (parky,
parkn and parkl are then all parked and ended; no queue runner):
- `harness parked: id, why, question, both commands` — `"$H" parked > "$T/parked.out"`: contains `parky`, `B`,
  `set the gatus vars`, `harness answer parky`, `harness continue parky` (and lists parkn and parkl too).
- `harness parked is read-only` — `touch "$T/parked.stamp"`, then `"$H" parked`, `"$H" parked parky --json`;
  `find "$HARNESS_STATE" "$T/wt/proj/parky" -newer "$T/parked.stamp"` prints nothing and
  `git -C "$T/wt/proj/parky" status --porcelain` is empty.
- `harness parked --json parses` — `"$H" parked parky --json | jq -e '.[0].feature == "B" and .[0].running == false and (.[0].commands | length) == 2'`.
- `with a queue runner going, the continue command is a queue add` — `mkdir -p "$HARNESS_STATE/queue"; echo $$ >
  "$HARNESS_STATE/queue/runner.pid"`; `"$H" parked parky` contains `harness queue add --continue parky` and not
  `harness continue parky`; then `rm -f "$HARNESS_STATE/queue/runner.pid"` (the later queue checks need no runner).
- `nothing parked` — `"$H" parked demo` prints `nothing parked in demo` (contains `nothing parked`).

**P2-03** (the skill and the template), anywhere after the units:
- `the answer skill exists and names the commands and the never-list` — `skills/harness-answer/SKILL.md` exists, its
  first line is `---`, it has `name: harness-answer`, and contains `harness parked`, `harness answer`,
  `never edit INBOX.md` (case-insensitive) and `sudo`.
- `the user config template sets nothing` — `bash -n "$HH/templates/user/config.sh"` and
  `( unset NTFY_URL NTFY_TOKEN DESK_URL NOTIFY_CMD; source "$HH/templates/user/config.sh"; [[ -z ${NTFY_URL:-}${NTFY_TOKEN:-}${DESK_URL:-}${NOTIFY_CMD:-} ]] )`.

Count: 125 now → 132 after P2-02 → 134 after P2-03 (P2-04 updates README's Tests line to the real number).

## 8. Not in P2

The desk session, `DESK`, `DESK_MODEL` (P3: only commented placeholders in §6); answers that are queued with
`harness answer` but not yet moved into INBOX.md (`<state>/inbox.md`) are not shown by `harness parked` (a later
`harness parked` after `continue` shows the feature gone); docs beyond §1's README items (P2-04).
