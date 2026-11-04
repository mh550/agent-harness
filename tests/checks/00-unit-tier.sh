#!/usr/bin/env bash
# The unit tier: every tests/unit/*.test.mjs in one node process, as the suite's PASS/FAIL lines and its N/M line.
#   tests/checks/00-unit-tier.sh   → exit 1 on any FAIL line or a non-zero node exit (TEST_UNIT_DIR: another directory)
# No throwaway project (it doesn't source tests/lib.sh). A node exit that is non-zero with no FAIL line (a process.exit at
# import) prints one FAIL line of its own, so the runner's count isn't all passed (decisions/2026-11-03-unit-tier).
set -uo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd); ud=${TEST_UNIT_DIR:-$HERE/unit}
o=$(node --test --test-isolation=none --test-reporter="$HERE/unit/reporter.mjs" --test-reporter-destination=stdout "$ud"/*.test.mjs); rc=$?
[[ -n $o ]] && printf '%s\n' "$o"
pass=$(grep -c '^PASS ' <<< "$o") fail=$(grep -c '^FAIL ' <<< "$o")
(( rc && ! fail )) && { echo "FAIL unit tier: node --test exited $rc with no FAIL line"; fail=1; }
echo "$pass/$(( pass + fail )) checks passed"
(( ! rc && ! fail ))
