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

## Answers
