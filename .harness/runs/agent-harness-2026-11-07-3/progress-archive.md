<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress — run `agent-harness-2026-11-07-3` (agent-harness)

What this file is: the run's journal, rendered by the harness from `entries.jsonl`, newest entry first (the 15 newest in full; every entry is in `progress-archive.md`). Each entry is one session: its feature, outcome, summary, what it tried, what it found.

The run builds A1–A4 of `docs/specs/2026-10-22-n8n-events.md`, four milestones in series: **A1** `notify` learns `kind=`/`feature=` and, with `EVENT_URL` set, POSTs a v1 event for park, needs_michael, blocked and debrief through the stub curl, ntfy as the fallback; **A2** the debrief's gatherer moves into `lib/context.sh`, `harness context` writes a bundle (context.md with an ID glossary by `lib/glossary.mjs`, context.json) that a routed event points at; **A3** `harness requests` turns n8n's request files (`answer`, `continue`) into `harness answer` and `harness queue add --continue`, under a systemd path unit Michael installs; **A4** the docs and the live checklist. Inert unless `EVENT_URL` or the request inbox is configured; never a real HTTP request.

How to read the feature list: `feature_list.json` is in priority order; a feature runs when it isn't passing and its `after` all pass. Each milestone's plan feature writes `docs/plans/2026-11-07-A<n>-….md`; A2 and A3 end in a review feature, A1's review is folded into A1-03, A4 is one docs feature. When every feature of a milestone passes the harness verifies it and merges it into `main` (`MERGE_POLICY=auto`).

How to steer: edit `INBOX.md` in this directory from the phone or `harness answer`. A line `status: stop <why>` or `status: pause` on top stops or pauses the run; answers to questions go under `## Answers`; a brief under the steering comment changes scope for the next session. Open questions are listed under the entries that asked them and in `harness needs`.

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
