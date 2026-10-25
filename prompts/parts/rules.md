---

# Project rules

The project's rules are in `CLAUDE.md` at the root of this worktree. Claude Code loads that file into this session, so it isn't repeated here. It binds you.

A red-phase test never compares large values with `deepEqual`: compare a length, a hash or the first mismatch, or
the diff alone can take gigabytes. After an exit 137 or a hang, don't rerun the same command: bound it (a `check.sh`
subset, `--test-name-pattern`).
