#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 9c: refused sessions in an earlier segment aren't the cause of a later ending ----
STUB_LIMIT_HITS=6 "$H" start "$T/proj" stale --spec SPEC.md --foreground > "$T/run9c.out" 2>&1; rm -f "$HARNESS_STATE/LIMIT_UNTIL"
S9=$T/wt/proj/stale/.harness/runs/stale/summary.json
check "a limit ending: the cause is the usage limit" '[[ $(jq -r ".features_detail[0].cause" "$S9") == "usage limit" ]]'
"$H" continue stale --until-epoch $(( $(date +%s) - 60 )) --foreground > "$T/run9d.out" 2>&1
check "a later deadline: the earlier refusals aren't the cause" '[[ $(jq -r .end_reason "$S9") == deadline && $(jq -r ".features_detail[0].cause" "$S9") == "not reached" ]]'

suite_end
