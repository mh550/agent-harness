# Context pack for `V2-04`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (V2-03, affects V2-04): the checklist is docs/2026-11-10-review-surface-n8n-home.md, not docs/plans/ (a pointer stays there): V2-04 reads it there → entries.jsonl:8
- Discovery (V2-03, affects V2-04): memreview.mjs card's state is only open|merged (merged = the driver merged the facts PR under auto); q and section may be null → entries.jsonl:8
- Discovery (V2-02, affects V2-04, V2-03): requests.sh's v2 refusals after the claim (already merged/closed, review did not run) move done/<id>.request.json to rejected/; validate's --memory is <ledger>/memory.jsonl → entries.jsonl:7
- Discovery (V2-02, affects V2-04): requests.mjs declines --memory --pr --ledger prints the harness memory decline items (facts: <run>; rules: <run>/<n> per rules[] n of the ledger's memory-result.json) → entries.jsonl:7
- Discovery (V2-02, affects V2-03, V2-04): memory-requests.sh builds memory.jsonl via summary.mjs memory-line over event-memory.json (r1 facts pr/1 + rules pr/2 all held, r2 pr/3 review none) and resets the stub PRs per part → entries.jsonl:7
- Discovery (V2-01, affects V2): request-files.sh's v2 answer case now expects 'v 2 carries merge or close' (the old 'v is not 1 (this harness reads request v1)' is gone) → entries.jsonl:6
- Discovery (V2-01, affects V2-04, V2-02): V2-04: a run-level decline is not tied to a facts row of ledger/memory.jsonl, and declinedRuns matches by run, so it also excuses a closed rules PR of that run (spec design; review M2) → entries.jsonl:6
- Discovery (V2-01, affects V2-04): prompts/memory-review.md Q4 greps memory-answers.jsonl declined rows; a run-level row (text null) could be cited as <run>/null: one clause once V2-02 writes them → entries.jsonl:6
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

- A check may not read docs/plans or docs/specs (CHECK_KEY_IGNORE, check-key.sh): a doc a check keeps true lives under docs/ or tests/ (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:8
- gh 2.45's pr close/merge message formats are readable offline: strings $(command -v gh) | grep 'Closed pull request' (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:7
- a lane's .harness/runs/ is git-ignored by the state dir's exclude file: feature_list.json and entry.json never show in git status there (agent-harness-2026-11-10 2026-11-10) → entries.jsonl:3

## What it builds on

- 2026-11-10 22:42 · V2-01 · passes: requests.mjs v2: merge/close on a ledger/memory.jsonl PR of the request run (--memory read in node), pr URL shape first, close why ≤300 one line, merge why refused; 12-key result (pr, state), pr= in requests.log, validate pr/review/why lines. Run-level decline: harness memory decline <run> --why (n/key null); latestAnswers keeps it, apply ignores it, answersText renders it. Docs, decision.; tests 1135 → 1149; files lib/requests.mjs, lib/memory.mjs, lib/memory.sh, lib/curator.mjs, bin/harness, … → entries.jsonl:6
- 2026-11-10 23:06 · V2-02 · passes: harness requests runs v2 merge/close: ledger rule in node, then gh pr view state (merged/closed refused, claim to rejected/), the review rule on merge, then gh pr merge <url> --merge or gh pr close <url> [--comment why] as argv; a close with a why writes decline rows via harness memory decline (requests.mjs declineItems/declines). Stub gh by-URL merge/close; 11 checks, 1 unit test; docs.; tests 1149 → 1161; files lib/requests.sh, lib/requests.mjs, tests/stub-gh.sh, tests/checks/memory-requests.sh, tests/unit/requests.test.mjs, … → entries.jsonl:7
- 2026-11-10 23:17 · V2-03 · passes: The n8n-home checklist (intake v2 rule, workflow 42 memory card, the two request JSON shapes, the deploy order, Michael's EVENT_V2 step and undo, five must-nots) at docs/2026-11-10-review-surface-n8n-home.md (default: docs/plans is outside the suite key; a pointer stays there), one fast check, READMEs, decision lines.; tests 1161 → 1162; files docs/2026-11-10-review-surface-n8n-home.md, docs/plans/2026-11-10-review-surface-n8n-home.md, tests/checks/memory-requests.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, … → entries.jsonl:8

## Current rules

- A session's environment carries no TMUX; a driver's hangup names itself → journal/decisions/2026-11-10-session-env-no-tmux.md

_112 older rules: journal/decisions._
