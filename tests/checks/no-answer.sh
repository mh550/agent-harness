#!/usr/bin/env bash
# tier: slow
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- a question nobody answers (decisions/2026-11-03-purity): a decision that was bash is a node call now, and when ----
# ---- the helper and the spawn both fail the bash must take the safe branch, not whichever an empty answer falls into ----
# A node that answers nothing to the questions named, as a killed spawn does (exit 1, no output), and logs each refusal,
# so a check can tell the question really went unanswered. HARNESS_HELPER=0: every ask is that spawn.
real=$(command -v node)
cat > "$T/bin/node" <<WRAP
#!/usr/bin/env bash
q="\${1##*/} \${2:-}"
if [[ -n \${NO_ANSWER:-} && \$q =~ ^(\$NO_ANSWER)\$ ]]; then echo "\$q" >> "$T/no-answer.log"; exit 1; fi
if [[ -n \${NO_ANSWER_ONCE:-} && \$q =~ ^(\$NO_ANSWER_ONCE)\$ && ! -e "$T/no-answer-once" ]]; then : > "$T/no-answer-once"; echo "\$q" >> "$T/no-answer.log"; exit 1; fi
exec "$real" "\$@"
WRAP
chmod +x "$T/bin/node"; export HARNESS_HELPER=0
refused() { grep -c -x -- "$1" "$T/no-answer.log" 2> /dev/null; }
posts() { awk 'BEGIN { RS = "===\n"; split(ARGV[1], k, "\t"); ARGV[1] = "" } { for (i in k) if (!index($0, k[i])) next; n++ } END { print n + 0 }' "$(IFS=$'\t'; echo "$*")" "$T/curl.log"; }
st() { echo "$HARNESS_STATE/proj/$1"; }

# ---- the queue runner: its entry and the project hold ----
echo MAX_PARALLEL_RUNS=4 >> "$HARNESS_CONFIG"   # room to spare: only the project rule could hold it
Q=$HARNESS_STATE/queue
sleep 600 & LIVE=$!; echo "$LIVE" >> "$T/left.pids"   # sleep-ok: a live driver
L=$(st live1); mkdir -p "$L" && echo "$LIVE" > "$L/driver.pid" && printf 'PROJECT_DIR=%q\nWT=/x\nRUN_ID=live1\nSTATE=%q\n' "$T/proj" "$L" > "$L/meta.env"
"$H" queue add "$T/proj" qa --brief y > /dev/null
( wait_for 20 grep "could not read" "$T/qproj.out"; sleep 1; touch "$Q/STOP" ) &   # sleep-ok: then a negative (never started) over five polls
NO_ANSWER='queue.mjs projects' HARNESS_QUEUE_POLL=0.2 HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. timeout 30 "$HERE/../lib/queue.sh" > "$T/qproj.out" 2>&1
check "no answer: a poll that can't read its entries' projects starts nothing on a busy project: said, the entry still queued" \
  '(( $(refused "queue.mjs projects") >= 1 )) && grep "could not read the queued entries'"'"' projects" "$T/qproj.out" > /dev/null \
  && ! grep "starting:" "$T/qproj.out" > /dev/null && [[ -f $(ls "$Q"/*-start-proj.args) ]]'
kill "$LIVE" 2> /dev/null; rm -rf "$L"; rm -f "$Q/STOP"
( wait_for 20 grep "could not read" "$T/qdec.out"; sleep 1; touch "$Q/STOP" ) &   # sleep-ok: then a negative (never started) over five polls
NO_ANSWER='queue.mjs decode' HARNESS_QUEUE_POLL=0.2 HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. timeout 30 "$HERE/../lib/queue.sh" > "$T/qdec.out" 2>&1
check "no answer: an entry the runner can't decode stays queued, said: not moved to done/, no start with no arguments" \
  '(( $(refused "queue.mjs decode") >= 1 )) && grep "could not read .*start-proj.args: it stays queued" "$T/qdec.out" > /dev/null \
  && ! grep "starting:" "$T/qdec.out" > /dev/null && [[ -f $(ls "$Q"/*-start-proj.args) ]] && ! ls "$Q"/done/*-start-proj.args > /dev/null 2>&1'
