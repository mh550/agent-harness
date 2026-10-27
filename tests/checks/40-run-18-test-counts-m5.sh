#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 18: test counts (M5): the log says once per run which source the count came from (contract, a runner, none) ----
# contract: two segments (the first ends at its deadline after the initializer, the second runs to the end), one note
mkdir -p "$HARNESS_STATE/proj/contract" && echo "CHECK_CMD='echo \"# pass 9\"; echo HARNESS_TESTS=12'" > "$HARNESS_STATE/proj/contract/run.env"
"$H" start "$T/proj" contract --spec SPEC.md --until-epoch $(( $(date +%s) - 1 )) --foreground > "$T/contract.out" 2>&1
"$H" continue contract --foreground > "$T/contract2.out" 2>&1
mkdir -p "$HARNESS_STATE/proj/parsed" && echo "CHECK_CMD='echo \"# pass 7\"'" > "$HARNESS_STATE/proj/parsed/run.env"
"$H" start "$T/proj" parsed --spec SPEC.md --until-epoch $(( $(date +%s) - 1 )) --foreground > "$T/parsed.out" 2>&1
sumj() { echo "$T/wt/proj/$1/.harness/runs/$1/summary.json"; }
check "test count: a suite printing HARNESS_TESTS=12 is noted once per run as the contract, and summary.json tests.start is 12" \
  '[[ $(hlog contract | grep -c "test count: ") == 1 ]] && hlog contract | grep -qx -- "- .* · test count: HARNESS_TESTS contract" \
  && [[ $(hlog contract | grep -c "run ended") == 2 && $(jq -r .tests.start "$(sumj contract)") == 12 && $(cat "$HARNESS_STATE/proj/contract/testcount-source") == contract ]]'
check "test count: a suite printing only a node:test summary is noted as parsed (node)" \
  '[[ $(hlog parsed | grep -c "test count: ") == 1 ]] && hlog parsed | grep -q "· test count: parsed (node)$" && [[ $(jq -r .tests.start "$(sumj parsed)") == 7 ]]'

suite_end
