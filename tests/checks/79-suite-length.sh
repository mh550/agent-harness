#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the suite's length in the prompt (S1, fix 3): a green marker's `wall` line, read by every prompt's Suite line ----
# A counting suite that prints what tests/run.sh prints (PASS/FAIL, HARNESS_FAILED=, N/M checks passed), red while
# BROKEN exists; each call appends `<treekey> <args>` to $T/cs.log (the run's exported key ignore list: check.sh's key)
HH=$(cd "$HERE/.." && pwd)
cat > "$T/cs.sh" <<EOF
echo "\$(node $HH/lib/treekey.mjs) \$*" >> "$T/cs.log"
if [[ -f BROKEN ]]; then printf '%s\n' "FAIL t1" "HARNESS_FAILED=t1" "1/2 checks passed"; exit 1; fi
if (( \$# )); then for a; do echo "PASS \$a"; done; echo "\$#/\$# checks passed"; else printf '%s\n' "PASS t1" "PASS t2" "2/2 checks passed"; fi
EOF
PH="give a full run a timeout of at least twice that"
mkdir -p "$HARNESS_STATE/proj/sl" && echo "CHECK_CMD='bash $T/cs.sh'" > "$HARNESS_STATE/proj/sl/run.env"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" sl --spec SPEC.md --foreground > "$T/sl.out" 2>&1
SL=$HARNESS_STATE/proj/sl
walls=$(sed -n 's/^wall \([0-9][0-9]*\)$/\1/p' "$SL"/green/green-* 2> /dev/null | sort -u)
pwall() { sed -n "s/^Suite: last full run \([0-9][0-9]*\) s: $PH$/\1/p" "$1"; }
check "suite length: the coding and initializer prompts' This session Suite line has the wall of a marker in the run's green/" \
  '[[ -n $walls ]] && w=$(pwall "$SL/prompt-coding.md") && [[ -n $w ]] && grep -qx "$w" <<< "$walls" \
  && w=$(pwall "$SL/prompt-initializer.md") && [[ -n $w ]] && grep -qx "$w" <<< "$walls"'
# a wall differs from session to session: above `# This session` it would split two sessions' shared prefix
# (decisions/2026-10-21-static-first-prompts; the 08/13/14/15 prefix checks)
below() { awk '/^# This session$/ { s = 1 } /last full run ([0-9]+ s|not measured)/ { print (s ? "below" : "above") }' "$1" | sort -u; }
check "suite length: every kind's wall is under # This session; its This run Suite line points there" \
  'for k in coding initializer verify; do [[ $(below "$SL/prompt-$k.md") == below ]] || bad=1; done; [[ -z ${bad:-} ]] \
  && sed -n "/^# This session\$/,\$p" "$HH/prompts/resolve.md" | grep -xF "Suite: last full run {{SUITE_LENGTH}}" > /dev/null \
  && grep -qF "cached per code tree; its last full run is under *This session*) · init: " "$SL/prompt-coding.md"'
check "suite length: tests-start and tests-end hold the count of a two-line marker" \
  '[[ $(cat "$SL/tests-start") == 2 && $(cat "$SL/tests-end") == 2 ]] && grep -qx "wall [0-9]*" "$SL"/green/green-*'

# the lookup, by the command form: the cwd tree's green-<key>, else the newest green with a wall, then the cwd tree's
# red-<key>, else the newest red (a red may have stopped early: its wall only when no green has one), else none
k=$( source "$SL/meta.env" && cd "$WT" && HARNESS_CHECK_KEY_IGNORE=".harness/runs docs/plans" node "$HH/lib/treekey.mjs" )
fid=$(jq -r '.features[0].id' "$(list sl)")
sl() { bash "$HH/lib/prompt.sh" "$SL" coding "$fid" 2> /dev/null | grep "^Suite: last full run"; }
rm -f "$SL"/green/green-* "$SL"/green/red-*
printf '%s\n' "2 tests" "wall 4321" > "$SL/green/green-$k"; touch -d '-1 hour' "$SL/green/green-$k"
printf '%s\n' "2 tests" "wall 77" > "$SL/green/green-0123456789abcdef"; sl_own=$(sl)
rm "$SL/green/green-$k"; printf '%s\n' 1 t1 "wall 3" "check: RED (exit 1 after 3 s)" > "$SL/green/red-$k"; sl_gr=$(sl)
rm "$SL/green/green-0123456789abcdef"; touch -d '-1 hour' "$SL/green/red-$k"
printf '%s\n' 1 t1 "wall 9" "check: RED (exit 1 after 9 s)" > "$SL/green/red-0123456789abcdef"; sl_red=$(sl)
rm "$SL/green/red-$k"; sl_new=$(sl)
rm "$SL/green/red-0123456789abcdef"; printf '%s\n' "2 tests" > "$SL/green/green-0123456789abcdef"; : > "$SL/green/green-$k"; sl_none=$(sl)
check "suite length: the tree's own green wins over a newer one; any green's wall over a red's; then the tree's red, then the newest" \
  '[[ $sl_own == "Suite: last full run 4321 s: $PH" && $sl_gr == "Suite: last full run 77 s: $PH" ]] \
  && [[ $sl_red == "Suite: last full run 3 s: $PH" && $sl_new == "Suite: last full run 9 s: $PH" ]]'
check "suite length: with no wall line anywhere, the Suite line names the run's CHECK_TIMEOUT" \
  '[[ $sl_none == "Suite: last full run not measured yet; bounded by CHECK_TIMEOUT 15m: give a full run a timeout above that" ]]'

# sn: the init plants a one-line green for its own tree, so the first suite is cached and nothing has been measured
git -C "$T/origin.git" update-ref refs/heads/main "$(git rev-parse HEAD)"
mkdir -p "$HARNESS_STATE/proj/sn" && printf '%s\n' "CHECK_CMD='bash $T/cs.sh'" \
  "INIT_CMD='mkdir -p \$HARNESS_CHECK_CACHE; k=\$(node $HH/lib/treekey.mjs); [[ -f \$HARNESS_CHECK_CACHE/green-\$k ]] || echo \"2 tests\" > \$HARNESS_CHECK_CACHE/green-\$k'" > "$HARNESS_STATE/proj/sn/run.env"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" sn --spec SPEC.md --foreground > "$T/sn.out" 2>&1
check "suite length: a run whose first suite is a cached one-line marker renders 'not measured yet' to its initializer" \
  'grep -qx "check: green (cached for this code tree, 2 tests)" "$HARNESS_STATE/proj/sn/prompt-initializer.md" \
  && grep -qxF "Suite: last full run not measured yet; bounded by CHECK_TIMEOUT 15m: give a full run a timeout above that" "$HARNESS_STATE/proj/sn/prompt-initializer.md"'

# se: the stub project's own suite counts nothing, so its markers' line 1 is empty: run_init pins no tests-start
# (cat would read `\nwall 0` and write `\nwall`)
git -C "$T/origin.git" update-ref refs/heads/main "$(git rev-parse HEAD)"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" se --spec SPEC.md --foreground > "$T/se.out" 2>&1
check "run_init: a marker with an empty count line pins no tests-start" \
  'grep -qx "wall [0-9]*" "$HARNESS_STATE/proj/se"/green/green-* && [[ ! -e $HARNESS_STATE/proj/se/tests-start ]]'

# a red run with no names is rerun whole: a green rerun's wall is the suite's length, not the red run's
git init -q "$T/rw" && ( cd "$T/rw" && echo a > a && git add a && git -c user.name=t -c user.email=t@t commit -qm a )
printf '%s\n' 'n=$(( $(cat "$RW/n" 2> /dev/null || echo 0) + 1 )); echo "$n" > "$RW/n"' \
  '(( n == 1 )) && { echo "FAIL x"; exit 1; }; sleep 2; echo "2/2 checks passed"   # sleep-ok: a whole-suite rerun that takes its time' > "$T/rw-suite.sh"
( cd "$T/rw" && RW=$T/rw-s HARNESS_SCRATCH=$T/rw-s HARNESS_CHECK_CACHE=$T/rw-c HARNESS_CHECK_CMD="bash $T/rw-suite.sh" "$HH/lib/check.sh" ) > "$T/rw.out" 2>&1
rw_wall=$(sed -n 's/^wall //p' "$T/rw-c"/green-* 2> /dev/null)
check "check.sh: after a whole-suite rerun the marker's wall is the rerun's (a red run with no names is no measure of the suite)" \
  'grep -q "^check: green after a rerun (flaky: whole suite)" "$T/rw.out" && [[ $rw_wall =~ ^[0-9]+$ ]] && (( rw_wall >= 2 ))'

# tests_end reads line 1 only: an empty count line is no count (cat would write `\nwall` into tests-end)
TE=$T/te; mkdir -p "$TE/st/green" "$TE/s" && git init -q "$TE/r" && ( cd "$TE/r" && echo a > a && git add a && git -c user.name=t -c user.email=t@t commit -qm a )
te() { printf "$1" > "$TE/st/green/green-$( cd "$TE/r" && node "$HH/lib/treekey.mjs" )"; rm -f "$TE/st/tests-end"
  ( cd "$TE/r" && HARNESS_HOME=$HH && source "$HH/lib/record.sh" && STATE=$TE/st SCRATCH=$TE/s tests_end ) 2> /dev/null; cat "$TE/st/tests-end" 2> /dev/null; }
te_n=$(te '7 tests\nwall 3\n') te_e=$(te '\nwall 3\n')
check "tests_end: the count from a marker's first line; an empty first line writes no tests-end" '[[ $te_n == 7 && -z $te_e ]]'

# the rule and the project's suite line
check "the coding prompt's suite rule: a timeout twice the last wall, in the background over the tool's limit, never polled" \
  '[[ $(grep -c "never poll it" "$HH/prompts/coding.md") == 1 ]] && grep -qF "Give every full run a timeout of at least twice its last wall (under *This session*)" "$HH/prompts/coding.md" \
  && grep -q "never poll it, never run it without a timeout" "$HH/prompts/coding.md"'
check "CLAUDE.md's suite line points at the run's prompt, with no fixed measurement" \
  'grep -q "see the run'"'"'s prompt" "$HH/CLAUDE.md" && [[ $(grep -c "208 s" "$HH/CLAUDE.md") == 0 ]]'
suite_end
