#!/usr/bin/env bash
# tier: slow
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the memory event (docs/specs/2026-11-10-review-surface.md §V1-02): one `memory` notification at the end of
# memory_pr when a PR exists, POSTed as the v2 event when EVENT_URL and EVENT_V2=1 are both set, else the ntfy line.
# memory-review.sh's runs (its seeds, its run helper); every run shares $T/curl.log and $HARNESS_STATE/events ----
EU=https://n8n.example/webhook/harness-event
st() { echo "$HARNESS_STATE/proj/$1"; }
rec() { echo "$T/wt/proj/$1/.harness/runs/$1"; }
mposts() { awk -v r="\"kind\":\"memory\",\"project\":\"proj\",\"run\":\"$1\"" 'BEGIN { RS = "===\n" } index($0, "Content-Type: application/json") && index($0, r) { n = split($0, l, "\n")
  for (i = 1; i < n; i++) if (l[i] == "--data-binary") { print l[i + 1]; break } }' "$T/curl.log" 2> /dev/null; }   # <run> → its POSTed memory events, one a line
murl() { awk -v r="\"kind\":\"memory\",\"project\":\"proj\",\"run\":\"$1\"" 'BEGIN { RS = "===\n" } index($0, "Content-Type: application/json") && index($0, r) { n = split($0, l, "\n"); print l[n - 1] }' "$T/curl.log" 2> /dev/null; }   # <run> → the URL each was POSTed to
mline() { hlog "$1" | sed -n "s/^- [0-9-]* [0-9:]* · \(memory: \(facts\|review none\) .*\)$/\1/p"; }   # <run> → its `memory:` note's text
at() { awk -v k="$1" 'BEGIN { RS = "===\n" } index($0, k) { print NR; exit }' "$T/curl.log" 2> /dev/null; }   # the curl call number of the first containing $1
hv() { sed -n "s/^$2: //p" <<< "$1"; }   # <curl record> <header>: its value
rl() { grep -n -m1 -F -- "$2" "$(st "$1")/run.log" | cut -d: -f1; }   # <run> <text>: run.log's first line holding it
nrec() { curl_with "Title: [$1] ended: " | sed -E "s/$1/RUN/g; s/[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}(:[0-9]{2})?/TS/g"; }   # <run>: its end's ntfy record, normalised
pol() { cp "$T/base-config.sh" "$T/user-config.sh" && echo "MEMORY_POLICY=$1 RECORD_PR=end" >> "$T/user-config.sh"; shift; for a; do echo "$a" >> "$T/user-config.sh"; done; }   # <policy> [VAR=value…]
w=$T/seed; git clone -q "$T/origin.git" "$w" && printf '# proj\nrules\n\n## Code rules\n\n- bash, set -uo pipefail\n\n## Gotchas\n\n- seeded gotcha 1 (seed 2026-11-01)\n' > "$w/CLAUDE.md" \
  && git -C "$w" -c user.name=m -c user.email=m@test commit -qam "CLAUDE.md with two sections" && git -C "$w" push -q origin HEAD:main
main0=$(git -C "$T/origin.git" rev-parse main)
{ printf '# proj\nrules\n\n## Code rules\n\n- bash, set -uo pipefail\n\n## Gotchas\n\n'; for i in $(seq -w 1 15); do echo "- seeded gotcha $i: the seeded project keeps its fact number $((10#$i)) (seed 2026-11-01)"; done; } > "$w/CLAUDE.md" \
  && git -C "$w" -c user.name=m -c user.email=m@test commit -qam "CLAUDE.md with 15 gotchas" && git -C "$w" push -q origin HEAD:refs/heads/seed15
seed15=$(git -C "$T/origin.git" rev-parse seed15); base=$seed15
run() {   # <run> [VAR=value…]: a stub run from $base, memory-review.sh's
  local r=$1; shift; git -C "$T/origin.git" update-ref refs/heads/main "$base"
  env "$@" STUB_FACTS=A,B STUB_PROPOSE=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" "$r" --spec SPEC.md --foreground > "$T/$r.out" 2>&1
  mv "$T/gh.log" "$T/gh-$r.log" 2> /dev/null
}

