<!-- harness: rendered from entries.jsonl after every session; edits here are overwritten -->
# Progress log — run `n8n-home-2026-10-22` (branch `harness/n8n-home-2026-10-22`)

What this file is: the shared memory of the agent harness for this run. Each session appends one entry **at the top**
(newest first) when it finishes a feature: what it built, what it learned, what it asks. Nobody edits older entries.

How to read the feature list: `.harness/runs/n8n-home-2026-10-22/feature_list.json`. Array order is priority and
dependency order; the harness hands a session the first feature whose `passes` is false and whose `after` is
satisfied. A session may flip only its own feature's `passes`, and only after the suite is green on the committed
tree (before B2 lands, the stand-in is `bash -n` on every `.sh`, `tests/checks/*.sh`, and `docker compose -f
deploy/compose.yml config -q`). Milestones B1–B6 are spec §8's; each starts with a plan feature and ends with a
review feature; when a milestone passes, the harness verifies it and opens a PR (`MERGE_POLICY=pr`: nothing merges
itself).

How Michael steers: edit `.harness/runs/n8n-home-2026-10-22/INBOX.md` on this branch. First line `status: run | pause |
stop`; answers to the questions below go under `## Answers`. Every session reads it at startup. Defaults taken in his
absence are `D<n> *default*` rows in `docs/decisions.md`; he confirms or changes them there.

---

### 2026-10-27 20:44 · verify B6 · passes

