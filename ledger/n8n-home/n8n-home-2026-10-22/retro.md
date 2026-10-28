## Outcome
Delivered: 34/34 features passed, verified and merged (6 milestone PRs, #6–#11 range). The cost was $169.24 over 11.8 h and 51 sessions, about $4.98 per feature. The first attempt (22 Oct) ended after 0.6 h, blocked on B1-01 (0/32). Michael's answer let a continuation finish B1 on 27 Oct, and a second wait for B1-05 followed. Opus did 95% of the spend: build $88.8, review $43.4, plan $23.0, verify only $2.05.

## Non-passing features by cause
No feature ended non-passing. Rework: B1-01, B1-05, B4-08, B6-01 and B6-05 (first-attempt pass rate 0.85).
- B1-01 (22 Oct): environment/permission. Its last pre-continuation entry says docker compose was not yet allowed. The 27 Oct re-run passed in 2 min with "With docker compose config now allowed, re-checked steps 2, 3, 7".
- B1-05: environment. "bind source ~/.local/state/harness/requests is missing… sessions may not write there". It was parked for Michael for about 9 h.
- B4-08 and B6-01: model quality. Both failed the verify re-check. B6-01's evidence of the miss: the first build wrote the error-handler without checking the private-ntfy fallback (group `errors-private` was added on the second pass).
- B6-05: model quality, one self-failed attempt followed by a pass 8 min later.

## Harness behaviour
- Guards: verify_failed 2 (B4-08, B6-01) were correct catches, each fixed in one more attempt. There were 0 repairs, 0 red_unpass, 0 limit waits and 0 escalations.
- One cosmetic event: B6-02's entry.json was rejected for a 425-character summary (limit 400), so the harness recorded a minimal entry. The session lost its real summary for no gain.
- The first block ("remaining features wait on B1-01") burned $10.68 including $6.86 on init. The feature list (32 features) was planned before the policy change, so it was later rewritten to 34.
- Verify sessions were cheap: 8 sessions at $2.06 total, 0.35 h. The suite is cleared and run in full at every milestone. That is real re-running, but I did not count evidence rows against steps.
- Orientation was 1.39M tokens over 19 turns, which is small. Cache hit rate was 96.6%, context peak 253k.
- Driver overhead was 0.08 h.

## Proposed harness changes
1. **Preflight checks for the brief.** Before the init plan, check the brief against project CLAUDE.md and settings. Compare the permissions and policy the run needs (docker compose, request-inbox write, MERGE_POLICY) with what the settings allow, and park questions before any session starts. Evidence: the brief still said "no deploy, no docker compose, MERGE_POLICY pr" while CLAUDE.md said live-staged. B1-01 was blocked on this, and B1-05 waited about 9 h on a missing directory that a preflight could have flagged. I did not check whether earlier retros proposed it.
2. **Entry validation.** Where entry.json fails validation (`summary` over 400 characters), return the error to the session so it can fix the entry, instead of recording a minimal one. Evidence: B6-02. Not seen in earlier retros as far as I checked.
3. **Verify gate.** On verify's first run, check the steps most likely to be missed (alternate configs such as private-ntfy) or add them to the build prompt. Evidence: B4-08 and B6-01 both needed a second build pass, costing roughly $6–10. Weak evidence, since the gate caught both.
