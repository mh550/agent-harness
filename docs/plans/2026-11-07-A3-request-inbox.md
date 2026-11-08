# A3 · Request inbox (plan, 2026-11-07)

Run `agent-harness-2026-11-07-3`, feature A3-01. Spec: `docs/specs/2026-10-22-n8n-events.md` §A3 and its Contracts.
Read against `main` at 565414f (A1 and A2 merged), so every line reference below is today's. The request and result
JSON are v1 and fixed: n8n-home is built and live against them (§4.3 of its `docs/specs/2026-10-22-harness-reporter.md`).
What its code pins, read in `~/projects/n8n-home` at 859b25a and never changed:

- **How a request is written** (its `docs/decisions.md` D25, `lib/card.js` `buildRequest`): as the final file
  `<STATE_ROOT>/requests/<id>.json` **in one write, not a temp file renamed** (its Read/Write Files node has no rename),
  `JSON.stringify(request) + "\n"`. That is why the 10 s grace exists. Keys in this order and only these: `answer` →
  `v, id, at, verb, run, text, source, event`; `continue` → `v, id, at, verb, run, source, event`, plus `brief` after
  `run` only when given. An answer-and-continue card writes the `answer` before the `continue` in one Write node, ids
  `1-<h>` and `2-<h>`, so the answer sorts first by name too: oldest first by mtime **then name** keeps it first.
- **What it already refuses itself**: `text` 1–4000 and `brief` 1–2000 by JavaScript `.length` (UTF-16 units),
  `run` `^[A-Za-z0-9][A-Za-z0-9._-]*$`, a NUL anywhere. The harness counts the same way (`.length`), so nothing n8n
  sends is refused here for a length n8n allowed.
- **How it reads the result** (`lib/card.js` `renderResult`, `mainCardResult`): it polls `requests/done/<id>.json`
  for up to 14 s, takes a result only when `typeof r.id === "string"`, and says *refused: `<refused>`* whenever
  `refused != null || ok !== true`, else `exit <n>` for a failure; for a `continue`, `runner_started === true` is
  "is starting again", otherwise "is queued to start again". So the backup window is `ok: true` with `refused` set,
  and every result's `id` is a string (the request file's name when its `id` isn't usable, §1.4).

**In one paragraph.** A3-02 writes `lib/requests.mjs`: pure functions that validate a request file's text against
v1, decide the backup window from a time, name the result, and build the result JSON and the `requests.log` line,
unit-tested in `tests/unit/requests.test.mjs`, plus a small CLI bash reads as labelled lines. A3-03 writes
`lib/requests.sh` (`harness requests`): under `flock` on `requests/.lock`, every pending `*.json`, oldest first, is
validated by that CLI, claimed into `done/`, run as one argv call (`harness answer` or `harness queue add --continue`,
then `harness queue start` outside 03:15–04:30), and answered with a result file and one log line; anything else goes
to `rejected/`. A3-04 ships `systemd/harness-requests.{path,service}` (never installed), verified by
`systemd-analyze --user verify` where it exists, plus the decision file and the docs. Nothing runs unless something
calls `harness requests`: with the units not linked and no request files, the harness works exactly as today.

