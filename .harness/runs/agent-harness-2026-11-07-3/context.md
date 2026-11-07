# Context pack for `A1`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Dead end (A1-02, 02-A1-02): a curl-event-timeout.err fixture with curl's (28) line (A1-01's discovery) — with -s and no -S real curl 8.5.0 writes nothing on stderr on a timeout: re-captured on loopback, so the stub prints only stdout 000 and exits 28 → entries.jsonl:3
- Question (A1-03): EVENT_URL may hold a webhook secret but sits on curl's command line (ps, HARNESS_XTRACE traces) as NTFY_URL does; should lib/xtrace.sh's warning name it too, or the POST read the URL from a file (curl -K)? Default: left as is. Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-0/docs/plans/2026-11-07-A1-review.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-0/lib/notify.sh:62 → entries.jsonl:4
- 2026-11-07 16:19 · A1-03 · passes: Every notify call site names its kind (park+feature, needs_michael, blocked/ended by ehigh, started, paused, verified, merged, limit, debrief, other); tests/checks/event-run.sh (slow, 6 checks, 5 stub runs + debrief) proves the routes end to end; decision 2026-10-22-event-hook-ntfy-fallback; architecture §3/§4/§7/§10 and README Steering; Opus review: no Critical/Important.; tests 1808 → 1814; files lib/record.sh, lib/driver.sh, lib/lane.sh, lib/debrief.sh, lib/desk.sh, … → entries.jsonl:4
- 2026-11-07 16:08 · A1-02 · passes: notify takes kind=/feature=; with EVENT_URL set park/needs_michael/blocked/debrief build v1 JSON in lib/notify.mjs event, keep it at events/<id>/event.json and POST it once (-w http_code, --max-time EVENT_TIMEOUT, no retry/token); 2xx logs and returns, else a note and today's ntfy/NOTIFY_CMD post unchanged. Stub-curl STUB_EVENT knob with real curl fixtures.; tests 1791 → 1808; files lib/notify.mjs, lib/notify.sh, lib/config.sh, templates/user/config.sh, tests/stub-curl.sh, … → entries.jsonl:3
- 2026-11-07 15:59 · A1-01 · passes: Wrote docs/plans/2026-11-07-A1-event-hook.md: the v1 event keys and who fills each, the POST verbatim (-w '%{http_code}', no --fail/--retry/token), the two log lines, stub-curl's STUB_EVENT knob with fixtures from real curl 8.5.0 on loopback, every notify call mapped to its kind, 11 existing curl checks (all stay) and the 23 new check names with tiers.; tests 1791 → 1791; files docs/plans/2026-11-07-A1-event-hook.md → entries.jsonl:2

## Discoveries for this feature

- Discovery (A1-02, affects A1-03): notify's kind defaults to other and no call site passes kind= yet: A1-03 adds them; until then every notification goes to ntfy exactly as before, EVENT_URL set or not. → entries.jsonl:3
- Discovery (A1-02, affects A1-03): tests/checks/event-hook.sh's eh/rec/posted/hdr helpers read one case's curl record; event-run.sh can read the event as the line after --data-binary in the call carrying 'Content-Type: application/json'. → entries.jsonl:3
- Discovery (A1-02, affects A1-03): The decision file (2026-10-22-event-hook-ntfy-fallback) and the architecture/README lines are A1-03's per the plan; A1-02 wrote none. → entries.jsonl:3
- Discovery (A1-01, affects A1-03): A park run ends 'waiting on Michael: B' (ehigh 1), so with EVENT_URL set it posts a park event AND a blocked run-end event: event-run's park check must count park events, not POSTs. → entries.jsonl:2
- Discovery (A1-01, affects A1-03): needs_notify already forwards a caller's kind=/feature= (both branches call notify "$msg" "$@" before the record's 5 fields): no change to lib/needs.sh in A1. → entries.jsonl:2
- Discovery (A1-01, affects A1-02): Real curl 8.5.0, -s -o /dev/null -w '%{http_code}': 500 → stdout 500 exit 0 no stderr; timeout → stdout 000, exit 28, 'curl: (28) Operation timed out after N milliseconds with 0 bytes received'. → entries.jsonl:2
- Discovery (A1-01, affects run): features.mjs repair compares the list as JSON, so a jq rewrite of feature_list.json that flips only passes is not an edit. → entries.jsonl:2
- Discovery (init, affects run): A1 ships events with `context: null`; A2-04 wires lib/context.sh's bundle into lib/notify.sh's routed post (the spec's A1 text puts the bundle in A1). → entries.jsonl:1
- Discovery (init, affects run): Decision files take the spec's names (journal/decisions/2026-10-22-<slug>.md, the three §A4 lists), not today's date: the spec and n8n-home cite them so. → entries.jsonl:1
- Discovery (init, affects run): tests/fixtures/n8n-event-v1.json already holds the v1 event JSON (needs-record.sh reads its keys): the event builder's key order is checked against it. → entries.jsonl:1
- Discovery (init, affects run): tests/lib.sh exports HARNESS_NO_RUNNER=1 (queue_ensure_runner a silent no-op): A3-03's runner check unsets it for that call or reads `queue start`'s line. → entries.jsonl:1

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
- The resident helper: one warm node process per driver and lane answers the `.mjs` questions over a coproc → journal/decisions/2026-11-03-resident-helper.md
- The purity moves: the bash decision tables become pure functions with a unit test per branch; no note text changes → journal/decisions/2026-11-03-purity.md
- The fast gate: `check.sh --fast` runs the fast tier, marks `fast-<key>`, and a fast-green is never read as a green → journal/decisions/2026-11-03-fast-gate.md
- The check count and the check budget: every verified milestone says what it added to the suite, against a budget when the spec set one; a note, never a gate → journal/decisions/2026-11-03-check-budget.md
- A run never starts on a spec that isn't there: `harness start` and `queue add` refuse a spec absent from the run's base ref → journal/decisions/2026-10-31-spec-must-exist.md
- One full run per coding session, last: the prompt's rule and §3 order, and `Suite runs` in the report → journal/decisions/2026-10-31-one-full-run.md
- Fewer node starts: where a stub run's process starts come from, and the cuts C1 makes → journal/decisions/2026-10-31-fewer-node-starts.md
- The suite's length in every prompt: a green marker's `wall` line, and a timeout rule → journal/decisions/2026-10-30-suite-length-in-prompt.md
- A red tree is cached: `red-<key>`, so the next full call on the tree just found red runs nothing → journal/decisions/2026-10-30-red-marker.md
- A mapped path's change runs only its readers: `CHECK_KEY_MAP`, the `part-<key>` sidecar, the partial run, the lint → journal/decisions/2026-10-30-partial-key.md
- The coordinator opens no lane while a lane that exited is not reaped yet → journal/decisions/2026-10-30-opens-wait-for-reap.md
- The lane guard reverts against the lane's merge-base with main, in the index only → journal/decisions/2026-10-30-lane-guard-base.md
- Timing checks bound CPU time; a stopped file's missing names don't void `HARNESS_FAILED=` → journal/decisions/2026-10-30-cpu-time-bound-and-stopped-files.md

_76 older rules: journal/decisions._
