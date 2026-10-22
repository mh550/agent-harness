#!/usr/bin/env bash
# Stand-in for `claude -p` in tests: acts out initializer / coding / verify / retro sessions from the prompt's first line,
# including scripted misbehaviour, and prints stream-json lines like the real CLI. Usage limits replay the real
# lines captured on 2026-10-17 (fixtures/usage-limit.jsonl), finished sessions the 2026-10-21 capture
# (fixtures/usage-tokens.jsonl): fakes mirror the live API. Without -p it is a desk
# (`claude --remote-control <name>`, no -p, in tmux): it prints the pane line of fixtures/remote-control-pane.txt with
# session_TEST<n>, records argv and $PWD in $STUB_DIR/desk/<n>-<name>.args, its environment's names in <n>-<name>.env
# and each typed line in <n>-<name>.in. STUB_DESK_MENU=1: after the first typed line it shows the permission dialog of
# fixtures/permission-menu.txt (the desk asks to run a command) and takes nothing more as an answer.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
ARGS=("$@"); prompt="" headless=0 rc=""
while (( $# )); do
  [[ $1 == -p || $1 == --print ]] && headless=1
  [[ $1 == --remote-control ]] && rc=${2:-}
  [[ $1 == -p && -n ${2:-} && ${2:-} != -* ]] && { prompt=$2; shift; }; shift; done
if (( ! headless )) && [[ -n $rc ]]; then   # interactive (a desk): the pane line Remote Control prints, then each typed line to <name>.in
  mkdir -p "$STUB_DIR/desk"; n=$(( $(cat "$STUB_DIR/desk/count" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$STUB_DIR/desk/count"
  name=$n-$(printf '%s' "$rc" | LC_ALL=C tr -cs 'A-Za-z0-9._-' _); name=${name%_}
  { printf '%s\n' "${ARGS[@]}"; echo "PWD=$PWD"; } > "$STUB_DIR/desk/$name.args"
  env | cut -d= -f1 | sort > "$STUB_DIR/desk/$name.env"
  [[ ${STUB_DESK_NO_URL:-} == 1 ]] || sed -n "2s/session_[^[:space:]]*/session_TEST$n/p" "$HERE/fixtures/remote-control-pane.txt"
  while IFS= read -r line; do
    printf '%s\n' "$line" >> "$STUB_DIR/desk/$name.in"
    [[ ${STUB_DESK_MENU:-} == 1 && $(wc -l < "$STUB_DIR/desk/$name.in") == 1 ]] && sed 1d "$HERE/fixtures/permission-menu.txt"
  done
  exit 0
fi
[[ -n $prompt ]] || prompt=$(cat)   # `claude -p` with the prompt on stdin
first=$(head -1 <<< "$prompt")
L=${HARNESS_RUN_DIR:-.}/feature_list.json
count() { local f=$HARNESS_SCRATCH/count-$1 n; n=$(( $(cat "$f" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$f"; echo "$n"; }
set_passes() { node -e 'const fs=require("fs"),[f,id,v]=process.argv.slice(1),l=JSON.parse(fs.readFileSync(f));for(const x of l.features)if(x.id===id)x.passes=v==="true";fs.writeFileSync(f,JSON.stringify(l,null,2))' "$L" "$1" "$2"; }
# A finished session: the real capture's assistant, tool-result and result events (fixtures/usage-tokens.jsonl, so every
# session carries tokens), with cost, final text, turns and duration substituted. --argjson: callers' \\n become newlines.
ok() { jq -c --argjson c "${1:-0.25}" --argjson r "\"${2:-done}\"" 'if .type == "result" then .total_cost_usd = $c | .result = $r | .num_turns = 12 | .duration_ms = 60000 else . end' "$HERE/fixtures/usage-tokens.jsonl"; }

case $first in
  "# Initializer session"*)
    [[ ${STUB_SLOW_INIT:-} ]] && sleep "$STUB_SLOW_INIT"
    [[ ${STUB_INIT_LIMIT:-} ]] && { cat "$HERE/fixtures/usage-limit.jsonl"; exit 1; }   # refused before the list exists
    [[ ${STUB_QUEUE_STOP:-} ]] && touch "$HARNESS_STATE/queue/STOP"   # Michael runs `harness queue stop` meanwhile
    after=""; [[ ${STUB_INDEPENDENT_M2:-} ]] && after=', "after": []'
    cat > "$L" <<JSON
{ "run": "test", "features": [
  { "id": "A", "milestone": "M1", "kind": "build", "model": "sonnet", "description": "a", "steps": ["x", "y"], "passes": false },
  { "id": "B", "milestone": "M1", "kind": "build", "description": "b", "steps": ["y"], "passes": false },
  { "id": "C", "milestone": "M2", "kind": "build", "model": "opus", "description": "c", "steps": ["z"]$after, "passes": false } ] }
JSON
    printf '# progress\n\n' > "$HARNESS_RUN_DIR/progress.md"
    git add -A && git commit -qm "HARNESS: feature list" && git push -q -u origin "$HARNESS_BRANCH"
    if [[ ${STUB_PHONE_STOP:-} ]]; then   # Michael edits INBOX.md on GitHub: status: stop
      tmp=$(mktemp -d); git clone -q "$(git remote get-url origin)" "$tmp" -b "$HARNESS_BRANCH"
      sed -i '1s/.*/status: stop/' "$tmp/$HARNESS_RUN_DIR/INBOX.md"
      git -C "$tmp" commit -qam "phone: stop" && git -C "$tmp" push -q origin "$HARNESS_BRANCH"
    fi
    ok 1.5 ;;
  "# Coding session"*)
    [[ ${STUB_SLOW_CODING:-} ]] && { touch "$STUB_DIR/slow-coding"; sleep "$STUB_SLOW_CODING"; }   # a session to interrupt
    if [[ ${STUB_WEEKLY:-} ]]; then   # the rate-limit event every real session carries: this one reports the 7-day window
      now=$(date +%s); echo "{\"type\":\"rate_limit_event\",\"rate_limit_info\":{\"status\":\"allowed\",\"resetsAt\":$(( now + 3600 )),\"rateLimitType\":\"five_hour\",\"unifiedWindows\":{\"five_hour\":{\"utilization\":0.2,\"resetsAt\":$(( now + 3600 ))},\"seven_day\":{\"utilization\":$STUB_WEEKLY,\"resetsAt\":$(( now + 259200 ))}}}}"
    fi
    if [[ ${STUB_LIMIT_HITS:-} ]] && (( $(count limit) <= STUB_LIMIT_HITS )); then   # the real 2026-10-17 limit, nothing done
      cat "$HERE/fixtures/usage-limit.jsonl"; exit 1
    fi
    if [[ ${STUB_NOWORK:-} ]] && (( $(count nowork) == 1 )); then   # an error that isn't a limit: $0, one turn
      echo '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":0,"num_turns":1,"duration_ms":400,"result":""}'; exit 0
    fi
    id=$(sed -n 's/^# Coding session — `\([^`]*\)`.*/\1/p' <<< "$first"); n=$(count "$id")
    echo "$id attempt $n" >> "$HARNESS_SCRATCH/sessions.log"
    if [[ ${STUB_PARK:-} == "$id" && $n == 1 ]]; then   # can't go on without Michael: asks in INBOX.md, parks
      sed -i '/^## Answers/i ### '"$id"': set the gatus vars, then answer\n' "$HARNESS_RUN_DIR/INBOX.md"
      git add -A && git commit -qm "$id: question for Michael" && git push -q origin "$HARNESS_BRANCH"
      ok 0.3 "Not done: needs two values only Michael can set.\\nPARKED: set the gatus vars"; exit 0
    fi
    if [[ ${STUB_LIMIT_MIDWAY:-} ]] && (( $(count midway) == 1 )); then   # real work, then the limit cuts the session off
      echo "half of $id" > "half-$id.txt"; git add -A && git commit -qm "$id: half"
      ok 1.4 "working"; sed -n 2p "$HERE/fixtures/usage-limit.jsonl" | sed 's/"total_cost_usd":0/"total_cost_usd":1.4/'
      echo '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":1.4,"num_turns":0,"duration_ms":0,"result":""}'   # as 22-T4-09: a background task's empty result after the cut
      exit 1
    fi
    set_passes "$id" true
    if [[ ${STUB_PASS_THEN_LIMIT:-} && $id == A && $n == 1 ]]; then   # claims the feature, then the limit cuts it off
      echo "A $n" > "work-A.txt"; git add -A && git commit -qm "A: claimed"; sed -n 2p "$HERE/fixtures/usage-limit.jsonl"; exit 1
    fi
    if [[ $id == B && $n == 1 && ! ${STUB_NO_TAMPER:-} ]]; then   # tampers: flips C and rewrites its description
      node -e 'const fs=require("fs"),f=process.argv[1],l=JSON.parse(fs.readFileSync(f));const c=l.features.find(x=>x.id==="C");c.passes=true;c.description="easier";fs.writeFileSync(f,JSON.stringify(l))' "$L"
    fi
    if [[ $id == C ]]; then [[ $n == 1 && ! ${STUB_NO_RED:-} ]] && touch BROKEN || rm -f BROKEN; fi   # first try leaves the suite red
    echo "$id $n" > "work-$id.txt"
    git add -A && git commit -qm "$id: stub work ($n)" && git push -q origin "$HARNESS_BRANCH"
    ok ;;
  "# Verify session"*)
    m=$(sed -n 's/^# Verify session — milestone \([^ ]*\).*/\1/p' <<< "$first"); n=$(count "verify-$m")
    echo "verify $m $n" >> "$HARNESS_SCRATCH/sessions.log"
    if [[ ${STUB_VERIFY_LIMIT:-} && $m == M1 && $n == 1 ]]; then cat "$HERE/fixtures/usage-limit.jsonl"; exit 1; fi   # refused
    if [[ ${STUB_VERIFY_EDITS:-} && $n == 1 ]]; then echo hack > "hack-$m.txt"; echo "edited" >> CLAUDE.md; fi   # a verifier "fixing" code
    [[ $m == M1 && ( $n == 1 || ${STUB_STRICT_VERIFIER:-} ) && ! ${STUB_LENIENT:-} ]] && set_passes A false   # catches a false pass
    { sed -n '1,2p' "$HARNESS_RUN_DIR/progress.md"; echo "### $(date '+%F %H:%M') · verify $m"; echo
      echo "| Feature | Step | Ran | Saw | Holds |"; echo "|---|---|---|---|---|"
      if [[ ! ${STUB_THIN_VERIFY:-} || $n -gt 1 ]]; then
        node -e 'const l=JSON.parse(require("fs").readFileSync(process.argv[1]));for(const f of l.features.filter(f=>f.milestone===process.argv[2]))f.steps.forEach((s,i)=>console.log(`| ${f.id} | ${i+1} | check | ok | yes |`))' "$L" "$m"
      fi; echo; sed -n '3,$p' "$HARNESS_RUN_DIR/progress.md"; } > "$HARNESS_SCRATCH/p.md" && mv "$HARNESS_SCRATCH/p.md" "$HARNESS_RUN_DIR/progress.md"
    git add -A && git commit -qm "verify $m ($n)" --allow-empty && git push -q origin "$HARNESS_BRANCH"
    ok 0.1 ;;
  "# Retro"*)
    echo "retro" >> "$HARNESS_SCRATCH/sessions.log"
    [[ ${STUB_RETRO_EDITS:-} ]] && { echo "retro was here" > retro-hack.txt; echo x >> "$HARNESS_RUN_DIR/progress.md"; }
    ok 0.2 "## Outcome\\nStub retro.\\n\\n## Proposed harness changes\\n1. none" ;;
  "# Probe session"*)   # records its command line, $PWD and prompt; for t2, Q1 (T2a's files) is right and Q2 (T2b's deps) wrong
    { printf '%s\n' "${ARGS[@]}"; echo "PWD=$PWD"; echo "HARNESS_EVAL=${HARNESS_EVAL:-}"; } > "$STUB_DIR/probe-args"; printf '%s\n' "$prompt" > "$STUB_DIR/probe-prompt"
    [[ ${STUB_PROBE_ERROR:-} ]] && { echo "warning: noise on stderr" >&2
      cat "$HERE/fixtures/usage-limit.jsonl"; exit 1; }   # the real capture of a refused session
    ok 0.01 "Q1: work-T2a.txt\\nQ2: nothing" ;;
  "# Debrief"*)   # records its command line and prompt; STUB_DEBRIEF_CONTINUE="<run>…": asks to continue each
    printf '%s\n' "${ARGS[@]}" > "$STUB_DIR/debrief-args"; printf '%s\n' "$prompt" > "$STUB_DIR/debrief-prompt"
    [[ ${STUB_DEBRIEF_LIMIT:-} ]] && { cat "$HERE/fixtures/usage-limit.jsonl"; exit 1; }
    if [[ ${STUB_DEBRIEF_ERROR:-} ]]; then
      echo '{"type":"result","subtype":"error_max_turns","is_error":true,"total_cost_usd":0.4,"num_turns":40,"result":"Error: reached max turns"}'; exit 1
    fi
    [[ ${STUB_DEBRIEF_DEAD:-} ]] && { echo "Error: unknown option '--whatever'" >&2; exit 1; }   # dies at startup
    [[ ${STUB_DEBRIEF_TOUCH:-} ]] && echo x > "$STUB_DEBRIEF_TOUCH"   # writes a file while it runs
    echo "debrief" >> "$STUB_DIR/debriefs.log"
    note=$'## Headline\nLanded: proj M1, M2 on main.\nBlocked: nothing.\nSpend $1.20; window open.\nFOURTH headline line\n\n## Runs\nstub runs <i>raw</i>\n\n## Needs Michael\n_Nothing._\n'
    [[ ${STUB_DEBRIEF_NEEDS:-} ]] && note=${note/Blocked: nothing./Blocked: parky B waits on Michael.} note=${note/_Nothing._/parky B: set the gatus vars (progress.md)}
    lead="- "; for r in ${STUB_DEBRIEF_CONTINUE:-}; do note+=$'\n'"${lead}CONTINUE: $r :: do C next"; lead=""; done
    jq -cn --arg r "$note" '{type:"result",subtype:"success",is_error:false,total_cost_usd:0.3,duration_ms:1000,num_turns:5,result:$r}' ;;
esac
