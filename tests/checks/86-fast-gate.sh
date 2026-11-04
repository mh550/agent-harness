#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the fast gate (T2-01): check.sh --fast runs CHECK_FAST_CMD, marks fast-<key>, never green-<key> ----
# 73-check-rerun.sh's stub suite, its own copy: one throwaway repo, a directory $T/fg-<case> per case (the counter n,
# every call's arguments in args, each call's output out<n>, its scratch s and cache c). FG_MODE: green (5 tests bare,
# 3 under --tier fast, one PASS per name), always (red every call, HARNESS_FAILED=a), once (red on call 1, then green),
# noline (red on call 1 with no HARNESS_FAILED= line, then green), nolinered (red every call, no line), hang (past its
# timeout). FAST is the fast command: the same stub with --tier fast.
git init -q "$T/fg" && ( cd "$T/fg" && echo a > a && echo c > CLAUDE.md && git add -A && git -c user.name=t -c user.email=t@t commit -qm a )
cat > "$T/fg-suite.sh" <<'EOF'
n=$(( $(cat "$FG/n" 2> /dev/null || echo 0) + 1 )); echo "$n" > "$FG/n"; echo "$*" >> "$FG/args"; o=$FG/out$n
green() { if [[ $* == "--tier fast" ]]; then echo "3/3 checks passed"; elif (( $# )); then for a; do echo "PASS $a"; done; echo "$#/$# checks passed"
  else echo "5/5 checks passed"; fi > "$o"; cat "$o"; exit 0; }
case $FG_MODE in
  green) green "$@" ;;
  always) printf '%s\n' "FAIL a" "HARNESS_FAILED=a" "2/3 checks passed" > "$o" ;;
  once) (( n == 1 )) || green "$@"; printf '%s\n' "FAIL a" "HARNESS_FAILED=a" "2/3 checks passed" > "$o" ;;
  noline) (( n == 1 )) || green "$@"; printf '%s\n' "FAIL x" "2/3 checks passed" > "$o" ;;
  nolinered) printf '%s\n' "FAIL x" "2/3 checks passed" > "$o" ;;
  hang) sleep 5 ;;   # sleep-ok: a suite that outlives its timeout
esac
cat "$o"; exit 1
EOF
FAST="bash $T/fg-suite.sh --tier fast"
fg() { local c=$1 m=$2; shift 2; mkdir -p "$T/fg-$c/c"
  ( cd "$T/fg" && FG=$T/fg-$c FG_MODE=$m HARNESS_SCRATCH=$T/fg-$c/s HARNESS_CHECK_CACHE=$T/fg-$c/c HARNESS_CHECK_FAST_CMD=${FGF-$FAST} \
    HARNESS_CHECK_CMD="bash $T/fg-suite.sh" "$HERE/../lib/check.sh" "$@" ); }
calls() { cat "$T/fg-$1/n" 2> /dev/null || echo 0; }
args() { sed -n "$2p" "$T/fg-$1/args"; }
rows() { cut -f2 "$T/fg-$1/s/check-runs.log" | paste -sd' '; }
marks() { ls "$T/fg-$1/c" | grep -E '^(green|red|fast)-' | sed 's/-.*//' | paste -sd' '; }
key=$(cd "$T/fg" && node "$HERE/../lib/treekey.mjs")

# no fast command: --fast is the full form, byte for byte
o_n1=$(FGF="" fg none green --fast; echo "rc=$?") o_n2=$(FGF="" fg none green --fast; echo "rc=$?")
check "fast gate: with no fast command, --fast runs the suite bare, writes green-<key> (count, wall) and prints the full green line" \
  '[[ $o_n1 =~ ^check:\ green\ in\ [0-9]+\ s,\ 5\ tests$'"'"'\n'"'"'rc=0$ && $(calls none) == 1 && -z $(args none 1) ]] \
  && [[ $(marks none) == green && $(sed -n 1p "$T/fg-none/c/green-$key") == "5 tests" && $(sed -n 2p "$T/fg-none/c/green-$key") =~ ^wall\ [0-9]+$ ]] \
  && [[ $(grep -c "" "$T/fg-none/c/green-$key") == 2 ]]'
check "fast gate: with no fast command, the next --fast call is the full form's cached line; rows full then cached" \
  '[[ $o_n2 == $'"'"'check: green (cached for this code tree, 5 tests)\nrc=0'"'"' && $(calls none) == 1 && $(rows none) == "full cached" ]]'

# the fast tier
o_f1=$(fg fast green --fast; echo "rc=$?") o_f2=$(fg fast green --fast; echo "rc=$?")
check "fast gate: --fast runs the fast command (--tier fast), writes fast-<key> (the fast count, wall) and no green-<key>; row fast" \
  '[[ $o_f1 =~ ^check:\ fast\ green\ in\ [0-9]+\ s,\ 3\ tests$'"'"'\n'"'"'rc=0$ && $(args fast 1) == "--tier fast" ]] \
  && [[ $(marks fast) == fast && $(sed -n 1p "$T/fg-fast/c/fast-$key") == "3 tests" && $(sed -n 2p "$T/fg-fast/c/fast-$key") =~ ^wall\ [0-9]+$ ]] \
  && [[ $(grep -c "" "$T/fg-fast/c/fast-$key") == 2 && $(rows fast | cut -d" " -f1) == fast ]]'
