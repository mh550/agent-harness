<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-07-3` (agent-harness)

What this file is: the run's journal, rendered by the harness from `entries.jsonl`, newest entry first (the 15 newest in full; every entry is in `progress-archive.md`). Each entry is one session: its feature, outcome, summary, what it tried, what it found.

The run builds A1–A4 of `docs/specs/2026-10-22-n8n-events.md`, four milestones in series: **A1** `notify` learns `kind=`/`feature=` and, with `EVENT_URL` set, POSTs a v1 event for park, needs_michael, blocked and debrief through the stub curl, ntfy as the fallback; **A2** the debrief's gatherer moves into `lib/context.sh`, `harness context` writes a bundle (context.md with an ID glossary by `lib/glossary.mjs`, context.json) that a routed event points at; **A3** `harness requests` turns n8n's request files (`answer`, `continue`) into `harness answer` and `harness queue add --continue`, under a systemd path unit Michael installs; **A4** the docs and the live checklist. Inert unless `EVENT_URL` or the request inbox is configured; never a real HTTP request.

How to read the feature list: `feature_list.json` is in priority order; a feature runs when it isn't passing and its `after` all pass. Each milestone's plan feature writes `docs/plans/2026-11-07-A<n>-….md`; A2 and A3 end in a review feature, A1's review is folded into A1-03, A4 is one docs feature. When every feature of a milestone passes the harness verifies it and merges it into `main` (`MERGE_POLICY=auto`).

How to steer: edit `INBOX.md` in this directory from the phone or `harness answer`. A line `status: stop <why>` or `status: pause` on top stops or pauses the run; answers to questions go under `## Answers`; a brief under the steering comment changes scope for the next session. Open questions are listed under the entries that asked them and in `harness needs`.

### 2026-11-07 19:23 · A3-03 · passes

lib/requests.sh (harness requests): flock on requests/.lock, *.json oldest by mtime then name, each judged by requests.mjs validate, claimed into done/<id>.request.json, run as one argv call (answer; queue add --continue [--brief] then queue start outside 03:15–04:30), result written to a temp name and renamed, one log line; rest to rejected/. bin/harness dispatch and header.

