# A1 · Event hook with an ntfy fallback (plan, 2026-11-07)

Run `agent-harness-2026-11-07-3`, feature A1-01. Spec: `docs/specs/2026-10-22-n8n-events.md` §A1 and its Contracts
(v1, fixed: n8n-home is live against them, its `docs/specs/2026-10-22-harness-reporter.md` §4.3). Read against `main`
at 8e05980 (after lanes, the driver CLI and the memory curator), so every line reference below is today's.

**In one paragraph.** `notify` (lib/notify.sh) learns two more `key=value` fields, `kind=` and `feature=`. When
`EVENT_URL` is set and the kind is one of the four routed kinds (`park`, `needs_michael`, `blocked`, `debrief`), it
asks `lib/notify.mjs event` for the v1 event JSON, keeps it at `<STATE_ROOT>/events/<id>/event.json`, and POSTs it
once through `${HARNESS_CURL:-curl}`. A 2xx ends there (n8n tells Michael); any other outcome is noted and the ntfy
(or `NOTIFY_CMD`) branch runs exactly as today. `EVENT_URL` unset, or any other kind: nothing changes, byte for byte.
`notify` still always returns 0. `context` stays `null` in A1: A2-04 wires lib/context.sh's bundle in.

## 1. The event JSON (v1)

Exactly tests/fixtures/n8n-event-v1.json's keys, in its order (`jq -r 'keys_unsorted|join(" ")'` on the fixture
prints `v id at kind project run feature title body priority click actions context`, which
tests/checks/needs-record.sh already pins):

