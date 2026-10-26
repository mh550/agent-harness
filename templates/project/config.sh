# .harness/config.sh — this project's harness settings. Everything not set here is a harness default or detected:
# the suite (.harness/check.sh, npm run check/test, pytest…), the smoke check (.harness/smoke.*), the init (.harness/init.sh).
POLICY=build-only          # build-only | live-staged (live-staged needs a "## Live system" section in CLAUDE.md)
# MERGE_POLICY=auto        # opt in to self-merge: the driver merges each verified milestone PR itself. Default pr: PRs wait for you. Only for a repo whose main has no production
# CHECK_KEY_IGNORE=".harness/runs docs/plans"   # path prefixes the suite never reads, left out of its cache key: a change there alone doesn't rerun it