- **Files:** lib/requests.sh, bin/harness, tests/checks/request-files.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt
- **Verified:** request-files.sh written first: 0/11 red, then 11/11 (5.5 s, fast tier); bash tests/run.sh request-files queue-view 24/24; xtrace 13/13; fast tier 1053/1053 (check.sh --fast green in 119 s); bash -n lib/requests.sh bin/harness; grep -c 'eval\|bash -c' lib/requests.sh prints 0.
- **Tests:** 1876 → 1887
- **Dead end:** node -e 'import(process.argv[1])' "$MJS" for BACKUP_REFUSAL — requests.mjs's isMain sees argv[1] as itself and runs its CLI (usage error): the path goes in by env (M=$MJS) instead
- **Dead end:** a bare wait for the two lock-contending calls — status_stubs' live driver (sleep 600) is a job of the check's shell: wait on the two pids
- **Discovery** (affects project): Every executable lib/*.sh needs the xtrace guard line ([[ -z ${HARNESS_XTRACE:-} ]] || source …/xtrace.sh) once, or xtrace.sh's guard check fails (agent-harness-2026-11-07-3 2026-11-07)
- **Discovery** (affects project): wait_for runs a command, not a string: a negation or variables go through wait_for <s> eval '<expr>' (agent-harness-2026-11-07-3 2026-11-07)
- **Discovery** (affects A3-04, A3-05): requests.sh writes no result when done/<name>.json exists (a duplicate, or a bad file named for a done id): only the log line; a symlink is moved unread and gets 'the request is not a regular file'
- **Discovery** (affects A3-04): requests.sh's checks are tests/checks/request-files.sh (11 names, fast, 5.5 s); A3-04's unit checks go in the same file
- **Proposed change:** A3-03 step 3 asks the duplicate for a result with ok == false; the plan (§1.3) keeps the first result byte-identical and moves the duplicate to rejected/ with a refused log line, which is what was built and checked
- **Proposed change:** A3-03 step 5 and A3-04 step 4 should read `bash tests/run.sh request-files …` (the plan's name; requests-inbox.sh fails the name lint)
- *11-A3-03 · claude-opus-5-5*

### 2026-11-07 19:13 · A3-02 · passes

lib/requests.mjs: validateRequest (the plan's 11 rules in order, exact reasons; id/verb/run set only once validated), inBackupWindow + BACKUP_REFUSAL, resultJson (ten keys, output cut at 2000 bytes on a char boundary), resultName, logLine (takes no text), and validate/result CLIs. 19 unit tests, fixtures made by n8n-home's buildRequest at 859b25a.

- **Files:** lib/requests.mjs, tests/unit/requests.test.mjs, tests/fixtures/requests/answer.json, tests/fixtures/requests/continue.json, tests/fixtures/requests/continue-brief.json, tests/fixtures/requests/README.md, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt
- **Verified:** Red first (ERR_MODULE_NOT_FOUND), then node --test tests/unit/requests.test.mjs 19/19; all units 534/534; bash tests/run.sh unit-tier 535/535; check.sh --fast green, 1042 tests (1023 before). node --check lib/requests.mjs.
- **Tests:** 1857 → 1876
- **Discovery** (affects A3-03): requests.mjs result --id - prints no result JSON and only appends the log line (a request with no usable name); for a duplicate, bash ignores result's stdout so done/<id>.json stays the first's
- **Discovery** (affects A3-03): validate's done set reads <done>/*.json names, stripping .request.json or .json, so a claim counts; window is judged at --now in the process's TZ; text/brief land in --out only for verdict ok
- **Discovery** (affects A3-03, A3-05): Request fixtures come from n8n-home's buildRequest (tests/fixtures/requests/README.md holds the generator): change a value with jq, never hand-type a shape
- **Proposed change:** A3-02 step 1 lists 18 named cases; the plan's §1.5 result CLI got a 19th unit test (the result CLI prints the JSON and appends the log line, none for --id -).
- *10-A3-02 · claude-opus-5-5*

### 2026-11-07 19:07 · A3-01 · passes

Wrote docs/plans/2026-11-07-A3-request-inbox.md: requests.mjs's validation table with exact reason strings, result JSON, log line and CLI; harness requests' pass (flock, order, claim-then-run, argv calls, backup window, real-clock grace); the runner start seen through gc-tmux's tmux shim; both units (verified with systemd-analyze here); 29 checks named with tiers.

- **Files:** docs/plans/2026-11-07-A3-request-inbox.md
- **Verified:** fast tier green (check.sh --fast: cached, 1857 tests; the plan is outside the key). Drafted units passed systemd-analyze --user verify (exit 0; a bad ExecStart exits 1). The name lint loop flagged requests-inbox vs inbox; request-files clean. n8n-home 859b25a read for D25, buildRequest and renderResult.
- **Tests:** 1857 → 1857
- **Dead end:** tests/checks/requests-inbox.sh as the steps name it — suite-runner.sh's name lint fails it: inbox.sh's name is part of it
- **Dead end:** DirectoryNotEmpty= on requests/ — done/, rejected/, requests.log, .lock keep it true: systemd restarts the service at once, 5 starts in 10 s fail the path unit (systemd.path(5))
- **Discovery** (affects project): A check file name may not hold or sit inside another (suite-runner.sh namelint): requests-inbox.sh fails on inbox.sh (agent-harness-2026-11-07-3 2026-11-07)
- **Discovery** (affects A3-02, A3-03, A3-05): n8n writes requests/<id>.json in one write, no rename (its D25); answer 1-<h> before continue 2-<h>; its card needs a string result id
- **Discovery** (affects A3-03, A3-04, A3-05): The check file is tests/checks/request-files.sh (the plan's intro); runner start is seen via gc-tmux.sh's tmux shim with HARNESS_NO_RUNNER unset (plan 2.5)
- **Discovery** (affects A3-03, A3-05): A duplicate id keeps the first done/<id>.json as it is and goes to rejected/ (plan 1.3), not A3-03 step 3 ok==false result
- **Discovery** (affects A3-03, A3-04): systemd: a path unit restarts its service at once while the glob holds; 5 starts in 10 s fail it. One call waits out a young file (plan 2.4)
- **Question for Michael:** A duplicate request id (default): moved to requests/rejected/, the first result left as it is, a refused log line; no second result. Keep, or write the duplicate's refusal somewhere n8n reads? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-0/docs/plans/2026-11-07-A3-request-inbox.md:101
- **Question for Michael:** A rejected request's result has exit: null (default: no command ran; n8n's card shows refused first). Keep null, or an integer like 2? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-0/docs/plans/2026-11-07-A3-request-inbox.md:101
- **Proposed change:** A3-03 steps 1-5 and A3-04 steps 1 and 4: tests/checks/requests-inbox.sh -> tests/checks/request-files.sh (the name lint, suite-runner.sh:207); step 5's command is bash tests/run.sh request-files queue-view
- **Proposed change:** A3-03 step 3: the duplicate id ends in rejected/ with done/req-0001-aaaa.json unchanged (cmp), not a second ok==false result
- **Proposed change:** A3-04 step 1: PathExistsGlob= only (DirectoryNotEmpty= loops on done/); A3-01 step 4's Environment=PATH= with node's directory is PATH without nvm, lib/requests.sh sourcing nvm.sh as lib/debrief.sh does
- *09-A3-01 · claude-opus-5-5*

### 2026-11-07 18:55 · verify A2 · passes

All 5 A2 features hold. Full suite 1857/1857, fast 1023/1023, context-bundle/event-run/queue-debrief/flakes-run green. Independent diff: origin/main's debrief --dry-run context equals the branch's but the appended ## Glossary. Glossary CLI on fixtures resolves D24 (2 files, newest first), N1-01, M8, D-H1; Q99 unresolved. dj checkout clean.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| A2-01 | 1 | read docs/plans/2026-11-07-A2-context-bundle.md §1-§3 | §1 A2-02 (glossary.mjs, fixtures, unit tier fast), §2 A2-03 (context.sh, context.mjs, bin/harness, context-bundle.sh fast by the 30 s rule), §3 A2-04 (context.json, retention, notify hook; event-run slow); each names files and checks first | yes |
| A2-01 | 2 | read docs/plans/2026-11-07-A2-context-bundle.md §1.3 fixture table | lists feature_list.json from dj .harness/runs/dj-2026-10-17 (desc cut 300), docs/decisions.md D1/D24/D36 rows, park inbox.md, text.md with D24 N1-01 M8 D-H1 Q99, provenance in tests/fixtures/glossary/README.md, D-H1 against ### D-H1 · heading, and each ID's resolution | yes |
| A2-01 | 3 | read docs/plans/2026-11-07-A2-context-bundle.md §1.1-1.2 | spec regexes verbatim (features, milestones not followed by -\d, D\d+/D-H\d+ before milestones), sources in order, 300 chars stripped, newest file first, source <path>:<line>, never guessed; exports findIds resolveIds glossaryMarkdown strip fsReader | yes |
| A2-01 | 4 | read docs/plans/2026-11-07-A2-context-bundle.md §2.1 | line table moving alive, rec_dir, fence, capped, run_context, rate_info, spend, names, the { … } > $CTX block and CMAX cut into context_runs; caller provides STATE_ROOT Q H LEDGER SINCE CTX WS F MET; glossary kept apart; check (b) diffs dry-run vs --since with glossary cut | yes |
| A2-01 | 5 | read docs/plans/2026-11-07-A2-context-bundle.md §2.2, §3.1-3.4 | CLI with header lines, default out <STATE_ROOT>/events/<id>/, no harness report; context.json block with every spec key; built by lib/context.mjs; 30-day retention on write with touch -d check; notify_event bundle before the POST, context its path, null + note on failure | yes |
| A2-01 | 6 | bash tests/run.sh --tier fast | 1023/1023 checks passed (wall 120.7 s); harness init full suite 1857/1857, 0 FAIL | yes |
| A2-02 | 1 | node --test --test-isolation=none tests/unit/*.test.mjs; read tests/unit/glossary.test.mjs; LC_ALL=C sort -c on both name lists | 515/515 pass; 18 glossary.mjs tests assert findIds order 'N1-01 D24 D-H1 M8 Q99' with kinds, no N1/H1, D24 row text 300 chars at docs/decisions.md:18, N1-01 desc + ' (milestone N1)', M8 two headings newest first, D-H1 heading, D24 two files order swaps with mtimes, D1 decision+milestone, Q99 unresolved, markdown lines; all 18 in both lists, sorted | yes |
| A2-02 | 2 | diff fixtures vs git -C ~/projects/dj-crate-streaming show 38ef992:docs/decisions.md / 385d31c:README.md, architecture.md; git status --porcelain there | decisions.md and README.md fixtures byte-equal to the cited lines; architecture.md equal but one blank separator line; README.md has a provenance line per fixture; dj status empty (clean, as the session's before-file) | yes |
| A2-02 | 3 | head lib/glossary.mjs; grep ^export; node --check; node lib/glossary.mjs tests/fixtures/glossary/wt …/feature_list.json < text.md; grep jq -n in lib bin | usage header; exports findIds resolveIds glossaryMarkdown strip knownIds fsReader main; check ok; CLI prints {glossary:[N1-01,D24×2 newest first,D-H1,M8×2], unresolved:[Q99]}; no bash builds glossary JSON | yes |
| A2-02 | 4 | node --test --test-isolation=none tests/unit/*.test.mjs; bash tests/run.sh unit-tier | 515/515 pass, 0 fail; bash tests/run.sh unit-tier: 515/515 then 516/516 checks passed | yes |
| A2-02 | 5 | bash tests/run.sh --tier fast | 1023/1023 checks passed (wall 120.7 s); harness init full suite 1857/1857, 0 FAIL | yes |
| A2-03 | 1 | read tests/checks/context-bundle.sh; independent script: status_stubs, last-debrief at(11000), origin/main's (6849e17, git archive) harness debrief --dry-run vs this branch's, diff with line 1 and ## Glossary cut | checks pin the parked section equal to the debrief's, D24/N1-01/M8/D-H1 lines + Unresolved Q99, --since body diff empty, find -newer summary.json empty, nosuch exit 1 'no run', no arg usage exit 2; my diff old vs new: identical but the blank line before ## Glossary | yes |
| A2-03 | 2 | head lib/context.sh; grep functions; grep -c '^run_context()' lib/debrief.sh; bash -n lib/context.sh lib/debrief.sh bin/harness | usage header; alive rec_dir context_since fence capped ended_of run_context rate_info spend names context_runs context_glossary in context.sh; debrief count 0, it sources context.sh and calls context_runs/context_glossary; bash -n ok | yes |
| A2-03 | 3 | grep bin/harness header and dispatch | header lines 49-54 `harness context <run-id> \| --since <YYYY-MM-DD HH:MM:SS> [--out <dir>]`, read-only, writes, default <state>/events/<uuid>/, prints dir; line 900 `context) shift; exec lib/context.sh`; check (e) asserts the uuid dir on stdout | yes |
| A2-03 | 4 | bash tests/run.sh context-bundle event-run queue-debrief flakes-run | 107/107 checks passed: context-bundle 13/13 (fast, 12.2 s), flakes-run 9/9, event-run 12/12, queue-debrief 72/72; all names in check-names.txt (LC_ALL=C sorted), context-bundle's in check-names-fast.txt too | yes |
| A2-03 | 5 | bash tests/run.sh --tier fast | 1023/1023 checks passed (wall 120.7 s); harness init full suite 1857/1857, 0 FAIL | yes |
| A2-04 | 1 | read context-bundle.sh 'context.json has the spec's shape…', '--since names its time', 'summary…or null', 'open_questions…'; grep -c 'jq -n' lib/context.sh | the step's jq -e verbatim on $T/b1/context.json, scope.since == at(11000) and 3 runs as Covers, givenup summary equals its summary.json and others null, open_questions[0] the B INBOX text; grep prints 0; all PASS in my subset run | yes |
| A2-04 | 2 | read context-bundle.sh retention check and event-run.sh 'the hook notes the old bundles it removed' | events/old (touch -d '31 days ago') gone, recent kept, b3.out line 2 'events: removed 1 bundle older than 30 days'; event-run: events/stale gone and hlog evp has the line; both PASS | yes |
| A2-04 | 3 | read tests/checks/event-run.sh lines 18-51, 80-88; ran in subset | STUB_CURL_SPY records test -f context(.json) and test -f context.md beside it ('park evp 0 0 <path>'; the step's second test names the same file, context.md is the stronger check), scope.runs [evp], parked question in open_questions, event.json beside; debrief scope.runs == Covers runs; HARNESS_CONTEXT=false → context null + note; 12/12 PASS | yes |
| A2-04 | 4 | read lib/notify.sh notify_event; grep report; bash -n lib/notify.sh lib/context.sh lib/debrief.sh; node --check lib/notify.mjs lib/context.mjs lib/glossary.mjs | bundle (timeout 60 context.sh <RUN_ID> --out events/<id> --id) before the curl POST, only in the routed branch (EVENT_URL set); no harness report; the debrief now passes bundle="$WS" (context.sh --from its own gather, A2-05's I1) instead of --since, scope still the debrief's runs and since; syntax ok | yes |
| A2-04 | 5 | read journal/decisions/2026-10-22-context-bundle-glossary.md; grep docs/architecture.md §3/§4, README ## Debrief | decision: title, provenance, finding, choice (place, shape, glossary by code, no store, 30-day retention and synchronous bundle *default*), rejected (model glossary, store, n8n-built); architecture §3 rows lib/context.sh, context.mjs, glossary.mjs, §4 events/<id>/ row with retention, bin/harness command list has context; README Debrief paragraph line 382 | yes |
| A2-04 | 6 | bash tests/run.sh context-bundle event-run queue-debrief flakes-run | 107/107 checks passed: context-bundle 13/13 (fast, 12.2 s), flakes-run 9/9, event-run 12/12, queue-debrief 72/72; all names in check-names.txt (LC_ALL=C sorted), context-bundle's in check-names-fast.txt too | yes |
| A2-04 | 7 | bash tests/run.sh --tier fast | 1023/1023 checks passed (wall 120.7 s); harness init full suite 1857/1857, 0 FAIL | yes |
| A2-05 | 1 | ls scratch A2.diff; read docs/plans/2026-11-07-A2-review.md | one round, 0 Critical/2 Important/6 Minor, each with file:line and what was done; the four hard questions answered with lines (bytes, unresolved/no near match, bundle can't fail notify, nothing outside out dir); my own origin/main-vs-branch dry-run diff agrees on bytes | yes |
| A2-05 | 2 | read review I1/I2 fixes and their checks in event-run.sh/context-bundle.sh; bash -n, node --check on A2's files | I1: 'the debrief event's bundle is the context its note was written from' (cmp, id); I2: 'the debrief's context says a finishing run is still running, as before the move' and 'a bundle says how a finishing run ended'; all PASS; red phase not re-observed (commit history); syntax ok | yes |
| A2-05 | 3 | read the decision file | finding; choice: dir and files, context.json keys in order (v first), regexes and sources in order, newest first, unresolved, 30-day retention, bundle before POST, failure note; defaults marked *default*; rejected: model glossary, glossary store, n8n-built bundle | yes |
| A2-05 | 4 | grep docs/architecture.md (§3, §4, §16 line 831, bin/harness row) and README.md (Debrief 382, Events row 207) against bin/harness header | §3 rows for context.sh/glossary.mjs, §4 events/<id>/, §16 names context_runs, command list includes context; README paragraph and Events state row; wording matches bin/harness's usage lines | yes |
| A2-05 | 5 | the harness's full check.sh run at init (cache cleared), output check-7703f1ecd314e470.out | 1857/1857 checks passed, 0 FAIL, wall 706.3 s; my fast tier 1023/1023 and subset all green | yes |

- **Discovery** (affects project): Verify can check the gatherer's move against main directly: git archive origin/main into scratch, run its bin/harness debrief --dry-run and the branch's on one status_stubs state, diff with line 1 and ## Glossary cut (context-bundle's own (b) compares two callers of the same function).
- *184954-verify-A2 · claude-opus-5-5*

### 2026-11-07 18:38 · A2-05 · passes

A2 review (one Opus round): 0 Critical, 2 Important, 6 Minor. Fixed RED→GREEN: I1 the debrief event's bundle is now the debrief's own (context.json from its gather, copied by context.sh --from via notify bundle=); I2 the debrief's ended words are alive-first again (ended_of; CTX_ENDED_FIRST for harness context). Minor fixed: dotted ids, spend, queue/done. Review file, decision, docs.

- **Files:** lib/context.sh, lib/debrief.sh, lib/notify.sh, lib/glossary.mjs, bin/harness, tests/checks/context-bundle.sh, tests/checks/event-run.sh, tests/unit/glossary.test.mjs, tests/stub-context.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt, docs/plans/2026-11-07-A2-review.md, +4 more
- **Verified:** Full suite: check.sh green in 720 s, 1857 tests (N = M). Fast tier: green in 118 s, 1023 tests, run before the full suite with no edits after. Unit tests: node --test, 515 pass. RED then GREEN, each check watched failing first: context-bundle 11/13 (the queue/done and still-running checks red, then 13/13), event-run 11/12 (the debrief bundle cmp red, then 12/12), the dotted-id unit test red, then 515/515. bash -n and node --check clean on every file touched.
- **Tests:** 1853 → 1857
- **Dead end:** an event-run check counting `# Context ·` bundles against routed events — fragile across the file's runs (stale and stub bundles); a cmp of the debrief's context.md with the bundle's says it directly
- **Discovery** (affects A3, A4): The debrief's bundle is its own gather's (context.json in its workspace, copied by context.sh --from); notify's since= is gone, bundle=<dir> replaces it
- **Discovery** (affects A3, A4): lib/context.sh ended_of: alive first (the debrief's bytes); CTX_ENDED_FIRST=1 (harness context only) reads ended first for the end event's bundle
- **Discovery** (affects project): harness queue list/show no longer mkdir queue/done (cmd_queue makes it only for a write) (agent-harness-2026-11-07-3 2026-11-07)
- **Resolved:** Discovery (A2-04, affects A2-05): The debrief's bundle reruns context_since at notify time, so a run started during the debrief's session is in scope.runs but not in the note's Covers (accepted, review finding 6).
- **Resolved:** Discovery (A2-03, affects A2-05): harness context writes $STATE_ROOT/queue/done (an empty dir) when there is no queue yet: cmd_queue mkdirs before list; context-bundle (c) finds files only (! -type d)
- **Proposed change:** M1: lib/lane.sh:535 commits any dirty record after notify_park as 'HARNESS: park notification failed', including a routed park's 'events: removed' note; name it 'HARNESS: park notification notes' and change park-desk's assertion with it
- **Proposed change:** M6: a CONTEXT_TIMEOUT config value and the bundle's exit code in the 'context bundle failed' note, if a real bundle nears the 60 s cap
- *08-A2-05 · claude-opus-5-5*

### 2026-11-07 18:05 · A2-04 · passes

context.json (spec key order) now comes from the same lib/context.mjs call as context.md; a bundle written in events/ prunes bundles with no file newer than 30 days and says so; notify_event writes the bundle to events/<id>/ before the POST, so context names an existing context.json; the debrief passes since=$SINCE. A failed bundle: a note, context null. Decision file, docs.

- **Files:** lib/context.mjs, lib/context.sh, lib/notify.sh, lib/notify.mjs, lib/debrief.sh, tests/checks/context-bundle.sh, tests/checks/event-run.sh, tests/checks/event-hook.sh, tests/stub-context.sh, tests/fixtures/context-bundle.json, tests/unit/context.test.mjs, tests/unit/notify.test.mjs, +5 more
- **Verified:** Each new check watched red on the old lib (reverted with a patch file), then green: context-bundle 11/11, event-run 11/11, event-hook 11/11, queue-debrief 72/72, flakes-run 9/9, unit tier 515/515; check.sh --fast green, 1020 tests; bash -n and node --check clean; grep -c 'jq -n' lib/context.sh = 0.
- **Tests:** 1839 → 1853
- **Dead end:** parked[].why from the needs item's .why, as the plan said — a real `harness needs parked --json` has no top-level why; it comes from <state>/parked.json, else the card headline
- **Discovery** (affects A2-05): The event-run check's spy compares context.md beside context.json, not the plan's second `test -f context.json` (the same file twice).
- **Discovery** (affects A2-05, run): run_context and context_glossary now read <state>/ended before alive: the driver writes ended (driver.sh:352) before its end notify, while still alive.
- **Discovery** (affects A2-05): The debrief's bundle reruns context_since at notify time, so a run started during the debrief's session is in scope.runs but not in the note's Covers (accepted, review finding 6).
- **Discovery** (affects A2-05): A glossary exception now costs context.json too (one node call, as the spec says). For the debrief that means a null context, so ntfy (review finding 5, accepted).
- **Discovery** (affects A2-05, A4): notify_event's ctx is the directory context.sh prints (cd && pwd), so a trailing-slash HARNESS_STATE never gives n8n a // path (its contextPaths guard).
- **Discovery** (affects project): A bundle runs the gatherer (harness status/needs/trends/queue): each routed event in a stub run costs ~1 s more; event-run.sh takes 39 s
- **Question for Michael:** Default taken: a routed event's context bundle is synchronous, capped at 60 s, before the 5 s POST, and events/ bundles older than 30 days are removed when a new one is written. Keep both? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/journal/decisions/2026-10-22-context-bundle-glossary.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/lib/notify.sh:55
- **Proposed change:** A2-04 step 3: the spy's second test should be `test -f <context dir>/context.md` (n8n reads it beside context.json); `test -f <context dir>/context.json` repeats the first.
- *07-A2-04 · claude-opus-5-5*

### 2026-11-07 17:33 · A2-03 · passes

Moved the debrief's gatherer verbatim into lib/context.sh (context_since, context_runs, context_glossary); debrief.sh sources it, no copy. New `harness context <run> | --since <ts> [--out] [--id]` writes context.md (gatherer + ## Glossary via new lib/context.mjs) to events/<uuid>/ by default. The debrief's context gains the glossary. Tests 1831 → 1839.

- **Files:** lib/context.sh, lib/context.mjs, lib/debrief.sh, bin/harness, tests/checks/context-bundle.sh, tests/unit/context.test.mjs, tests/checks/status-card.sh, tests/checks/needs-questions.sh, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt
- **Verified:** Bytes: in one status_stubs throwaway, the saved pre-move debrief.sh and the new one, --dry-run, two windows x CMAX 150000/8000/3000: `diff <(sed '1d; /^## Glossary$/,$d' old) <(same new)` is one blank line (the glossary's separator) in all 6. context-bundle 6/6 red then green; context-bundle+queue-debrief+flakes-run 88/88; needs-questions 21/21; status-card 15/15; unit-tier 511/511; check.sh --fast green, 1011 tests. Opus review: 0 Critical/Important, 6 Minor, 5 fixed.
- **Tests:** 1831 → 1839
- **Dead end:** `${CTX_SINCE_WHY:-the queue runner's start}` inside the moved double-quoted echo — the apostrophe in a ${:-} default parses as a quote inside a function body (bash -n: syntax error); a local `why` variable carries the default
- **Dead end:** runSection ending at any `##`/`###` line — the fenced INBOX.md has `### B:` and `## Answers` headings of its own; it now skips ~~~ fences and also stops at every run's known heading (a part cut mid-fence leaves an odd ~~~)
- **Discovery** (affects A2-04): context.sh: context_glossary writes $WS/runs.tsv (state, run, project, ended, running, features, record, worktree, docs root, needs json) and $WS/needs-<i>.json for A2-04's context.json; context.mjs parseRow reads it
- **Discovery** (affects A2-04, A2-05): glossaryMarkdown's cut line says 'context.json lists every one', but the debrief's own context dir never gets a context.json: reword it or write one there
- **Discovery** (affects A2-05): harness context writes $STATE_ROOT/queue/done (an empty dir) when there is no queue yet: cmd_queue mkdirs before list; context-bundle (c) finds files only (! -type d)
- **Discovery** (affects A2-04, A2-05): status_stubs's run ids A/B/C are matched as the run's own feature ids (knownIds), so a bare English 'A' resolves to feature A in stub glossaries; real ids (N1-01) don't collide
- **Discovery** (affects A2-05): capped's cut note names $WS/s.json; in a `harness context` bundle that scratch is removed on exit, so the note's path is gone (debrief bytes kept as they were)
- **Discovery** (affects project): bash: an apostrophe in a ${v:-default} inside a double-quoted string fails to parse in a function body; put the default in a variable (agent-harness-2026-11-07-3 2026-11-07)
- **Proposed change:** A2-05's review should name the queue/done mkdir (cmd_queue) and the glossary cut line's context.json wording as its two leftover Minor findings from A2-03's review
- *06-A2-03 · claude-opus-5-5*

### 2026-11-07 17:06 · A2-02 · passes

lib/glossary.mjs: findIds (the list's own ids, then three masking passes), resolveIds (feature list; doc rows and headings newest file first; unresolved never guessed), glossaryMarkdown (byte cap, whole lines), strip, knownIds, fsReader and a CLI; 17 unit tests on fixtures copied read-only from dj-crate-streaming; tests 1814 → 1831.

- **Files:** lib/glossary.mjs, tests/unit/glossary.test.mjs, tests/fixtures/glossary/, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt
- **Verified:** red first (module missing; then 2 review tests red), node --test glossary.test.mjs 17/17; bash tests/run.sh unit-tier 509/509; fast tier green 1003; node --check; CLI on the real dj checkout: 24 entries in 0.1 s, D-H1, Q99, I3 unresolved; dj git status --porcelain unchanged. Opus review: 2 Important (non-array features threw; D pass split a known S2-D1) and 9 Minor fixed (fences, spaced ranges, M8.1, empty ids, vanished files, absolute store, readStdin); strip of [a](x/(y)) and __init__ left.
- **Tests:** 1814 → 1831
- **Discovery** (affects A2-03, A2-04): glossary.mjs resolveIds takes featureList {path,text} and a reader {root, files()→[{path,mtimeMs,titleOnly}], read()}; fsReader(root,{mtimes}) is the fs one; knownIds(list) feeds findIds
- **Discovery** (affects A2-05): Glossary refinements of the plan: D<n>-<digit> is a feature; a heading names an ID only before end/punctuation/a separator (not `## D24 on`, `## D1 – D23`, `## M8.1`); known ids go first
- **Question for Michael:** The session's `git push -u origin harness-lane/agent-harness-2026-11-07-3/A2` was denied by the auto-mode classifier (Out-of-Place Publication); commit 62c1210 is local only. Should lane sessions be allowed that push, or does the harness push the lane branch itself? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/lib/glossary.mjs
- **Proposed change:** A2-05's decision file should name the three glossary refinements above (D1-01 a feature, the heading's follower rule, the section number stripped) as *default*
- *05-A2-02 · claude-opus-5-5*

### 2026-11-07 16:54 · A2-01 · passes

Wrote docs/plans/2026-11-07-A2-context-bundle.md: glossary rules verbatim and how glossary.mjs applies them, dj fixtures with provenance, the line-by-line move of debrief.sh's gatherer into context.sh, harness context's CLI, context.json's shape, 30-day retention, the hook's bundle before the POST, all checks named with tiers.

- **Files:** docs/plans/2026-11-07-A2-context-bundle.md
- **Verified:** Plan only; fast tier green (check.sh --fast: cached green for this code tree, 1814 tests; docs/plans is outside the key). Line refs checked against lib/debrief.sh, lib/notify.sh, dj at 429dd96 and n8n-home's lib/intake.js.
- **Tests:** 1814 → 1814
- **Discovery** (affects A2-04): n8n-home's intake (lib/intake.js contextPaths) needs event.context = absolute <STATE_ROOT>/events/<dir>/context.json, dir = the event id (^[A-Za-z0-9-]{8,64}$); context.md beside it
- **Discovery** (affects A2-04, run): n8n-home's intake refuses a debrief event whose context isn't a string, so A1's debrief event (context null) always falls back to ntfy until A2-04
- **Discovery** (affects A2-04): event-hook.sh (c),(d),(k) compare the whole note file: A2-04 sets HARNESS_CONTEXT to a stub there, or the 'context bundle failed' note turns them red
- **Discovery** (affects A2-03): queue-debrief.sh 'the whole context is capped too' asserts <= CMAX bytes: the debrief's glossary gets only the bytes the gatherer left (--max-bytes)
- **Discovery** (affects A2-02): The spec's regexes miss dj ids N1F-01, S2-05a, S2-R1: the plan adds exact matches of the feature list's own ids (known) as a default
- **Discovery** (affects A2-04): status_stubs pins HARNESS_NOW in the past: events/ retention must use the real clock, or touch -d '31 days ago' reads as recent
- **Question for Michael:** Default taken: the glossary also matches exact ids from the run's feature list that the spec's regexes miss (dj's N1F-01, S2-05a, S2-R1, N1F). Keep that, or stick to the spec's regexes only? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/docs/plans/2026-11-07-A2-context-bundle.md:60
- **Question for Michael:** Default taken: the debrief's own context also ends with the ## Glossary section, so its session reads the IDs explained (within the context cap). Keep it, or keep the glossary in harness context bundles only? Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-1/docs/plans/2026-11-07-A2-context-bundle.md
- *04-A2-01 · claude-opus-5-5*

### 2026-11-07 16:40 · verify A1 · passes

A1-01..03 hold. Full suite green at init (690 s, 1814); fast tier 986/986; event-run/event-hook/park-desk/needs-driver/queue-debrief 165/165; event-hook+unit-tier 503/503; notify-body-cap/origin-outage/needs-record 45/45. Mutation: pre-A1 notify turns 7/11 event-hook + 5/6 unit red; pre-A1-03 call sites turn 4/6 event-run red. Real curl 8.5.0 loopback matches the fixtures.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| A1-01 | 1 | cat docs/plans/2026-11-07-A1-event-hook.md | §2 A1-02 (notify.mjs, notify.sh, config, stub-curl; checks §2.5 with tiers: unit fast, event-hook.sh fast) and §3 A1-03 (call sites, event-run.sh slow, decision, docs, review §3.4); files and tiers named | yes |
| A1-01 | 2 | plan §1 table vs jq -r 'keys_unsorted\|join(" ")' tests/fixtures/n8n-event-v1.json | same 13 keys in order v..context; id randomUUID, at ISO, project PROJECT_NAME, run RUN_ID, feature or null, priority "" stays, click/actions null, context null in A1; debrief nulls project/run/feature | yes |
| A1-01 | 3 | plan §2.2-2.4 | POST verbatim with ${HARNESS_CURL:-curl}, Content-Type json, --max-time $EVENT_TIMEOUT, no --retry, no Authorization, -w '%{http_code}' chosen; both lines verbatim (log; note or log as debrief.sh); STUB_EVENT 200/500/timeout knobs and fixtures from real curl 8.5.0 (plan's timeout stderr line later found absent under -s, corrected in A1-02; my loopback rerun: 200/0/'200', 500/0/'500', hang/28/'000', no stderr) | yes |
| A1-01 | 4 | plan §3.1 table vs grep -n 'notify "' lib/*.sh bin/harness | every call mapped: notify_park park, needs_you and merge_refused needs_michael, run end blocked/ended by ehigh, started, paused, deploy guard other, verified, merged, limit, debrief headline debrief, fail() other, desk other, continue-refused other; needs_notify forwards "$@" (no change) | yes |
| A1-01 | 5 | grep -ln 'curl_\\|notify-cmd' tests/checks/*.sh vs plan §4 | 11 pre-existing files all listed 'stays' (12th hit is the new event-run.sh); new checks named in event-hook.sh, event-run.sh, tests/unit/notify.test.mjs; storage <STATE_ROOT>/events/<id>/event.json, retention A2 | yes |
| A1-01 | 6 | bash tests/run.sh --tier fast | 986/986 checks passed, wall 115 s; init full suite green 1814 | yes |
| A1-02 | 1 | node --test ... tests/unit/notify.test.mjs (6 'notify.mjs event:' tests read); same tests against 8e05980's notify.mjs in a scratch copy; LC_ALL=C sort -c both name files | tests assert Object.keys join == fixture keys, v 1, uuid regex, Date.parse, nulls and "", debrief nulls, CLI one line; green in unit-tier 503/503, 5/6 red on pre-A1 notify.mjs; names in check-names.txt and -fast.txt, both sorted; CLI by hand prints the v1 JSON | yes |
| A1-02 | 2 | read tests/checks/event-hook.sh; bash tests/run.sh event-hook; same file against 8e05980's lib/notify.sh | line 2 '# tier: fast', sourced notify with NTFY_TOKEN=tok-secret-123; cases a-k assert one ntfy call, one POST with Content-Type/jq -e v1 park B/no Authorization/no token/no ntfy URL/log line, 500 and timeout diff-equal fallbacks with exact notes, ended and no-kind ntfy only, rc 0, kept event == posted, fields equal; 11/11 green, 7/11 red on pre-A1 code | yes |
| A1-02 | 3 | grep -n EVENT lib/config.sh templates/user/config.sh; grep -c EVENT_URL ... | config.sh:71 EVENT_URL="" EVENT_TIMEOUT=5 beside NTFY_URL with one comment; template lines 9-10 commented under Notifications; counts 1 and 1 | yes |
| A1-02 | 4 | git diff 8e05980 HEAD -- lib/notify.sh; bash -n lib/notify.sh; node --check lib/notify.mjs | kind=/feature= parsed (default other); only park\|needs_michael\|blocked\|debrief with EVENT_URL call notify_event via ask notify.mjs event; kept at events/<id>/event.json; POST --max-time EVENT_TIMEOUT, no retry/token; 2xx logs and returns 0 before ntfy/NOTIFY_CMD; else note and ntfy branch unchanged (diff shows it untouched); header names fields and routing; syntax ok | yes |
| A1-02 | 5 | cat tests/stub-curl.sh, cat -A tests/fixtures/curl-event-*; real curl 8.5.0 on 127.0.0.1:7829; bash tests/run.sh notify-body-cap origin-outage needs-record | Content-Type json call answers STUB_EVENT 200 default/500/timeout exit 28, header names knob and fixtures; fixtures '200','500','000' match my real curl capture (no stderr under -s); STUB_CURL_FAIL path unchanged; 45/45 checks passed | yes |
| A1-02 | 6 | bash tests/run.sh event-hook unit-tier | 503/503 checks passed | yes |
| A1-02 | 7 | bash tests/run.sh --tier fast | 986/986 checks passed | yes |
| A1-03 | 1 | read tests/checks/event-run.sh; bash tests/run.sh event-run ...; event-run against 308c085's call-site files in a scratch copy | line 2 '# tier: slow'; evp run with EVENT_URL appended, stub 200: one park event feature B run evp project proj title '[evp] B needs you' context null, kept, run.log 'event → n8n: park <id>' (grep -F), no ntfy with that title, no 'event hook failed'; green, red without call-site kinds | yes |
| A1-03 | 2 | event-run.sh checks 2 and 3 | STUB_EVENT=500 run: event posted, ntfy Title/Priority/Click/Actions/data compared to kept event.json field by field, harness-log note 'event hook failed (500): park; sent to ntfy'; EVENT_URL-unset run's ntfy record diffed with evf's after run id/timestamp normalisation; both PASS | yes |
| A1-03 | 3 | event-run.sh checks 4-6 | STUB_GIVE_UP=A run posts one blocked event, feature null, title '[evg] ended: blocked on A'; started and a done run's ended reach ntfy only, no started/ended event; harness debrief posts debrief event with null project/run/feature, title 'harness debrief', $HARNESS_STATE/queue/runner.log has 'event → n8n: debrief <id>'; PASS (4 of 6 red without call-site kinds) | yes |
| A1-03 | 4 | grep -n 'kind=' lib/record.sh lib/driver.sh lib/lane.sh lib/debrief.sh lib/desk.sh lib/needs.sh bin/harness; sed -n 18,26p lib/needs.sh; bash -n on each | record.sh:575 park feature=$id, :553 and :1011 needs_michael, :1101 verified, :1106 merged; driver.sh:383-386 ekind blocked when ehigh==1 else ended, :563 started, :598 paused, :518 other; lane.sh:478 limit; debrief.sh:343 debrief, :35 other; desk.sh:150 other; bin/harness:269 other; needs_notify passes "$@" in both branches; no unkinded notify call left; bash -n clean | yes |
| A1-03 | 5 | cat journal/decisions/2026-10-22-event-hook-ntfy-fallback.md; git diff 8e05980 HEAD -- docs/architecture.md README.md | title, provenance (this run, the spec), finding/choice/rejected: four routed kinds, 2xx rule, best-effort synchronous 5 s default, events/ kept; rejected NOTIFY_CMD repoint, retries, routing every kind. architecture §3 notify.sh/notify.mjs event, §4 events row, §7 Event hook fallback guard (token never sent), §10 EVENT_URL/EVENT_TIMEOUT; README ## Steering paragraph (n8n, fallback, unset unchanged) | yes |
| A1-03 | 6 | cat docs/plans/2026-11-07-A1-review.md; A1-03 entry summary | one-round Opus review of the merge-base diff on the three questions; no Critical/Important, six minors each with what was done; my own read of the diff agrees (ntfy branch untouched, notify_event reads no NTFY_TOKEN) | yes |
| A1-03 | 7 | bash tests/run.sh event-run event-hook park-desk needs-driver queue-debrief; grep check-names | 165/165 checks passed (event-run 6, event-hook 11, park-desk 66, queue-debrief 72, needs-driver); 6 event run names in check-names.txt only, 11 event hook names in both, both LC_ALL=C sorted | yes |
| A1-03 | 8 | bash tests/run.sh --tier fast | 986/986 checks passed; full suite at init green 1814 in 690 s | yes |

- **Discovery** (affects project): Real curl 8.5.0 with -s (no -S) prints nothing on stderr for a 500 or a --max-time timeout; stdout is the -w code ('000' on timeout), exit 28.
- *163059-verify-A1 · claude-opus-5-5*

### 2026-11-07 16:19 · A1-03 · passes

Every notify call site names its kind (park+feature, needs_michael, blocked/ended by ehigh, started, paused, verified, merged, limit, debrief, other); tests/checks/event-run.sh (slow, 6 checks, 5 stub runs + debrief) proves the routes end to end; decision 2026-10-22-event-hook-ntfy-fallback; architecture §3/§4/§7/§10 and README Steering; Opus review: no Critical/Important.

- **Files:** lib/record.sh, lib/driver.sh, lib/lane.sh, lib/debrief.sh, lib/desk.sh, lib/needs.sh, bin/harness, tests/checks/event-run.sh, tests/fixtures/check-names.txt, journal/decisions/2026-10-22-event-hook-ntfy-fallback.md, docs/architecture.md, README.md, +1 more
- **Verified:** event-run.sh red first (4/6 FAIL: park, refused park, blocked, debrief), then 6/6; bash tests/run.sh event-run event-hook park-desk needs-driver queue-debrief: 165/165; check.sh --fast green (986 tests); bash -n on every touched shell file, node --check lib/notify.mjs.
- **Tests:** 1808 → 1814
- **Discovery** (affects A2): event-run.sh's five stub runs plus the debrief take ~35 s; events are read from curl.log (Content-Type: application/json calls) and $HARNESS_STATE/events/*/event.json, filtered by .run
- **Discovery** (affects A2): A park run with EVENT_URL set posts two events: park, then blocked (its end reason 'waiting on Michael: B' is ehigh); A2-04's context bundle check must select by kind
- **Question for Michael:** EVENT_URL may hold a webhook secret but sits on curl's command line (ps, HARNESS_XTRACE traces) as NTFY_URL does; should lib/xtrace.sh's warning name it too, or the POST read the URL from a file (curl -K)? Default: left as is. Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-0/docs/plans/2026-11-07-A1-review.md, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-07-3/slot-0/lib/notify.sh:62
- *03-A1-03 · claude-opus-5-5*

