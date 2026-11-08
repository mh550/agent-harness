#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- harness requests (A3-03): the request inbox n8n writes (<state>/requests/*.json), each under flock, oldest first ----
# Requests are made from n8n-home's buildRequest fixtures (tests/fixtures/requests/) with jq, never hand-typed. Their real
# mtime is days after the fake now, which reads as young: a file is aged with touch where its age matters.
status_stubs
R=$HARNESS_STATE/requests Q=$HARNESS_STATE/queue FX=$HERE/fixtures/requests RQ=$HERE/../lib/requests.sh
req() { local n=$1 fx=$2 f=$3; shift 3; jq -c "$@" "$f" "$FX/$fx.json" > "$R/$n"; }   # <file> <fixture> <jq filter> [jq args…]
aged() { touch -d "@$(( HARNESS_NOW - $2 ))" "$R/$1"; }   # <file> <s old by the fake clock>
res() { jq -e "$2" "$R/done/$1.json" > /dev/null 2>&1; }   # <name> <jq test>: the result says so
inboxes() { find "$HARNESS_STATE" -name inbox.md -exec md5sum {} + | LC_ALL=C sort; }
mkdir -p "$T/tmuxlog" && printf '#!/usr/bin/env bash\necho "$*" >> %q\n' "$T/tmux-calls" > "$T/tmuxlog/tmux" && chmod +x "$T/tmuxlog/tmux"   # gc-tmux.sh's logging shim
runner() { PATH=$T/tmuxlog:$PATH HARNESS_NO_RUNNER= "$H" requests "$@"; }   # queue start's real path, its tmux the shim

# an answer whose text a shell would expand: it must land as it is
"$H" requests > "$T/r0.out" 2>&1; r0_rc=$?
TXT=$'it\'s `x` $(rm -rf /) "q"\nline two'
req req-0001-aaaa.json answer '.text = $t' --arg t "$TXT"; cp "$R/req-0001-aaaa.json" "$T/req1.json"
"$H" requests > "$T/r1.out" 2>&1; r1_rc=$?
check "harness requests: an answer lands in the run's inbox.md byte for byte, quotes, backticks, a command substitution and newlines included" '
  (( r1_rc == 0 )) && cmp <(jq -r .text "$T/req1.json") "$HARNESS_STATE/proj/parked/inbox.md" && [[ $(grep -c "eval\|bash -c" "$RQ") == 0 ]]'
check "harness requests: an answer's result is ok, its request moves to done/ and requests.log has one line without the text" '
  (( r0_rc == 0 )) && grep -qxF "requests: none pending ($R)" "$T/r0.out" && [[ ! -e $R/req-0001-aaaa.json ]] \
  && res req-0001-aaaa ".ok == true and .exit == 0 and .verb == \"answer\" and .run == \"parked\" and .id == \"req-0001-aaaa\"" \
  && [[ $(jq -c keys_unsorted "$R/done/req-0001-aaaa.json") == "[\"v\",\"id\",\"at\",\"verb\",\"run\",\"ok\",\"exit\",\"output\",\"runner_started\",\"refused\"]" ]] \
  && cmp "$T/req1.json" "$R/done/req-0001-aaaa.request.json" && [[ $(wc -l < "$R/requests.log") == 1 ]] \
  && grep -E "^2026-10-28 00:00:00 id=req-0001-aaaa verb=answer run=parked ok exit=0$" "$R/requests.log" > /dev/null && ! grep -F "rm -rf" "$R/requests.log" > /dev/null \
  && grep -qxF "requests: 1 done, 0 rejected, 0 waiting" "$T/r1.out" && [[ $(stat -c %a "$R" "$R/done" "$R/rejected" | paste -sd" ") == "700 700 700" ]]'

# a continue: queued as requested, with its brief, then the runner started (tmux through the shim)
req req-0003-cccc.json continue-brief .
runner > "$T/r3.out" 2>&1; r3_rc=$?
check "harness requests: a continue queues the run requested with its brief and starts the runner" '(( r3_rc == 0 )) && q=$(compgen -G "$Q/*-continue-stopped.args") \
  && grep -qx -- --requested "$q" && grep -qx -- --brief "$q" && grep -qxF "Finish B3 first." "$q" \
  && res req-0003-cccc ".ok == true and .exit == 0 and .verb == \"continue\" and .runner_started == true and .refused == null and (.output | contains(\"queue runner started (tmux h-queue)\"))" \
  && grep -x "new-session -d -s h-queue .*" "$T/tmux-calls" > /dev/null && grep -E " id=req-0003-cccc verb=continue run=stopped ok exit=0 runner=started$" "$R/requests.log" > /dev/null'
