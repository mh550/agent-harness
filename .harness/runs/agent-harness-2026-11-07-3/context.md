# Context pack for `A2-03`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (A2-02, affects A2-03, A2-04): glossary.mjs resolveIds takes featureList {path,text} and a reader {root, files()→[{path,mtimeMs,titleOnly}], read()}; fsReader(root,{mtimes}) is the fs one; knownIds(list) feeds findIds → entries.jsonl:7
- Discovery (A2-01, affects A2-04, run): n8n-home's intake refuses a debrief event whose context isn't a string, so A1's debrief event (context null) always falls back to ntfy until A2-04 → entries.jsonl:6
- Discovery (A2-01, affects A2-03): queue-debrief.sh 'the whole context is capped too' asserts <= CMAX bytes: the debrief's glossary gets only the bytes the gatherer left (--max-bytes) → entries.jsonl:6
- Discovery (A1-03, affects A2): event-run.sh's five stub runs plus the debrief take ~35 s; events are read from curl.log (Content-Type: application/json calls) and $HARNESS_STATE/events/*/event.json, filtered by .run → entries.jsonl:4
- Discovery (A1-03, affects A2): A park run with EVENT_URL set posts two events: park, then blocked (its end reason 'waiting on Michael: B' is ehigh); A2-04's context bundle check must select by kind → entries.jsonl:4
- Discovery (A1-01, affects run): features.mjs repair compares the list as JSON, so a jq rewrite of feature_list.json that flips only passes is not an edit. → entries.jsonl:2
- Discovery (init, affects run): A1 ships events with `context: null`; A2-04 wires lib/context.sh's bundle into lib/notify.sh's routed post (the spec's A1 text puts the bundle in A1). → entries.jsonl:1
- Discovery (init, affects run): Decision files take the spec's names (journal/decisions/2026-10-22-<slug>.md, the three §A4 lists), not today's date: the spec and n8n-home cite them so. → entries.jsonl:1
- Discovery (init, affects run): tests/fixtures/n8n-event-v1.json already holds the v1 event JSON (needs-record.sh reads its keys): the event builder's key order is checked against it. → entries.jsonl:1
- Discovery (init, affects run): tests/lib.sh exports HARNESS_NO_RUNNER=1 (queue_ensure_runner a silent no-op): A3-03's runner check unsets it for that call or reads `queue start`'s line. → entries.jsonl:1

## Promote to Gotchas

- Real curl 8.5.0 with -s (no -S) prints nothing on stderr for a 500 or a --max-time timeout; stdout is the -w code ('000' on timeout), exit 28. → entries.jsonl:5
- curl -s (no -S) prints nothing on stderr on error: a timeout is stdout 000 + exit 28 only (agent-harness-2026-11-07-3 2026-11-07) → entries.jsonl:3
- needs_notify (lib/needs.sh) rebuilds notify's fields from the needs record: forward a caller's kind= or it is lost (agent-harness-2026-11-07-3 2026-11-07) → entries.jsonl:1
- lib/debrief.sh has log (runner.log) but no note: notify's failure line lands in $Q/runner.log, not harness-log.md (agent-harness-2026-11-07-3 2026-11-07) → entries.jsonl:1

## What it builds on

- 2026-11-07 17:06 · A2-02 · passes: lib/glossary.mjs: findIds (the list's own ids, then three masking passes), resolveIds (feature list; doc rows and headings newest file first; unresolved never guessed), glossaryMarkdown (byte cap, whole lines), strip, knownIds, fsReader and a CLI; 17 unit tests on fixtures copied read-only from dj-crate-streaming; tests 1814 → 1831.; tests 1814 → 1831; files lib/glossary.mjs, tests/unit/glossary.test.mjs, tests/fixtures/glossary/, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt → entries.jsonl:7

## Lately in the run

- 2026-11-07 16:54 · A2-01 · passes: Wrote docs/plans/2026-11-07-A2-context-bundle.md: glossary rules verbatim and how glossary.mjs applies them, dj fixtures with provenance, the line-by-line move of debrief.sh's gatherer into context.sh, harness context's CLI, context.json's shape, 30-day retention, the hook's bundle before the POST, all checks named with tiers.; tests 1814 → 1814; files docs/plans/2026-11-07-A2-context-bundle.md → entries.jsonl:6
- 2026-11-07 16:40 · verify A1 · passes: A1-01..03 hold. Full suite green at init (690 s, 1814); fast tier 986/986; event-run/event-hook/park-desk/needs-driver/queue-debrief 165/165; event-hook+unit-tier 503/503; notify-body-cap/origin-outage/needs-record 45/45. Mutation: pre-A1 notify turns 7/11 event-hook + 5/6 unit red; pre-A1-03 call sites turn 4/6 event-run red. Real curl 8.5.0 loopback matches the fixtures. → entries.jsonl:5

## Current rules

- The memory curator: itemized operations, a tier the driver derives, a protected list that is fixed → journal/decisions/2026-11-07-memory-tiers.md
- The gate replaces the lint: `memlint-self` retired, `MEMORY_POLICY`, and the curator's acceptance counted → journal/decisions/2026-11-07-memory-policy.md
- One writer for project memory: a coding session's `CLAUDE.md` edit is reverted, a fact goes in the entry → journal/decisions/2026-11-07-memory-one-writer.md
- Supervised efforts for every project: one user-level skill, one dispatch list per effort, plain names throughout → journal/decisions/2026-11-05-supervised-efforts.md
- The suite's shape: check files named for what they test, no name part of another's, two cuts that need no replay, a tier on every line → journal/decisions/2026-11-05-suite-shape.md
- A merge survives an origin outage: bounded retries, a card past them, a tag that isn't claimed, gc holds verified work → journal/decisions/2026-11-04-origin-retries.md
- No run ends on a clock unless asked to: `HOURS` defaults to none, and the night leaves the docs → journal/decisions/2026-11-04-no-default-end-time.md
- A red verify opens a fix round, not a card: at most `MAX_FIX_ROUNDS` per milestone, each one counted → journal/decisions/2026-11-04-fix-rounds.md
- The unit tier: node evals become `node:test` files in one process, reported as the suite's PASS/FAIL lines → journal/decisions/2026-11-03-unit-tier.md
- The trim: 22 checks removed, each with the check that makes its assertions now; five gaps closed; no covered line lost → journal/decisions/2026-11-03-trim.md
- The suite's tiers: every check file declares `fast` or `slow` on line 2, and `tests/run.sh --tier` runs one tier → journal/decisions/2026-11-03-suite-tiers.md
- The trace switch: `HARNESS_XTRACE=<dir>` traces every harness process, off unless set → journal/decisions/2026-11-03-suite-coverage.md

_89 older rules: journal/decisions._