### 2026-11-07 16:08 · A1-02 · passes

notify takes kind=/feature=; with EVENT_URL set park/needs_michael/blocked/debrief build v1 JSON in lib/notify.mjs event, keep it at events/<id>/event.json and POST it once (-w http_code, --max-time EVENT_TIMEOUT, no retry/token); 2xx logs and returns, else a note and today's ntfy/NOTIFY_CMD post unchanged. Stub-curl STUB_EVENT knob with real curl fixtures.

- **Files:** lib/notify.mjs, lib/notify.sh, lib/config.sh, templates/user/config.sh, tests/stub-curl.sh, tests/fixtures/curl-event-200.out, tests/fixtures/curl-event-500.out, tests/fixtures/curl-event-timeout.out, tests/checks/event-hook.sh, tests/unit/notify.test.mjs, tests/fixtures/check-names.txt, tests/fixtures/check-names-fast.txt
- **Verified:** Red first: 5/6 unit tests and 7/11 event-hook checks failed before the code (the rest are guards that hold today). Then bash tests/run.sh event-hook unit-tier notify-body-cap origin-outage needs-record: 547/547; check.sh --fast green: 986 tests in 115 s.
- **Tests:** 1791 → 1808
- **Dead end:** a curl-event-timeout.err fixture with curl's (28) line (A1-01's discovery) — with -s and no -S real curl 8.5.0 writes nothing on stderr on a timeout: re-captured on loopback, so the stub prints only stdout 000 and exits 28
- **Discovery** (affects A1-03): notify's kind defaults to other and no call site passes kind= yet: A1-03 adds them; until then every notification goes to ntfy exactly as before, EVENT_URL set or not.
- **Discovery** (affects A1-03): tests/checks/event-hook.sh's eh/rec/posted/hdr helpers read one case's curl record; event-run.sh can read the event as the line after --data-binary in the call carrying 'Content-Type: application/json'.
- **Discovery** (affects A1-03): The decision file (2026-10-22-event-hook-ntfy-fallback) and the architecture/README lines are A1-03's per the plan; A1-02 wrote none.
- **Discovery** (affects project): curl -s (no -S) prints nothing on stderr on error: a timeout is stdout 000 + exit 28 only (agent-harness-2026-11-07-3 2026-11-07)
- **Proposed change:** A1-02's unit-test name says 'stays ""'; it is 'stays the empty string' (a quote in a node:test name breaks the name fixtures' extraction)
- *02-A1-02 · claude-opus-5-5*

