# .harness/config.sh — this project's harness settings. Everything not set here is a harness default or detected:
# the suite (.harness/check.sh, npm run check/test, pytest…), the smoke check (.harness/smoke.*), the init (.harness/init.sh).
POLICY=build-only          # build-only | live-staged (live-staged needs a "## Live system" section in CLAUDE.md)
# MERGE_POLICY=auto        # opt in to self-merge: the driver merges each verified milestone PR itself. Default pr: PRs wait for you. Only for a repo whose main has no production
# DECISIONS=docs/decisions.md   # the decisions store: a file (numbered D<n> entries) or a directory (one file per decision, never numbered). Default docs/decisions.md if it exists
# CHECK_KEY_IGNORE=".harness/runs docs/plans"   # path prefixes the suite never reads, left out of its cache key: a change there alone doesn't rerun it
# CHECK_FAST_CMD="<suite> --tier fast"   # the fast tier, what a feature's `passes` stands on (check.sh --fast); verify and merge still run the whole suite; empty: the whole suite is the fast tier
# CHECK_NAMES=tests/fixtures/check-names.txt   # the suite's check names, one per line, C-sorted: a verified milestone's diff of it is its `<m>: checks +a ~b −c` note, against the feature list's check_budget when one is set (a note, never a gate); absent: the suite's count instead
# CHECK_KEY_MAP="CLAUDE.md:<check>"   # a file only check-file lines read, and every check that reads it: a change to it alone runs just those; a reader left out lets a stale green through, so the suite needs a lint proving the list (as key-map-lint)
