## Outcome
The run delivered everything. All 7 features passed on the first attempt (`first_attempt_pass_rate` 1, `verify_fail_rate` 0) and were verified and merged. Milestone V1 merged as PR #178 and V2 as PR #180. It cost $34.38 ($4.91 per passing feature) over 3.6 h wall time. Guards: 0 repairs, 0 un-passes, 0 limit waits. V2 went over its check budget (28 added against 25), and the driver recorded the reason: the specs name each refusal and each stub-gh behaviour as its own check.

checks: +43 ~3 −0 (V1 +15 ~1 −0, budget 15; V2 +28 ~2 −0, budget 25, over)

## Non-passing features by cause
None. Every feature passed, so there are no causes to assign.

## Harness behaviour
- **Guards:** only the two milestone merges fired, and both were correct. The log shows "merged main into harness-lane/…/V2" at 23:36, which is the driver's own merge before verify, not a session merging main into its branch.
- **Suite runs:** `suite_runs` shows 0 full and 10 fast across 7 coding sessions, 1.4 fast per session. V2-01 (267 s) and V2-03 (275 s) each ran the suite twice, against the prompt's one-run-last rule. Neither cost much, but it recurs.
- **Review:** the log line "review V2-04: 1020 changed lines, at or over 0; opus" shows a threshold of 0, which looks like a threshold or logging oddity. Review cost $8.34, 24% of the run.
- **Questions for Michael:** V2-01, V2-03 and V2-04 each recorded a "Default taken: … Keep that?" question on a feature that passed. These are informational, not blockers, but they land in "harness needs".
- **Fact length:** V2-03 logged "a project fact is 170 characters, over 160". That is a minor lint hit.
- **Verify evidence:** verify sessions did record evidence rows, 19 for V1 and 24 for V2. V1's steps total 7+7+5 = 19, so the rows match one per step. V2's steps total 8+6+5+5 = 24, which also matches. Verify therefore re-ran every step.

## Proposed harness changes
1. `verify-question-noise` (proposed, seen 1, now 2): classify recorded questions as info or blocking in the entry schema and `lib/record.sh`, so "default taken" notes don't become needs cards. Evidence: V2-01, V2-03 and V2-04 each recorded one.
2. `suite-time-budget` (proposed, seen 11): have `check.sh` warn or cap a session's repeated suite runs. Evidence: V2-01 and V2-03 each ran it twice, at about 270 s.

I wrote these two to `retro-proposals.json`.
