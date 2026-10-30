# The harness working on itself. Verified milestones merge themselves (MERGE_POLICY from ~/.config/harness/config.sh,
# auto since decisions/2026-10-24-permissions-policy), so each queued run builds on the last.
CHECK_CMD="bash tests/run.sh"
# paths the suite never reads stay out of its cache key, so a plan, spec, decision or ledger change doesn't rerun it
CHECK_KEY_IGNORE=".harness/runs docs/plans docs/specs journal findings-and-research ledger"
# CLAUDE.md is read by these checks alone, so a session that only adds a Gotchas line runs just them
# (decisions/2026-10-30-partial-key; tests/checks/82-key-map-lint proves the list)
CHECK_KEY_MAP="CLAUDE.md:39-memlint-m4:37-memory-prompts-m2:79-suite-length"
# the decisions store: one file per decision, never numbered (decisions/2026-10-21-one-file-per-decision)
DECISIONS=journal/decisions
# the suite takes 601 s alone and 857 s with a second lane's beside it (2026-10-29): 15m left 43 s
# (decisions/2026-10-29-check-timeout-25m)
CHECK_TIMEOUT=25m
