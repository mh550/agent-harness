#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- test counts, pure (R1): one fixture per runner (tests/fixtures/check-*.txt, line 1 says where its text came from) ----
tc() { node "$HERE/../lib/testcount.mjs" "$HERE/fixtures/check-$1.txt"; }
check "testCount: node:test fixture gives 3" '[[ $(tc node-test) == "3 tests" ]]'
check "testCount: pytest fixture gives 4" '[[ $(tc pytest) == "4 tests" ]]'
check "testCount: jest fixture gives the Tests: count (7), not Test Suites:" '[[ $(tc jest) == "7 tests" ]] && grep -q "^Test Suites: 2 passed, 2 total" "$HERE/fixtures/check-jest.txt"'
check "testCount: cargo fixture gives the sum of its test result lines (3)" '[[ $(tc cargo) == "3 tests" && $(grep -c "^test result: ok" "$HERE/fixtures/check-cargo.txt") == 2 ]]'
check "testCount: go fixture gives its --- PASS count (3)" '[[ $(tc go) == "3 tests" ]]'

suite_end
