#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the suite's own tools (R1-02): wait_for, the stub_wait/stub_go barrier and STUB_BARRIER, run.sh --repeat ----
# wait_for: back as soon as the condition holds; past its limit, one still-failing line and 1
( sleep 0.5; touch "$T/wf" ) &   # sleep-ok: the event under test, half a second off
w0=${EPOCHREALTIME/[.,]/}; wait_for 30 test -f "$T/wf"; wrc=$? wus=$(( ${EPOCHREALTIME/[.,]/} - w0 ))
check "suite tools: wait_for returns as soon as its command succeeds (a background touch, well under its 30 s limit)" '(( wrc == 0 && wus < 5000000 ))'
wf=$(wait_for 1 test -f "$T/missing" 2>&1); wrc=$?
check "suite tools: wait_for gives up after its limit with its still-failing line, exit 1" '(( wrc == 1 )) && [[ $wf == "wait_for: test -f $T/missing still failing after 1 s" ]]'
# a limit that isn't whole seconds is refused at once (its arithmetic would fail and the wait never end)
( wait_for 0.5 false 2> "$T/wf-frac" ) & wp=$!
wait_for 5 eval "! kill -0 $wp"; wfe=$?; kill "$wp" 2> /dev/null; wait "$wp"; wfrc=$?
check "suite tools: wait_for refuses a limit that isn't whole seconds with one line, exit 2" \
  '(( wfe == 0 && wfrc == 2 )) && [[ $(cat "$T/wf-frac") == "wait_for: 0.5 is not whole seconds" ]]'

# the barrier: job 1 (started first) waits for job 2's stub_go, so the order file reads first, second every round
for i in $(seq 20); do
  ( stub_wait "r$i" && echo second >> "$T/order" ) & p1=$!
  ( echo first >> "$T/order"; stub_go "r$i" ) & p2=$!
  wait "$p1" "$p2"
done
check "suite tools: a stub_wait/stub_go barrier orders two background jobs the same way in 20 of 20 rounds" \
  '[[ $(cat "$T/order") == "$(for i in $(seq 20); do printf "first\nsecond\n"; done)" ]]'

# STUB_BARRIER=A:a-end: A's first coding session says a-end.held, then waits for a-end before its entry, and says
# a-end.released as it goes on: not released over 2 s at the barrier (a negative: nothing to count), released after stub_go
STUB_BARRIER=A:a-end STUB_NO_TAMPER=1 STUB_NO_RED=1 "$H" start "$T/proj" bar --spec SPEC.md --foreground > "$T/bar.out" 2>&1 & bp=$!
stub_wait a-end.held; bheld=$?
wait_for 2 test -e "$T/barriers/a-end.released" 2> /dev/null; bearly=$?
stub_go a-end; stub_wait a-end.released; brel=$?; wait "$bp"
check "suite tools: STUB_BARRIER holds that feature's first coding session until stub_go" \
  '(( bheld == 0 && bearly == 1 && brel == 0 )) && [[ $(jq -r ".features[] | select(.id == \"A\") | .passes" "$(list bar)") == true ]]'

# settle waits for this copy's debriefs only: a process named like a debrief with another state dir (a sibling copy's,
# another file's) is not its business; one with this copy's is waited for until it ends
( export HARNESS_STATE=${T%/}-sibling/state; exec -a "$HH/lib/debrief.sh" sleep 40 ) & fp=$!   # sleep-ok: a foreign debrief that lives on
( exec -a "$HH/lib/debrief.sh" sleep 3 ) & op=$!   # sleep-ok: this copy's debrief, 3 s of work
s0=${EPOCHREALTIME/[.,]/}; settle; src=$? sus=$(( ${EPOCHREALTIME/[.,]/} - s0 )); kill "$fp" 2> /dev/null
check "suite tools: settle waits for this copy's debrief to end and never for another state dir's" '(( src == 0 && sus >= 2000000 && sus < 20000000 ))'

# --repeat on two fixture check files: flaky is red on an even count (a flock'ed counter, so one copy of three), steady never
mkdir -p "$T/rep"
cat > "$T/rep/flaky.sh" <<EOF
#!/usr/bin/env bash
source "$HERE/lib.sh" && suite_setup
n=\$(flock "$T/rep-count.lock" bash -c 'n=\$(( \$(cat "\$1" 2> /dev/null || echo 0) + 1 )); echo "\$n" > "\$1"; echo "\$n"' _ "$T/rep-count")
check "fixture: red on an even copy" '(( n % 2 ))'
suite_end
EOF
cat > "$T/rep/steady.sh" <<EOF
#!/usr/bin/env bash
source "$HERE/lib.sh" && suite_setup
check "fixture: always green" 'true'
suite_end
EOF
rf=$(TEST_CHECKS=$T/rep TEST_JOBS=2 bash "$HERE/run.sh" --repeat 3 flaky 2>&1); rfc=$?
check "suite tools: --repeat 3 on a file red every other copy prints k/3 green and the red copies' FAIL lines, exit 1" \
  '(( rfc == 1 )) && grep -x "flaky: 2/3 green" <<< "$rf" > /dev/null \
  && [[ $(grep -cxE "copy [123]: FAIL fixture: red on an even copy" <<< "$rf") == 1 ]]'
rs=$(TEST_CHECKS=$T/rep TEST_JOBS=2 bash "$HERE/run.sh" --repeat 3 steady 2>&1); rsc=$?
check "suite tools: --repeat 3 on a steady file prints 3/3 green, exit 0" \
  '(( rsc == 0 )) && grep -x "steady: 3/3 green" <<< "$rs" > /dev/null && ! grep "^copy " <<< "$rs" > /dev/null'
# the sleep lint (R1-03): a sleep line without `# sleep-ok:` is listed as <file>:<line>; the real checks and library hold none
mkdir -p "$T/lint" && printf '%s\n' '#!/usr/bin/env bash' 'sleep 1' 'echo done' > "$T/lint/bare.sh" && printf '%s\n' '#!/usr/bin/env bash' 'sleep 1  # sleep-ok: x' > "$T/lint/ok.sh"   # sleep-ok: text (the fixtures)
lb=$(bash "$HERE/lint-sleeps.sh" "$T/lint/bare.sh" 2>&1); lbc=$?
check "sleep lint: a bare sleep is listed as <file>:<line>, exit 1" '(( lbc == 1 )) && [[ $lb == "$T/lint/bare.sh:2" ]]'   # sleep-ok: text
lo=$(bash "$HERE/lint-sleeps.sh" "$T/lint/ok.sh" 2>&1); loc=$?
check "sleep lint: a sleep with # sleep-ok: passes silently" '(( loc == 0 )) && [[ -z $lo ]]'
lr=$(bash "$HERE/lint-sleeps.sh" 2>&1); lrc=$?
check "sleep lint: tests/checks and tests/lib.sh hold no bare sleep" '(( lrc == 0 )) && [[ -z $lr ]] || { printf "%s\n" "$lr" | head -20; false; }'   # sleep-ok: text
suite_end
