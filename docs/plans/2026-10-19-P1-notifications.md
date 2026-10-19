Milestone base: a4625257b22ecb3aee0de6d1a80fabc383a4855f

# P1 · Notifications carry the question and the links (plan)

Spec: `docs/specs/2026-10-19-phone-answers.md` § P1. This plan fixes the interfaces so P1-02, P1-03 and P1-04 build
the same thing; P1-05 (review) diffs from the base above. Decision: D-H29 (P1-05 writes it).

Builders: P1-02 = §1–§4 and the P1-02 checks of §7 · P1-03 = the park row of §5, §6 and its checks ·
P1-04 = every other row of §5 and its checks. Nothing here changes how parking, verify or merging work.

## 1. Where the code lives

| File | What | Who |
|---|---|---|
| `lib/notify.sh` (new) | `notify` and `gh_url`, sourced by `lib/driver.sh` and `lib/debrief.sh` (one `source` line each) | P1-02 (`gh_url`: P1-03) |
| `lib/notify.mjs` (new) | pure helpers (§3), exported, plus a small CLI for bash (same `main([cmd, …])` + `import.meta.url` idiom as `lib/features.mjs`) | P1-02 (`trimBody`, `actionsHeader`), P1-03 (`githubUrls`, `inboxQuestion`) |
| `lib/config.sh` | `NTFY_URL="" NTFY_TOKEN="" DESK_URL=""` on the `CHECK_CMD=… NOTIFY_CMD=""` defaults line | P1-02 (all three, so P1-03 only reads `DESK_URL`) |
| `bin/harness` | `HARNESS_CURL` added to the `for v in HARNESS_CLAUDE …` list in `cmd_start` (tmux-started drivers lose it otherwise; the suite runs `--foreground`, so check by reading) | P1-02 |
| `lib/driver.sh` | the one-line `notify()` is replaced by `source "$HARNESS_HOME/lib/notify.sh"` + `NOTIFY_TAG=$RUN_ID`; call sites get fields (§5); `$STATE/inbox-before.md` (§6) | P1-02, P1-03, P1-04 |
| `lib/debrief.sh` | `tell()` goes; its two callers call `notify` (no `NOTIFY_TAG`: the messages already start `[debrief]`) | P1-04 |
| `tests/stub-curl.sh`, `tests/fixtures/ntfy-publish.txt` (new) | §4 | P1-02 |

Usage header for `lib/notify.sh` (line 2, after the shellcheck line, matching the other lib files):

```bash
# Usage: source lib/notify.sh; notify "<message>" [title=…] [body=…] [click=…] [actions=…] [priority=…] [tags=…]
#        gh_url <path in the repo> [blob|edit]   (the GitHub URL of that file on the current branch, or nothing)
```

## 2. `notify`: signature, environment, ntfy request

```bash
notify "<message>" [title=<t>] [body=<text>] [click=<url>] [actions=<ntfy actions header>] [priority=<p>] [tags=<t,t>]
```

- `<message>` is the one-line message. With `NOTIFY_TAG` set (the driver sets `NOTIFY_TAG=$RUN_ID`), it is sent as
  `[<NOTIFY_TAG>] <message>`, so **`$1` to `NOTIFY_CMD` stays exactly `[<run>] <message>`** as today. The debrief
  leaves `NOTIFY_TAG` unset and its messages keep their own `[debrief] …` prefix.
