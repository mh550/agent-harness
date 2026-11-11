# Context pack for `V2-01`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (V1, affects run): feature_list V1-02 step 1 says the record's memory-event.json equals the POSTed body and step 2 says Title '1 held · 1 failed': the built design is memory-event.json == body.memory and '2 held · 1 failed' (rules/1 counted); V2 steps reading either should use the built shape → entries.jsonl:5
- Discovery (V1-03, affects V2): M1 left in code: memory-event.json in the record is removed only at memory_pr's start; a fix belongs beside finish's memory.json rm (driver.sh), a finish edit → entries.jsonl:4
- Discovery (V1-03, affects V2): notify.mjs ROUTED/ROUTED_V2 are mirrored by notify.sh's case arms; notify.test.mjs's ROUTED test parses that line by regex: keep its shape or update the regex → entries.jsonl:4
- Discovery (V1-02, affects V1-03, V2): The record's memory-event.json is the card (the event's memory object), not the whole event; the check compares it to the POSTed body's .memory → entries.jsonl:3
- Discovery (V1-01, affects V1-02, V2): the v2 fixture's placeholders: id <uuid>, at <ISO 8601>, the facts PR URL <facts PR url>, the rules PR URL <rules PR url> (jq walk split/join; command in tests/unit/notify.test.mjs) → entries.jsonl:2
- Discovery (init, affects run): features.mjs lint prints review-small for V1-03 (V1 has two build features); the brief asks for three features in V1 with the review last, so the line stands by Michael's word (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:1
- Discovery (init, affects run): the run-level decline (memory.mjs answerRow without n, memory.sh decline <run> --why, curator answersText, the summary test) is in V2-01, not the spec's V2-02, for size; V2-02 only calls it (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:1
- Discovery (init, affects run): lib/notify.sh's routing (line 30) repeats ROUTED's kinds in a bash case, not read from notify.mjs: V1-02 adds a memory) arm testing EVENT_URL and EVENT_V2 there (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:1
- Discovery (init, affects run): memory_pr's last line (lib/record.sh) is the memreview.mjs line note with url/rurl in scope; the card and the notify call go after it, guarded by [[ $url$rurl == *http* ]] (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:1
- Discovery (init, affects run): tests/stub-curl.sh answers the event POST by STUB_EVENT (200|500|timeout) from fixtures/curl-event-<code>.out, three bytes of http_code and no newline: a 422 is a new fixture of the same shape (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:1
- Discovery (init, affects run): tests/stub-gh.sh's pr close takes a head branch today and pr merge reads N from the URL's last segment; close by URL and --comment are V2-02's additions, STUB_REFUSE_MERGE already exists (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:1
- Discovery (init, affects run): V1-01 has no stub run yet: the v2 fixture is made from notify.mjs event's own stdout over memreview.mjs card's, and V1-02's memory-event.sh check cmp's it against a stub run's event.json with placeholders; re-make it there if they differ (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:1
- Discovery (init, affects run): the request fixtures (tests/fixtures/requests/*.json) were written by n8n-home's buildRequest, which has no v2 branch yet: V2-01's three v2 request files come from one node command recorded in that README, and n8n-home builds to them (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:1

## Promote to Gotchas

- a lane's .harness/runs/ is git-ignored by the state dir's exclude file: feature_list.json and entry.json never show in git status there (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:3

## What it builds on

- 2026-11-10 21:09 · V1-01 · passes: notify.mjs: KINDS gains memory, ROUTED_V2 exported, buildEvent v2 (14th key memory, v 2) for kind=memory only, memory= refused elsewhere; memreview.mjs card and title (pure, CLI). v2 fixture made from the stub-run files (command in notify.test.mjs, bytes pinned); v1 fixture untouched, v1 kinds' bytes pinned by sha256. Docs, decision file.; tests 1123 → 1130; files lib/notify.mjs, lib/memreview.mjs, tests/unit/notify.test.mjs, tests/unit/memreview.test.mjs, tests/fixtures/n8n-event-v2-memory.json, … → entries.jsonl:2
- 2026-11-10 21:37 · V1-02 · passes: memory_pr ends with memory_event when a PR exists and the memory: line is non-empty: memreview.mjs card → memory-event.json in the record, one notify kind=memory. notify.sh routes memory only with EVENT_URL and EVENT_V2=1 (v2, no bundle), else ntfy, no note. EVENT_V2 in config and template; stub curl 422; card survives a failed input. memory-event.sh (8 runs, 7 checks), docs, decision rows.; tests 1130 → 1131; files lib/notify.sh, lib/record.sh, lib/config.sh, lib/memreview.mjs, templates/user/config.sh, … → entries.jsonl:3
- 2026-11-10 21:53 · V1-03 · passes: Opus review of V1 (docs/plans/2026-11-10-V1-review.md): 0 Critical, 0 Important, 4 Minor; five invariants hold. Fixed: docs level (memory-event.json lifecycle, memory_event writer, sizes, F3d tense), EVENT_V2 '1 exactly', ROUTED unit test now reads notify.sh's routing arms (renamed, failed on a mutation first), notify.mjs event CLI uses buildEvent's refusals. V1 checks +15 ~1 −0 recorded.; tests 1131 → 1131; files docs/plans/2026-11-10-V1-review.md, docs/architecture.md, journal/decisions/2026-11-10-review-surface-event.md, lib/notify.mjs, lib/notify.sh, … → entries.jsonl:4

## Lately in the run

- 2026-11-10 22:25 · verify V1 · passes: V1-01, V1-02, V1-03 hold. Full suite 2019/2019 (823 s), fast tier 1135/1135, event-hook event-run memory-event memory-review 59/59. v1 bytes: origin/main's buildEvent and this branch's give the same sha256 over the ten v1 kinds; v2 fixture remade from its comment command is cmp-equal; real curl 8.5.0's 422 on loopback is curl-event-422.out. Two step wordings differ from the design (noted in rows). → entries.jsonl:5

## Current rules

- A session's environment carries no TMUX; a driver's hangup names itself → journal/decisions/2026-11-10-session-env-no-tmux.md
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

_101 older rules: journal/decisions._
