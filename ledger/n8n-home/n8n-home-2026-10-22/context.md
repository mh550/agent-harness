# Context pack for `B1-05`

Chosen by the harness from entries.jsonl in a fixed order; each item names its line. The full record is entries.jsonl / progress-archive.md.

## Michael's answers

- The harness pulls before every session; every session reads this file at startup. --> ## Answers ### 2026-10-27 00:19 (local) Q1: done as (b) on main (afd3273, 89d11d2). The run merges main at its start. Re-check B1-01 steps 2, 3 and 7 with 'docker compose -f deploy/compose.yml config -q' and carry on. → INBOX.md

## Discoveries for this feature

- Discovery (B1-04, affects B1-05, run): flock(1) passes its lock descriptor to the command it runs, and the command can flock that fd again at once (same open file description). n8n-snapshot.sh relies on this. → entries.jsonl:4
- Discovery (B1-04, affects B1-05, B6-05, B2): deploy.sh now refuses 03:15-04:30 and while restic-backup.service is active/activating (override DEPLOY_TIME=HHMM, SYSTEMCTL for tests). It also unpublishes workflows in DEPLOYED's commit that HEAD lacks, and warns when that commit isn't fetched. → entries.jsonl:4
- Discovery (B1-03, affects B1-04, B1-05): systemd-analyze --user verify checks ExecStart exists; %h follows $HOME, so HOME=<scratch home with projects/n8n-home -> checkout> verifies a unit before Michael's checkout has the script. → entries.jsonl:3
- Discovery (B1-03, affects B1-05, B6-05, run): restic-backup.service is a oneshot: 'activating' while it runs, never 'active'. CLAUDE.md's Backups window rule ('while systemctl is-active ... prints active') never fires during a backup. → entries.jsonl:3
- Discovery (B1-02, affects B1-05, B6-05): 2.42.5 refuses to re-import a published workflow; every redeploy unpublishes the repo's published ones first (D12), so a failure between unpublish and publish needs the DB snapshot rollback; deploy.sh says so → entries.jsonl:2
- Discovery (B1-02, affects B2-02, B1-05): deploy.sh refuses N8N_DIR != /srv/n8n while deploy/compose.yml says name: n8n (a real docker would recreate the live container); tests rename the project in their copies → entries.jsonl:2
- Discovery (B1-02, affects B1-05): Live dry run: /srv/n8n has no DEPLOYED yet; the deploy will create /srv/n8n/workflows and files/; ~/.local/state/harness/requests must exist before up -d (D11) → entries.jsonl:2
- Discovery (B1-01, affects B1-02, B1-05): Rendered compose omits read_only:false and create_host_path:false (bind: {}); the static checks in compose.sh still cover create_host_path. → entries.jsonl:1

## Lately in the run

- 2026-10-27 00:59 · B1-04 · passes: Opus review of the B1 diff: 0 Critical, 3 Important, 5 Minor. Each Important fix was a RED then a GREEN commit: n8n-snapshot.sh under 'flock -n live.lock' reuses the inherited lock (it used to wait on itself); deploy.sh refuses 03:15-04:30 or a running restic; deploy.sh unpublishes workflows retired since DEPLOYED. Minors fixed. Added README.md and docs/plans/2026-10-22-B1-review.md.; tests 81 → 91; files README.md, docs/plans/2026-10-22-B1-review.md, scripts/deploy.sh, scripts/n8n-snapshot.sh, tests/checks/deploy.sh, … → entries.jsonl:4
- 2026-10-27 00:46 · B1-03 · passes: scripts/n8n-snapshot.sh: sqlite .backup to <N8N_DIR>/snapshots/database-<stamp>.sqlite via a checked .part file (mode 600), keeps newest 7; takes live.lock (flock -w 600), skips inside 03:15-04:30 or while restic runs (D14). Units deploy/systemd/n8n-snapshot.{service,timer}, not installed. tests/checks/snapshot.sh 31 PASS. Plan and checklist step 9 filled in.; tests 50 → 81; files scripts/n8n-snapshot.sh, tests/checks/snapshot.sh, deploy/systemd/n8n-snapshot.service, deploy/systemd/n8n-snapshot.timer, docs/decisions.md, … → entries.jsonl:3
- 2026-10-27 00:38 · B1-02 · passes: scripts/deploy.sh: refusals (deploy paths dirty, unpushed, no .env, foreign N8N_DIR on live project), compose diff, copy, up -d, unpublish-before-import, import, publish active-only, restart, post-check, DEPLOYED; --dry-run, --check. Workflows mount (D13), active marker (D12). tests/checks/deploy.sh (stub docker) 26 PASS; compose.sh 23→24.; tests 23 → 50; files scripts/deploy.sh, tests/checks/deploy.sh, tests/checks/compose.sh, deploy/compose.yml, docs/decisions.md, … → entries.jsonl:2
