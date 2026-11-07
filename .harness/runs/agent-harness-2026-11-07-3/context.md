# Context pack for `A3-01`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (A2-05, affects A3, A4): The debrief's bundle is its own gather's (context.json in its workspace, copied by context.sh --from); notify's since= is gone, bundle=<dir> replaces it → entries.jsonl:10
- Discovery (A2-05, affects A3, A4): lib/context.sh ended_of: alive first (the debrief's bytes); CTX_ENDED_FIRST=1 (harness context only) reads ended first for the end event's bundle → entries.jsonl:10
- Discovery (A2-04, affects A2-05, run): run_context and context_glossary now read <state>/ended before alive: the driver writes ended (driver.sh:352) before its end notify, while still alive. → entries.jsonl:9
- Discovery (A2-01, affects A2-04, run): n8n-home's intake refuses a debrief event whose context isn't a string, so A1's debrief event (context null) always falls back to ntfy until A2-04 → entries.jsonl:6
- Discovery (A1-01, affects run): features.mjs repair compares the list as JSON, so a jq rewrite of feature_list.json that flips only passes is not an edit. → entries.jsonl:2
- Discovery (init, affects run): A1 ships events with `context: null`; A2-04 wires lib/context.sh's bundle into lib/notify.sh's routed post (the spec's A1 text puts the bundle in A1). → entries.jsonl:1
- Discovery (init, affects run): Decision files take the spec's names (journal/decisions/2026-10-22-<slug>.md, the three §A4 lists), not today's date: the spec and n8n-home cite them so. → entries.jsonl:1
- Discovery (init, affects run): tests/fixtures/n8n-event-v1.json already holds the v1 event JSON (needs-record.sh reads its keys): the event builder's key order is checked against it. → entries.jsonl:1
- Discovery (init, affects run): tests/lib.sh exports HARNESS_NO_RUNNER=1 (queue_ensure_runner a silent no-op): A3-03's runner check unsets it for that call or reads `queue start`'s line. → entries.jsonl:1

## Promote to Gotchas

- Verify can check the gatherer's move against main directly: git archive origin/main into scratch, run its bin/harness debrief --dry-run and the branch's on one status_stubs state, diff with line 1 and ## Glossary cut (context-bundle's own (b) compares two callers of the same function). → entries.jsonl:11
- harness queue list/show no longer mkdir queue/done (cmd_queue makes it only for a write) (agent-harness-2026-11-07-3 2026-11-07) → entries.jsonl:10
- A bundle runs the gatherer (harness status/needs/trends/queue): each routed event in a stub run costs ~1 s more; event-run.sh takes 39 s → entries.jsonl:9
- bash: an apostrophe in a ${v:-default} inside a double-quoted string fails to parse in a function body; put the default in a variable (agent-harness-2026-11-07-3 2026-11-07) → entries.jsonl:8
- Real curl 8.5.0 with -s (no -S) prints nothing on stderr for a 500 or a --max-time timeout; stdout is the -w code ('000' on timeout), exit 28. → entries.jsonl:5

## What it builds on

- 2026-11-07 16:54 · A2-01 · passes: Wrote docs/plans/2026-11-07-A2-context-bundle.md: glossary rules verbatim and how glossary.mjs applies them, dj fixtures with provenance, the line-by-line move of debrief.sh's gatherer into context.sh, harness context's CLI, context.json's shape, 30-day retention, the hook's bundle before the POST, all checks named with tiers.; tests 1814 → 1814; files docs/plans/2026-11-07-A2-context-bundle.md → entries.jsonl:6
- 2026-11-07 17:06 · A2-02 · passes: lib/glossary.mjs: findIds (the list's own ids, then three masking passes), resolveIds (feature list; doc rows and headings newest file first; unresolved never guessed), glossaryMarkdown (byte cap, whole lines), strip, knownIds, fsReader and a CLI; 17 unit tests on fixtures copied read-only from dj-crate-streaming; tests 1814 → 1831.; tests 1814 → 1831; files lib/glossary.mjs, tests/unit/glossary.test.mjs, tests/fixtures/glossary/, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt → entries.jsonl:7
- 2026-11-07 17:33 · A2-03 · passes: Moved the debrief's gatherer verbatim into lib/context.sh (context_since, context_runs, context_glossary); debrief.sh sources it, no copy. New `harness context <run> | --since <ts> [--out] [--id]` writes context.md (gatherer + ## Glossary via new lib/context.mjs) to events/<uuid>/ by default. The debrief's context gains the glossary. Tests 1831 → 1839.; tests 1831 → 1839; files lib/context.sh, lib/context.mjs, lib/debrief.sh, bin/harness, tests/checks/context-bundle.sh, … → entries.jsonl:8
- 2026-11-07 18:05 · A2-04 · passes: context.json (spec key order) now comes from the same lib/context.mjs call as context.md; a bundle written in events/ prunes bundles with no file newer than 30 days and says so; notify_event writes the bundle to events/<id>/ before the POST, so context names an existing context.json; the debrief passes since=$SINCE. A failed bundle: a note, context null. Decision file, docs.; tests 1839 → 1853; files lib/context.mjs, lib/context.sh, lib/notify.sh, lib/notify.mjs, lib/debrief.sh, … → entries.jsonl:9
- 2026-11-07 18:38 · A2-05 · passes: A2 review (one Opus round): 0 Critical, 2 Important, 6 Minor. Fixed RED→GREEN: I1 the debrief event's bundle is now the debrief's own (context.json from its gather, copied by context.sh --from via notify bundle=); I2 the debrief's ended words are alive-first again (ended_of; CTX_ENDED_FIRST for harness context). Minor fixed: dotted ids, spend, queue/done. Review file, decision, docs.; tests 1853 → 1857; files lib/context.sh, lib/debrief.sh, lib/notify.sh, lib/glossary.mjs, bin/harness, … → entries.jsonl:10

## Lately in the run

- 2026-11-07 18:55 · verify A2 · passes: All 5 A2 features hold. Full suite 1857/1857, fast 1023/1023, context-bundle/event-run/queue-debrief/flakes-run green. Independent diff: origin/main's debrief --dry-run context equals the branch's but the appended ## Glossary. Glossary CLI on fixtures resolves D24 (2 files, newest first), N1-01, M8, D-H1; Q99 unresolved. dj checkout clean. → entries.jsonl:11

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

_91 older rules: journal/decisions._

_3 items left out at 8192 bytes: entries.jsonl has them all._
