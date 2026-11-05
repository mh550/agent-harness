#!/usr/bin/env bash
# Usage: gate.sh <label> — no other run and no other suite, waiting up to 30 min; the state and the load printed beside the row
waited=0
while :; do
  st=$(harness status 2> /dev/null); run=$(grep -c '^● ' <<< "$st"); other=$(grep '^● ' <<< "$st" | grep -vc 'agent-harness-2026-11-05 '); q=$(sed -n 's/^QUEUED \([0-9]*\).*/\1/p' <<< "$st")
  su=$(pgrep -fc '^([^ ]*/)?bash ([^ ]*/)?tests/run\.sh')
  [[ $other == 0 && ${q:-0} == 0 && $su == 0 ]] && { clear=yes; break; }
  (( waited >= 1800 )) && { clear=NO; break; }
  sleep 180; waited=$(( waited + 180 ))
done
echo "gate $1: $(date +%H:%M:%S) clear=$clear running=$run other=$other queued=${q:-?} suites=$su waited=${waited}s load=$(cut -d' ' -f1-3 /proc/loadavg)"
