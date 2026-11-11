<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-10` (agent-harness)

What this file is: the run's journal, newest entry first, rendered by the harness from `entries.jsonl` for your phone. Each entry is one session (coding, verify, review, retro) and says what it did, what it tried that failed, and what it found.

The run builds `docs/specs/2026-11-10-review-surface.md` in full under the brief of 2026-11-10 19:21: milestone V1 (one `memory` notification per run with a memory PR, sent at the end of the curator step after the reviewer's verdict: a v2 event POSTed to n8n only when `EVENT_URL` and `EVENT_V2=1` are both set, the plain ntfy line otherwise; every v1 event and the run's end notification keep their bytes), then V2 (two request verbs the card's actions write, `merge` and `close`, run by `harness requests` against the ledger's PRs with gh's state and the review rule first; a close with a reason is a decline the next curator reads; the n8n-home half is a checklist file in this repo). Three features in V1, four in V2, the review last in each; V2 after V1. Nothing is sent anywhere: curl and gh are stubs.

How to read the feature list: `feature_list.json` in this directory is in priority order; a session takes the first feature whose `passes` is false and whose `after` all pass. Each feature's `steps` are what a verifier re-runs; the last is always the suite green.

How to steer: edit `INBOX.md` on this branch from the GitHub app. Its first line `status: run|pause|stop` controls the run; an answer to a question goes under `## Answers`. The harness pulls it before every session.

Defaults the spec marks *default* are taken without asking (the brief says so) and recorded marked *default* in `journal/decisions/2026-11-10-review-surface-event.md` (V1) and `journal/decisions/2026-11-10-review-surface-verbs.md` (V2). The one live step (appending `EVENT_V2=1` to the user config after the n8n-home deploy) is written out in the V2-03 checklist for you; no session runs it.

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
