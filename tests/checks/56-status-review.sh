#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- U1-07's review (docs/plans/2026-10-28-U1-review.md): each finding's check, red before its fix ----
status_stubs
CD() { HARNESS_GLYPHS=unicode COLUMNS=${C:-100} "$H" status "$@" 2> "$T/card.err"; }
QS() { HARNESS_GLYPHS=unicode COLUMNS=100 "$H" queue show "$@" 2> "$T/qs.err"; }
Q=$HARNESS_STATE/queue port=7990   # sr numbers the ports it gives past this

check "status review: session counts coding sessions only (no init, verify, retro or limit-refused row) plus the one running" '
  "$H" status running --json > "$T/r.json" && jq -e ".session == 2 and .feature == \"B\"" "$T/r.json" > /dev/null \
  && CD running | grep -x "  now        B · session 2 · attempt 2 of 2 · opus · 30 min in" > /dev/null \
  && CD running | grep -E "^  spend      \\\$[0-9.]+ · 2 sessions · " > /dev/null'
# a session runs from its "session <n> · <id>" line until its "<id> · <model> · passes=" note or its limit note (lane.sh)
lg() { cp "$RL" "$T/log.bak"; for l; do echo "$(date -d "@$(( HARNESS_NOW - ${l%%|*} ))" "+%F %T") ${l#*|}" >> "$RL"; done; }
RL=$HARNESS_STATE/proj/running/run.log
check "status review: between sessions (the newest session has its passes note and row) the run counts its rows and shows no minutes in" '
  m=$T/wt/proj/running/.harness/runs/running/metrics.jsonl; cp "$m" "$T/m.bak"
  MX_AT=600 mx proj running verify:M1 B; lg "600|B · claude-opus-5-5 · passes=false · 20 min · 1/3 passing"
  "$H" status running --json > "$T/b.json"; CD running > "$T/b.out"; cp "$T/m.bak" "$m"; cp "$T/log.bak" "$RL"
  jq -e ".session == 2" "$T/b.json" > /dev/null && grep -x "  now        B · session 2 · attempt 2 of 2 · opus" "$T/b.out" > /dev/null'
check "status review: a session waiting out a limit (its limit note, its row refused) is no live session and has no minutes in" '
  m=$T/wt/proj/running/.harness/runs/running/metrics.jsonl; cp "$m" "$T/m.bak"
  mx proj running refused:B; lg "600|session for B hit a limit (five-hour); not counted; resuming at 01:30"
  "$H" status running --json > "$T/l.json"; CD running > "$T/l.out"; cp "$T/m.bak" "$m"; cp "$T/log.bak" "$RL"
  jq -e ".session == 1" "$T/l.json" > /dev/null && grep -x "  now        B · session 1 · attempt 2 of 2 · opus" "$T/l.out" > /dev/null'
check "status review: two lanes: one lane closing its session leaves the other live (counted, its minutes in)" '
  m=$T/wt/proj/running/.harness/runs/running/metrics.jsonl; cp "$m" "$T/m.bak"
  lg "1700|session 3 · C · claude-opus-5-5" "600|C · claude-opus-5-5 · passes=true · 18 min · 2/3 passing"; MX_AT=600 mx proj running C
  "$H" status running --json > "$T/t.json"; CD running > "$T/t.out"; cp "$T/m.bak" "$m"; cp "$T/log.bak" "$RL"
  jq -e ".session == 3" "$T/t.json" > /dev/null && grep -x "  now        B · session 3 · attempt 2 of 2 · opus · 30 min in" "$T/t.out" > /dev/null'
check "status review: a feature list without milestones shows its features under default, never undefined" '
  sr proj nomil 3000 done 1200 && echo "{\"features\":[{\"id\":\"A\",\"passes\":true},{\"id\":\"B\",\"passes\":false}]}" > "$T/wt/proj/nomil/.harness/runs/nomil/feature_list.json" \
  && CD nomil > "$T/n.out" && grep -x "  milestones default 1/2" "$T/n.out" > /dev/null && ! grep undefined "$T/n.out" > /dev/null \
  && "$H" status nomil --json | jq -e ".features.total == 2" > /dev/null'
check "status review: a queue entry with an out-of-range --until-epoch shows it as given; status and queue list and show still print" '
  printf "%s\n" start "$T/proj2" --until-epoch 99999999999999999 > "$Q/0009-start-proj2.args"
  "$H" status > /dev/null 2> "$T/e1" && "$H" queue list > /dev/null 2> "$T/e2" && QS 3 > "$T/s3.out"; r=$?; rm -f "$Q/0009-start-proj2.args"
  (( r == 0 )) && ! grep -i error "$T/e1" "$T/e2" "$T/qs.err" > /dev/null && grep -x "  until      99999999999999999" "$T/s3.out" > /dev/null'
check "status review: queue show shortens the home directory in spec and brief to a tilde" '
  printf "%s\n" start "$T/proj2" --spec "$T/proj2/docs/s.md" --brief "from $T/b.md" > "$Q/0009-start-proj2.args"
  HOME=$T QS 3 > "$T/h.out"; rm -f "$Q/0009-start-proj2.args"
  grep -x "  spec       ~/proj2/docs/s.md" "$T/h.out" > /dev/null && grep -x "  brief      from ~/b.md" "$T/h.out" > /dev/null'
check "status review: harness queue show takes --parked before or after the number" '
  QS --parked 1 > "$T/p1.out" && QS 1 --parked > "$T/p2.out" && cmp -s "$T/p1.out" "$T/p2.out" && sed -n 1p "$T/p1.out" | grep "proj2-next" > /dev/null'
check "status review: a lane now line loses its control bytes in the card and in the view's lane rows" '
  L=$HARNESS_STATE/proj/running/lanes; cp "$L/M1/now" "$T/now.bak"; printf "B \033[31m· session 2\n" > "$L/M1/now"; cp -r "$L/M1" "$L/M2"
  CD running -v > "$T/c.out"; HARNESS_GLYPHS=unicode COLUMNS=100 "$H" status > "$T/v.out"; cp "$T/now.bak" "$L/M1/now"; rm -rf "$L/M2"
  ! grep $'"'"'\033'"'"' "$T/c.out" "$T/v.out" > /dev/null && grep "lane M1 · B  \[31m· session 2" "$T/c.out" > /dev/null \
  && grep -x "    lane M2 · B  \[31m· session 2" "$T/v.out" > /dev/null'

suite_end
