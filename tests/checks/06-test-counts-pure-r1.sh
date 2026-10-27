#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- test counts, pure (R1): one fixture per runner (tests/fixtures/check-*.txt, line 1 says where its text came from) ----
tc() { node "$HERE/../lib/testcount.mjs" "$HERE/fixtures/check-$1.txt"; }
check "testCount: node:test fixture gives 3" '[[ $(tc node-test) == "3 tests" ]]'
check "testCount: pytest fixture gives 4" '[[ $(tc pytest) == "4 tests" ]]'
check "testCount: jest fixture gives the Tests: count (7), not Test Suites:" '[[ $(tc jest) == "7 tests" ]] && grep -q "^Test Suites: 2 passed, 2 total" "$HERE/fixtures/check-jest.txt"'
check "testCount: cargo fixture gives the sum of its test result lines (3)" '[[ $(tc cargo) == "3 tests" && $(grep -c "^test result: ok" "$HERE/fixtures/check-cargo.txt") == 2 ]]'
check "testCount: go fixture gives its --- PASS count (3)" '[[ $(tc go) == "3 tests" ]]'

# ---- the test-count contract (M5): a HARNESS_TESTS=<n> line wins, then the runners' parsers, then the generic rule ----
tcs() { node "$HERE/../lib/testcount.mjs" "$1" --source; }
check "testCount: a HARNESS_TESTS= line wins over the jest summary (1115, not 7), source contract" \
  '[[ $(tc jest-contract) == "1115 tests" && $(tcs "$HERE/fixtures/check-jest-contract.txt") == "1115 tests · contract" ]] && grep -q "^Tests: .*7 passed" "$HERE/fixtures/check-jest-contract.txt"'
check "testCount: the last HARNESS_TESTS= line wins, and only a whole line counts" \
  'node --input-type=module -e "import { testCount } from \"$HERE/../lib/testcount.mjs\"; const a = testCount(\"HARNESS_TESTS=3\\n# pass 9\\nHARNESS_TESTS=5\\n\"), b = testCount(\"echo HARNESS_TESTS=8\\n# pass 2\\n\"); process.exit(a === 5 && b === 2 ? 0 : 1)"'
check "testCount: a HARNESS_TESTS= line with trailing text or a count past 2^53 is no contract, a CRLF one is" \
  'node --input-type=module -e "import { testCount } from \"$HERE/../lib/testcount.mjs\"; const a = testCount(\"HARNESS_TESTS=8 of 9\\n# pass 2\\n\"), b = testCount(\"HARNESS_TESTS=8\\r\\n\"), c = testCount(\"HARNESS_TESTS=123456789012345678901\\n# pass 2\\n\"); process.exit(a === 2 && b === 8 && c === 2 ? 0 : 1)"'
check "testCount: this repo's own check.out (last 30 lines) gives its N/M checks passed by the generic rule (395)" \
  '[[ $(tcs "$HERE/fixtures/check-agent-harness.txt") == "395 tests · generic" ]] && [[ $(tail -1 "$HERE/fixtures/check-agent-harness.txt") == "395/395 checks passed" ]]'
check "testcount --source names the rule: jest, generic (pytest), node, cargo, go; an empty file gives none" \
  '[[ $(tcs "$HERE/fixtures/check-jest.txt") == "7 tests · jest" && $(tcs "$HERE/fixtures/check-pytest.txt") == "4 tests · generic" ]] \
  && [[ $(tcs "$HERE/fixtures/check-node-test.txt") == "3 tests · node" && $(tcs "$HERE/fixtures/check-cargo.txt") == "3 tests · cargo" && $(tcs "$HERE/fixtures/check-go.txt") == "3 tests · go" ]] \
  && : > "$T/empty.out" && [[ $(tcs "$T/empty.out") == "? tests · none" && -z $(node "$HERE/../lib/testcount.mjs" "$T/empty.out") ]]'

suite_end