rm -f "$T/tmux-calls"
req req-0004-dddd.json continue-brief '.id = "req-0004-dddd"'
HARNESS_NOW=$(( HARNESS_NOW + 12600 )) runner > "$T/r4.out" 2>&1; r4_rc=$?   # 03:30 UTC
check "harness requests: in the backup window a continue is queued and no runner starts" '(( r4_rc == 0 )) && compgen -G "$Q/*-continue-stopped.args" > /dev/null \
  && ! grep "new-session" "$T/tmux-calls" > /dev/null 2>&1 && jq -e --arg w "backup window 03:15–04:30: queued, runner not started" \
    ".ok == true and .exit == 0 and .runner_started == false and .refused == \$w" "$R/done/req-0004-dddd.json" > /dev/null \
  && grep -F "2026-10-28 03:30:00 id=req-0004-dddd verb=continue run=stopped ok exit=0 why=backup window 03:15–04:30: queued, runner not started" "$R/requests.log" > /dev/null'

# five bad requests and a duplicate id, in one pass
before=$(inboxes); cp "$R/done/req-0001-aaaa.json" "$T/first.json"
req rej-0001-verb.json answer '.id = "rej-0001-verb" | .verb = "merge"'
req rej-0002-norun.json answer '.id = "rej-0002-norun" | .run = "nosuch"'
req rej-0003-dots.json answer '.id = "rej-0003-dots" | .run = "../x"'
req rej-0004-long.json answer '.id = "rej-0004-long" | .text = ("y" * 4001)'
req rej-0005-vtwo.json answer '.id = "rej-0005-vtwo" | .v = 2'
req dup-0001.json answer '.text = "the duplicate text"'
"$H" requests > "$T/r5.out" 2>&1; r5_rc=$?
REJ=("rej-0001-verb|verb is not answer or continue" "rej-0002-norun|no run 'nosuch' (see: harness status)"
  "rej-0003-dots|run does not match ^[A-Za-z0-9._-]+\$" "rej-0004-long|text must be 1-4000 characters for answer"
  "rej-0005-vtwo|v is not 1 (this harness reads request v1)")
rejected_each() { local e ok=0; for e in "${REJ[@]}"; do
    [[ -f $R/rejected/${e%%|*}.json && ! -e $R/${e%%|*}.json ]] && jq -e --arg w "${e#*|}" '.ok == false and .exit == null and .refused == $w and .output == ""' "$R/done/${e%%|*}.json" > /dev/null || ok=1
  done; return $ok; }
check "harness requests: a bad verb, an unknown run, a parent-directory run, 4001 characters and v 2 are rejected with a result each and reach no inbox.md" '
  (( r5_rc == 0 )) && rejected_each && [[ $(inboxes) == "$before" ]] && grep -qxF "requests: 0 done, 6 rejected, 0 waiting" "$T/r5.out" \
  && grep -F " id=rej-0003-dots verb=answer run=- refused exit=- why=run does not match" "$R/requests.log" > /dev/null'
check "harness requests: a duplicate id goes to rejected/ and the first result stands" '[[ -f $R/rejected/dup-0001.json ]] && cmp "$T/first.json" "$R/done/req-0001-aaaa.json" \
  && grep -F " id=req-0001-aaaa verb=- run=- refused exit=- why=duplicate id: done/req-0001-aaaa.json already exists" "$R/requests.log" > /dev/null \
  && [[ $(grep -c "line two" "$HARNESS_STATE/proj/parked/inbox.md") == 1 ]] && ! grep -r "the duplicate text" "$HARNESS_STATE" --include inbox.md > /dev/null'

# a half-written file: n8n writes in one write, so a young unparsable file is left for 10 s
printf '{"v":1,' > "$R/half-0001-aaaa.json"; aged half-0001-aaaa.json 2
"$H" requests > "$T/r7a.out" 2>&1; r7a_rc=$?; cp "$R/requests.log" "$T/log7a"
HARNESS_NOW=$(( HARNESS_NOW + 10 )) "$H" requests > "$T/r7b.out" 2>&1; r7b_rc=$?
check "harness requests: a half-written file younger than 10 s is left alone and rejected once it is 10 s old" '(( r7a_rc == 0 && r7b_rc == 0 )) \
  && grep -qxF "requests: 0 done, 0 rejected, 1 waiting" "$T/r7a.out" && ! grep half-0001 "$T/log7a" > /dev/null \
  && [[ ! -e $R/half-0001-aaaa.json && -f $R/rejected/half-0001-aaaa.json ]] \
  && res half-0001-aaaa ".ok == false and .refused == \"the request is not JSON (still unparsable after 10 s)\""'
