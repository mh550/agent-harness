# Context pack for `A3`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Dead end (A3-05, 13-A3-05): the I2 check matching the systemd-run line with $H — tests/lib.sh's H is tests/../bin/harness, while requests.sh's is the resolved HARNESS_HOME path: match /.*/bin/harness → entries.jsonl:16
- Dead end (A3-03, 11-A3-03): node -e 'import(process.argv[1])' "$MJS" for BACKUP_REFUSAL — requests.mjs's isMain sees argv[1] as itself and runs its CLI (usage error): the path goes in by env (M=$MJS) instead → entries.jsonl:14
- Dead end (A3-03, 11-A3-03): a bare wait for the two lock-contending calls — status_stubs' live driver (sleep 600) is a job of the check's shell: wait on the two pids → entries.jsonl:14
- Dead end (A3-01, 09-A3-01): tests/checks/requests-inbox.sh as the steps name it — suite-runner.sh's name lint fails it: inbox.sh's name is part of it → entries.jsonl:12
- Dead end (A3-01, 09-A3-01): DirectoryNotEmpty= on requests/ — done/, rejected/, requests.log, .lock keep it true: systemd restarts the service at once, 5 starts in 10 s fail the path unit (systemd.path(5)) → entries.jsonl:12
- Question (A3-01): A duplicate request id (default): moved to requests/rejected/, the first result left as it is, a refused log line; no second result. Keep, or write the duplicate's refusal somewhere n8n reads? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-0/docs/plans/2026-11-07-A3-request-inbox.md:101 → entries.jsonl:12
- Question (A3-01): A rejected request's result has exit: null (default: no command ran; n8n's card shows refused first). Keep null, or an integer like 2? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-0/docs/plans/2026-11-07-A3-request-inbox.md:101 → entries.jsonl:12
- 2026-11-07 19:57 · A3-05 · passes: A3 review: 1 Critical, 3 Important, 8 Minor. Fixed C1 (queue add --continue rewrote a queued entry raw, so a brief's lines became continue options), I1 (brief that is one option word refused), I2 (runner via systemd-run --scope under the unit), I3 (unreadable/non-regular *.json rejected), M1, M2, M5. Review file, decision, architecture, README.; tests 1890 → 1898; files bin/harness, lib/queue.mjs, lib/requests.mjs, lib/requests.sh, tests/checks/request-files.sh, … → entries.jsonl:16
- 2026-11-07 19:29 · A3-04 · passes: Shipped systemd/harness-requests.path (PathExistsGlob=%h/.local/state/harness/requests/*.json) and .service (oneshot, ExecStart the live bin/harness requests); 3 checks in request-files.sh (unit lines, systemd-analyze --user verify on copies pointed at this checkout, no XDG_CONFIG_HOME/systemd); decision 2026-10-22-request-inbox; README Steering paragraph with install; architecture §3/§4/§7.; tests 1053 → 1056; files systemd/harness-requests.path, systemd/harness-requests.service, tests/checks/request-files.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, … → entries.jsonl:15
- 2026-11-07 19:23 · A3-03 · passes: lib/requests.sh (harness requests): flock on requests/.lock, *.json oldest by mtime then name, each judged by requests.mjs validate, claimed into done/<id>.request.json, run as one argv call (answer; queue add --continue [--brief] then queue start outside 03:15–04:30), result written to a temp name and renamed, one log line; rest to rejected/. bin/harness dispatch and header.; tests 1876 → 1887; files lib/requests.sh, bin/harness, tests/checks/request-files.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt → entries.jsonl:14
- 2026-11-07 19:13 · A3-02 · passes: lib/requests.mjs: validateRequest (the plan's 11 rules in order, exact reasons; id/verb/run set only once validated), inBackupWindow + BACKUP_REFUSAL, resultJson (ten keys, output cut at 2000 bytes on a char boundary), resultName, logLine (takes no text), and validate/result CLIs. 19 unit tests, fixtures made by n8n-home's buildRequest at 859b25a.; tests 1857 → 1876; files lib/requests.mjs, tests/unit/requests.test.mjs, tests/fixtures/requests/answer.json, tests/fixtures/requests/continue.json, tests/fixtures/requests/continue-brief.json, … → entries.jsonl:13
- 2026-11-07 19:07 · A3-01 · passes: Wrote docs/plans/2026-11-07-A3-request-inbox.md: requests.mjs's validation table with exact reason strings, result JSON, log line and CLI; harness requests' pass (flock, order, claim-then-run, argv calls, backup window, real-clock grace); the runner start seen through gc-tmux's tmux shim; both units (verified with systemd-analyze here); 29 checks named with tiers.; tests 1857 → 1857; files docs/plans/2026-11-07-A3-request-inbox.md → entries.jsonl:12

## Discoveries for this feature

- Discovery (A3-04, affects A3-05, A4): architecture.md now has Request inbox rows in §3 (lib/requests.sh, lib/requests.mjs), §4 and §7 (Request inbox, Backup window); A3-05 corrects them as built, A4 needn't add more → entries.jsonl:15
- Discovery (A3-03, affects A3-04, A3-05): requests.sh writes no result when done/<name>.json exists (a duplicate, or a bad file named for a done id): only the log line; a symlink is moved unread and gets 'the request is not a regular file' → entries.jsonl:14
- Discovery (A3-03, affects A3-04): requests.sh's checks are tests/checks/request-files.sh (11 names, fast, 5.5 s); A3-04's unit checks go in the same file → entries.jsonl:14
- Discovery (A3-02, affects A3-03): requests.mjs result --id - prints no result JSON and only appends the log line (a request with no usable name); for a duplicate, bash ignores result's stdout so done/<id>.json stays the first's → entries.jsonl:13
- Discovery (A3-02, affects A3-03): validate's done set reads <done>/*.json names, stripping .request.json or .json, so a claim counts; window is judged at --now in the process's TZ; text/brief land in --out only for verdict ok → entries.jsonl:13
- Discovery (A3-02, affects A3-03, A3-05): Request fixtures come from n8n-home's buildRequest (tests/fixtures/requests/README.md holds the generator): change a value with jq, never hand-type a shape → entries.jsonl:13
- Discovery (A3-01, affects A3-02, A3-03, A3-05): n8n writes requests/<id>.json in one write, no rename (its D25); answer 1-<h> before continue 2-<h>; its card needs a string result id → entries.jsonl:12
- Discovery (A3-01, affects A3-03, A3-04, A3-05): The check file is tests/checks/request-files.sh (the plan's intro); runner start is seen via gc-tmux.sh's tmux shim with HARNESS_NO_RUNNER unset (plan 2.5) → entries.jsonl:12
- Discovery (A3-01, affects A3-03, A3-05): A duplicate id keeps the first done/<id>.json as it is and goes to rejected/ (plan 1.3), not A3-03 step 3 ok==false result → entries.jsonl:12
- Discovery (A3-01, affects A3-03, A3-04): systemd: a path unit restarts its service at once while the glob holds; 5 starts in 10 s fail it. One call waits out a young file (plan 2.4) → entries.jsonl:12
- Discovery (A2-05, affects A3, A4): The debrief's bundle is its own gather's (context.json in its workspace, copied by context.sh --from); notify's since= is gone, bundle=<dir> replaces it → entries.jsonl:10
- Discovery (A2-05, affects A3, A4): lib/context.sh ended_of: alive first (the debrief's bytes); CTX_ENDED_FIRST=1 (harness context only) reads ended first for the end event's bundle → entries.jsonl:10
- Discovery (A2-04, affects A2-05, run): run_context and context_glossary now read <state>/ended before alive: the driver writes ended (driver.sh:352) before its end notify, while still alive. → entries.jsonl:9
- Discovery (A2-01, affects A2-04, run): n8n-home's intake refuses a debrief event whose context isn't a string, so A1's debrief event (context null) always falls back to ntfy until A2-04 → entries.jsonl:6
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

_78 older rules: journal/decisions._