All 5 hold. Suite 89/0, canvas 138/0, deploy --check ok, Check green. Caveats: B6-01 step 2 holds only on private topic (public omits body by D28/R1); live POST {} not re-run (denied); validate_workflow not re-run.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| B6-01 | 1 | ls docs/plans | 2026-10-22-B6-error-and-canvas.md exists | yes |
| B6-01 | 2 | .harness/check.sh; read tests/lib-errors.sh, errors-private.sh | PASS error handler card/report (public: title/click/priority + failure line, no body, D28/R1); PASS 'error handler card/report (private topic)' with NTFY_PRIVATE=true asserts body == event body + blank + 'n8n: wf failed at node' + URL under PUBLIC_BASE_URL. Step holds only in private mode; public deliberately omits body | yes |
| B6-01 | 3 | suite | PASS error handler generic (tests/workflows/rig-fail.json exists) | yes |
| B6-01 | 4 | jq -r .settings.errorWorkflow workflows/*.json; jq node names | 6x ReporterError090, null for handler; 15 named nodes, 3 sticky notes; validate_workflow not re-run (MCP closed earlier); canvas lint 138/0 | yes |
| B6-01 | 5 | check.sh | suite .harness/check.sh: 89 passed, 0 failed, exit 0 | yes |
| B6-02 | 1 | bash tests/checks/canvas.sh / suite | canvas.sh 138 passed, 0 failed incl. 'catches' cases; canvas.sh prints PASS per rule per workflow (11 rules x 7 + rig files) | yes |
| B6-02 | 2 | bash tests/checks/canvas.sh / suite | canvas.sh 138 passed, 0 failed incl. 'catches' cases; scratch-copy break cases in canvas.sh | yes |
| B6-02 | 3 | bash tests/checks/canvas.sh / suite | canvas.sh 138 passed, 0 failed incl. 'catches' cases; canvas lint + earlier validate_workflow record; sticky notes rule passes | yes |
| B6-02 | 4 | bash tests/checks/canvas.sh / suite | canvas.sh 138 passed, 0 failed incl. 'catches' cases; docs/workflows.md present, notes rule | yes |
| B6-02 | 5 | bash tests/checks/canvas.sh / suite | canvas.sh 138 passed, 0 failed incl. 'catches' cases; suite .harness/check.sh: 89 passed, 0 failed, exit 0 | yes |
| B6-03 | 1 | bash -n; ls -l; file docs/plans/screenshots/*.png | bash -n tests/screenshots.sh ok | yes |
| B6-03 | 2 | bash -n; ls -l; file docs/plans/screenshots/*.png | 7 B6-*.png each 1600x900, 88-113 KB; doc lists images, only mentions secrets as absent | yes |
| B6-03 | 3 | bash -n; ls -l; file docs/plans/screenshots/*.png | doc and checklist step 12 present | yes |
| B6-03 | 4 | bash -n; ls -l; file docs/plans/screenshots/*.png | suite .harness/check.sh: 89 passed, 0 failed, exit 0 | yes |
| B6-04 | 1 | grep/read docs | B6-review.md has findings table; no Critical/Important open | yes |
| B6-04 | 2 | grep/read docs | checklist steps 0-16 each with Done when (18 matches), covers all items | yes |
| B6-04 | 3 | grep/read docs | no unexplained TODO/FIXME (only 'TODO-MICHAEL.md' references); decisions D1-D10 marked | yes |
| B6-04 | 4 | grep/read docs | review doc records fresh-clone run 85 passed, 147 s (pre-B6-01 fix) | yes |
| B6-04 | 5 | grep/read docs | suite .harness/check.sh: 89 passed, 0 failed, exit 0 | yes |
| B6-05 | 1 | read entries; systemctl not re-run | recorded preconditions in entry 43; live state: DEPLOYED=3123885, image 2.42.5 running | yes |
| B6-05 | 2 | scripts/deploy.sh --check | 7 workflows present with expected active state; DEPLOYED sha present | yes |
| B6-05 | 3 | curl healthz, deploy --check, GET /webhook/report?id=does-not-exist | healthz ok, deploy --check ok, 404. POST {} to live intake denied by classifier, not re-run; relied on rig intake checks and prior entry (422) | yes |
| B6-05 | 4 | read workflows/ active flags + entries | 20,40,90 unpublished by D31; no live event posted by me | yes |
| B6-05 | 5 | n/a | no failure; Check green | yes |
| B6-05 | 6 | read live-checklist step 8/6 | names workflows to activate and how | yes |

- *204008-verify-B6 · claude-sonnet-5-5*

### 2026-10-27 20:40 · B6-01 · passes

Step 2 now holds as written: new rig group errors-private (tests/run.sh `# env:` header restarts the rig with NTFY_PRIVATE=true) checks the card and report fallback carries the event's Title, Click, Priority, Actions, body, then the failure line and URL. The public-topic checks (D28/R1: no body) stay in errors. Alert helpers moved to tests/lib-errors.sh.

- **Files:** tests/run.sh, tests/lib-errors.sh, tests/checks/errors.sh, tests/checks/errors-private.sh, docs/plans/2026-10-22-B2-test-rig.md, docs/plans/2026-10-22-B6-error-and-canvas.md
- **Verified:** .harness/check.sh: 89 passed, 0 failed (PASS error handler card/report/generic/execution records/after the card was sent; PASS rig restarted for errors-private, rig restarted with NTFY_PRIVATE=true, error handler card (private topic), error handler report (private topic)). Red first: the private checks failed on the public rig (body was the failure line only). jq .settings.errorWorkflow: ReporterError090 for 10, 20, 21, 30, 40, 41; none for 90; 90 has 15 named nodes, 3 sticky notes; workflows/ and lib/ unchanged since attempt 1 (validate_workflow then clean; the n8n-docs MCP closed the connection this session). Opus review: 5 minor findings, all fixed (help range, KEY=value guard, awk escapes, globbing, Priority/Actions null checks). Note: the harness lib/check.sh reports 'no suite configured (CHECK_CMD)'; I ran .harness/check.sh directly. No live writes.
- **Tests:** 85 → 89
- **Dead end:** validate_workflow on 90 through the n8n-docs MCP — Connection closed; the workflow JSON is unchanged since attempt 1's clean validation
- **Discovery** (affects run): tests/run.sh: a rig group may add `# env: KEY=value …`; it runs after the other rig groups on the rig recreated (docker stop, rm, run; same database) with those rig_env values replaced. An unknown key or a token without = fails.
- **Discovery** (affects run): The harness suite command (agent-harness lib/check.sh) finds no CHECK_CMD for this run, so its green cache means nothing here; .harness/check.sh is the real suite.
- **Question for Michael:** D28/R1: on a public topic the error fallback sends the event's Title/Click/Priority and the failure line, never the event body (the question). The rig now checks both modes. Keep that (my default), or send the full plain ntfy publicly as the harness does today?
- **Proposed change:** B6-01 step 2: name the private-topic checks (`error handler card (private topic)`, `error handler report (private topic)`, group errors-private) for 'body contains the event's body', and say that on the public topic (`error handler card`/`report`) the body is the failure line and URL only (D28, B6-04 review R1).
- **Proposed change:** Set CHECK_CMD for n8n-home runs to .harness/check.sh, so the harness's own suite run isn't a no-op.
- *33-B6-01 · claude-opus-5-5*

### 2026-10-27 20:26 · verify B6 · not yet

Suite 85/0, canvas 138/0, deploy --check ok. B6-01 step 2 fails as written: D28/R1 sends no event body on the public topic, the step demands it; needs Michael's answer or step amended. Live POST to intake was blocked, so not re-run (rig covers it).

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| B6-01 | 1 | ls docs/plans/2026-10-22-B6-error-and-canvas.md | exists | yes |
| B6-01 | 2 | suite: PASS error handler card/report; read tests/checks/errors.sh alert_problems | Both PASS, but the assertion says the event body must NOT appear on the public topic (body is only the 'n8n: wf failed at node' line + URL); step says body contains the event's body. Deliberate D28/R1 change, unanswered by Michael | no |
| B6-01 | 3 | suite: PASS error handler generic | PASS; rig-fail.json names workflow/node, no event fields | yes |
| B6-01 | 4 | jq -r '.settings.errorWorkflow // "NONE"' workflows/*.json | ReporterError090 for six, NONE for 90 handler; canvas lint passes (names, stickies) | yes |
| B6-01 | 5 | .harness/check.sh | 85 passed, 0 failed | yes |
| B6-02 | 1 | bash tests/checks/canvas.sh | 138 passed, 0 failed: per-rule PASS per workflow plus negative cases (rename to Code, etc.) | yes |
| B6-02 | 2 | read canvas.sh negative cases in output | PASS lines 'canvas lint catches ...' break scratch copies and expect FAIL | yes |
| B6-02 | 3 | read canvas lint output; validate_workflow not re-run | lint rules pass for all workflows incl. sticky/layout; MCP validate_workflow not re-run by me | yes |
| B6-02 | 4 | grep webhook paths in docs/workflows.md | sections per workflow and table with harness-event, report-now, report-check, card-answer present | yes |
| B6-02 | 5 | .harness/check.sh | 85 passed, 0 failed | yes |
| B6-03 | 1 | bash -n tests/screenshots.sh | ok; script exists | yes |
| B6-03 | 2 | file docs/plans/screenshots/B6-*.png; read what-michael-sees doc | 7 PNGs 1600x900, 88-113 KB; doc lists per image, no tokens/hostnames (grep for taildf8564\|tk_\|ntfy.sh only matches in prose) | yes |
| B6-03 | 3 | read doc | headless render worked, no fallback needed; recommended workflow named | yes |
| B6-03 | 4 | .harness/check.sh | 85 passed, 0 failed | yes |
| B6-04 | 1 | ls docs/plans/2026-10-22-B6-review.md | review doc present with findings | yes |
| B6-04 | 2 | read live-checklist headings; grep -c 'Done when' | steps 0-16 in order, 18 Done-when lines, covers env keys, credentials, restic, tailscale, linger, EVENT_URL, report-now cost, screenshot | yes |
| B6-04 | 3 | grep -rn 'TODO\\|FIXME' lib scripts workflows tests docs | only TODO-MICHAEL.md references (spec, checklist), no unexplained | yes |
| B6-04 | 4 | not re-run: fresh clone suite | read review doc claim only; full suite in this tree passed | yes |
| B6-04 | 5 | .harness/check.sh | 85 passed, 0 failed | yes |
| B6-05 | 1 | curl healthz; docker inspect; cat /srv/n8n/DEPLOYED; git rev-parse | ok, 2.42.5 running; DEPLOYED 3123885 pushed ancestor of HEAD; preconditions read from entry 43 (not re-run) | yes |
| B6-05 | 2 | scripts/deploy.sh --check | 7 workflow(s) present with active state, rc 0; deploy output read from entry 43 | yes |
| B6-05 | 3 | GET /webhook/report?id=does-not-exist; ls /srv/n8n/files/events | 404 'No report'; 0 event files. POST {} to live intake denied by permission classifier, not run; rig PASS 'intake rejects' covers it | yes |
| B6-05 | 4 | read entry 43 and deploy --check | 20/40/90 unpublished; no v1 event posted; EVENT_URL unset | yes |
| B6-05 | 5 | no failure occurred | n/a: no rollback needed in attempt 2 | yes |
| B6-05 | 6 | read checklist step 6 and 8 | step 6 names the three workflows and the sed to set active:true then redeploy | yes |

- *202218-verify-B6 · claude-sonnet-5-5*

### 2026-10-27 20:22 · B6-05 · passes

Deployed 3123885 live (attempt 2): all 7 workflows on n8n 2.42.5; 10 intake, 21 report serve, 30 memory, 41 card serve published; 20 desk report, 40 phone card, 90 error handler imported unpublished until Michael creates the credentials (D31). Check and deploy --check green; intake refuses {} with 422, report/card pages 404. Checklist step 8 marked done.

- **Files:** docs/plans/2026-10-22-live-checklist.md
- **Verified:** LIVE. Preconditions 20:14-20:17: .harness/check.sh 85 passed, 0 failed on 3123885 (pushed to origin/harness/n8n-home-2026-10-22; tree clean but the harness's harness-log.md). Check: curl -sf http://127.0.0.1:5678/healthz -> {"status":"ok"}; docker inspect -> docker.n8n.io/n8nio/n8n:2.42.5 running (= deploy/compose.yml pin). systemctl show restic-backup.service -p ExecMainExitTimestamp -p ExecMainStatus -> Tue 2026-10-27 03:32:47 EDT, 0; is-active -> inactive; time 20:14 (outside 03:15-04:30). Rollback record: image 2.42.5; sha256sum /srv/n8n/compose.yml 99b2add98d6609bdc71b567f643d3d1147dcaf2bbf66bcf6a4631efa2f8ddd54; DEPLOYED dcdc51dba89dc2c47de4def36169b36628255253. Snapshots 20:17: flock -n /srv/n8n/live.lock sh -c 'sqlite3 /srv/n8n/data/database.sqlite ".backup /srv/n8n/data/database.sqlite.pre-n8n-home-2026-10-22-B6.snap" && sqlite3 /srv/n8n/data/database.sqlite.pre-n8n-home-2026-10-22-B6.snap "pragma integrity_check" && cp /srv/n8n/compose.yml /srv/n8n/compose.yml.pre-n8n-home-2026-10-22-B6 && tar -C /srv/n8n -czf /srv/n8n/files.pre-n8n-home-2026-10-22-B6.tgz files' -> ok, rc 0 (snap 2306048 B, compose snap sha 99b2add...). flock -n /srv/n8n/live.lock scripts/deploy.sh --dry-run -> rc 0: compose diff adds N8N_BLOCK_ENV_ACCESS_IN_NODE, NODE_FUNCTION_ALLOW_EXTERNAL, HARNESS_STATE_DIR, HARNESS_WORKTREES_DIR, the ./lib mount; copies all 7 workflows; publish ReporterIntake10, ReporterServe021, ReporterMemory30, ReporterCard0041 only. 20:17:22 flock -n /srv/n8n/live.lock scripts/deploy.sh -> rc 0 at 20:18:00: recreate, 'Successfully imported 7 workflows.', 4 published, restart, lib/post check passed, 'deployed 3123885e723c7329776ae51f79d3196447a09f9e (HARNESS: context pack for B6-05)'. After: healthz ok, 2.42.5 running; scripts/deploy.sh --check -> 'check: 7 workflow(s) present with the active state workflows/ gives them' rc 0; /srv/n8n/compose.yml sha f881fb1a... = deploy/compose.yml; n8n list:workflow -> 7; --active=true -> 10, 21, 30, 41. curl -X POST -d '{}' /webhook/harness-event -> 422 {"refused":["keys: missing [v,id,...]"]}, /srv/n8n/files/events has 0 files; GET /webhook/report?id=does-not-exist -> 404 'No report'; GET /webhook/card?event=nope -> 404 'No card'; POST /webhook/report-now -> 404 not registered (20 unpublished). No file under /srv/n8n/files newer than DEPLOYED. Container logs: only the Python-runner and localStorage warnings. No v1 event posted; EVENT_URL absent from ~/.config/harness/config.sh (grep -c 0), so no real notification or Claude call is possible yet. Suite after the checklist edit: 85 passed, 0 failed.
- **Tests:** 85 → 85
- **Discovery** (affects run): Live now runs 3123885 (DEPLOYED). Restore point for this deploy is the -B6 snapshot set (B1 state). Publishing 20/40/90 is checklist step 6, after Michael creates `Anthropic API key` and `ntfy token`.
- **Discovery** (affects run): n8n import:workflow logs 'Deactivating workflow ...' for every workflow whose JSON says active, even when nothing was published; the publish steps after it set the state, so the message is harmless.
- **Question for Michael:** D31: 20 desk report, 40 phone card and 90 error handler are live but unpublished until you create `Anthropic API key` and `ntfy token`; checklist step 6 publishes them. OK, or should all seven be published now?
- **Proposed change:** B6-05 step 3 could also name the card page (GET /webhook/card?event=nope answers 404 'No card'); this session checked it.
- *32-B6-05 · claude-opus-5-5*

### 2026-10-27 20:13 · B6-05 · not yet

Live deploy of 111d42b failed its own post-check (deploy --check loaded each lib file alone; card.js needs report.js) and was rolled back to B1 (dcdc51d, Check green). Fixed the check (each Code node's load list, real-lib test, no vacuous pass). 20/40/90 now held inactive until credentials exist (D31). Not retried live this session per protocol; attempt 2 deploys aa2175c.

- **Files:** scripts/deploy.sh, tests/checks/deploy.sh, tests/checks/workflows.sh, workflows/20-desk-report.json, workflows/40-phone-card.json, workflows/90-error-handler.json, docs/decisions.md, docs/plans/2026-10-22-live-checklist.md, docs/workflows.md, README.md, CLAUDE.md
- **Verified:** LIVE (top for Michael): deploy of 111d42b failed at its post-check and was ROLLED BACK; live is the B1 state again. Preconditions 20:02: suite .harness/check.sh 85 passed 0 failed on 111d42b, pushed (origin/harness/n8n-home-2026-10-22), tree clean apart from the harness's harness-log.md. Check: healthz {"status":"ok"}, docker.n8n.io/n8nio/n8n:2.42.5 running. systemctl show restic-backup.service -> ExecMainExitTimestamp=Tue 2026-10-27 03:32:47 EDT, ExecMainStatus=0; is-active -> inactive; time 20:02 (outside 03:15-04:30). Rollback record: image docker.n8n.io/n8nio/n8n:2.42.5; sha256sum /srv/n8n/compose.yml 99b2add98d6609bdc71b567f643d3d1147dcaf2bbf66bcf6a4631efa2f8ddd54; DEPLOYED dcdc51dba89dc2c47de4def36169b36628255253. Snapshots: flock -n /srv/n8n/live.lock sh -c 'sqlite3 /srv/n8n/data/database.sqlite ".backup /srv/n8n/data/database.sqlite.pre-n8n-home-2026-10-22-B6.snap" && sqlite3 /srv/n8n/data/database.sqlite.pre-n8n-home-2026-10-22-B6.snap "pragma integrity_check" && cp /srv/n8n/compose.yml /srv/n8n/compose.yml.pre-n8n-home-2026-10-22-B6 && tar -C /srv/n8n -czf /srv/n8n/files.pre-n8n-home-2026-10-22-B6.tgz files' -> ok, rc 0. flock -n /srv/n8n/live.lock scripts/deploy.sh --dry-run -> rc 0: compose diff adds only N8N_BLOCK_ENV_ACCESS_IN_NODE "false", NODE_FUNCTION_ALLOW_EXTERNAL n8n-home-lib, HARNESS_STATE_DIR, HARNESS_WORKTREES_DIR and the ./lib mount; lib/ new; publish ReporterIntake10, ReporterServe021, ReporterMemory30, ReporterCard0041; 20/40/90 imported unpublished. 20:02:59 flock -n /srv/n8n/live.lock scripts/deploy.sh -> rc 1 at 20:03:35: up -d recreated n8n-n8n-1, 'Successfully imported 7 workflows', 4 published, restart, then check_instance: 'n8n-home-lib/card.js:22 ... ReferenceError: schemaObject is not defined' -> 'the lib does not load in the container'. Rollback 20:04:08: flock -n /srv/n8n/live.lock sh -c 'set -e; cp /srv/n8n/compose.yml.pre-n8n-home-2026-10-22-B6 /srv/n8n/compose.yml; docker compose --project-directory /srv/n8n stop; cp /srv/n8n/data/database.sqlite.pre-n8n-home-2026-10-22-B6.snap /srv/n8n/data/database.sqlite; rm -f /srv/n8n/data/database.sqlite-wal /srv/n8n/data/database.sqlite-shm; docker compose --project-directory /srv/n8n up -d' -> rc 0. Check after: healthz ok, 2.42.5 running, compose sha 99b2add… again, n8n list:workflow empty, sqlite integrity ok, GET / 200, DEPLOYED dcdc51d; again 20:13 green. Left in place (not mounted by the B1 compose; the next deploy rewrites them): /srv/n8n/lib, lib.prev (empty), workflows/*.json, files/{events,cards,executions,...}. EVENT_URL is unset in the harness config (grep -c 0), so no event reached the instance. Offline: rehearsal in a throwaway n8n-test-* container (workflows/ only, no credentials, publish active only): POST {} harness-event 422 keys refusal, 0 event files; GET report?id=does-not-exist 404 'No report'; card 404 'No card'; report-now not registered. The new loader run in the pinned image with lib mounted: all 5 lists ok. Suite at aa2175c: 85 passed, 0 failed (417 PASS lines); tests/checks/deploy.sh 46 passed (RED first: the real-lib deploy case failed with the live error; the unreadable-list case passed rc 0 before the fix). Opus review of the diff: 1 Important (vacuous pass, fixed), minors (stub & quoting fixed; jq error masking in the active lint left: other checks parse the JSON).
- **Tests:** 412 → 417
- **Dead end:** Live deploy of 111d42b with scripts/deploy.sh — its post-deploy check loaded each lib/*.js alone in the container; card.js runs report.js's schemaObject at top level, so the check failed although the Code nodes (which load memory.js+report.js+card.js together) would have worked. Rolled back compose and the database; not retried live this session (protocol).
- **Discovery** (affects B6-05, run): deploy --check now loads each load([...]) list the workflows' Code nodes name, and fails a node that requires n8n-home-lib in any other form. tests/checks/deploy.sh STUB_LIB_REAL=1 runs that check for real against the deployed lib copy.
- **Discovery** (affects B6-05, run): 20, 40 and 90 are "active": false (D31) until Michael makes the credentials; the workflows lint now allows an inactive workflow only if a node uses `Anthropic API key` or `ntfy token`. Checklist step 6 has the commands to publish them.
- **Discovery** (affects B6-05): Next B6-05 attempt: take snapshots again (the -B6 names exist from 20:02; overwrite them, the B1-state database is what they hold and is unchanged since), dry run, deploy aa2175c or later, then mark checklist step 8 done with sha and snapshot names.
- **Question for Michael:** D31: I deployed (and will deploy) 20 desk report, 40 phone card and 90 error handler unpublished until you create `Anthropic API key` and `ntfy token`, while 10, 21, 30 and 41 are published. Checklist step 6 then publishes them by setting "active": true on main and deploying. OK, or should all seven go out published now?
- **Proposed change:** B6-05 step 3: 'GET /webhook/report?id=does-not-exist answers 404 through the path guard' could also name the card page (GET /webhook/card?event=nope answers 404 'No card') since 41 is published too.
- *31-B6-05 · claude-opus-5-5*

### 2026-10-27 19:54 · B6-04 · passes

B6 review: no Critical; R1 Important fixed (error fallback no longer sends the event body/Actions on a public topic), R2/R4/R5/R6 fixed, R3 accepted; B6-03's 41 note defects fixed via new lint rule; live checklist reordered 0-16 with workflow-deploy and report-now cost steps; README, decisions (D1/2/8/9/10 confirmed, D28 updated, D30) aligned.

- **Files:** lib/errors.js, workflows/90-error-handler.json, workflows/10-event-intake.json, workflows/30-memory.json, workflows/41-card-serve.json, tests/checks/canvas.mjs, tests/checks/canvas.sh, tests/checks/errors.sh, tests/unit/errors.test.mjs, docs/plans/2026-10-22-B6-review.md, docs/plans/2026-10-22-live-checklist.md, docs/decisions.md, +5 more
- **Verified:** Opus reviewer on git diff e12eb34...HEAD (3918 lines), each finding checked against code. RED seen then GREEN: canvas placement (10, 30, 41), units R1/R2 (217 -> 219 pass), rig errors card/report failed on body+Actions then 9/0, canvas 135 -> 138/0. Fresh clone of 10df691 in /tmp: .harness/check.sh exit 0, 147 s, 85 passed 0 failed (lines in the review doc). Worktree full suite: 85 passed, 0 failed. Screenshots retaken from a KEEP=1 rig, removed after. No live commands run.
- **Tests:** 217 → 219
- **Dead end:** a unit test name with an apostrophe in single quotes — the whole test file failed to load (206 pass, 1 fail at tests/unit:1); use double quotes
- **Discovery** (affects B6-05, run): Checklist renumbered: workflow deploy is step 8 (B6-05 marks it done with sha and snapshot names), EVENT_URL 13, harness-requests 14, report-now + measured cost 15 (Measured: line to fill), fixture bundle 16; snapshot timer stays 9.
- **Discovery** (affects B6-05, run): The error fallback now reads NTFY_PRIVATE (90 Config); on a public topic it sends Title/Click/Priority and the failure line only. AFTER_NTFY in lib/errors.js must list the nodes after ntfy in 20 and 40; a unit test fails if they drift.
- **Discovery** (affects run): Canvas lint has a placement rule (notes 40 px apart, none between two rows); env-urls now matches the whole URL form (ENV_URL).
- **Question for Michael:** D28/R1: a failed card or report now re-sends only the event's title, link and priority on the public topic (no question body, no GitHub actions); with NTFY_PRIVATE=true the full message. OK, or do you want the full harness message on the public topic as spec §4.3 literally says?
- **Question for Michael:** D30: until you have an ntfy token, create the `ntfy token` credential as Header Auth `X-Ntfy-Unused: none` (checklist step 6). OK?
- **Proposed change:** CLAUDE.md ## Live system still says '(B1 adds it)' / 'B1 builds it' for deploy.sh --check and the deploy; both exist now, so those parentheticals could go, and its Rollback could add moving files/executions aside (B6-04 review R3).
- *30-B6-04 · claude-opus-5-5*

### 2026-10-27 19:32 · B6-03 · passes

Headless editor screenshots work: tests/screenshots.sh sets up the rig owner over REST, logs in, and tests/screenshot-canvas.mjs drives the Playwright headless shell over CDP (cookie via Network.setCookie, Shift+1 fit). 7 PNGs B6-<workflow>.png at 1600x900; the what-michael-sees doc recommends B6-10-event-intake.png; checklist step 12 updated.

- **Files:** tests/screenshots.sh, tests/screenshot-canvas.mjs, docs/plans/screenshots/B6-*.png, docs/plans/2026-10-22-B6-what-michael-sees.md, docs/plans/2026-10-22-live-checklist.md, README.md
- **Verified:** bash -n tests/screenshots.sh ok; tests/screenshots.sh on a fresh KEEP=1 rig (n8n-test-6L6lvfcB) exit 0 in 32 s, again on the same rig (owner already set up) exit 0; `file` says 1600 x 900 for all 7, sizes 88-113 KB; looked at every image; jq over every sticky note finds no URL, ntfy.sh, taildf8564, token pattern or credential name; refuses a non n8n-test-* container (exit 2). Rig torn down. .harness/check.sh: 85 passed, 0 failed (no suite file changed). Nothing live touched.
- **Tests:** 85 → 85
- **Dead end:** a first trial owner set up by hand with another password — the script's login then fails on that rig; the script uses one fixed scratch password, so test it on a fresh rig
- **Dead end:** flipping passes with JSON.parse/stringify — it reformatted all of feature_list.json (commit 45ac95c); a9f2e8c restores the original text with only the passes line changed
- **Discovery** (affects run): n8n 2.42.5 login is POST /rest/login {emailOrLdapLoginId, password}, cookie n8n-auth (secure flag, accepted on http://127.0.0.1); node 24's global WebSocket is enough to drive chrome-headless-shell over CDP with no npm.
- **Discovery** (affects B6-04): Defects for B6-04 (in the what-michael-sees doc): 41's 'Answer' sticky sits inside the flow between branches and 'Remember'/'Wait for the harness' touch; 20, 40, 41 are unreadable at 1600 px zoom-to-fit.
- **Proposed change:** B6-03 step 2 says 5 files; workflows/ has 7 (10, 20, 21, 30, 40, 41, 90), and all 7 were shot.
- *29-B6-03 · claude-opus-5-5*

### 2026-10-27 19:20 · B6-02 · passes

B6-02 passes. The work is in commit `1e40404` and the `passes` flip in `38704b8`, both pushed. - **Lint:** `tests/checks/canvas.sh` gives 123 PASS, 0 FAIL: 10 rules on each of the 10 workflows, plus 22 checks that break a scratch copy and expect the FAIL line. A node renamed to `Code` fails with the file and node name. Every workflow passes `validate_workflow` with no errors. - **Suite:** 85 pass…

- **Files:** docs/decisions.md, docs/plans/2026-10-22-B6-error-and-canvas.md, docs/workflows.md, lib/card.js, lib/report.js, tests/checks/canvas.mjs, tests/checks/canvas.sh, tests/unit/card.test.mjs, tests/unit/report.test.mjs, tests/workflows/rig-memory.json, tests/workflows/rig-smoke.json, workflows/10-event-intake.json, +6 more
- *28-B6-02 · claude-opus-5-5 · recorded by the harness: entry.json invalid: summary: 425 characters (at most 400)*

### 2026-10-27 19:07 · B6-01 · passes

workflows/90-error-handler.json (Error Trigger) is every workflow's error workflow. 10, 20 and 40 record files/executions/<execution id>.json naming their event; the handler re-sends the stored event's plain ntfy plus 'n8n: <wf> failed at <node>' and the execution URL, else a generic alert. After 20/40's own ntfy the record is marked notified (generic only). D28.

- **Files:** workflows/90-error-handler.json, lib/errors.js, workflows/10-event-intake.json, workflows/20-desk-report.json, workflows/40-phone-card.json, workflows/21-report-serve.json, workflows/30-memory.json, workflows/41-card-serve.json, tests/checks/errors.sh, tests/unit/errors.test.mjs, tests/workflows/rig-fail.json, fixtures/events/park-broken.json, +13 more
- **Verified:** Full .harness/check.sh: 84 passed, 0 failed (79 before; new group errors: card, report, generic, execution records, after the card was sent). Units 206 -> 217. Mutations: errorWorkflow removed from 20/40 -> card and report FAIL 'no ntfy in 60 s'; notified/30-skip guards removed -> 'after the card was sent' FAIL with 3 ntfy incl. '30 memory (sub-workflow) failed'. validate_workflow (n8n-docs MCP) on 90: valid, 0 errors, 0 warnings; rig-fail and the record chain also valid. jq -r .settings.errorWorkflow workflows/*.json: ReporterError090 for all but 90 (null). No live command run.
- **Tests:** 79 → 84
- **Dead end:** finding the event in the Error Trigger item — n8n 2.42.5's execute-error-workflow.js passes only execution id/url/error/lastNodeExecuted/mode/retryOf/executionContext and workflow id/name; reading the execution back needs an n8n API key
- **Dead end:** the new rig check with memory left from earlier groups — the park question was already in memory, so no write failed; the check now empties files/memory first
- **Discovery** (affects B6, run): n8n dispatches the error workflow for sub-workflow executions (integrated mode, waited or not): a failing 30 memory fired the handler beside its caller, so lib/errors.js CALLER_ALERTS drops 30's alerts.
- **Discovery** (affects B6-04, B6-05): files/executions/ gets one small record per intake, card and report execution and nothing prunes it; deploy.sh now creates the dir.
- **Discovery** (affects B6-02): B6-02's rule 'every HTTP Request url begins with ={{ $env.' fails today on 20/21/40's Claude nodes ($json.url from messagesRequest) and 40/20's ntfy (Config's item); 90's ntfy already uses $env.NTFY_URL.
- **Discovery** (affects B6-04): Left from the B6-01 review (Minor): a retried execution has no record under its new id (retryOf not tried), and an empty record/event file would throw in Record text/Event text with nothing sent.
- **Question for Michael:** D28: a failed card or report re-sends the event's own title/body on NTFY_URL even when NTFY_PRIVATE is false, as the harness's own fallback does today (spec 4.3), so the question can reach the public topic when the card build fails. Keep that, or send only the generic alert unless NTFY_PRIVATE=true?
- *27-B6-01 · claude-opus-5-5*

### 2026-10-27 18:34 · verify B5 · passes

All six B5 features re-verified: suite 79 passed 0 failed, 206 unit tests pass, named rig checks pass, docs/screenshots/checklist steps present, sync in order. No feature changed.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| B5-01 | 1 | grep docs/plans/2026-10-22-B5-phone-card.md | schema, exactly-one-recommended, 2-4 options, verb default rule (lines 177-186) present | yes |
| B5-01 | 2 | read plan; compared with workflows/41-card-serve.json nodes | serve/answer node chain (Read card, Crypto id, Write request, Wait+Read poll, result page) matches; id regex ID_GUARD in lib | yes |
| B5-01 | 3 | read plan + what-michael-sees doc | HTML, result texts, ntfy public/private, idempotency, check names present; checks exist in suite | yes |
| B5-01 | 4 | ran .harness/check.sh | `.harness/check.sh`: 79 passed, 0 failed; `node --test tests/unit/`: 206 pass | yes |
| B5-02 | 1 | node --test tests/unit/ ; grep -c tests card.test.mjs | 55 tests in card.test.mjs (>=12), all pass incl. buildRequest cases | yes |
| B5-02 | 2 | unit tests buildCard | pass (recommended, verb default, 5->4 trim) | yes |
| B5-02 | 3 | unit tests renderCard | pass | yes |
| B5-02 | 4 | unit tests ntfyMessage/renderResult | pass | yes |
| B5-02 | 5 | sync-code-nodes.mjs --check | in sync: 22 nodes; code in D6 style | yes |
| B5-02 | 6 | suite | `.harness/check.sh`: 79 passed, 0 failed; `node --test tests/unit/`: 206 pass | yes |
| B5-03 | 1 | suite rig: card built park/blocked/needs_michael | PASS lines seen in suite output | yes |
| B5-03 | 2 | suite rig: card ntfy public + card LLM body clean | PASS lines seen in suite output | yes |
| B5-03 | 3 | suite rig: card question remembered + card idempotent | PASS lines seen in suite output | yes |
| B5-03 | 4 | suite rig: intake routes to card; grep -c interim=0; sync check | PASS lines seen in suite output | yes |
| B5-03 | 5 | suite | `.harness/check.sh`: 79 passed, 0 failed; `node --test tests/unit/`: 206 pass | yes |
| B5-04 | 1 | suite: card served | PASS | yes |
| B5-04 | 2 | suite: card answer writes request, card answer continue, card writes only requests | PASS | yes |
| B5-04 | 3 | suite: card shows result, card result pending | PASS | yes |
| B5-04 | 4 | suite: card question answered, card writes only requests | PASS | yes |
| B5-04 | 5 | inspected workflows/41 nodes; sync --check | Crypto node request id, fixed names, sticky notes; in sync | yes |
| B5-04 | 6 | suite | `.harness/check.sh`: 79 passed, 0 failed; `node --test tests/unit/`: 206 pass | yes |
| B5-05 | 1 | read docs/plans/2026-10-22-B5-what-michael-sees.md | public Title/Click from fake /_calls beside private message, side by side | yes |
| B5-05 | 2 | file/ls -l on screenshots | B5-card-390-light 62KB, dark 64KB, B5-result-390-light 17KB; all 390 wide PNG | yes |
| B5-05 | 3 | read doc | per-screen description and 'Defects for B5-06' section present | yes |
| B5-05 | 4 | suite | `.harness/check.sh`: 79 passed, 0 failed; `node --test tests/unit/`: 206 pass | yes |
| B5-06 | 1 | read docs/plans/2026-10-22-B5-review.md | findings table incl. B5-05 defects P1-P5.., 'Open: no Critical or Important'; unit tests named per defect pass | yes |
| B5-06 | 2 | inspected lib/card.js, lib/report.js, workflow 41, code node line counts | shared guardedId/ID_GUARD; poll is one Wait 1 s + Read results; largest Code node 3 lines (lib-backed) | yes |
| B5-06 | 3 | grep live-checklist.md | intro states requests inbox/harness answer, not GitHub; steps 8 (EVENT_URL), 8b (path unit), 10 (NTFY_PRIVATE), 14 (DESK_URL) each with Done when; docs/workflows.md has sections 40 and 41 | yes |
| B5-06 | 4 | grep docs/decisions.md D5; CLAUDE.md | D5 present and updated; CLAUDE.md gotchas consistent with build | yes |
| B5-06 | 5 | suite | `.harness/check.sh`: 79 passed, 0 failed; `node --test tests/unit/`: 206 pass | yes |

- *183209-verify-B5 · claude-sonnet-5-5*

### 2026-10-27 18:32 · B5-06 · passes

B5 reviewed: all 8 B5-05 defects fixed, plus Opus review R1/R3 and the B5-04 Importants: answer-derived request ids (sha256 of event+text) and allowedOrigins on 21. The card shows the question and the words each option sends, the result page speaks plainly, and the double tap is keyed on the card's event. Docs: workflows.md 40/41, checklist steps 8/8b/10/14, D5/D9/D24/D25.

- **Files:** lib/card.js, lib/memory.js, workflows/41-card-serve.json, workflows/21-report-serve.json, tests/unit/card.test.mjs, tests/unit/memory.test.mjs, tests/checks/card-serve.sh, tests/checks/card.sh, tests/checks/report-serve.sh, tests/lib.sh, docs/plans/2026-10-22-B5-review.md, docs/workflows.md, +6 more
- **Verified:** .harness/check.sh: 79 passed, 0 failed (98 s; no n8n-test containers left). node --test tests/unit/: 193 -> 206, each new test RED first (7b6abe3, f62df65) then GREEN (f62df65, 2bb2333, 663c962). Rig: report no cross-origin read RED (evil.example and null echoed) then GREEN; card-serve checks request ids = 1-/2-<sha256(event\ntext)[:40]> and data-state. n8n-docs validate_node: Crypto hash SHA256 and webhook allowedOrigins valid. Code nodes: 22, all 3 lines; longest lib function 148. Sonnet: 390 px screenshots and getBoundingClientRect, nothing under 44 px after the summary fix, scrollWidth <= 390. Nothing live.
- **Tests:** 193 → 206
- **Dead end:** Opus review R2 as Important: 'needs_you is followed by return 1, so the run ends' — driver.sh's main loop runs `verify_ready || continue`, so the run goes on. Always offering continue would queue a restart behind a live run, so instead the ok page says when the run reads the answer, and the question goes to Michael
- **Dead end:** keeping the 2-minute double-tap window — answer-derived ids make a re-send a no-op on Run A's side, so the guard is same event and same text at any age; the window would only hide a blocked card's continue (defect 5)
- **Discovery** (affects B6, run): Memory question rows gain answered_event (SCHEMA, docs/memory.md, B3 plan). markAnswered takes {event}; 41's memoryArgs pass the card's event.
- **Discovery** (affects run, B6): Card request ids are now 1-/2-<first 40 hex of sha256(event + '\n' + answer text)>, not uuids. Run A's spec says an id already in done/ is ignored, but its checks also say a 'duplicate id' is rejected with a result. If that result overwrites done/<id>.json, a double tap's page would show a refusal; checklist 8b checks it live.
- **Discovery** (affects B6, run): Run A has not merged: ~/projects/agent-harness has no systemd/ dir yet. Checklist steps 8 and 8b are [later: Run A].
- **Discovery** (affects B6): Result pages carry data-verb/data-state (ok, refused, pending) on each request line, and the rig greps those, not the wording.
- **Discovery** (affects B6): tests/lib.sh now has acao (the Access-Control-Allow-Origin a webhook answers); compose.sh fails if the image tag appears outside deploy/compose.yml, comments included.
- **Question for Michael:** R2: a park or needs_michael card is built while its run is still running, so it offers 'answer' only. If the run has ended by the time you answer, the answer waits in its inbox until the run next starts, and the result page says so. Should those cards also offer 'answer and continue' (it would queue a restart behind the live run), or is the page's sentence enough?
- **Question for Michael:** D9 (updated, default): the public ntfy title is now '<project>: <run>', not the run alone. The project name isn't secret. Keep it?
- **Proposed change:** B6: add a sanitised ledger debrief.md fixture and a card check that its text reaches the card prompt (review R8, B5-03's proposal).
- **Proposed change:** B6: when 40's askQuestion fails, 41's markAnswered finds no row and saves nothing silently (review R6). The error workflow should cover 'Stop: memory not saved'.
- **Proposed change:** Set CHECK_CMD=.harness/check.sh for n8n-home: the harness's suite command still prints 'no suite configured'.
- *26-B5-06 · claude-opus-5-5*

### 2026-10-27 18:12 · B5-05 · passes

docs/plans/2026-10-22-B5-what-michael-sees.md: public ntfy (fake /_calls) beside private (ntfyMessage on the unit fixture), 6 screenshots at 390x844 (card light/dark, answered card, result pending, result ok light/dark) from KEEP=1 rigs, each screen described, tap sizes measured, 8 defects for B5-06. No code changed.

- **Files:** docs/plans/2026-10-22-B5-what-michael-sees.md, docs/plans/screenshots/B5-card-390-light.png, docs/plans/screenshots/B5-card-390-dark.png, docs/plans/screenshots/B5-card-answered-390-light.png, docs/plans/screenshots/B5-result-390-light.png, docs/plans/screenshots/B5-result-ok-390-light.png, docs/plans/screenshots/B5-result-ok-390-dark.png
- **Verified:** KEEP=1 tests/run.sh --only card,card-serve: 21 passed; --only card (twice, fresh state): 11 passed. Screenshots with chrome-headless-shell 1248 --window-size=390,844 (dark: --blink-settings=preferredColorScheme=0); `file`: all 390 x 844; card 62/64 KB, result (pending) 17 KB. Element sizes from getBoundingClientRect in the same shell. Rigs removed (docker ps: no n8n-test-*). .harness/check.sh: 78 passed, 0 failed (unchanged). Nothing live.
- **Tests:** 78 → 78
- **Dead end:** the answer_continue 'ok' result page as B5-result-390-light.png — it is 5 short lines; its PNG is 12.6 KB, under the step's 15 KB. B5-result-390-light.png is the 'sent, not yet confirmed' page (17 KB); the ok page is B5-result-ok-390-light/dark.png
- **Dead end:** answering the blocked card after the park card in the same rig — both cards share question H3-04, so the 2-minute double-tap guard returned 'Already sent' and wrote no continue (defect 5); a fresh rig was needed
- **Discovery** (affects B5-06): The card never renders question.text: Michael sees blocked_what/why but not which values or files the parked question names (defect 1, the main one for B5-06).
- **Discovery** (affects B5-06, run): The double-tap guard keys on question id + answer text, not event: a blocked card's answer_continue within 2 min of the park card's same answer writes no continue request (defect 5).
- **Discovery** (affects B5-06): Links 'talk it through' and 'Back to the card' and the <abbr> are 23 px tall at 390 (defect 2); options and Send are 48+ px.
- **Proposed change:** B5-05 step 2's 15 KB floor doesn't fit the ok result page (12.6 KB at 390x844, a short page on a blank screen); a later check of short pages should use a non-blank test (e.g. distinct colours) rather than a byte floor.
- *25-B5-05 · claude-opus-5-5*

### 2026-10-27 18:02 · B5-04 · passes

workflows/41-card-serve.json (ReporterCard0041) serves the card on GET /webhook/card and answers it on POST /webhook/card-answer: request JSON v1 files (1-/2-<Crypto uuid>) into the request inbox, markAnswered in memory, a 1 s poll of done/<id>.json up to 14 s, result page. Both webhooks refuse cross-origin reads. Rig group card-serve (10 checks) with a fake consumer.

- **Files:** workflows/41-card-serve.json, lib/card.js, scripts/code-nodes.json, tests/checks/card-serve.sh, tests/lib.sh, tests/unit/card.test.mjs, docs/decisions.md
- **Verified:** .harness/check.sh: 78 passed, 0 failed (card-serve: card served, card no cross-origin read, card answer writes request, card shows result (3.3 s), card question answered, card answer continue, card answer guards, card answer token, card result pending (14.4 s), card writes only requests); node --test tests/unit/: 193/193 (7 new); sync --check in sync 22 nodes; n8n-docs validate_workflow on 41: valid, 0 errors, 5 warnings (intended executeOnce); validate_node on the webhook allowedOrigins option: valid. KEEP=1 run inspected by hand: request files byte-exact, 1-/2- in mtime order, memory rows answered via n8n-card. Opus review: 1 Critical (CORS) fixed RED then GREEN, 1 Important left for B5-06 (D25 updated), 2 rig Minors fixed. Nothing live.
- **Tests:** 68 → 78
- **Dead end:** an absent allowedOrigins on the card webhooks (the plan assumed no CORS) — n8n 2.42.5 copies any request's Origin, null included, into Access-Control-Allow-Origin (webhook-request-handler.js), so any page could read the card and its token; now one origin that can't match
- **Discovery** (affects B5-06, B6, run): n8n 2.42.5 webhooks with no allowedOrigins answer every Origin (also null) with Access-Control-Allow-Origin = that origin. 41 sets allowedOrigins to https://cross-origin-refused.invalid; 21-report-serve's report and report-check webhooks still have none (report pages readable cross-origin; report-check spends an LLM call).
- **Discovery** (affects B5-06, run): Two POSTs of the same answer within the same second both pass the double-tap check (memory is saved after the write) and write two requests each. Needs answer-derived request ids plus Run A refusing an id already handled (D25 updated in place).
- **Discovery** (affects B5-06): A failed Write request (disk full, permissions) ends the POST with n8n's error and no memory mark; if 1- was written and 2- failed, the answer is out without its continue. Not handled.
- **Discovery** (affects B5-05, B5-06): The card POST turns CRLF into LF in the note before counting and sending it (D27 default).
- **Discovery** (affects B5-05, B5-06): tests/lib.sh fake_consumer lists the files already there before it returns and runs as $fake_consumer_pid; answer POSTs in the rig send Origin: null, as the sandboxed page does.
- **Question for Michael:** D27 (default): the card POST normalises CRLF to LF in the note, so a note at the textarea's limit with line breaks is accepted. Keep it?
- **Proposed change:** B5-06: close the concurrent double tap (answer-derived request ids + Run A refusing handled ids) and give 21-report-serve's webhooks allowedOrigins, with the same cross-origin rig check.
- *24-B5-04 · claude-opus-5-5*

### 2026-10-27 17:39 · B5-03 · passes

workflows/40-phone-card.json (ReporterCard0040) builds the card for park/needs_michael/blocked through the fake Claude, writes files/cards/<id>.json, remembers the question (askQuestion, also on a re-send) and sends the D9 ntfy; the intake routes card kinds to it (Plain ntfy gone) and 422s a card kind with a bad bundle path.

- **Files:** workflows/40-phone-card.json, workflows/10-event-intake.json, lib/card.js, lib/intake.js, scripts/code-nodes.json, tests/checks/card.sh, tests/checks/intake.sh, tests/fakes/responses/card.json, tests/fakes/README.md, tests/unit/card.test.mjs, tests/unit/intake.test.mjs, docs/decisions.md, +1 more
- **Verified:** .harness/check.sh on the commit: 68 passed, 0 failed (new rig checks: card built park/blocked/needs_michael, card ntfy public, card LLM body clean, card question remembered, card idempotent, card resend restores memory, intake routes to card; intake park 200 replaces the two plain-ntfy checks; intake rejects gains park context null/outside events/). node --test tests/unit/: 186 pass (8 new). grep -c interim workflows/10-event-intake.json = 0; sync-code-nodes --check: 17 in sync; n8n-docs validate_workflow: 40 and 10 valid, 0 errors (5 warnings: intended executeOnce). Opus review: no high/medium; its 3 low findings fixed (debrief read errors other than no-file fail the build; re-send runs askQuestion; D21 updated in place). Nothing live this session.
- **Tests:** 60 → 68
- **Dead end:** the plan's `Gather again` Merge (Check card event + Stored card text) for the re-send — Check card event runs on the build path too, so that Merge would get input 1 with no input 2 coming; built as a Set (`Card again`) reading $('Check card event') instead
- **Discovery** (affects B5-04, B6): In 40 both paths meet at `Memory op: ask` (Message: built carries {ntfy, memoryArgs}; Message: again builds both from the stored card); the ntfy node reads whichever Message: ran. B5-04's markAnswered can count on the row existing once any delivery of the event reached the card.
- **Discovery** (affects B5-06, B6): The rig has no ledger debrief.md, so the Debrief text -> ctx.debrief_md path (live always has one) is covered by units only; a sanitised fixtures/harness/ledger/debrief.md naming dj-2026-10-17 plus a card.sh assertion on the LLM body would cover it end to end.
- **Discovery** (affects B6, run): validateEvent now 422s every routed kind whose bundle path fails the guard when the intake passes stateDir (context null included); mainCheckEvent/report-now unchanged (no stateDir).
- **Discovery** (affects run): /home/mh550/projects/agent-harness/lib/check.sh prints 'no suite configured or detected (CHECK_CMD)' for this project; .harness/check.sh is the suite and was run in full.
- **Proposed change:** Set CHECK_CMD for n8n-home (.harness/check.sh) so the harness's own suite run checks it instead of reporting nothing to run.
- **Proposed change:** B5-06 or B6: add a sanitised ledger debrief.md fixture and a card check that its text reaches the card prompt.
- *23-B5-03 · claude-opus-5-5*

### 2026-10-27 17:17 · B5-02 · passes

lib/card.js: card question/ctx/prompt/parse/repair, card file and view, phone HTML, answerText, requestDrafts, buildRequest (request JSON v1), ntfyMessage (D9), renderResult, mainCardPrompt. memory.js gains askQuestion/markAnswered in apply; pageShell takes page CSS; docs/memory.md says tradeoff. Opus review: 4 fixes in.

- **Files:** lib/card.js, lib/memory.js, lib/report.js, tests/unit/card.test.mjs, tests/unit/memory.test.mjs, docs/memory.md
- **Verified:** node --test tests/unit/: 145 -> 177 pass, 0 fail (29 new in card.test.mjs, 3 in memory.test.mjs; each written red first). node --check on lib/card.js, memory.js, report.js; require('./lib/index.js').load(['memory.js','report.js','card.js']) returns mainCardPrompt/renderCard/askQuestion. .harness/check.sh: 60 passed, 0 failed. Opus review of the diff: 1 Important + 4 Minor; 1,2,3,5 fixed with regression tests (review 1-5), 4 left as a discovery. No live commands run.
- **Tests:** 60 → 60
- **Discovery** (affects B5-03, B5-04): Only mainCardPrompt of the plan's main* entries is in lib/card.js; mainCardSelect/Parse/Resend (B5-03) and mainCardLink/Page/Requests/RequestFile/Result (B5-04) are left to the features that fix their node item shapes. selectForCard takes the Card token as a 7th argument (ctx.token).
- **Discovery** (affects B5-04, B5-06): Browsers send textarea line breaks as CRLF while maxlength counts LF, so a note at NOTE_MAX (998) with k newlines arrives as 998+k characters; with answer_text near its 3000 cap answerText then throws. B5-04's POST check should count the note as received and answer 400 naming it (or normalise CRLF before counting only).
- **Discovery** (affects B5-03, B5-04): cardQuestion and the card's run are always event.run (review 3): the bundle's runs[0] stands in only for picking the question, so a bundle missing the event's run can't route an answer to another run.
- **Discovery** (affects B5-03, B5-06): renderCard/renderResult/ntfyMessage refuse a PUBLIC_BASE_URL that isn't http(s) printable ASCII, so ntfy headers stay ASCII without ntfyHeader (which lives in intake.js and can't share a scope with report.js).
- **Discovery** (affects B5-04, B5-06): pageShell(title, body, css) takes a page's extra CSS; card pages pass CARD_CSS (class rec, never the word recommended).
- **Proposed change:** B5-02 step 5's code-nodes.json mapping belongs to B5-03/B5-04 (as it says); the plan's lib/card.js table could say the main* entries land with those features.
- *22-B5-02 · claude-opus-5-5*

### 2026-10-27 16:57 · B5-01 · passes

Wrote docs/plans/2026-10-22-B5-phone-card.md: card schema and prompts, workflows 40 (build) and 41 (serve/answer), request JSON v1, token, poll, ntfy (D9), memory rules, rig checks by name. Added D24-D26; D5, D7, D9 updated in place. An Opus review's 8 Important and 11 Minor findings folded in.

- **Files:** docs/plans/2026-10-22-B5-phone-card.md, docs/decisions.md
- **Verified:** Each B5-01 step checked against the plan text. .harness/check.sh: 60 passed, 0 failed, before and after the edits. Fixture facts read with jq from fixtures/bundles. Request/result JSON copied from Run A's spec via gh api (contents/docs/specs/2026-10-22-n8n-events.md). No live commands run.
- **Tests:** 60 → 60
- **Dead end:** Origin/Referer check against cross-site posts to card-answer — the CSP sandbox gives the card page an opaque origin, so its own form posts Origin: null. A per-card Crypto token in a hidden field is used instead
- **Dead end:** serving the desk report's card links (&q=, &run=) from memory in B5 (first draft of D26) — the report id is on the public ntfy topic too, so these links need a token in the report's links. That is a B4 change, so they were moved to a proposed feature
- **Discovery** (affects B5-02, B5-06): Report rows store options as {label, tradeoff} (applyReport takes the report's resolved options), but docs/memory.md says {label, tradeoffs}. B5-02 corrects the doc, and readers accept either key.
- **Discovery** (affects B5-03, B5-04, B6): In 2.42.5, $('Memory save').first() throws 'hasn't been executed' on a path that skipped that node. Guard it with $('X').isExecuted. A successful Read/Write Files read drops its input json, so config reaches a later Code node only through a Merge.
- **Discovery** (affects B5-04, run): Request ids are '1-<uuid>' (answer) and '2-<uuid>' (continue), so the answer sorts first by name as well as by mtime, whichever key Run A's 'oldest first' uses.
- **Discovery** (affects B5-06, B6, run): The desk report's 'Answer on the card' and 'Decide on the card' links still 404 after B5 (D26).
- **Question for Michael:** D26: the desk report's card links need a per-report token, so B5 leaves them as 404. Should a feature (proposed B5-07) add them, or should the report drop those buttons and point to the phone card instead?
- **Question for Michael:** D25: a card answer marks the question answered in memory as soon as the request file is written, not when the harness confirms it. Is that right, or should it wait for an ok result?
- **Proposed change:** Add B5-07: the desk report's card links (D26): a per-report token in reports.jsonl and the links, question cards built from the memory row, and a re-queue card that sends continue with the note as brief.
- **Proposed change:** B5-01 step 2 names a '.json.tmp then rename' option. Read/Write Files has no rename, so the plan writes the final file directly (D25).
- **Proposed change:** B5-02 step 1: a continue request carries no text. The step's 'exactly the keys v, id, at, verb, run, text, brief, source, event' reads as the allowed set, not as keys every request has.
- **Proposed change:** B5-06 checklist: add a check that Run A's harness-requests path unit runs again for a request it skipped while young, without hitting systemd's start limit.
- **Proposed change:** CLAUDE.md says the suite runs in under a minute. It took 70 s today, and B5 adds about 35 s.
- *21-B5-01 · claude-opus-5-5*

### 2026-10-27 16:35 · verify B4 · passes

Suite 60/0, units 145/145. All 8 features hold on re-run, incl. B4-08 step 2: every Code node is 3 lines requiring n8n-home-lib; $env only in Config. No live actions taken.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| B4-01 | 1 | ls docs/plans; read B4-desk-report.md | plan exists; workflows built to it (intake 15 nodes, report 36) | yes |
| B4-01 | 2 | read plan schemas | report_plan/check_grade schemas present; suite 'report LLM body clean' passes | yes |
| B4-01 | 3 | read plan; suite report served/guards/built | file name, webhooks, guard, ntfy as built and tested | yes |
| B4-01 | 4 | check.sh | `.harness/check.sh`: 60 passed, 0 failed; `node --test tests/unit/index.js`: 145/145 | yes |
| B4-02 | 1 | suite 'intake debrief 200' | PASS | yes |
| B4-02 | 2 | suite 'intake park plain ntfy' | PASS | yes |
| B4-02 | 3 | suite 'intake rejects' | PASS (non-JSON 422) | yes |
| B4-02 | 4 | parsed workflows/10-event-intake.json; grep -c ntfy.sh | nodes Harness event (POST), Validate v1 + kind, Store event, Respond: received, Route by kind; executeWorkflow waitForSubWorkflow false -> ReporterReport20; grep 0 | yes |
| B4-02 | 5 | check.sh | `.harness/check.sh`: 60 passed, 0 failed; `node --test tests/unit/index.js`: 145/145 | yes |
| B4-03 | 1 | node --test tests/unit | 145 pass incl. report.test.mjs | yes |
| B4-03 | 2 | unit tests lintBareIds | pass | yes |
| B4-03 | 3 | unit tests svgDiagram | pass | yes |
| B4-03 | 4 | unit tests buildPromptInput/messagesRequest | pass; suite 'report LLM body clean' | yes |
| B4-03 | 5 | node scripts/sync-code-nodes.mjs --check | in sync: 12 node(s) | yes |
| B4-03 | 6 | check.sh | `.harness/check.sh`: 60 passed, 0 failed; `node --test tests/unit/index.js`: 145/145 | yes |
| B4-04 | 1 | suite 'report built' | PASS | yes |
| B4-04 | 2 | suite 'report memory saved' | PASS | yes |
| B4-04 | 3 | suite 'report ntfy', 'report LLM body clean' | PASS; anthropic-version sent | yes |
| B4-04 | 4 | suite 'report-now' | PASS | yes |
| B4-04 | 5 | sync --check; python scan of workflows | in sync; ids fixed; intake points at ReporterReport20 | yes |
| B4-04 | 6 | check.sh | `.harness/check.sh`: 60 passed, 0 failed; `node --test tests/unit/index.js`: 145/145 | yes |
| B4-05 | 1 | suite 'report served' | PASS | yes |
| B4-05 | 2 | suite 'report guards' | PASS | yes |
| B4-05 | 3 | suite 'report-check grades', 'report-check skipped' | PASS | yes |
| B4-05 | 4 | workflows/21-report-serve.json present, validated by suite | PASS | yes |
| B4-05 | 5 | check.sh | `.harness/check.sh`: 60 passed, 0 failed; `node --test tests/unit/index.js`: 145/145 | yes |
| B4-06 | 1 | suite 'report 2 brief concept' | PASS | yes |
| B4-06 | 2 | suite 'report 2 shaky again' | PASS | yes |
| B4-06 | 3 | suite 'report 2 follow-up question' | PASS | yes |
| B4-06 | 4 | suite 'reports index' | PASS | yes |
| B4-06 | 5 | suite fakes check; tests/fakes/README.md | present, fakes group passes | yes |
| B4-06 | 6 | check.sh | `.harness/check.sh`: 60 passed, 0 failed; `node --test tests/unit/index.js`: 145/145 | yes |
| B4-07 | 1 | ls docs/plans/2026-10-22-B4-what-michael-sees.md | exists | yes |
| B4-07 | 2 | file docs/plans/screenshots/B4-report-*.png; ls -l | 1280x2960 x2, 390x4060 x2, each ~350-400 KB | yes |
| B4-07 | 3 | read doc | per-section description present | yes |
| B4-07 | 4 | read doc | defects listed | yes |
| B4-07 | 5 | check.sh | `.harness/check.sh`: 60 passed, 0 failed; `node --test tests/unit/index.js`: 145/145 | yes |
| B4-08 | 1 | read B4-review.md; git log | findings table, 'Open Critical/Important: none', RED/GREEN commits separate | yes |
| B4-08 | 2 | python scan of workflows/*.json | max Code node 3 lines in all 4 workflows; $env outside Config none in 10/20/21 | yes |
| B4-08 | 3 | ls docs/workflows.md; grep checklist | exists; report URL and report-now in checklist | yes |
| B4-08 | 4 | grep docs/decisions.md; CLAUDE.md | D4/D7/D9 amended in place; CLAUDE.md gotcha accurate (n8n-home-lib) | yes |
| B4-08 | 5 | check.sh | `.harness/check.sh`: 60 passed, 0 failed; `node --test tests/unit/index.js`: 145/145 | yes |

- *163310-verify-B4 · claude-sonnet-5-5*

### 2026-10-27 16:33 · B4-08 · passes

Step 2 now holds literally: every Code node is 3 lines requiring lib/ as the module n8n-home-lib (lib/index.js; compose and rig mount it read-only, NODE_FUNCTION_ALLOW_EXTERNAL allows it; deploy.sh copies it, keeps lib.prev, --check verifies it). D6/D23 updated in place; Opus review L1-L7 fixed RED then GREEN. Suite 60/60, units 141->145.

- **Files:** lib/index.js, lib/package.json, scripts/sync-code-nodes.mjs, scripts/deploy.sh, deploy/compose.yml, tests/run.sh, tests/lib.sh, tests/checks/code-sync.sh, tests/checks/compose.sh, tests/checks/deploy.sh, tests/unit/lib-module.test.mjs, workflows/*.json, +5 more
- **Verified:** Throwaway n8n-test-modx container (2.42.5): a Code node require of a mounted module with NODE_FUNCTION_ALLOW_EXTERNAL works (n8n execute -> out 'hi x', then lib load: 78 functions). .harness/check.sh 60 passed 0 failed (rig: report built/served/report-check/report-now/intake/memory all through the module); code-sync 22/0 incl. 'no Code node over 150 lines' (all 12 nodes are 3 lines); compose 29/0; deploy 43/0; node --test 145/145; sync --check in sync 12; n8n-docs validate_node code: valid. --check probe run in the image: loads with the mount (rc 0), fails without (rc 1). No live command run this session.
- **Tests:** 141 → 145
- **Dead end:** tree-shaking the embedded lib per node — Render HTML still needs 963 lines (799 code-only), Select memory 412, Parse plan 270: splitting into 150-line nodes would take 10+ chained nodes and split renderReport
- **Dead end:** D23's first reading (the rule meant lib functions) — the B4 verify failed the literal step
- **Discovery** (affects B5, B6, run): n8n 2.42.5's task runner lets a Code node require a module bind-mounted at /usr/local/lib/node_modules/<name> when NODE_FUNCTION_ALLOW_EXTERNAL names it; lib/ is now that module (n8n-home-lib), so Code nodes are 3 lines and a lib change needs only the sync if a node's files or entry change
- **Discovery** (affects B6, run): The next live deploy changes compose (new ./lib mount + env) and copies lib/ to /srv/n8n/lib; workflows from B4-08 on fail every Code node without that mount, so compose, lib (lib.prev) and the database roll back together
- **Question for Michael:** D6/D23 (updated): Code nodes now require lib/ as a mounted module (n8n-home-lib) instead of embedding it, so 'no Code node over 150 lines' holds literally (3 lines each). The cost: the workflows need the lib mount to run, and a deploy changes compose. Keep this, or would you rather have the embedded lib back (and the 150-line rule dropped)?
- **Proposed change:** CLAUDE.md ## Live system → Deploy and rollback: deploy.sh also copies lib/ to /srv/n8n/lib (keeping the previous one in /srv/n8n/lib.prev); a rollback past B4-08 restores compose, lib (from lib.prev) and the database snapshot together, never compose alone. Snapshots could add `cp -a /srv/n8n/lib /srv/n8n/lib.pre-<run-id>`.
- *20-B4-08 · claude-opus-5-5*

### 2026-10-27 16:02 · verify B4 · not yet

Suite 60/0, units 141/141. All steps hold except B4-08 step 2: Code nodes are 1575 lines each (whole lib embedded, D6); D23 default reinterprets the 150-line rule as per function. Literal step fails; Michael to rule or split lib per node.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| B4-01 | 1 | ls docs/plans/2026-10-22-B4-desk-report.md; read plan; workflow node names vs workflows/ | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-01 | 2 | read plan schemas; unit tests assert refs not values (renderReport cost rows from ledger) | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-01 | 3 | read plan; suite checks named report built/served/guards/report-check/report-now exist | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-01 | 4 | `.harness/check.sh`: 60 passed, 0 failed | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-02 | 1 | suite PASS `intake debrief 200`; read tests/checks/intake.sh | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-02 | 2 | suite PASS `intake park plain ntfy` | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-02 | 3 | suite PASS `intake rejects` | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-02 | 4 | python over workflows/10-event-intake.json: id ReporterIntake10, 3 stickies, waitForSubWorkflow false at line 323; grep -c ntfy.sh = 0 | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-02 | 5 | `.harness/check.sh`: 60 passed, 0 failed | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-03 | 1 | node --test tests/unit/index.js | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-03 | 2 | unit tests lintBareIds/gloss | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-03 | 3 | unit tests svgDiagram/@media | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-03 | 4 | unit tests buildPromptInput/buildMessagesBody | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-03 | 5 | node scripts/sync-code-nodes.mjs --check | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-03 | 6 | `.harness/check.sh`: 60 passed, 0 failed | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-04 | 1 | suite PASS `report built` | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-04 | 2 | suite PASS `report memory saved` | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-04 | 3 | suite PASS `report ntfy`, `report LLM body clean` | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-04 | 4 | suite PASS `report-now` | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-04 | 5 | sync --check: in sync 12 nodes; workflow id ReporterReport20, 6 stickies | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-04 | 6 | suite | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-05 | 1 | suite PASS `report served` | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-05 | 2 | suite PASS `report guards` | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-05 | 3 | suite PASS `report-check grades`, `report-check skipped` | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-05 | 4 | unit tests on form action/Skip; workflow 21 ids+stickies | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-05 | 5 | suite | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-06 | 1 | suite PASS `report 2 brief concept` | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-06 | 2 | suite PASS `report 2 shaky again` | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-06 | 3 | suite PASS `report 2 follow-up question` | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-06 | 4 | suite PASS `reports index` | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-06 | 5 | tests/fakes/responses report_plan.<id>.json + README | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-06 | 6 | suite | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-07 | 1 | doc lines 15-21 quote Title 'Desk report ready', body, Click shape | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-07 | 2 | `file` on 4 PNGs: 1280x2960 x2, 390x4060 x2; all >300 KB; HS command in doc line 37 | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-07 | 3 | doc sections exist (read) | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-07 | 4 | defects listed in doc (read; B4-08 review rows P1-P6 map to them) | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-07 | 5 | `.harness/check.sh`: 60 passed, 0 failed | Re-ran/read it; matches the step (suite 60/60, units 141/141 in my run) | yes |
| B4-08 | 1 | git log: B4-08 RED commits c80dd40,59e2810,36606ab precede GREEN efb7693,0c275e2,aaf25de; review.md ends 'Open Critical/Important: none'; P rows present | as read | yes |
| B4-08 | 2 | `$env` only in Config nodes (python scan) and one messagesRequest holds; BUT Code nodes are 146-1575 lines (Select memory, Build prompt, Parse plan, Render HTML, Check id... each 1575) so 'no Code node over 150 lines' fails literally; D23 default reinterprets it as lib functions | Code nodes of 1575 lines each (whole lib embedded) | no |
| B4-08 | 3 | docs/workflows.md has sections 10, 30, 20, 21; live checklist lines 168-176 have tailnet URL and report-now | as read | yes |
| B4-08 | 4 | docs/decisions.md D4/D7/D9 amended/confirmed; D23 present; CLAUDE.md still accurate | as read | yes |
| B4-08 | 5 | `.harness/check.sh`: 60 passed, 0 failed | as read | yes |

- *155955-verify-B4 · claude-sonnet-5-5*

### 2026-10-27 15:59 · B4-08 · passes

B4 reviewed (two Opus passes) and simplified; B4-07's 9 page defects fixed (tall diagram, stacked cost table, tappable glosses, cut glossary text, question glosses below it, local time) plus 17 review findings, RED then GREEN. One Claude request pattern; only Config reads $env. docs/workflows.md, checklist step 13, D4/D7/D9 confirmed, D23 default. Suite 60/60, units 118 -> 141.

- **Files:** lib/report.js, lib/intake.js, workflows/10-event-intake.json, workflows/20-desk-report.json, workflows/21-report-serve.json, tests/unit/report.test.mjs, tests/unit/intake.test.mjs, tests/checks/report.sh, tests/checks/intake.sh, docs/workflows.md, docs/plans/2026-10-22-B4-review.md, docs/plans/2026-10-22-live-checklist.md, +3 more
- **Verified:** Full suite .harness/check.sh: 60 passed, 0 failed (after aaf25de; docs-only after). Unit tests 141/141 (were 118). RED commits c80dd40, 59e2810, 36606ab each failed their new tests on the code before them (checked by running them); GREEN efb7693, 0c275e2, aaf25de. A Sonnet agent screenshot the rig-built page (KEEP=1, report group) at 390 and 1280, light and dark: diagram vertical at 390 with ~13 px text, cost table stacked with labels, question without inline glosses and a legend line, glossary texts ending in an ellipsis, 'on pop-os' after host paths, 'Built at 2026-10-27 15:34 (UTC-04:00)', Skip apart from the button; I checked page.html myself (Built at line, 3 'on pop-os', tall svg present). n8n-docs validate_node on the new Claude HTTP node: valid, 0 warnings. Rig container removed afterwards. Nothing live was touched.
- **Tests:** 118 → 141
- **Dead end:** gloss the diagram label first, then cut it to 22 — the cut could leave Q99 bare (lint fails); the raw label is now cut shorter until its glossed form fits
- **Dead end:** tall diagram with a level's boxes side by side — a fan-out made it 400-541 px at its own size (second review); now one column with side lanes
- **Dead end:** matching known concepts against every string of the plan — file paths and run ids matched concept terms; now proseOf skips ref/path/run keys
- **Discovery** (affects B5, B6, run): The intake now refuses (422) a debrief whose bundle path the report would refuse; its Config passes HARNESS_STATE_DIR. An unset HARNESS_STATE_DIR therefore 422s every debrief (the harness sends its own ntfy).
- **Discovery** (affects B5, B6): Config in 20 passes now_local ($now.toISO(), GENERIC_TIMEZONE) beside the UTC now; both Claude nodes are url = {{ $json.url }} from messagesRequest, so a new LLM call should reuse messagesRequest.
- **Discovery** (affects B5, B6): Left for B6: the 502 grading branch is unit-tested only (the fake can't fail on demand); a wide-diagram arrow that skips a level still crosses the box between; 'Answer on the card' 404s until B5.
- **Question for Michael:** D23 (default): I read 'no Code node over 150 lines' as no lib function over 150 lines, since D6 embeds the whole lib in each node (1464 lines of generated jsCode for a report node). Is that what you meant, or do you want lib/report.js split per node?
- **Proposed change:** B4-08 step 2 should say 'no lib/*.js function over 150 lines' (D23): every report Code node embeds the shared lib by D6.
- *19-B4-08 · claude-opus-5-5*

### 2026-10-27 15:20 · B4-07 · passes

docs/plans/2026-10-22-B4-what-michael-sees.md: the recorded ntfy (Title 'Desk report ready', body 'Desk report ready. Tap to open.', Click <PUBLIC_BASE_URL>/webhook/report?id=<event id>), 4 full-page screenshots (1280/390, light/dark), the 8 sections described, the CSP-only sandbox, and 10 defects with lib/report.js line hints for B4-08. No code changed; suite 60/0.

- **Files:** docs/plans/2026-10-22-B4-what-michael-sees.md, docs/plans/screenshots/B4-report-1280-light.png, docs/plans/screenshots/B4-report-1280-dark.png, docs/plans/screenshots/B4-report-390-light.png, docs/plans/screenshots/B4-report-390-dark.png
- **Verified:** KEEP=1 tests/run.sh --only report: 9 passed, 0 failed; fake /_calls ntfy read (3 calls, report + 2 report-now). Screenshots with chrome-headless-shell 1248 against the kept rig; content height measured from a tall probe PNG (2921 px at 1280, 4017 at 390). file: 1280x2960 and 390x4060; sizes 348-400 KB. GET body byte-equal to the stored file; CSP sandbox header only, no wrapper. Card link 404 (B5), Skip 200. Rig torn down (docker ps shows no n8n-test-*). .harness/check.sh: 60 passed, 0 failed. Nothing live touched.
- **Tests:** 60 → 60
- **Dead end:** --force-dark-mode (and --enable-features=WebContentsForceDark) in headless shell — prefers-color-scheme stays light: the PNG was byte-identical to the light one; --blink-settings=preferredColorScheme=0 works
- **Discovery** (affects B4-08): B4-08 defects to fix (doc table): SVG diagram ~7 px text at 390 (width:100%), arrow labels overlap boxes (GAP_X 90), cost table's Wall time/Passing off-screen at 390 with no cue, <abbr> glosses invisible on touch (D31 unresolved only in title), glossary text cut mid-word by the bundle shown raw, bold Needs-you question 11 lines with nested parens, host paths unclickable, UTC footer time, Skip tight to button.
- **Discovery** (affects B5, B6, run): Playwright 1248's headless shell is at ~/.cache/ms-playwright/chromium_headless_shell-1248/chrome-headless-shell-linux64/chrome-headless-shell; dark mode needs --blink-settings=preferredColorScheme=0.
- **Discovery** (affects B4-08, B6): The bundle's glossary text arrives cut mid-word (e.g. D24 '…above the fl'); it comes from the harness side (Run A), so B4-08 can only mark it with an ellipsis.
- **Proposed change:** B4-07 step 2's binary path (chrome-linux/headless_shell) and --force-dark-mode are wrong for playwright 1248: use chrome-headless-shell-linux64/chrome-headless-shell and --blink-settings=preferredColorScheme=0 in later screenshot features.
- *18-B4-07 · claude-opus-5-5*

### 2026-10-27 15:14 · B4-06 · passes

Report 2 proves memory in the rig: new group report-memory (4 checks), the fake picks <title>.<metadata.user_id>.json (guarded), second canned plan, debrief-2 bundle amended (planted follow-up, N3-02 line, report 1's glossary, Q99), tests/fakes/README.md. No lib or workflow change was needed. 56 -> 60 checks.

- **Files:** tests/checks/report-memory.sh, tests/fakes/server.mjs, tests/fakes/README.md, tests/fakes/responses/report_plan.ae65cbf6-3f94-42cd-b9f9-bb9cae4d2c86.json, tests/checks/fakes.sh, tests/checks/fixtures.mjs, tests/unit/report.test.mjs, fixtures/bundles/ae65cbf6-3f94-42cd-b9f9-bb9cae4d2c86/context.json, fixtures/bundles/ae65cbf6-3f94-42cd-b9f9-bb9cae4d2c86/context.md, fixtures/README.md
- **Verified:** Red first: report-memory 3 FAIL (no plan 2), fakes 'llm canned by metadata.user_id' FAIL. Then .harness/check.sh: 60 passed, 0 failed (exit 0). KEEP=1 rig page read by hand: D24 one paragraph 'first explained in <a ...report?id=f1e03cb5...>', N3-02 full, 'Reverse log, explained again:', planted question 'asked before on' + 'since then:', footer clean (no bare IDs, nothing dropped). Mutation: removing the fake's id guard makes the fakes check FAIL. Opus review: 8 findings, all fixed (prompt check now on the D24 line 'already explained in report <id1>', report 1 re-dated to 2026-10-20 so the date check bites, every cost_usd > 0, N3-02's LLM text absent, statSync isFile, N3-02 facts). Nothing live this session.
- **Tests:** 56 → 60
- **Dead end:** a ../ user_id as the fake's escape probe — report_plan.../x.json is no escape: it passed with the guard removed; x/../report_plan.<id> reaches the real file through join() and does catch it
- **Discovery** (affects B4-07, B4-08): A glossary ID in the LLM's concepts_introduced is rendered from the glossary (full mode), never from the LLM's explanation; report-memory checks that explanation stays off the page.
- **Discovery** (affects B4-07, B5): debrief-2 now has 3 open questions (Gatus new q1, the planted follow-up q2, N3-02 new q3) and 6 glossary entries, H3-04 still first (memory.test keyGlossary reads [0]).
- **Discovery** (affects B4-07): In the rig both reports build on the same day; report-memory re-dates report 1's index row and question first_asked_at to 2026-10-20 in the scratch memory before report 2.
- **Proposed change:** B4-06 step 5 can drop the 'scope hint / report_plan_2' alternatives: the plan fixed metadata.user_id.
- *17-B4-06 · claude-opus-5-5*

### 2026-10-27 14:56 · B4-05 · passes

workflows/21-report-serve.json: GET /webhook/report?id= serves the stored page raw (guarded id, dated glob, 400/404 short pages, last-by-name for two dates); POST /webhook/report-check grades answers via one check_grade call and saves understanding through ReporterMemory30. Failed grading answers 502 with a link back. Rig group report-serve; 52 -> 56 checks, unit 104 -> 118.

- **Files:** workflows/21-report-serve.json, lib/report.js, scripts/code-nodes.json, workflows/20-desk-report.json, tests/checks/report-serve.sh, tests/fakes/responses/check_grade.json, tests/unit/report.test.mjs, docs/plans/2026-10-22-B4-desk-report.md, CLAUDE.md
- **Verified:** Every step verified, no live writes this session. Step 1: PASS report served, page served raw (body byte-equal to the file); headers: Content-Type text/html; charset=utf-8 and the CSP sandbox (allow-forms asserted); Needs you links absolute. Step 2: PASS report guards (all-zero uuid 404; nope, ../../etc/passwd, encoded, a/b, id*, empty, missing all 400; two dates serve the later; every Read node reads {{ $json.glob }} only). Step 3: PASS report-check grades: the fake got one check_grade call carrying both answers; D24 understood, concept/reverse-log shaky, last_checked set. PASS report-check skipped: blank answers 200 skipped, bad report 400, unknown 404, no LLM call. Step 4: form action absolute (asserted); 3 sticky notes; n8n-docs validate_workflow valid, 0 errors (2 executeOnce warnings) on a copy with code stubs. Step 5: .harness/check.sh 56 passed, 0 failed.
- **Tests:** 52 → 56
- **Dead end:** the plan's dated glob reports/[0-9]...-<id>.html in Read/Write Files as is — 2.42.5 reads [ ] literally by default (option literalBrackets, default true): 404 on an existing file. Fixed with options.literalBrackets: false.
- **Discovery** (affects B4-06, B5, run): Read/Write Files read in 2.42.5 has option literalBrackets (default true): [0-9] and ( ) are literal unless it is false. Gotcha added to CLAUDE.md.
- **Discovery** (affects B4-07): The served page is raw: n8n's HTML sandbox is only the CSP header (it includes allow-forms), so the check-yourself form POSTs from a browser.
- **Discovery** (affects B4-08): Opus review, left for B4-08: (a) grades follow the stored plan on disk now; a rebuild under the same id can change q1's concept, and gradeAnswers silently drops a key memory lacks while the page still says graded; (b) any GET read error, not only No file(s) found, answers 404 without failing the execution; (c) the Claude-error -> 502 branch is unit-tested but not rig-tested (the fake can't fail on demand).
- **Proposed change:** B4-05 step 2 says ?id=nope -> 404, but the 8-64 id guard makes it 400 (the plan already said so); the check uses the all-zero uuid for 404.
- *16-B4-05 · claude-opus-5-5*

### 2026-10-27 14:34 · B4-04 · passes

Desk report workflow 20 builds a report end to end in the rig: intake or report-now, bundle+ledger+memory, one Claude call via the fake, HTML+plan JSON under files/reports, memory applyReport, one D9 ntfy. New rig group report (7 checks), unit tests for mainCheckEvent and the main* entries, fake records usage, D22 env paths. Suite 45 -> 52 checks.

- **Files:** workflows/20-desk-report.json, lib/report.js, lib/intake.js, scripts/code-nodes.json, tests/checks/report.sh, tests/fakes/responses/report_plan.json, tests/fakes/server.mjs, tests/checks/fakes.sh, tests/lib.sh, deploy/compose.yml, tests/checks/compose.sh, tests/unit/report.test.mjs, +7 more
- **Verified:** .harness/check.sh: 52 passed, 0 failed (rig: report built, report memory saved, report ntfy, report LLM body clean, report-now, report-now refuses a bad event, report without a ledger; intake debrief not sent plain now waits for the real report ntfy). node --test tests/unit/: 112 pass. node scripts/sync-code-nodes.mjs --check: in sync, 7 nodes. n8n-docs validate_workflow on 20 (Code bodies stubbed): valid, 0 errors, 4 executeOnce warnings. Opus review: 1 Important (report-now wrote event id to memory) fixed, 2 Minor fixed (glob dir guard, weak asserts), 2 documented for B4-08. Nothing live.
- **Tests:** 45 → 52
- **Dead end:** dropping the Claude node's own anthropic-version header (plan to-check) — the anthropicApi credential sends x-api-key only: the fake recorded no anthropic-version, so the header stays
- **Discovery** (affects B4-05, B5, B6): n8n's error output item (continueErrorOutput/continueRegularOutput) keeps the input item's json beside `error`; a Code node must test for `error` before other shapes (the no-ledger rig check found mainSelect taking it for a second Check event item). Gotcha added to CLAUDE.md.
- **Discovery** (affects B4-08): A failed report-now build answers n8n's generic 500 {"message":"Error in workflow"}; a retried build or a report-now reusing an id rewrites the page and .json and sends the ntfy again while memory keeps the first build's rows. Recorded in the plan's As built for B4-08 to decide.
- **Discovery** (affects B4-05, B4-06): Every report run writes reports/<date>-<id>.json (the resolved plan: check_questions carry id q1.., q, expected, concept key, term) for report-check to grade against; reports.jsonl event is null for report-now builds.
- **Discovery** (affects B6, run): The bundle dir in event.context must now pass the id guard ^[A-Za-z0-9-]{8,64}$ (it goes into a glob). Harness bundle dirs are event uuids; a differently named dir would be refused.
- *15-B4-04 · claude-opus-5-5*

### 2026-10-27 14:10 · B4-03 · passes

lib/report.js: prompt input, Messages body, plan parse/resolve, 8-section HTML with ID glossing, bare-ID lint, light/dark CSS, inline SVG, cost table from the ledger, ntfy, memory args, grading helpers. memory.js: D20 question matching, D22 keyGlossary root, reworded follow-ups take new options. Unit tests 69 -> 104; suite 45/0.

- **Files:** lib/report.js, lib/memory.js, workflows/30-memory.json, tests/unit/report.test.mjs, tests/unit/memory.test.mjs, docs/plans/2026-10-22-B4-desk-report.md
- **Verified:** node --test tests/unit/: 104 pass, 0 fail (31 new in report.test.mjs, 4 new in memory.test.mjs). node scripts/sync-code-nodes.mjs --check: in sync: 2 node(s) (memory.js re-synced into 30-memory.json; no report.js map entry yet). .harness/check.sh: 45 passed, 0 failed (rig memory group included). Rendered the debrief fixture with a canned plan in scratch: lintBareIds [] and the 8 h2s in order. Opus review: 12 findings. Fixed with tests first: ledger values not escaped (XSS), one ID in two projects resolving two ways, a parked question carried into a later run asked twice, diagram-label and link-text lint, concept cap and repeated refs, a null glossary entry. Nothing live was touched.
- **Tests:** 45 → 45
- **Discovery** (affects B4-04, B4-05): The main* entries (mainSelect, mainPrompt, mainParse, mainRender, and the B4-05 serve ones) are not written yet. Each should arrive with the workflow whose node names it, so its item shapes match the real nodes. The bundle argument is context.json's object plus context_md (the text of context.md).
- **Discovery** (affects B4-04): reportNtfy(ctx, resolved, {baseUrl, priority, private}) differs from the plan's (ctx, meta, …): it needs the resolved plan's headline and the event's priority. memoryArgs(ctx, resolved, reportMeta) builds applyReport's args.
- **Discovery** (affects B4-08): A retried build of a report that reworded a follow-up does not render the same page. applyReport already rewrote the row, so the retry shows 'reads the same' instead of 'it used to read'. Retries are rare, and the wording difference is cosmetic.
- **Discovery** (affects B4-08): Review minors left for B4-08: the u<n> link refs are every URL in context.md (capped at 20), not the plan's click and harness-log URLs. The footer's unbacked-numbers check is substring-based (it misses short numbers and flags word/word). A brief line whose first_report was undone and is graded understood reads 'Michael understands it'.
- *14-B4-03 · claude-opus-5-5*

### 2026-10-27 13:36 · B4-02 · passes

Event intake: workflows/10-event-intake.json (ReporterIntake10) validates v1 + routed kinds in lib/intake.js, stores events/<id>.json, answers 200 (422 refused, 503 without NTFY_URL), sends debrief to ReporterReport20 async and park/needs_michael/blocked as a plain ntfy. Sync gains the {files, entry} map form. Suite 40 -> 45.

- **Files:** workflows/10-event-intake.json, lib/intake.js, tests/unit/intake.test.mjs, tests/checks/intake.sh, scripts/sync-code-nodes.mjs, scripts/code-nodes.json, tests/checks/code-sync.sh, tests/checks/workflows.sh, docs/plans/2026-10-22-B4-desk-report.md
- **Verified:** .harness/check.sh: 45 passed, 0 failed (rig: intake park plain ntfy, intake card kinds plain ntfy, intake rejects, intake debrief 200, intake debrief not sent plain; code-sync 17/17 incl. 'a named entry is called by the glue' and 'a named entry defined twice is refused'; workflows 8/8 incl. 'intake has no ntfy.sh'; unit 17 new intake tests, all pass). validate_workflow (n8n-docs MCP): valid, 0 errors, 0 warnings (on a copy without sticky notes and with a stub jsCode; the full-size call dropped its connection). KEEP=1 rig probe: a non-ASCII Title reaches ntfy as =?UTF-8?B?...?=, Authorization 'Bearer dummy-ntfy' (credential re-linked by name), the debrief execution fails after its 200 with 'Workflow is not active' (no ReporterReport20 yet). Opus review: 0 critical; 3 minor fixed (lone surrogate -> 422, debrief-not-plain check, needs_michael/blocked rig coverage), 1 important deferred (below). Nothing live touched.
- **Tests:** 40 → 45
- **Dead end:** validate_workflow with the full 14 KB workflow JSON — the MCP connection closed; a copy without sticky notes and with a stub jsCode validates
- **Discovery** (affects B4-02): A non-JSON POST gets 422 'Failed to parse request body' from n8n's Webhook node; no execution runs.
- **Discovery** (affects B6, B5): Once the intake has answered 200, a failed plain ntfy (credential missing or not linked live, wrong token, ntfy down past 3 tries) is lost: nothing tells Michael. The fix is spec §4.8's error workflow (plain ntfy from the stored event), with the intake setting settings.errorWorkflow to it.
- **Discovery** (affects B4-04): intake.sh's debrief wait switches itself to 'wait up to 60 s for the report ntfy' once a workflow with id ReporterReport20 exists, and fails 'intake debrief not sent plain' if that ntfy never comes; B4-04 must make the report send one ntfy, or adjust that wait.
- **Discovery** (affects B4-04): lib/intake.js has contextPaths (the bundle path guard, unit-tested) but no mainCheckEvent yet: B4-04 adds that entry for the report's 'Check event' node.
- **Proposed change:** B4-02 step 3 names one 'intake rejects' check; the group also has 'intake card kinds plain ntfy' and 'intake debrief not sent plain' (review findings).
- *13-B4-02 · claude-opus-5-5*

### 2026-10-27 13:22 · B4-01 · passes

Wrote docs/plans/2026-10-22-B4-desk-report.md: intake, report and serve workflows node by node, report_plan/check_grade schemas, prompts, renderer rules, ID gloss and lint, files, webhooks, ntfy text, canned answers and every rig check by name. Recorded D18-D22; D4, D6, D7 updated in place. An Opus review's 13 findings are folded in.

- **Files:** docs/plans/2026-10-22-B4-desk-report.md, docs/decisions.md
- **Verified:** Each B4-01 step checked against the plan text: step 1 node lists (intake per D7 with the Plain ntfy branch; report nodes in the step's order), step 2 schemas, refs-not-values rule and prompt texts, step 3 file name, the three webhooks, the id guard, CSS, SVG, the 8 h2 titles, ntfy text, the fake responses and the check names. Fixture facts read with jq. The n8n HTML sandbox was read from the pinned image's html-sandbox.js: it is a CSP header, not an iframe. .harness/check.sh: 40 passed, 0 failed, before and after. No live commands were run.
- **Tests:** 40 → 40
- **Dead end:** telling report-now from the intake by $json.body ?? $json in Config — a v1 event has its own body key (a string), so the event became that string (review finding 1); the plan now uses one Set node per trigger
- **Discovery** (affects B4-05, B4-07, B5): In 2.42.5 the webhook HTML sandbox is a CSP header ('sandbox allow-forms allow-scripts allow-popups allow-top-navigation-by-user-activation ...'), not an iframe/srcdoc wrapper. Pages are served raw, with an opaque origin, and forms can POST.
- **Discovery** (affects B4-04, B4-06): Neither debrief fixture has parked items. Report 1's question is the planted open question (run-level, feature null). B4-06 must amend the debrief-2 bundle: add the planted question, N3-02, the D24/N1-01/D-H1/M8 glossary entries and Q99. Its worktree is null, so keyGlossary needs HARNESS_WORKTREES_DIR (D22).
- **Discovery** (affects B4-02, B4-03): sync-code-nodes --check refuses any unmapped Code node in workflows/, so B4-02 must add the {files, entry} map form (D6 update) together with its own Code node.
- **Discovery** (affects B4-04): The fake's usage is ceil(raw bytes/4) and isn't recorded. B4-04 makes /_calls record each LLM answer's usage, so 'report memory saved' can compare it.
- **Discovery** (affects B4-02, B4-04, B4-05, B4-06): A debrief POST starts a report build that outlives its 200 response. Rig groups that post one must wait for that build to finish before their next check.
- **Question for Michael:** D18: a report's id is its debrief event id and its file is reports/<event-at date>-<id>.html (plus a .json of the plan). This replaces B3's <date>-<8 chars> id. OK?
- **Question for Michael:** D19: one Claude call per report, refs instead of values, and a metadata.user_id equal to the report id (used by the fake). OK to send that field to Anthropic?
- **Question for Michael:** D20: 'Needs you' also lists runs' open INBOX questions, matched across runs by exact text. Stale open rows stay open until you withdraw them. OK?
- **Question for Michael:** D21: memory writes are not serialised (rare, human-paced writers). Accept the small lost-update risk?
- **Question for Michael:** D22: two new fixed path settings, HARNESS_STATE_DIR and HARNESS_WORKTREES_DIR, go in compose and ship with the B6 deploy. OK?
- **Question for Michael:** D7 update: the intake answers 503 while NTFY_URL is empty, so the harness sends its own ntfy. OK?
- **Proposed change:** B4-04 step 1 node order: the plan keeps 'Memory save, ntfy'. The save's error output also goes to ntfy, then the execution fails.
- **Proposed change:** B4-01 step 2 schema: check_questions[] gains 'concept', and changes[].see_it_yourself becomes {how, ref} (D19).
- **Proposed change:** B4-05 step 2: '?id=nope' is 4 characters, so the {8,64} guard returns 400. Use the all-zero uuid for the 404 case.
- **Proposed change:** B4-05 step 3: post q1 and q2. An unanswered question grades nothing, yet the step expects one understood and one shaky.
- **Proposed change:** B4-06 step 3: the repeated question is the planted run-level open question, not a park question (the debrief fixtures have no parked items).
- **Proposed change:** B4-04 step 5 vs B4-08 step 2: the Claude URL must read $env.LLM_BASE_URL, but 'Config is the only $env reader' forbids that. One of the two steps should give way.
- **Proposed change:** B4-08 'no Code node over 150 lines': synced nodes embed lib/memory.js and lib/report.js whole. Count the entry functions instead.
- *12-B4-01 · claude-opus-5-5*

### 2026-10-27 12:55 · verify B3 · passes

All four B3 features hold: suite 40/0, 52 unit tests, sync check (and drift detection in scratch), validate_workflow clean, review table has no open Critical/Important, docs match SCHEMA.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| B3-01 | 1 | ls docs/plans/2026-10-22-B3-memory.md; grep SCHEMA in lib/memory.js | plan exists; lib SCHEMA keys for concepts/questions/reports match the step; memory-docs suite group passes | yes |
| B3-01 | 2 | awk function list of lib/memory.js; memory-docs check | selectConcepts, matchQuestions, applyReport, gradeAnswers, parseJsonl all defined; plan names only defined functions | yes |
| B3-01 | 3 | read workflows/30-memory.json, sync script, tests/checks/code-sync.sh | sub-workflow with trigger, Read/Write nodes, rig driver and sync --check all exist (apply op added, D17) | yes |
| B3-01 | 4 | ls docs/memory.md; unit test count | docs/memory.md exists; 52 unit tests; plan lists tests | yes |
| B3-01 | 5 | `.harness/check.sh` | 40 passed, 0 failed | yes |
| B3-02 | 1 | node --test tests/unit/ | 52 tests pass, 0 fail, in tests/unit/memory.test.mjs | yes |
| B3-02 | 2 | grep require/import and top-level return in lib/memory.js; grep vm.runInNewContext in test | no matches in lib; test loads via vm.runInNewContext | yes |
| B3-02 | 3 | node scripts/sync-code-nodes.mjs --check; suite groups | 'in sync: 1 node(s)' rc 0; suite shows PASS unit tests and code-sync group | yes |
| B3-02 | 4 | appended '// drift' to Memory rules jsCode in /tmp copy, ran --check; node --check / bash -n on all files | 'drift: workflows/30-memory.json: Memory rules' rc=1; no syntax errors | yes |
| B3-02 | 5 | `.harness/check.sh` | 40 passed, 0 failed | yes |
| B3-03 | 1 | inspect workflows/30-memory.json; sync --check; mcp validate_workflow | id ReporterMemory30, Execute Workflow Trigger, 4 stickies, Read/Write paths on $env.REPORTER_FILES_DIR, Code synced; validate_workflow valid:true, 0 errors, 0 warnings | yes |
| B3-03 | 2 | `.harness/check.sh` memory group | PASS memory load empty / load creates no files / save / reload / save again / corrupt line (+ keys in schema order, one object per line) | yes |
| B3-03 | 3 | suite check 'memory files human-readable' | PASS (jq per line, line length check) | yes |
| B3-03 | 4 | read docs/memory.md; memory-docs group | schemas, examples, correct-it and backup sections present; group passes | yes |
| B3-03 | 5 | `.harness/check.sh` | 40 passed, 0 failed | yes |
| B3-04 | 1 | read docs/plans/2026-10-22-B3-review.md; git log | findings table, 'Open Critical/Important: none'; RED commits ec57fb9/1bfa8e5/64eb40a precede GREEN 3a8d87d/b577356 | yes |
| B3-04 | 2 | awk function lengths in lib/memory.js; grep glue; read workflow nodes | longest function 39 lines; glue generated by sync script; every node does work (Gather merges, Switch routes) | yes |
| B3-04 | 3 | memory-docs suite group; grep decisions D3/D6/D17 | docs match SCHEMA keys; D3/D6 confirmed by build, D17 updated | yes |
| B3-04 | 4 | `.harness/check.sh` | 40 passed, 0 failed | yes |

- *125348-verify-B3 · claude-sonnet-5-5*

### 2026-10-27 12:53 · B3-04 · passes

B3 review in docs/plans/2026-10-22-B3-review.md (21 rows). Fixed: save refuses a file read empty or cut short; save merges rows; answered beats a loose follow-up; main refuses stray items; cost rounding. New memory-docs group checks the docs against SCHEMA. D3/D6 confirmed, D17 updated. Suite 35 -> 40.

- **Files:** lib/memory.js, lib/memory-node.js, workflows/30-memory.json, tests/unit/memory.test.mjs, tests/checks/memory.sh, tests/checks/unit.sh, tests/checks/memory-docs.sh, tests/checks/memory-docs.mjs, docs/plans/2026-10-22-B3-review.md, docs/plans/2026-10-22-B3-memory.md, docs/memory.md, docs/decisions.md
- **Verified:** git diff a7ad73e...HEAD -- lib scripts workflows tests docs > /tmp/b3.diff (2003 lines); two Opus reviews (B3 diff, then the fix diff). Each finding was reproduced with node vm before fixing. RED commits ec57fb9, 1bfa8e5, 64eb40a (rig cut-short check FAILed on the old lib: status 200, 476 bytes written); GREEN 3a8d87d, b577356. Longest lib/memory.js function is applyReport at 39 lines; sync --check in sync; memory-docs proves itself on 4 broken copies. .harness/check.sh: 40 passed, 0 failed. No live commands run.
- **Tests:** 35 → 40
- **Dead end:** asserting the cut-short refusal's message in the rig response — the rig webhook answers only {"message":"Error in workflow"}; the check expects 500 and reasons from the passing empty-file load instead
- **Discovery** (affects B4, B5): Memory save now merges rows key by key (B5 may send {id, status, answer, answered_at, via} alone), refuses a file read empty or cut short (the execution fails with 500), and main throws on a second call item: send exactly one item to ReporterMemory30.
- **Discovery** (affects B4-01): Left for B4-01 (review rows 12, 13, 21): stale open questions the run no longer parks steer the any-wording follow-up match; keyGlossary roots on the first run's worktree; overlapping apply calls can still lose an update, so decide whether memory calls need serialising.
- **Discovery** (affects B4, B5): Extract From File (text) on a 0-byte file gives a string text in 2.42.5: load of an empty file returns empty rows.
- **Proposed change:** B4-01 should state how memory writes are serialised (one writer or a lock) and how stale open questions are closed.
- *11-B3-04 · claude-opus-5-5*

### 2026-10-27 12:36 · B3-03 · passes

workflows/30-memory.json (ReporterMemory30, active, 8 nodes + 4 stickies, Code node synced from lib/memory*.js) loads/saves/applies the three JSONL files; tests/workflows/rig-memory.json drives it; tests/checks/memory.sh adds 14 rig checks; workflows check 'sub-workflows are marked active'; docs/memory.md. Opus review: 2 Important + 7 Minor fixed. Suite 21 -> 35, 0 failed.

- **Files:** workflows/30-memory.json, tests/workflows/rig-memory.json, tests/checks/memory.sh, tests/checks/workflows.sh, scripts/code-nodes.json, docs/memory.md
- **Verified:** .harness/check.sh: 35 passed, 0 failed (memory group 14 PASS: load empty, load creates no files, save, save returns one item per file written, lines one object each, keys in schema order, reload, reload stable, save again, save unchanged, apply, corrupt line, save keeps the corrupt line, files human-readable). Mutation: write node append:true -> save again, save unchanged, apply FAIL (12/15); active:false on 30-memory.json -> 'sub-workflows are marked active' FAIL. node scripts/sync-code-nodes.mjs --check: 'in sync: 1 node(s)'. n8n-docs validate_workflow (sticky notes dropped, jsCode stubbed to a one-line main + the glue since the 15KB lib is unit-tested): 30-memory {"valid":true,"errorCount":0,"warningCount":0,"totalNodes":8,"validConnections":9,"expressionsValidated":6}; rig-memory {"valid":true,"errorCount":0,"warningCount":0,"totalNodes":4,"validConnections":3}. bash -n on both .sh files. Nothing live.
- **Tests:** 21 → 35
- **Dead end:** jsonl_problems called with two args — kind was undefined; the node helper needs the file kind as a third arg
- **Discovery** (affects B3-04, B4, B5): All the B3-01 'to check' items hold in 2.42.5: publish:workflow accepts an Execute-Workflow-Trigger-only workflow; Merge append runs with input 2 from either the File text or the read error branch; Extract From File keepSource json keeps fileName; the default callerPolicy lets CLI-imported callers in; Execute Workflow 1.4 with a passthrough trigger needs no input mapping. No fallback nodes needed.
- **Discovery** (affects B4, B5, B3-04): A save/apply that writes files returns the Write node's items to the caller: one {fileName: <abs path>} per file written (up to 3), not the {written} status item (that comes back only when nothing changed). B4/B5 nodes after a memory save must set executeOnce or they run up to 3 times.
- **Discovery** (affects B6-05): import:workflow logs 'Deactivating workflow "30 memory (sub-workflow)"' before the rig publishes it: deploy.sh's publish step (D12) is what makes it callable live.
- **Proposed change:** B3-04: docs/plans/2026-10-22-B3-memory.md 'Callers rely only on …' should say what save/apply return when files are written ({fileName} per file) and that callers run once after it (executeOnce).
- *10-B3-03 · claude-opus-5-5*

### 2026-10-27 12:22 · B3-02 · passes

lib/memory.js (rules + helpers) and lib/memory-node.js (main) with 44 node --test unit tests; scripts/sync-code-nodes.mjs (+ --check, jsCode-only rewrite) and scripts/code-nodes.json ({} until B3-03); new groups unit and code-sync run before the container. Opus review: 1 Important + 7 Minor fixed TDD. Suite 19 -> 21, 0 failed.

- **Files:** lib/memory.js, lib/memory-node.js, tests/unit/memory.test.mjs, tests/unit/index.js, scripts/sync-code-nodes.mjs, scripts/code-nodes.json, tests/checks/unit.sh, tests/checks/code-sync.sh, docs/plans/2026-10-22-B3-memory.md, CLAUDE.md
- **Verified:** Red first (ReferenceError: selectConcepts is not defined), then node --test tests/unit/: 44 tests, 44 pass. Mutations of cost, shaky, newest-row-wins, first_report-once, glue text, drift detection, jsCode-only rewrite each turned a check red. Step 4 demo on a scratch copy: sync -> 'synced: workflows/30-memory.json: Memory rules', --check exit 0; after hand-editing the return line --check printed 'drift: workflows/30-memory.json: Memory rules', exit 1. The synced jsCode run as an async function body with $input stubbed returned [{file concepts.jsonl …},{written:[concepts.jsonl]}]. bash -n on both .sh, node --check on all 5 js/mjs: ok. .harness/check.sh: 21 passed, 0 failed (~40 s). No live writes.
- **Tests:** 19 → 21
- **Dead end:** node --test tests/unit/ as written — node 24 resolves a directory argument as a module (MODULE_NOT_FOUND); tests/unit/index.js now imports every *.test.mjs so the literal command works
- **Discovery** (affects B3-03): scripts/code-nodes.json is {} because workflows/30-memory.json doesn't exist yet: B3-03 must add {"workflows/30-memory.json": {"Memory rules": ["lib/memory.js", "lib/memory-node.js"]}} and give the node a unique placeholder jsCode (e.g. "// sync: Memory rules"), then run node scripts/sync-code-nodes.mjs. Until then the repo-side code-sync checks pass vacuously ('in sync: 0 node(s)'); the scratch-tree checks exercise the script for real.
- **Discovery** (affects B3-03, B4, B5): applyMemory takes args by name: applyReport {reportMeta, introduced, asked}, gradeAnswers {grades}. saveMemory throws on a row without a string id (an LLM concept that reaches applyReport without key fails loudly instead of growing the file).
- **Discovery** (affects B4): keyGlossary follows the plan's 'never guess': once a run's paths.worktree is null (ended runs, e.g. fixture ae65cbf6) a glossary ID keys as unknown/<id>, so a concept explained while the run was live is explained in full again at the debrief, and same-named IDs from different projects share an unknown/ row. B4 should decide whether to key from run.project when the source path can't place it.
- **Discovery** (affects B3-04, B4): matchQuestions changed beyond the plan (review): each open row follows up one parked item, same wording first; a question reworded while open and then answered is matched as answered by run+feature+text, not only by its first-asked id. Plan row updated.
- **Proposed change:** B3-02 step 1: on node 24 `node --test tests/unit/` only works because of the tests/unit/index.js shim; `node --test tests/unit/*.test.mjs` would be the shim-free form if Michael prefers it.
- *09-B3-02 · claude-opus-5-5*

### 2026-10-27 12:08 · B3-01 · passes

Wrote docs/plans/2026-10-22-B3-memory.md: three JSONL schemas, lib/memory.js rules and helpers, the 30-memory sub-workflow (load/save/apply), the D6 sync with --check, the docs/memory.md outline, 36 unit and 12 rig/static tests by name. D17 default (file rules, no lock, apply op); D6 amended (list of lib files). Opus review: 6 Important, all folded in.

- **Files:** docs/plans/2026-10-22-B3-memory.md, docs/decisions.md, CLAUDE.md
- **Verified:** .harness/check.sh: 19 passed, 0 failed (before and after). n8n facts read from docker.n8n.io/n8nio/n8n:2.42.5 source with docker run --rm --network none: ReadWriteFile read.operation.js, write.operation.js, n8n-core writeContentToFile, workflow-execute-additional-data.js getPublishedWorkflowData, workflow-helpers.js getLastExecutedNodeData, ExecuteWorkflow.node.js. No live commands.
- **Tests:** 19 → 19
- **Dead end:** one main() per lib file as D6 first said — B4's nodes need memory.js's selectConcepts beside their own main; D6 amended to an ordered list with exactly one main
- **Dead end:** save rows computed from an earlier load (re-load before save) — a grade or card answer landing between B4's load and save is overwritten; replaced by op apply, read-modify-write in one call
- **Discovery** (affects B3-03, B4, B5): Read/Write Files v1.1 read throws 'No file(s) found' on an empty glob; write has an append option (B3-01 step 3 says it has none) and never creates directories.
- **Discovery** (affects B3-03, B6-05): Execute Workflow runs the sub-workflow's published version ('Workflow is not active' otherwise): workflows/30-memory.json must be "active": true; the rig publishes all so only a static check catches it.
- **Discovery** (affects B3-03, B4, B5): The caller gets all outputs of the sub-workflow's last executed node and passes on output 0: load ends on Switch output 0; a save with nothing to write must still return a status item.
- **Discovery** (affects B3-02): Workflow JSON is hand-formatted, not JSON.stringify(...,2): the sync script must replace only the jsCode string. lib/*.js may not contain the text $env or process.env, even in comments (workflows check).
- **Discovery** (affects B4, B5): Memory writes from B4/B5 go through op apply ({fn: applyReport|gradeAnswers|markAnswered, args}), never save of rows from an earlier load (D17).
- **Question for Michael:** D17: memory files keep one row per id with the later line winning, unreadable lines kept at the end, and no lock (writes go through one read-modify-write call). OK?
- **Proposed change:** B3-01 step 3: drop '(no append mode in the node)': 2.42.5's Write has append; memory doesn't use it.
- **Proposed change:** B3-02 step 3: the map value may be a lib file or an ordered list of lib files (D6 as amended); the plan maps 'Memory rules' to [lib/memory.js, lib/memory-node.js].
- **Proposed change:** B3-03 step 2: the trigger takes op load|save|apply, and add the rig checks 'memory save unchanged' and 'memory apply' the plan names.
- *08-B3-01 · claude-opus-5-5*

### 2026-10-27 11:46 · verify B2 · passes

All six B2 features hold: full suite 19 passed 0 failed (39s), also from a fresh clone; FAIL_ME/KEEP/--only/loopback/cleanup verified. Caveat: B2-02 step 4 literal grep hits tests/checks/compose.sh (B1 config renders; D16 default, unanswered); rig code clean.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| B2-01 | 1 | read docs/plans/2026-10-22-B2-test-rig.md vs rig behaviour (tests/run.sh, lib.sh, KEEP output) | plan sections present; rig matches: n8n-test-<rand>, /tmp/n8n-test-*, image 2.42.5, loopback ports 24702/24703 | yes |
| B2-01 | 2 | grep plan for placeholders, fake API, PASS/FAIL format, --only/KEEP, lib helpers | present; FAIL_ME/KEEP/--only behave as described | yes |
| B2-01 | 3 | grep plan for check names + credential-by-name | names listed; 'credential re-linked by name' PASSes in suite | yes |
| B2-01 | 4 | suite groups compose/deploy/snapshot (B1 stand-ins) in check.sh | `.harness/check.sh` full run: 19 passed, 0 failed, 39 s; no n8n-test container or /tmp/n8n-test-* left; snapshot 32/32, compose and deploy groups PASS | yes |
| B2-02 | 1 | .harness/check.sh | PASS healthz, smoke webhook 200, env visible to workflows, file read inside allow-list, file read outside allow-list refused; 19 passed, 0 failed, exit 0, 39 s | yes |
| B2-02 | 2 | KEEP=1 run; docker ps; ss -ltnp; docker ps -a after cleanup | n8n-test-04VwXwvK image docker.n8n.io/n8nio/n8n:2.42.5; listeners 127.0.0.1:24702/24703 only; after normal run docker ps -a empty, no /tmp/n8n-test-* | yes |
| B2-02 | 3 | FAIL_ME=1 .harness/check.sh; KEEP=1 | one 'FAIL fail_me', 19 passed 1 failed, exit 1, container+scratch removed; KEEP printed port, dir and removal command and left them | yes |
| B2-02 | 4 | grep -rn 'docker compose' tests/ .harness/; grep n8n-n8n-1 | literal grep NOT empty: tests/checks/compose.sh (B1 render checks, config only, D16 default; the run dir text also matches). Rig code (run.sh, lib.sh, smoke.sh, check.sh) has none; no n8n-n8n-1. Accepted per D16 reading; Michael hasn't answered. rig-smoke id/webhook/sticky from suite passing | yes |
| B2-02 | 5 | suite tail | `.harness/check.sh` full run: 19 passed, 0 failed, 39 s; no n8n-test container or /tmp/n8n-test-* left | yes |
| B2-03 | 1 | .harness/check.sh --only fakes | 23 passed, 0 failed, 'fakes under 10 s' PASS, no container | yes |
| B2-03 | 2 | fakes group PASS lines (401, 400 for temperature/top_p/top_k/tool_choice/thinking, 200 shape, canned by schema) | all PASS in tests/checks/fakes.sh output | yes |
| B2-03 | 3 | fakes group: ntfy POST/PUT, /_calls, /_reset, 404 | PASS path recorded without query string, _calls shape, _reset empties calls, unknown route 404 | yes |
| B2-03 | 4 | fakes group: rig_smoke selection, usage numeric, recorded body | PASS lines present (23/23) | yes |
| B2-03 | 5 | suite tail | `.harness/check.sh` full run: 19 passed, 0 failed, 39 s; no n8n-test container or /tmp/n8n-test-* left; fakes wired as pre-container group | yes |
| B2-04 | 1 | fixtures group: 'ledger rows for the three runs', 'ledger and worktree files present' | PASS | yes |
| B2-04 | 2 | fixtures group: events have the 13 v1 keys, kinds, ISO at, debrief nulls, events name the fixture runs | PASS (13 keys incl. v, matches Run A spec; step text says 12 but lists 13 names) | yes |
| B2-04 | 3 | fixtures group: bundle shape, glossary D24 N1-01 M8 D-H1, Q99 unresolved, ## Glossary | PASS | yes |
| B2-04 | 4 | fixtures group: README names every fixture; live checklist replaces shaped bundles | PASS | yes |
| B2-04 | 5 | grep -rEn secrets pattern fixtures/; fixtures group | grep empty; 'no secrets in fixtures' PASS; 21 passed, 0 failed | yes |
| B2-04 | 6 | suite tail | `.harness/check.sh` full run: 19 passed, 0 failed, 39 s; no n8n-test container or /tmp/n8n-test-* left | yes |
| B2-05 | 1 | suite 'fixtures staged' PASS; smoke staging | PASS fixtures staged; bundle readable and requests dir writable PASS at host-equal paths | yes |
| B2-05 | 2 | suite smoke checks; env visible to workflows | PASS; fake started first, KEEP output showed fake pid/port and container; both removed by trap | yes |
| B2-05 | 3 | PASS credential re-linked by name | PASS (fake saw x-api-key=dummy-anthropic via wrong-id credential) | yes |
| B2-05 | 4 | new PASS lines | smoke LLM call via credential, smoke ntfy post recorded, bundle readable at event.context path, requests dir writable, fixtures shape (fixtures group), fakes all PASS | yes |
| B2-05 | 5 | git clone -b harness/... /tmp/n8n-home-clone && .harness/check.sh; --only fakes | clone 19 passed, 0 failed, 38 s; --only fakes ran only fakes | yes |
| B2-05 | 6 | suite tail | `.harness/check.sh` full run: 19 passed, 0 failed, 39 s; no n8n-test container or /tmp/n8n-test-* left | yes |
| B2-06 | 1 | read docs/plans/2026-10-22-B2-review.md | findings table with RED cd6d10e / GREEN 1ef8bad; 'Open Critical/Important: none' | yes |
| B2-06 | 2 | grep sleep in tests/run.sh lib.sh; image tag source | only sleep is inside wait_for with wall-clock deadline (runner group tests it); tag read via rig_image from deploy/compose.yml | yes |
| B2-06 | 3 | grep CLAUDE.md 'created by B2'; 'As built' in fixtures/README.md and plan | no 'created by B2'; flags --only/KEEP/FAIL_ME and timing match; As built sections exist in both | yes |
| B2-06 | 4 | suite tail | `.harness/check.sh` full run: 19 passed, 0 failed, 39 s; no n8n-test container or /tmp/n8n-test-* left | yes |

- *114255-verify-B2 · claude-sonnet-5-5*

### 2026-10-27 11:42 · B2-06 · passes

Reviewed B2 (2 Opus passes, 16 findings, 1 Important). D15 check now allows only $env.<reporter key>; wait_for keeps a wall-clock deadline; groups/import run in background so TERM tears down at once; shared fake_start/fake_stop/http; tag read only via rig_image; new runner group. CLAUDE.md How to verify and As built docs updated. Suite 18 -> 19, 0 failed, ~38 s.

- **Files:** tests/run.sh, tests/lib.sh, tests/checks/runner.sh, tests/checks/workflows.sh, tests/checks/compose.sh, tests/checks/deploy.sh, tests/checks/fakes.sh, tests/checks/fixtures.sh, tests/checks/smoke.sh, tests/checks/snapshot.sh, CLAUDE.md, docs/plans/2026-10-22-B2-review.md, +2 more
- **Verified:** Each fix with a check went RED then GREEN in separate commits: cd6d10e/1ef8bad (D15), 31714e1/f717cfb (wait_for, TERM), 3f4cc86/44bee0d (image tag). .harness/check.sh: 19 passed, 0 failed (38 s); fresh clone of the pushed branch: 19 passed, 0 failed (39 s). By hand: TERM during the import gives exit 130 after 1 s, with no n8n-test-* container, /tmp/n8n-test-* or fake left; FAIL_ME=1 exits 1 and tears down; KEEP=1 leaves the rig and prints it (then removed); an id-less workflow gives FAIL healthz with the reason. No live commands.
- **Tests:** 18 → 19
- **Dead end:** importing fixtures.mjs with its path as argv[1] to read PLACEHOLDERS — its run-directly guard compares argv[1], so main ran; pass the path in env instead
- **Discovery** (affects run): The suite has a no-container 'runner' group that runs a copy of tests/run.sh against stub groups; new run.sh behaviour can be tested there without docker.
- **Discovery** (affects B3, B4, B5, B6): Workflows may read only $env.<KEY> for a non-N8N_ key the rig sets (tests/lib.sh rig_env); a new env var a workflow reads must be added to rig_env (and deploy/compose.yml) or the workflows check fails.
- **Discovery** (affects run): Groups run under setsid: a supervisor that KILLs run.sh's process group without a TERM first no longer kills a running group. TERM, INT and HUP tear everything down.
- **Proposed change:** The B2 plan and fixtures/README.md now list every check name by hand, and that list goes stale as soon as B3 adds checks. Better to drop the step's 'list every check name' for later milestones and point at `tests/run.sh --list` plus the suite output.
- *07-B2-06 · claude-opus-5-5*

### 2026-10-27 11:19 · B2-05 · passes

Rig now stages fixtures into scratch (placeholders replaced), starts the fake server first (FAKE_PORT=0) and kills it in teardown, imports fixtures/credentials.json before workflows. rig-smoke gained llm/ntfy/bundle/write ops; 6 new top-level checks (fixtures staged + 5 smoke). Suite 12 -> 18, 0 failed, 33 s; fresh clone same.

- **Files:** tests/run.sh, tests/lib.sh, tests/checks/smoke.sh, tests/workflows/rig-smoke.json, tests/fakes/server.mjs, fixtures/credentials.json, fixtures/README.md, docs/plans/2026-10-22-B2-test-rig.md
- **Verified:** Red first: tests/run.sh --only smoke -> 5 new FAILs ('unknown op'). Then .harness/check.sh: 18 passed, 0 failed in 33 s. Mutation: credential name changed to one with no match -> 'smoke LLM call via credential' and 'credential re-linked by name' FAIL (restored). FAIL_ME=1: exit 1, no n8n-test-* container, /tmp/n8n-test-* dir or fake process left. tests/run.sh --only fakes: 1 passed. Fresh git clone of origin at 1c6f872 into the scratch dir (not /tmp/n8n-home-clone, to stay in scratch): 18 passed, 0 failed, 33 s. New nodes checked with n8n-docs validate_node (all valid). Opus review: 9 findings, 8 fixed (fake death reported with its log, fake killed and waited for, stage_fixtures OK with no placeholder, FAIL message, bundle check compares id, fake env isolated, reset checked), 1 not fixed (placeholder scan covers all of scratch, as the step says). Nothing live.
- **Tests:** 12 → 18
- **Discovery** (affects B6-05, run): 2.42.5 re-links credentials by name on import:workflow: an id not in the DB falls back to findByNameAndTypeInProject (replaceInvalidCredentials). D2's create-by-name plan holds; deploy.sh needs no id rewrite.
- **Discovery** (affects B3, B4, B5, B6): lib.sh now has event_json, post_event (POST /webhook/harness-event), fake_calls [llm|ntfy], fake_reset, stage_fixtures, placeholder_sed. The fake no longer sits at P+2: its port is in FAKE_URL.
- **Discovery** (affects B2-06): The rig only needs P and P+1 free now; rig-smoke's credential ids are deliberately wrong (WrongIdAnthropic, WrongIdNtfy00001).
- **Proposed change:** B2-05 step 5 names /tmp/n8n-home-clone, outside the session's scratch dir; point it at the scratch dir.
- *06-B2-05 · claude-opus-5-5*

### 2026-10-27 11:08 · B2-04 · passes

Added fixtures/: real ledger rows and run records (byte-identical copies), the dj-2026-10-17 run files and its decision-table specs (gh api at 328eca5f2f), six v1 events and five context bundles shaped from Run A's spec, README. tests/checks/fixtures.sh (+ fixtures.mjs validators): 20 checks, no docker. Suite 11 -> 12 top-level, 0 failed.

- **Files:** fixtures/, tests/checks/fixtures.sh, tests/checks/fixtures.mjs, docs/plans/2026-10-22-B2-test-rig.md, docs/plans/2026-10-22-live-checklist.md
- **Verified:** .harness/check.sh: 12 passed, 0 failed in ~27 s, no n8n-test-* container or /tmp/n8n-test-* left. bash tests/checks/fixtures.sh: 20 PASS. cmp: runs.jsonl rows and all 16 copied run files identical to ~/projects/agent-harness/ledger and ~/projects/dj-crate-streaming/.harness/runs/dj-2026-10-17. Mutation runs in scratch (extra key, bad at, null event, wrong glossary line, no Q99, heading after Glossary, stray file, planted tk_ token, missing fixtures/, symlinked checkout) each FAIL the right check. Opus review: 6 findings, all fixed. No live writes; only reads outside the worktree.
- **Tests:** 11 → 12
- **Dead end:** copying docs/specs/2026-10-13-next-session-design.md from dj main — since 2026-10-25 it only points at docs/decisions.md; the table version came from gh api at 328eca5f2f (the run's start)
- **Discovery** (affects B2-05, B3, B4, B5): fixtures/events ids: park 008c52a0-7cc4-4971-b5e0-a2bb28292608 (run dj-2026-10-17, feature H3-04); bundles live at fixtures/bundles/<event id>/; ended has context null. tests/checks/fixtures.mjs exports eventProblems/bundleProblems/EVENT_KEYS/PLACEHOLDERS for later checks.
- **Discovery** (affects B2-05, B3): D24 and D-H1 appear in no real dj-2026-10-17 text: the park and debrief bundles carry one planted open question naming D24, D-H1, M8, N1-01 and Q99 (README says so). D-H1 resolves to fixtures/harness/worktrees/agent-harness/agent-harness-2026-10-21-measure/journal/decisions.md.
- **Discovery** (affects B2-04, run): The event contract has 13 keys (v..context), not 12; the check is named 'events have the 13 v1 keys'.
- **Proposed change:** B2-04 step 2 says 'exactly the 12 keys' but lists 13 (Run A's contract has 13): should say 13.
- **Proposed change:** B2-05 step 4 lists a top-level line 'fixtures shape'; the group's top-level line is 'fixtures' (group names have no spaces). The plan now says 'fixtures'.
- *05-B2-04 · claude-opus-5-5*

### 2026-10-27 10:54 · B2-03 · passes

Built tests/fakes/server.mjs (fake Anthropic /v1/messages with the 2026-10-21 400s and canned answers by schema title, ntfy POST/PUT, /_calls, /_reset, 404s), responses/rig_smoke.json and default.txt, and tests/checks/fakes.sh: 23 checks, curl+jq, about 1 s, no docker. Wired in as the no-container group 'fakes'. Suite 10 -> 11 top-level, 0 failed.

- **Files:** tests/fakes/server.mjs, tests/fakes/responses/rig_smoke.json, tests/fakes/responses/default.txt, tests/checks/fakes.sh
- **Verified:** Red first: bash tests/checks/fakes.sh gave 18 FAIL with no server. Green: 23 PASS in 0.9 s, no node left behind. FAKE_PORT=7808 node tests/fakes/server.mjs prints 'listening 7808' and ss shows 127.0.0.1:7808 only. .harness/check.sh: 11 passed, 0 failed in 27 s, no n8n-test-* container or /tmp/n8n-test-* left. An Opus review found 7 issues, all fixed: the server crashed on a missing default.txt or on a request target like 'http://[::1' (proven against a copy of the old code: 000, node exited), path kept the query string, a body over 10 MB was answered but not recorded, an empty schema title didn't fall back to format.name, and 2 checks were too weak. Hand probes: a missing default.txt gives 500 naming the file; an 11 MB body gives one 413 and is recorded. Nothing live.
- **Tests:** 10 → 11
- **Dead end:** new URL(req.url, base) for the path — it throws on absolute-form targets like 'http://[::1', which killed the server; it now splits on '?'
- **Discovery** (affects B4, B6): The fake records path without the query string and refuses any tool_choice (feature step), not only forced ones. It requires model, max_tokens and messages, as the real API does. Thinking enabled/adaptive gets 200.
- **Discovery** (affects run): /home/mh550/projects/agent-harness/lib/check.sh prints 'no suite configured or detected (CHECK_CMD)' in this worktree and runs nothing. .harness/check.sh (tests/run.sh) is the real suite and is green.
- **Discovery** (affects B2-05): lib.sh has no fake_calls/fake_reset helpers yet (plan's helper table). B2-05 adds them when it starts the fake in run.sh with FAKE_PORT=0.
- **Proposed change:** The harness suite command (lib/check.sh) should detect or be configured with .harness/check.sh for n8n-home. It currently runs nothing, so 'suite green' is vacuous unless a session runs .harness/check.sh itself.
- *04-B2-03 · claude-opus-5-5*

### 2026-10-27 10:46 · B2-02 · passes

Built the rig: tests/run.sh + lib.sh, .harness/check.sh, rig-smoke workflow, smoke (rig) and workflows (D15 guard) groups; B1 groups use lib's check. N8N_BLOCK_ENV_ACCESS_IN_NODE=false now in compose.yml (D15). Suite: 10 top-level checks green in 31 s, no container or /tmp/n8n-test-* left. D16 default: step 4's grep read as the rig's code.

- **Files:** tests/run.sh, tests/lib.sh, .harness/check.sh, tests/checks/smoke.sh, tests/checks/workflows.sh, tests/workflows/rig-smoke.json, tests/checks/compose.sh, tests/checks/deploy.sh, tests/checks/snapshot.sh, deploy/compose.yml, docs/decisions.md
- **Verified:** HARNESS_CHECK_CMD=.harness/check.sh lib/check.sh on clean 94c3cbf: 'green in 31 s, 10 tests' (compose 26, deploy 38, snapshot 32, workflows 4 inner; healthz, smoke webhook 200, env visible to workflows, file read inside allow-list, file read outside allow-list refused, loopback only). Red first: with N8N_BLOCK_ENV_ACCESS_IN_NODE=true the env check failed ('access to env vars denied'); compose check red until compose.yml had it; drift and D15 guards shown to fail on a planted key. FAIL_ME=1: one FAIL, exit 1, 0 containers, 0 dirs. KEEP=1: kept line, container on docker.n8n.io/n8nio/n8n:2.42.5, host net, listeners 127.0.0.1:P and P+1 only, removed by hand. timeout -s INT at 3 s and 10 s, and double INT at 17/19/21 s: nothing left. A planted rig group dying after one PASS gives 'FAIL dies: exit 1 after 1 checks'. Opus review: 2 Important + 5 Minor, all fixed in 94c3cbf. No live command run.
- **Tests:** 94 → 10
- **Dead end:** an echo'd token file for the read check — webhook() flattens newlines to spaces, so the body had a trailing space; token now written with printf %s and webhook() trims trailing spaces
- **Discovery** (affects run): The harness now counts top-level lines (10), not B1's inner 94: each no-container group is one line, its own checks indented.
- **Discovery** (affects B2-03, B2-05): run.sh reserves P+2 for the fake server and points LLM_BASE_URL/NTFY_URL/FAKE_URL at it, but starts nothing; B2-05 starts tests/fakes/server.mjs there (or switches to FAKE_PORT=0 and reads its port) and adds it to teardown().
- **Discovery** (affects B2-05, B4, B5, B6): rig_env in tests/lib.sh is the rig's single env list; compose.sh fails if compose.yml sets a key it lacks (live-only: N8N_EDITOR_BASE_URL, N8N_PROXY_HOPS, EXECUTIONS_DATA_*). Rig boot (import+publish+start+webhook) takes about 18 s.
- **Discovery** (affects B2-06): A TERM sent while a foreground child runs (import container, a 30 s webhook curl) is handled only after it exits; a supervisor that escalates to KILL inside that window leaves n8n-test-* behind.
- **Question for Michael:** D16: B2-02 step 4's `grep -rn 'docker compose' tests/ .harness/` can never be empty (the run dir's brief, INBOX and feature list say it), and B1's compose.sh renders a temp copy with `docker compose config`. I read the step as 'the rig's code never runs docker compose' and kept B1's render checks. OK, or should the render move out of the suite?
- **Proposed change:** B2-02 step 4: grep tests/run.sh tests/lib.sh tests/checks/smoke.sh .harness/check.sh (the rig code) instead of tests/ .harness/, and 'tests/ never names n8n-n8n-1' instead of 'the tree' (README, CLAUDE.md and deploy.sh's refusal name it).
- *03-B2-02 · claude-opus-5-5*

### 2026-10-27 10:28 · B2-01 · passes

Wrote docs/plans/2026-10-22-B2-test-rig.md: layout, lifecycle (mktemp /tmp/n8n-test-*, cli import+publish then start, host net, ports P and P+1), rig env, mounts, placeholders, fake API, check format, --only/KEEP/FAIL_ME, lib.sh helpers, every B2-02..05 check by name. D15 default: N8N_BLOCK_ENV_ACCESS_IN_NODE=false, since $env is denied by default in 2.42.5.

- **Files:** docs/plans/2026-10-22-B2-test-rig.md, docs/decisions.md, docs/plans/2026-10-22-B1-compose.md
- **Verified:** Plan only, nothing live. B1 stand-ins: bash -n on every *.sh clean; tests/checks/compose.sh 24 PASS, deploy.sh 38 PASS, snapshot.sh 32 PASS, 0 FAIL; docker compose -f deploy/compose.yml config -q exit 0. Facts read from the pinned image with docker run --rm --network none --entrypoint sh docker.n8n.io/n8nio/n8n:2.42.5 -c 'grep ...' (no n8n-test-* left after).
- **Tests:** 94 → 94
- **Dead end:** gh api on agent-harness ref spec/2026-10-22-n8n-events (spec section 0.3) — the branch is gone (404); the spec is on agent-harness main now
- **Discovery** (affects B2-02, B4, B5, B6-05): In 2.42.5 $env in expressions is denied unless N8N_BLOCK_ENV_ACCESS_IN_NODE=false (workflow-data-proxy-env-provider.js). D15 default: set it in the rig and compose.yml (B2-02); it reaches live with the B6 deploy.
- **Discovery** (affects B2-04, run): Run A's spec is now on agent-harness main: gh api 'repos/mh550/agent-harness/contents/docs/specs/2026-10-22-n8n-events.md?ref=main'. The spec/2026-10-22-n8n-events branch no longer exists.
- **Discovery** (affects B2-02, B2-05): The task-runner broker listens on 127.0.0.1:5679 by default; on --network host the rig sets N8N_RUNNERS_BROKER_PORT=N8N_PORT+1. import:credentials encrypts plain-object data, so fixtures/credentials.json can hold plaintext dummies.
- **Question for Michael:** D15: OK to run live n8n with N8N_BLOCK_ENV_ACCESS_IN_NODE=false? It lets any expression read N8N_ENCRYPTION_KEY; only repo workflows run, and the suite will fail on $env.N8N_* or process.env. The alternative is a config file you write under /srv/n8n/files/.
- **Proposed change:** Spec section 0.3 should point at agent-harness main for docs/specs/2026-10-22-n8n-events.md; the spec branch it names is gone.
- *02-B2-01 · claude-opus-5-5*

### 2026-10-27 10:21 · verify B1 · passes

All five B1 features hold: deploy 38, snapshot 32, compose 24 checks pass; bash -n clean; compose config ok; live Check green, DEPLOYED dcdc51d, mounts/env match. docker exec into live was denied, so mounts verified via docker inspect and host ls.

| Feature | Step | What you ran or read | What you saw | Holds |
|---|---|---|---|---|
| B1-01 | 1 | grep headings docs/plans/2026-10-22-B1-compose.md | Mounts, Environment, Deploy flow, Snapshot timer, Checklist, Facts carried over from §0.2 sections present | yes |
| B1-01 | 2 | docker compose -f deploy/compose.yml config -q | exit 0, no deploy/.env | yes |
| B1-01 | 3 | docker compose -f deploy/compose.yml config \| grep | image 2.42.5, port 5678, mounts ledger ro, harness ro, requests rw, worktrees ro, files rw, data; plus workflows ro (D13, seven mounts); no docker.sock, no NODES_EXCLUDE; tests/checks/compose.sh 24 PASS | yes |
| B1-01 | 4 | docker compose -f deploy/compose.yml config \| grep RESTRICT\|LLM_ | RESTRICT = the five paths joined by ';'; all 9 env keys with D2 defaults (api.anthropic.com, claude-sonnet-5-5) | yes |
| B1-01 | 5 | diff of ${KEY} in compose.yml vs .env.example; grep -c '=.\+' | keys match (only regex artifact N8N_...); value count 0 | yes |
| B1-01 | 6 | grep '^###' docs/plans/2026-10-22-live-checklist.md | steps 0-12 in order each with Done when; done items marked | yes |
| B1-01 | 7 | bash -n on all git-tracked *.sh; compose config -q | no errors, exit 0 | yes |
| B1-02 | 1 | bash tests/checks/deploy.sh; head scripts/deploy.sh | PASS parses, set -uo pipefail, N8N_DIR/DOCKER overrides, data/ only mentioned to leave alone | yes |
| B1-02 | 2 | bash tests/checks/deploy.sh | dirty/unpushed/non-main/.env/dry-run PASS lines all present; 38 passed, 0 failed | yes |
| B1-02 | 3 | bash tests/checks/deploy.sh | 'real run copies compose.yml and workflows, creates files/ subdirs' and 'up -d, import, publish, restart in order' PASS | yes |
| B1-02 | 4 | bash tests/checks/deploy.sh | 'real run ends deployed <sha> (<subject>)' PASS; dry-run test covers nothing changed | yes |
| B1-02 | 5 | bash tests/checks/deploy.sh | DEPLOYED written, --check pass/fail naming workflow, never reads .env (mode 000) all PASS | yes |
| B1-02 | 6 | read checklist step 5 | dry-run then deploy, healthz Done when, undo via git checkout <sha>; deploy has since been done; 'compose ps' wording replaced by --check/mount list (equivalent) | yes |
| B1-02 | 7 | bash -n; deploy.sh checks; compose config -q | all pass | yes |
| B1-03 | 1 | bash tests/checks/snapshot.sh | snapshot path/size, integrity_check ok; 32 passed, 0 failed | yes |
| B1-03 | 2 | bash tests/checks/snapshot.sh | 9 old -> exactly 7 newest, removed count printed, missing db exit 1 PASS | yes |
| B1-03 | 3 | cat deploy/systemd/*; systemd-analyze --user verify; snapshot.sh | service oneshot, timer 03:00 persistent; test 'systemd-analyze verify' PASS. Literal verify in this worktree exits 1 only because %h/projects/n8n-home/scripts path is main-checkout and not yet merged here (path is not executable at ~/projects/n8n-home) | yes |
| B1-03 | 4 | snapshot.sh 'checklist step 9' check; read step 9 | link, enable, list-timers, one-off start, linger, undo PASS | yes |
| B1-03 | 5 | bash -n; deploy.sh; snapshot.sh; compose config -q | all pass | yes |
| B1-04 | 1 | read docs/plans/2026-10-22-B1-review.md | findings table with severity, file:line, fix; 3 Important all with RED/GREEN commits, none open | yes |
| B1-04 | 2 | read review rows 1-5 | each Important has RED commit then GREEN commit named | yes |
| B1-04 | 3 | grep headings README.md | Layout, How to verify, How deploys happen present | yes |
| B1-04 | 4 | read live-checklist and B1-compose plan vs compose/.env.example | paths/keys match rendered compose; seven mounts; checklist consistent | yes |
| B1-04 | 5 | bash -n; deploy.sh; snapshot.sh; compose config -q | all pass | yes |
| B1-05 | 1 | curl healthz; docker inspect; cat /srv/n8n/DEPLOYED; systemctl show restic; ls snapshots; sqlite3 snap integrity_check | ok; 2.42.5 running; DEPLOYED dcdc51d; restic status 0 at 03:32 today; pre- compose and db snap exist, integrity ok. Past preconditions (progress record) not re-observable | yes |
| B1-05 | 2 | read DEPLOYED, checklist step 5, git log | DEPLOYED=dcdc51dba89d.. 'HARNESS: context pack for B1-05' matches the deploy message; dry-run output not re-runnable (live write gate) | yes |
| B1-05 | 3 | curl healthz; docker inspect Env/Mounts; curl / ; ls /srv/n8n/files | healthz ok, image+running, RESTRICT env equals compose value, mounts ledger/files present, 200, DEPLOYED dcdc51d is an ancestor commit of the run branch. docker exec was denied by the classifier so mounts checked via inspect | yes |
| B1-05 | 4 | n/a (no failure occurred) | deploy succeeded; rollback files exist; passes true is consistent | yes |
| B1-05 | 5 | read checklist steps 5, 4, 0, 1, 7 | B1 deploy marked done by run with sha dcdc51d; remaining todo steps are Michael's/Run A/B6 | yes |

- *101950-verify-B1 · claude-sonnet-5-5*

### 2026-10-27 10:19 · B1-05 · passes

B1 deployed live at 10:17: dry run, then `flock -n /srv/n8n/live.lock scripts/deploy.sh` -> `deployed dcdc51d (HARNESS: context pack for B1-05)`. n8n 2.42.5 running with the seven mounts, N8N_RESTRICT_FILE_ACCESS_TO as in compose.yml, /srv/n8n/files/{cards,events,memory,reports}; DEPLOYED=dcdc51d. Checklist steps 4 and 5 marked done.

- **Files:** docs/plans/2026-10-22-live-checklist.md, docs/plans/2026-10-22-B1-compose.md
- **Verified:** Preconditions (10:16:57 EDT, HEAD dcdc51d pushed to origin/harness/n8n-home-2026-10-22; only harness-log.md dirty, the harness's file): bash tests/checks/{compose,deploy,snapshot}.sh 24/38/32 passed, 0 failed (lib/check.sh: no suite configured). Check: `curl -sf http://127.0.0.1:5678/healthz && docker inspect -f '{{.Config.Image}} {{.State.Status}}' n8n-n8n-1` -> {"status":"ok"} docker.n8n.io/n8nio/n8n:2.42.5 running. `systemctl show restic-backup.service -p ExecMainExitTimestamp -p ExecMainStatus` -> Tue 2026-10-27 03:32:47 EDT, 0 (under 7 h). `systemctl is-active restic-backup.service` -> inactive. Rollback record: image docker.n8n.io/n8nio/n8n:2.42.5; `sha256sum /srv/n8n/compose.yml` 7a1785d9784b2585d40f3e4a4fde12307d979dd6c29e61e1b70c5978c3522882; DEPLOYED none. Snapshots: `flock -n /srv/n8n/live.lock sh -c "sqlite3 /srv/n8n/data/database.sqlite '.backup /srv/n8n/data/database.sqlite.pre-n8n-home-2026-10-22-B1.snap' && sqlite3 /srv/n8n/data/database.sqlite.pre-n8n-home-2026-10-22-B1.snap 'pragma integrity_check' && cp /srv/n8n/compose.yml /srv/n8n/compose.yml.pre-n8n-home-2026-10-22-B1"` -> ok, exit 0 (no /srv/n8n/files, so no tgz). `flock -n /srv/n8n/live.lock scripts/deploy.sh --dry-run` -> commit dcdc51d, compose diff (env_file required:false, N8N_RESTRICT_FILE_ACCESS_TO, reporter env, six binds), mkdir workflows+files/{reports,memory,events,cards}, cp+mv compose.yml, up -d, health wait, restart, --check, write DEPLOYED; `dry run: nothing changed`, exit 0. `flock -n /srv/n8n/live.lock scripts/deploy.sh` 10:17:28-10:17:45 -> `deployed dcdc51dba89dc2c47de4def36169b36628255253 (HARNESS: context pack for B1-05)`, exit 0. After: Check -> {"status":"ok"} 2.42.5 running; `docker exec n8n-n8n-1 ls /srv/n8n/files /home/mh550/projects/agent-harness/ledger` lists cards events memory reports and the ledger (runs.jsonl, project dirs); `docker exec n8n-n8n-1 printenv N8N_RESTRICT_FILE_ACCESS_TO` equals compose.yml's value; `curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:5678/` 200; /srv/n8n/DEPLOYED = HEAD dcdc51d; `scripts/deploy.sh --check` exit 0 (0 workflows); mounts: rw=true only /srv/n8n/files, /srv/n8n/data, requests; compose.yml sha256 now 99b2add9... = deploy/compose.yml. Final Check after the doc edits green again.
- **Tests:** 94 → 94
- **Discovery** (affects B6-05, run): Live n8n now runs the B1 compose file (DEPLOYED dcdc51d, a run-branch commit). Rollback files: /srv/n8n/compose.yml.pre-n8n-home-2026-10-22-B1 and /srv/n8n/data/database.sqlite.pre-n8n-home-2026-10-22-B1.snap. B6-05 deploys the workflows on top.
- **Discovery** (affects B6-05): tests/checks/compose.sh requires a 'Done when:' line in every live-checklist step, [done] steps included.
- **Proposed change:** B1-05 step 1 says 'checks green': until B2 creates .harness/check.sh, lib/check.sh runs nothing, so name `bash tests/checks/*.sh` as B1's checks.
- *01-B1-05 · claude-opus-5-5*

### 2026-10-27 01:03 · B1-05 · parked

Live deploy not run: bind source ~/.local/state/harness/requests is missing (create_host_path:false, so up -d would fail after removing the running container), and sessions may not write there. Built: deploy.sh refuses a missing bind source before any write; its dry run names it. deploy checks 35 -> 38. Checklist step 4 marked as the blocker; Q2 in INBOX.

- **Files:** scripts/deploy.sh, tests/checks/deploy.sh, docs/plans/2026-10-22-live-checklist.md, .harness/runs/n8n-home-2026-10-22/INBOX.md
- **Verified:** Read-only live commands (no live write, no snapshot taken): `curl -sf http://127.0.0.1:5678/healthz` -> {"status":"ok"}; `docker inspect -f '{{.Config.Image}} {{.State.Status}}' n8n-n8n-1` -> docker.n8n.io/n8nio/n8n:2.42.5 running; `systemctl show restic-backup.service -p ExecMainExitTimestamp -p ExecMainStatus -p ActiveState` -> Mon 2026-10-26 03:42:54 EDT, 0, inactive (21 h old); `sha256sum /srv/n8n/compose.yml` -> 7a1785d9784b2585d40f3e4a4fde12307d979dd6c29e61e1b70c5978c3522882; `cat /srv/n8n/DEPLOYED` -> none; time 01:00 EDT. `ls -ld ~/.local/state/harness/requests` -> No such file. `flock -n /srv/n8n/live.lock scripts/deploy.sh --dry-run` on pushed 27cb037 -> exit 0, 'note: missing bind source(s): /home/mh550/.local/state/harness/requests (create them first: live checklist); a real deploy now would refuse', compose diff as expected, 'dry run: nothing changed'. Stand-ins: bash -n on every *.sh ok; tests/checks/compose.sh 24/0, deploy.sh 38/0, snapshot.sh 32/0; docker compose -f deploy/compose.yml config -q exit 0.
- **Tests:** 91 → 94
- **Dead end:** deploying live as B1-05 says — ~/.local/state/harness/requests is missing; making it is a write under ~/.local/state/harness (off-limits; checklist step 4 is Michael's or Run A's)
- **Discovery** (affects B1-05, B6-05, B2): deploy.sh now refuses (dry run: notes) any missing bind source in compose.yml except N8N_DIR/files and N8N_DIR/workflows, which it creates. Test cases point bind sources at per-case host dirs.
- **Discovery** (affects run): The run brief (2026-10-22) says build-only and never park; POLICY=live-staged (2026-10-23) and B1-05 say deploy. This session followed live-staged and parked, since only Michael can unblock it.
- **Question for Michael:** Q2: run `install -d -m 700 ~/.local/state/harness/requests` (or let Run A make it) so B1-05 can deploy?
- **Question for Michael:** Does the brief's build-only line still hold, or does live-staged win (as this session assumed)?
- *05-B1-05 · claude-opus-5-5*

### 2026-10-27 00:59 · B1-04 · passes

Opus review of the B1 diff: 0 Critical, 3 Important, 5 Minor. Each Important fix was a RED then a GREEN commit: n8n-snapshot.sh under 'flock -n live.lock' reuses the inherited lock (it used to wait on itself); deploy.sh refuses 03:15-04:30 or a running restic; deploy.sh unpublishes workflows retired since DEPLOYED. Minors fixed. Added README.md and docs/plans/2026-10-22-B1-review.md.

- **Files:** README.md, docs/plans/2026-10-22-B1-review.md, scripts/deploy.sh, scripts/n8n-snapshot.sh, tests/checks/deploy.sh, tests/checks/snapshot.sh, docs/decisions.md, docs/plans/2026-10-22-B1-compose.md, docs/plans/2026-10-22-live-checklist.md
- **Verified:** bash tests/checks/compose.sh 24 PASS, deploy.sh 35 PASS (was 26), snapshot.sh 32 PASS (was 31); each new check seen FAIL before its fix. docker compose -f deploy/compose.yml config -q exit 0; bash -n on every *.sh. lib/check.sh: no suite configured (exit 0). Nothing live was run.
- **Tests:** 81 → 91
- **Dead end:** holding the lock in the test with 'flock -n live.lock sleep 30 &' and killing $! — kill hits flock, and the orphaned sleep keeps the inherited lock fd; a subshell that execs sleep is one process
- **Dead end:** holding it with an fd in the test shell (exec 8>>live.lock) — the script inherits fd 8 and, after fix #1, uses it, so the held-lock case passes falsely
- **Discovery** (affects B1-05, run): flock(1) passes its lock descriptor to the command it runs, and the command can flock that fd again at once (same open file description). n8n-snapshot.sh relies on this.
- **Discovery** (affects B1-05, B6-05, B2): deploy.sh now refuses 03:15-04:30 and while restic-backup.service is active/activating (override DEPLOY_TIME=HHMM, SYSTEMCTL for tests). It also unpublishes workflows in DEPLOYED's commit that HEAD lacks, and warns when that commit isn't fetched.
- **Question for Michael:** Can the CLAUDE.md wording below (proposed_changes) go in? The backup check 'systemctl is-active restic-backup.service' never fires during a backup, and the Deploy paragraph no longer matches deploy.sh.
- **Proposed change:** CLAUDE.md Backups → Window: replace 'while systemctl is-active restic-backup.service prints active' with 'while systemctl show -p ActiveState --value restic-backup.service prints active or activating (a oneshot is activating while it runs); scripts/deploy.sh refuses both itself'. B1-05 step 1 and B6-05 should use the same wording.
- **Proposed change:** CLAUDE.md Deploy and rollback: deploy.sh refuses uncommitted or untracked files only under deploy/, workflows/ and scripts/ (D12), runs compose as 'docker compose -f /srv/n8n/compose.yml', and its unpublish/import write the database, so the database snapshot is a prerequisite. It unpublishes workflows that were deployed before and have since left the repo (D12).
- **Proposed change:** CLAUDE.md How to verify, the B1 bullet: add 'bash tests/checks/{compose,deploy,snapshot}.sh' (they exist and are what B1 features check).
- *04-B1-04 · claude-opus-5-5*

### 2026-10-27 00:46 · B1-03 · passes

scripts/n8n-snapshot.sh: sqlite .backup to <N8N_DIR>/snapshots/database-<stamp>.sqlite via a checked .part file (mode 600), keeps newest 7; takes live.lock (flock -w 600), skips inside 03:15-04:30 or while restic runs (D14). Units deploy/systemd/n8n-snapshot.{service,timer}, not installed. tests/checks/snapshot.sh 31 PASS. Plan and checklist step 9 filled in.

- **Files:** scripts/n8n-snapshot.sh, tests/checks/snapshot.sh, deploy/systemd/n8n-snapshot.service, deploy/systemd/n8n-snapshot.timer, docs/decisions.md, docs/plans/2026-10-22-B1-compose.md, docs/plans/2026-10-22-live-checklist.md
- **Verified:** bash -n on scripts/*.sh tests/checks/*.sh ok; bash tests/checks/snapshot.sh 31 passed 0 failed (incl. integrity_check ok, rows only in an open writer's WAL copied, 9 old -> 7 left, missing db exit 1, window edges 03:14/03:15/04:30, restic active/activating skip, held lock exit 1, failing copy leaves no .part, systemd-analyze --user verify of both units exit 0 with HOME pointed at a scratch home linking projects/n8n-home to this checkout); tests/checks/deploy.sh 26/0; tests/checks/compose.sh 24/0; docker compose -f deploy/compose.yml config -q exit 0. Plain `systemd-analyze --user verify deploy/systemd/n8n-snapshot.service` exits 1 ('Command /home/mh550/projects/n8n-home/scripts/n8n-snapshot.sh is not executable') until ~/projects/n8n-home has the script after merge+pull; documented in the plan. No live writes this session. Opus review: 1 Important (oneshot restic is 'activating' not 'active' while it runs; confirmed with systemctl show: Type=oneshot RemainAfterExit=no) fixed, Minor lock-before-window, stale .part, journalctl -n 3, window-edge tests fixed.
- **Tests:** 50 → 81
- **Dead end:** systemctl is-active --quiet restic-backup.service to detect a running backup — restic-backup.service is Type=oneshot without RemainAfterExit, so it is 'activating' while it runs and is-active exits 3; now uses systemctl show -p ActiveState --value
- **Discovery** (affects B1-04, B1-05): systemd-analyze --user verify checks ExecStart exists; %h follows $HOME, so HOME=<scratch home with projects/n8n-home -> checkout> verifies a unit before Michael's checkout has the script.
- **Discovery** (affects B1-05, B6-05, run): restic-backup.service is a oneshot: 'activating' while it runs, never 'active'. CLAUDE.md's Backups window rule ('while systemctl is-active ... prints active') never fires during a backup.
- **Discovery** (affects B1-04): sqlite3 shell .backup copies 100 pages per step and restarts when another connection writes between steps; fine at 03:00 on a small db, VACUUM INTO is the fallback if a busy instance ever keeps it restarting.
- **Question for Michael:** D14: the snapshot script waits up to 10 min for /srv/n8n/live.lock and skips (exit 0) inside 03:15-04:30 or while restic runs. OK, or should it take the lock with -n and skip the night instead?
- **Proposed change:** CLAUDE.md ## Live system > Backups > Window: replace 'while `systemctl is-active restic-backup.service` prints `active`' with 'while `systemctl show -p ActiveState --value restic-backup.service` prints anything but `inactive`/`failed`' (a oneshot is `activating` while it runs).
- **Proposed change:** B1-03 step 3: the plain verify command can exit 0 only after ~/projects/n8n-home has the script; the step should accept the HOME-override form tests/checks/snapshot.sh uses (or name the checklist re-check after the pull).
- *03-B1-03 · claude-opus-5-5*

### 2026-10-27 00:38 · B1-02 · passes

scripts/deploy.sh: refusals (deploy paths dirty, unpushed, no .env, foreign N8N_DIR on live project), compose diff, copy, up -d, unpublish-before-import, import, publish active-only, restart, post-check, DEPLOYED; --dry-run, --check. Workflows mount (D13), active marker (D12). tests/checks/deploy.sh (stub docker) 26 PASS; compose.sh 23→24.

- **Files:** scripts/deploy.sh, tests/checks/deploy.sh, tests/checks/compose.sh, deploy/compose.yml, docs/decisions.md, docs/plans/2026-10-22-B1-compose.md, docs/plans/2026-10-22-live-checklist.md
- **Verified:** bash tests/checks/deploy.sh: 26 passed, 0 failed (mutation-tested: publish-all, no unpublish, no push check, no post-check, no active compare, no stale clear, no env -u, no live guard, whole-tree dirty, no db message each turn a check red). bash tests/checks/compose.sh: 24 passed. docker compose -f deploy/compose.yml config -q: OK. bash -n on every *.sh. n8n 2.42.5 CLI verified in throwaway n8n-test-* containers (list/import/publish/unpublish semantics). Live, read-only, 00:38, restic inactive: `flock -n /srv/n8n/live.lock scripts/deploy.sh --dry-run` exit 0, printed sha 5952a99, the compose diff and every command; /srv/n8n listing unchanged except the empty live.lock that flock created. No live write, no snapshot taken (none needed). Opus review: 0 critical, 5 important (all fixed), minor 1,3,4,5(partly),6,8,9 fixed.
- **Tests:** 23 → 50
- **Dead end:** import:workflow --activeState=fromJson — refused outside queue/multi-main mode in 2.42.5
- **Dead end:** re-importing a published workflow — 2.42.5 fails: 'You do not have permission to deactivate this workflow'; deploy.sh unpublishes first
- **Discovery** (affects B1-05, B6-05): 2.42.5 refuses to re-import a published workflow; every redeploy unpublishes the repo's published ones first (D12), so a failure between unpublish and publish needs the DB snapshot rollback; deploy.sh says so
- **Discovery** (affects B2-01, B2-02): deploy/compose.yml now has a 7th mount ./workflows -> /srv/n8n/workflows (ro, create_host_path false); a rig that uses this compose file needs <dir>/workflows to exist
- **Discovery** (affects B2-02, B1-05): deploy.sh refuses N8N_DIR != /srv/n8n while deploy/compose.yml says name: n8n (a real docker would recreate the live container); tests rename the project in their copies
- **Discovery** (affects B1-05): Live dry run: /srv/n8n has no DEPLOYED yet; the deploy will create /srv/n8n/workflows and files/; ~/.local/state/harness/requests must exist before up -d (D11)
- **Question for Michael:** D12: a workflow is marked active by "active": true in its JSON, and the deploy checks for dirty files only under deploy/, workflows/ and scripts/ (the harness writes .harness/ during sessions). OK?
- **Question for Michael:** D13: workflows/ reaches the import through a read-only ./workflows -> /srv/n8n/workflows mount. OK?
- **Proposed change:** B1-02 step 2: the commands are `… exec -T n8n n8n …` (no TTY in sessions) and include `unpublish:workflow --id` before the import (re-import of a published workflow fails in 2.42.5)
- **Proposed change:** CLAUDE.md ## Live system → Deploy: 'refuses a dirty tree' → 'refuses uncommitted files under deploy/, workflows/, scripts/ (D12)'; it runs `docker compose -f /srv/n8n/compose.yml up -d` (same project dir), unpublishes the repo's published workflows before importing, and `/srv/n8n/workflows` is a 7th, read-only mount (D13)
- **Proposed change:** B1-05's mount check expects seven sources (checklist step 5 updated)
- *02-B1-02 · claude-opus-5-5*

### 2026-10-27 00:22 · B1-01 · passes

With docker compose config now allowed, re-checked steps 2, 3, 7 and all hold. tests/checks/compose.sh gains 4 checks on the rendered config (temp copy, no .env, keys unset): config -q, image+port, six mounts with modes, sandbox paths + reporter defaults. Plan, live checklist step 0 (done) and D10 updated for live-staged.

- **Files:** tests/checks/compose.sh, docs/plans/2026-10-22-B1-compose.md, docs/plans/2026-10-22-live-checklist.md, docs/decisions.md
- **Verified:** `docker compose -f deploy/compose.yml config -q` exit 0 with no deploy/.env; `config` shows image docker.n8n.io/n8nio/n8n:2.42.5, 127.0.0.1:5678, the six binds (ledger/state/worktrees ro, requests and /srv/n8n/files rw, ./data at /home/node/.n8n), no docker.sock, no NODES_EXCLUDE, RESTRICT = the five paths, D2 defaults. .env.example keys = compose ${KEY}s (+N8N_ENCRYPTION_KEY), grep -c '=.\+' = 0. bash -n on every *.sh ok. bash tests/checks/compose.sh: 23 passed, 0 failed; mutations (requests ro, LLM_MODEL default, broken YAML) each made the new checks FAIL. No live commands run.
- **Tests:** 19 → 23
- **Discovery** (affects B1-02, B1-05): Rendered compose omits read_only:false and create_host_path:false (bind: {}); the static checks in compose.sh still cover create_host_path.
- **Discovery** (affects B1-02, B1-03, B2-02): No CHECK_CMD yet, so lib/check.sh runs nothing; bash tests/checks/compose.sh is the B1 stand-in until B2's .harness/check.sh.
- **Proposed change:** The brief (2026-10-22) still says 'no deploy, no docker compose, MERGE_POLICY pr'; CLAUDE.md and the 2026-10-23 live-staged change say otherwise. Michael may want to refresh the brief so later sessions don't have to reconcile them.
- *01-B1-01 · claude-opus-5-5*

<!-- harness: progress.md before the journal, kept as it was -->
# Progress log — run `n8n-home-2026-10-22` (branch `harness/n8n-home-2026-10-22`)

What this file is: the shared memory of the agent harness for this run. Each session appends one entry **at the top**
(newest first) when it finishes a feature: what it built, what it learned, what it asks. Nobody edits older entries.

How to read the feature list: `.harness/runs/n8n-home-2026-10-22/feature_list.json`. Array order is priority and
dependency order; the harness hands a session the first feature whose `passes` is false and whose `after` is
satisfied. A session may flip only its own feature's `passes`, and only after the suite is green on the committed
tree (before B2 lands, the stand-in is `bash -n` on every `.sh`, `tests/checks/*.sh`, and `docker compose -f
deploy/compose.yml config -q`). Milestones B1–B6 are spec §8's; each starts with a plan feature and ends with a
review feature; when a milestone passes, the harness verifies it and opens a PR (`MERGE_POLICY=pr`: nothing merges
itself).

How Michael steers: edit `.harness/runs/n8n-home-2026-10-22/INBOX.md` on this branch. First line `status: run | pause |
stop`; answers to the questions below go under `## Answers`. Every session reads it at startup. Defaults taken in his
absence are `D<n> *default*` rows in `docs/decisions.md`; he confirms or changes them there.

---

### 2026-10-22 19:40 · B1-01 · not yet

**Same blocker as last session. No code changed.** `docker compose -f deploy/compose.yml config -q` is still denied by `.claude/settings.json`
(`Bash(docker compose:*)`). I didn't route around it: no `docker run docker/compose`, no edit to settings or to the feature list.
**Re-verified on the tree as committed:** `bash tests/checks/compose.sh` 19 PASS / 0 FAIL. Step 5's key diff matches and `grep -c '=.\+'` gives 0.
The B1 plan has all six sections. The live checklist has 14 `Done when:` lines. `bash -n` passes on both `*.sh`. Steps 1, 5 and 6 hold. Steps 2, 3 and 7 can't be checked from a session.
**For Michael:** the question is now **Q1 in INBOX.md** with options (a)/(b)/(c). I recommend (b). Your brief says never park, so I didn't, but no
session can pass B1-01 until you answer. Every retry repeats this entry.
**Proposed change:** if the harness allows it, carry on with B1-02/B1-03 (their `after` is empty) while B1-01 waits.

### 2026-10-22 19:25 · B1-01 · not yet

**Built (all done and verified, except one check).** `deploy/compose.yml` now has the five harness/files bind mounts at host-equal paths: long syntax with
`create_host_path: false` (D11 *default*, new), plus `N8N_RESTRICT_FILE_ACCESS_TO` (the five paths, `;`-joined, without the data dir), the nine D2
keys and `env_file` `required: false`. New: `deploy/.env.example` (7 keys, no values), `docs/plans/2026-10-22-B1-compose.md`,
`docs/plans/2026-10-22-live-checklist.md` (steps 0–12, §7 order, §7a items marked [done]) and `tests/checks/compose.sh`.
**Checks: 0 → 19.** `bash tests/checks/compose.sh` was 6 PASS / 11 FAIL before the change and 19 PASS / 0 FAIL after. Six mutated copies (volume
type, quoted read_only, a second service with docker.sock, an extra mount, an extra sandbox path, a value in `.env.example`) each FAIL as they should.
Step 5's literal grep/diff and `bash -n` on every `*.sh` pass. Compose plugin is 2.40.3, which supports `env_file.required`. An Opus review found
5 Important and 3 Minor issues; all are fixed except "jq in a check" (jq is a system tool on the box, not an npm package).
**Why not passing:** steps 2–3 (and half of 7) require `docker compose -f deploy/compose.yml config [-q]`, and `.claude/settings.json` denies
`Bash(docker compose:*)`. A deny beats any allow, and I did not route around it. A PyYAML parse confirms the structure, but that is not the render.
**Question for Michael (the run stalls on B1-01 until one is done):** (a) run checklist step 0 yourself and flip B1-01 if it shows what the step
says; or (b) in `.claude/settings.json`, replace the deny `Bash(docker compose:*)` with denies on `docker compose -f /srv*`, `-p n8n*`, `up*`,
`exec*`, `run*` and `down*`, and allow `Bash(docker compose -f deploy/compose.yml config:*)`; or (c) change B1-01..B2-01's stand-in from
"`docker compose … config -q`" to "`bash tests/checks/compose.sh`" in feature_list.json. I'd pick (b): later B1 features need the same check.
**Next session must know:** (1) 2.x blocks `process.env` by default (the image's `process-env-access.rule.js`). Whether `$env.KEY` in Set-node
expressions survives that is **unproven**. B2's first rig check must prove it; the plan's Environment section has the fallback. (2) The B1-02
deploy flow needs `/srv/n8n/workflows` visible inside the container for `exec … import:workflow`; it is not mounted yet (plan, Deploy flow step 4).
`tests/checks/compose.sh` asserts exactly six mounts, so update it with the mount. (3) `deploy.sh` should `env -u` the six interpolated keys so
`/srv/n8n/.env` wins over Michael's shell.
**Proposed changes:** (b) or (c) above. B1-02's step list should include adding the workflows mount.

### 2026-10-22 · initializer

**Feature counts:** B1 compose project 4 · B2 test rig 6 · B3 memory 4 · B4 desk report 8 · B5 phone card 6 ·
B6 error workflow + canvas 4 = **32 features**. First up: `B1-01`, `B1-02`, `B1-03`. Rough cost at $2–4.70 per
passing feature (spec §9): $65–150.

**Read before coding, every session:** `CLAUDE.md`; spec `docs/specs/2026-10-22-harness-reporter.md` §0 (scope,
verified facts; §0.2 wins), §4.3 (contracts), and the section for your milestone; `docs/decisions.md` D1–D10 (the
defaults this plan rests on); your milestone's plan in `docs/plans/`. Run A's spec (the harness side of the
contracts: event, request, result, **context bundle shape**, glossary rules) is read with

    gh api 'repos/mh550/agent-harness/contents/docs/specs/2026-10-22-n8n-events.md?ref=spec/2026-10-22-n8n-events' -H 'Accept: application/vnd.github.raw'

never by checking anything out in `~/projects/agent-harness`. Its `context.json` shape: `{v, id, generated_at,
scope: {runs, since}, runs: [{run, project, ended, running, features, paths: {record, worktree, state, report, inbox,
progress}, summary, parked: [{feature, why, question}], open_questions}], glossary: [{id, kind, text, source}],
unresolved: []}`; `context.md` is the gatherer's markdown plus `## Glossary`. The result file the harness writes is
`requests/done/<id>.json` = `{v, id, at, verb, run, ok, exit, output, runner_started, refused}`.

**Where things live (nothing but `deploy/compose.yml` exists yet):**
- `deploy/compose.yml` (B1 extends it), `deploy/.env.example`, `deploy/systemd/` (snapshot timer, not installed).
- `scripts/deploy.sh` (Michael-only; D10), `scripts/n8n-snapshot.sh`, `scripts/sync-code-nodes.mjs` + `scripts/code-nodes.json` (D6).
- `workflows/*.json` deploys; planned files and fixed ids: `10-event-intake`, `20-desk-report` (serving may be
  `21-report-serve`), `30-memory`, `40-phone-card` (answering may be `41-card-serve`), `90-error-handler`. Pick ids
  of 16–24 letters/digits (`HarnessEventIntake01`-style worked in the spike) and keep them forever: the rig and
  `deploy.sh` publish by id. Webhook paths are fixed: `harness-event`, `report-now`, `report`, `report-check`,
  `card`, `card-answer`.
- `tests/run.sh` (the suite; `.harness/check.sh` runs it), `tests/lib.sh`, `tests/checks/*.sh` (one PASS/FAIL line
  per check), `tests/fakes/server.mjs` (+ `responses/`), `tests/unit/*.test.mjs` (`node --test`), `tests/workflows/`
  (test-only workflows, D8). `fixtures/harness/` (sanitised real files), `fixtures/events/`, `fixtures/bundles/`,
  `fixtures/credentials.json`, `fixtures/README.md`.
- `lib/*.js`: Code-node logic as plain functions (D6): `memory.js`, `report.js`, `card.js`.
- Docs: `docs/plans/2026-10-22-<milestone>-<topic>.md`, `docs/plans/2026-10-22-live-checklist.md` (every live step
  for Michael, in order, with `Done when:`), `docs/workflows.md`, `docs/memory.md`, `docs/decisions.md`, `README.md`.

**Verified in a throwaway container on 2026-10-22 (image `docker.n8n.io/n8nio/n8n:2.42.5`, already pulled):**
- `n8n import:workflow --separate --input=<dir>` imports but leaves workflows **unpublished** ("Deactivating
  workflow …"); `n8n update:workflow --all --active=true` is deprecated and does nothing; `n8n publish:workflow
  --id=<id>` publishes (needs n8n not running, or a restart); then `n8n start` → the webhook answers 200 about 4 s
  after `/healthz` is 200 (healthz itself ~6–20 s after start). Run import and publish as separate `docker run --rm`
  invocations on the same data dir, then start the long-lived container (D1). `n8n list:workflow` prints `id|name`.
  Other CLI: `import:credentials`, `export:credentials --decrypted` (use it once to learn the import shape),
  `export:workflow`, `user-management:reset`.
- `--network host` + `N8N_LISTEN_ADDRESS=127.0.0.1` + `N8N_PORT=<random>` works; the container's node user is uid
  1000 = mh550, so a plain `mktemp -d` scratch dir is writable without chmod. Set `N8N_DIAGNOSTICS_ENABLED=false`,
  `N8N_VERSION_NOTIFICATIONS_ENABLED=false`; no owner account is needed for production webhooks.
- Security defaults in the image: `restrictFileAccessTo = '~/.n8n-files'`, `blockFileAccessToN8nFiles = true`,
  `blockFilePatterns` blocks any path with a `.git` segment (worktree `.harness/runs/...` paths are fine). The rig must
  set `N8N_RESTRICT_FILE_ACCESS_TO` to the scratch mounts exactly as the compose does for the live paths.
- Webhook HTML responses are wrapped in a sandboxed iframe (`n8n-core/dist/html-sandbox.js`) whose sandbox is
  `allow-downloads allow-forms allow-modals allow-orientation-lock allow-pointer-lock allow-popups
  allow-popups-to-escape-sandbox allow-presentation allow-scripts allow-top-navigation-by-user-activation
  allow-top-navigation-to-custom-protocols`. Forms and scripts work; the content is `srcdoc`, so **relative URLs
  break: every link and form action must be absolute** (`$env.PUBLIC_BASE_URL`). A check must assert on the body
  text, not on the outer HTML being the report itself.

**Gotchas for workers:**
- Code nodes in 2.x run in a task runner: do not rely on `$env`, `require`, `fs` or `crypto` inside Code. Read
  `$env.*` in a `Config` Set node's expressions and pass values along as fields; read/write files with the Read/Write
  Files from Disk node; make UUIDs with the Crypto node ("Generate") or build ids from `$execution.id` + timestamp
  (the request id regex is `^[A-Za-z0-9-]{8,64}$`). If a Code node does need `$env`, prove it in the rig first.
- Anthropic (spec §0.2): `POST <LLM_BASE_URL>/v1/messages`, headers `x-api-key`, `anthropic-version`; body `model`,
  `max_tokens`, `system`, `messages`, `output_config: {format: {type: "json_schema", schema: {...}}}`; **never**
  `temperature`/`top_p`/`top_k`/`tool_choice`/`thinking` (the fake returns 400 on them, like the real API since
  2026-10-21). Cost at $2/$10 per Mtok from `usage`. Use the HTTP Request node, not the Anthropic Chat Model node.
- Credentials: reference them by **name** (`Anthropic API key`, `ntfy token`); n8n's import re-links by type+name
  when the id is unknown (B2-05 proves it; if it does not, fall back to fixed credential ids in both the fixture and
  the checklist and record the change in `docs/decisions.md` D2).
- Mounting a parent read-only and a child read-write (`~/.local/state/harness` ro, `…/requests` rw) is fine in
  Docker: list the child after the parent.
- `docker compose` is denied for every session (settings deny rule) and must never appear under `tests/`; the rig
  uses `docker run`/`docker rm -f` on `n8n-test-*` names only. Never name `n8n-n8n-1`. `docker compose -f
  deploy/compose.yml config -q` is the one allowed compose use (B1) and needs `env_file: - path: .env  required: false`.
- Fixture sources (read-only): `~/projects/agent-harness/ledger/runs.jsonl` and
  `ledger/<project>/<run>/{summary.json,report.md,progress.md,INBOX.md,feature_list.json,harness-log.md,metrics.jsonl}`
  for `dj-crate-streaming/dj-2026-10-17` (33 features, 4 continuations, "For Michael" INBOX sections, 40
  question-ish lines in progress.md), `dj-crate-streaming/dj-crate-streaming-2026-10-21`,
  `agent-harness/agent-harness-2026-10-21-measure`; the run record also sits at
  `~/worktrees/dj-crate-streaming/dj-2026-10-17/.harness/runs/dj-2026-10-17/`; decision table rows `| D1 | … |` in
  `~/worktrees/dj-crate-streaming/dj-2026-10-17/docs/specs/2026-10-13-next-session-design.md`. No
  `parked.json` exists for ended runs (state dirs hold `attempts.json`, `inbox.md`, `logs/`), so the bundles'
  `parked[]` are shaped from the INBOX/progress questions. A secret scan of the dj ledger dir found nothing, but
  scan what you copy (`ntfy.sh/`, `tk_…`, `sk-ant-`, `ghp_`, emails).
- Tools on the box: node 24.21 (`node --test`, `crypto.randomUUID`), docker 29, sqlite3, jq, python3,
  `systemd-analyze`, firefox, and Playwright's browsers at `~/.cache/ms-playwright/chromium_headless_shell-1248/`
  and `chromium-1248/` (use the binaries directly for screenshots; no npm packages). `n8n-docs` MCP
  (`validate_workflow`, `validate_node`, node docs) is allowed and expected before importing any workflow JSON;
  the instance MCP is read-only.
- Timing: budget the suite at under 4 minutes; wait for files/ntfy with a polling helper and a hard timeout, never a
  bare `sleep`. Every check prints `PASS <name>` or `FAIL <name>: <why>`; the suite ends with `<n> passed, <m>
  failed` and exits 1 on any FAIL.
- Nothing live, ever: no deploy, no `sudo`, no writes under `/srv`, `~/.local/state/harness`, `~/projects`,
  `~/worktrees/*` (other than this worktree), no real ntfy or Anthropic calls. Live steps go into
  `docs/plans/2026-10-22-live-checklist.md` as commands with `Done when:`.

**Questions for Michael (defaults taken, all reversible; see `docs/decisions.md`):**
1. Secrets as n8n credentials matched by name (`Anthropic API key`, `ntfy token`), non-secret config via env (D2).
   Alternative: everything in `.env`. Changing it later touches the HTTP Request nodes and the checklist only.
2. The phone card is a webhook-served HTML form, not an n8n Form node (D5). If you prefer the n8n Form look for the
   application screenshot, say so; only `40-phone-card` changes.
3. Memory as three JSONL files under `/srv/n8n/files/memory/` rather than Data Tables (D3).
4. `scripts/deploy.sh` imports and publishes the workflows and restarts n8n on every deploy (seconds of downtime;
   D10). Alternative: import by hand in the editor.
5. Public-topic mode sends only the run name and a link until you set `NTFY_PRIVATE=true` (D9).
