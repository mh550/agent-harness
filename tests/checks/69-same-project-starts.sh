#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- same-project starts (U3-05): a plain start or continue queues behind a live run of its project, before it ----
# ---- changes any state; --now, --foreground and the runner's starts (which pass --now) start anyway ----
echo MAX_PARALLEL_RUNS=4 >> "$HARNESS_CONFIG"   # room to spare: only the project rule queues here
sleep 600 & LIVE=$!; echo "$LIVE" >> "$T/left.pids"
L=$HARNESS_STATE/proj/live1; mkdir -p "$L" && echo "$LIVE" > "$L/driver.pid" && printf 'PROJECT_DIR=%q\nWT=/x\nRUN_ID=live1\nSTATE=%q\n' "$T/proj" "$L" > "$L/meta.env"
Q=$HARNESS_STATE/queue PAST=$(( $(date +%s) - 1 ))
MSG="live1 is running on proj: queued (the runner starts it when that run ends; --now starts it anyway)"
tended() { local i; for i in $(seq 600); do [[ -f $1/ended && ! -f $1/driver.pid ]] && return 0; sleep 0.1; done; return 1; }   # ≤ 60 s

check "same-project starts: start proj --brief x while a run of proj is alive queues it, prints why, and starts nothing" '
  o=$("$H" start proj --brief x 2>&1) && [[ $o == "$MSG" ]] && f=$(ls "$Q"/*-start-proj.args) &&
  [[ $(paste -sd" " "$f") == "start $T/proj --brief x" ]] && [[ $(ls "$HARNESS_STATE/proj") == live1 ]] &&
  grep " queued behind live1: ${f##*/}\$" "$Q/runner.log" > /dev/null'
check "same-project starts: a run id and its options go into the entry as the MAX_PARALLEL_RUNS branch writes them" '
  rm -f "$Q"/*.args; o=$("$H" start "$T/proj" q2 --spec SPEC.md --until-epoch 4000000000 2>&1) && [[ $o == "$MSG" ]] &&
  [[ $(cat "$Q"/*-start-proj.args | paste -sd" ") == "start $T/proj q2 --spec SPEC.md --until-epoch 4000000000" ]] && [[ ! -e $HARNESS_STATE/proj/q2 ]]'
"$H" start proj nowrun --spec SPEC.md --until-epoch "$PAST" --now --no-supervisor > "$T/now.out" 2>&1; tended "$HARNESS_STATE/proj/nowrun"
check "same-project starts: --now starts it anyway (the runner passes --now: its starts are unchanged)" '
  grep "^started tmux session h-nowrun " "$T/now.out" > /dev/null && [[ -f $HARNESS_STATE/proj/nowrun/meta.env ]] && (( $(ls "$Q"/*.args | wc -l) == 1 ))'
"$H" start proj fg1 --spec SPEC.md --until-epoch "$PAST" --foreground > "$T/fg.out" 2>&1
check "same-project starts: --foreground starts it anyway (harness merge runs that way)" '
  grep " run fg1 on harness/fg1 " "$HARNESS_STATE/proj/fg1/run.log" > /dev/null && [[ -f $HARNESS_STATE/proj/fg1/ended ]] && ! grep "queued" "$T/fg.out" > /dev/null'
E=$(cat "$HARNESS_STATE/proj/fg1/ended")
check "same-project starts: continue <ended run> queues continue <run> --queued --requested and leaves its ended in place" '
  rm -f "$Q"/*.args; o=$("$H" continue fg1 2>&1) && [[ $o == "$MSG" ]] && [[ $(cat "$HARNESS_STATE/proj/fg1/ended") == "$E" ]] &&
  [[ $(cat "$Q"/*-continue-fg1.args | paste -sd" ") == "continue fg1 --queued --requested" ]]'
check "same-project starts: a second continue replaces the queued entry with its options (one entry)" '
  o=$("$H" continue fg1 --keep-attempts --brief more 2>&1) && [[ $o == "$MSG" ]] && (( $(ls "$Q"/*.args | wc -l) == 1 )) &&
  [[ $(cat "$Q"/*-continue-fg1.args | paste -sd" ") == "continue fg1 --queued --requested --keep-attempts --brief more" ]]'
check "same-project starts: a continue queues --until as --until-epoch and --brief-file as its text (as a start queues them)" '
  echo "from the file" > "$T/bf.txt"; o=$("$H" continue fg1 --until 23:59 --brief-file "$T/bf.txt" 2>&1) && [[ $o == "$MSG" ]] &&
  [[ $(cat "$Q"/*-continue-fg1.args | paste -sd" ") =~ ^"continue fg1 --queued --requested --until-epoch "[0-9]{10}" --brief from the file"$ ]]'
L2=$HARNESS_STATE/proj/live2; mkdir -p "$L2" && echo "$LIVE" > "$L2/driver.pid" && printf 'PROJECT_DIR=%q\nWT=/x\nRUN_ID=live2\nSTATE=%q\n' "$T/proj" "$L2" > "$L2/meta.env"
check "same-project starts: a given run id is refused as before (already running) while another run of the project is alive" '
  rm -f "$Q"/*.args; "$H" start proj live2 --brief x > "$T/l2.out" 2>&1; (( $? == 1 )) && grep "run live2 is already running" "$T/l2.out" > /dev/null &&
  ! ls "$Q"/*.args > /dev/null 2>&1'
rm -rf "$L2"
git init -q -b main "$T/_x" && git -C "$T/_x" commit -q --allow-empty -m init
check "same-project starts: an id auto_id makes is still checked (a project named _x)" '
  "$H" start "$T/_x" --brief x > "$T/ux.out" 2>&1; (( $? == 1 )) && grep "run-id: letters, digits" "$T/ux.out" > /dev/null && [[ ! -e $HARNESS_STATE/_x ]]'
kill "$LIVE" 2> /dev/null; rm -f "$L/driver.pid"
( exec -a "$HERE/../lib/lane.sh" sleep 600 ) & LANE=$!; echo "$LANE" >> "$T/left.pids"; mkdir -p "$L/lanes/M1"; echo "$LANE" > "$L/lanes/M1/pid"
check "same-project starts: a run whose driver is gone but a lane lives keeps its project busy" '
  rm -f "$Q"/*.args; o=$("$H" start proj --brief y 2>&1) && [[ $o == "$MSG" ]] && [[ -f $(ls "$Q"/*-start-proj.args) ]]'
( sleep 2; touch "$Q/STOP" ) &
HARNESS_QUEUE_POLL=0.2 HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. timeout 30 "$HERE/../lib/queue.sh" > "$T/qlane.out" 2>&1
check "same-project starts: the runner holds that entry too while the lane lives (and waits for it, not done)" '
  grep "holding .*(proj): that project has a run going" "$T/qlane.out" > /dev/null && ! grep "starting:\|queue empty" "$T/qlane.out" > /dev/null &&
  grep "stopped by harness queue stop" "$T/qlane.out" > /dev/null && [[ -f $(ls "$Q"/*-start-proj.args) ]]'
kill "$LANE" 2> /dev/null
check "same-project starts: an ended run of the project holds nothing (continue --foreground runs)" '
  rm -f "$Q"/*.args; "$H" continue fg1 --foreground --until-epoch "$PAST" > "$T/fg2.out" 2>&1 &&
  (( $(grep -c " run fg1 on harness/fg1 " "$HARNESS_STATE/proj/fg1/run.log") == 2 )) && ! ls "$Q"/*.args > /dev/null 2>&1'
suite_end
