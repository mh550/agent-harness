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
