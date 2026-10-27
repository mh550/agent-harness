#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- lanes scheduler (lanes P1-02): features.mjs lanes, next <m>, deps, pass; scope_owns' <m>- roles ----
FM() { node "$HERE/../lib/features.mjs" "$@"; }
LS=$T/lanes; mkdir -p "$LS"
# <name> <json features>: a list file; a state dir per check, with the run's meta.env (lanes names the tags by its RUN_ID)
ll() { printf '{"features":%s}\n' "$2" > "$LS/$1.json"; }
st() { rm -rf "$LS/st-$1"; mkdir -p "$LS/st-$1"; printf 'RUN_ID=demo\n' > "$LS/st-$1/meta.env"; echo "$LS/st-$1"; }
lanes() { FM lanes "$LS/$1.json" "$LS/att.json" 2 "$LS/parked.json" "$2" | tr '\t' '|' | paste -sd ' ' -; }   # "<m>|<tags> …"
echo '{}' > "$LS/att.json"; echo '{}' > "$LS/parked.json"
ll und '[{"id":"a1","milestone":"M1","passes":false},{"id":"b1","milestone":"M2","after":[],"passes":false},{"id":"c1","milestone":"M3","passes":false}]'
s=$(st und0); u0=$(lanes und "$s"); touch "$s/verified-M1"; u1=$(lanes und "$s"); touch "$s/verified-M2"; u2=$(lanes und "$s")
check "lanes: a milestone whose first feature has no after waits on every earlier milestone (tags of each as its base)" \
  '[[ $u0 == "M1| M2|" && $u1 == "M2|" && $u2 == "M3|run/demo/M1 run/demo/M2" ]]'
check "lanes: a milestone whose first feature has after: [] opens at once, beside the first" '[[ $u0 == "M1| M2|" ]]'
ll into '[{"id":"a1","milestone":"M1","passes":false},{"id":"b1","milestone":"M2","after":[],"passes":false},{"id":"b2","milestone":"M2","after":["a1"],"passes":false}]'
s=$(st into); i0=$(lanes into "$s"); i0d=$(FM deps "$LS/into.json" M2 | paste -sd ' ' -); touch "$s/verified-M1"; i1=$(lanes into "$s")
check "lanes: a later feature's after into another milestone makes the lane wait for it (F deps names it)" \
  '[[ $i0 == "M1|" && $i0d == M1 && $i1 == "M2|run/demo/M1" && -z $(FM deps "$LS/into.json" M1) ]]'
s=$(st needs); touch "$s/needs-M2"; n0=$(lanes und "$s"); touch "$s/verified-M1"; n1=$(lanes und "$s")
check "lanes: a needs-<m> milestone never opens" '[[ $n0 == "M1|" && -z $n1 ]]'
ll fwd '[{"id":"a1","milestone":"M1","passes":false},{"id":"a2","milestone":"M1","after":["b1"],"passes":false},{"id":"b1","milestone":"M2","after":["a1"],"passes":false}]'
ll fwdm '[{"id":"a1","milestone":"M1","after":["M2"],"passes":false},{"id":"b1","milestone":"M2","passes":false}]'
s=$(st fwd); v0=$(lanes fwd "$s"); v1=$(lanes fwdm "$s"); touch "$s/verified-M1"; v2=$(lanes fwdm "$s"); v3=$(FM deps "$LS/fwd.json" M1)
FM lanes "$LS/fwd.json" "$LS/att.json" 2 "$LS/parked.json" 2> /dev/null; v4=$?
check "lanes: an after into a later milestone (a name or its feature) never makes a lane wait on a later one (no cycle)" \
  '[[ $v0 == "M1|" && $v1 == "M1|" && $v2 == "M2|run/demo/M1" && -z $v3 && $v4 == 2 ]]'
s=$(st open); mkdir -p "$s/lanes/M1" "$s/lanes/M2"; echo $$ > "$s/lanes/M1/pid"
( exit 0 ) & dead=$!; wait $dead; echo "$dead" > "$s/lanes/M2/pid"; o0=$(lanes und "$s")
check "lanes: an open milestone (lanes/<m>/pid alive) is not a candidate; a dead pid's is" '[[ $o0 == "M2|" ]]'
ll inner '[{"id":"a1","milestone":"M1","passes":false},{"id":"a2","milestone":"M1","passes":false},{"id":"b1","milestone":"M2","after":[],"passes":true},{"id":"b2","milestone":"M2","passes":false}]'
nx() { FM next "$LS/$1.json" "$LS/att.json" 2 "$LS/parked.json" ${2:+"$2"} | cut -f1; }
w0=$(nx inner); w2=$(nx inner M2); w1=$(nx inner M1)
ll inner2 '[{"id":"a1","milestone":"M1","passes":true},{"id":"a2","milestone":"M1","passes":false},{"id":"b1","milestone":"M2","after":[],"passes":false},{"id":"b2","milestone":"M2","passes":false}]'
w3=$(nx inner2 M2); w4=$(nx inner2 M1); w5=$(nx inner2 M3)
check "next <m>: a feature without after waits on its own milestone's earlier features only" \
  '[[ $w0 == a1 && $w2 == b2 && $w1 == a1 && $w3 == b1 && $w4 == a2 && -z $w5 ]]'
