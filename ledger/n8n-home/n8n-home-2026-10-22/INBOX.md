status: run
<!-- Steer this run from the GitHub app: edit this file on branch harness/n8n-home-2026-10-22.
     Change the first line to "status: pause" or "status: stop"; write answers to questions under "## Questions

**Q1 (B1-01, 2026-10-22 19:40). The run is stuck on B1-01 until you answer.** Steps 2, 3 and 7 require `docker compose -f deploy/compose.yml config`,
and `.claude/settings.json` denies `Bash(docker compose:*)`. No session can verify the steps or work around the deny, and I can't
pick a default for it myself. Everything else in B1-01 is built and checked (`bash tests/checks/compose.sh`: 19 PASS). Pick one:
- (a) Run `docker compose -f deploy/compose.yml config` in this worktree yourself, and set B1-01 `passes` to true if the output matches steps 2–4.
- (b) In `.claude/settings.json`, allow `Bash(docker compose -f deploy/compose.yml config:*)` and replace the blanket deny with denies on
  `docker compose -f /srv*`, `docker compose -p n8n*`, `docker compose * up*`, `* exec*`, `* run*`, `* down*`. Later B1 features need the same check. (recommended)
- (c) Change the stand-in for B1-01..B2-01 in feature_list.json from `docker compose … config -q` to `bash tests/checks/compose.sh`.

## Answers".
     The harness pulls before every session; every session reads this file at startup. -->

**Q2 (B1-05, 2026-10-27 01:05). The B1 live deploy is waiting on one directory.** `~/.local/state/harness/requests`
(the request inbox, mounted rw) doesn't exist, and with `create_host_path: false` the new compose file can't start
without it. Sessions may not write under `~/.local/state/harness`, and live checklist step 4 makes it your step (or Run
A's). Everything else is ready: Check green, restic 2026-10-26 03:42 status 0, dry run clean on 27cb037 apart from this.
`scripts/deploy.sh` now refuses up front when a mount source is missing. Please run:

    install -d -m 700 ~/.local/state/harness/requests && stat -c '%a %U' ~/.local/state/harness/requests   # 700 mh550

and answer "Q2: done". The next B1-05 session deploys under `## Live system`. Also: the run brief (2026-10-22) still
says "build-only, nothing live", while `POLICY=live-staged` (2026-10-23) and B1-05 say deploy. I'm going by the
newer live-staged rule. Say so if the brief should win.

## Answers

### 2026-10-27 00:19 (local)
Q1: done as (b) on main (afd3273, 89d11d2). The run merges main at its start. Re-check B1-01 steps 2, 3 and 7 with 'docker compose -f deploy/compose.yml config -q' and carry on.

### 2026-10-27 10:16 (local)
Q2: done (700 mh550). The live-staged policy from 2026-10-23 wins over the 10-22 brief: deploy B1-05 under ## Live system.
