#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- two lanes (P2-02): admission by headroom, a port per lane, the run's end reaching every lane ----
# M2 is after: [] (STUB_INDEPENDENT_M2), so it may open beside M1. The stub holds every coding session (hold-coding)
# until release-<run> or release-<run>-<id>: C goes first and M2 merges before M1 verifies, so M1's verify merges main
# in and both land (a lane verified while the other merged is P2-03's re-base)
two_both="" mem_c="" cap_end=""
echo 'MAX_LANES=2' >> "$T/user-config.sh"

held
STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" two --spec SPEC.md --foreground > "$T/two.out" 2>&1 & P=$!
wait_for 120 eval '[[ -f $T/held-two-A && -f $T/held-two-C ]]' && two_both=yes
STUB_MEM_CURRENT=52428800 HARNESS_GLYPHS=unicode "$H" status two > "$T/status-two.out" 2>&1   # both sessions' scopes are live (P2-06); the card's lanes field
touch "$T/release-two-C"; wait_for 120 eval 'hlog two | grep -F "· M2 merged into main" > /dev/null'; touch "$T/release-two"; wait "$P"; rm -f "$T/hold-coding"
S=$HARNESS_STATE/proj/two
check "lanes two: with MAX_LANES=2 and M2 after: [], both lanes' sessions run at once and two lanes open before any closes" \
  '[[ $two_both == yes ]] && c=$(ats two "· lane .* closed \(") && [[ -n $c ]] && (( $(hlog two | head -n "$c" | grep -c "· lane .* opened (") == 2 ))'
check "lanes two: M1 opens in slot 0 on the run's port, M2 in slot 1 on the first free one" \
  'hlog two | grep -F "· lane M1 opened (slot 0, port 7950, from " > /dev/null && hlog two | grep -F "· lane M2 opened (slot 1, port 7951, from " > /dev/null \
  && [[ $(cat "$S/lanes/M1/port") == 7950 && $(cat "$S/lanes/M2/port") == 7951 ]]'
check "lanes two: each lane's prompt renders its own port (A: 7950, C: 7951)" \
  'grep -qx "Port: 7950 · scratch directory: \`$T/scratch/proj/two/lanes/M1\`" $S/logs/*-A.prompt.md && grep -qx "Port: 7951 · scratch directory: \`$T/scratch/proj/two/lanes/M2\`" $S/logs/*-C.prompt.md'
check "lanes two: both milestones merge (one pr merge each, no refused merge) and the run ends done" \
  'grep -q "^done" "$S/ended" && on_main run/two/M1 && on_main run/two/M2 && [[ $(grep -c "pr merge" "$T/gh.log") == 2 ]] && ! hlog two | grep -E "merge was refused|moved since" > /dev/null'
check "lanes status: harness status prints one line per open lane (feature, session, port, slot, its units with MemoryCurrent), no bare line for a lane's unit" \
  'grep -Eqx "    lane M1 · A · session [0-9]+ · port 7950 · slot 0 · MemoryCurrent harness-two-M1-s[0-9]+ 50 MB(, .*)?" "$T/status-two.out" \
  && grep -Eqx "    lane M2 · C · session [0-9]+ · port 7951 · slot 1 · MemoryCurrent harness-two-M2-s[0-9]+ 50 MB(, .*)?" "$T/status-two.out" \
  && [[ $(grep -c "^    lane " "$T/status-two.out") == 2 ]] && ! grep -E "^    harness-two-M[12]-" "$T/status-two.out" > /dev/null'
check "lanes summary: the two-lane run's summary.json has lanes {max_open: 2, lane_hours, wall_hours} and report.md its Lanes line" \
  'R=$T/wt/proj/two/.harness/runs/two; jq -e ".lanes.max_open == 2 and (.lanes.lane_hours | type) == \"number\" and .lanes.wall_hours == .time.wall_h" "$R/summary.json" > /dev/null \
  && grep -Ex "\| Lanes \| at most 2 open at once · [0-9.]+ lane hours in [0-9.]+ h wall \|" "$R/report.md" > /dev/null'

