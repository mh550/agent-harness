# Bounded init output: the last 40 lines and the full log's path (the spec's D-H38, init-output half)

*(2026-10-21, E3-02 of run agent-harness-2026-10-21-measure; plan `docs/plans/2026-10-21-E3-prompts.md` §6, §11; the
clock line, E3-04, is the other half of D-H38)*

- **Finding:** `{{INIT_OUTPUT}}` was `tail -c 4000` of `$SCRATCH/init.out`: cut mid-line, with no way for the session
  to find the rest.
- **Choice:** the last 40 whole lines of `init.out`, then `full output: <path>` (in the session's own scratch
  directory, so it can `cat` or `grep` it). `init.out` ends with `(init exit N)` and `check.sh`'s summary, and a red
  suite prints its own last 25 lines and the path of `check.out`, so the 40 lines hold what the session needs first.
- **Rejected:** pasting the whole of `init.out` (unbounded); a per-line `cut -c` (GNU `cut` counts bytes and splits
  UTF-8; the spec's rule is lines).