ll done '[{"id":"a1","milestone":"M1","passes":true},{"id":"b1","milestone":"M2","after":[],"passes":true},{"id":"c1","milestone":"M3","after":[],"passes":false}]'
echo '{"c1":2}' > "$LS/att-gu.json"
s=$(st done); d0=$(lanes done "$s"); touch "$s/verified-M1"; d1=$(FM lanes "$LS/done.json" "$LS/att-gu.json" 2 "$LS/parked.json" "$s" | cut -f1 | paste -sd ' ' -)
check "lanes: a complete unverified milestone is a candidate (to be verified); a given-up one with nothing to try is not" \
  '[[ $d0 == "M1| M2| M3|" && $d1 == M2 ]]'
ll def '[{"id":"a1","milestone":"M1","after":[],"passes":false},{"id":"x1","passes":false},{"id":"a2","milestone":"M1","passes":false}]'
s=$(st def); f0=$(lanes def "$s"); fn=$(nx def default); rm "$s/meta.env"; f1=$(lanes def "$s")
check "lanes: features with no milestone form lane default, listed first; without meta.env the tags name the state dir" \
  '[[ $f0 == "default| M1|" && $fn == x1 && $f1 == "default| M1|" ]] && ll def2 '"'"'[{"id":"x1","passes":true},{"id":"a1","milestone":"M1","passes":false}]'"'"' && [[ $(lanes def2 "$s") == "M1|" ]] && touch "$s/verified-M1" && [[ $(lanes into "$s") == "M2|run/st-def/M1" ]]'
cp "$LS/und.json" "$LS/pass.json"; FM pass "$LS/pass.json" b1; pa=$(jq -c '[.features[].passes]' "$LS/pass.json")
check "pass: F pass <list> <id> flips passes to true and nothing else (the mirror of unpass)" \
  '[[ $pa == "[false,true,false]" ]] && FM unpass "$LS/pass.json" b1 && cmp -s "$LS/pass.json" <(jq . "$LS/und.json")'
check "scope.sh: scope_owns accepts a <m>- role prefix (s<n>, check-<pid>, svc) and nothing else after it" \
  '( source "$HERE/../lib/scope.sh"; scope_owns demo harness-demo-M1-s3.scope && scope_owns demo harness-demo-M1-check-42.scope \
    && scope_owns demo harness-demo-M1-svc.scope && ! scope_owns demo harness-demo-M1-x.scope && ! scope_owns demo harness-demo-s3-extra.scope \
    && ! scope_owns demo harness-demo-M1-M2-svc.scope && ! scope_owns demo harness-demo-M1-svc )'
check "lanes config: MAX_LANES=1 LANE_RESERVE_GB=4 LANE_OPEN_BELOW_5H=70 LANE_REBASE=suite MAX_REBASE_ROUNDS=1 RECORD_PR=end by default; commented in the user template; HARNESS_LANE_POLL in the driver's usage" \
  '( source "$HERE/../lib/config.sh" && HARNESS_CONFIG=/dev/null harness_config /nonexistent \
    && [[ "$MAX_LANES $LANE_RESERVE_GB $LANE_OPEN_BELOW_5H $LANE_REBASE $MAX_REBASE_ROUNDS $RECORD_PR" == "1 4 70 suite 1 end" ]] ) \
  && for v in MAX_LANES=1 LANE_RESERVE_GB=4 LANE_OPEN_BELOW_5H=70 LANE_REBASE=suite MAX_REBASE_ROUNDS=1 RECORD_PR=end; do grep -q "^# $v\b" "$HERE/../templates/user/config.sh" || exit 1; done \
  && sed -n "1,/^set /p" "$HERE/../lib/driver.sh" | grep "HARNESS_LANE_POLL.*10.*suite sets 1" > /dev/null'
ll dflt '[{"id":"d1","passes":false},{"id":"a1","milestone":"M1","passes":false}]'
s=$(st dflt); d0=$(lanes dflt "$s"); FM pass "$LS/dflt.json" d1; d1=$(lanes dflt "$s"); d1d=$(FM deps "$LS/dflt.json" M1)
check "lanes: the default lane (no milestone, never verified) holds later lanes only until its features pass, then never opens" \
  '[[ $d0 == "default|" && $d1 == "M1|" && -z $d1d ]]'
suite_end
