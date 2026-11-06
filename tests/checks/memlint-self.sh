#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- memlint on this checkout (M4): the repo's own memory files lint clean ----
# The one memlint check that reads the checkout it runs from, so the one a CLAUDE.md edit can turn red (a sixteenth
# Gotchas line did, twice, outside the feature that added it): it stays in the fast tier and in CHECK_KEY_MAP
# (key-map-lint). The module's cases are tests/unit/memlint.test.mjs, the driver's notes tests/checks/memlint-run.sh
# (decisions/2026-11-05-suite-shape).
M="node $HERE/../lib/memlint.mjs" MM=$HERE/../lib/memlint.mjs
check "memlint: the store lookup is decisionsStore (one function), and this worktree prints nothing" '
  [[ $(grep -c "\"\.harness/config\.sh\"" "$MM") == 1 && $(grep -c "\"docs/decisions\.md\"" "$MM") == 1 ]] &&
  o=$($M "$HERE/..") && [[ -z $o ]]'
suite_end
