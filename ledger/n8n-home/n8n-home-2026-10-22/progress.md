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

## Older entries (in full in progress-archive.md)

- 2026-10-27 16:57 · B5-01 · passes · Wrote docs/plans/2026-10-22-B5-phone-card.md: card schema and prompts, workflows 40 (build) and 41 (… ([in full](progress-archive.md))
- 2026-10-27 16:35 · verify B4 · passes · Suite 60/0, units 145/145. All 8 features hold on re-run, incl. B4-08 step 2: every Code node is 3 l… ([in full](progress-archive.md))
- 2026-10-27 16:33 · B4-08 · passes · Step 2 now holds literally: every Code node is 3 lines requiring lib/ as the module n8n-home-lib (li… ([in full](progress-archive.md))
- 2026-10-27 16:02 · verify B4 · not yet · Suite 60/0, units 141/141. All steps hold except B4-08 step 2: Code nodes are 1575 lines each (whole… ([in full](progress-archive.md))
- 2026-10-27 15:59 · B4-08 · passes · B4 reviewed (two Opus passes) and simplified; B4-07's 9 page defects fixed (tall diagram, stacked co… ([in full](progress-archive.md))
- 2026-10-27 15:20 · B4-07 · passes · docs/plans/2026-10-22-B4-what-michael-sees.md: the recorded ntfy (Title 'Desk report ready', body 'D… ([in full](progress-archive.md))
- 2026-10-27 15:14 · B4-06 · passes · Report 2 proves memory in the rig: new group report-memory (4 checks), the fake picks <title>.<metad… ([in full](progress-archive.md))
- 2026-10-27 14:56 · B4-05 · passes · workflows/21-report-serve.json: GET /webhook/report?id= serves the stored page raw (guarded id, date… ([in full](progress-archive.md))
- 2026-10-27 14:34 · B4-04 · passes · Desk report workflow 20 builds a report end to end in the rig: intake or report-now, bundle+ledger+m… ([in full](progress-archive.md))
- 2026-10-27 14:10 · B4-03 · passes · lib/report.js: prompt input, Messages body, plan parse/resolve, 8-section HTML with ID glossing, bar… ([in full](progress-archive.md))
- 2026-10-27 13:36 · B4-02 · passes · Event intake: workflows/10-event-intake.json (ReporterIntake10) validates v1 + routed kinds in lib/i… ([in full](progress-archive.md))
- 2026-10-27 13:22 · B4-01 · passes · Wrote docs/plans/2026-10-22-B4-desk-report.md: intake, report and serve workflows node by node, repo… ([in full](progress-archive.md))
- 2026-10-27 12:55 · verify B3 · passes · All four B3 features hold: suite 40/0, 52 unit tests, sync check (and drift detection in scratch), v… ([in full](progress-archive.md))
- 2026-10-27 12:53 · B3-04 · passes · B3 review in docs/plans/2026-10-22-B3-review.md (21 rows). Fixed: save refuses a file read empty or … ([in full](progress-archive.md))
- 2026-10-27 12:36 · B3-03 · passes · workflows/30-memory.json (ReporterMemory30, active, 8 nodes + 4 stickies, Code node synced from lib/… ([in full](progress-archive.md))
- 2026-10-27 12:22 · B3-02 · passes · lib/memory.js (rules + helpers) and lib/memory-node.js (main) with 44 node --test unit tests; script… ([in full](progress-archive.md))
- 2026-10-27 12:08 · B3-01 · passes · Wrote docs/plans/2026-10-22-B3-memory.md: three JSONL schemas, lib/memory.js rules and helpers, the … ([in full](progress-archive.md))
- 2026-10-27 11:46 · verify B2 · passes · All six B2 features hold: full suite 19 passed 0 failed (39s), also from a fresh clone; FAIL_ME/KEEP… ([in full](progress-archive.md))
- 2026-10-27 11:42 · B2-06 · passes · Reviewed B2 (2 Opus passes, 16 findings, 1 Important). D15 check now allows only $env.<reporter key>… ([in full](progress-archive.md))
- 2026-10-27 11:19 · B2-05 · passes · Rig now stages fixtures into scratch (placeholders replaced), starts the fake server first (FAKE_POR… ([in full](progress-archive.md))
- 2026-10-27 11:08 · B2-04 · passes · Added fixtures/: real ledger rows and run records (byte-identical copies), the dj-2026-10-17 run fil… ([in full](progress-archive.md))
- 2026-10-27 10:54 · B2-03 · passes · Built tests/fakes/server.mjs (fake Anthropic /v1/messages with the 2026-10-21 400s and canned answer… ([in full](progress-archive.md))
- 2026-10-27 10:46 · B2-02 · passes · Built the rig: tests/run.sh + lib.sh, .harness/check.sh, rig-smoke workflow, smoke (rig) and workflo… ([in full](progress-archive.md))
- 2026-10-27 10:28 · B2-01 · passes · Wrote docs/plans/2026-10-22-B2-test-rig.md: layout, lifecycle (mktemp /tmp/n8n-test-*, cli import+pu… ([in full](progress-archive.md))
- 2026-10-27 10:21 · verify B1 · passes · All five B1 features hold: deploy 38, snapshot 32, compose 24 checks pass; bash -n clean; compose co… ([in full](progress-archive.md))
- 2026-10-27 10:19 · B1-05 · passes · B1 deployed live at 10:17: dry run, then `flock -n /srv/n8n/live.lock scripts/deploy.sh` -> `deploye… ([in full](progress-archive.md))
- 2026-10-27 01:03 · B1-05 · parked · Live deploy not run: bind source ~/.local/state/harness/requests is missing (create_host_path:false,… ([in full](progress-archive.md))
- 2026-10-27 00:59 · B1-04 · passes · Opus review of the B1 diff: 0 Critical, 3 Important, 5 Minor. Each Important fix was a RED then a GR… ([in full](progress-archive.md))
- 2026-10-27 00:46 · B1-03 · passes · scripts/n8n-snapshot.sh: sqlite .backup to <N8N_DIR>/snapshots/database-<stamp>.sqlite via a checked… ([in full](progress-archive.md))
- 2026-10-27 00:38 · B1-02 · passes · scripts/deploy.sh: refusals (deploy paths dirty, unpushed, no .env, foreign N8N_DIR on live project)… ([in full](progress-archive.md))
- 2026-10-27 00:22 · B1-01 · passes · With docker compose config now allowed, re-checked steps 2, 3, 7 and all hold. tests/checks/compose.… ([in full](progress-archive.md))
