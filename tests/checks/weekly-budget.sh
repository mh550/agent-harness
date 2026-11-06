#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# A section of the queue and debrief file (tests/checks/queue-debrief.sh) until the shape cut it out
# (decisions/2026-11-05-suite-shape): it reads no run of that file, so it needs no replay. What it had there, and has here:
# the plain user config the debrief sections end on, and the queue's directory by name.
echo 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"
Q=$HARNESS_STATE/queue
# ---- run 17: the 7-day window past WEEKLY_STOP_AT: the run stops before its next session; the queue starts nothing ----
# HARNESS_COUNT_HOLD: the lane's weekly exit lands between the coordinator's lane count and its end check, the window
# that ended this run "no feature left to try" now and then (R1-05; decisions/2026-10-29-lane-count-end-check)
HARNESS_COUNT_HOLD=1 STUB_WEEKLY=0.9 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" weekly --spec SPEC.md --foreground > "$T/run17.out" 2>&1
check "the weekly budget ends a run after the session that crossed it" 'grep -q "^weekly budget (7-day window at 90%" "$HARNESS_STATE/proj/weekly/ended" && [[ $(grep -c attempt "$T/scratch/proj/weekly/sessions.log") == 1 ]]'
"$H" queue add "$T/proj" --spec SPEC.md > /dev/null
HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$T/queue5.out" 2>&1
check "the queue starts no run past the weekly budget" 'grep -q "7-day window at 90%" "$T/queue5.out" && [[ $(ls "$Q"/*.args | wc -l) == 1 ]]'
echo 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1 WEEKLY_STOP_AT=95' > "$T/user-config.sh"
check "WEEKLY_STOP_AT raises the bar"     '( source "$HERE/../lib/config.sh" && harness_config /nonexistent && [[ $WEEKLY_STOP_AT == 95 ]] && ! weekly_over "$HARNESS_STATE/USAGE_7D" > /dev/null )'
rm -f "$Q"/*.args "$HARNESS_STATE/USAGE_7D"; echo 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"

suite_end