### 2026-11-07 15:59 · A1-01 · passes

Wrote docs/plans/2026-11-07-A1-event-hook.md: the v1 event keys and who fills each, the POST verbatim (-w '%{http_code}', no --fail/--retry/token), the two log lines, stub-curl's STUB_EVENT knob with fixtures from real curl 8.5.0 on loopback, every notify call mapped to its kind, 11 existing curl checks (all stay) and the 23 new check names with tiers.

- **Files:** docs/plans/2026-11-07-A1-event-hook.md
- **Verified:** fast tier green (check.sh --fast: cached for this code tree, 1791 tests; docs/plans is outside the key); plan's line refs re-read against main 8e05980; curl outputs captured from a node listener on 127.0.0.1:7829
- **Tests:** 1791 → 1791
- **Discovery** (affects A1-03): A park run ends 'waiting on Michael: B' (ehigh 1), so with EVENT_URL set it posts a park event AND a blocked run-end event: event-run's park check must count park events, not POSTs.
- **Discovery** (affects A1-03): needs_notify already forwards a caller's kind=/feature= (both branches call notify "$msg" "$@" before the record's 5 fields): no change to lib/needs.sh in A1.
- **Discovery** (affects A1-02): Real curl 8.5.0, -s -o /dev/null -w '%{http_code}': 500 → stdout 500 exit 0 no stderr; timeout → stdout 000, exit 28, 'curl: (28) Operation timed out after N milliseconds with 0 bytes received'.
- **Discovery** (affects run): features.mjs repair compares the list as JSON, so a jq rewrite of feature_list.json that flips only passes is not an edit.
- **Proposed change:** A1-03 step 1: 'posts exactly one event to EVENT_URL with kind == park' should read 'exactly one park event': the park run's end (waiting on Michael) also posts a blocked event.
- **Proposed change:** A1-02 step 2 could add (j) NOTIFY_CMD not called on a 2xx and called on a refusal, and (k) an event node can't build falls back to ntfy (the ask gotcha): the plan names both.
- *01-A1-01 · claude-opus-5-5*

