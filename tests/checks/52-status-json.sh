#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- harness status --json (U1-03): lib/status.mjs builds the run, needs and queue objects from the stub state ----
status_stubs
S=$HERE/../lib/status.mjs
J() { "$H" status --json "$@" 2> "$T/json.err"; }   # one document; stderr kept for a failure's look
K='[paths | map(if type == "number" then "[]" else "." + . end) | join("") | ltrimstr(".")] | unique | .[]'
R() { jq -c --arg r "$1" '[.running[], .finished[]] | map(select(.run == $r))[0]'; }   # <run> → its object, from the document on stdin

check "status json: lib/status.mjs has a usage header, imports only node: built-ins and ./view.mjs, exports runObject, queueEntry and sections" '
  [[ $(head -1 "$S") == "// "* ]] && node --check "$S" && bash -n "$H" \
  && [[ -z $(grep "^import " "$S" | grep -v " from \"node:" | grep -v " from \"./view.mjs\"") ]] \
  && node --input-type=module -e "import * as M from \"$S\"; for (const f of [\"runObject\", \"queueEntry\", \"sections\"]) if (typeof M[f] !== \"function\") process.exit(1)"'
check "status json: harness status --json is one v1 document whose sorted key paths equal tests/fixtures/status-json-keys.txt" '
  J > "$T/s.json" && jq -e ".v == 1 and (.generated_at | test(\"^2026-10-28T00:00:00\")) and .since == \"24h\" and .runner.up == false and .runner.max_parallel_runs == 1" "$T/s.json" > /dev/null \
  && diff <(jq -r "$K" "$T/s.json") "$HERE/fixtures/status-json-keys.txt"'
check "status json: state is running, ended or crashed, end_class done, stopped or waiting as endClass says" '
  J > "$T/s.json" && [[ $(R running < "$T/s.json" | jq -r "[.state, .end_class, .end_reason] | join(\",\")") == running,, ]] \
  && [[ $(R done2h < "$T/s.json" | jq -r "[.state, .end_class, .end_reason, .ended_at] | join(\",\")") == ended,done,done,2026-10-27T22:00:00.000Z ]] \
  && [[ $(R stopped < "$T/s.json" | jq -r "[.state, .end_class, .end_reason] | join(\",\")") == "ended,stopped,stopped by Michael: rebase first" ]] \
  && [[ $(R givenup < "$T/s.json" | jq -r "[.state, .end_class] | join(\",\")") == ended,waiting ]] \
  && R crashed < "$T/s.json" | jq -e ".features.total == 1" > /dev/null \
  && R done2h < "$T/s.json" | jq -e ".features.passing == 3 and .cost_usd == 0.01 and .session == 3 and .features.merged == 3 and .tests == {start: 419, end: 430}" > /dev/null \
  && [[ $(R crashed < "$T/s.json" | jq -r "[.state, .end_class, .end_reason // \"null\", .ended_at] | join(\",\")") == crashed,failed,null,2026-10-27T14:00:00.000Z ]]'
check "status json: the gc'd run's features are 23/23 from the ledger's summary.json, its worktree gone, its lanes from the summary" '
  J | R gcd > "$T/gcd.json" && jq -e ".features.passing == 23 and .features.total == 23 and .features.merged == 23 and .worktree_exists == false
    and .lanes.max_open == 2 and .lanes.open == [] and .branch == \"harness/gcd\" and (.worktree | endswith(\"/wt/proj/gcd\"))" "$T/gcd.json" > /dev/null'
check "status json: needs counts a parked feature, a given-up one and a crashed driver; the gc'd run none, nor a live run's last attempt; items oldest first" '
  J > "$T/s.json" && [[ $(for r in parked givenup gcd crashed done2h stopped running; do R $r < "$T/s.json" | jq -r .needs; done | paste -sd" ") == "1 1 0 1 0 0 0" ]] \
  && [[ $(jq -r ".needs | map([.run, .feature // \"-\", .reason, .kind, .severity] | join(\":\")) | join(\" \")" "$T/s.json") == "crashed:-:driver_crash:needs_michael:block parked:B:parked:park:block givenup:C:given_up:blocked:block" ]] \
  && jq -e ".needs[1] | .milestone == \"M1\" and .title == \"[parked] B needs you\" and .card.headline == \"B parked: set the gatus vars\" and .at == \"2026-10-27T22:58:20.000Z\"" "$T/s.json" > /dev/null \
  && jq -e ".needs[2].card.headline == \"C given up (2 attempts)\"" "$T/s.json" > /dev/null'