check "fast gate: the next --fast call is the cached fast line, row cached, no run" \
  '[[ $o_f2 == $'"'"'check: fast green (cached for this code tree, 3 tests)\nrc=0'"'"' && $(calls fast) == 1 && $(rows fast) == "fast cached" ]]'
check "fast gate: the fast run's output is check-fast.out; check.out and check-<key>.out are not written" \
  'cmp -s "$T/fg-fast/s/check-fast.out" "$T/fg-fast/out1" && [[ ! -e $T/fg-fast/s/check.out && ! -e $T/fg-fast/s/check-$key.out ]]'
o_f3=$(fg fast green; echo "rc=$?")
check "fast gate: a bare call on a fast-green tree runs the suite bare (a fast-green is never read as a green)" \
  '[[ $o_f3 =~ ^check:\ green\ in\ [0-9]+\ s,\ 5\ tests$'"'"'\n'"'"'rc=0$ && $(calls fast) == 2 && -z $(args fast 2) ]] \
  && [[ $(rows fast) == "fast cached full" && -e $T/fg-fast/c/green-$key ]] && cmp -s "$T/fg-fast/s/check.out" "$T/fg-fast/out2" && cmp -s "$T/fg-fast/s/check-fast.out" "$T/fg-fast/out1"'

# full markers answer first
mkdir -p "$T/fg-pg/c" "$T/fg-pr/c"; printf '%s\n' "9 tests" "wall 100" > "$T/fg-pg/c/green-$key"
printf '%s\n' 1 a "wall 100" "check: RED (exit 1 after 100 s) — last lines of /x/check.out:" > "$T/fg-pr/c/red-$key"
o_pg=$(fg pg green --fast; echo "rc=$?") o_pr=$(fg pr green --fast; echo "rc=$?")
check "fast gate: a green-<key> answers --fast with the full cached line, no run, no fast-<key>" \
  '[[ $o_pg == $'"'"'check: green (cached for this code tree, 9 tests)\nrc=0'"'"' && $(calls pg) == 0 && $(marks pg) == green && $(rows pg) == cached ]]'
check "fast gate: a red-<key> answers --fast with the cached RED and exit 1, no run" \
  '[[ $(head -1 <<< "$o_pr") == "check: RED (cached for this code tree: a)" && $(tail -1 <<< "$o_pr") == rc=1 && $(calls pr) == 0 && $(rows pr) == cached ]]'

# a fast red: rerun guard, no marker of any kind
o_al=$(fg al always --fast; echo "rc=$?")
check "fast gate: a fast red twice reruns a once and prints the fast RED line on check-fast.out and its tail; exit 1" \
  '[[ $(head -1 <<< "$o_al") =~ ^check:\ RED\ \(fast:\ exit\ 1\ after\ [0-9]+\ s\;\ red\ again\ on\ a\ rerun\ of\ a\)\ —\ last\ lines\ of\ (.*)/check-fast.out:$ ]] \
  && [[ ${BASH_REMATCH[1]} == "$T/fg-al/s" && $(sed -n 2,4p <<< "$o_al") == $(cat "$T/fg-al/out1") && $(tail -1 <<< "$o_al") == rc=1 ]] \
  && [[ $(calls al) == 2 && $(args al 1) == "--tier fast" && $(args al 2) == a && $(rows al) == fast ]]'
check "fast gate: a fast red writes no fast-, green- or red- marker" '[[ -z $(marks al) ]]'

o_on=$(fg on once --fast; echo "rc=$?")
check "fast gate: red then green is the fast flake line, fast-<key> with the first run total, one flakes.jsonl row with tier fast" \
  '[[ $o_on == $'"'"'check: fast green after a rerun (flaky: a), 3 tests\nrc=0'"'"' && $(marks on) == fast && $(sed -n 1p "$T/fg-on/c/fast-$key") == "3 tests" ]] \
  && [[ $(grep -c "" "$T/fg-on/c/flakes.jsonl") == 1 ]] && jq -e '"'"'.tier == "fast" and .names == ["a"] and .rerun == "failed"'"'"' "$T/fg-on/c/flakes.jsonl" > /dev/null'
check "fast gate: a full run's flake row has no tier key" \
  'fg onf once > /dev/null; jq -e '"'"'has("tier") | not'"'"' "$T/fg-onf/c/flakes.jsonl" > /dev/null'

