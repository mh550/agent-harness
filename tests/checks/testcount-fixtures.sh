#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- test counts, pure (R1): one fixture per runner (tests/fixtures/check-*.txt, line 1 says where its text came from) ----
tc() { node "$HERE/../lib/testcount.mjs" "$HERE/fixtures/check-$1.txt"; }

# ---- the test-count contract (M5): a HARNESS_TESTS=<n> line wins, then the runners' parsers, then the generic rule ----
tcs() { node "$HERE/../lib/testcount.mjs" "$1" --source; }
check "testCount: a HARNESS_TESTS= line wins over the jest summary (1115, not 7), source contract" \
  '[[ $(tc jest-contract) == "1115 tests" && $(tcs "$HERE/fixtures/check-jest-contract.txt") == "1115 tests · contract" ]] && grep -q "^Tests: .*7 passed" "$HERE/fixtures/check-jest-contract.txt"'
check "testCount: this repo's own check.out (last 30 lines) gives its N/M checks passed by the generic rule (395)" \
  '[[ $(tcs "$HERE/fixtures/check-agent-harness.txt") == "395 tests · generic" ]] && [[ $(tail -1 "$HERE/fixtures/check-agent-harness.txt") == "395/395 checks passed" ]]'
# each runner's count with its rule (the count alone, per fixture, was five checks of its own until the trim,
# decisions/2026-11-03-trim). jest: the Tests: count (7), not Test Suites: (2); cargo: the sum of its two result lines
check "testcount --source names the rule: jest, generic (pytest), node, cargo, go; an empty file gives none" \
  'grep -q "^Test Suites: 2 passed, 2 total" "$HERE/fixtures/check-jest.txt" && [[ $(grep -c "^test result: ok" "$HERE/fixtures/check-cargo.txt") == 2 ]] \
  && [[ $(tcs "$HERE/fixtures/check-jest.txt") == "7 tests · jest" && $(tcs "$HERE/fixtures/check-pytest.txt") == "4 tests · generic" ]] \
  && [[ $(tcs "$HERE/fixtures/check-node-test.txt") == "3 tests · node" && $(tcs "$HERE/fixtures/check-cargo.txt") == "3 tests · cargo" && $(tcs "$HERE/fixtures/check-go.txt") == "3 tests · go" ]] \
  && : > "$T/empty.out" && [[ $(tcs "$T/empty.out") == "? tests · none" && -z $(node "$HERE/../lib/testcount.mjs" "$T/empty.out") ]]'

suite_end