**Two things the step texts get wrong, fixed here** (each in the entry's `proposed_changes`):

1. **The check file's name.** `tests/checks/requests-inbox.sh` fails the suite's name lint
   (`tests/checks/suite-runner.sh:207`, decisions/2026-11-05-suite-shape: `inbox` is part of `requests-inbox`, so
   `tests/run.sh inbox` would run both). The file is **`tests/checks/request-files.sh`** (checked: no name is part of
   it and it is part of none). A3-03 step 5's `bash tests/run.sh requests-inbox queue-view` is
   `bash tests/run.sh request-files queue-view`; A3-04's `requests-inbox` likewise.
2. **`DirectoryNotEmpty=` would loop.** `requests/` always holds `done/`, `rejected/`, `requests.log` and `.lock`
   after the first pass, so `DirectoryNotEmpty=` is true for ever. systemd.path(5): "When a service unit triggered by
   a path unit terminates …, monitored paths are checked immediately again, and the service accordingly restarted
   instantly … the start rate limit … causes the path unit to fail as well". The unit uses
   **`PathExistsGlob=%h/.local/state/harness/requests/*.json`**, which only pending requests match. The same rule is
   why one `harness requests` call waits out a young file's grace on the real clock instead of leaving it to "the next
   pass" (§2.4): the next pass would be an instant restart, five of which in 10 s fail the path unit.

And one the spec leaves open: **a duplicate id never overwrites the first result** (§1.3). A3-03 step 3 asks the
duplicate for "a result in `done/` whose `ok == false`"; that file is the first request's result, which n8n's card
reads. The duplicate goes to `rejected/`, `done/<id>.json` stays byte-identical (`cmp`), and its log line says why.

---

## 1. A3-02 · lib/requests.mjs

**Files:** `lib/requests.mjs` (new), `tests/unit/requests.test.mjs` (new), `tests/fixtures/requests/` (new: §1.6),
`tests/fixtures/check-names.txt`, `tests/fixtures/check-names-fast.txt` (the unit tier's names, `LC_ALL=C` sorted).
Tier: the unit tier (one node process; `tests/checks/unit-tier.sh` is fast).

Header: `// lib/requests.mjs: the request inbox's rules (v1): validate a request file, the backup window, the result
JSON and the requests.log line.   node lib/requests.mjs validate|result …`. Standard library only; pure functions
exported, the CLI at the bottom behind `import.meta.url === pathToFileURL(process.argv[1]).href` as the other modules
do. `node --check lib/requests.mjs`.

### 1.1 The validation, verbatim from the spec, in this order

`validateRequest(text, { runs, done, ageSeconds })` → `{ verdict, reason, id, verb, run, text, brief }`.
`runs` is a `Set` of real run ids, `done` a `Set` of ids already done, `ageSeconds` now − the file's mtime.
`verdict` is `ok`, `wait`, `rejected` or `duplicate`; `id`, `verb`, `run` are the request's values **only once each
has passed its rule** (else `null`), so nothing unvalidated reaches a path, a log line or a result. The rules, each
failing with the reason string beside it (a check greps it with `grep -F`, so each is exact):

| # | Rule (spec §A3 "Validate") | Verdict and `reason` when it fails |
|---|---|---|
| 1 | parses as JSON | `ageSeconds < 10` → `wait` (n8n may still be writing it; a negative age, a clock behind the file, is young too) · else `rejected`, `the request is not JSON (still unparsable after 10 s)` |
| 2 | a JSON object (not an array, a string, `null`) | `rejected`, `the request is not a JSON object` |
| 3 | no NUL byte in any string value or key (`\u0000`; a raw NUL never parses, rule 1) | `rejected`, `the request holds a NUL byte` |
| 4 | `v === 1` | `rejected`, `v is not 1 (this harness reads request v1)` |
| 5 | `id` a string matching `^[A-Za-z0-9-]{8,64}$` | `rejected`, `id does not match ^[A-Za-z0-9-]{8,64}$` |
| 6 | `id` not in `done` (idempotent) | `duplicate`, `duplicate id: done/<id>.json already exists` (the id has passed rule 5) |
| 7 | `verb` is `answer` or `continue` | `rejected`, `verb is not answer or continue` |
| 8 | `run` a string matching `^[A-Za-z0-9._-]+$` | `rejected`, `run does not match ^[A-Za-z0-9._-]+$` |
| 9 | `run` in `runs` (a real run, bin/harness `state_of`'s rule: §2.2) | `rejected`, `no run '<run>' (see: harness status)` (state_of's own words; the run has passed rule 8) |
| 10 | `answer`: `text` a string of 1–4000 characters (`.length`) | `rejected`, `text must be 1-4000 characters for answer` |
| 11 | `brief`, when present and not `""`: a string of at most 2000 characters | `rejected`, `brief must be a string of at most 2000 characters` |

A reason never quotes `text`, `brief` or a value that failed its rule: the result and the log line are safe to show
anywhere. Rule 3 comes before the field rules so a NUL in `text` is the NUL reason, as the unit test expects.

*Defaults* (in the decision file, §3.3): keys outside v1 (`at`, `source`, `event`, anything else) are not checked;
a `text` on a `continue` and a `brief` on an `answer` are ignored, not refused (the spec refuses neither; n8n never
sends them); an empty `brief` is no brief (no `--brief ""`); `at` is not compared with the clock.

### 1.2 The backup window

`inBackupWindow(date)`: local time, `03:15:00 <= t < 04:30:00` (minutes × 60 + seconds from `getHours`,
`getMinutes`, `getSeconds`), so 03:15:00 and 04:29:59 are in and 03:14:59 and 04:30:00 are out. The refusal is the
spec's string exactly: `BACKUP_REFUSAL = "backup window 03:15–04:30: queued, runner not started"` (an en dash;
exported, so the unit test and lib/requests.sh's check read one constant; the check file greps it with `grep -F`).

### 1.3 The result JSON and the duplicate

`resultJson({ id, verb, run, ok, exit, output, runnerStarted, refused, now })` → the object in the contract's key
order, `v, id, at, verb, run, ok, exit, output, runner_started, refused` (exactly ten keys):

- `v` 1; `at` `new Date(now * 1000).toISOString()`; `verb` and `run` the validated values or `null`;
- `ok` true when every command it ran exited 0 (a backup-window `continue` is `ok: true` with `refused` set: the
  entry is queued); a rejection is `ok: false`;
- `exit` the last command's exit status (`queue start`'s when it ran, else `queue add`'s or `answer`'s); a rejection,
  where nothing ran, is `exit: null` (*default*: no command, no status; n8n reads `refused` first, `lib/card.js:414`);
- `output` the commands' stdout and stderr together, **the first 2000 bytes** of its UTF-8, cut on a character
  boundary (a cut never leaves half a character); a rejection's is `""`;
- `runner_started` true only when `harness queue start` printed its `queue runner started` line (§2.3);
- `refused` the rejection's reason, `BACKUP_REFUSAL`, or `null`.

`resultName(verdict, fileName)` → the name the result and the claimed request take in `done/`: the validated `id`;
else the file's name without `.json` when it matches the id rule (n8n names the file `<id>.json`, so that is where its
card looks); else `null` (no result file: the request goes to `rejected/` and its log line says `id=-`). The result's
`id` is that same name, so n8n's `typeof r.id === "string"` holds for every result written.

