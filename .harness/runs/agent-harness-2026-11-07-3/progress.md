<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-07-3` (agent-harness)

What this file is: the run's journal, rendered by the harness from `entries.jsonl`, newest entry first (the 15 newest in full; every entry is in `progress-archive.md`). Each entry is one session: its feature, outcome, summary, what it tried, what it found.

The run builds A1–A4 of `docs/specs/2026-10-22-n8n-events.md`, four milestones in series: **A1** `notify` learns `kind=`/`feature=` and, with `EVENT_URL` set, POSTs a v1 event for park, needs_michael, blocked and debrief through the stub curl, ntfy as the fallback; **A2** the debrief's gatherer moves into `lib/context.sh`, `harness context` writes a bundle (context.md with an ID glossary by `lib/glossary.mjs`, context.json) that a routed event points at; **A3** `harness requests` turns n8n's request files (`answer`, `continue`) into `harness answer` and `harness queue add --continue`, under a systemd path unit Michael installs; **A4** the docs and the live checklist. Inert unless `EVENT_URL` or the request inbox is configured; never a real HTTP request.

How to read the feature list: `feature_list.json` is in priority order; a feature runs when it isn't passing and its `after` all pass. Each milestone's plan feature writes `docs/plans/2026-11-07-A<n>-….md`; A2 and A3 end in a review feature, A1's review is folded into A1-03, A4 is one docs feature. When every feature of a milestone passes the harness verifies it and merges it into `main` (`MERGE_POLICY=auto`).

How to steer: edit `INBOX.md` in this directory from the phone or `harness answer`. A line `status: stop <why>` or `status: pause` on top stops or pauses the run; answers to questions go under `## Answers`; a brief under the steering comment changes scope for the next session. Open questions are listed under the entries that asked them and in `harness needs`.

### 2026-11-07 15:59 · A1-01 · passes

Wrote docs/plans/2026-11-07-A1-event-hook.md: the v1 event keys and who fills each, the POST verbatim (-w '%{http_code}', no --fail/--retry/token), the two log lines, stub-curl's STUB_EVENT knob with fixtures from real curl 8.5.0 on loopback, every notify call mapped to its kind, 11 existing curl checks (all stay) and the 23 new check names with tiers.

- **Files:** docs/plans/2026-11-07-A1-event-hook.md
- **Verified:** fast tier green (check.sh --fast: cached for this code tree, 1791 tests; docs/plans is outside the key); plan's line refs re-read against main 8e05980; curl outputs captured from a node listener on 127.0.0.1:7829
- **Tests:** 1791 → 1791
- **Discovery** (affects A1-03): A park run ends 'waiting on Michael: B' (ehigh 1), so with EVENT_URL set it posts a park event AND a blocked run-end event: event-run's park check must count park events, not POSTs.
- **Discovery** (affects A1-03): needs_notify already forwards a caller's kind=/feature= (both branches call notify "$msg" "$@" before the record's 5 fields): no change to lib/needs.sh in A1.
- **Discovery** (affects A1-02): Real curl 8.5.0, -s -o /dev/null -w '%{http_code}': 500 → stdout 500 exit 0 no stderr; timeout → stdout 000, exit 28, 'curl: (28) Operation timed out after N milliseconds with 0 bytes received'.
- **Discovery** (affects run): features.mjs repair compares the list as JSON, so a jq rewrite of feature_list.json that flips only passes is not an edit.
- **Proposed change:** A1-03 step 1: 'posts exactly one event to EVENT_URL with kind == park' should read 'exactly one park event': the park run's end (waiting on Michael) also posts a blocked event.
- **Proposed change:** A1-02 step 2 could add (j) NOTIFY_CMD not called on a 2xx and called on a refusal, and (k) an event node can't build falls back to ntfy (the ask gotcha): the plan names both.
- *01-A1-01 · claude-opus-5-5*

### 2026-11-07 15:53 · init · passes

14 features: A1 3 (plan, event builder + routed post, call sites with folded review), A2 5 (plan, lib/glossary.mjs, lib/context.sh + harness context, context.json + retention + hook bundle, review), A3 5 (plan, lib/requests.mjs, harness requests, systemd units + docs, review), A4 1 (docs, sonnet). In series: A2 after A1, A3 after A2, A4 after A3. No check budget (the spec sets none).

- **Discovery** (affects run): A1 ships events with `context: null`; A2-04 wires lib/context.sh's bundle into lib/notify.sh's routed post (the spec's A1 text puts the bundle in A1).
- **Discovery** (affects run): Decision files take the spec's names (journal/decisions/2026-10-22-<slug>.md, the three §A4 lists), not today's date: the spec and n8n-home cite them so.
- **Discovery** (affects run): tests/fixtures/n8n-event-v1.json already holds the v1 event JSON (needs-record.sh reads its keys): the event builder's key order is checked against it.
- **Discovery** (affects run): tests/lib.sh exports HARNESS_NO_RUNNER=1 (queue_ensure_runner a silent no-op): A3-03's runner check unsets it for that call or reads `queue start`'s line.
- **Discovery** (affects project): needs_notify (lib/needs.sh) rebuilds notify's fields from the needs record: forward a caller's kind= or it is lost (agent-harness-2026-11-07-3 2026-11-07)
- **Discovery** (affects project): lib/debrief.sh has log (runner.log) but no note: notify's failure line lands in $Q/runner.log, not harness-log.md (agent-harness-2026-11-07-3 2026-11-07)
- *00-init · claude-fable-5-1*
