# Debrief · 2026-10-27 01:48

_runs since 2026-10-26 13:34:43: agent-harness-2026-10-25-memory agent-harness-2026-10-26 n8n-home-2026-10-22 · claude-sonnet-5-5, $0.21821800000000002 · context: /home/mh550/.local/state/harness/debrief/2026-10-27-014815/context.md_

## Headline
Landed on main: agent-harness memory run, M1–M6 (23/23, PRs up to #37). Nothing else merged.
Blocked: n8n-home on B1-05 (one `install -d` from you). agent-harness-2026-10-26 is stopped at 7/17 and needs a rebase onto main.
Spend $149.68. Window open: five_hour 14% (resets Tue 03:40), seven_day 20% (resets Sun 17:00).

## Runs
### agent-harness-2026-10-25-memory (agent-harness) · done
- 23/23 passing, verified and merged for all six milestones M1–M6 (6 merges). Tests 395 → 501. $58.05 ($2.52 per feature), 6.89 h.
- The only rework was M5-01. Its step cited "this run's scratch check.out" (395), but the fixture held 474, so M5 verify failed once.
- Retro proposes: lint steps that cite unreproducible values, a pre-verify literal check, and re-running only the flaky suite file.
- Init file 13 went red once and passed alone.

### agent-harness-2026-10-26 (agent-harness) · stopped by Michael
- 7/17 passing. P0 (4 features) verified and merged (PR #30). P1-01..03 pass but are unverified. Tests 419 → 430. $69.06 ($9.87 per feature), 7.58 h, 2 continuations.
- P1-04 was un-passed because the suite was red after a 58 min session. It was too big: the lane.sh and driver.sh rewrite plus a record.sh extraction. P1-05..P2-07 (9 features) were not reached.
- You stopped it to rebase onto main (conflicts in `lib/driver.sh`) once the memory run ended. It has now ended.
- Retro: the run was blocked twice after two failed attempts and sat idle for hours. P1-03 lost about 50 min to a missing `entry.json`.

### n8n-home-2026-10-22 (n8n-home) · waiting on Michael: B1-05
- 4/34 passing (B1-01..04), none verified or merged. $22.57, 1.33 h.
- B1-05 (the live deploy) parked because `~/.local/state/harness/requests` doesn't exist. Sessions may not create it, and `deploy.sh` now refuses up front.
- The other 29 features are marked blocked on B1-05. The retro says B2 is rig work in a throwaway container and doesn't need the live deploy.

## Needs Michael
- **n8n-home B1-05 (Q2, progress.md and INBOX):** run `install -d -m 700 ~/.local/state/harness/requests && stat -c '%a %U' ~/.local/state/harness/requests`. It should print `700 mh550`. Then answer "Q2: done" in INBOX.md.
- **n8n-home, also in progress.md:**
  - Can the proposed CLAUDE.md wording go in (restic check, Deploy paragraph)?
  - D12, D13 and D14: are the active-flag, read-only workflows mount and snapshot lock-wait defaults OK?
- **agent-harness-2026-10-26, rebase:** the run needs rebasing onto main now that memory has merged. Also decide D7 (should the default lane be verified and merged), D8 (deploy guards for `harness-lane/**`, which needs a `vercel.json` edit on portfolio_site), D2, D9–D12, the treekey and D1 defaults, and the legacy-refusal question.
- **Memory run, product calls (progress.md):**
  - Should the reviewer subagent follow the session's model? The question was asked three times.
  - Should the memlint notes repeat every segment, and are memlint defaults D1–D4 OK?
  - Should `run_init` pin the testcount source only from a green suite?
  - Is the review-gate Minor #8 worth a fix?
  - Should a review-bearing eval task be added?

## Draft answers
**n8n-home, "does the build-only brief still hold, or does live-staged win?"**
- Answer: live-staged wins, so the B1-05 session's assumption was right.
- Source: `~/.claude/CLAUDE.md`: "n8n-home: **live**. Agents deploy through the live-staged protocol in its `CLAUDE.md` (`## Live system`)".

## For the next interactive session
- **Merge conflicts:** `harness/agent-harness-2026-10-26` conflicts with main in `lib/driver.sh` (P1). The memory run is merged and its branch was deleted by gc.
- **Held or refused merges:** none. The n8n and 10-26 P1 milestones are unverified and unmerged.
- **Retro candidates in two or more retros** (I did not read the earlier ledger retros):
  - Lint or flag verify steps whose numbers can't be met or reproduced: P0-02 in the 10-26 run (a <150 s gate that was out of reach) and M5-01 in the memory run (scratch fixture 395 vs 474).
  - Proposed once only, each worth a look: split oversized features before the session (10-26); finer dependency granularity so build-only work continues while a live step is parked (n8n); preflight host-path blockers (n8n); ask for a missing `entry.json` instead of recording a minimal one (10-26).
- The driver should merge main at milestone boundaries; this was proposed only by the 10-26 retro.