A **duplicate** (rule 6) gets no result: `done/<id>.json` is the first request's and stays as it is. The duplicate
file moves to `rejected/` and its log line is `refused` with the reason. *Default*, as the spec's "an id already in
`done/` is ignored: idempotent" reads; a second result would overwrite the outcome the card is showing.

### 1.4 The requests.log line

`logLine({ now, name, verb, run, ok, exit, runnerStarted, refused })` → one line, local time first as runner.log's
(`%F %T`, from `now`), fields as `key=value`, a status word, and the reason last because it may hold spaces:

```
2026-10-28 00:00:00 id=req-0001-aaaa verb=answer run=parked ok exit=0
2026-10-28 00:00:01 id=req-0002-bbbb verb=continue run=stopped ok exit=0 runner=started
2026-10-28 03:30:00 id=req-0003-cccc verb=continue run=stopped ok exit=0 why=backup window 03:15–04:30: queued, runner not started
2026-10-28 00:00:02 id=req-0004-dddd verb=- run=- refused exit=- why=verb is not answer or continue
2026-10-28 00:00:03 id=req-0001-aaaa verb=- run=- refused exit=- why=duplicate id: done/req-0001-aaaa.json already exists
```

The status word is `ok`, `failed` (a command exited non-zero) or `refused` (a rejection or a duplicate); `-` stands
for a missing value; `runner=started` only when it did. It takes no `text` or `brief` argument at all, so it can't
carry them (the unit test passes a request whose text is `rm -rf` and greps the line).

### 1.5 The CLI

- `node lib/requests.mjs validate <file> --runs <id,id,…> --done <dir> --now <epoch> --out <dir>`: reads `<file>`
  once (`readFileSync`, after bash has refused a symlink, §2.1), takes `ageSeconds` from its `statSync` mtime and
  `--now`, `done` from `<dir>`'s `*.json` names (a `<id>.json` result and a `<id>.request.json` claim both count, so a
  pass that died between the claim and the result never runs the request twice), and prints labelled lines
  (lib/cli.mjs `labelled`): `verdict <v>`, `name <name or ->`, `id <id or ->`, `verb <verb or ->`, `run <run or ->`,
  `window <0|1>` (the backup window at `--now`), `reason <text>` (last; only when there is one). For `ok` it writes
  `<out>/text` and `<out>/brief` byte for byte (only those present) from the same parse, so bash never parses JSON
  and the text is never on a command line between processes. Exit 0 whatever the verdict; 2 on a usage error.
- `node lib/requests.mjs result --id <name> --verb <v|-> --run <r|-> --ok <0|1> --exit <n|-> --output <file>
  --runner-started <0|1> [--refused <text>] --now <epoch> --log <requests.log>`: prints `resultJson`'s JSON (one line
  and a newline) on stdout, which bash writes to a temp name and renames (§2.3), and appends `logLine` to `--log`.

### 1.6 Fixtures

