# The clock line and bounded init output: the last 40 lines and the full log's path, one line of time, budget and attempt (the spec's D-H38)

*(2026-10-21, E3-02 of run agent-harness-2026-10-21-measure; plan `docs/plans/2026-10-21-E3-prompts.md` §6, §11; the
clock line, E3-04, is the other half of D-H38)*

- **Finding:** `{{INIT_OUTPUT}}` was `tail -c 4000` of `$SCRATCH/init.out`: cut mid-line, with no way for the session
  to find the rest.
- **Choice:** the last 40 whole lines of `init.out`, then `full output: <path>` (in the session's own scratch
  directory, so it can `cat` or `grep` it). `init.out` ends with `(init exit N)` and `check.sh`'s summary, and a red
  suite prints its own last 25 lines and the path of `check.out`, so the 40 lines hold what the session needs first.
- **Rejected:** pasting the whole of `init.out` (unbounded); a per-line `cut -c` (GNU `cut` counts bytes and splits
  UTF-8; the spec's rule is lines).

## The clock line (E3-04, the other half)

*(2026-10-22, E3-04 of run agent-harness-2026-10-21-measure; plan `docs/plans/2026-10-21-E3-prompts.md` §7)*

- **Finding:** a session couldn't tell the time, how long the run has left, its own budget and turn cap, or that it
  is on its last attempt ("Claude can't tell time", per Carlini), so it couldn't pace itself or decide to commit a
  green half instead of starting something it can't finish.
- **Choice:** one line in the *This session* part of coding.md and verify.md, after the id lines, from the driver's
  `clock`: `Clock: 2026-10-21 22:05 · run 3h10m of 8h, ends 03:55 · this session: $20 budget, 250 turns, 100m
  timeout · attempt 2 of 2` (verify: `verify round 2 of 2`, the same round for the escalated re-run). The run is
  this driver's segment: `T0` is its start and the total is `DEADLINE - T0` (`8h`, or `6h40m` after a `DEADLINE_AT`
  cut), because that deadline is the one that ends the session's run; a `harness continue` starts a new segment. The
  attempt is the count after `F bump`, so a verifier's re-queue reads `attempt 2 of 2`. The initializer and retro get
  none. `lib/prompt.sh` run as a command (the eval probe) has no driver: its line reads `outside a run`, not blank.
- **Rejected:** a clock in the static part (it would break the shared prefix); a per-turn clock (`-p` has no hook
  for it); the whole run's elapsed time across `continue`s (the segment's deadline is what binds); a `harness-log.md`
  note per session (the line is kept in each `logs/*.prompt.md`; a note would repeat `session n · <id>` noise).