check "status json: the running run's feature, session (all segments'), model, port and started_at; lane M1 open with its unit; its own unit apart" '
  J | R running > "$T/run.json" && jq -e ".feature == \"B\" and .session == 2 and .model == \"claude-opus-5-5\" and .port == 7954 and .started_at == \"2026-10-27T22:00:00.000Z\"
    and .features == {passing: 1, total: 3, verified: 0, merged: 0} and (.cost_usd | type) == \"number\" and .lanes.max_open == null
    and .lanes.open == [{milestone: \"M1\", now: \"B · session 2\", port: 7960, slot: (.worktree + \"-slots/slot-1\"), units: [{unit: \"harness-running-M1-s2\", memory_mb: 300}]}]
    and .units == [{unit: \"harness-running-svc\", memory_mb: 300}] and .tests == {start: null, end: null}" "$T/run.json" > /dev/null'
check "status json: finished holds the runs ended in the last 24h, newest first, and older the rest; at least the 3 newest" '
  J > "$T/s.json" && [[ $(jq -r "[.finished[].run] | join(\" \")" "$T/s.json") == "givenup parked gcd done2h stopped crashed" && $(jq .older "$T/s.json") == 1 ]] \
  && [[ $(J --since 4d | jq -r "[(.finished | map(.run) | join(\" \")), .older, .since] | join(\",\")") == "givenup parked gcd done2h stopped crashed done3d,0,4d" ]] \
  && [[ $(J --since 30m | jq -r "[(.finished | map(.run) | join(\" \")), .older] | join(\",\")") == "givenup parked gcd,4" ]] \
  && [[ $(jq -r "[.running[].run] | join(\" \")" "$T/s.json") == running ]] && ! J --since 3x > /dev/null 2>&1'
check "status json: STATUS_SINCE in the user config sets the window, --since wins over it" '
  echo "STATUS_SINCE=4d MAX_PARALLEL_RUNS=2x" >> "$HARNESS_CONFIG" && [[ $(J | jq -r "[.since, .older, .runner.max_parallel_runs] | join(\",\")") == 4d,0,1 && $(J --since 24h | jq .older) == 1 ]]; r=$?; cp "$T/base-config.sh" "$HARNESS_CONFIG"; (( r == 0 ))'
check "status json: --project proj2 keeps only that project's runs, items and queue entries" '
  J --project proj2 > "$T/p2.json" && [[ $(jq -r "[.running[], .finished[], .needs[], .queued[]] | map(.project) | unique | join(\" \")" "$T/p2.json") == proj2 ]] \
  && [[ $(jq -r "[.finished[].run] | join(\" \")" "$T/p2.json") == "givenup stopped" && $(jq ".needs | length" "$T/p2.json") == 1 ]] \
  && J -p proj > /dev/null && ! "$H" status running -p proj2 > /dev/null 2>&1'
check "status json: queued holds the entries as queue list numbers them, held by a live run of their project, a brief's first 30 characters" '
  J > "$T/s.json" && [[ $(jq -r ".queued | map([.n, .verb, .project, .run // \"-\", .mark // \"-\", .parked] | join(\":\")) | join(\" \")" "$T/s.json") == "1:start:proj:-:-:false 2:continue:proj2:stopped:requested:false 1:start:proj2:proj2-next:-:true" ]] \
  && jq -e ".queued[0] | .held == {project: \"proj\", run: \"running\"} and .brief_head == \"brief brief brief brief brief \" and .brief_chars == 1200
    and .spec == [\"SPEC.md\", \"docs/b.md\"] and .until == \"2026-10-28T23:52:00.000Z\" and .overlap == [] and .why == null and .added_at == \"2026-10-27T23:50:00.000Z\"" "$T/s.json" > /dev/null \
  && jq -e ".queued[1].held == null and .queued[1].spec == [] and .queued[2].why == \"waiting on the measure PRs (2026-10-28 23:00)\" and .queued[2].until == \"2026-10-28T01:00:00.000Z\"" "$T/s.json" > /dev/null'
check "status json: harness status <run> --json prints that one run object with v; an unknown run is an error" '
  "$H" status parked --json > "$T/one.json" && jq -e ".v == 1 and .run == \"parked\" and .needs == 1 and .end_class == \"waiting\" and (has(\"finished\") | not)" "$T/one.json" > /dev/null \
  && diff <(jq -S "del(.v)" "$T/one.json") <(J | R parked | jq -S .) \
  && ! "$H" status nosuch --json > /dev/null 2> "$T/err" && grep -q "^harness: no run '\''nosuch'\''" "$T/err"'
check "status json: --json writes nothing, and reads the queue dir without creating it" '
  touch "$T/json.stamp"; sleep 1; J > /dev/null && "$H" status running --json > /dev/null \
  && [[ -z $(find "$HARNESS_STATE" "$T/wt" "$HARNESS_LEDGER" -newer "$T/json.stamp") ]] \
  && HARNESS_STATE=$T/empty "$H" status --json | jq -e ".queued == [] and .running == [] and .older == 0" > /dev/null && [[ ! -e $T/empty ]]'
check "status json: the text of harness status <run> is as before U1-03 (U1-05 makes it a card)" '
  diff <("$H" status running 2>&1 | sed "s|$T|<T>|g") "$HERE/fixtures/status-text-u1-03.txt"'
# 30 more ended runs (38 in all), an empty meta.env, an ended file with a bare reason (bulk-01)
status_bulk 30
check "status json: an empty meta.env is skipped and a bare end reason dated by its file" '
  mkdir -p "$HARNESS_STATE/proj/broken" && : > "$HARNESS_STATE/proj/broken/meta.env" && J > "$T/s.json"; r=$?; rm -rf "$HARNESS_STATE/proj/broken"
  (( r == 0 )) && [[ $(J --all | R bulk-01 | jq -r "[.end_reason, .end_class, .ended_at] | join(\",\")") == done,done,2026-10-23T23:59:00.000Z ]] \
  && [[ $(jq -r "[(.finished | length), .older] | join(\",\")" "$T/s.json") == 6,31 && $(J --since 5d | jq -r "[(.finished | length), .older] | join(\",\")") == 10,27 ]] \
  && [[ $(J --all | jq -r "[(.finished | length), .older, .finished[-1].run] | join(\",\")") == 37,0,bulk-30 ]]'
check "status json: harness status --json over 38 stub runs takes under 1 s (best of 3)" '
  best=99999; for i in 1 2 3; do t0=$(date +%s%N); J > /dev/null || break; t=$(( ($(date +%s%N) - t0) / 1000000 )); (( t < best )) && best=$t; done
  echo "    best of 3: $best ms over $(J --all | jq "[.running[], .finished[]] | length") runs"; (( best < 1000 )) && [[ $(J --all | jq "[.running[], .finished[]] | length") == 38 ]]'
suite_end
