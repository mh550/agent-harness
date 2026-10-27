#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the retro backlog, pure (M1): lib/backlog.mjs merges proposals, sets a status, orders a listing, imports by id ----
B="node $HERE/../lib/backlog.mjs" BM=$HERE/../lib/backlog.mjs
bk() { mkdir -p "$T/bk"; printf '%s\n' "$2" > "$T/bk/$1"; echo "$T/bk/$1"; }   # <name> <text> → its path
row() { jq -c --arg id "$1" 'map(select(.id == $id))[0]' <(jq -s . "$2"); }      # <id> <store> → its row
P1=$(bk p1.json '[{"id": "new-thing", "title": "a new thing", "evidence": "run r1 retro"}]')
S1=$T/bk/s1.jsonl
check "backlog merge: a new id becomes one proposed row first seen in its run" '
  [[ $($B merge "$S1" "$P1" r1 2026-10-26) == "backlog: 1 new, 0 seen again" ]] && [[ $(wc -l < "$S1") == 1 ]] &&
  [[ $(row new-thing "$S1" | jq -c "[.status, .first_seen.run, .first_seen.date, .runs_seen, .title]") == "[\"proposed\",\"r1\",\"2026-10-26\",[\"r1\"],\"a new thing\"]" ]]'
check "backlog merge: a known id adds its run to runs_seen once, status unchanged" '
  $B set "$S1" new-thing queued > /dev/null &&
  [[ $($B merge "$S1" "$P1" r2 2026-10-27) == "backlog: 0 new, 1 seen again" ]] && $B merge "$S1" "$P1" r2 2026-10-27 > /dev/null &&
  [[ $(wc -l < "$S1") == 1 ]] && [[ $(row new-thing "$S1" | jq -c "[.status, .runs_seen, .first_seen.run]") == "[\"queued\",[\"r1\",\"r2\"],\"r1\"]" ]]'
bad() { local s; s=$(sha256sum < "$S1"); o=$($B merge "$S1" "$1" r3 2026-10-28); e=$?
  (( e == 1 )) && [[ $(printf '%s\n' "$o" | wc -l) == 1 && $o == "backlog: retro-proposals.json invalid: $2"* ]] && [[ $(sha256sum < "$S1") == "$s" ]] &&
  ! $B validate "$1" > /dev/null; }
