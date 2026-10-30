#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the rerun guard (N1): check.sh's full form reruns a red once; a flake is green and counted, a real red stays red ----
# One stub suite (HARNESS_CHECK_CMD) in one throwaway repo, so treekey gives a key. Each case has its own directory
# $T/rr-<case>: the call counter n, every call's arguments (args, one line per call), each call's output (out<n>), and
# its own scratch and cache, so markers never cross cases. RR_MODE: once (red on call 1, HARNESS_FAILED=a b), always
# (red every call, HARNESS_FAILED=a), noline (red on call 1, no line), hang (past its timeout), oom (the scope stub's cap kill).
git init -q "$T/rr" && ( cd "$T/rr" && echo a > a && git add a && git -c user.name=t -c user.email=t@t commit -qm a )
cat > "$T/rr-suite.sh" <<'EOF'
n=$(( $(cat "$RR/n" 2> /dev/null || echo 0) + 1 )); echo "$n" > "$RR/n"; echo "$*" >> "$RR/args"; o=$RR/out$n
green() { if (( $# )); then for a; do echo "PASS $a"; done; echo "$#/$# checks passed"; else echo "5/5 checks passed"; fi > "$o"; cat "$o"; exit 0; }
case $RR_MODE in
  once) (( n == 1 )) || green "$@"; printf '%s\n' "FAIL a" "FAIL b" "HARNESS_FAILED=a b" "3/5 checks passed" > "$o" ;;
  always) printf '%s\n' "FAIL a" "HARNESS_FAILED=a" "4/5 checks passed" > "$o" ;;
  noline) (( n == 1 )) || green "$@"; printf '%s\n' "FAIL x" "4/5 checks passed" > "$o" ;;
  hang) sleep 5 ;;   # sleep-ok: a suite that outlives its timeout
  oom) touch "$STUB_DIR/scope/$STUB_SCOPE_UNIT.oom"; exit 137 ;;
esac
cat "$o"; exit 1
EOF
rr() { local c=$1 m=$2; shift 2; mkdir -p "$T/rr-$c"
  ( cd "$T/rr" && RR=$T/rr-$c RR_MODE=$m HARNESS_SCRATCH=$T/rr-$c/s HARNESS_CHECK_CACHE=$T/rr-$c/c HARNESS_CHECK_CMD="bash $T/rr-suite.sh" "$HERE/../lib/check.sh" "$@" ); }
calls() { cat "$T/rr-$1/n"; }
args() { sed -n "$2p" "$T/rr-$1/args"; }
sd_count() { awk -v k="$1" 'BEGIN { RS = "===\n" } index($0, k) { n++ } END { print n + 0 }' "$T/systemd.log" 2>/dev/null; }

o_once=$(rr once once; echo "rc=$?") o_once3=$(rr once once)
check "check rerun: red once with HARNESS_FAILED=a b, then green: exit 0 and the green-after-a-rerun line with the full count" \
  '[[ $o_once == $'"'"'check: green after a rerun (flaky: a b), 5 tests\nrc=0'"'"' ]]'
check "check rerun: the rerun gets exactly the named files as arguments" '[[ -z $(args once 1) && $(args once 2) == "a b" ]]'
check "check rerun: check.out is the first run byte for byte; check-rerun.out holds the rerun" \
  'cmp -s "$T/rr-once/s/check.out" "$T/rr-once/out1" && cmp -s "$T/rr-once/s/check-rerun.out" "$T/rr-once/out2" && grep -qx "2/2 checks passed" "$T/rr-once/s/check-rerun.out"'
check "check rerun: the green marker holds the first run's total, and the next call is cached with it" \
  '[[ $(ls "$T/rr-once/c"/green-* | wc -l) == 1 && $(sed -n 1p "$T/rr-once/c"/green-*) == "5 tests" ]] \
  && [[ $o_once3 == "check: green (cached for this code tree, 5 tests)" && $(calls once) == 2 ]]'
