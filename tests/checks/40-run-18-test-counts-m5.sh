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

# a continued run (M5-02): segment 1 stops at its deadline on tests.n 3; segment 2's A commits tests.n 5 and B, the next
# session, snapshots status, report and the state's markers: tests-end is refreshed after each session, not only at finish.
# C's first session leaves the suite red on tests.n 9 (it still prints its count): a red tree's count is never tests-end.
# (The contract run's suite ignores BROKEN, so its C merged one into main: gone first.)
git pull -q --ff-only origin main && git rm -q --ignore-unmatch BROKEN && echo 3 > tests.n && git add tests.n && git commit -qm "tests.n 3" && git push -q origin main
mkdir -p "$HARNESS_STATE/proj/cont" && echo "CHECK_CMD='echo HARNESS_TESTS=\$(cat tests.n); test ! -f BROKEN'" > "$HARNESS_STATE/proj/cont/run.env"
"$H" start "$T/proj" cont --spec SPEC.md --until-epoch $(( $(date +%s) - 1 )) --foreground > "$T/cont.out" 2>&1
cont_end1=$(cat "$HARNESS_STATE/proj/cont/tests-end" 2> /dev/null)
STUB_NO_TAMPER=1 STUB_TESTS_N=A:5,C:9 STUB_SNAPSHOT=B "$H" continue cont --foreground > "$T/cont2.out" 2>&1
S=$T/snap-cont
check "test count: a continued run refreshes tests-end after each session (summary.json 3 → 5 before finish), tests-start stays the baseline" \
  '[[ $cont_end1 == 3 && $(jq -r .tests.start "$S/summary.json") == 3 && $(jq -r .tests.end "$S/summary.json") == 5 && $(cat "$S/tests-start") == 3 ]] \
  && grep -q "^cont (proj) · running · .* · tests 3 → 5$" "$S/status.txt" && grep -qF "| Tests | 3 → 5 (baseline at run start → end) |" "$S/report.md" \
  && hlog cont | grep -q "· A · .* · passes=true · .* passing · tests 5$" && hlog cont | grep -q "· C · .* · passes=false · .* passing · tests 5$" \
  && hlog cont | grep -q "· C · .* · passes=true · .* passing · tests 9$" && [[ $(cat "$HARNESS_STATE/proj/cont/tests-start") == 3 && $(jq -r .tests.end "$(sumj cont)") == 9 ]]'
check "test count: report.md labels the tests cell, trends its column (baseline → end)" \
  'jq -nc "{run: \"r\", project: \"p\", passing: 0, total: 1, merged: 0, cost: 0, per_passing: null, wall_h: 0, end_reason: \"x\", causes: {}, tests_start: 3, tests_end: 5}" > "$T/tr.jsonl" \
  && node "$HERE/../lib/summary.mjs" trends "$T/tr.jsonl" | head -1 | grep -qF "| Passing | tests (baseline → end) | \$ |" \
  && node "$HERE/../lib/summary.mjs" trends "$T/tr.jsonl" | grep -qF "| 0/1 (merged 0) | 3 → 5 |" \
  && jq ".tests = {start: null, end: null}" "$(sumj cont)" > "$T/nt.json" && node "$HERE/../lib/summary.mjs" report "$T/nt.json" | grep -qxF "| Tests | not recorded |"'

suite_end
