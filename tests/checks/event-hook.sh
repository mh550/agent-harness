#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the event hook (lib/notify.sh notify_event, lib/notify.mjs event): a routed kind goes to EVENT_URL as v1 JSON
# first, ntfy only when that isn't a 2xx; one sourced notify per case, its curl.log kept as $T/eh-<case>.log ----
EU=https://n8n.example/webhook/harness-event
# eh <case> '<setup code>' [<field>…]: the fixed park notification plus <field>s, in a subshell after <setup code>; its
# curl.log, log lines, notes, NOTIFY_CMD calls and return code land in $T/eh-<case>.{log,out,note,cmd,rc}
eh() { local c=$1 s=$2; shift 2; rm -f "$T/curl.log"
  ( NTFY_URL=https://ntfy.example/t NTFY_TOKEN=tok-secret-123 NOTIFY_CMD="" EVENT_URL="" EVENT_TIMEOUT=5 RUN_ID=r1 PROJECT_NAME=proj
    log() { echo "$*" >> "$T/eh-$c.out"; }; note() { echo "$*" >> "$T/eh-$c.note"; }
    eval "$s"; source "$HERE/../lib/notify.sh"
    notify "needs Michael: B · x" title="[r1] B needs you" body="PARKED: x" priority=high click=https://e.test/c \
      actions="view, Edit, https://e.test/e" feature=B "$@"; echo $? > "$T/eh-$c.rc" )
  mv "$T/curl.log" "$T/eh-$c.log" 2> /dev/null || : > "$T/eh-$c.log"; }
rec() { awk -v n="$2" 'BEGIN { RS = "===\n" } NR == n { printf "%s===\n", $0 }' "$T/eh-$1.log"; }   # <case> <n>: its n-th call
recs() { awk 'BEGIN { RS = "===\n" } END { print NR }' "$T/eh-$1.log"; }   # how many calls
posted() { rec "$1" 1 | sed -n '/^--data-binary$/{n;p;q}'; }   # the event JSON the first call carried
hdr() { rec "$1" 2 | sed -n "s/^$2: //p"; }   # a header's value in the case's ntfy call (its second)
url() { rec "$1" "$2" | tail -2 | sed -n 1p; }   # <case> <n>: the URL its n-th call went to
ntfy_data() { rec "$1" 2 | sed '1,/^--data-binary$/d' | sed '$d' | sed '$d'; }   # its data: between --data-binary and the URL

eh a 'EVENT_URL=""' kind=park
eh b "EVENT_URL=$EU" kind=park
eh c "EVENT_URL=$EU; export STUB_EVENT=500" kind=park
eh d "EVENT_URL=$EU; export STUB_EVENT=timeout" kind=park
eh e "EVENT_URL=$EU" kind=ended
eh f "EVENT_URL=$EU"
eh j1 "EVENT_URL=$EU NTFY_URL=''; NOTIFY_CMD='echo \"\$1\" >> $T/eh-j1.cmd'" kind=park
eh j2 "EVENT_URL=$EU NTFY_URL=''; export STUB_EVENT=500; NOTIFY_CMD='echo \"\$1\" >> $T/eh-j2.cmd'" kind=park
eh k "EVENT_URL=$EU; ask() { return 1; }" kind=park
id_b=$(posted b | jq -r .id 2> /dev/null)
check "event hook: EVENT_URL unset, a park goes to ntfy alone" \
  '[[ $(recs a) == 1 ]] && [[ $(url a 1) == https://ntfy.example/t ]] && [[ $(rec a 1) == *"Title: [r1] B needs you"* ]]'
check "event hook: a received park is one POST to EVENT_URL, v1 JSON, no token" \
  '[[ $(recs b) == 1 ]] && [[ $(url b 1) == "$EU" ]] && rec b 1 | grep -Fx "Content-Type: application/json" > /dev/null \
   && posted b | jq -e ".v == 1 and .kind == \"park\" and .feature == \"B\" and .run == \"r1\" and .project == \"proj\"" > /dev/null \
   && ! grep -i "^Authorization" "$T/eh-b.log" > /dev/null && ! grep -F tok-secret-123 "$T/eh-b.log" > /dev/null \
   && ! grep -Fx https://ntfy.example/t "$T/eh-b.log" > /dev/null && [[ $id_b =~ ^[0-9a-f-]{36}$ ]] && grep -Fx "event → n8n: park $id_b" "$T/eh-b.out" > /dev/null'
check "event hook: a 500 falls back to the same ntfy post, and notes it" \
  '[[ $(recs c) == 2 ]] && [[ $(url c 1) == "$EU" ]] && diff <(rec c 2) <(rec a 1) > /dev/null \
   && [[ $(cat "$T/eh-c.note") == "event hook failed (500): park; sent to ntfy" ]]'
check "event hook: a timeout falls back to the same ntfy post, and notes curl's exit" \
  '[[ $(recs d) == 2 ]] && [[ $(rec d 1 | sed -n "/^--max-time\$/{n;p;q}") == 5 ]] && ! rec d 1 | grep -Fx -e --retry -e --fail > /dev/null \
   && diff <(rec d 2) <(rec a 1) > /dev/null && [[ $(cat "$T/eh-d.note") == "event hook failed (curl exit 28): park; sent to ntfy" ]]'
check "event hook: a kind that isn't routed goes to ntfy alone with EVENT_URL set" \
  'diff "$T/eh-e.log" "$T/eh-a.log" > /dev/null && [[ ! -e $T/eh-e.note ]]'
check "event hook: no kind is other, ntfy alone" \
  'diff "$T/eh-f.log" "$T/eh-a.log" > /dev/null && [[ ! -e $T/eh-f.note ]]'
check "event hook: notify returns 0 received, refused and timed out" \
  '[[ $(cat "$T/eh-b.rc" "$T/eh-c.rc" "$T/eh-d.rc" "$T/eh-k.rc" | tr -d "\n") == 0000 ]]'
check "event hook: the received event is kept under events/<id>/" \
  '[[ -n $id_b ]] && [[ $(cat "$HARNESS_STATE/events/$id_b/event.json") == "$(posted b)" ]]'
check "event hook: the fallback event carries ntfy's title, body, click, actions and priority" \
  'e=$(posted c); [[ $(jq -r .title <<< "$e" 2> /dev/null) == "$(hdr c Title)" && $(jq -r .click <<< "$e") == "$(hdr c Click)" \
   && $(jq -r .actions <<< "$e") == "$(hdr c Actions)" && $(jq -r .priority <<< "$e") == "$(hdr c Priority)" \
   && $(jq -r .body <<< "$e") == "$(ntfy_data c)" && $(jq -r .body <<< "$e") == "PARKED: x" ]]'
check "event hook: NOTIFY_CMD is not called for a received event, and is for a refused one" \
  '[[ $(recs j1) == 1 && ! -e $T/eh-j1.cmd && $(recs j2) == 1 && $(cat "$T/eh-j2.cmd") == "needs Michael: B · x" ]] && grep -F "event → n8n: park" "$T/eh-j1.out" > /dev/null'
check "event hook: an event node can't build is noted and sent to ntfy" \
  'diff "$T/eh-k.log" "$T/eh-a.log" > /dev/null && [[ $(cat "$T/eh-k.note") == "event hook failed (no event): park; sent to ntfy" ]]'

suite_end