printf '{"v":1,' > "$R/half-0002-bbbb.json"; touch -d "@$(( $(date +%s) - 9 ))" "$R/half-0002-bbbb.json"
t0=$SECONDS; env -u HARNESS_NOW "$H" requests > "$T/r8.out" 2>&1; r8_rc=$? r8_s=$(( SECONDS - t0 ))
check "harness requests: on the real clock one call waits out a young file's grace" '(( r8_rc == 0 && r8_s < 5 )) && [[ -f $R/rejected/half-0002-bbbb.json ]] \
  && res half-0002-bbbb ".refused == \"the request is not JSON (still unparsable after 10 s)\"" && grep -qxF "requests: 0 done, 1 rejected, 0 waiting" "$T/r8.out"'

# the lock: a stand-in holds it 2 s, two calls start together, the request runs once
req lock-0001-aaaa.json answer '.id = "lock-0001-aaaa" | .text = "locked once"'
flock "$R/.lock" sleep 2 & echo $! >> "$T/left.pids"   # sleep-ok: the holder
wait_for 5 eval '! flock -n "$R/.lock" true'
t0=${EPOCHREALTIME/[.,]/}
( "$H" requests > "$T/r9a.out" 2>&1; echo "$? $(( ${EPOCHREALTIME/[.,]/} - t0 ))" > "$T/r9a.rc" ) & p9a=$!
( "$H" requests > "$T/r9b.out" 2>&1; echo "$? $(( ${EPOCHREALTIME/[.,]/} - t0 ))" > "$T/r9b.rc" ) & p9b=$!
wait "$p9a" "$p9b"   # not a bare wait: status_stubs' live driver is a job of this shell
lock_ok() { local f rc us; for f in r9a r9b; do read -r rc us < "$T/$f.rc" || return 1; (( rc == 0 && us >= 1800000 )) || return 1; done; }
check "harness requests: a second call waits on requests/.lock and nothing runs twice" 'lock_ok && [[ -f $R/done/lock-0001-aaaa.json ]] \
  && [[ $(grep -c " id=lock-0001-aaaa " "$R/requests.log") == 1 ]] && [[ $(grep -c "^locked once$" "$HARNESS_STATE/proj/parked/inbox.md") == 1 ]] \
  && [[ $(cat "$T/r9a.out" "$T/r9b.out" | grep -c "^requests: 1 done, 0 rejected, 0 waiting$") == 1 ]]'

# the order: oldest mtime first, then the name (n8n's 1-<h> answer before its 2-<h> continue)
for x in b a c; do req "ord-$x-0001.json" answer '.id = $i | .text = $t' --arg i "ord-$x-0001" --arg t "order $x"; done
aged ord-c-0001.json 30; aged ord-a-0001.json 20; aged ord-b-0001.json 20
"$H" requests > "$T/r10.out" 2>&1
check "harness requests: requests run oldest first by mtime, then by name" '[[ $(tail -3 "$HARNESS_STATE/proj/parked/inbox.md" | paste -sd"|") == "order c|order a|order b" ]]'

# a symlink is never read: its target may be anywhere
jq -c '.id = "link-0001-aaaa" | .text = "via link"' "$FX/answer.json" > "$T/target.json"; cp "$T/target.json" "$T/target.copy"
ln -s "$T/target.json" "$R/link-0001-aaaa.json"
"$H" requests > "$T/r11.out" 2>&1; r11_rc=$?
check "harness requests: a symlink request is rejected unread" '(( r11_rc == 0 )) && [[ -L $R/rejected/link-0001-aaaa.json && ! -e $R/link-0001-aaaa.json ]] \
  && cmp "$T/target.json" "$T/target.copy" && ! grep -r "via link" "$HARNESS_STATE" --include inbox.md > /dev/null \
  && res link-0001-aaaa ".ok == false and .refused == \"the request is not a regular file\""'

suite_end
