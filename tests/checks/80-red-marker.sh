#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the red marker (S1-03): a red full run that wasn't a timeout or a cap kill is cached; the next full call answers ----
# 73-check-rerun.sh's stub suite, its own copy: one throwaway repo, a directory $T/rm-<case> per case (the counter n, each
# call's arguments, its scratch s and cache c). RM_MODE: always (red, HARNESS_FAILED=a), late (red on calls 1-3, green
# from 4), noline (red, no HARNESS_FAILED= line), hang (past its timeout), oom (the scope stub's cap kill), plant (green,
# after writing a red-<key> into the cache mid-run: a planted marker the lookup has already passed), three (always, exit 3),
# sig (red by a signal's code, 143), rehang (red with a name, then a rerun past its timeout).
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
  three) printf '%s\n' "FAIL a" "HARNESS_FAILED=a" "4/5 checks passed"; exit 3 ;;
  sig) printf '%s\n' "FAIL x" "4/5 checks passed"; exit 143 ;;
  rehang) (( n == 2 )) && sleep 5; printf '%s\n' "FAIL a" "HARNESS_FAILED=a" "4/5 checks passed" ;;   # sleep-ok: a rerun that outlives its timeout
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
al_k=${al_m##*/red-} al_head="${al_red% — last lines of *} — last lines of $T/rm-al/s/check-${al_m##*/red-}.out (this tree's first run):"
check "red marker: the next full call prints the cached line, the stored RED line on this tree's own output, exits 1, runs nothing" \
  '[[ $(sed -n 1p <<< "$o_al2") == "check: RED (cached for this code tree: a)" && $(sed -n 2p <<< "$o_al2") == "$al_head" ]] \
  && [[ $(sed -n 3,5p <<< "$o_al2") == $(cat "$T/rm-al/s/check-$al_k.out") && $(tail -1 <<< "$o_al2") == rc=1 ]] \
  && [[ $(calls al) == 2 && ! -e $T/rm-al/s/check.out && $(lastrow al) == cached ]]'
# the tree's output gone (another tree ran since: check.out and check-<key>.out are that tree's): the cached answer says so
mv "$T/rm-al/s/check-$al_k.out" "$T/rm-al/s/check-0123456789abcdef.out"; o_al4=$(rm_ al always; echo "rc=$?")
check "red marker: with this tree's output gone from scratch, the cached answer names the subset call, not another tree's file" \
  '[[ $(sed -n 2p <<< "$o_al4") == "${al_red% — last lines of *} — its output is gone from scratch: check.sh a shows the failures" ]] \
  && [[ $(grep -c "" <<< "$o_al4") == 3 && $(calls al) == 2 ]]'
mv "$T/rm-al/s/check-0123456789abcdef.out" "$T/rm-al/s/check-$al_k.out"
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

rm_ th three > /dev/null; o_th=$(rm_ th three; echo "rc=$?")
check "red marker: the cached answer exits with the stored code (3), not 1" '[[ $(tail -1 <<< "$o_th") == rc=3 && $(calls th) == 2 ]]'
rm_ sg sig > /dev/null; sg_reds=$(reds sg); rm_ sg sig > /dev/null
HARNESS_CHECK_TIMEOUT=2s rm_ rh rehang > /dev/null; rh_reds=$(reds rh); HARNESS_CHECK_TIMEOUT=2s rm_ rh rehang > /dev/null
check "red marker: a red by a signal's code (143) and a red whose rerun timed out write no red-<key>; the next call runs" \
  '[[ $sg_reds == 0 && $(calls sg) == 4 && $rh_reds == 0 && $(calls rh) == 4 ]]'
mkdir -p "$T/rm-bd/c"; printf '%s\n' "" "" "wall 1" "check: RED (x)" > "$T/rm-bd/c/red-$( cd "$T/rm" && node "$HERE/../lib/treekey.mjs" )"
o_bd=$(rm_ bd always 2>&1; echo "rc=$?")
check "red marker: a marker whose exit line isn't a red exit code answers exit 1" '[[ $(tail -1 <<< "$o_bd") == rc=1 && ! -e $T/rm-bd/n ]]'

o_pl=$(rm_ pl plant; echo "rc=$?")
check "red marker: a green run removes a planted red-<key>" \
  '[[ $(tail -1 <<< "$o_pl") == rc=0 && $(calls pl) == 1 && $(reds pl) == 0 ]] && ls "$T/rm-pl/c"/green-* > /dev/null'
check "red marker: check.sh's usage header names red-<key>" 'sed -n "2,/^set -uo/p" "$HERE/../lib/check.sh" | grep "red-<key>" > /dev/null'

# ---- the driver (S1-04): a retry's run_init answers from the marker; verify's run_init fresh clears both markers ----
# A counting suite that prints what tests/run.sh prints, red while BROKEN exists; each call appends `<treekey> <red|green>
# <args>` to $CS_LOG (the run's exported key ignore list: check.sh's key)
HH=$(cd "$HERE/.." && pwd)
cat > "$T/cs.sh" <<EOF
if [[ -f BROKEN ]]; then echo "\$(node $HH/lib/treekey.mjs) red \$*" >> "\$CS_LOG"; printf '%s\n' "FAIL t1" "HARNESS_FAILED=t1" "1/2 checks passed"; exit 1; fi
echo "\$(node $HH/lib/treekey.mjs) green \$*" >> "\$CS_LOG"
if (( \$# )); then for a; do echo "PASS \$a"; done; echo "\$#/\$# checks passed"; else printf '%s\n' "PASS t1" "PASS t2" "2/2 checks passed"; fi
EOF
csrun() { mkdir -p "$HARNESS_STATE/proj/$1" && echo "CHECK_CMD='CS_LOG=$T/cs-$1.log bash $T/cs.sh'" > "$HARNESS_STATE/proj/$1/run.env"; }
# rm: the stub's C leaves BROKEN on its first try; the post-session run and its rerun find it red, the retry's init is cached
csrun rm; STUB_NO_TAMPER=1 STUB_LENIENT=1 "$H" start "$T/proj" rm --spec SPEC.md --foreground > "$T/rm.out" 2>&1
rm_key=$(awk '$2 == "red" { print $1; exit }' "$T/cs-rm.log" 2> /dev/null)
rm_retry=$(grep -l '^Feature: `C`$' $(find "$HARNESS_STATE/proj/rm" -name '*.prompt.md' | sort) 2> /dev/null | sed -n 2p)
check "red marker: C's red un-passes it; the retry's init output is the cached red and run.log says suite red before the session" \
  'hlog rm | grep " · C un-passed: suite red after the session$" > /dev/null && grep "suite red before the session" "$HARNESS_STATE/proj/rm/run.log" > /dev/null \
  && [[ -n $rm_retry ]] && grep "^check: RED (cached for this code tree: t1)$" "$rm_retry" > /dev/null'
check "red marker: the red tree ran the suite twice (the full run and the rerun guard's), none from the retry's run_init" \
  '[[ -n $rm_key && $(grep -c "^$rm_key " "$T/cs-rm.log") == 2 && $(grep -c "^$rm_key red \$" "$T/cs-rm.log") == 1 ]] \
  && [[ $(grep -c "^$rm_key red t1\$" "$T/cs-rm.log") == 1 ]]'

# pv: B (M1's last) plants a red-<key> and a green-<key> for its committed tree: the post-session check trusts the green,
# verify's run_init fresh removes both and runs the verified tree in full
git -C "$T/origin.git" update-ref refs/heads/main "$(git rev-parse HEAD)"
csrun pv; STUB_PLANT_MARKERS=B STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" pv --spec SPEC.md --foreground > "$T/pv.out" 2>&1
pv_key=$(cat "$T/planted-pv" 2> /dev/null) PV=$HARNESS_STATE/proj/pv/green
check "red marker: verify's run_init fresh removes the tree's red-<key> and green-<key>; the suite runs in full on it" \
  'hlog pv | grep " · verify M1: suite cache cleared; the suite runs in full on the verified tree$" > /dev/null \
  && [[ -n $pv_key && ! -e $PV/red-$pv_key && $(sed -n 1p "$PV/green-$pv_key") == "2 tests" ]] \
  && grep -x "$pv_key green " "$T/cs-pv.log" > /dev/null && ! hlog pv | grep "verify M1: the suite is red" > /dev/null'

# if: the run's first init fails and its suite (red until an init succeeded: the environment, not the tree) is red twice; a
# red under a failed init isn't kept, so the first coding session's init, which succeeds, runs the suite on that tree
git -C "$T/origin.git" update-ref refs/heads/main "$(git rev-parse HEAD)"
mkdir -p "$HARNESS_STATE/proj/ifr" && printf '%s\n' \
  "CHECK_CMD='if [[ -f $T/if-ok ]]; then echo \"PASS t1\"; echo \"1/1 checks passed\"; else echo \"FAIL t1\"; echo HARNESS_FAILED=t1; echo \"0/1 checks passed\"; exit 1; fi'" \
  "INIT_CMD='if [[ -f $T/if-1 ]]; then touch $T/if-ok; else touch $T/if-1; echo \"init failed\"; exit 1; fi'" > "$HARNESS_STATE/proj/ifr/run.env"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" ifr --spec SPEC.md --foreground > "$T/ifr.out" 2>&1
if_first=$(grep -l '^Feature: `' $(find "$HARNESS_STATE/proj/ifr" -name '*.prompt.md' | sort) 2> /dev/null | head -1)
check "red marker: a red under a failed init isn't kept (noted); the next init, which succeeds, runs the suite" \
  'hlog ifr | grep " · suite red under a failed init: not cached (the next init runs it)$" > /dev/null && [[ -n $if_first ]] \
  && ! grep "cached for this code tree: t1" "$if_first" > /dev/null && grep "^check: green in " "$if_first" > /dev/null'
suite_end
