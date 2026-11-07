<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-07-3` (agent-harness)

What this file is: the run's journal, rendered by the harness from `entries.jsonl`, newest entry first (the 15 newest in full; every entry is in `progress-archive.md`). Each entry is one session: its feature, outcome, summary, what it tried, what it found.

The run builds A1–A4 of `docs/specs/2026-10-22-n8n-events.md`, four milestones in series: **A1** `notify` learns `kind=`/`feature=` and, with `EVENT_URL` set, POSTs a v1 event for park, needs_michael, blocked and debrief through the stub curl, ntfy as the fallback; **A2** the debrief's gatherer moves into `lib/context.sh`, `harness context` writes a bundle (context.md with an ID glossary by `lib/glossary.mjs`, context.json) that a routed event points at; **A3** `harness requests` turns n8n's request files (`answer`, `continue`) into `harness answer` and `harness queue add --continue`, under a systemd path unit Michael installs; **A4** the docs and the live checklist. Inert unless `EVENT_URL` or the request inbox is configured; never a real HTTP request.

How to read the feature list: `feature_list.json` is in priority order; a feature runs when it isn't passing and its `after` all pass. Each milestone's plan feature writes `docs/plans/2026-11-07-A<n>-….md`; A2 and A3 end in a review feature, A1's review is folded into A1-03, A4 is one docs feature. When every feature of a milestone passes the harness verifies it and merges it into `main` (`MERGE_POLICY=auto`).

How to steer: edit `INBOX.md` in this directory from the phone or `harness answer`. A line `status: stop <why>` or `status: pause` on top stops or pauses the run; answers to questions go under `## Answers`; a brief under the steering comment changes scope for the next session. Open questions are listed under the entries that asked them and in `harness needs`.

### 2026-11-07 15:53 · init · passes

14 features: A1 3 (plan, event builder + routed post, call sites with folded review), A2 5 (plan, lib/glossary.mjs, lib/context.sh + harness context, context.json + retention + hook bundle, review), A3 5 (plan, lib/requests.mjs, harness requests, systemd units + docs, review), A4 1 (docs, sonnet). In series: A2 after A1, A3 after A2, A4 after A3. No check budget (the spec sets none).

- **Discovery** (affects run): A1 ships events with `context: null`; A2-04 wires lib/context.sh's bundle into lib/notify.sh's routed post (the spec's A1 text puts the bundle in A1).
- **Discovery** (affects run): Decision files take the spec's names (journal/decisions/2026-10-22-<slug>.md, the three §A4 lists), not today's date: the spec and n8n-home cite them so.
- **Discovery** (affects run): tests/fixtures/n8n-event-v1.json already holds the v1 event JSON (needs-record.sh reads its keys): the event builder's key order is checked against it.
- **Discovery** (affects run): tests/lib.sh exports HARNESS_NO_RUNNER=1 (queue_ensure_runner a silent no-op): A3-03's runner check unsets it for that call or reads `queue start`'s line.
- **Discovery** (affects project): needs_notify (lib/needs.sh) rebuilds notify's fields from the needs record: forward a caller's kind= or it is lost (agent-harness-2026-11-07-3 2026-11-07)
- **Discovery** (affects project): lib/debrief.sh has log (runner.log) but no note: notify's failure line lands in $Q/runner.log, not harness-log.md (agent-harness-2026-11-07-3 2026-11-07)
- *00-init · claude-fable-5-1*
