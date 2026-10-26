#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 12: a session claims its feature, then the limit cuts it off: the claim is reverted ----
{ cat "$T/base-config.sh"; echo 'MERGE_POLICY=pr'; } > "$T/user-config.sh"   # its milestones are proposed, not merged
STUB_PASS_THEN_LIMIT=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" claim --spec SPEC.md --foreground > "$T/run12.out" 2>&1
cp "$T/base-config.sh" "$T/user-config.sh"
# the record's list (harness/claim) never shows A passing before A's second session's entry: the cut claim never reached it
cl_rec() { local c n=0; for c in $(git -C "$T/origin.git" rev-list --reverse harness/claim -- .harness/runs/claim/feature_list.json); do
  git -C "$T/origin.git" show "$c:.harness/runs/claim/feature_list.json" | jq -e ".features[] | select(.id == \"A\") | .passes" > /dev/null || continue
  [[ $(git -C "$T/origin.git" show "$c:.harness/runs/claim/entries.jsonl" | jq -s "map(select(.feature == \"A\")) | length") -ge 2 ]] || return 1; n=$(( n + 1 )); done; (( n )); }
check "a limit-cut session's passes is reverted, A retried" 'grep -q "A attempt 2" "$T/scratch/proj/claim/sessions.log" && cl_rec'
check "a refused session's minimal entry is not yet, not its reverted claim (E4 review F3)" 'jq -se "map(select(.feature == \"A\")) | .[0].outcome == \"not yet\" and .[0].minimal == \"missing\" and .[-1].outcome == \"passes\"" \
  "$T/wt/proj/claim/.harness/runs/claim/entries.jsonl" > /dev/null'
check "a proposed merge: ready to merge, click = the PR, default priority" 'Bp=$(curl_with "[claim] M1 verified · review:"); U=$(grep -o "https://example.test/pr/[0-9]*" <<< "$Bp" | head -1) \
  && [[ -n $U ]] && grep -qx "Title: \[claim\] M1 ready to merge" <<< "$Bp" && grep -qx "Click: $U" <<< "$Bp" && ! grep -q "^Priority:" <<< "$Bp"'

suite_end
