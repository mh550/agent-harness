#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the red marker (S1-03): a red full run that wasn't a timeout or a cap kill is cached; the next full call answers ----
# 73-check-rerun.sh's stub suite, its own copy: one throwaway repo, a directory $T/rm-<case> per case (the counter n, each
# call's arguments, its scratch s and cache c). RM_MODE: always (red, HARNESS_FAILED=a), late (red on calls 1-3, green
# from 4), noline (red, no HARNESS_FAILED= line), hang (past its timeout), oom (the scope stub's cap kill), plant (green,
# after writing a red-<key> into the cache mid-run: a planted marker the lookup has already passed).
git init -q "$T/rm" && ( cd "$T/rm" && echo a > a && git add a && git -c user.name=t -c user.email=t@t commit -qm a )
cat > "$T/rm-suite.sh" <<'EOF'
n=$(( $(cat "$RM/n" 2> /dev/null || echo 0) + 1 )); echo "$n" > "$RM/n"; echo "$*" >> "$RM/args"
green() { if (( $# )); then for a; do echo "PASS $a"; done; echo "$#/$# checks passed"; else echo "5/5 checks passed"; fi; exit 0; }
case $RM_MODE in
  always) printf '%s\n' "FAIL a" "HARNESS_FAILED=a" "4/5 checks passed" ;;
  late) (( n >= 4 )) && green "$@"; printf '%s\n' "FAIL a" "HARNESS_FAILED=a" "4/5 checks passed" ;;
  noline) printf '%s\n' "FAIL x" "4/5 checks passed" ;;
  hang) sleep 5 ;;   # sleep-ok: a suite that outlives its timeout
  oom) touch "$STUB_DIR/scope/$STUB_SCOPE_UNIT.oom"; exit 137 ;;
  plant) printf '%s\n' 1 a "wall 0" "check: RED (planted)" > "$RM/c/red-$(node "$TREEKEY")"; green "$@" ;;
esac
exit 1
EOF
rm_() { local c=$1 m=$2; shift 2; mkdir -p "$T/rm-$c/c"
  ( cd "$T/rm" && RM=$T/rm-$c RM_MODE=$m TREEKEY=$HERE/../lib/treekey.mjs HARNESS_SCRATCH=$T/rm-$c/s HARNESS_CHECK_CACHE=$T/rm-$c/c \
    HARNESS_CHECK_CMD="bash $T/rm-suite.sh" "$HERE/../lib/check.sh" "$@" ); }
calls() { cat "$T/rm-$1/n"; }
reds() { ls "$T/rm-$1/c" | grep -c '^red-'; }
lastrow() { tail -1 "$T/rm-$1/s/check-runs.log" | cut -f2; }

o_al1=$(rm_ al always; echo "rc=$?")
al_m=$(ls "$T/rm-al/c"/red-* 2> /dev/null | head -1) al_red=$(grep '^check: RED (' <<< "$o_al1")
check "red marker: red twice with HARNESS_FAILED=a writes red-<key>: 1, a, wall <s>, the RED line as printed; no green-<key>" \
  '[[ $(reds al) == 1 && $(sed -n 1p "$al_m") == 1 && $(sed -n 2p "$al_m") == a && $(sed -n 3p "$al_m") =~ ^wall\ [0-9]+$ ]] \
  && [[ -n $al_red && $(sed -n 4p "$al_m") == "$al_red" && $(grep -c "" "$al_m") == 4 && $(calls al) == 2 ]] \
  && ! ls "$T/rm-al/c"/green-* 2> /dev/null'
rm -f "$T/rm-al/s/check.out"; o_al2=$(rm_ al always; echo "rc=$?")
check "red marker: the next full call prints the cached line and the stored RED line, exits 1, runs nothing, writes no check.out" \
  '[[ $o_al2 == "check: RED (cached for this code tree: a)"$'"'"'\n'"'"'"$al_red"$'"'"'\nrc=1'"'"' ]] \
  && [[ $(calls al) == 2 && ! -e $T/rm-al/s/check.out && $(lastrow al) == cached ]]'
o_al3=$(rm_ al always a; echo "rc=$?")
check "red marker: a subset call on the red tree runs the suite and reads no marker" \
  '[[ $(calls al) == 3 && $(tail -1 <<< "$o_al3") == rc=1 && $(lastrow al) == subset ]] && ! grep cached <<< "$o_al3"'

rm_ lt late > /dev/null; rm_ lt late a > /dev/null; o_lt=$(rm_ lt late; echo "rc=$?")
check "red marker: a suite that would be green on call 4 still gets the cached red (the key is the tree's)" \
  '[[ $(head -1 <<< "$o_lt") == "check: RED (cached for this code tree: a)" && $(tail -1 <<< "$o_lt") == rc=1 && $(calls lt) == 3 ]]'

rm_ nl noline > /dev/null; o_nl=$(rm_ nl noline; echo "rc=$?")
check "red marker: a red with no HARNESS_FAILED line answers cached for this code tree: whole suite" \
  '[[ $(head -1 <<< "$o_nl") == "check: RED (cached for this code tree: whole suite)" && $(calls nl) == 2 ]] \
  && [[ -z $(sed -n 2p "$T/rm-nl/c"/red-*) ]]'

HARNESS_CHECK_TIMEOUT=2s rm_ hg hang > /dev/null; hg_reds=$(reds hg); HARNESS_CHECK_TIMEOUT=2s rm_ hg hang > /dev/null
HARNESS_SCOPE_PREFIX=harness-rm rm_ om oom > /dev/null; om_reds=$(reds om); HARNESS_SCOPE_PREFIX=harness-rm rm_ om oom > /dev/null
check "red marker: a timeout and a cap kill write no red-<key>, and the next call runs the suite" \
  '[[ $hg_reds == 0 && $(calls hg) == 2 && $om_reds == 0 && $(calls om) == 2 ]]'

o_pl=$(rm_ pl plant; echo "rc=$?")
check "red marker: a green run removes a planted red-<key>" \
  '[[ $(tail -1 <<< "$o_pl") == rc=0 && $(calls pl) == 1 && $(reds pl) == 0 ]] && ls "$T/rm-pl/c"/green-* > /dev/null'
check "red marker: check.sh's usage header names red-<key>" 'sed -n "2,/^set -uo/p" "$HERE/../lib/check.sh" | grep "red-<key>" > /dev/null'
suite_end
