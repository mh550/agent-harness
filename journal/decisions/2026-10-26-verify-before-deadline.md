# Verify before the deadline: one session per complete milestone, then finish

*(2026-10-26, run agent-harness-2026-10-26-2, feature F2-05; spec `docs/specs/2026-10-21-retro-fixes.md` R5, plan
`docs/plans/2026-10-26-F2-initializer-verify.md` § R5)*

- **Finding:** voice-concierge-2026-10-20 ended on its deadline twice with a milestone whose features all passed but
  that was never verified: the loop checks the deadline at its top, before `verify_ready`, so the last feature's
  session ran out the clock and `finish "deadline"` left finished work unmerged until Michael continued the run.
- **Choice:**
  - Both deadline branches of the driver's loop (`deadline reached`, `deadline reached while paused`) run
    `verify_ready once` before `finish`. For each complete milestone not `verified-<m>` or `needs-<m>`, the note
    `deadline reached: <m> complete but unverified; one verify before the end`, then `verify <m> once`.
  - `once` is one session, bounded by `SESSION_TIMEOUT` like every session: no re-run on `VERIFY_ESCALATE_MODEL`
    (thin evidence is `… after one verify at the deadline; not verified (needs Michael)`), and this round is the
    last (`round <r> of <r>`), so a failed step is `needs Michael`, never an attempt granted that no session would
    use. A verify that holds merges through `merge_milestones` as always. A refused verify is deferred as always;
    the deadline doesn't wait for the window, it finishes.
  - **D3 *default***: the paused branch verifies too. A pause stops new feature work; this one session only makes
    work already done mergeable.
- **Rejected:**
  - `MAX_VERIFY_ROUNDS` at the deadline: a failed round grants an attempt and a second verify, each a full session
    plus escalation, so `--until` would overrun by an unbounded number of sessions; the queue's next run waits on it.
  - Extending the deadline until the milestone is verified: the same overrun, without a bound at all.
  - Verifying at the session cap as well: the cap queues a continuation that verifies first thing, so nothing is
    left unmerged for long; the deadline queues none.
