#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the replay set (E2): every committed task validates; each error names its field ----
# validateTask, compare and compareText are tests/unit/eval.test.mjs; what stays here is the validate CLI on this repo's tasks
mkdir -p "$T/evbad/nofeat" && jq -n '{id:"nofeat",project:"p",repo:"/r",base:("a"*40),policy:"build-only",why:"w"}' > "$T/evbad/nofeat/task.json"
check "eval: every task.json validates and a bad one is rejected" 'node "$HERE/../lib/eval.mjs" validate "$HERE/../evals/tasks" 2> /dev/null \
  && ! node "$HERE/../lib/eval.mjs" validate "$T/evbad" > "$T/evbad.out" 2>&1 && grep -q "nofeat/task.json: features: required" "$T/evbad.out" \
  && [[ -z $(grep -v "^#" "$HERE/../evals/sets/default.txt" | while read -r t; do [[ -f "$HERE/../evals/tasks/$t/task.json" ]] || echo "$t"; done) ]]'

suite_end