check "check rerun: a rerun-green appends one flakes.jsonl row with at, key, names, rerun, first, load and lane" \
  '[[ $(grep -c "" "$T/rr-once/c/flakes.jsonl") == 1 ]] && key=$(basename "$T/rr-once/c"/green-*) && jq -e --arg k "${key#green-}" '"'"'
    .names == ["a","b"] and .rerun == "failed" and .lane == "" and .key == $k and (.first | test("^exit 1 after [0-9]+ s$"))
    and (.at | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z$")) and (.load | test("^[0-9.]+ [0-9.]+ [0-9.]+$"))
    and (keys == ["at","first","key","lane","load","names","rerun"])'"'"' "$T/rr-once/c/flakes.jsonl" > /dev/null'

o_alw=$(rr always always; echo "rc=$?")
check "check rerun: red every time exits 1 with red again on a rerun of a and the rerun's tail; no marker, no flakes row" \
  'grep -qx "check: RED (exit 1 after [0-9]* s; red again on a rerun of a) — last lines of $T/rr-always/s/check-rerun.out:" <<< "$o_alw" \
  && [[ $(tail -2 <<< "$o_alw") == $'"'"'4/5 checks passed\nrc=1'"'"' && $(calls always) == 2 && $(args always 2) == a ]] \
  && cmp -s "$T/rr-always/s/check.out" "$T/rr-always/out1" && ! ls "$T/rr-always/c"/green-* 2> /dev/null && [[ ! -e $T/rr-always/c/flakes.jsonl ]]'

o_nol=$(HARNESS_LANE=M1 rr noline noline; echo "rc=$?")
check "check rerun: auto with no HARNESS_FAILED line reruns the whole suite (flaky: whole suite)" \
  '[[ $o_nol == $'"'"'check: green after a rerun (flaky: whole suite), 5 tests\nrc=0'"'"' && $(calls noline) == 2 && -z $(args noline 2) ]] \
  && jq -e '"'"'.names == [] and .rerun == "suite" and .lane == "M1"'"'"' "$T/rr-noline/c/flakes.jsonl" > /dev/null'

o_fail=$(HARNESS_CHECK_RERUN=failed rr failed noline; echo "rc=$?") o_off=$(HARNESS_CHECK_RERUN=off rr off once; echo "rc=$?")
check "check rerun: CHECK_RERUN=failed with no line, or off, runs the suite once and is red as today" \
  'grep -qx "check: RED (exit 1 after [0-9]* s) — last lines of $T/rr-failed/s/check.out:" <<< "$o_fail" && [[ $(tail -1 <<< "$o_fail") == rc=1 && $(calls failed) == 1 ]] \
  && grep -qx "check: RED (exit 1 after [0-9]* s) — last lines of $T/rr-off/s/check.out:" <<< "$o_off" && [[ $(tail -1 <<< "$o_off") == rc=1 && $(calls off) == 1 ]] \
  && [[ ! -e $T/rr-failed/s/check-rerun.out && ! -e $T/rr-off/s/check-rerun.out ]]'

o_sui=$(HARNESS_CHECK_RERUN=suite rr suite once; echo "rc=$?")
check "check rerun: CHECK_RERUN=suite reruns the whole suite even with the line" \
  '[[ $o_sui == $'"'"'check: green after a rerun (flaky: a b), 5 tests\nrc=0'"'"' && $(calls suite) == 2 && -z $(args suite 2) ]] \
  && jq -e '"'"'.names == ["a","b"] and .rerun == "suite"'"'"' "$T/rr-suite/c/flakes.jsonl" > /dev/null'

o_to=$(HARNESS_CHECK_TIMEOUT=2s rr hang hang; echo "rc=$?")
check "check rerun: a timeout is never rerun" \
  'grep -qx "check: RED (timed out after 2s, exit 124 after [0-9]* s) — last lines of $T/rr-hang/s/check.out:" <<< "$o_to" \
  && [[ $(tail -1 <<< "$o_to") == rc=124 && $(calls hang) == 1 && ! -e $T/rr-hang/s/check-rerun.out ]]'

o_oom=$(HARNESS_SCOPE_PREFIX=harness-rr rr oom oom; echo "rc=$?")
check "check rerun: a kill at the memory cap is never rerun" \
  'grep -qx "check: RED (killed at its 3G memory cap, exit 137 after [0-9]* s) — last lines of $T/rr-oom/s/check.out:" <<< "$o_oom" \
  && [[ $(tail -1 <<< "$o_oom") == rc=137 && $(calls oom) == 1 && $(sd_count --unit=harness-rr-check-) == 1 ]]'

o_sub=$(rr sub once a; echo "rc=$?")
check "check rerun: the subset form never reruns" '[[ $(tail -1 <<< "$o_sub") == rc=1 && $(calls sub) == 1 ]] && ! grep "after a rerun" <<< "$o_sub"'

printf '%s\n' "FAIL a" "3/5 checks passed" "PASS b" "2/2 checks passed" > "$T/tc-two.txt"; printf '%s\n' "HARNESS_TESTS=4" "12 passed" > "$T/tc-none.txt"
check "testcount.mjs: --total is the last N/M line's total; nothing without one" \
  '[[ $(node "$HERE/../lib/testcount.mjs" "$T/tc-two.txt" --total) == "2 tests" && -z $(node "$HERE/../lib/testcount.mjs" "$T/tc-none.txt" --total) ]] \
  && node --input-type=module -e "import { total } from \"$HERE/../lib/testcount.mjs\"; process.exit(total(\"3/5 checks passed\nx 7/9 tests passed\n\") === 9 && total(\"ok\") === null ? 0 : 1)"'
check "check rerun: CHECK_RERUN=auto in config.sh, exported as HARNESS_CHECK_RERUN; the template has it; lanes export HARNESS_LANE" \
  '( source "$HERE/../lib/config.sh" && HARNESS_CONFIG=/dev/null harness_config /nonexistent && [[ $CHECK_RERUN == auto ]] ) \
  && grep -qF "HARNESS_CHECK_RERUN=\$CHECK_RERUN" "$HERE/../lib/prompt.sh" && grep -q "^# CHECK_RERUN=auto .*auto.*failed.*suite.*off" "$HERE/../templates/user/config.sh" \
  && grep -q "^export HARNESS_LANE=\$M " "$HERE/../lib/lane.sh"'
suite_end