### 2026-11-07 15:53 · init · passes

14 features: A1 3 (plan, event builder + routed post, call sites with folded review), A2 5 (plan, lib/glossary.mjs, lib/context.sh + harness context, context.json + retention + hook bundle, review), A3 5 (plan, lib/requests.mjs, harness requests, systemd units + docs, review), A4 1 (docs, sonnet). In series: A2 after A1, A3 after A2, A4 after A3. No check budget (the spec sets none).

- **Discovery** (affects run): A1 ships events with `context: null`; A2-04 wires lib/context.sh's bundle into lib/notify.sh's routed post (the spec's A1 text puts the bundle in A1).
- **Discovery** (affects run): Decision files take the spec's names (journal/decisions/2026-10-22-<slug>.md, the three §A4 lists), not today's date: the spec and n8n-home cite them so.
- **Discovery** (affects run): tests/fixtures/n8n-event-v1.json already holds the v1 event JSON (needs-record.sh reads its keys): the event builder's key order is checked against it.
- **Discovery** (affects run): tests/lib.sh exports HARNESS_NO_RUNNER=1 (queue_ensure_runner a silent no-op): A3-03's runner check unsets it for that call or reads `queue start`'s line.
- **Discovery** (affects project): needs_notify (lib/needs.sh) rebuilds notify's fields from the needs record: forward a caller's kind= or it is lost (agent-harness-2026-11-07-3 2026-11-07)
- **Discovery** (affects project): lib/debrief.sh has log (runner.log) but no note: notify's failure line lands in $Q/runner.log, not harness-log.md (agent-harness-2026-11-07-3 2026-11-07)
- *00-init · claude-fable-5-1*
