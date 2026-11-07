# Context pack for `A2-05`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (A2-04, affects A2-05): The event-run check's spy compares context.md beside context.json, not the plan's second `test -f context.json` (the same file twice). → entries.jsonl:9
- Discovery (A2-04, affects A2-05, run): run_context and context_glossary now read <state>/ended before alive: the driver writes ended (driver.sh:352) before its end notify, while still alive. → entries.jsonl:9
- Discovery (A2-04, affects A2-05): The debrief's bundle reruns context_since at notify time, so a run started during the debrief's session is in scope.runs but not in the note's Covers (accepted, review finding 6). → entries.jsonl:9
- Discovery (A2-04, affects A2-05): A glossary exception now costs context.json too (one node call, as the spec says). For the debrief that means a null context, so ntfy (review finding 5, accepted). → entries.jsonl:9
- Discovery (A2-04, affects A2-05, A4): notify_event's ctx is the directory context.sh prints (cd && pwd), so a trailing-slash HARNESS_STATE never gives n8n a // path (its contextPaths guard). → entries.jsonl:9
- Discovery (A2-03, affects A2-04, A2-05): glossaryMarkdown's cut line says 'context.json lists every one', but the debrief's own context dir never gets a context.json: reword it or write one there → entries.jsonl:8
- Discovery (A2-03, affects A2-05): harness context writes $STATE_ROOT/queue/done (an empty dir) when there is no queue yet: cmd_queue mkdirs before list; context-bundle (c) finds files only (! -type d) → entries.jsonl:8
- Discovery (A2-03, affects A2-04, A2-05): status_stubs's run ids A/B/C are matched as the run's own feature ids (knownIds), so a bare English 'A' resolves to feature A in stub glossaries; real ids (N1-01) don't collide → entries.jsonl:8
- Discovery (A2-03, affects A2-05): capped's cut note names $WS/s.json; in a `harness context` bundle that scratch is removed on exit, so the note's path is gone (debrief bytes kept as they were) → entries.jsonl:8
- Discovery (A2-02, affects A2-05): Glossary refinements of the plan: D<n>-<digit> is a feature; a heading names an ID only before end/punctuation/a separator (not `## D24 on`, `## D1 – D23`, `## M8.1`); known ids go first → entries.jsonl:7
- Discovery (A2-01, affects A2-04, run): n8n-home's intake refuses a debrief event whose context isn't a string, so A1's debrief event (context null) always falls back to ntfy until A2-04 → entries.jsonl:6
- Discovery (A1-03, affects A2): event-run.sh's five stub runs plus the debrief take ~35 s; events are read from curl.log (Content-Type: application/json calls) and $HARNESS_STATE/events/*/event.json, filtered by .run → entries.jsonl:4
- Discovery (A1-03, affects A2): A park run with EVENT_URL set posts two events: park, then blocked (its end reason 'waiting on Michael: B' is ehigh); A2-04's context bundle check must select by kind → entries.jsonl:4
- Discovery (A1-01, affects run): features.mjs repair compares the list as JSON, so a jq rewrite of feature_list.json that flips only passes is not an edit. → entries.jsonl:2
- Discovery (init, affects run): A1 ships events with `context: null`; A2-04 wires lib/context.sh's bundle into lib/notify.sh's routed post (the spec's A1 text puts the bundle in A1). → entries.jsonl:1
- Discovery (init, affects run): Decision files take the spec's names (journal/decisions/2026-10-22-<slug>.md, the three §A4 lists), not today's date: the spec and n8n-home cite them so. → entries.jsonl:1
- Discovery (init, affects run): tests/fixtures/n8n-event-v1.json already holds the v1 event JSON (needs-record.sh reads its keys): the event builder's key order is checked against it. → entries.jsonl:1
- Discovery (init, affects run): tests/lib.sh exports HARNESS_NO_RUNNER=1 (queue_ensure_runner a silent no-op): A3-03's runner check unsets it for that call or reads `queue start`'s line. → entries.jsonl:1

## Promote to Gotchas

- A bundle runs the gatherer (harness status/needs/trends/queue): each routed event in a stub run costs ~1 s more; event-run.sh takes 39 s → entries.jsonl:9
- bash: an apostrophe in a ${v:-default} inside a double-quoted string fails to parse in a function body; put the default in a variable (agent-harness-2026-11-07-3 2026-11-07) → entries.jsonl:8
- Real curl 8.5.0 with -s (no -S) prints nothing on stderr for a 500 or a --max-time timeout; stdout is the -w code ('000' on timeout), exit 28. → entries.jsonl:5
- curl -s (no -S) prints nothing on stderr on error: a timeout is stdout 000 + exit 28 only (agent-harness-2026-11-07-3 2026-11-07) → entries.jsonl:3
- needs_notify (lib/needs.sh) rebuilds notify's fields from the needs record: forward a caller's kind= or it is lost (agent-harness-2026-11-07-3 2026-11-07) → entries.jsonl:1
- lib/debrief.sh has log (runner.log) but no note: notify's failure line lands in $Q/runner.log, not harness-log.md (agent-harn… → entries.jsonl:1

## What it builds on

- 2026-11-07 17:06 · A2-02 · passes: lib/glossary.mjs: findIds (the list's own ids, then three masking passes), resolveIds (feature list; doc rows and headings newest file first; unresolved never guessed), glossaryMarkdown (byte cap, whole lines), strip, knownIds, fsReader and a CLI; 17 unit tests on fixtures copied read-only from dj-crate-streaming; tests 1814 → 1831.; tests 1814 → 1831; files lib/glossary.mjs, tests/unit/glossary.test.mjs, tests/fixtures/glossary/, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt → entries.jsonl:7
- 2026-11-07 17:33 · A2-03 · passes: Moved the debrief's gatherer verbatim into lib/context.sh (context_since, context_runs, context_glossary); debrief.sh sources it, no copy. New `harness context <run> | --since <ts> [--out] [--id]` writes context.md (gatherer + ## Glossary via new lib/context.mjs) to events/<uuid>/ by default. The debrief's context gains the glossary. Tests 1831 → 1839.; tests 1831 → 1839; files lib/context.sh, lib/context.mjs, lib/debrief.sh, bin/harness, tests/checks/context-bundle.sh, … → entries.jsonl:8
- 2026-11-07 18:05 · A2-04 · passes: context.json (spec key order) now comes from the same lib/context.mjs call as context.md; a bundle written in events/ prunes bundles with no file newer than 30 days and says so; notify_event writes the bundle to events/<id>/ before the POST, so context names an existing context.json; the debrief passes since=$SINCE. A failed bundle: a note, context null. Decision file, docs.; tests 1839 → 1853; files lib/context.mjs, lib/context.sh, lib/notify.sh, lib/notify.mjs, lib/debrief.sh, … → entries.jsonl:9

## Current rules

- The memory curator: itemized operations, a tier the driver derives, a protected list that is fixed → journal/decisions/2026-11-07-memory-tiers.md
- The gate replaces the lint: `memlint-self` retired, `MEMORY_POLICY`, and the curator's acceptance counted → journal/decisions/2026-11-07-memory-policy.md
- One writer for project memory: a coding session's `CLAUDE.md` edit is reverted, a fact goes in the entry → journal/decisions/2026-11-07-memory-one-writer.md
- Supervised efforts for every project: one user-level skill, one dispatch list per effort, plain names throughout → journal/decisions/2026-11-05-supervised-efforts.md
- The suite's shape: check files named for what they test, no name part of another's, two cuts that need no replay, a tier on every line → journal/decisions/2026-11-05-suite-shape.md
- A merge survives an origin outage: bounded retries, a card past them, a tag that isn't claimed, gc holds verified work → journal/decisions/2026-11-04-origin-retries.md
- No run ends on a clock unless asked to: `HOURS` defaults to none, and the night leaves the docs → journal/decisions/2026-11-04-no-default-end-time.md

_95 older rules: journal/decisions._