# mev: at 15 Gotchas a replace, an eviction the reviewer fails (q2) and a rule, under pr, the switch on (the fixture's run)
pol pr "EVENT_URL=$EU" EVENT_V2=1
run mev STUB_CURATOR_OPS=evict-two STUB_MEMORY_REVIEW=evict-fails
E=$(mposts mev) EID=$(jq -r '.id // empty' <<< "$E" 2> /dev/null)
check "memory event: with EVENT_URL and EVENT_V2=1 a run with a memory PR POSTs one v2 memory event to EVENT_URL, its body the memory: line, and no ntfy post of it" \
  '[[ $(wc -l <<< "$E") == 1 && -n $EID && $(murl mev) == "$EU" ]] \
   && jq -e "(keys_unsorted | length) == 14 and .v == 2 and .kind == \"memory\" and .context == null and (.memory.failures[0].id | test(\"^facts/[0-9]+\$\"))
     and .memory.state == \"open\" and .memory.review == \"ok\"" <<< "$E" > /dev/null \
   && [[ -n $(mline mev) && $(jq -r .body <<< "$E") == "$(mline mev)" && $(curl_count "Title: $(jq -r .title <<< "$E")") == 0 ]] \
   && ! hlog mev | grep -F "context bundle failed" > /dev/null'
check "memory event: run.log says event → n8n: memory <id> after the memory: note; events/<id>/event.json is the POSTed body and the record keeps memory-event.json, its memory object" \
  'n=$(rl mev "$(mline mev)") e=$(rl mev "event → n8n: memory $EID") && [[ -n $n && -n $e ]] && (( n < e )) \
   && [[ $(cat "$HARNESS_STATE/events/$EID/event.json") == "$E" && -s $(rec mev)/memory-event.json ]] \
   && jq -e --argjson e "$E" ". == \$e.memory" "$(rec mev)/memory-event.json" > /dev/null'
# the fixture n8n-home copies is this run's event with its placeholders (tests/unit/notify.test.mjs's command)
check "memory event: the run's events/<id>/event.json with its id, at and PR URLs as placeholders is tests/fixtures/n8n-event-v2-memory.json byte for byte" \
  'f=$(jq -r .memory.pr <<< "$E") r=$(jq -r .memory.rules_pr <<< "$E") && [[ $f == http* && $r == http* ]] \
   && jq -c --arg f "$f" --arg r "$r" ".id = \"<uuid>\" | .at = \"<ISO 8601>\" | walk(if type == \"string\" then split(\$f) | join(\"<facts PR url>\") | split(\$r) | join(\"<rules PR url>\") else . end)" \
      "$HARNESS_STATE/events/$EID/event.json" > "$T/mev-placed.json" && cmp "$T/mev-placed.json" "$HH/tests/fixtures/n8n-event-v2-memory.json"'

# mvu: EVENT_URL set, EVENT_V2 unset; mvn: both unset → the ntfy line, no POST, no failure note
pol pr "EVENT_URL=$EU"
run mvu STUB_CURATOR_OPS=evict-two STUB_MEMORY_REVIEW=evict-fails
pol pr
run mvn STUB_CURATOR_OPS=evict-two STUB_MEMORY_REVIEW=evict-fails
check "memory event: with EVENT_V2 unset (EVENT_URL set or not) the memory notification is one ntfy post: the title, the memory: line, the facts PR's click and both PRs' actions; no POST, no failure note" \
  'ok=1; for r in mvu mvn; do N=$(curl_with "Title: [$r] memory: ") m=$(st "$r")/memory.json; f=$(jq -r .pr "$m") q=$(jq -r .rules_pr "$m"); \
     [[ -z $(mposts "$r") && $(curl_count "Title: [$r] memory: ") == 1 && $(hv "$N" Title) == "[$r] memory: 2 held · 1 failed" ]] || ok=0; \
     [[ $f == http* && $q == http* && $(hv "$N" Click) == "$f" && $(hv "$N" Actions) == "view, Facts PR, $f; view, Rules PR, $q" ]] || ok=0; \
     [[ -n $(mline "$r") && $(curl_body "Title: [$r] memory: ") == "$(mline "$r")" ]] || ok=0; \
     ! hlog "$r" | grep -F "event hook failed" > /dev/null || ok=0; grep -F "notified: [$r] memory: 2 held · 1 failed" "$(st "$r")/run.log" > /dev/null || ok=0; done; (( ok ))'