- Fields are `key=value` words after the message, in any order, any subset; an empty value is the same as absent.
  Unknown keys are ignored. `title` defaults to `harness` (what Michael's NOTIFY_CMD sends today). `actions` is the
  already-built header string from `node lib/notify.mjs actions …` (§3), so the same string reaches both paths.
  `priority` is an ntfy name (`high`; absent = ntfy's default 3; routine notifications never pass one).
- Header values (title, click, actions, tags, priority) have CR and LF replaced by spaces: a `why` or reason must
  not be able to add a header. Titles we build are ASCII (run and feature ids); ntfy accepts UTF-8 headers anyway.
- `body` is trimmed with `trimBody` (cap 3500 bytes, ends `…` when cut) before either path sees it.
- `notify` always returns 0 and never blocks the run for more than curl's `--max-time 15`. Its children get `9>&-`
  (the debrief holds its lock on fd 9; today's `tell` does the same).

**Path A, `NTFY_URL` set** (it wins: `NOTIFY_CMD` is not called):

```bash
"${HARNESS_CURL:-curl}" -sS --fail --max-time 15 -o /dev/null \
  -H "Title: <title>" [-H "Priority: <p>"] [-H "Tags: <tags>"] [-H "Click: <url>"] [-H "Actions: <actions>"] \
  [-H "Authorization: Bearer $NTFY_TOKEN"] --data-binary "<body, or the message when there is no body>" "$NTFY_URL"
```

Argument order is fixed (the stub log's parsing relies on it): options, `-H` pairs in the order above,
`--data-binary` and the data as the second-to-last pair, **the URL last**. A header is left out when its field is
empty (Title never is). Success: `log "notified: <title>"` (run.log only). Failure (any non-zero exit):
`note "notification failed (curl exit <n>): <title>"` where `note` exists (driver), else `log` (debrief). Neither
line ever contains the token, the URL's query or the body. `NTFY_TOKEN` appears only as that curl argument (visible
in `ps` for the seconds curl runs, like Michael's NOTIFY_CMD curl today; accepted, single-user box).

**Path B, only `NOTIFY_CMD` set:** `bash -c "$NOTIFY_CMD" _ "<[tag] message>"` as today, with exactly these five
variables in its environment (set for that command only, empty when the field is absent, title `harness` by default):

| Variable | Value |
|---|---|
| `HARNESS_NOTIFY_TITLE` | the title |
| `HARNESS_NOTIFY_BODY` | the trimmed body (empty when none) |
| `HARNESS_NOTIFY_CLICK` | the click URL |
| `HARNESS_NOTIFY_ACTIONS` | the ntfy actions header, `view, <label>, <url>; view, …` |
| `HARNESS_NOTIFY_PRIORITY` | `high` or empty |

`tags` reaches only ntfy (the spec's P1.1 lists five variables). Neither set: nothing happens.

## 3. `lib/notify.mjs`: pure helpers (exported) and the CLI bash calls

```js
githubUrls(originUrl, branch, path)  // -> { blob, edit } | null
//   git@github.com:o/r.git, git@github.com:o/r, https://github.com/o/r.git, https://github.com/o/r(/),
//   ssh://git@github.com/o/r.git -> { blob: "https://github.com/o/r/blob/<branch>/<path>",
//                                      edit: "https://github.com/o/r/edit/<branch>/<path>" }
//   anything else (a local path, another host) -> null. Branch and path are joined as-is (harness/<run> keeps its /).
trimBody(text, cap = 3500)           // -> text unchanged when Buffer.byteLength(text) <= cap; else cut at a UTF-8
//   character boundary so that the result *including* the trailing "…" (3 bytes) is <= cap bytes, and ends in "…".
actionsHeader([{ label, url }])      // -> "view, <label>, <url>; view, <label>, <url>" — entries with an empty url
//   are skipped, at most 3 kept (ntfy shows three buttons); [] or all empty -> "".
inboxQuestion(before, after)         // -> the lines of `after` above its "## Answers" line that are not in `before`
//   above its "## Answers" (multiset difference, order of `after`), leading/trailing blank lines dropped, joined
//   with "\n"; "" when nothing was added. Text after "## Answers" never counts (that is Michael's).
```

CLI (`node lib/notify.mjs <cmd> …`), each a thin wrapper over the export:
`urls <origin> <branch> <path>` prints `blob<TAB>edit` (exit 1, nothing printed, when null) ·
`trim [cap]` stdin → stdout · `actions <label> <url> [<label> <url> …]` prints the header (may be empty) ·
`question <before file> <after file>` prints the added lines (a missing before file counts as empty).

`gh_url <path> [blob|edit]` in `lib/notify.sh`: reads `git config --get remote.origin.url` (**not**
`git remote get-url`, which returns the `insteadOf`-rewritten URL), the current branch, calls `urls`, prints the
chosen URL or nothing. Run in the worktree (the driver's cwd).

## 4. Test doubles: `tests/stub-curl.sh` and the fixture

`tests/stub-curl.sh` (executable; `tests/run.sh` exports `HARNESS_CURL=$HERE/stub-curl.sh` beside
`HARNESS_CLAUDE`): appends **one block per call** to `$STUB_DIR/curl.log`: every argument on its own line
(`printf '%s\n' "$@"`; a multi-line body spans lines), then a line `===`. It reads no stdin and makes no network
call. With `STUB_CURL_FAIL=1` it still records, then prints real curl's `--fail` error to stderr,
`curl: (22) The requested URL returned error: 500`, and exits 22. Otherwise exits 0, prints nothing.

`tests/fixtures/ntfy-publish.txt`: line 1 `https://docs.ntfy.sh/publish/`, then the documented request shape,
copied from that page (fetched 2026-10-19), so a reader can compare the stub's headers with the real API:

```
https://docs.ntfy.sh/publish/
# Title, priority, tags (docs example):
curl -H "Title: Unauthorized access detected" -H "Priority: urgent" -H "Tags: warning,skull" -d "Remote access to phils-laptop detected. Act right away." ntfy.sh/phil_alerts
# Click action:
curl -H "Click: https://www.reddit.com/message/messages" ntfy.sh/reddit_alerts
# Action buttons, simple format:
curl -H "Actions: view, Open Twitter, https://twitter.com/binwiederhier/status/1467633927951163392" ntfy.sh/myhome
# Access token:
curl -H "Authorization: Bearer tk_AgQdq7mVBoFD37zQVN29RhuMzNIz2" -d "Look ma, with auth" https://ntfy.example.com/mysecrets
# Priorities: 5 max|urgent, 4 high, 3 default (when none is set), 2 low, 1 min.
# Messages over 4,096 bytes (or not UTF-8) are sent as an attachment; the harness caps bodies at 3,500 bytes.
```

## 5. Call sites: title, priority, click, body

`<run>` = `$RUN_ID`; `gh(<file>)` = `gh_url "$RUN_DIR/<file>"` (blob), empty for a non-GitHub origin. "—" = absent.
Message (`$1`) text stays as today except where the row says "dropped". Rows marked *needs Michael* are priority
`high`; all others pass no priority.

| # | Where (today's message) | title | priority | click | body / actions | Who |
|---|---|---|---|---|---|---|
| 1 | driver loop, the park: `needs Michael: <id> · <why>` | `[<run>] <id> needs you` | high, tags `question` | `gh(INBOX.md)` | body §6; actions Edit INBOX = `gh_url … edit` of INBOX.md, Answer with Claude = `$DESK_URL`, Progress = `gh(progress.md)` | P1-03 |
| 2 | `finish`: `ended (<reason>): <summary> · $…` | `[<run>] ended: <reason>` | high when `<reason>` starts with `blocked on`, `waiting on Michael`, `feature-list edits` or `initializer failed`; else — | `gh(report.md)` (written and pushed before this notify) | when high: actions Edit INBOX, Progress | P1-04 |
| 3 | loop end: `needs Michael: blocked on …/waiting on Michael: …` | **dropped**: row 2 carries the same reason one line later | | | | P1-04 |
| 4 | `initializer failed`, `ended: <weekly why>`, `ended: <n> sessions refused in a row`, `stopped: feature list edits` (each right before `finish`) | **dropped** for the same reason: one notification per run end | | | | P1-04 |
| 5 | verify `thin`: `<m> needs Michael: verify evidence too thin` | `[<run>] <m> needs you` | high | `gh(progress.md)` | — | P1-04 |
| 6 | verify `red`: `<m> needs Michael: suite red after merging main` | `[<run>] <m> needs you` | high | `gh(progress.md)` | — | P1-04 |
| 7 | verify `fail`: `<m> needs Michael: <id> fails verification` | `[<run>] <m> needs you` | high | `gh(progress.md)` | — | P1-04 |
| 8 | `merge_one` conflict: `<m> needs Michael: conflicts with <main>` | `[<run>] <m> needs you` | high | `gh(harness-log.md)` (there is no PR yet) | — | P1-04 |
| 9 | `merge_one` refused: `<m> needs Michael: merge refused · <url>` | `[<run>] <m> needs you` | high | the PR `$url` | — | P1-04 |
| 10 | `merge_one` proposed (`MERGE_POLICY=pr`): `<m> verified · review: <url>` | `[<run>] <m> ready to merge` | — | the PR `$url` | — | P1-04 |
| 11 | `merge_one` merged: `<m> merged · <url>` | — (`harness`) | — | the PR `$url` | — | P1-04 |
| 12 | `started: <summary>` | — | — | `gh(progress.md)` | — | P1-04 |
| 13 | `paused`, `refused (<reason>); waiting until <hh:mm>` | — | — | — | — | unchanged |
| 14 | debrief `fail()`: `[debrief] <what>: <why>` | `harness debrief` | — | — | — | P1-04 |
| 15 | debrief headline: `[debrief] <headline>` + 2 lines + note path | `harness debrief` | high when the note's `## Needs Michael` section is not `Nothing.` / empty | — (the note is a local path, not a URL) | — | P1-04 |

Rows 3–4 are a choice this plan makes (D-H29 records it): today a run that ends needing Michael sends two
notifications (one at once, one after the merge, suite and retro; P1-05 corrected "in the same second"); after P1 it
sends one, right after `run ended` is pushed and before the retro (P1-05), high, whose click is the report and whose actions reach
the INBOX. The park itself (row 1) already went out with the INBOX as its click.

## 6. The park body (P1-03)

Before every coding session (in the loop, right before `session coding`):
`cp "$RUN_DIR/INBOX.md" "$STATE/inbox-before.md" 2>/dev/null`. In the park branch (after `F park`):

```
PARKED: <why>

<node lib/notify.mjs question "$STATE/inbox-before.md" "$RUN_DIR/INBOX.md">   (this block and its blank line only when non-empty)

Answer: harness answer <run> "…"
```

That text is the `body=` field (trimmed by `notify`); `$1` stays `[<run>] needs Michael: <id> · <why>`.

## 7. Checks to add to `tests/run.sh` (names exact; write each first and watch it fail)

**Suite plumbing.**
- `HARNESS_CURL=$HERE/stub-curl.sh` in the exported test environment (line 8). A `curl_with <key>` helper beside
  `msg_with` prints the first `===` block of `$T/curl.log` containing `<key>`; `curl_body <key>` prints that
  block's lines after `--data-binary`, without the last line (the URL).
- **GitHub-shaped origin, for the whole suite (P1-03):** line 25 becomes
  `git config url."$T/origin.git".insteadOf git@github.com:test/proj.git && git remote add origin git@github.com:test/proj.git`.
  Pushes and fetches stay local (`insteadOf` rewrites both; `git remote get-url`, used by the stubs, returns the
  local path), while `git config --get remote.origin.url` (what `gh_url` reads) returns the GitHub URL. Worktrees
  share the config. Run the whole suite once right after this one-line change, before anything else, so a
  regression is attributed to it. The non-GitHub case sets `remote.origin.url` back to `$T/origin.git` for one run.
- Base user config (line 16) becomes `LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1 NTFY_URL=https://ntfy.example/t
  NTFY_TOKEN=tok-secret-123` plus `NOTIFY_CMD` appending `$1` and `===` to `$T/notify-cmd.log` (P1-02). Runs 1–14
  then post through the stub curl; the later rewrites (lines 160/162, 266) keep `NTFY_URL` where a check below
  reads curl.log from that run. The debrief section's NOTIFY_CMD-only config (line 188) stays as it is.

**P1-02** (structured notify, ntfy, cap, token)
- `notify.mjs: trimBody caps at 3500 bytes with …` — unit (`node --input-type=module -e`): 4000 × `x` → ≤ 3500
  bytes ending `…`; a 4000-byte text of `é` cuts on a character boundary; 100 bytes unchanged.
- `notify.mjs: actionsHeader joins view actions, skips empty urls, at most 3` — unit.
- `NTFY_URL: curl posts the fields as headers, NOTIFY_CMD not called` — run 1 (demo): `curl_with "[demo] started:"`
  has `https://ntfy.example/t` as its last line, `-H` then `Title: harness`, and the message as the body;
  `$T/notify-cmd.log` does not exist.
- `NTFY_TOKEN: bearer header sent, never logged` — demo: `Authorization: Bearer tok-secret-123` in curl.log;
  `grep -r tok-secret-123` over `$HARNESS_STATE/proj/demo` and `$RD/harness-log.md` finds nothing (before gc).
- `NOTIFY_CMD-only: $1 unchanged, fields as env` — run 2 (stoppy) with a config of only `NOTIFY_CMD` that appends
  `$1` and `env | grep ^HARNESS_NOTIFY_` to `$T/notify-env.log`: it holds `[stoppy] started: …` and
  `HARNESS_NOTIFY_TITLE=harness`, and curl.log has no `[stoppy]` block. The base config is restored after run 2.
- `a body over the cap is trimmed` — no run needed: `( NTFY_URL=https://ntfy.example/t; NOTIFY_CMD=; log() { :; };
  source "$HH/lib/notify.sh"; notify "long one" body="$(head -c 4000 /dev/zero | tr '\0' x)" )`; `curl_body "long one"`
  is ≤ 3500 bytes and ends in `…`.
- `a failed post is noted and the run goes on` — run 4 (gated) runs with `STUB_CURL_FAIL=1`: `hlog gated` has
  `notification failed (curl exit 22): harness`, and gated's existing checks stay green; demo's harness-log has no
  `notification failed` (success is run.log only: `grep -q "notified: harness" "$HARNESS_STATE/proj/demo/run.log"`).

**P1-03** (the park)
- `notify.mjs: githubUrls for ssh, https and non-GitHub origins` — unit (the four forms of §3 and a local path → null).
- `notify.mjs: inboxQuestion is the lines added above ## Answers` — unit (the P1-03 step's example; added lines
  below `## Answers` are not returned).
- `a park notification: title, question, answer command, click and Edit INBOX action` — run 16 (parky), config
  base + `DESK_URL=https://claude.ai/code/env-test`: `curl_with "Title: [parky] B needs you"` has `Priority: high`,
  `Tags: question`, `Click: https://github.com/test/proj/blob/harness/parky/.harness/runs/parky/INBOX.md`, an
  `Actions:` line containing `view, Edit INBOX, https://github.com/test/proj/edit/harness/parky/.harness/runs/parky/INBOX.md`
  and `view, Progress, https://github.com/test/proj/blob/harness/parky/.harness/runs/parky/progress.md`, and a body
  containing `PARKED: set the gatus vars`, `### B: set the gatus vars, then answer` and `harness answer parky`.
- `Answer with Claude only when DESK_URL is set` — parky's Actions line contains
  `view, Answer with Claude, https://claude.ai/code/env-test`; the `parkl` block below has none.
- `no URLs for a non-GitHub origin` — a new short run `parkl`: `git -C "$T/proj" config remote.origin.url "$T/origin.git"`,
  base config without `DESK_URL`, `STUB_PARK=A` (B and C wait on A, so it ends after one session, waiting on
  Michael), then set `remote.origin.url` back to `git@github.com:test/proj.git`. Its `[parkl] A needs you` block
  has the title and a body with `harness answer parkl`, and no `Click:` and no `Actions:` line.

**P1-04** (every other needs-Michael notification)
- `a waiting-on-Michael run end: priority high, click = report.md` — parky's first run: the
  `[parky] ended (waiting on Michael: B)` block has `Priority: high` and
  `Click: https://github.com/test/proj/blob/harness/parky/.harness/runs/parky/report.md`.
- `one notification per run end` — parky's first run produced exactly one block containing `ended (` and none
  containing `needs Michael: waiting on Michael` (rows 3–4).
- `a refused merge: priority high, click = the PR` — run 10 (later): a block with `needs Michael: merge refused`,
  `Priority: high`, `Click: https://example.test/pr/<n>` (the stub gh's URL for that PR).
- `verify needs Michael: priority high, click = progress.md` — run 3 (strict, GitHub-shaped origin): a block with
  `M1 needs Michael`, `Priority: high` and `Click: https://github.com/test/proj/blob/harness/strict/.harness/runs/strict/progress.md`.
- `routine notifications keep the default priority` — demo's `[demo] started:` and `[demo] M1 merged` blocks have
  no `Priority:` line.
- `debrief notifications go to NTFY_URL when set` — after the existing debrief checks, rerun
  `STUB_DEBRIEF_DEAD=1 "$H" debrief` with `NTFY_URL` added to that section's config: curl.log gains a block with
  `[debrief] failed` and `Title: harness debrief` and no `Click:`; the existing NOTIFY_CMD debrief checks stay green.

## 8. Not in P1

`harness parked` (P2), the desk session and `DESK`/`DESK_MODEL` (P3), notifications for anything not in §5, and
answering through ntfy (out of scope in the spec). Docs (README Steering/Notifications, architecture §3/§10/§13,
D-H29) are P1-05's, as the feature list says.
