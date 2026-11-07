# The event hook: four kinds go to n8n first, as v1 event JSON, with today's ntfy post as the fallback

*(2026-11-07, A1-02 and A1-03 of run agent-harness-2026-11-07-3; spec `docs/specs/2026-10-22-n8n-events.md` §A1 and its
Contracts (v1, fixed: n8n-home's `docs/specs/2026-10-22-harness-reporter.md` §4.3); plan
`docs/plans/2026-11-07-A1-event-hook.md`. The file keeps the spec's name, which n8n-home cites)*

- **Finding:** `notify` (lib/notify.sh) posted to `NTFY_URL`, or ran `NOTIFY_CMD` when it was unset. Nothing said what
  kind of notification a call was, and nothing could hand one to another service (n8n, which can hold a park until
  Michael answers it and attach the run's context) while keeping ntfy as the net under it.
- **Choice:**
  - `notify` takes `kind=` and `feature=` like its other fields; no `kind=` is `other`. Every call site names its kind
    (the plan's §3.1 table): `notify_park` → `park` (`feature=<id>`); `needs_you` and the merge-refused notification →
    `needs_michael`; the run-end notification → `blocked` when the end reason is one Michael must act on (`lane.mjs
    end-kind`'s `high`: `blocked on`, `waiting on Michael`, `feature-list edits`, `initializer failed`), else `ended`;
    `verified`, `merged`, `started`, `paused`, `limit` (the lane's usage-limit line); the debrief's headline →
    `debrief`; the debrief's failure, the deploy-guard line, the desk's card and `harness continue`'s refusal →
    `other`. `needs_notify` (lib/needs.sh) forwards a caller's `kind=` and `feature=`: the route is the call site's,
    never the needs record's own `kind`.
  - **Only `park`, `needs_michael`, `blocked` and `debrief` are routed**, and only with `EVENT_URL` set. Such a call
    asks `lib/notify.mjs event` for the v1 event (`v id at kind project run feature title body priority click actions
    context`, in that order; `context` null until A2; a debrief has null `project`, `run` and `feature`), keeps it at
    `<STATE_ROOT>/events/<id>/event.json`, and POSTs it once with `Content-Type: application/json`.
  - **A 2xx is received: n8n now owns telling Michael.** `log "event → n8n: <kind> <id>"`, no ntfy post and no
    `NOTIFY_CMD`. Any other answer, a timeout, a curl error or an event node couldn't build →
    `note "event hook failed (<code>|curl exit <n>|no event): <kind>; sent to ntfy"` (`log` where the caller has no
    `note`: the debrief's `$Q/runner.log`), then today's ntfy post or `NOTIFY_CMD`, byte for byte. The event's title,
    body, priority, click and actions are the ntfy post's. `notify` still always returns 0.
  - The code is read from `-w '%{http_code}'` (*default*), not `--fail`'s exit: the note names a `500`, not `curl exit
    22`.
  - The post is **best-effort and synchronous**, capped by `EVENT_TIMEOUT` (5 s, *default*): the bound on how long a
    dead n8n holds the driver before the fallback goes out.
  - **The token is never sent:** nothing in the event post reads `NTFY_TOKEN` (ntfy's), and no `Authorization` header
    is built. Neither line carries `EVENT_URL` (it may hold a webhook secret) nor the body.
  - `EVENT_URL` unset: nothing changes; every check of ntfy's arguments stays as it was.
  - `paused` is not in v1's kind enum; it is never routed, so it never reaches an event.
- **Rejected:**
  - Repointing `NOTIFY_CMD` at n8n: `NTFY_URL` disables `NOTIFY_CMD`, and it has no fallback (a dead n8n would be a lost
    notification).
  - Retries on the event POST: the ntfy fallback is the retry, and each retry would hold the driver another
    `EVENT_TIMEOUT`.
  - Routing every kind: `started`, `merged` and the rest need no answer from Michael; n8n would only forward them, and a
    failed n8n would be one more way to lose them.
  - An `Authorization` header from `NTFY_TOKEN`: a token for one service sent to another.
