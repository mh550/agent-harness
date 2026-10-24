## Outcome
All 28 features passed, were verified and were merged (M1–M4, PRs #2 and #3) at $130.50 and 9.4 h wall, with 41 sessions and tests going from 8 to 868. The run ended `done`. It was stopped twice along the way (parked at 18:17 on 10-19 waiting on M1-04, and stopped by Michael at 09:18 on 10-20), and it needed 2 continuations. The M1–M4 merges were delayed until M4, because the M1 and M2 tags each contained unverified M3-01 work.

## Non-passing features by cause
No feature ended as "not done". Three were bounced by verify and later passed:
- **M1-04** (3 sessions, 41 min, $7.41): spec problem. It was parked with "Michael to choose: amend M1-04 step 3 to check the version line in stdout… or drop `--controller-debug`". This stalled the run for about 14 h.
- **M1-05** (2 sessions): failed the re-check and was fixed in a retry. I did not check the cause.
- **M3-05** (2 sessions, 32 min, $7.85): failed the re-check once. I did not trace the cause.

## Harness behaviour
- **Guards:** 3 `verify_failed`, 0 repairs, 0 `red_unpass`, 0 limit waits. The re-check guard fired and the retries passed, so it looks correct.
- **Failure reasons:** the `verify_failed` log lines carry no reason.
- **Verify cost:** verify was cheap, $2.44 across 6 sessions on Sonnet.
- **Evidence rows vs steps:** I did not compare these. `summary.json` has no per-step counts, so I can't confirm the verifies re-ran every step. Failing 3 features suggests they did real work.
- **Review cost:** review was $23.27, 18% of spend and 2.16 h. The review role is billed on Opus (`by_model`: Opus $123.08).
- **Held merges:** M1 and M2 were held until M4, so M1 and M2 sat unmerged for about 1.5 days.
- **Long M4-08:** this session ran 81 min for $9.23. The cause is not examined here.
- **Retro and docs:** retro and docs were negligible.

## Proposed harness changes
1. **Cap or skip per-milestone review on small milestones, or route it to Sonnet** (driver config). Evidence: review was $23.27 of $130.50 here, and Sonnet verify costs about $0.40 per session. This is a repeat, proposed in `v2-2026-10-18`, `agent-harness-2026-10-19`, `rane-one-mixxx-2026-10-19`, `portfolio_site-2026-10-20`, `-2` and `-v3`, and `voice-concierge-2026-10-20` and `-10-21`. It is still unfixed.
2. **Lint steps at plan time by dry-running them** (init and plan prompts). Evidence: M1-04 needed a spec amendment and a 14 h human wait over a step about `--controller-debug` stdout. M1-05 and M3-05 also failed verify. Repeat of the dry-run-steps idea first proposed in this run's own earlier retro, then in `voice-concierge-2026-10-20` and `hit_list-2026-10-20`.
3. **Let a parked feature not block unrelated milestones, and put the failure reason in the `verify_failed` log line** (driver). Evidence: after M1-04 parked, the run ended waiting for 14 h. Held-milestone merging also delayed M1 and M2. The reason-in-log half was proposed in `hit_list-2026-10-20`. The parked-feature half was proposed in `voice-concierge-2026-10-20`.