| Key | Filled by | Value |
|---|---|---|
| `v` | node | `1` |
| `id` | node | `crypto.randomUUID()` (matches `^[0-9a-f-]{36}$`) |
| `at` | node | `new Date().toISOString()` (ISO 8601, UTC, ms) |
| `kind` | bash, the `kind=` field | one of v1's enum; `event` refuses any other (exit 2, prints nothing) |
| `project` | bash, `${PROJECT_NAME:-}` (lib/prompt.sh's `prompt_vars`: the project directory's name, the state dir's `<project>`) | string; empty → `null` |
| `run` | bash, `${RUN_ID:-}` | string; empty → `null` |
| `feature` | bash, the `feature=` field | string, or `null` when empty/absent |
| `title` | the ntfy `Title:` value (`title=`, default `harness`) | string |
| `body` | the ntfy data: `${body:-$(notify_trim "$msg")}`, i.e. the trimmed body or, with none, the tagged message | string (before the ` @` guard, which is a curl-argument quirk, not content) |
| `priority` | the ntfy `Priority:` value | `"high"` or `""` (empty stays `""`, never null) |
| `click` | the ntfy `Click:` value | string; empty → `null` |
| `actions` | the ntfy `Actions:` value | string; empty → `null` |
| `context` | A2 | `null` in A1 (an empty `context=` → `null`) |

The `debrief` kind gives `null` `project`, `run` and `feature` whatever it is passed (the contract: a debrief covers
many runs). `tags` is not in v1 and is not sent (n8n's fallback alert is the plain one).

`lib/needs.mjs` `record()` already builds needs items whose first 13 keys are these; the event is built by its own
pure function (`buildEvent`) because its title/body/priority are the ones *this* post carries (a caller's or the
needs record's, already resolved by `needs_notify`), not the record's card; the two share only the key order, which
the unit test pins against the fixture.

## 2. A1-02 · the event builder (lib/notify.mjs) and the routed post (lib/notify.sh)

### 2.1 lib/notify.mjs

- `export const ROUTED = ["park", "needs_michael", "blocked", "debrief"]` and `export const KINDS` (v1's ten:
  `park needs_michael blocked ended debrief verified merged started limit other`). `paused` is not in v1's enum; it is
  never routed, so it never reaches an event (noted in the decision file).
- `export function buildEvent(f, now = new Date(), uuid = randomUUID)` → the object of §1 (pure given `now`/`uuid`;
  throws on a kind outside `KINDS`).
- CLI: `node lib/notify.mjs event kind=… run=… project=… feature=… title=… body=… priority=… click=… actions=…
  [context=…]` → `JSON.stringify(buildEvent(…))` on one line (no indentation: one argv word, one line in the stub's
  log), exit 0; a kind outside v1 → nothing printed, exit 2. Arguments split at the first `=`. The usage header gains
  the line. Goes through `ask notify.mjs event …` (lib/record.sh's helper in a driver/lane, a spawn elsewhere).

### 2.2 lib/notify.sh

`notify`'s field loop gains `kind) kind=$v ;; feature) feature=$v ;;` (no kind → `other`; control bytes stripped as
for every field but `body`). After the body trim, before today's `if [[ -n ${NTFY_URL:-} ]]`:

```bash
data=${body:-$(notify_trim "$msg")}   # what ntfy's data is; the ntfy branch's v= uses it, unchanged
if [[ -n ${EVENT_URL:-} ]] && case $kind in park|needs_michael|blocked|debrief) true ;; *) false ;; esac; then
  notify_event && return 0      # 2xx: n8n owns telling Michael
fi
```

`notify_event` (a function in lib/notify.sh, reading notify's locals):

1. `ev=$(ask notify.mjs event kind="$kind" run="${RUN_ID:-}" project="${PROJECT_NAME:-}" feature="$feature"
   title="$title" body="$data" priority="$priority" click="$click" actions="$actions" 2> /dev/null 8>&- 9>&-)`.
   No JSON is written in bash. `id=$(jq -r '.id // empty' <<< "$ev" 2> /dev/null)`.
   **Safe branch** (the `ask` gotcha: helper and spawn can both fail): empty `ev` or `id` →
   `event hook failed (no event): <kind>; sent to ntfy`, return 1.
2. Keep it: `d=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness}/events/$id`;
   `mkdir -p "$d" && printf '%s\n' "$ev" > "$d/event.json"` (the posted bytes plus one newline). A failed write does
   not stop the POST (best effort; it is a record, not the delivery). Retention is A2's (30 days, spec §A2).
3. The POST, verbatim:

   ```bash
   code=$("${HARNESS_CURL:-curl}" -s -o /dev/null -w '%{http_code}' --max-time "$EVENT_TIMEOUT" \
     -H "Content-Type: application/json" --data-binary "$ev" "$EVENT_URL" < /dev/null 2> /dev/null 8>&- 9>&-); rc=$?
   ```

   No `--retry`, no `--fail`, never an `Authorization` header (NTFY_TOKEN is ntfy's; nothing in notify_event reads
   it). **The HTTP code is read from `-w '%{http_code}'`** (the plan's choice over `--fail`'s exit: it names the code
   in the note, a `500` rather than `curl exit 22`). Received ⇔ `rc == 0` and `code` matches `^2[0-9][0-9]$`.
4. The two lines, verbatim (neither carries `EVENT_URL`, which may hold a webhook secret, nor the body):
   - received: `log "event → n8n: <kind> <id>"`, return 0 (no ntfy post, no `NOTIFY_CMD`);
   - otherwise the reason is `curl exit <rc>` when `rc != 0`, else the code (`500`, `302`, `000`):
     `event hook failed (<reason>): <kind>; sent to ntfy` by `note` when the caller has one (`declare -F note`), else by
     `log` (lib/debrief.sh: `log` tees to `$Q/runner.log`, it has no `note`), return 1, and today's branch runs.

Real curl 8.5.0 on this box, against a loopback listener (node `http` on 127.0.0.1:7829, the session's port; no
request left the machine), with the exact flags above and `--max-time 1`:

| Answer | exit | stdout (`-w`) | stderr |
|---|---|---|---|
| 200 | 0 | `200` | (none) |
| 500 | 0 | `500` | (none: no `--fail`) |
| no answer | 28 | `000` | `curl: (28) Operation timed out after 1002 milliseconds with 0 bytes received` |

So the 500 note is `event hook failed (500): park; sent to ntfy` and the timeout's
`event hook failed (curl exit 28): park; sent to ntfy`.

The usage header names the two fields and the routing (one added line: "kind= park|needs_michael|blocked|debrief
with EVENT_URL set go to EVENT_URL as v1 event JSON first; ntfy/NOTIFY_CMD only when that isn't a 2xx").

### 2.3 Config

- lib/config.sh `harness_config`, beside `NTFY_URL`: `EVENT_URL="" EVENT_TIMEOUT=5   # EVENT_URL set: park,
  needs_michael, blocked and debrief go to n8n first, ntfy only when it doesn't take them`.
- templates/user/config.sh under the Notifications lines: `# EVENT_URL=http://127.0.0.1:5678/webhook/harness-event   #
  park, needs-you, blocked and debrief notifications go here first (v1 event JSON); ntfy/NOTIFY_CMD when it fails` and
  `# EVENT_TIMEOUT=5   # seconds a dead n8n may hold the driver, then the ntfy fallback`.
- lib/eval.sh sets `HARNESS_CURL=${HARNESS_EVAL_CURL:-false}`: an eval config with `EVENT_URL` would get exit 1 and fall
  back; nothing to change.

### 2.4 tests/stub-curl.sh

A call is the event POST when one of its arguments is exactly `Content-Type: application/json` (no ntfy call carries
it: notify's headers are Title, Priority, Tags, Click, Actions, Authorization). The stub records every call first, as
today. Then, for the event POST only, the knob **`STUB_EVENT`**: unset or `200` → prints
`tests/fixtures/curl-event-200.out`'s bytes, exit 0; `500` → `curl-event-500.out`, exit 0; `timeout` →
`curl-event-timeout.out` on stdout, `curl-event-timeout.err` on stderr, exit 28, no sleep. The four fixture files are
the stdout/stderr of the runs in §2.2's table (the timeout's line copied as curl printed it), named in the stub's
header with the knob. `STUB_CURL_FAIL=1` keeps today's path and only applies to non-event calls (so a check can fail
ntfy and the event independently). `STUB_CURL_SPY` runs for both.

### 2.5 Checks A1-02 writes first (watched failing)

**tests/unit/notify.test.mjs** (unit tier, which is `fast`; flat `test()` calls; names in check-names.txt and
check-names-fast.txt, LC_ALL=C sorted):

- `notify.mjs event: buildEvent's keys are the v1 fixture's, in order` (`Object.keys(e).join(" ")` against the
  fixture's, a string compare, never `deepEqual`)
- `notify.mjs event: v is 1, id a uuid, at an ISO time`
- `notify.mjs event: an empty click, actions or context is null, an empty priority stays ""`
- `notify.mjs event: a debrief has null project, run and feature`
- `notify.mjs event: the CLI prints buildEvent's JSON on one line` (`node lib/notify.mjs event kind=park run=r1
  project=p feature=B title=t body=b priority=high click= actions=`; parsed, fields compared, `id`/`at` by shape)
- `notify.mjs event: a kind outside v1 prints nothing and exits 2`

**tests/checks/event-hook.sh** (line 2 `# tier: fast`: no stub runs, a few sourced `notify` calls, well under 30 s;
timed once by `TEST_JOBS=4 bash tests/run.sh event-hook` per the suite-tiers rule). Each case runs
`( NTFY_URL=https://ntfy.example/t NTFY_TOKEN=tok-secret-123 NOTIFY_CMD=…; log() { echo "$*" >> $T/eh-log; };
note() { echo "$*" >> $T/eh-note; }; source "$HERE/../lib/notify.sh"; notify … )` as notify-body-cap.sh does, with
`$T/curl.log` moved aside between cases (each case's record in `$T/eh-<case>.log`). A fixed field set for every case:
`notify "needs Michael: B · x" title="[r1] B needs you" body="PARKED: x" priority=high click=https://e.test/c
actions="view, Edit, https://e.test/e" kind=park feature=B` (RUN_ID=r1 PROJECT_NAME=proj).

- `event hook: EVENT_URL unset, a park goes to ntfy alone` (a)
- `event hook: a received park is one POST to EVENT_URL, v1 JSON, no token` (b: one call, last arg EVENT_URL,
  `Content-Type: application/json` among its args, body `jq -e '.v == 1 and .kind == "park" and .feature == "B"'`, no
  `Authorization` arg, `grep -c tok-secret-123 $T/curl.log` 0, no call to the ntfy URL, `grep -F "event → n8n: park
  <id>"` in the log file)
- `event hook: a 500 falls back to the same ntfy post, and notes it` (c: the POST, then an ntfy call `diff`-equal to
  (a)'s, note `event hook failed (500): park; sent to ntfy`)
- `event hook: a timeout falls back to the same ntfy post, and notes curl's exit` (d: `(curl exit 28)`)
- `event hook: a kind that isn't routed goes to ntfy alone with EVENT_URL set` (e: kind=ended, (a)'s record)
- `event hook: no kind is other, ntfy alone` (f)
- `event hook: notify returns 0 received, refused and timed out` (g)
- `event hook: the received event is kept under events/<id>/` (h: `$(cat $HARNESS_STATE/events/<id>/event.json)` ==
  the posted body)
- `event hook: the fallback event carries ntfy's title, body, click, actions and priority` (i)
- `event hook: NOTIFY_CMD is not called for a received event, and is for a refused one` (j: NTFY_URL unset; the
  feature's "without any ntfy or NOTIFY_CMD call")
- `event hook: an event node can't build is noted and sent to ntfy` (k: `ask() { return 1; }` declared before
  sourcing; note `event hook failed (no event): park; sent to ntfy`, (a)'s record)

Also run at A1-02's end: `bash tests/run.sh notify-body-cap origin-outage needs-record` green (the stub's
`STUB_CURL_FAIL` path unchanged) and `bash tests/run.sh event-hook unit-tier`.

## 3. A1-03 · the call sites, the decision file, the docs, the review

### 3.1 Every `notify` call and its kind

| Call site (today's line) | Notification | kind | feature |
|---|---|---|---|
| lib/record.sh:572 `notify_park` → `needs_notify` | `[<run>] <id> needs you` | `park` | `$id` |
| lib/record.sh:552 `needs_you` → `needs_notify` (callers: lane.sh:273, lane.sh:337, record.sh:521, :999, :1080) | `[<run>] <m> needs you` | `needs_michael` | — |
| lib/record.sh:1011 `merge_refused_` → `needs_notify` | `[<run>] <m> needs you` (merge refused) | `needs_michael` | — |
| lib/driver.sh:386 run end | `[<run>] ended: <reason>` | `blocked` when `ehigh` is 1 (lane.mjs `end-kind`), else `ended` | — |
| lib/driver.sh:563 | `started: …` | `started` | — |
| lib/driver.sh:598 | `paused` | `paused` | — |
| lib/driver.sh:518 | `no deploy guard (…)` | `other` | — |
| lib/record.sh:1101 | `[<run>] <m> ready to merge` | `verified` | — |
| lib/record.sh:1106 | `<m> merged · <url>` | `merged` | — |
| lib/lane.sh:478 | `refused (<reason>); waiting until …` | `limit` | — |
| lib/debrief.sh:343 headline | `harness debrief` | `debrief` | — |
| lib/debrief.sh:35 `fail()` | `[debrief] failed: …` | `other` | — |
| lib/desk.sh:150 `tell` | `[<run>] needs you: …` (the desk's own card; the park it follows was already routed) | `other` (the spec's "desk") | — |
| bin/harness:268 continue refused | `[<run>] continue refused: a pre-lanes run` | `other` (Michael is at the terminal; not in the spec's table) | — |

`ehigh` is set at lib/driver.sh:357 from `ask lane.mjs end-kind "$1"` (1 for the reasons Michael must act on: `blocked
on`, `waiting on Michael`, `feature-list edits`, `initializer failed`; also 1 when `end-kind` gives no answer). The run-end call becomes
`notify … kind="$([[ $ehigh == 1 ]] && echo blocked || echo ended)"` (or a local set beside `pri`).

**`needs_notify` (lib/needs.sh:20) needs no change:** both its branches call `notify "$msg" "$@" …`, so a caller's
`kind=` and `feature=` reach `notify`; the record's five fields come after "$@" and override only title, body, click,
priority and actions. The stub-run checks (park via `notify_park`, needs_michael via `needs_you`) prove it end to end;
a refactor that drops "$@" turns them red. The needs record's own `kind` (needs.mjs REASONS) is the card's
classification and is not read: the route is the call site's.

### 3.2 Checks A1-03 writes first: tests/checks/event-run.sh (line 2 `# tier: slow`: stub runs)

The base config plus `EVENT_URL=https://n8n.example/webhook/harness-event` appended to `$T/user-config.sh` for the
routed runs; runs and their ids follow park-desk.sh's park knob (`STUB_PARK=B STUB_NO_TAMPER=1 STUB_NO_RED=1
STUB_LENIENT=1`) and needs-driver.sh's given-up run; events are read from `curl.log` (`curl_with`
"Content-Type: application/json") and `$HARNESS_STATE/events/*/event.json`.

- `event run: a park posts one park event with its feature, run, project and title, and no ntfy` (A1-03 step 1;
  **counts park events, not POSTs**: a park run ends "waiting on Michael: B", which is `ehigh`, so it also posts a
  `blocked` event at its end)
- `event run: a park the hook refuses reaches ntfy with the event's fields, noted` (500 run; field-by-field)
- `event run: with EVENT_URL unset a park's ntfy post is the fallback's` (the third run; records diffed with
  timestamps and the run id normalised)
- `event run: a blocked run end posts a blocked event, feature null`
- `event run: started and a done run's end reach ntfy alone`
- `event run: the debrief posts a debrief event with null project, run and feature` (run as queue-debrief.sh runs
  `harness debrief`, stub claude; `$Q/runner.log` holds `event → n8n: debrief <id>`)

Every name goes in tests/fixtures/check-names.txt (LC_ALL=C sorted), not the fast list (slow file).

### 3.3 Decision file and docs

- `journal/decisions/2026-10-22-event-hook-ntfy-fallback.md` (the spec's name, cited by n8n-home): finding · choice ·
  rejected as A1-03 step 5 lists; *default*: the synchronous best-effort POST and its 5 s cap; `-w '%{http_code}'`
  over `--fail`; desk and continue-refused as `other`; `paused` outside v1 and never routed.
- docs/architecture.md: §3 Components (the hook in lib/notify.sh, lib/notify.mjs `event`), §4 Where state lives
  (`<STATE_ROOT>/events/<id>/event.json`), §7 Guards (the fallback, the token never sent, the URL never logged),
  §10 Configuration (`EVENT_URL`, `EVENT_TIMEOUT`). README.md `## Steering`: the EVENT_URL paragraph.

### 3.4 The review

`git diff $(git merge-base HEAD origin/main) -- lib bin tests templates > $HARNESS_SCRATCH/A1.diff`, one Opus round:
no kind on the wrong route, the ntfy arguments unchanged with EVENT_URL unset, NTFY_TOKEN unable to reach an event
POST. Findings and what was done → `docs/plans/2026-11-07-A1-review.md`.

## 4. Existing checks the new fields or knobs could touch

`grep -ln 'curl_\|notify-cmd' tests/checks/*.sh`: the base config (tests/lib.sh:41) sets no `EVENT_URL`, the new
stub branch fires only on a `Content-Type: application/json` argument, and `STUB_CURL_FAIL=1` keeps its path for
ntfy calls, so every one **stays**:

| File | Assertions | Verdict |
|---|---|---|
| tests/checks/claim-reverted.sh | the ready-to-merge post's click/priority | stays |
| tests/checks/fix-rounds.sh | `curl_count "[fx*] M1 needs you"` | stays |
| tests/checks/lanes-continue.sh | continue-refused priority; `[pm] M2 ready to merge` | stays |
| tests/checks/needs-driver.sh | park post's body/headers; `ended: blocked on A`; `ended: usage limit …` | stays |
| tests/checks/needs-questions.sh | no question text in curl.log | stays |
| tests/checks/notify-body-cap.sh | the trimmed body | stays |
| tests/checks/origin-outage.sh | `M1 needs you` / `ended:` / `merged` counts; `STUB_CURL_FAIL`-free | stays |
| tests/checks/park-desk.sh | headers, priorities, clicks, actions, desk card; `STUB_CURL_FAIL=1` run `parkl`; `STUB_CURL_SPY` | stays |
| tests/checks/queue-debrief.sh | debrief headline/failure posts; `STUB_CURL_FAIL=1` run `gated` | stays |
| tests/checks/run-scopes-services-gc.sh | started/merged headers; deploy-guard counts | stays |
| tests/checks/stop-records.sh | started/merged headers | stays |

No check is replaced: the new ones assert the event route, which nothing asserts today. (b)'s "no token in curl.log"
holds only in event-hook.sh's own log (each case's record apart): a whole-run curl.log carries the token on every
ntfy call by design.

## 5. Not in A1

The context bundle and `context` path (A2-04), events/ retention (A2), the request inbox (A3), README's
Notifications section and the live checklist (A4). Nothing under `~/.config`, `/srv` or `~/.claude`; no real request.
