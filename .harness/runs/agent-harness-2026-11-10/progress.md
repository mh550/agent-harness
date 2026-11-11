<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-10` (agent-harness)

What this file is: the run's journal, newest entry first, rendered by the harness from `entries.jsonl` for your phone. Each entry is one session (coding, verify, review, retro) and says what it did, what it tried that failed, and what it found.

The run builds `docs/specs/2026-11-10-review-surface.md` in full under the brief of 2026-11-10 19:21: milestone V1 (one `memory` notification per run with a memory PR, sent at the end of the curator step after the reviewer's verdict: a v2 event POSTed to n8n only when `EVENT_URL` and `EVENT_V2=1` are both set, the plain ntfy line otherwise; every v1 event and the run's end notification keep their bytes), then V2 (two request verbs the card's actions write, `merge` and `close`, run by `harness requests` against the ledger's PRs with gh's state and the review rule first; a close with a reason is a decline the next curator reads; the n8n-home half is a checklist file in this repo). Three features in V1, four in V2, the review last in each; V2 after V1. Nothing is sent anywhere: curl and gh are stubs.

How to read the feature list: `feature_list.json` in this directory is in priority order; a session takes the first feature whose `passes` is false and whose `after` all pass. Each feature's `steps` are what a verifier re-runs; the last is always the suite green.

How to steer: edit `INBOX.md` on this branch from the GitHub app. Its first line `status: run|pause|stop` controls the run; an answer to a question goes under `## Answers`. The harness pulls it before every session.

Defaults the spec marks *default* are taken without asking (the brief says so) and recorded marked *default* in `journal/decisions/2026-11-10-review-surface-event.md` (V1) and `journal/decisions/2026-11-10-review-surface-verbs.md` (V2). The one live step (appending `EVENT_V2=1` to the user config after the n8n-home deploy) is written out in the V2-03 checklist for you; no session runs it.

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