`tests/fixtures/requests/answer.json`, `continue.json`, `continue-brief.json`, made by n8n-home's own `buildRequest`
at 859b25a (its `lib/memory.js`, `lib/report.js` and `lib/card.js` loaded read-only into one `vm` context as its
`tests/unit/card.test.mjs` does, run `parked` / `stopped`, a fixed id and `at`), written `JSON.stringify(r) + "\n"` as
D25 writes them, with a `tests/fixtures/requests/README.md` naming the commit and the command. The unit tests and the
check build every request from these with `jq` (a changed `id`, `run`, `text`, `v` or `verb`): never a hand-typed
shape.

### 1.7 Unit tests, written first and watched failing (`tests/unit/requests.test.mjs`, flat `test()` calls)

1. `requests.mjs: a valid answer is ok and keeps its text byte for byte`
2. `requests.mjs: a valid continue is ok with and without a brief, and an empty brief is none`
3. `requests.mjs: v 2 is rejected`
4. `requests.mjs: an array, a string and null are not a request object`
5. `requests.mjs: an id of 7 characters or with a slash is rejected and named nowhere`
6. `requests.mjs: an id already in done is a duplicate`
7. `requests.mjs: verb merge is rejected`
8. `requests.mjs: a run with a parent-directory segment is rejected by its pattern before any lookup` (`../x`; `runs`
   holds `x` so only the pattern can refuse it)
9. `requests.mjs: a run not among the real runs is rejected with state_of's words`
10. `requests.mjs: an empty text and a text of 4001 characters are rejected, 4000 is ok`
11. `requests.mjs: a brief of 2001 characters is rejected, 2000 is ok`
12. `requests.mjs: a NUL byte in the text is rejected as a NUL`
13. `requests.mjs: unparsable text waits at 5 s and is rejected at 11 s`
14. `requests.mjs: the backup window holds 03:15:00 and 04:29:59 local, not 03:14:59 or 04:30:00` (`TZ` fixed by
    building the dates with `new Date(y, m, d, h, mi, s)`, local by construction)
15. `requests.mjs: resultJson has the contract's ten keys in order and cuts output at 2000 bytes on a character
    boundary` (keys compared joined; the cut checked by `Buffer.byteLength` and a trailing `é` at the edge, never a
    `deepEqual` of a large value)
16. `requests.mjs: resultName is the id, else the file name when it passes the id rule, else none`
17. `requests.mjs: logLine names id, verb, run, the status and exit and never the text`
18. `requests.mjs: the validate CLI prints labelled lines and writes text and brief byte for byte` (one spawn, via
    `tests/unit/cli-same.mjs` as glossary.test.mjs does; a text with quotes, backticks, a command substitution and a
    trailing newline)

18 names. Done when `node --test --test-isolation=none tests/unit/*.test.mjs` passes, `bash tests/run.sh unit-tier`
ends `N/N checks passed`, and the fast tier is green.

---

## 2. A3-03 · `harness requests` (lib/requests.sh)

**Files:** `lib/requests.sh` (new), `bin/harness` (the dispatch and the header line), `tests/checks/request-files.sh`
(new, `# tier: fast`: status_stubs plus about twenty node calls, a 2 s lock hold and a ~1 s real-clock wait, well
under the 30 s rule; if its measured time is over 30 s it is `slow`, and says so in the entry),
`tests/fixtures/check-names.txt` and `check-names-fast.txt`.

### 2.1 The pass

```
#!/usr/bin/env bash
# harness requests: the request inbox (<state>/requests/*.json, from n8n), each one under flock, oldest first …
#   requests.sh
set -uo pipefail
```

1. **Tools.** The path unit's PATH has no nvm directory: the lines of `lib/debrief.sh:38-45` (`missing` for node, jq,
   flock, tmux; `nvm.sh` when one is missing; `~/.local/bin` for the runner's `claude`) run first, and `export PATH`,
   so `"$H" queue add` (node) and the runner it starts find what they need. Missing still → one line on stderr, exit 1.