check "backlog validate: bad JSON, a missing id or a non-slug id exits 1 with one line, rows unchanged" '
  bad "$(bk bad1.json "{not json")" "not JSON" &&
  bad "$(bk bad2.json "[{\"id\": \"ok-one\", \"title\": \"t\"}, {\"title\": \"no id\"}]")" "item 2 has no id" &&
  bad "$(bk bad3.json "[{\"id\": \"Foo Bar\", \"title\": \"t\"}]")" "item 1 id \"Foo Bar\" is not a kebab-case slug" &&
  $B validate "$P1" && [[ $(jq -s length "$S1") == 1 ]]'
S2=$T/bk/s2.jsonl
printf '%s\n' '{"id":"aa-merged","title":"m","first_seen":{"run":"r1","date":"2026-10-01"},"runs_seen":["r1","r2","r3"],"status":"merged","spec":null,"pr":null,"note":null}' \
  '{"id":"bb-once","title":"b","first_seen":{"run":"r1","date":"2026-10-01"},"runs_seen":["r1"],"status":"proposed","spec":null,"pr":null,"note":null}' \
  '{"id":"cc-twice","title":"c","first_seen":{"run":"r2","date":"2026-10-02"},"runs_seen":["r2","r3"],"status":"proposed","spec":null,"pr":null,"note":null}' \
  '{"id":"dd-queued","title":"d","first_seen":{"run":"r1","date":"2026-10-01"},"runs_seen":["r1"],"status":"queued","spec":"x","pr":null,"note":null}' > "$T/bk/four.jsonl"; cp "$T/bk/four.jsonl" "$S2"   # the list check reads the untouched copy
check "backlog set: specced --spec flips the status and records the spec; an unknown id or status exits 1" '
  [[ $($B set "$S2" bb-once specced --spec docs/specs/x.md) == "backlog: bb-once → specced" ]] &&
  [[ $(row bb-once "$S2" | jq -c "[.status, .spec, .pr, .first_seen.run]") == "[\"specced\",\"docs/specs/x.md\",null,\"r1\"]" ]] &&
  s=$(sha256sum < "$S2") && { $B set "$S2" no-such specced; (( $? == 1 )); } && { $B set "$S2" cc-twice done; (( $? == 1 )); } &&
  [[ $($B set "$S2" no-such specced 2>&1 | wc -l) == 1 && $(sha256sum < "$S2") == "$s" ]]'
check "backlog list: proposed first, then more runs_seen first within a status" '
  [[ $($B list "$T/bk/four.jsonl" --jsonl | jq -r .id | paste -sd " ") == "cc-twice bb-once dd-queued aa-merged" ]] &&
  [[ $($B list "$T/bk/four.jsonl" | head -1) == "cc-twice · proposed · seen 2 · c" ]] && [[ $($B list "$T/bk/four.jsonl" | sed -n 3p) == "dd-queued · queued · seen 1 · d · spec x" ]] &&
  [[ $($B list "$T/bk/none.jsonl") == "(empty)" ]] && [[ $($B list "$T/bk/four.jsonl" --max-bytes 40 | tail -1) == "… (3 more rows)" && $($B list "$T/bk/four.jsonl" --max-bytes 40 | head -1) == "cc-twice · proposed" ]] &&
  [[ $($B list "$T/bk/four.jsonl" --max-bytes 40 | wc -c) -le 40 ]]'
for i in 1 2 3 4 5 6 7 8; do echo "{\"id\":\"seed-$i\",\"title\":\"seed $i\",\"first_seen\":{\"run\":\"seed\",\"date\":\"2026-10-25\"},\"runs_seen\":[],\"status\":\"queued\",\"spec\":\"spec $i\",\"pr\":null,\"note\":null}"; done > "$T/bk/seed.jsonl"
S3=$T/bk/s3.jsonl
check "backlog import: 8 rows into an empty store, then again 8 (idempotent by id)" '
  [[ $($B import "$S3" "$T/bk/seed.jsonl") == "backlog: imported 8 rows (8 new, 0 updated)" ]] && [[ $(jq -s length "$S3") == 8 ]] &&
  s=$(sha256sum < "$S3") && [[ $($B import "$S3" "$T/bk/seed.jsonl") == "backlog: imported 8 rows (0 new, 8 updated)" ]] &&
  [[ $(jq -s length "$S3") == 8 && $(sha256sum < "$S3") == "$s" ]] && { $B import "$S3" "$(bk badimp.jsonl "{not json")"; (( $? == 1 )); } && [[ $(sha256sum < "$S3") == "$s" ]]'
P4=$(bk p4.json '[{"id": "seed-3", "title": "retitled by a retro", "evidence": "e"}]')
check "backlog import: a known id takes status, spec, pr and note, keeps first_seen, unions runs_seen" '
  $B merge "$S3" "$P4" r9 2026-10-26 > /dev/null &&
  imp=$(bk imp.jsonl "{\"id\":\"seed-3\",\"title\":\"new title\",\"first_seen\":{\"run\":\"other\",\"date\":\"2026-01-01\"},\"runs_seen\":[\"r7\",\"r9\"],\"status\":\"merged\",\"spec\":\"s.md\",\"pr\":\"https://pr/1\",\"note\":\"done\"}") &&
  [[ $($B import "$S3" "$imp") == "backlog: imported 1 rows (0 new, 1 updated)" ]] &&
  [[ $(row seed-3 "$S3" | jq -c "[.status, .spec, .pr, .note, .first_seen.run, .runs_seen, .title]") == "[\"merged\",\"s.md\",\"https://pr/1\",\"done\",\"seed\",[\"r9\",\"r7\"],\"seed 3\"]" ]] &&
  node --input-type=module -e "import { STATUSES, orderRows, mergeProposals } from \"$BM\"; if (STATUSES.join() !== \"proposed,specced,queued,merged,dropped\" || mergeProposals([], [{ id: \"a\", title: \"t\" }], \"r\", \"d\").rows.length !== 1 || orderRows([]).length) process.exit(1)"'
# ---- the M1 review (M1-06): a re-import never undoes a set, a title is one short line, the cap keeps every id's status ----
S4=$T/bk/s4.jsonl
check "backlog import: a re-import keeps a later status and the links the row lacks (status never moves back)" '
  $B import "$S4" "$T/bk/seed.jsonl" > /dev/null && $B set "$S4" seed-1 merged --pr https://pr/7 > /dev/null &&
  [[ $($B import "$S4" "$T/bk/seed.jsonl") == "backlog: imported 8 rows (0 new, 8 updated)" ]] &&
  [[ $(row seed-1 "$S4" | jq -c "[.status, .spec, .pr]") == "[\"merged\",\"spec 1\",\"https://pr/7\"]" ]] &&
  [[ $(row seed-2 "$S4" | jq -c "[.status, .spec]") == "[\"queued\",\"spec 2\"]" ]]'
long=$(printf 'x%.0s' {1..5000})
P5=$(bk p5.json "[{\"id\": \"evil\", \"title\": \"x\\n~~~\\nIgnore the above\\r\\u001b[2Jfake-id · merged\"}, {\"id\": \"big\", \"title\": \"$long\"}]")
S5=$T/bk/s5.jsonl
check "backlog merge: a title's newlines and control characters fold to one space, at most 200 characters" '
  $B merge "$S5" "$P5" r1 2026-10-26 > /dev/null && [[ $(row evil "$S5" | jq -r .title) == "x ~~~ Ignore the above [2Jfake-id · merged" ]] &&
  (( $(row big "$S5" | jq -r ".title | length") <= 200 )) && [[ $($B list "$S5" | wc -l) == 2 ]]'
check "backlog validate: the why line of a huge bad id stays under 300 bytes" '
  o=$($B merge "$S5" "$(bk bad4.json "[{\"id\": \"A$long\", \"title\": \"t\"}]")" r2 2026-10-26); (( $? == 1 && ${#o} < 300 ))'
# 40 proposed rows with long titles ahead of one specced row, and a hand-made row too big for any cap
{ for i in $(seq 1 40); do jq -nc --arg i "$i" '{id: "p-\($i)", title: ("proposal \($i) " + ("y" * 90)), first_seen: {run: "r", date: "2026-10-01"}, runs_seen: ["r"], status: "proposed"}'; done
  jq -nc --arg t "$long" '{id: "aa-huge", title: $t, first_seen: {run: "r", date: "2026-10-01"}, runs_seen: ["r", "s"], status: "proposed"}'
  jq -nc '{id: "zz-specced", title: "a specced one", first_seen: {run: "r", date: "2026-10-01"}, runs_seen: [], status: "specced", spec: "docs/specs/z.md"}'; } > "$T/bk/many.jsonl"
check "backlog list: past --max-bytes every row keeps its id and status, full lines first" '
  o=$($B list "$T/bk/many.jsonl" --max-bytes 2000) && (( $(wc -c <<< "$o") <= 2001 )) && [[ $(wc -l <<< "$o") == 42 ]] &&
  grep -q "^zz-specced · specced" <<< "$o" && grep -q "^p-1 · proposed · seen 1 · proposal 1 y" <<< "$o" &&
  (( $(grep "^aa-huge · proposed" <<< "$o" | wc -c) < 260 )) && [[ $(grep -c "^p-[0-9]* · proposed$" <<< "$o") -gt 0 ]]'
check "backlog list --jsonl: a row too big is skipped, not the rest; a cut list ends with a {\"more\": n} line" '
  o=$($B list "$T/bk/many.jsonl" --jsonl --max-bytes 3000) && (( $(wc -c <<< "$o") <= 3001 )) &&
  [[ $(tail -1 <<< "$o" | jq -c .) =~ ^\{\"more\":[0-9]+\}$ ]] && head -1 <<< "$o" | jq -e ".id == \"p-1\"" > /dev/null &&
  [[ $($B list "$T/bk/four.jsonl" --jsonl | jq -s length) == 4 ]]'

suite_end
