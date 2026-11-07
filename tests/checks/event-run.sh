#!/usr/bin/env bash
# tier: slow
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the event hook on stub runs (A1-03): each notify call site names its kind, so a park, a blocked run end and the
# debrief go to EVENT_URL as v1 events and everything else to ntfy; a refused event falls back to the same ntfy post.
# Plan: docs/plans/2026-11-07-A1-event-hook.md §3. Every run shares $T/curl.log and $HARNESS_STATE/events ----
EU=https://n8n.example/webhook/harness-event
events() { awk 'BEGIN { RS = "===\n" } index($0, "Content-Type: application/json") { n = split($0, l, "\n")
  for (i = 1; i < n; i++) if (l[i] == "--data-binary") { print l[i + 1]; break } }' "$T/curl.log" 2> /dev/null; }   # every POSTed event, one JSON a line
evs() { events | jq -sc "$1" 2> /dev/null; }   # <jq over the POSTed events>
kept() { jq -sc "$1" "$HARNESS_STATE"/events/*/event.json 2> /dev/null; }   # <jq over the kept events>
hv() { sed -n "s/^$2: //p" <<< "$1"; }   # <curl record> <header>: its value
nrec() { curl_with "Title: [$1] B needs you" | sed -E "s/$1/RUN/g; s/[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2})?/TS/g"; }   # <run>: its park's ntfy record, normalised
ON=(STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1)
PARK=(STUB_PARK=B STUB_INDEPENDENT_M2=1 "${ON[@]}")
withurl() { cp "$T/base-config.sh" "$T/user-config.sh"; echo "EVENT_URL=$EU" >> "$T/user-config.sh"; }

# a park the hook takes (the stub answers 200): one park event, no ntfy post of it
withurl
env "${PARK[@]}" "$H" start "$T/proj" evp --spec SPEC.md --foreground > "$T/evp.out" 2>&1
P=$(evs 'map(select(.kind == "park" and .run == "evp"))') PID=$(jq -r '.[0].id // empty' <<< "$P" 2> /dev/null)
check "event run: a park posts one park event with its feature, run, project and title, and no ntfy" \
  '[[ $(jq length <<< "$P") == 1 ]] && jq -e ".[0] | .feature == \"B\" and .project == \"proj\" and .title == \"[evp] B needs you\" and .context == null and .v == 1" <<< "$P" > /dev/null \
   && [[ $(kept "map(select(.id == \"$PID\")) | length") == 1 ]] && grep -F "event → n8n: park $PID" "$HARNESS_STATE/proj/evp/run.log" > /dev/null \
   && [[ $(curl_count "Title: [evp] B needs you") == 0 ]] && ! hlog evp | grep -F "event hook failed" > /dev/null'

# the same park refused (500): the event, then today's ntfy post with the event's fields, and a note
STUB_EVENT=500 env "${PARK[@]}" "$H" start "$T/proj" evf --spec SPEC.md --foreground > "$T/evf.out" 2>&1
E=$(kept 'map(select(.kind == "park" and .run == "evf")) | .[0]') N=$(curl_with "Title: [evf] B needs you")
check "event run: a park the hook refuses reaches ntfy with the event's fields, noted" \
  '[[ $(evs "map(select(.kind == \"park\" and .run == \"evf\")) | length") == 1 && -n $N && $E != null ]] \
   && [[ $(hv "$N" Title) == "$(jq -r .title <<< "$E")" && $(hv "$N" Priority) == "$(jq -r .priority <<< "$E")" ]] \
   && [[ $(hv "$N" Click) == "$(jq -r .click <<< "$E")" && $(hv "$N" Actions) == "$(jq -r .actions <<< "$E")" ]] \
   && [[ $(curl_body "Title: [evf] B needs you") == "$(jq -r .body <<< "$E")" ]] \
   && hlog evf | grep -F "event hook failed (500): park; sent to ntfy" > /dev/null'

# and again with EVENT_URL unset: the ntfy post is the fallback's, byte for byte but for the run id and the times
cp "$T/base-config.sh" "$T/user-config.sh"
env "${PARK[@]}" "$H" start "$T/proj" evu --spec SPEC.md --foreground > "$T/evu.out" 2>&1
check "event run: with EVENT_URL unset a park's ntfy post is the fallback's" \
  '[[ -n $(nrec evu) && $(evs "map(select(.run == \"evu\")) | length") == 0 ]] && diff <(nrec evf) <(nrec evu) > /dev/null'

# a given-up feature: the run ends blocked on A, which Michael must act on (needs-driver.sh's gu run)
withurl
env STUB_GIVE_UP=A "${ON[@]}" "$H" start "$T/proj" evg --spec SPEC.md --foreground > "$T/evg.out" 2>&1
check "event run: a blocked run end posts a blocked event, feature null" \
  '[[ $(evs "map(select(.kind == \"blocked\" and .run == \"evg\")) | length") == 1 ]] \
   && jq -e ".[0] | .feature == null and .title == \"[evg] ended: blocked on A\" and .project == \"proj\" and .priority == \"high\"" <<< "$(evs "map(select(.kind == \"blocked\" and .run == \"evg\"))")" > /dev/null \
   && [[ $(curl_count "Title: [evg] ended: blocked on A") == 0 ]]'

# a run that ends done, EVENT_URL set: its start and its end are ntfy's alone
env "${ON[@]}" "$H" start "$T/proj" evd --spec SPEC.md --foreground > "$T/evd.out" 2>&1
check "event run: started and a done run's end reach ntfy alone" \
  'grep -q "^done" "$HARNESS_STATE/proj/evd/ended" && [[ $(curl_count "Title: [evd] ended: done") == 1 && $(curl_count "[evg] started: ") == 1 && $(curl_count "[evd] started: ") == 1 ]] \
   && [[ $(evs "map(select(.run == \"evd\")) | length") == 0 && $(evs "map(select(.kind == \"started\" or .kind == \"ended\" or (.body | test(\"started: \")))) | length") == 0 ]]'

# the debrief after those runs (stub claude, as queue-debrief.sh runs it by hand): one debrief event, no run in it
"$H" debrief > "$T/debrief.out" 2>&1
D=$(evs 'map(select(.kind == "debrief"))') DID=$(jq -r '.[0].id // empty' <<< "$D" 2> /dev/null)
check "event run: the debrief posts a debrief event with null project, run and feature" \
  '[[ $(jq length <<< "$D") == 1 ]] && jq -e ".[0] | .project == null and .run == null and .feature == null and .title == \"harness debrief\"" <<< "$D" > /dev/null \
   && grep -F "event → n8n: debrief $DID" "$HARNESS_STATE/queue/runner.log" > /dev/null && [[ $(curl_count "Title: harness debrief") == 0 ]]'
suite_end