check "memory event: the run end notification is the same bytes with the memory event POSTed and with no switch set" \
  'a=$(at "Title: [mev] ended: ") b=$(at "\"run\":\"mev\"") && [[ -n $a && -n $b && -n $(nrec mev) ]] && (( a < b )) && diff <(nrec mev) <(nrec mvn) > /dev/null'

# mvr: the switch on and the intake refusing it (422) → the POST, then the ntfy post and the one note
pol pr "EVENT_URL=$EU" EVENT_V2=1
run mvr STUB_EVENT=422 STUB_CURATOR_OPS=evict-two STUB_MEMORY_REVIEW=evict-fails
check "memory event: a memory event the intake refuses (422) falls back to the same ntfy post after the POST, with one event hook failed (422) note" \
  'a=$(at "\"run\":\"mvr\"") b=$(at "Title: [mvr] memory: ") && [[ -n $a && -n $b && $(mposts mvr | wc -l) == 1 && $(curl_count "Title: [mvr] memory: ") == 1 ]] && (( a < b )) \
   && [[ $(curl_body "Title: [mvr] memory: ") == "$(mline mvr)" && $(hlog mvr | grep -c " · event hook failed (422): memory; sent to ntfy$") == 1 ]]'

# mva: three ops all held under auto: the facts PR merges, then the event says so; mvp: a proposal alone, no PR, no
# event; mvx: no review on fact-a: one event titled review none; mvo: a held fact under MERGE_POLICY=off, no PR, no event
base=$main0
pol auto "EVENT_URL=$EU" EVENT_V2=1
run mva STUB_CURATOR_OPS=three-ops STUB_MEMORY_REVIEW=hold
pol pr "EVENT_URL=$EU" EVENT_V2=1
run mvp STUB_CURATOR_OPS=proposal STUB_MEMORY_REVIEW=hold
run mvx STUB_CURATOR_OPS=fact-a STUB_MEMORY_REVIEW=none
pol pr "EVENT_URL=$EU" EVENT_V2=1 MERGE_POLICY=off   # mvo: a reviewed fact and its memory: line, but no PR to send
run mvo STUB_CURATOR_OPS=fact-a STUB_MEMORY_REVIEW=hold
X=$(mposts mvx)
check "memory event: under auto the event is sent after the merge note, state merged; a run with no memory PR sends none and keeps no memory-event.json; a review none is one event titled review none, no failures" \
  'A=$(mposts mva) && jq -e ".memory.state == \"merged\" and .memory.held == 3" <<< "$A" > /dev/null \
   && m=$(rl mva "memory PR merged into main") e=$(rl mva "event → n8n: memory $(jq -r .id <<< "$A")") && [[ -n $m && -n $e ]] && (( m < e )) \
   && ok=1 && for r in mvp mvo; do [[ -z $(mposts "$r") && $(curl_count "Title: [$r] memory: ") == 0 && ! -e $(rec "$r")/memory-event.json ]] || ok=0; done && (( ok )) \
   && hlog mvp | grep -E " · memory PR: none \(" > /dev/null && [[ -n $(mline mvo) ]] && hlog mvo | grep -F " · memory PR: none (MERGE_POLICY=off)" > /dev/null \
   && [[ $(wc -l <<< "$X") == 1 ]] && jq -e --slurpfile m "$(st mvx)/memory.json" ".title == \"[mvx] memory: review none\" and .memory.failures == [] and .memory.review == \$m[0].review and .memory.review != \"ok\"" <<< "$X" > /dev/null'
suite_end
