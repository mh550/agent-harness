# Context pack for `A3-05`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Discoveries for this feature

- Discovery (A3-04, affects A3-05, A4): architecture.md now has Request inbox rows in §3 (lib/requests.sh, lib/requests.mjs), §4 and §7 (Request inbox, Backup window); A3-05 corrects them as built, A4 needn't add more → entries.jsonl:15
- Discovery (A3-03, affects A3-04, A3-05): requests.sh writes no result when done/<name>.json exists (a duplicate, or a bad file named for a done id): only the log line; a symlink is moved unread and gets 'the request is not a regular file' → entries.jsonl:14
- Discovery (A3-02, affects A3-03, A3-05): Request fixtures come from n8n-home's buildRequest (tests/fixtures/requests/README.md holds the generator): change a value with jq, never hand-type a shape → entries.jsonl:13
- Discovery (A3-01, affects A3-02, A3-03, A3-05): n8n writes requests/<id>.json in one write, no rename (its D25); answer 1-<h> before continue 2-<h>; its card needs a string result id → entries.jsonl:12
- Discovery (A3-01, affects A3-03, A3-04, A3-05): The check file is tests/checks/request-files.sh (the plan's intro); runner start is seen via gc-tmux.sh's tmux shim with HARNESS_NO_RUNNER unset (plan 2.5) → entries.jsonl:12
- Discovery (A3-01, affects A3-03, A3-05): A duplicate id keeps the first done/<id>.json as it is and goes to rejected/ (plan 1.3), not A3-03 step 3 ok==false result → entries.jsonl:12
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

- Every executable lib/*.sh needs the xtrace guard line ([[ -z ${HARNESS_XTRACE:-} ]] || source …/xtrace.sh) once, or xtrace.sh's guard check fails (agent-harness-2026-11-07-3 2026-11-07) → entries.jsonl:14
- wait_for runs a command, not a string: a negation or variables go through wait_for <s> eval '<expr>' (agent-harness-2026-11-07-3 2026-11-07) → entries.jsonl:14
- A check file name may not hold or sit inside another (suite-runner.sh namelint): requests-inbox.sh fails on inbox.sh (agent-harness-2026-11-07-3 2026-11-07) → entries.jsonl:12
- Verify can check the gatherer's move against main directly: git archive origin/main into scratch, run its bin/harness debrief --dry-run and the branch's on one status_stubs state, diff with line 1 and ## Glossary cut (context-bundle's own (b) compares two callers of the same function). → entries.jsonl:11
- harness queue list/show no longer mkdir queue/done (cmd_queue makes it only for a write) (agent-harness-2026… → entries.jsonl:10

## What it builds on

- 2026-11-07 19:13 · A3-02 · passes: lib/requests.mjs: validateRequest (the plan's 11 rules in order, exact reasons; id/verb/run set only once validated), inBackupWindow + BACKUP_REFUSAL, resultJson (ten keys, output cut at 2000 bytes on a char boundary), resultName, logLine (takes no text), and validate/result CLIs. 19 unit tests, fixtures made by n8n-home's buildRequest at 859b25a.; tests 1857 → 1876; files lib/requests.mjs, tests/unit/requests.test.mjs, tests/fixtures/requests/answer.json, tests/fixtures/requests/continue.json, tests/fixtures/requests/continue-brief.json, … → entries.jsonl:13
- 2026-11-07 19:23 · A3-03 · passes: lib/requests.sh (harness requests): flock on requests/.lock, *.json oldest by mtime then name, each judged by requests.mjs validate, claimed into done/<id>.request.json, run as one argv call (answer; queue add --continue [--brief] then queue start outside 03:15–04:30), result written to a temp name and renamed, one log line; rest to rejected/. bin/harness dispatch and header.; tests 1876 → 1887; files lib/requests.sh, bin/harness, tests/checks/request-files.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt → entries.jsonl:14
- 2026-11-07 19:29 · A3-04 · passes: Shipped systemd/harness-requests.path (PathExistsGlob=%h/.local/state/harness/requests/*.json) and .service (oneshot, ExecStart the live bin/harness requests); 3 checks in request-files.sh (unit lines, systemd-analyze --user verify on copies pointed at this checkout, no XDG_CONFIG_HOME/systemd); decision 2026-10-22-request-inbox; README Steering paragraph with install; architecture §3/§4/§7.; tests 1053 → 1056; files systemd/harness-requests.path, systemd/harness-requests.service, tests/checks/request-files.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, … → entries.jsonl:15

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

_93 older rules: journal/decisions._

_6 items left out at 8192 bytes: entries.jsonl has them all._
