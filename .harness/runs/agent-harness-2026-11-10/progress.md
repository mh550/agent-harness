<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-10` (agent-harness)

What this file is: the run's journal, newest entry first, rendered by the harness from `entries.jsonl` for your phone. Each entry is one session (coding, verify, review, retro) and says what it did, what it tried that failed, and what it found.

The run builds `docs/specs/2026-11-10-review-surface.md` in full under the brief of 2026-11-10 19:21: milestone V1 (one `memory` notification per run with a memory PR, sent at the end of the curator step after the reviewer's verdict: a v2 event POSTed to n8n only when `EVENT_URL` and `EVENT_V2=1` are both set, the plain ntfy line otherwise; every v1 event and the run's end notification keep their bytes), then V2 (two request verbs the card's actions write, `merge` and `close`, run by `harness requests` against the ledger's PRs with gh's state and the review rule first; a close with a reason is a decline the next curator reads; the n8n-home half is a checklist file in this repo). Three features in V1, four in V2, the review last in each; V2 after V1. Nothing is sent anywhere: curl and gh are stubs.

How to read the feature list: `feature_list.json` in this directory is in priority order; a session takes the first feature whose `passes` is false and whose `after` all pass. Each feature's `steps` are what a verifier re-runs; the last is always the suite green.

How to steer: edit `INBOX.md` on this branch from the GitHub app. Its first line `status: run|pause|stop` controls the run; an answer to a question goes under `## Answers`. The harness pulls it before every session.

Defaults the spec marks *default* are taken without asking (the brief says so) and recorded marked *default* in `journal/decisions/2026-11-10-review-surface-event.md` (V1) and `journal/decisions/2026-11-10-review-surface-verbs.md` (V2). The one live step (appending `EVENT_V2=1` to the user config after the n8n-home deploy) is written out in the V2-03 checklist for you; no session runs it.

### 2026-11-10 23:06 · V2-02 · passes

harness requests runs v2 merge/close: ledger rule in node, then gh pr view state (merged/closed refused, claim to rejected/), the review rule on merge, then gh pr merge <url> --merge or gh pr close <url> [--comment why] as argv; a close with a why writes decline rows via harness memory decline (requests.mjs declineItems/declines). Stub gh by-URL merge/close; 11 checks, 1 unit test; docs.

