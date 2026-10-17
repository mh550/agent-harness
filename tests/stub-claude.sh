#!/usr/bin/env bash
# Stand-in for `claude -p` in tests: acts out initializer / coding / verify sessions from the prompt's first line,
# including scripted misbehaviour, and prints a stream-json result line like the real CLI.
set -euo pipefail
prompt=""; while (( $# )); do [[ $1 == -p ]] && { prompt=$2; shift; }; shift; done
first=$(head -1 <<< "$prompt")
L=$HARNESS_RUN_DIR/feature_list.json
count() { local f=$HARNESS_SCRATCH/count-$1 n; n=$(( $(cat "$f" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$f"; echo "$n"; }
set_passes() { node -e 'const fs=require("fs"),[f,id,v]=process.argv.slice(1),l=JSON.parse(fs.readFileSync(f));for(const x of l.features)if(x.id===id)x.passes=v==="true";fs.writeFileSync(f,JSON.stringify(l,null,2))' "$L" "$1" "$2"; }

case $first in
  "# Initializer session"*)
    cat > "$L" <<'EOF'
{ "run": "test", "features": [
  { "id": "A", "milestone": "M1", "model": "sonnet", "description": "a", "steps": ["x"], "passes": false },
  { "id": "B", "milestone": "M1", "description": "b", "steps": ["y"], "passes": false },
  { "id": "C", "milestone": "M2", "model": "opus", "description": "c", "steps": ["z"], "passes": false } ] }
EOF
    printf '# progress\n' > "$HARNESS_RUN_DIR/progress.md"
    git add -A && git commit -qm "HARNESS: feature list" && git push -q -u origin "$HARNESS_BRANCH"
    if [[ ${STUB_PHONE_STOP:-} ]]; then   # Michael edits INBOX.md on GitHub: status: stop
      tmp=$(mktemp -d); git clone -q "$(git remote get-url origin)" "$tmp" -b "$HARNESS_BRANCH"
      sed -i '1s/.*/status: stop/' "$tmp/$HARNESS_RUN_DIR/INBOX.md"
      git -C "$tmp" commit -qam "phone: stop" && git -C "$tmp" push -q origin "$HARNESS_BRANCH"
    fi ;;
  "# Coding session"*)
    id=$(sed -n 's/^# Coding session — `\([^`]*\)`.*/\1/p' <<< "$first"); n=$(count "$id")
    echo "$id attempt $n" >> "$HARNESS_SCRATCH/sessions.log"
    set_passes "$id" true
    if [[ $id == B && $n == 1 ]]; then   # tampers: flips C and rewrites its description
      node -e 'const fs=require("fs"),f=process.argv[1],l=JSON.parse(fs.readFileSync(f));const c=l.features.find(x=>x.id==="C");c.passes=true;c.description="easier";fs.writeFileSync(f,JSON.stringify(l))' "$L"
    fi
    if [[ $id == C ]]; then [[ $n == 1 ]] && touch BROKEN || rm -f BROKEN; fi   # first try leaves the suite red
    git add -A && git commit -qm "$id: stub work ($n)" && git push -q origin "$HARNESS_BRANCH" ;;
  "# Verify session"*)
    m=$(sed -n 's/^# Verify session — milestone \([^ ]*\).*/\1/p' <<< "$first"); n=$(count "verify-$m")
    [[ $m == M1 && ( $n == 1 || ${STUB_STRICT_VERIFIER:-} ) ]] && set_passes A false   # catches a false pass (always, if strict)
    git add -A && git commit -qm "verify $m ($n)" --allow-empty && git push -q origin "$HARNESS_BRANCH" ;;
esac
echo '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":0.25,"duration_ms":60000,"num_turns":12}'
