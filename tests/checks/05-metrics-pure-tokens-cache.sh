#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- metrics: the session-id and summary CLI (the pure evals and the resume row are tests/unit/metrics.test.mjs) ----
# a resume (R2): the init line's session id
R=$HERE/fixtures/claude-resume
check "metrics: session-id prints the init line's session_id of first.jsonl" '[[ $(node "$HERE/../lib/metrics.mjs" session-id "$R/first.jsonl") == "$(jq -r "select(.type == \"system\" and .subtype == \"init\").session_id" "$R/first.jsonl")" ]] \
  && ! node "$HERE/../lib/metrics.mjs" session-id "$R/unknown-id.out" > /dev/null'
printf '%s\n' '{"kind":"coding","feature":"A","model":"opus","cost_usd":1.5,"turns":9,"passes":true}' '{"kind":"entry-resume","feature":"A","model":"opus","cost_usd":0.25,"turns":2,"passes":false}' > "$T/resume-metrics.jsonl"
check "metrics: summary counts an entry-resume row's cost but never as a session" '[[ $(node "$HERE/../lib/metrics.mjs" summary "$T/resume-metrics.jsonl") == "1 sessions (1 real) · 1 features passed · \$1.75 · "* ]]'

suite_end