2. **The directory.** `R=$STATE_ROOT/requests` (`STATE_ROOT` as bin/harness's). `(umask 077; mkdir -p "$R/done"
   "$R/rejected")`: created mode 700 when missing, `done/` and `rejected/` too; an existing `requests/` keeps its mode
   (*default*: Michael or n8n-home's checklist may have made it). The check: `stat -c %a "$R"` is `700`.
3. **The lock.** `exec 9> "$R/.lock"; flock -w 60 9` (a second call waits; past 60 s: `requests: $R/.lock held for
   60 s` on stderr, exit 1). Held for the whole call, the wait of §2.4 included.
4. **The order.** `find "$R" -maxdepth 1 -name '*.json' \( -type f -o -type l \) -printf '%T@ %f\0' | LC_ALL=C sort
   -z -k1,1n -k2,2` (oldest mtime first, then name: D25's `1-…` answer before its `2-…` continue), read with
   `read -r -d ''`. A symlink (or anything not a regular file) is never read: rejected at once, `the request is not a
   regular file`, moved itself (`mv` moves the link, never its target), with no result unless its name passes the id
   rule. *Default*: n8n writes plain files; a link left in place would match the glob for ever.
5. **Validate.** `while read -r k v; do …; done < <(node "$HARNESS_HOME/lib/requests.mjs" validate "$R/$f" --runs
   "$runs" --done "$R/done" --now "$now" --out "$tmp")`, with `now=${HARNESS_NOW:-$(date +%s)}` (the suite's fake
   clock, epoch seconds as lib/needs.mjs reads it) and `$tmp` a `mktemp -d` removed on exit. An empty verdict (node
   failed) is handled as `wait` with a line on stderr: the file stays, nothing runs (Gotchas: "ask and its spawn can
   both fail").
6. **Per verdict.**
   - `wait`: left in place, no result, no log line; the call remembers it waited (§2.4).
   - `rejected`: `mv -- "$R/$f" "$(free "$R/rejected" "$f")"`, then the result (§2.3) when `name` isn't `-`, with
     `--ok 0 --exit - --refused "$reason"` and an empty output.
   - `duplicate`: moved to `rejected/` as above; no result (`done/<id>.json` is the first one's); the log line only.
   - `ok`: claimed first, `mv -- "$R/$f" "$R/done/$name.request.json"` (the move is the at-most-once mark: a pass that
     dies after it never runs the request again, §1.5); then the verb (§2.2); then the result.
   `free <dir> <name>` → `<dir>/<name>`, or `<dir>/<stem>.<n>.json` with the first free `<n>`: a move never overwrites.
   A failed move: one line on stderr, the call goes on with the next file and exits 1 at the end (the unit's failure
   then shows in `systemctl --user status`).

### 2.2 The verbs: argv only

`runs` is state_of's rule as a list (the `with=` loop of `bin/harness:130`): every `$STATE_ROOT/<p>/<run>/meta.env`
that is a file, `queue/` left out, joined with commas (run ids hold no comma by rule 8). `run` is used in a command only
after rules 8 and 9; `harness answer` and `queue add` call `state_of` again themselves.

```bash
text=$(cat -- "$tmp/text"; printf x); text=${text%x}   # $(…) would drop trailing newlines; NULs are refused (rule 3)
out=$("$H" answer "$run" "$text" 2>&1); rc=$?
```

```bash
args=(queue add --continue "$run"); [[ -e $tmp/brief ]] && args+=(--brief "$brief")   # $brief read from $tmp/brief as $text is
out=$("$H" "${args[@]}" 2>&1); rc=$?
if (( rc == 0 )); then
  if [[ $window == 1 ]]; then refused=$BACKUP   # the entry stays queued
  else so=$("$H" queue start 2>&1); rc=$?; out+=$'\n'$so
       [[ $so == *"queue runner started (tmux h-queue)"* ]] && started=1; fi
