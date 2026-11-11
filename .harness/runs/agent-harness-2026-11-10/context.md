# Context pack for `V1-02`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (V1-01, affects V1-02): notify.mjs event treats an empty memory= as none, so V1-02's notify_event may pass memory="$memory" on every kind; only a non-empty memory= on a v1 kind exits 2 → entries.jsonl:2
- Discovery (V1-01, affects V1-02): V1-02's title: memreview.mjs title <memory-event.json> <run> (reads the card's held, failed, review); fixture made with actions labels 'Facts PR' and 'Rules PR', run mev, project proj → entries.jsonl:2
- Discovery (V1-01, affects V1-02, V2): the v2 fixture's placeholders: id <uuid>, at <ISO 8601>, the facts PR URL <facts PR url>, the rules PR URL <rules PR url> (jq walk split/join; command in tests/unit/notify.test.mjs) → entries.jsonl:2
- Discovery (V1-01, affects V1-02): the WIP commit's tests/fixtures/memory/event-{input,verdicts,memory}.json are a stub run mev's record (evict-two/evict-fails, pr); card and the v2 fixture are built on them → entries.jsonl:2
- Discovery (init, affects run): features.mjs lint prints review-small for V1-03 (V1 has two build features); the brief asks for three features in V1 with the review last, so the line stands by Michael's word (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:1
- Discovery (init, affects run): the run-level decline (memory.mjs answerRow without n, memory.sh decline <run> --why, curator answersText, the summary test) is in V2-01, not the spec's V2-02, for size; V2-02 only calls it (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:1
- Discovery (init, affects run): lib/notify.sh's routing (line 30) repeats ROUTED's kinds in a bash case, not read from notify.mjs: V1-02 adds a memory) arm testing EVENT_URL and EVENT_V2 there (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:1
- Discovery (init, affects run): memory_pr's last line (lib/record.sh) is the memreview.mjs line note with url/rurl in scope; the card and the notify call go after it, guarded by [[ $url$rurl == *http* ]] (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:1
- Discovery (init, affects run): tests/stub-curl.sh answers the event POST by STUB_EVENT (200|500|timeout) from fixtures/curl-event-<code>.out, three bytes of http_code and no newline: a 422 is a new fixture of the same shape (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:1
- Discovery (init, affects run): tests/stub-gh.sh's pr close takes a head branch today and pr merge reads N from the URL's last segment; close by URL and --comment are V2-02's additions, STUB_REFUSE_MERGE already exists (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:1
- Discovery (init, affects run): V1-01 has no stub run yet: the v2 fixture is made from notify.mjs event's own stdout over memreview.mjs card's, and V1-02's memory-event.sh check cmp's it against a stub run's event.json with placeholders; re-make it there if they differ (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:1
- Discovery (init, affects run): the request fixtures (tests/fixtures/requests/*.json) were written by n8n-home's buildRequest, which has no v2 branch yet: V2-01's three v2 request files come from one node command recorded in that README, and n8n-home builds to them (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:1

## What it builds on

- 2026-11-10 21:09 · V1-01 · passes: notify.mjs: KINDS gains memory, ROUTED_V2 exported, buildEvent v2 (14th key memory, v 2) for kind=memory only, memory= refused elsewhere; memreview.mjs card and title (pure, CLI). v2 fixture made from the stub-run files (command in notify.test.mjs, bytes pinned); v1 fixture untouched, v1 kinds' bytes pinned by sha256. Docs, decision file.; tests 1123 → 1130; files lib/notify.mjs, lib/memreview.mjs, tests/unit/notify.test.mjs, tests/unit/memreview.test.mjs, tests/fixtures/n8n-event-v2-memory.json, … → entries.jsonl:2

## Lately in the run

- 2026-11-10 19:41 · init · passes: 7 features: V1 3 (V1-01 the v2 event shape and fixture; V1-02 the send at the end of memory_pr behind EVENT_URL and EVENT_V2, else the ntfy line, memory-event.sh slow; V1-03 review), V2 4 (V2-01 request and result v2 and the run-level decline; V2-02 harness requests merge and close, the gh stub, memory-requests.sh fast; V2-03 the n8n-home checklist; V2-04 review). V2 after V1. Budget V1 15, V2 25. → entries.jsonl:1

## Current rules

- The memory event: v2 of the n8n contract on the `memory` kind alone, its object from the record, its title → journal/decisions/2026-11-10-review-surface-event.md
- The thin verify names its missing steps; a comment line is not a Gotcha → journal/decisions/2026-11-09-thin-verify-and-comment-lines.md
- The memory reviewer: one read-only session on what would land, four questions per operation, under the curator's deny list → journal/decisions/2026-11-09-memory-reviewer.md
- The memory reviewer counted: its cost and time beside its verdict, the ledger's rows by tier, and the rule that earns `auto` → journal/decisions/2026-11-09-memory-graduation.md
- The curator's write gate and its prompt say one rule: words may be left out after the first 40 characters, never added → journal/decisions/2026-11-09-curator-gate-words.md
- A claim that never reached the list is named, retried once told, and given up with its reason → journal/decisions/2026-11-09-claim-gap.md
- The memory session and the answers: a denied curator, an `auto` that keeps its body, answers the next curator reads → journal/decisions/2026-11-08-memory-session-and-answers.md
- The tiers and the files: tier 2 is a PR, the twins are guarded, the cap is per operation → journal/decisions/2026-11-08-memory-rules-pr.md
- The memory curator: itemized operations, a tier the driver derives, a protected list that is fixed → journal/decisions/2026-11-07-memory-tiers.md
- The gate replaces the lint: `memlint-self` retired, `MEMORY_POLICY`, and the curator's acceptance counted → journal/decisions/2026-11-07-memory-policy.md
- One writer for project memory: a coding session's `CLAUDE.md` edit is reverted, a fact goes in the entry → journal/decisions/2026-11-07-memory-one-writer.md
- Supervised efforts for every project: one user-level skill, one dispatch list per effort, plain names throughout → journal/decisions/2026-11-05-supervised-efforts.md

_99 older rules: journal/decisions._
