## Outcome
The run delivered 11 of 29 features. E1 passed all 9 features and was verified and tagged `run/agent-harness-2026-10-21-measure/E1`. E2-01 and E3-01 also passed. Nothing was merged, and the run ended "blocked on E2-02" at 18:34. It cost $37.60 over 4.3 h in 15 sessions. The main reason is that E2-02 failed twice and the other 17 features were waiting on it. Several of those waits were not real dependencies.

## Non-passing features by cause
- **E2-02: not done, 2 sessions, $4.30.** Cause: spec or feature-list problem, plus a permission denial. The step says to add retried and depends-on tasks from other projects' run records, but the session could not read `~/projects/*/.harness/runs`. Evidence: "Question for Michael… allow reads of the source records… `git clone -q --mirror /home/mh550/projects/*`".
- **17 features had cause "blocked"** (E2-03…08, E3-02…05, E4-01…07), with no session of their own. Cause: depends on a failed feature. The E2-02 builder wrote that E2-03…E2-06 "don't need more tasks, so the run can go on past E2-02". The feature list gave E3-02…05 no `after`, so they waited on E2. The builder spotted this: "E3-02 … E3-05 have no `after`… Add `"after": ["E3-01"]`".

## Harness behaviour
- **Guards:** none fired (repairs, red_unpass, verify_failed and limit_waits are all 0). The "given up" block after two E2-02 attempts was correct. The driver then stopped the whole run, although E2-03…06 and E3-02…05 were runnable.
- **Wasted work:** the second E2-02 session (13 min) was a near-repeat of the first, with the same denial and the same question. Nothing in the driver changed between the two attempts.
- **Merge:** "main conflicts with harness/…; carrying on without it". E1 is held because its tag contains other milestones' work, so even the verified milestone did not reach a PR.
- **Verify:** the single verify session for E1 (cost $0.40) re-ran the suite fresh (189/189) and wrote a table with one row per feature and step. That is real re-running. I did not compare rows against the step count.

## Proposed harness changes
1. **Keep running independent features when one is given up** (`lib/features.mjs` `next`, `lib/driver.sh`). Skip the blocked feature and run those that don't need it. Make the default order dependency in the feature list explicit and validated at init. Evidence: 17 features stalled behind E2-02, and 4 of them (E2-03…06) were declared independent. Earlier retros asked for this: `voice-concierge-2026-10-20` proposal 2 (don't let one parked feature idle the run) and `voice-concierge-2026-10-21`.
2. **Don't retry a session that stopped on a permission question with nothing changed** (`lib/driver.sh`). If the first attempt ends with an INBOX question about a denied read, park the feature right away. Evidence: E2-02 attempt 2 repeated attempt 1 (13 min, about $2). I found no earlier retro proposing this.
3. **Check at init that the source paths a feature's steps name are readable** (init prompt plus a `feature_list.json` check). Evidence: E2-02 needed `~/projects/*/.harness/runs`, which the session could not read. This is close to the earlier "lint step text" proposal (`voice-concierge-2026-10-21`, `rane-one-mixxx-2026-10-19`, `portfolio_site-2026-10-20`).