# memory: 7 GB available is over MEM_MIN_AVAILABLE_GB (5: no session waits) and under 5 + LANE_RESERVE_GB 4 x 1 open
held; sed 's/^MemAvailable: .*/MemAvailable:    7340032 kB/' "$HERE/fixtures/meminfo.txt" > "$T/meminfo.txt"
HARNESS_MEMINFO=$T/meminfo.txt STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" mem --spec SPEC.md --foreground > "$T/mem.out" 2>&1 & P=$!
wait_for 120 eval '[[ -f $T/held-mem-A ]]'; sleep 4   # sleep-ok: a negative over four polls at 1 s
mem_waits=$(hlog mem | grep -cF "· lane M2 waiting: 7 GB available, under 9 GB (MEM_MIN_AVAILABLE_GB 5 + LANE_RESERVE_GB 4 x 1 open)")
mem_open=$(hlog mem | grep -c "· lane M2 opened (")
cp "$HERE/fixtures/meminfo.txt" "$T/meminfo.txt"   # 9 GB
wait_for 60 eval '[[ -f $T/held-mem-C ]]' && mem_c=yes
touch "$T/release-mem-C"; wait_for 120 eval 'hlog mem | grep -F "· M2 merged into main" > /dev/null'; touch "$T/release-mem"; wait "$P"; rm -f "$T/hold-coding"
check "lanes admission: under the memory reserve the second lane waits, noted once with the figures, and opens once memory is back" \
  '[[ $mem_waits == 1 && $mem_open == 0 && $mem_c == yes ]] && c=$(ats mem "· lane .* closed \(") && o=$(ats mem "· lane M2 opened \(slot 1, ") && (( o < c )) \
  && grep -q "^done" "$HARNESS_STATE/proj/mem/ended"'

# the five-hour window: the newest session's USAGE_5H at 80 %, resetting in an hour, is over LANE_OPEN_BELOW_5H (70)
held; echo "0.80 $(( $(date +%s) + 3600 ))" > "$HARNESS_STATE/USAGE_5H"
STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" u5 --spec SPEC.md --foreground > "$T/u5.out" 2>&1 & P=$!
wait_for 120 eval '[[ -f $T/held-u5-A ]]'; sleep 4   # sleep-ok: a negative over four polls at 1 s
u5_waits=$(hlog u5 | grep -cE "· lane M2 waiting: 5-hour window at 80%, opens under 70% \(resets [0-9]{2}:[0-9]{2}\)$")
u5_open=$(hlog u5 | grep -c "· lane M2 opened (")
touch "$T/release-u5"; wait "$P"; rm -f "$T/hold-coding"
check "lanes admission: with the five-hour window at 80 % the second lane waits, noted once; it opens when the first closes (0 open always admits)" \
  '[[ $u5_waits == 1 && $u5_open == 0 ]] && c=$(ats u5 "· lane M1 closed \(") && o=$(ats u5 "· lane M2 opened \(slot 0, ") && (( c < o )) && grep -q "^done" "$HARNESS_STATE/proj/u5/ended"'
# the same window, with HARNESS_COUNT_HOLD: M1's lane exits after the coordinator's reap and count, before its opens
# (F1-03: M2 opened in M1's slot, admitted as 0 open, before M1's close was noted)
held
HARNESS_COUNT_HOLD=1 STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" uh --spec SPEC.md --foreground > "$T/uh.out" 2>&1 & P=$!
wait_for 120 eval '[[ -f $T/held-uh-A ]]'; touch "$T/release-uh"; wait "$P"; rm -f "$T/hold-coding" "$HARNESS_STATE/USAGE_5H"   # left, it would refuse every later run's second lane
check "lanes admission: a lane that exits after the coordinator's reap is noted closed (its slot free) before another lane opens; M2's session after it" \
  'grep -F "count hold: 1 lane(s) counted, held until gone" "$HARNESS_STATE/proj/uh/run.log" > /dev/null && c=$(ats uh "· lane M1 closed \(M1 merged\)$") \
  && o=$(ats uh "· lane M2 opened \(slot 0, port [0-9]+, from [0-9a-f]+, slot reused\)$") && s=$(ats uh "· context.md for C: ") && [[ -n $c && -n $o && -n $s ]] && (( c < o && o < s )) \
  && grep -q "^done" "$HARNESS_STATE/proj/uh/ended"'

# the run's end reaches every lane: M1's lane ends the run at the session cap; M2's, mid-session, exits 16 after it
held; echo MAX_SESSIONS=2 >> "$T/user-config.sh"
STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" cap --spec SPEC.md --foreground > "$T/cap.out" 2>&1 & P=$!
wait_for 120 eval '[[ -f $T/held-cap-A && -f $T/held-cap-C ]]'; touch "$T/release-cap-A"
wait_for 120 eval '[[ -f $HARNESS_STATE/proj/cap/lanes-end ]]' && cap_end=$(cat "$HARNESS_STATE/proj/cap/lanes-end")
touch "$T/release-cap"; wait "$P"; rm -f "$T/hold-coding"
check "lanes end: a lane's session cap ends the run (lanes-end); the other lane finishes its session and closes, the run is ending" \
  '[[ $cap_end == "session cap (2)" ]] && grep -q "^session cap (2)" "$HARNESS_STATE/proj/cap/ended" && hlog cap | grep -F "· lane M1 closed (session cap (2))" > /dev/null \
  && hlog cap | grep -F "· lane M2 closed (the run is ending (session cap (2)))" > /dev/null && [[ $(jq -s "map(select(.kind == \"coding\")) | length" "$T/wt/proj/cap/.harness/runs/cap/metrics.jsonl") == 2 ]]'

