# Context pack for `A4`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- 2026-11-07 20:28 · A4-01 · passes: Docs checked against code: README, config template, lib/config.sh, decisions and architecture already held from A1-A3. Added the spec/fixture citations (contract v1) to architecture §4 and wrote docs/plans/2026-10-22-n8n-events-live.md (stages, commands, how to tell, undo). Subagent review fixed the inbox.md path.; tests 1064 → 1064; files docs/architecture.md, docs/plans/2026-10-22-n8n-events-live.md → entries.jsonl:18

## Discoveries for this feature

- Discovery (A3, affects run): Step texts naming tests/checks/requests-inbox.sh and `bash tests/run.sh requests-inbox` match no file: the check file is tests/checks/request-files.sh (the name lint). A3-03 step 3's 'duplicate gets ok==false result' is by design not written: the first result stands (plan §1.3, A3-01's open question). → entries.jsonl:17
- Discovery (A3-05, affects project, A4): A tmux server first started from a systemd oneshot dies with the oneshot's cgroup: start it via systemd-run --user --scope when INVOCATION_ID is set (agent-harness-2026-11-07-3 2026-11-07) → entries.jsonl:16
- Discovery (A3-05, affects A4): A4's live checklist should include running systemctl --user reset-failed harness-requests.path when the path unit has failed (five restarts in 10 s). → entries.jsonl:16
- Discovery (A3-04, affects A4): The README's request-inbox paragraph is a Steering bullet after Notifications ('Answers from the phone card'); A4's live checklist can link it rather than repeat the install → entries.jsonl:15
- Discovery (A3-04, affects A3-05, A4): architecture.md now has Request inbox rows in §3 (lib/requests.sh, lib/requests.mjs), §4 and §7 (Request inbox, Backup window); A3-05 corrects them as built, A4 needn't add more → entries.jsonl:15
- Discovery (A2-05, affects A3, A4): The debrief's bundle is its own gather's (context.json in its workspace, copied by context.sh --from); notify's since= is gone, bundle=<dir> replaces it → entries.jsonl:10
- Discovery (A2-05, affects A3, A4): lib/context.sh ended_of: alive first (the debrief's bytes); CTX_ENDED_FIRST=1 (harness context only) reads ended first for the end event's bundle → entries.jsonl:10
- Discovery (A2-04, affects A2-05, run): run_context and context_glossary now read <state>/ended before alive: the driver writes ended (driver.sh:352) before its end notify, while still alive. → entries.jsonl:9
- Discovery (A2-04, affects A2-05, A4): notify_event's ctx is the directory context.sh prints (cd && pwd), so a trailing-slash HARNESS_STATE never gives n8n a // path (its contextPaths guard). → entries.jsonl:9
- Discovery (A2-01, affects A2-04, run): n8n-home's intake refuses a debrief event whose context isn't a string, so A1's debrief event (context null) always falls back to ntfy until A2-04 → entries.jsonl:6
- Discovery (A1-01, affects run): features.mjs repair compares the list as JSON, so a jq rewrite of feature_list.json that flips only passes is not an edit. → entries.jsonl:2
- Discovery (init, affects run): A1 ships events with `context: null`; A2-04 wires lib/context.sh's bundle into lib/notify.sh's routed post (the spec's A1 text puts the bundle in A1). → entries.jsonl:1
- Discovery (init, affects run): Decision files take the spec's names (journal/decisions/2026-10-22-<slug>.md, the three §A4 lists), not today's date: the spec and n8n-home cite them so. → entries.jsonl:1
- Discovery (init, affects run): tests/fixtures/n8n-event-v1.json already holds the v1 event JSON (needs-record.sh reads its keys): the event builder's key order is checked against it. → entries.jsonl:1
- Discovery (init, affects run): tests/lib.sh exports HARNESS_NO_RUNNER=1 (queue_ensure_runner a silent no-op): A3-03's runner check unsets it for that call or reads `queue start`'s line. → entries.jsonl:1

## Lately in the run

- 2026-11-07 20:24 · verify A3 · passes: A3-01..05 hold. Full suite 1898/1898 (710 s), fast 1064/1064, unit 538/538. Re-ran every step by hand in a throwaway state: verbatim answer, continue+runner via tmux shim, 03:30 refusal, 6 rejections, grace, lock, unit PATH without nvm, systemd-analyze. Reverting C1's fix turns its check red. Plan-recorded deviations accepted: request-files.sh name, duplicate keeps first result, unit PATH, --out. → entries.jsonl:17
- 2026-11-07 19:57 · A3-05 · passes: A3 review: 1 Critical, 3 Important, 8 Minor. Fixed C1 (queue add --continue rewrote a queued entry raw, so a brief's lines became continue options), I1 (brief that is one option word refused), I2 (runner via systemd-run --scope under the unit), I3 (unreadable/non-regular *.json rejected), M1, M2, M5. Review file, decision, architecture, README.; tests 1890 → 1898; files bin/harness, lib/queue.mjs, lib/requests.mjs, lib/requests.sh, tests/checks/request-files.sh, … → entries.jsonl:16

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

_78 older rules: journal/decisions._