fi
```

`H=$HARNESS_HOME/bin/harness`. `text` and `brief` appear only as quoted argv elements: no `eval`, no `bash -c`, no
`printf %b` or here-string on them. `grep -c 'eval\|bash -c' lib/requests.sh` must print `0`, so not even a comment in
lib/requests.sh may hold those words (write "never through a shell" instead). `queue start` is called whatever the
runner's state: `queue_ensure_runner` (`bin/harness:231`) returns at once, printing nothing, when the runner is up, so
`runner_started` is false then and the card says "queued to start again", which is true.

*Defaults*: no third verb; no batching (each request is its own `harness answer` call, its own result); a `continue`
for a run whose driver is alive is passed to `queue add` as it is today (it waits until the run ends); the backup
window is judged once per request, at `now`, after its `queue add`.

### 2.3 The result and the log line

`node lib/requests.mjs result … --output "$tmp/out" … --log "$R/requests.log" > "$R/done/.$name.json.tmp" && mv -f --
"$R/done/.$name.json.tmp" "$R/done/$name.json"` (written to a temp name in `done/` and renamed, so n8n's poll never reads
half a result; the dot name isn't `*.json` at the top of `requests/`, so it can't trigger the unit). A rejection whose
name already has a result in `done/` writes none (a result is never overwritten). Stdout: each log line as written, then
`requests: <a> done, <b> rejected, <c> waiting` when any file was seen, `requests: none pending (<R>)` when none.
`harness requests` writes nothing to a run's record (the record lock is the driver's): `requests.log` is where it
says what it did, as `runner.log` is the runner's.

### 2.4 The grace on the real clock

With `HARNESS_NOW` set (the suite) a call is one pass. Without it, a pass that left a `wait` file runs again after
`sleep 1`, at most 11 passes in all, so one call outlives a young file's 10 s and rejects it (or processes it, once it
parses) and the path unit isn't restarted in a loop (the intro's item 2). The check below costs about one second.

### 2.5 How the suite sees the runner start

tests/lib.sh exports `HARNESS_NO_RUNNER=1`, which makes `queue_ensure_runner` a silent no-op (no line, no session), so
`runner_started` could never be true. The check **unsets it for that one call and puts gc-tmux.sh's logging `tmux`
shim first on PATH** (`tests/checks/gc-tmux.sh:31`: a script that appends `$*` to `$T/tmux-calls` and exits 0). Then
`queue start` takes its real path: `runner_up` is false (status_stubs leaves no `queue/runner.pid`), the shim answers
`has-session` and `kill-session -t =h-queue`, logs `new-session -d -s h-queue …` and the harness prints `queue runner
started (tmux h-queue)`. The check asserts the result's `runner_started == true`, that line in `output`, and a
`new-session -d -s h-queue` line in `$T/tmux-calls`; at 03:30, no such line and `runner_started == false`.
Rejected: a real runner on the suite's private server (`tmux has-session -t =h-queue`): it would dequeue status_stubs'
`0001-start-proj` / `continue stopped` and start a stub driver that races the file's checks and cleanup; the
`queue runner started` line alone under `HARNESS_NO_RUNNER=1`: never printed.

### 2.6 bin/harness

`requests) shift; exec "$HARNESS_HOME/lib/requests.sh" "$@" ;;` beside `context)`, and in the header after
`harness answer`:

```
#   harness requests                             the request inbox: each <state>/requests/*.json (from n8n), oldest first
#                                                under flock: answer → harness answer, continue → queue add --continue and
#                                                queue start (never 03:15–04:30); a result in requests/done/<id>.json and a
#                                                requests.log line (never the text); anything else to requests/rejected/.
#                                                The systemd path unit runs it (systemd/, README Steering)
```

`bash -n lib/requests.sh bin/harness`.

### 2.7 Checks, written first and watched failing (`tests/checks/request-files.sh`)

The file starts from `status_stubs` (TZ=UTC, `HARNESS_NOW` = 2026-10-28 00:00 UTC; runs `parked` in proj and
`stopped` in proj2 with meta.env; `queue/0002-continue-stopped.args` already queued and requested, so the continue
prints `already queued: continue stopped (replaced by this request)` and rewrites it with the brief). Requests are
built from `tests/fixtures/requests/` with jq; a file is aged with `touch -d @$(( HARNESS_NOW - s ))` where its age
matters (its real mtime is days after the fake now, which reads as young). Every inbox.md under `$HARNESS_STATE` is
hashed before the bad requests and compared after.

1. `harness requests: an answer lands in the run's inbox.md byte for byte, quotes, backticks, a command substitution and newlines included`
   — the request of A3-03 step 1 (`req-0001-aaaa`, `parked`); `cmp` of `proj/parked/inbox.md` with `jq -r .text` of
   the request; and `grep -c 'eval\|bash -c' lib/requests.sh` is 0.
2. `harness requests: an answer's result is ok, its request moves to done/ and requests.log has one line without the text`
   — `done/req-0001-aaaa.json` `ok == true`, `exit == 0`, `verb == "answer"`, its ten keys in order;
   `done/req-0001-aaaa.request.json` is the request (`cmp`); one log line with `id=req-0001-aaaa`, `verb=answer`,
   `run=parked`, ` ok `, and no `rm -rf`; `stat -c %a` of `requests/`, `done/`, `rejected/` all `700`.
3. `harness requests: a continue queues the run requested with its brief and starts the runner` — §2.5;
   `$Q/*-continue-stopped.args` holds `--requested`, `--brief` and the brief line; `runner_started == true`,
   `refused == null`, `queue runner started` in `output`, `new-session -d -s h-queue` in `$T/tmux-calls`.
