#!/usr/bin/env bash
# tier: fast
# The unit tier: every tests/unit/*.test.mjs in one node process, as the suite's PASS/FAIL lines and its N/M line.
#   tests/checks/00-unit-tier.sh   → exit 1 on any FAIL line or a non-zero node exit (TEST_UNIT_DIR: another directory)
# No throwaway project (it doesn't source tests/lib.sh). What would be red with no FAIL line of node's prints one of its
# own, so the runner's count isn't all passed: a non-zero exit (a process.exit at import), no test file, no run summary
# from the reporter (a process.exit(0)), PASS/FAIL lines that aren't the summary's count (decisions/2026-11-03-unit-tier).
set -uo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd); ud=${TEST_UNIT_DIR:-$HERE/unit}
[[ -z ${TEST_XTRACE_DIR:-} ]] || export NODE_V8_COVERAGE=$TEST_XTRACE_DIR/00-unit-tier/v8   # the coverage measurement (tests/lib.sh, which this file doesn't source)
shopt -s nullglob; files=("$ud"/*.test.mjs); shopt -u nullglob
(( ${#files[@]} )) || { echo "FAIL unit tier: no *.test.mjs in $ud"; echo "0/1 checks passed"; exit 1; }
o=$(node --test --test-isolation=none --test-reporter="$HERE/unit/reporter.mjs" --test-reporter-destination=stdout "${files[@]}"); rc=$?
n=$(sed -n 's/^# unit tier: \([0-9][0-9]*\) tests$/\1/p' <<< "$o" | tail -1); o=$(grep -v '^# unit tier: [0-9]* tests$' <<< "$o")
[[ -n $o ]] && printf '%s\n' "$o"
pass=$(grep -c '^PASS ' <<< "$o") fail=$(grep -c '^FAIL ' <<< "$o")
if (( rc && ! fail )); then echo "FAIL unit tier: node --test exited $rc with no FAIL line"; fail=$(( fail + 1 ))
elif [[ -z $n ]]; then echo "FAIL unit tier: node --test ended without its summary (a process.exit?)"; fail=$(( fail + 1 ))
elif (( pass + fail != n )); then echo "FAIL unit tier: $(( pass + fail )) PASS/FAIL lines for $n tests (a test wrote to stdout?)"; fail=$(( fail + 1 ))
fi
echo "$pass/$(( pass + fail )) checks passed"
(( ! rc && ! fail ))