o_nl=$(fg nl noline --fast; echo "rc=$?") o_nr=$(fg nr nolinered --fast; echo "rc=$?")
check "fast gate: a fast red with no HARNESS_FAILED= line reruns the fast tier: flaky: the fast tier, or red again on a rerun of the fast tier" \
  '[[ $o_nl == $'"'"'check: fast green after a rerun (flaky: the fast tier), 3 tests\nrc=0'"'"' && $(args nl 2) == "--tier fast" ]] \
  && jq -e '"'"'.tier == "fast" and .names == [] and .rerun == "suite"'"'"' "$T/fg-nl/c/flakes.jsonl" > /dev/null \
  && [[ $(head -1 <<< "$o_nr") =~ ^check:\ RED\ \(fast:\ exit\ 1\ after\ [0-9]+\ s\;\ red\ again\ on\ a\ rerun\ of\ the\ fast\ tier\)\ —\ last ]] \
  && [[ $(calls nr) == 2 && $(args nr 2) == "--tier fast" && -z $(marks nr) && $(tail -1 <<< "$o_nr") == rc=1 ]]'
o_hg=$(HARNESS_CHECK_TIMEOUT=2s fg hg hang --fast; echo "rc=$?")
check "fast gate: a hanging fast run times out: the fast RED timeout line, no rerun, no marker" \
  'grep -qx "check: RED (fast: timed out after 2s, exit 124 after [0-9]* s) — last lines of $T/fg-hg/s/check-fast.out:" <<< "$o_hg" \
  && [[ $(tail -1 <<< "$o_hg") == rc=124 && $(calls hg) == 1 && -z $(marks hg) && ! -e $T/fg-hg/s/check-fast-rerun.out ]]'

# --fast never reads part-<key>: a green full run with a map writes the sidecar, then a mapped-only diff
( cd "$T/fg" && mkdir -p .harness && echo 'CHECK_KEY_MAP="CLAUDE.md:memlint"' > .harness/config.sh && git add -A && git -c user.name=t -c user.email=t@t commit -qm map )
HARNESS_CHECK_KEY_MAP=CLAUDE.md:memlint fg pt green > /dev/null; echo x >> "$T/fg/CLAUDE.md"
o_pt=$(HARNESS_CHECK_KEY_MAP=CLAUDE.md:memlint fg pt green --fast; echo "rc=$?")
check "fast gate: with a part- sidecar and a mapped-only diff, --fast runs the fast tier, not the partial subset; row fast" \
  '[[ $(ls "$T/fg-pt/c" | grep -c "^part-") == 1 && $(calls pt) == 2 && $(args pt 2) == "--tier fast" && $(rows pt) == "full fast" ]] \
  && [[ $o_pt =~ ^check:\ fast\ green\ in\ [0-9]+\ s,\ 3\ tests$'"'"'\n'"'"'rc=0$ && ! -e $T/fg-pt/s/check-partial.out ]] \
  && cmp -s "$T/fg-pt/s/check.out" "$T/fg-pt/out1"'
( cd "$T/fg" && git checkout -q -- . )

o_sb=$(fg sb green x; echo "rc=$?")
check "fast gate: the subset form is unchanged with a fast command set: its args, row subset, no marker" \
  '[[ $o_sb == $'"'"'PASS x\n1/1 checks passed\nrc=0'"'"' && $(args sb 1) == x && $(rows sb) == subset && -z $(marks sb) ]]'
o_ar=$(fg ar green --fast x; echo "rc=$?")
check "fast gate: --fast with further arguments is a usage error (exit 2), nothing run" \
  '[[ $(tail -1 <<< "$o_ar") == rc=2 && $(calls ar) == 0 ]] && grep -q "^check: --fast takes no arguments" <<< "$o_ar"'

check "fast gate: CHECK_FAST_CMD empty by default, exported as HARNESS_CHECK_FAST_CMD; the template has it commented; this repo sets the fast tier" \
  '( source "$HERE/../lib/config.sh" && HARNESS_CONFIG=/dev/null harness_config /nonexistent && [[ -z ${CHECK_FAST_CMD-x} ]] ) \
  && ( source "$HERE/../lib/config.sh" && HARNESS_CONFIG=/dev/null harness_config "$HERE/.." && [[ $CHECK_FAST_CMD == "bash tests/run.sh --tier fast" ]] ) \
  && [[ $(grep -c "HARNESS_CHECK_FAST_CMD=\$CHECK_FAST_CMD" "$HERE/../lib/prompt.sh") == 1 ]] \
  && grep -q "^# CHECK_FAST_CMD=.*fast tier.*empty.*whole suite" "$HERE/../templates/project/config.sh"'
check "fast gate: check.sh's usage header documents --fast, fast-<key>, check-fast.out and the fast row" \
  'h=$(sed -n "/^set -uo/q;p" "$HERE/../lib/check.sh") && grep -qF -- "--fast" <<< "$h" && grep -qF "fast-<key>" <<< "$h" \
  && grep -qF "check-fast.out" <<< "$h" && grep -qF "<full|fast|subset|partial|cached>" <<< "$h"'
suite_end
