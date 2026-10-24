## Outcome
Not delivered. The run ended at 22:51–23:27 with 0 of 32 features passing, after 3 sessions, $10.68 and 0.59 h. The run ended with "blocked on B1-01". B1-01's own work was built and its local check passed (`tests/checks/compose.sh`: 19 PASS). But steps 2, 3 and 7 need `docker compose -f deploy/compose.yml config`, and `.claude/settings.json` denies `Bash(docker compose:*)`. The remaining 31 features were never attempted, because the driver treated all of them as waiting on B1-01.

## Non-passing features by cause
- **B1-01, "not done"** (2 sessions, 14 min, $3.82): spec or feature-list problem, with permission denial as a secondary cause. `CLAUDE.md` and the B1 plan say `docker compose … config -q` is "the one allowed compose use", but the settings file blanket-denies `docker compose`. The final entry reads: "Steps 2, 3 and 7 need `docker compose -f deploy/compose.yml config`, which `.claude/settings.json` still blocks. I didn't work around that block."
- B1-02, B1-03, B1-04 and B2-01 through B6-*: 31 features, cause "blocked", all depending on a failed feature. Each is listed in `summary.json` as "waits on B1-01, which was given up".

## Harness behaviour
- **Guards:** none fired (repairs, red_unpass, verify_failed and escalations are all 0). Giving up on B1-01 after a second session was reasonable, since the session correctly refused to work around a deny.
- **Wasted time and money:**
  - Init cost $6.86 (Fable) and the plan session cost $3.82. The plan session wrote the B1 plan and then could not get the feature checked.
  - The second B1-01 session lasted 1 min and was a no-op re-verify.
  - The driver stopped the whole run because of one feature. Many later features, such as B2 and the other milestones, probably do not need compose. Nothing in the feature list says whether they truly depend on it.
  - The INBOX Q1 was written after the run ended (19:40 vs the log's 19:27).
- **Verify:** no verify session ran, so there is no evidence on whether verify re-ran steps.

## Proposed harness changes
1. **Park a blocked feature and continue with features that don't depend on it** (driver next-feature selection). Evidence: all 31 later features were unattempted, though B2 onward is mostly independent of a compose check. Proposed before by `threads-2026-10-17` and by the run that stopped at 18:34, so this is a repeat, probably the third time.
2. **Check the feature list's verification commands against `.claude/settings.json` at init** (init prompt, or an init script step). Evidence: B1-01's steps need a command the deny list blocks, which was knowable before any session started. The init session wrote this rule into its own plan notes and then still produced the impossible steps. I found no earlier retro proposing this.
3. **Write the INBOX question when the feature is given up** (driver). Evidence: the block was logged at 19:27 but Q1 only appeared at 19:40. I found no earlier proposal for this.
