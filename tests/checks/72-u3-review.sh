#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- U3 review (U3-08, docs/plans/2026-10-28-U3-review.md): one check per Important finding, red before its fix ----
# MERGE_POLICY=pr keeps a stub run's code on its lane branches (work-A.txt, none on main): an ended, unmerged run
export HARNESS_GLYPHS=unicode HARNESS_COLOR=never COLUMNS=200 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1
echo 'MERGE_POLICY=pr' >> "$T/user-config.sh"; echo MAX_PARALLEL_RUNS=4 >> "$HARNESS_CONFIG"; Q=$HARNESS_STATE/queue
"$H" start "$T/proj" r1 --spec SPEC.md --foreground > "$T/r1.out" 2>&1
W1=$(source "$HARNESS_STATE/proj/r1/meta.env" && echo "$WT")
sleep 600 & LIVE=$!; echo "$LIVE" >> "$T/left.pids"
L=$HARNESS_STATE/proj/live1; mkdir -p "$L" && echo "$LIVE" > "$L/driver.pid" && printf 'PROJECT_DIR=%q\nWT=/x\nRUN_ID=live1\nSTATE=%q\n' "$T/proj" "$L" > "$L/meta.env"
BRIEF=$'redo `work-A.txt`\nthen the second line'
"$H" start proj --brief "$BRIEF" > "$T/q.out" 2>&1; E=$(ls "$Q"/*-start-proj.args 2> /dev/null | head -1)
check "u3 review: a multi-line --brief is one argument in its queue entry (one line per argument; queue show has it whole)" '
  [[ -f $E ]] && (( $(wc -l < "$E") == 4 )) && "$H" queue show 1 > "$T/qs.out" && grep "then the second line" "$T/qs.out" > /dev/null'
check "u3 review: a continue queued behind a live run keeps a multi-line --brief-file as one --brief" '
  printf "one\ntwo\n" > "$T/bf.txt" && "$H" continue r1 --brief-file "$T/bf.txt" > /dev/null 2>&1 && c=$(ls "$Q"/*-continue-r1.args) &&
  (( $(wc -l < "$c") == 6 )) && [[ $(sed -n 6p "$c") != two ]]; ok=$?; rm -f "$Q"/*-continue-r1.args; (( ok == 0 ))'
kill "$LIVE" 2> /dev/null; rm -rf "$L"
[[ -z $(git -C "$W1" status --porcelain) ]] && echo clean > "$T/w1-before"
HARNESS_QUEUE_POLL=0.2 HARNESS_QUEUE_SETTLE=0 HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. timeout 120 "$HERE/../lib/queue.sh" > "$T/qr.out" 2>&1
N=$(ls "$HARNESS_STATE/proj" | grep -vx 'r1' | head -1); NS=$HARNESS_STATE/proj/$N
check "u3 review: the runner starts that entry with its brief whole (both lines reach the run), not 'unknown option'" '
  [[ -n $N && -f $NS/meta.env ]] && ! grep "unknown option\|^failed: " "$T/qr.out" "$Q/runner.log" > /dev/null &&
  grep -x "then the second line" "$HARNESS_LEDGER/proj/$N/brief.md" > /dev/null'
check "u3 review: an overlap with an ended run records on it in its state only: its worktree stays clean, so the runner's gc removes it" '
  [[ -f $T/w1-before ]] && grep " needs: overlap with $N opened " "$HARNESS_STATE/proj/r1/run.log" > /dev/null &&
  [[ ! -d $W1 ]] && grep "gc proj: + needs: resolved r1/[0-9]* (run removed)" "$Q/runner.log" > /dev/null'
# ---- Minor 5 and 6: a lane alone (its driver gone) holds its project in queue list too, and --until ends the runner ----
L=$HARNESS_STATE/proj/lane1; mkdir -p "$L/lanes/M1" && printf 'PROJECT_DIR=%q\nWT=/x\nRUN_ID=lane1\nSTATE=%q\n' "$T/proj" "$L" > "$L/meta.env"
( exec -a "$HERE/../lib/lane.sh" sleep 600 ) & LANE=$!; echo "$LANE" >> "$T/left.pids"; echo "$LANE" > "$L/lanes/M1/pid"
rm -f "$Q"/*.args; "$H" start proj --brief y > /dev/null 2>&1
check "u3 review: queue list shows held: <project> busy for an entry a live lane holds (as the runner holds it)" '
  "$H" queue list > "$T/ql.out" 2>&1 && grep -E "^ +held: proj busy \(lane1\)$" "$T/ql.out" > /dev/null'
HARNESS_QUEUE_POLL=0.2 HARNESS_HOME=$HERE/.. timeout 10 "$HERE/../lib/queue.sh" "$(( $(date +%s) - 5 ))" > "$T/qu.out" 2>&1; QU=$?
check "u3 review: past --until with only lane-held entries the runner ends (it no longer polls until the lane ends)" '
  (( QU == 0 )) && grep "past the --until time; 1 left queued" "$T/qu.out" > /dev/null'
kill "$LANE" 2> /dev/null
suite_end