4. `harness requests: in the backup window a continue is queued and no runner starts` — `HARNESS_NOW` + 12600 s
   (03:30 UTC); the entry is there, no `new-session` line, `runner_started == false`, `ok == true`,
   `refused == "backup window 03:15–04:30: queued, runner not started"` (jq `--arg`, compared in jq).
5. `harness requests: a bad verb, an unknown run, a parent-directory run, 4001 characters and v 2 are rejected with a result each and reach no inbox.md`
   — five files; each in `rejected/`, each `done/<id>.json` `ok == false`, `exit == null`, `refused` the §1.1 string;
   the inbox.md hashes unchanged.
6. `harness requests: a duplicate id goes to rejected/ and the first result stands` — a second file `dup-0001.json`
   with id `req-0001-aaaa`; `done/req-0001-aaaa.json` `cmp`-equal to its copy from before; the file in `rejected/`; a
   `refused` log line with `duplicate id`; inbox.md once.
7. `harness requests: a half-written file younger than 10 s is left alone and rejected once it is 10 s old` —
   `{"v":1,` as `half-0001-aaaa.json`, 2 s old: still there, no result, no log line; the next call with `HARNESS_NOW`
   + 10: in `rejected/`, `done/half-0001-aaaa.json` with `refused` the not-JSON string.
8. `harness requests: on the real clock one call waits out a young file's grace` — `env -u HARNESS_NOW`, the file
   `touch`ed 9 s before the real now: the same call rejects it, in under 5 s.
9. `harness requests: a second call waits on requests/.lock and nothing runs twice` — a stand-in holds the lock
   (`flock "$R/.lock" sleep 2 &`, `# sleep-ok: the holder`), one answer request, two `harness requests` started
   together: both exit 0, both end at least 2 s later, one result, one log line for the id, the text once in inbox.md.
10. `harness requests: requests run oldest first by mtime, then by name` — three answers to `parked`, `c` 30 s old,
    `a` and `b` 20 s old: inbox.md's last three lines are c's, a's, b's texts.
11. `harness requests: a symlink request is rejected unread` — `link-0001-aaaa.json` → a file holding a valid answer:
    the link in `rejected/` (`test -L`), its target untouched, no inbox.md line.

11 names. Done when `bash tests/run.sh request-files queue-view` ends `N/N checks passed`, every name is in both
fixture files, and the fast tier is green.

---

## 3. A3-04 · the units, the decision file, the docs

**Files:** `systemd/harness-requests.path`, `systemd/harness-requests.service` (new), `tests/checks/request-files.sh`
(three more checks), `journal/decisions/2026-10-22-request-inbox.md` (new; the spec's name, as A1's and A2's),
`README.md` (`## Steering`), `docs/architecture.md` (§3, §4, §7, the command list), both check-name fixtures.

### 3.1 The units (verified on this box: systemd 255, `systemd-analyze --user verify` exit 0, nothing written to
`XDG_CONFIG_HOME`; with ExecStart pointing nowhere it exits 1, `Command … is not executable`)

`systemd/harness-requests.path`:

```ini
[Unit]
Description=harness requests: run harness requests when n8n writes a request file

[Path]
PathExistsGlob=%h/.local/state/harness/requests/*.json
Unit=harness-requests.service

[Install]
WantedBy=default.target
```

`systemd/harness-requests.service`:

```ini
[Unit]
Description=harness requests: process the request inbox once

[Service]
Type=oneshot
Environment=PATH=%h/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=%h/projects/agent-harness/bin/harness requests
```

`ExecStart` is the live checkout's `bin/harness` (the one `harness` is). `Environment=PATH=` holds no nvm directory
(`~/.nvm/versions/node/v24.21.0/bin` today), which the next `nvm install` would leave stale: lib/requests.sh finds node
through `nvm.sh` as the debrief does (§2.1 step 1). *Default*; the alternative, node's directory written into the unit
at install, is a drop-in Michael would have to redo per node version.

### 3.2 Checks, written first and watched failing (in `tests/checks/request-files.sh`)

12. `the request units: a path unit on requests/*.json starts a oneshot service running bin/harness requests` —
    `grep -x` of `PathExistsGlob=%h/.local/state/harness/requests/*.json`, `Unit=harness-requests.service`,
    `WantedBy=default.target`, `Type=oneshot`, and an `ExecStart=` line ending in `bin/harness requests`.
13. `the request units pass systemd-analyze --user verify, or the check says it skipped` — both copied to `$T/units/`,
    ExecStart's path rewritten to this checkout's `bin/harness` (`$HERE/../bin/harness`, `realpath`); with
    `command -v systemd-analyze`: exit 0 and no line matching `error` (case-insensitive); without it, the check passes
    and the file prints `skipped: no systemd-analyze` after its PASS line.
