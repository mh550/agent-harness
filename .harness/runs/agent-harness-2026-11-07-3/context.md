# Context pack for `A4-01`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## This feature's earlier attempts

- Verify A4 found (A4-01 step 6): ran Sonnet subagent review of git diff 8e05980 HEAD (the run's docs: the step's merge-base diff is now only A4's 2 files) against bin/, lib/, systemd/, fixtures; saw one finding unfixed: docs/architecture.md:58 says the debrief notification passes `since=` its SINCE; lib/notify.sh:2,26 has no since key and lib/debrief.sh:251 passes bundle="$WS" → entries.jsonl:19
- 2026-11-07 20:28 · A4-01 · passes: Docs checked against code: README, config template, lib/config.sh, decisions and architecture already held from A1-A3. Added the spec/fixture citations (contract v1) to architecture §4 and wrote docs/plans/2026-10-22-n8n-events-live.md (stages, commands, how to tell, undo). Subagent review fixed the inbox.md path.; tests 1064 → 1064; files docs/architecture.md, docs/plans/2026-10-22-n8n-events-live.md → entries.jsonl:18

## Discoveries for this feature

- Discovery (A4, affects run): A4-01 step 6's diff `git diff $(git merge-base HEAD origin/main)` covers only A4's own commits once A1-A3 merged per milestone; the run's docs as one piece are `git diff 8e05980 HEAD` (main before A1's merge). → entries.jsonl:19
- Discovery (A3, affects run): Step texts naming tests/checks/requests-inbox.sh and `bash tests/run.sh requests-inbox` match no file: the check file is tests/checks/request-files.sh (the name lint). A3-03 step 3's 'duplicate gets ok==false result' is by design not written: the first result stands (plan §1.3, A3-01's open question). → entries.jsonl:17
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

## Promote to Gotchas

- bin/harness's cmd_continue and queue add match --now, --queued, --requested, --automatic and --keep-attempts anywhere in the args, not in pairs, so a value equal to a flag is read as that flag (agent-harness-2026-11-07-3 2026-11-07) → entries.jsonl:16
- A tmux server first started from a systemd oneshot dies with the oneshot's cgroup: start it via systemd-run --user --scope when INVOCATION_ID is set (agent-harness-2026-11-07-3 2026-11-07) → entries.jsonl:16
- Every executable lib/*.sh needs the xtrace guard line ([[ -z ${HARNESS_XTRACE:-} ]] || source …/xtrace.sh) once, or xtrace.sh's guard check fails (agent-harness-2026-11-07-3 2026-11-07) → entries.jsonl:14
- wait_for runs a command, not a string: a negation or variables go through wait_for <s> eval '<expr>' (agent-harness-2026-11-07-3 2026-11-07) → entries.jsonl:14
- A check file name may not hold or sit inside another (suite-runner.sh namelint): requests-inbox.sh fails on inbox.sh (agent-harnes… → entries.jsonl:12

## What it builds on

- 2026-11-07 19:07 · A3-01 · passes: Wrote docs/plans/2026-11-07-A3-request-inbox.md: requests.mjs's validation table with exact reason strings, result JSON, log line and CLI; harness requests' pass (flock, order, claim-then-run, argv calls, backup window, real-clock grace); the runner start seen through gc-tmux's tmux shim; both units (verified with systemd-analyze here); 29 checks named with tiers.; tests 1857 → 1857; files docs/plans/2026-11-07-A3-request-inbox.md → entries.jsonl:12
- 2026-11-07 19:13 · A3-02 · passes: lib/requests.mjs: validateRequest (the plan's 11 rules in order, exact reasons; id/verb/run set only once validated), inBackupWindow + BACKUP_REFUSAL, resultJson (ten keys, output cut at 2000 bytes on a char boundary), resultName, logLine (takes no text), and validate/result CLIs. 19 unit tests, fixtures made by n8n-home's buildRequest at 859b25a.; tests 1857 → 1876; files lib/requests.mjs, tests/unit/requests.test.mjs, tests/fixtures/requests/answer.json, tests/fixtures/requests/continue.json, tests/fixtures/requests/continue-brief.json, … → entries.jsonl:13
- 2026-11-07 19:23 · A3-03 · passes: lib/requests.sh (harness requests): flock on requests/.lock, *.json oldest by mtime then name, each judged by requests.mjs validate, claimed into done/<id>.request.json, run as one argv call (answer; queue add --continue [--brief] then queue start outside 03:15–04:30), result written to a temp name and renamed, one log line; rest to rejected/. bin/harness dispatch and header.; tests 1876 → 1887; files lib/requests.sh, bin/harness, tests/checks/request-files.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt → entries.jsonl:14
- 2026-11-07 19:29 · A3-04 · passes: Shipped systemd/harness-requests.path (PathExistsGlob=%h/.local/state/harness/requests/*.json) and .service (oneshot, ExecStart the live bin/harness requests); 3 checks in request-files.sh (unit lines, systemd-analyze --user verify on copies pointed at this checkout, no XDG_CONFIG_HOME/systemd); decision 2026-10-22-request-inbox; README Steering paragraph with install; architecture §3/§4/§7.; tests 1053 → 1056; files systemd/harness-requests.path, systemd/harness-requests.service, tests/checks/request-files.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, … → entries.jsonl:15

_11 items left out at 8192 bytes: entries.jsonl has them all._
