# The harness working on itself. Verified milestones merge themselves (MERGE_POLICY from ~/.config/harness/config.sh,
# auto since decisions/2026-10-24-permissions-policy), so each queued run builds on the last.
CHECK_CMD="bash tests/run.sh"
# paths the suite never reads stay out of its cache key, so a plan, spec, decision or ledger change doesn't rerun it
CHECK_KEY_IGNORE=".harness/runs docs/plans docs/specs journal findings-and-research ledger"