# a usage-limit wait sleeps in slices of at most 60 s: a stop during an hour's window ends the run within a slice,
# with no session started inside the window (before P2 it slept the whole window)
cp "$T/base-config.sh" "$T/user-config.sh"; echo "$(( $(date +%s) + 3600 ))" > "$HARNESS_STATE/LIMIT_UNTIL"
HARNESS_LIMIT_SLEEP=3600 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" lw --spec SPEC.md --foreground > "$T/lw.out" 2>&1 & P=$!
wait_for 120 eval 'hlog lw | grep -F "· usage-limit window (shared by all runs): waiting until " > /dev/null'; lw0=$(date +%s)
touch "$HARNESS_STATE/proj/lw/STOP"; wait "$P"; lw_s=$(( $(date +%s) - lw0 )); rm -f "$HARNESS_STATE/LIMIT_UNTIL"
check "lanes end: a stop during a usage-limit wait ends the run within a 60 s slice and starts no session in the window" \
  '(( lw_s < 90 )) && grep -q "^stopped by Michael" "$HARNESS_STATE/proj/lw/ended" && ! grep -q " coding exit " "$HARNESS_STATE/proj/lw/run.log"'

# unit: the five-hour window from the real capture; admit (lib/scope.sh) on stub files
check "metrics usage: five_hour reads the newest event's five-hour window; the default stays the seven-day one" \
  '[[ $(node "$HERE/../lib/metrics.mjs" usage "$HERE/fixtures/usage-limit.jsonl" five_hour) == "1 1792231800" && $(node "$HERE/../lib/metrics.mjs" usage "$HERE/fixtures/usage-limit.jsonl") == "0.85 1792360800" ]] \
  && ! node "$HERE/../lib/metrics.mjs" usage "$HERE/fixtures/usage-tokens.jsonl" five_hour > /dev/null'
check "lanes admission: admit opens the first lane always, refuses on memory or a live five-hour window, and ignores a window already reset" \
  '( source "$HERE/../lib/scope.sh"; MEM_MIN_AVAILABLE_GB=5 LANE_RESERVE_GB=4 LANE_OPEN_BELOW_5H=70 HARNESS_MEMINFO=$T/meminfo.txt; u=$T/u5.txt
     echo "0.80 $(( $(date +%s) + 600 ))" > "$u"; admit 0 "$u" > /dev/null || exit 1
     [[ $(admit 1 "$u") == five-hour$'"'"'\t'"'"'"5-hour window at 80%, opens under 70% (resets "* ]] || exit 1
     echo "0.99 $(( $(date +%s) - 60 ))" > "$u"; admit 1 "$u" > /dev/null || exit 1; echo "0.69 $(( $(date +%s) + 600 ))" > "$u"; admit 1 "$u" > /dev/null || exit 1
     [[ $(admit 2 "$u") == memory$'"'"'\t'"'"'"9 GB available, under 13 GB (MEM_MIN_AVAILABLE_GB 5 + LANE_RESERVE_GB 4 x 2 open)" ]] && ! admit 2 "$u" > /dev/null )'
check "lanes ports: port_taken counts a live lane's port (pid, svc-up or opening beside it), not a closed lane's" \
  '( source "$HERE/../lib/config.sh"; STATE_ROOT=$T/pt; d=$STATE_ROOT/p/r/lanes/M2; mkdir -p "$d"; echo 7961 > "$d/port"
     ! port_taken 7961 || exit 1; : > "$d/opening"; port_taken 7961 || exit 1; rm "$d/opening"; : > "$d/svc-up"; port_taken 7961 || exit 1
     rm "$d/svc-up"; echo 7962 > "$STATE_ROOT/p/r/port"; port_taken 7962 )'
# unit: a forked child (lane_wait's sleep, killed before its exec) inherits the EXIT traps; it must not run them. The
# driver's ran lanes_term and removed driver.pid mid-run whenever a lane exited between reap and lane_wait (P2 review 1)
trapkid() {   # <file> <state dir>: the file's EXIT trap in a shell whose child is killed at once
  ( STATE=$2 LDIR=$2 RWT=$2 REC=$2; for f in lanes_term scope_stop services_down lanes_services_down; do eval "$f() { :; }"; done
    eval "$(awk "/^trap '/ { on = 1 } on { print } on && /' EXIT\$/ { exit }" "$1")"
    for i in 1 2 3 4 5; do sleep 5 & kill $! 2> /dev/null; wait $! 2> /dev/null; done; trap - EXIT ) 2> /dev/null; }   # sleep-ok: the child killed
check "lanes trap: a killed background child runs neither the driver's nor a lane's EXIT trap (driver.pid stays, no ended, no exit line)" \
  '( d=$T/trap-d; l=$T/trap-l; mkdir -p "$d" "$l"; echo 1 > "$d/driver.pid"; trapkid "$HERE/../lib/driver.sh" "$d"; trapkid "$HERE/../lib/lane.sh" "$l"
     [[ -f $d/driver.pid && ! -e $d/ended && ! -e $l/exit ]] )'
suite_end
