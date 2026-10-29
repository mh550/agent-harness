# Debrief · 2026-10-28 22:40

_runs since 2026-10-27 01:48:15: agent-harness-2026-10-26 agent-harness-2026-10-28 n8n-home-2026-10-22 · claude-sonnet-5-5, $0.198248 · context: /home/mh550/.local/state/harness/debrief/2026-10-28-224015/context.md_

## Headline
All three runs finished, 75/75 features verified and merged to main. agent-harness-2026-10-26 merged P0, P1 and P2 (PRs #40, #41). agent-harness-2026-10-28 merged U1, U2 and U3 (PR #45). n8n-home-2026-10-22 merged B1–B6 (PRs #6–#11). Nothing is blocked.
Spend $436.58. The usage window is open: five_hour 2% (resets Thu 02:00), seven_day 38% (resets Sun 17:00).

## Runs
### agent-harness-2026-10-26 (agent-harness) · done
- 17/17 passing, P0, P1 and P2 verified and merged. Tests 419 → 602. $127.95 ($7.53 per feature), 14.2 h wall, 4 continuations.
- It stopped four times, each needing Michael: P0-02 (a spec step demanding <150 s, ruled "measured, not a gate"), P1-03 (entry.json missing twice), and two rebases onto main. About 8.5 h of the wall time was spent waiting.
- The retro proposes three things: validate entry.json inside the session, carry on with independent features when one is blocked, and escalate main conflicts early.

### agent-harness-2026-10-28 (agent-harness) · done
- 24/24 passing, U1, U2 and U3 verified and merged. Tests 602 → 859. $139.24 ($5.80 per feature), 21.5 h wall.
- Only U1-07 needed rework. One usage-limit wait (`limit_waits` 1).
- Review was 16% of cost and every review found something. The retro proposed suite-flake-retry and verify-evidence-rows, both now in the backlog.

### n8n-home-2026-10-22 (n8n-home) · done
- 34/34 passing, B1–B6 verified and merged. Tests 10 → ? (no end count recorded). $169.39 ($4.98 per feature), 11.8 h wall, 2 continuations.
- It was blocked twice and each time needed Michael. B1-01 was blocked on the docker compose deny, which wasn't in the brief. B1-05 waited about 9 h for `~/.local/state/harness/requests` to be created.
- Verify caught B4-08 and B6-01, each fixed in one more attempt.
- B6-02 lost its session summary to the 400-character limit on `entry.json`.

## Needs Michael
All of these are defaults the runs took, with no deadline.
- **agent-harness-2026-10-26, P2-07 and P1-04 (progress.md):**
  - D21: gc now keeps a record branch while its record PR is open. Keep that?
  - D7: should the default lane (features with no milestone) be verified and merged? Today its code never reaches main.
  - D9–D14, D16–D18 and D15: lane defaults, including whether MAX_LANES>1 should wait until P2 merges.
  - LANE_RESERVE_GB=4 and LANE_OPEN_BELOW_5H=70: change either before the first night at MAX_LANES=2?
- **agent-harness-2026-10-28, U3 and the earlier U-features (progress.md):**
  - Does a bare project name resolve through its runs' PROJECT_DIR before `~/projects`?
  - Should `show` count a path once when two run branches have the same blob?
  - Should named() drop `docs/plans/`?
  - Should an overlap record resolve once either side is on main?
  - Does a trends table that lists newest first and drops columns when narrow suit you?
- **n8n-home, D28/R1, D30 and D31:**
  - On the public topic, the error fallback sends only the title, link and priority. Keep that?
  - Before you have an ntfy token, create the `ntfy token` credential as Header Auth `X-Ntfy-Unused: none`. OK?
  - 20 desk report, 40 phone card and 90 error handler are live but unpublished until you create `Anthropic API key` and `ntfy token`. Checklist step 6 publishes them. Publish all seven now instead?

## For the next interactive session
- No merge conflicts, holds or refusals. gc deleted both agent-harness run branches. The n8n-home worktree and branch are listed as removed.
- Open `proposed` backlog items:
  - `suite-flake-retry`: re-run failed test files serially before declaring the suite red (seen 1×).
  - `verify-evidence-rows`: record per-step evidence rows from verify sessions (seen 1×).
  - `no-retry-on-denial`: don't retry a session that stopped on a permission question with nothing changed (seen 0×).
- Not yet in the backlog, so worth adding:
  - entry.json validated inside the session, with the error returned so the session can fix it. Seen in agent-harness-2026-10-26 (P1-03, P2-01) and n8n-home (B6-02): 2 runs.
  - A brief preflight against CLAUDE.md and settings (n8n-home B1-01 and B1-05).
  - Escalating a main conflict early (agent-harness-2026-10-26).
  - The retro's blocked-spec-step proposal is probably covered by the merged `carry-on-past-given-up` (lanes), but I didn't confirm that.
- Check whether n8n-home's `tests` end count (null in summary.json) is a harness bug.