14. `harness requests installs nothing: no systemd directory under XDG_CONFIG_HOME` — `XDG_CONFIG_HOME=$T/cfg "$H"
    requests`, then `[[ ! -e $T/cfg/systemd ]]`.

The file holds 14 names in all.

### 3.3 The decision file, `journal/decisions/2026-10-22-request-inbox.md`

Title `# The request inbox: n8n writes request files, a systemd path unit runs harness requests, two verbs`,
provenance (run, A3-02 to A3-04, the spec, this plan), then:

- **Finding**: the spec's (answers only through `harness answer` or an INBOX.md edit; a re-queue never starts the
  runner; n8n can't and mustn't run host commands), and D25's one-write file.
- **Choice**: `<STATE_ROOT>/requests/` mode 700; the two verbs and their argv calls; the validation table (§1.1) with
  its reasons; the result (§1.3) and the log line (§1.4); the claim before the run (at most once); the order; the
  10 s grace and the real-clock wait; the backup window and its refusal; the path unit on `PathExistsGlob=` (and why
  not `DirectoryNotEmpty=`), not the queue runner; the units shipped, never installed. *Default* marks: no third
  verb; no batching; a `continue` for a live run accepted as `queue add` accepts it today; a duplicate keeps the
  first result; `exit: null` on a rejection; an empty brief is none; unknown keys ignored; an existing `requests/`
  keeps its mode; a symlink rejected unread; the unit's PATH without nvm.
- **Rejected**: n8n committing to `INBOX.md` through the GitHub API (a GitHub write token in n8n, and it races the
  driver's own commits); the queue runner as the consumer (it exits when the queue is empty); a third verb;
  `DirectoryNotEmpty=` (always true once `done/` exists: an instant restart loop that fails the path unit); bash
  parsing the request (a `jq` per field, and the text crossing a pipe); a real runner in the suite (§2.5).

### 3.4 The docs

- `README.md`, `## Steering`: a paragraph "Answers from the phone card": n8n writes `requests/<id>.json`; the path
  unit runs `harness requests`; an `answer` becomes `harness answer`, a `continue` `harness queue add --continue`
  then `queue start` (never 03:15–04:30); the result in `requests/done/<id>.json` is what the card shows back
  ("has your answer", "is starting again", "is queued to start again", or "refused: <why>"); `requests.log`. Then the
  install, run once by Michael:
  ```
  harness requests     # makes ~/.local/state/harness/requests (mode 700); prints "requests: none pending (…)"
  systemctl --user link ~/projects/agent-harness/systemd/harness-requests.path ~/projects/agent-harness/systemd/harness-requests.service
  systemctl --user enable --now harness-requests.path
  ```
  and, after a unit file changes in git, `systemctl --user daemon-reload`.
- `docs/architecture.md`: §3 names `lib/requests.sh` and `lib/requests.mjs`; §4 `requests/` (pending `*.json`,
  `done/<id>.json` and `<id>.request.json`, `rejected/`, `requests.log`, `.lock`); §7 Guards the validation (argv only,
  the patterns before any path, at most once, the grace) and the backup window; the command list gains
  `harness requests`.

Done when `bash tests/run.sh request-files` ends `N/N checks passed`, the names are in both fixtures, and the fast tier
is green.

---

## 4. Live steps (build-only: for Michael, A4's checklist `docs/plans/2026-10-22-n8n-events-live.md` carries them)

1. Dry: `harness requests` once (creates `requests/`, prints `none pending`); `ls -ld ~/.local/state/harness/requests`
   shows `drwx------`.
2. One request by hand: write an `answer` for an ended run (`jq` from `tests/fixtures/requests/answer.json`), run
   `harness requests`, read `requests/done/<id>.json` and the run's `inbox.md`.
3. Link and enable the units (§3.4); `systemctl --user status harness-requests.path` is `active (waiting)`.
4. One card answer from n8n; `journalctl --user -u harness-requests.service -n 20`, `requests.log`.
   Undo: `systemctl --user disable --now harness-requests.path harness-requests.service` (`disable` also removes
   the links `link` made, systemctl(1)); the request files stay where they are.

## 5. What A3-05 reads first

The argv calls (§2.2), the patterns before any path (§1.1 rules 5, 8, 9; `resultName`; `free`), the claim and the
`done/` check inside the lock (§2.1 steps 3, 6; §1.5), the grace (rule 1, §2.4), the symlink rule (§2.1 step 4).
