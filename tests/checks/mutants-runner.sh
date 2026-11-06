#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the mutation sample's runner (slim suite S1-02): tests/tools/mutants.sh on a throwaway repo ----
# A repo of its own holding the runner, the picker, tests/run.sh, one lib file and one check file on it. The sample is
# two mutants in the picker's shape (tests/tools/mutants.mjs pick): one the check turns red on, one on a line nothing
# asserts on. The check file logs whether it ran under MUTANT_WRAP's command.
R=$T/mrepo; mkdir -p "$R/lib" "$R/tests/tools" "$R/tests/checks" "$R/tests/fixtures"
echo "c1: big from 2 up" > "$R/tests/fixtures/check-names.txt"   # the runner's conformance check reads it
cp "$HERE/run.sh" "$R/tests/"; cp "$HERE/tools/mutants.sh" "$HERE/tools/mutants.mjs" "$HERE/tools/coverage.mjs" "$R/tests/tools/"
printf '%s\n' '#!/usr/bin/env bash' 'big() { [[ $1 -ge 2 ]] && echo big; }' 'unused=3' > "$R/lib/a.sh"
printf '%s\n' '#!/usr/bin/env bash' '# tier: fast' 'source "$(dirname "$0")/../../lib/a.sh"; echo "wrap=${WRAPPED:-no}" >> "$(dirname "$0")/../../wrap.log"' \
  'if [[ $(big 2) == big && -z $(big 1) ]]; then echo "PASS c1: big from 2 up"; else echo "FAIL c1: big from 2 up"; exit 1; fi' > "$R/tests/checks/c1.sh"
git -C "$R" init -q -b main && git -C "$R" add -A && git -C "$R" commit -qm init
A0=$(cat "$R/lib/a.sh")
{ jq -cn --arg b 'big() { [[ $1 -ge 2 ]] && echo big; }' --arg a 'big() { [[ $1 -gt 2 ]] && echo big; }' \
    '{id: "compare-01", file: "lib/a.sh", line: 2, kind: "compare", before: $b, after: $a, files: ["c1"], partial: false}'
  jq -cn '{id: "literal-01", file: "lib/a.sh", line: 3, kind: "literal", before: "unused=3", after: "unused=4", files: ["c1"], partial: false}'
  jq -cn '{id: "delete-01", file: "lib/a.sh", line: 3, kind: "delete", before: "unused=3", after: null, files: ["c1"], partial: false}'; } > "$T/sample.jsonl"

MUTANT_WRAP="env WRAPPED=yes" bash "$R/tests/tools/mutants.sh" "$T/sample.jsonl" "$T/mout" compare-01 literal-01 > "$T/m1.out" 2>&1; m1_rc=$?
check "mutants runner: a mutant a check turns red on is caught and one nothing asserts on survives, each a line with its place, kind, files and seconds" \
  '[[ $m1_rc == 0 && $(wc -l < "$T/mout/results.txt") == 2 ]] && grep -qE "^compare-01 caught lib/a\.sh:2 compare · 1 files · [0-9]+ s$" "$T/mout/results.txt" \
   && grep -qE "^literal-01 survived lib/a\.sh:3 literal · 1 files · [0-9]+ s$" "$T/mout/results.txt" && cmp -s "$T/m1.out" "$T/mout/results.txt"'
check "mutants runner: each mutant's suite output is kept: the caught one's holds the red check, the survivor's is all green" \
  'grep -qx "FAIL c1: big from 2 up" "$T/mout/compare-01.out" && grep -qx "2/2 checks passed" "$T/mout/literal-01.out" && ! grep -q "^FAIL " "$T/mout/literal-01.out"'
check "mutants runner: the tree is as it was after the sample: no mutant stays" \
  'git -C "$R" diff --quiet && [[ $(cat "$R/lib/a.sh") == "$A0" ]]'
check "mutants runner: MUTANT_WRAP's command is what the suite runs under" \
  '[[ $(grep -cx "wrap=yes" "$R/wrap.log") == 2 ]] && ! grep -qx "wrap=no" "$R/wrap.log"'

bash "$R/tests/tools/mutants.sh" "$T/sample.jsonl" "$T/mout" > "$T/m2.out" 2>&1; m2_rc=$?
check "mutants runner: a mutant already in results.txt is not run again; with no id the rest of the sample runs" \
  '[[ $m2_rc == 0 && $(wc -l < "$T/mout/results.txt") == 3 ]] && grep -qE "^delete-01 survived lib/a\.sh:3 delete · 1 files · [0-9]+ s$" "$T/m2.out" && [[ $(wc -l < "$T/m2.out") == 1 && $(wc -l < "$R/wrap.log") == 3 ]]'

echo "# an edit nobody committed" >> "$R/lib/a.sh"
bash "$R/tests/tools/mutants.sh" "$T/sample.jsonl" "$T/mout2" > "$T/m3.out" 2>&1; m3_rc=$?
check "mutants runner: a tree that is not clean stops it before anything runs, exit 1" \
  '[[ $m3_rc == 1 && ! -e $T/mout2/results.txt && $(wc -l < "$R/wrap.log") == 3 ]] && grep -qx "mutants: the tree is not clean before compare-01; stopped" "$T/m3.out"'
git -C "$R" checkout -q -- lib/a.sh

# stopped while a mutant is in the tree (a session's timeout, Ctrl-C): the mutant goes before the runner does
printf '%s\n' '#!/usr/bin/env bash' '# tier: fast' ': > "$(dirname "$0")/../../started"; sleep 60   # sleep-ok: held until the runner is stopped' > "$R/tests/checks/c1.sh"
git -C "$R" commit -qam "a check file that holds"
bash "$R/tests/tools/mutants.sh" "$T/sample.jsonl" "$T/mout3" literal-01 > "$T/m4.out" 2>&1 & mp=$!
wait_for 30 test -e "$R/started"; held=$(grep -c "unused=4" "$R/lib/a.sh"); kill -TERM "$mp"; wait "$mp"; m4_rc=$?
check "mutants runner: stopped while a mutant is in the tree, it puts the tree back before it goes" \
  '[[ $held == 1 && $m4_rc != 0 ]] && git -C "$R" diff --quiet && [[ $(cat "$R/lib/a.sh") == "$A0" ]] && ! grep -q "^literal-01 " "$T/mout3/results.txt" 2> /dev/null'
pkill -f "$R/tests/checks/c1.sh" 2> /dev/null
suite_end