rm -f "$Q"/*.args "$Q/STOP"

check "no answer: stop_why with no answer is the plain stop's words, never an empty end reason" \
  '( ask() { return 1; }; REC=$T STATE=$T; eval "$(grep "^stop_why()" "$HERE/../lib/record.sh")"; [[ $(stop_why) == "stopped by Michael" ]] )'

# ---- the lane's verdict and the run's end: one project with two tiers, as session-gate-driver's ----
cat > .harness/suite.sh <<'SUITE'
#!/usr/bin/env bash
case ${1:-} in
  "") red=$(ls BROKEN BROKEN-SLOW 2> /dev/null); pass=(t1 t2 t3) ;;
  --tier) red=$(ls BROKEN BROKEN-FAST 2> /dev/null); pass=(t1 t2) ;;
  *) red=$(ls BROKEN BROKEN-SLOW BROKEN-FAST 2> /dev/null); pass=("$@") ;;
esac
if [[ -n $red ]]; then printf '%s\n' "FAIL t1 ($red)" "HARNESS_FAILED=t1" "0/1 checks passed"; exit 1; fi
for t in "${pass[@]}"; do echo "PASS $t"; done; echo "${#pass[@]}/${#pass[@]} checks passed"
SUITE
sed -i 's|^CHECK_CMD=.*|CHECK_CMD="bash .harness/suite.sh"\nCHECK_FAST_CMD="bash .harness/suite.sh --tier fast"|' .harness/config.sh
git add -A && git commit -qm "two tiers" && git push -q origin main
main0=$(git rev-parse HEAD)
go() { local r=$1; shift; git -C "$T/origin.git" update-ref refs/heads/main "$main0"
  env STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$@" timeout 150 "$H" start "$T/proj" "$r" --spec SPEC.md --foreground > "$T/$r.out" 2>&1; }
closed_with() { hlog "$1" | grep -F "lane M1 closed ($2)" > /dev/null; }

: > "$T/no-answer.log"
go na NO_ANSWER='lane.mjs (suite-verdict|end-kind)' NO_ANSWER_ONCE='lane.mjs run-end'
check "no answer: suite-verdict unanswered on a green suite: the hold stands, the milestone verified and tagged" \
  '(( $(refused "lane.mjs suite-verdict") >= 1 )) && hlog na | grep "M1 verified and tagged run/na/M1" > /dev/null && git -C "$T/origin.git" rev-parse -q --verify "refs/tags/run/na/M1" > /dev/null'
check "no answer: run-end unanswered once is asked again at the next poll: the run ends done, not no feature left to try" \
  '[[ $(refused "lane.mjs run-end") == 1 ]] && grep "^done · " "$(st na)/ended" > /dev/null && ! hlog na | grep "no feature left to try" > /dev/null'
check "no answer: end-kind unanswered: the run end's notification goes out at high priority" \
  '(( $(refused "lane.mjs end-kind") >= 1 )) && [[ $(posts "Title: [na] ended: done" "Priority: high") == 1 ]]'

: > "$T/no-answer.log"
mkdir -p "$(st ns)" && echo MAX_FIX_ROUNDS=0 > "$(st ns)/run.env"
go ns STUB_SLOW_RED=B NO_ANSWER='lane.mjs (suite-verdict|verdict)'
check "no answer: suite-verdict unanswered on a red suite: red, no tag, never a hold" \
  '(( $(refused "lane.mjs suite-verdict") >= 1 )) && hlog ns | grep "verify M1: the suite is red on the verified tree" > /dev/null \
  && ! git -C "$T/origin.git" rev-parse -q --verify "refs/tags/run/ns/M1" > /dev/null && ! git -C "$T/proj" rev-parse -q --verify "refs/tags/run/ns/M1" > /dev/null'
check "no answer: verdict unanswered where the milestone needs Michael: the lane closes on a need, its card and its notification" \
  '(( $(refused "lane.mjs verdict") >= 1 )) && closed_with ns "M1 needs Michael: verify red (see harness-log.md)" \
  && jq -se "any(.reason == \"verify_red\")" "$(st ns)"/needs/*.json > /dev/null && (( $(posts "Title: [ns] M1 needs you") >= 1 ))'

: > "$T/no-answer.log"
go nr STUB_LENIENT= STUB_STRICT_VERIFIER=1 NO_ANSWER='lane.mjs verify-round'
check "no answer: verify-round unanswered when the verifier un-passed a feature: the re-check's fail, no lane crash" \
  '(( $(refused "lane.mjs verify-round") >= 1 )) && hlog nr | grep "verify M1: A failed the re-check" > /dev/null \
  && ! hlog nr | grep "lane exited unexpectedly" > /dev/null'

: > "$T/no-answer.log"
go nd NO_ANSWER='lane.mjs verify-round'
check "no answer: verify-round unanswered on a done milestone: thin, its card, one verify round per model and no more" \
  '(( $(refused "lane.mjs verify-round") >= 1 )) && closed_with nd "M1 needs Michael: verify evidence too thin" \
  && jq -se "any(.reason == \"verify_thin\")" "$(st nd)"/needs/*.json > /dev/null && (( $(grep -c " verify M1 · " "$(st nd)/run.log") <= 2 ))'
suite_end
