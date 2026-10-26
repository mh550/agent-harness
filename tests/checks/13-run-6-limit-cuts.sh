#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 6: a limit cuts a session off midway: work kept, attempt given back ----
STUB_LIMIT_MIDWAY=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" midway --spec SPEC.md --foreground > "$T/run6.out" 2>&1
check "mid-session limit: attempt given back, work kept" 'hlog midway | grep -q "hit a limit" && [[ $(jq -r .A "$HARNESS_STATE/proj/midway/attempts.json") == 1 ]] && [[ -f $T/wt/proj/midway/half-A.txt ]]'

# ---- run 7: a future window set by another run makes this one wait first ----
# an 11-minute window: over SVC_IDLE_STOP_MIN=10, so the services stop first; a 9-minute one keeps them (L2-04)
echo $(( $(date +%s) + 660 )) > "$HARNESS_STATE/LIMIT_UNTIL"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" waiter --spec SPEC.md --foreground > "$T/run7.out" 2>&1
check "waits for another run's limit window" 'hlog waiter | grep -q "usage-limit window (shared by all runs): waiting"'
check "a usage-limit wait over SVC_IDLE_STOP_MIN stops the services first" 'hlog waiter | grep -B1 "· usage-limit window (shared by all runs): waiting" | head -1 | grep -q "· services stopped (usage-limit wait)$" \
  && [[ -f $T/scratch/proj/waiter/teardown-usage-limit-wait.marker ]]'
echo $(( $(date +%s) + 540 )) > "$HARNESS_STATE/LIMIT_UNTIL"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" waiter9 --spec SPEC.md --foreground > "$T/run7b.out" 2>&1
check "a usage-limit wait under SVC_IDLE_STOP_MIN keeps the services" 'hlog waiter9 | grep -q "usage-limit window (shared by all runs): waiting" && ! hlog waiter9 | grep -q "(usage-limit wait)" \
  && hlog waiter9 | grep -q "· services stopped (done)$"'
rm -f "$HARNESS_STATE/LIMIT_UNTIL"

suite_end
