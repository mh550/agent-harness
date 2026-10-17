#!/usr/bin/env bash
# Stand-in for `claude -p` in tests: acts out initializer / coding / verify / retro sessions from the prompt's first line,
# including scripted misbehaviour, and prints stream-json lines like the real CLI. Usage limits replay the real
# lines captured on 2026-10-17 (fixtures/usage-limit.jsonl): fakes mirror the live API.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
ARGS=("$@"); prompt=""; while (( $# )); do [[ $1 == -p ]] && { prompt=$2; shift; }; shift; done
first=$(head -1 <<< "$prompt")
L=${HARNESS_RUN_DIR:-.}/feature_list.json
count() { local f=$HARNESS_SCRATCH/count-$1 n; n=$(( $(cat "$f" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$f"; echo "$n"; }
set_passes() { node -e 'const fs=require("fs"),[f,id,v]=process.argv.slice(1),l=JSON.parse(fs.readFileSync(f));for(const x of l.features)if(x.id===id)x.passes=v==="true";fs.writeFileSync(f,JSON.stringify(l,null,2))' "$L" "$1" "$2"; }
ok() { echo "{\"type\":\"result\",\"subtype\":\"success\",\"is_error\":false,\"total_cost_usd\":${1:-0.25},\"duration_ms\":60000,\"num_turns\":12,\"result\":\"${2:-done}\"}"; }

case $first in
  "# Initializer session"*)
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
    if [[ ${STUB_LIMIT_HITS:-} ]] && (( $(count limit) <= STUB_LIMIT_HITS )); then   # the real 2026-10-17 limit, nothing done
      cat "$HERE/fixtures/usage-limit.jsonl"; exit 1
    fi
    if [[ ${STUB_NOWORK:-} ]] && (( $(count nowork) == 1 )); then   # an error that isn't a limit: $0, one turn
      echo '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":0,"num_turns":1,"duration_ms":400,"result":""}'; exit 0
    fi
    id=$(sed -n 's/^# Coding session — `\([^`]*\)`.*/\1/p' <<< "$first"); n=$(count "$id")
    echo "$id attempt $n" >> "$HARNESS_SCRATCH/sessions.log"
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
  "# Debrief"*)   # records its command line; STUB_DEBRIEF_CONTINUE: asks for continuations (one eligible, one not)
    echo "debrief" >> "$STUB_DIR/debriefs.log"; printf '%s\n' "${ARGS[@]}" > "$STUB_DIR/debrief-args"
    printf '%s\n' "$prompt" > "$STUB_DIR/debrief-prompt"
    note=$'## Headline\nLanded: proj M1, M2 on main.\nBlocked: nothing.\nSpend $1.20; window open.\nFOURTH headline line\n\n## Runs\nstub runs\n'
    [[ ${STUB_DEBRIEF_CONTINUE:-} ]] && note+=$'\nCONTINUE: stoppy :: do C next\nCONTINUE: demo :: again\n'
    jq -cn --arg r "$note" '{type:"result",subtype:"success",is_error:false,total_cost_usd:0.3,duration_ms:1000,num_turns:5,result:$r}' ;;
esac