- **Files:** lib/requests.sh, lib/requests.mjs, tests/stub-gh.sh, tests/checks/memory-requests.sh, tests/unit/requests.test.mjs, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, docs/architecture.md, README.md, journal/decisions/2026-11-10-review-surface-verbs.md, journal/decisions/2026-11-03-suite-tiers.md
- **Verified:** check.sh --fast green 1161 tests (133 s); the 11 new memory-requests checks failed against HEAD's requests.sh (2/13) and pass now (13/13, 3.6 s alone at TEST_JOBS=4); memory-review memory-branch lanes-record-pr memory-requests request-files 103/103; requests.test.mjs 30/30; grep -c 'eval\|bash -c' lib/requests.sh 0; git diff origin/main -- lib/record.sh has no memory_merge line
- **Tests:** 1149 → 1161
- **Dead end:** writing requests into requests/ before any harness requests call — the directory does not exist yet: req's redirect fails and the pass sees none pending; the check runs harness requests once first
- **Discovery** (affects V2-04, V2-03): requests.sh's v2 refusals after the claim (already merged/closed, review did not run) move done/<id>.request.json to rejected/; validate's --memory is <ledger>/memory.jsonl
- **Discovery** (affects V2-04): requests.mjs declines --memory --pr --ledger prints the harness memory decline items (facts: <run>; rules: <run>/<n> per rules[] n of the ledger's memory-result.json)
- **Discovery** (affects project): gh 2.45's pr close/merge message formats are readable offline: strings $(command -v gh) | grep 'Closed pull request' (agent-harness-2026-11-10 2026-11-10)
- **Discovery** (affects V2-03, V2-04): memory-requests.sh builds memory.jsonl via summary.mjs memory-line over event-memory.json (r1 facts pr/1 + rules pr/2 all held, r2 pr/3 review none) and resets the stub PRs per part
- **Proposed change:** V2-02 step 1's 'a second merge of a merged PR moves to requests/rejected/' means the claimed request is moved there after gh's state answers MERGED: the built order is claim, view, then move; V2-04 may read it
- *05-V2-02 · claude-opus-5-5*

### 2026-11-10 22:42 · V2-01 · passes

requests.mjs v2: merge/close on a ledger/memory.jsonl PR of the request run (--memory read in node), pr URL shape first, close why ≤300 one line, merge why refused; 12-key result (pr, state), pr= in requests.log, validate pr/review/why lines. Run-level decline: harness memory decline <run> --why (n/key null); latestAnswers keeps it, apply ignores it, answersText renders it. Docs, decision.

- **Files:** lib/requests.mjs, lib/memory.mjs, lib/memory.sh, lib/curator.mjs, bin/harness, tests/checks/memory-requests.sh, tests/checks/request-files.sh, tests/unit/requests.test.mjs, tests/unit/memory.test.mjs, tests/unit/curator.test.mjs, tests/unit/summary.test.mjs, tests/fixtures/requests/merge.json, +9 more
- **Verified:** unit: requests/memory/curator/summary 120/120 (9 requests and 5 memory/curator/summary tests red first); memory-requests 2/2 (red on HEAD's memory.sh/memory.mjs first), request-files 18/18; fast tier 1149/1149 (check.sh --fast, 134 s).; Opus review 0 Critical, 0 Important, 5 Minor: 3 fixed (apply test now red without its filter, why refuses control/line-separator chars, a ledger run failing RUN_RULE never quoted), 2 left (below)
- **Tests:** 1135 → 1149
- **Discovery** (affects V2-02): requests.sh one()'s ok branch runs every verb but answer as a continue: V2-02's v2 branch must come before it; today v2 never reaches ok there because --memory is not passed
- **Discovery** (affects V2-02): validate prints for a v2 request: pr, review (the row's review, - when none), why 1|0, after run; the why is in <out>/why; result --pr <url|-> makes the result v2 (--state merged|closed|-)
- **Discovery** (affects V2-02, V2-03): request fixtures v2 use run r1, facts PR https://example.test/pr/1, rules PR /pr/2 (stub-gh URLs); memory-requests.sh builds ledger/proj/r1/memory-result.json via curator.mjs apply on corrected.* (no rules[]: V2-02 needs a rules op)
- **Discovery** (affects V2): request-files.sh's v2 answer case now expects 'v 2 carries merge or close' (the old 'v is not 1 (this harness reads request v1)' is gone)
- **Discovery** (affects V2-04, V2-02): V2-04: a run-level decline is not tied to a facts row of ledger/memory.jsonl, and declinedRuns matches by run, so it also excuses a closed rules PR of that run (spec design; review M2)
- **Discovery** (affects V2-04): prompts/memory-review.md Q4 greps memory-answers.jsonl declined rows; a run-level row (text null) could be cited as <run>/null: one clause once V2-02 writes them
- **Question for Michael:** Default taken: a v2 pr must match ^https://<host>/<path>$ (≤200 chars) before any refusal quotes it; keep, or quote any string? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-10/slot-1/lib/requests.mjs, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-10/slot-1/journal/decisions/2026-11-10-review-surface-verbs.md
- **Proposed change:** V2-01 step 1: the existing 'verb merge is rejected' test already covers v1 with merge; and tests/checks/request-files.sh's v2-answer reason must change with this feature (not named in the steps)
- *04-V2-01 · claude-opus-5-5*

### 2026-11-10 22:25 · verify V1 · passes

V1-01, V1-02, V1-03 hold. Full suite 2019/2019 (823 s), fast tier 1135/1135, event-hook event-run memory-event memory-review 59/59. v1 bytes: origin/main's buildEvent and this branch's give the same sha256 over the ten v1 kinds; v2 fixture remade from its comment command is cmp-equal; real curl 8.5.0's 422 on loopback is curl-event-422.out. Two step wordings differ from the design (noted in rows).

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| V1-01 | 1 | node --test --test-isolation=none tests/unit/notify.test.mjs; read the four new/renamed notify tests; node lib/notify.mjs event kind=park memory=<card> and kind=memory with no memory= | tests pass; v1 test asserts 13 keys v 1 per kind and V1_SHA; I recomputed the sha with origin/main's lib/notify.mjs: same 84b98d33…; park+memory= exit 2, stdout empty, stderr 'memory= is the memory kind's'; memory without memory= exit 2; ROUTED/ROUTED_V2 as specified; old name gone from both name files | yes |
| V1-01 | 2 | read tests/unit/memreview.test.mjs card/title tests; node lib/memreview.mjs card event-verdicts.json event-memory.json event-input.json pr; title; card with no verdicts file | card keys pr rules_pr policy reviewed held failed failures state review; failures[0] {id facts/2, section ## Gotchas, q 2, reason without ' (q2)' (the verdict's ends '(q2)')}; one JSON line, cmp-equal to event-card.json; title '[mev] memory: 2 held · 1 failed', review none variant; merged when merged_by driver asserted in the test | yes |
| V1-01 | 3 | read lib/notify.mjs and lib/memreview.mjs diffs; node --check lib/notify.mjs; node --check lib/memreview.mjs | KINDS gains memory, ROUTED_V2 = [...ROUTED,'memory'] exported, buildEvent v2 for kind=memory only with refusals, CLI returns 2 on buildEvent's throws; card and title exported pure, card/title commands; both --check clean | yes |
| V1-01 | 4 | re-ran the command in tests/unit/notify.test.mjs:152 into scratch and cmp'd with tests/fixtures/n8n-event-v2-memory.json; git diff origin/main -- tests/fixtures/n8n-event-v1.json \| wc -c | cmp equal (V2_REMADE_SAME); v1 fixture diff 0 bytes; event-*.json are a stub run mev's record (README), and memory-event.sh's fixture check cmp's a live stub run's event.json against it (passed in the suite) | yes |
| V1-01 | 5 | sed docs/specs/2026-10-22-n8n-events.md:72-75; grep docs/architecture.md rows 65, 97, 166; cat journal/decisions/2026-11-10-review-surface-event.md | Updated in place 2026-11-10 line in Contracts pointing to the review-surface spec §V1-01; notify.mjs row names ROUTED_V2 and memory=, memreview row card( and title(, Routed events row v2 and memory-event.json; decision file has title, provenance, finding/choice/rejected, the five V1-01 defaults and rejected v 2 on every kind | yes |
| V1-01 | 6 | LC_ALL=C sort -c on check-names.txt and check-names-fast.txt; node --test --test-isolation=none tests/unit/notify.test.mjs tests/unit/memreview.test.mjs | both sorted (no output); new notify/memreview names in both files; 30/30 tests pass | yes |
| V1-01 | 7 | bash tests/run.sh --tier fast; bash tests/run.sh | fast: 1135/1135 checks passed; full: 2019/2019 checks passed, wall 823.3 s | yes |
| V1-02 | 1 | read tests/checks/memory-event.sh checks 1-4 (mev run); bash tests/run.sh event-hook event-run memory-event memory-review | 7/7 memory-event checks pass: one POST to EU, 14 keys, v 2, kind memory, failures[0].id ^facts/[0-9]+$, state open, review ok, body == memory: line, no ntfy of its title, run.log order, events/<id>/event.json == body, end notification diff vs mvn. Wording: the record's memory-event.json equals the body's .memory (the card, per step 3), not the whole body; the check asserts that | yes |
| V1-02 | 2 | read memory-event.sh checks for mvu/mvn/mvr/mva/mvp/mvx/fixture; real curl 8.5.0 -w '%{http_code}' against a node loopback 422 server on port 7837, cmp with tests/fixtures/curl-event-422.out | all pass; 422 bytes '422' no newline, cmp equal; the 422 note checked once; auto merged after merge note; proposal: no POST/ntfy/memory-event.json; review none title and failures []. Wording: the step's Title '1 held · 1 failed' is '2 held · 1 failed' (held counts rules/1, as the fixture), the check asserts 2 | yes |
| V1-02 | 3 | read lib/notify.sh, lib/record.sh memory_pr/memory_event, lib/config.sh, templates/user/config.sh diffs; bash -n on the five files; grep -n memory lib/notify.sh | routing arm memory) [[ -n ${EVENT_URL:-} && ${EVENT_V2:-} == 1 ]] (line 34); no bundle for memory, event.json still written; memory_event after the line note guarded by url/rurl http* (and a non-empty line, a recorded default); card → REC/memory-event.json; one notify kind=memory priority=""; EVENT_V2="" and the commented template line; bash -n clean | yes |
| V1-02 | 4 | git diff origin/main --stat -- tests/checks/event-hook.sh tests/checks/event-run.sh; bash tests/run.sh event-hook event-run memory-event memory-review; grep memory-event journal/decisions/2026-11-03-suite-tiers.md | diff empty; 59/59 checks passed (memory-event 72.7 s alone-ish, 82.2 s in the full run); tiers row memory-event slow 68.2 with reason present | yes |
| V1-02 | 5 | grep docs/architecture.md lines 64, 347-349, 482, 584; git diff README.md; read the decision file's V1-02 section | notify.sh row has EVENT_V2 and no bundle; CURATOR EVENT line; config row EVENT_V2; guard row names memory; README Notifications names memory kind and EVENT_V2, Memory reviewer the card; decision rows default (per segment own id, no bundle, EVENT_V2 switch) and rejected list (probing, per-kind list, silent 422, bundle) | yes |
| V1-02 | 6 | git diff origin/main tests/fixtures/check-names*.txt; grep -c '^memory event:' check-names-fast.txt; jq .checks entries.jsonl line 3 | seven memory event: names in check-names.txt, sorted; 0 in the fast file; entry checks 'V1 so far +15 ~1 -0 against the budget of 15' | yes |
| V1-02 | 7 | bash tests/run.sh --tier fast; bash tests/run.sh | fast 1135/1135; full 2019/2019 | yes |
| V1-03 | 1 | ls /tmp/harness/agent-harness/agent-harness-2026-11-10/V1.diff; cat docs/plans/2026-11-10-V1-review.md; checked each invariant myself (v1 sha old vs new, routing line, driver.sh not in diff, fixture cmp, http guard) | diff file 111939 bytes; review grades Critical none, Important none, 4 Minor; covers all five invariants with evidence; my own checks agree on each; one round (nothing Critical) | yes |
| V1-03 | 2 | read the review's Outcome; grep the ROUTED test reading notify.sh arms; git diff lib/notify.mjs event CLI | no Critical/Important; M2 and M4 fixed (ROUTED test reads notify.sh case arms, renamed within V1), M1 and M3 documented with why not in code; simplification 1 applied (CLI uses buildEvent's refusals), 2 declined with reason | yes |
| V1-03 | 3 | grep architecture.md rows 64/65/97/142/166/584, wc -l lib/memreview.mjs lib/notify.mjs, grep F3d; decision file Checks section | rows match the code (memory-event.json lifecycle at 142, memory_event writer at 166, sizes ~155/~120 vs 156/118 lines, no F3d left); README Notifications level; decision file lists every V1 default, the replaced name with its successor, +15 ~1 −0 against 15 | yes |
| V1-03 | 4 | bash -n lib/notify.sh lib/record.sh lib/config.sh tests/checks/memory-event.sh tests/stub-curl.sh; node --check lib/notify.mjs lib/memreview.mjs; bash tests/run.sh event-hook event-run memory-event memory-review | all clean; 59/59 checks passed (event-hook 11, event-run 12, memory-event 7, memory-review 28) | yes |
| V1-03 | 5 | bash tests/run.sh --tier fast; bash tests/run.sh | fast 1135/1135 checks passed; full 2019/2019 checks passed | yes |

- **Discovery** (affects run): feature_list V1-02 step 1 says the record's memory-event.json equals the POSTed body and step 2 says Title '1 held · 1 failed': the built design is memory-event.json == body.memory and '2 held · 1 failed' (rules/1 counted); V2 steps reading either should use the built shape
- *220639-verify-V1 · claude-opus-5-5*

### 2026-11-10 21:53 · V1-03 · passes

Opus review of V1 (docs/plans/2026-11-10-V1-review.md): 0 Critical, 0 Important, 4 Minor; five invariants hold. Fixed: docs level (memory-event.json lifecycle, memory_event writer, sizes, F3d tense), EVENT_V2 '1 exactly', ROUTED unit test now reads notify.sh's routing arms (renamed, failed on a mutation first), notify.mjs event CLI uses buildEvent's refusals. V1 checks +15 ~1 −0 recorded.

- **Files:** docs/plans/2026-11-10-V1-review.md, docs/architecture.md, journal/decisions/2026-11-10-review-surface-event.md, lib/notify.mjs, lib/notify.sh, lib/config.sh, lib/record.sh, lib/memreview.mjs, tests/unit/notify.test.mjs, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt
- **Verified:** unit notify+memreview 30/30; bash tests/run.sh memory-event event-hook event-run 31/31; check.sh --fast green 1131 tests; bash -n and node --check on touched files; the renamed ROUTED test failed with notify.sh's arm mutated to …|debrief|limit) and passes on the real one
- **Tests:** 1131 → 1131
- **Discovery** (affects V2): M1 left in code: memory-event.json in the record is removed only at memory_pr's start; a fix belongs beside finish's memory.json rm (driver.sh), a finish edit
- **Discovery** (affects V2): notify.mjs ROUTED/ROUTED_V2 are mirrored by notify.sh's case arms; notify.test.mjs's ROUTED test parses that line by regex: keep its shape or update the regex
- *03-V1-03 · claude-opus-5-5*

### 2026-11-10 21:37 · V1-02 · passes

memory_pr ends with memory_event when a PR exists and the memory: line is non-empty: memreview.mjs card → memory-event.json in the record, one notify kind=memory. notify.sh routes memory only with EVENT_URL and EVENT_V2=1 (v2, no bundle), else ntfy, no note. EVENT_V2 in config and template; stub curl 422; card survives a failed input. memory-event.sh (8 runs, 7 checks), docs, decision rows.

- **Files:** lib/notify.sh, lib/record.sh, lib/config.sh, lib/memreview.mjs, templates/user/config.sh, tests/stub-curl.sh, tests/fixtures/curl-event-422.out, tests/checks/memory-event.sh, tests/unit/memreview.test.mjs, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, docs/architecture.md, +3 more
- **Verified:** memory-event.sh red 0/7 before the code, 7/7 after; a mutant without the PR guard turned its last check red (mvo). bash tests/run.sh event-hook event-run memory-event memory-review: 59/59. TEST_JOBS=4 bash tests/run.sh memory-event: 68.2 s. Unit memreview+notify 30/30. check.sh --fast: green, 1130 → 1131 tests (the 7 memory-event checks are slow tier). event-hook.sh, event-run.sh, n8n-event-v1.json and lib/driver.sh unchanged against the merge base.
- **Tests:** 1130 → 1131
- **Dead end:** IFS=tab read of card .pr and .rules_pr — tab is IFS whitespace: an empty .pr folds and the rules PR lands in f; two jq calls instead
- **Discovery** (affects V1-03): The step's ntfy Title [<run>] memory: 1 held · 1 failed for evict-two/evict-fails is 2 held · 1 failed (held counts rules/1, as the fixture's title); the check asserts 2
- **Discovery** (affects V1-03, V2): The record's memory-event.json is the card (the event's memory object), not the whole event; the check compares it to the POSTed body's .memory
- **Discovery** (affects V1-03): memory_event also needs a non-empty memory: line (default, in the decision file): a reused PR refreshed with proposals alone sends nothing
- **Discovery** (affects V1-03): Review minor left for V1-03: a continue segment whose curator never reaches memory_pr (no ops file, memory_base fails) keeps the earlier segment's memory-event.json in the record, as memory-review.json does
- **Discovery** (affects project): a lane's .harness/runs/ is git-ignored by the state dir's exclude file: feature_list.json and entry.json never show in git status there (agent-harness-2026-11-10 2026-11-10)
- **Proposed change:** V1-02 step 2's ntfy Title should read `[<run>] memory: 2 held · 1 failed` (the evict-two run holds facts/1 and rules/1)
- **Proposed change:** V1-02 step 1's `the record's memory-event.json ... equal to the POSTed body` should say `to the POSTed body's memory`
- *02-V1-02 · claude-opus-5-5*

### 2026-11-10 21:09 · V1-01 · passes

notify.mjs: KINDS gains memory, ROUTED_V2 exported, buildEvent v2 (14th key memory, v 2) for kind=memory only, memory= refused elsewhere; memreview.mjs card and title (pure, CLI). v2 fixture made from the stub-run files (command in notify.test.mjs, bytes pinned); v1 fixture untouched, v1 kinds' bytes pinned by sha256. Docs, decision file.

- **Files:** lib/notify.mjs, lib/memreview.mjs, tests/unit/notify.test.mjs, tests/unit/memreview.test.mjs, tests/fixtures/n8n-event-v2-memory.json, tests/fixtures/memory/event-card.json, tests/fixtures/memory/README.md, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, docs/architecture.md, docs/specs/2026-10-22-n8n-events.md, journal/decisions/2026-11-10-review-surface-event.md
- **Verified:** node --test notify+memreview: 29/29 (new ones red first: missing exports / ROUTED_V2); check.sh --fast green, 1130 tests; git diff origin/main -- n8n-event-v1.json empty; LC_ALL=C sort -c on both name files
- **Tests:** 1123 → 1130
- **Discovery** (affects V1-02): notify.mjs event treats an empty memory= as none, so V1-02's notify_event may pass memory="$memory" on every kind; only a non-empty memory= on a v1 kind exits 2
- **Discovery** (affects V1-02): V1-02's title: memreview.mjs title <memory-event.json> <run> (reads the card's held, failed, review); fixture made with actions labels 'Facts PR' and 'Rules PR', run mev, project proj
- **Discovery** (affects V1-02, V2): the v2 fixture's placeholders: id <uuid>, at <ISO 8601>, the facts PR URL <facts PR url>, the rules PR URL <rules PR url> (jq walk split/join; command in tests/unit/notify.test.mjs)
- **Discovery** (affects V1-02): the WIP commit's tests/fixtures/memory/event-{input,verdicts,memory}.json are a stub run mev's record (evict-two/evict-fails, pr); card and the v2 fixture are built on them
- *01-V1-01 · claude-opus-5-5*

### 2026-11-10 19:41 · init · passes

7 features: V1 3 (V1-01 the v2 event shape and fixture; V1-02 the send at the end of memory_pr behind EVENT_URL and EVENT_V2, else the ntfy line, memory-event.sh slow; V1-03 review), V2 4 (V2-01 request and result v2 and the run-level decline; V2-02 harness requests merge and close, the gh stub, memory-requests.sh fast; V2-03 the n8n-home checklist; V2-04 review). V2 after V1. Budget V1 15, V2 25.

- **Discovery** (affects run): features.mjs lint prints review-small for V1-03 (V1 has two build features); the brief asks for three features in V1 with the review last, so the line stands by Michael's word (agent-harness-2026-11-10 2026-11-10)
- **Discovery** (affects run): the run-level decline (memory.mjs answerRow without n, memory.sh decline <run> --why, curator answersText, the summary test) is in V2-01, not the spec's V2-02, for size; V2-02 only calls it (agent-harness-2026-11-10 2026-11-10)
- **Discovery** (affects run): lib/notify.sh's routing (line 30) repeats ROUTED's kinds in a bash case, not read from notify.mjs: V1-02 adds a memory) arm testing EVENT_URL and EVENT_V2 there (agent-harness-2026-11-10 2026-11-10)
- **Discovery** (affects run): memory_pr's last line (lib/record.sh) is the memreview.mjs line note with url/rurl in scope; the card and the notify call go after it, guarded by [[ $url$rurl == *http* ]] (agent-harness-2026-11-10 2026-11-10)
- **Discovery** (affects run): tests/stub-curl.sh answers the event POST by STUB_EVENT (200|500|timeout) from fixtures/curl-event-<code>.out, three bytes of http_code and no newline: a 422 is a new fixture of the same shape (agent-harness-2026-11-10 2026-11-10)
- **Discovery** (affects run): tests/stub-gh.sh's pr close takes a head branch today and pr merge reads N from the URL's last segment; close by URL and --comment are V2-02's additions, STUB_REFUSE_MERGE already exists (agent-harness-2026-11-10 2026-11-10)
- **Discovery** (affects run): V1-01 has no stub run yet: the v2 fixture is made from notify.mjs event's own stdout over memreview.mjs card's, and V1-02's memory-event.sh check cmp's it against a stub run's event.json with placeholders; re-make it there if they differ (agent-harness-2026-11-10 2026-11-10)
- **Discovery** (affects run): the request fixtures (tests/fixtures/requests/*.json) were written by n8n-home's buildRequest, which has no v2 branch yet: V2-01's three v2 request files come from one node command recorded in that README, and n8n-home builds to them (agent-harness-2026-11-10 2026-11-10)
- *00-init · claude-fable-5-1*
