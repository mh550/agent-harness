#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- metrics, pure: tokens, cache and context peak from the real capture (fixtures/usage-tokens.jsonl, E1) ----
TOKS='import { outcome, events } from "'$HERE'/../lib/metrics.mjs"; const o = outcome(events("'$HERE'/fixtures/usage-tokens.jsonl")), n = outcome([{ type: "result", total_cost_usd: 0 }]);
  process.exit(o.tokens_in === 4 && o.cache_read === 35768 && o.cache_write === 13651 && o.tokens_out === 219 && o.cache_hit_rate === 0.724 && o.context_peak === 24881
    && n.tokens_in === null && n.cache_hit_rate === null && n.context_peak === null ? 0 : 1);'
check "metrics.mjs: tokens, cache rate and context peak from the real fixture" 'node --input-type=module -e "$TOKS"'
# Orientation: the capture's first message (thinking, then Write, one message.id) is the first edit, so it alone counts;
# without the Write event both messages count, timed to the last event. No usage → null; no timestamps → seconds null;
# an edit event without one is timed by the last stamped event before it.
ORNT='import { orientation as or, events } from "'$HERE'/../lib/metrics.mjs"; const evs = events("'$HERE'/fixtures/usage-tokens.jsonl"), eq = (a, b) => JSON.stringify(a) === JSON.stringify(b);
  const noEdit = evs.filter(e => !e.message?.content?.some(c => c.name === "Write")), noTs = evs.map(({ timestamp, ...e }) => e);
  process.exit(eq(or(evs), { tokens: 24547, turns: 1, seconds: 0.233 }) && eq(or(noEdit), { tokens: 49432, turns: 2, seconds: 1.441 })
    && eq(or(noTs), { tokens: 24547, turns: 1, seconds: null }) && eq(or(evs.map((e, i) => i === 1 ? noTs[1] : e)), { tokens: 24547, turns: 1, seconds: 0 }) && eq(or([{ type: "result" }]), { tokens: null, turns: null, seconds: null }) ? 0 : 1);'
check "metrics.mjs: orientation stops at the first Write" 'node --input-type=module -e "$ORNT"'

# A resume (R2): the init line's session id, and an entry-resume row that holds the resume's cumulative figures minus the
# session's (total_cost_usd and modelUsage are cumulative over a session id), compared with what jq computes from the files
R=$HERE/fixtures/claude-resume
check "metrics: session-id prints the init line's session_id of first.jsonl" '[[ $(node "$HERE/../lib/metrics.mjs" session-id "$R/first.jsonl") == "$(jq -r "select(.type == \"system\" and .subtype == \"init\").session_id" "$R/first.jsonl")" ]] \
  && ! node "$HERE/../lib/metrics.mjs" session-id "$R/unknown-id.out" > /dev/null'
RESUME='import { resumeRow, events } from "'$HERE'/../lib/metrics.mjs"; const [a, b, want, tin] = process.argv.slice(1), r = resumeRow(events(a), events(b), ["", "", "", "run", "A", "opus", "coding", "30", "0", "null", "M1"]);
  console.error(JSON.stringify(r)); process.exit(r.kind === "entry-resume" && r.role === "coding" && r.feature === "A" && r.lane === "M1" && r.cost_usd === Number(want) && r.cost_usd > 0 && r.tokens_in === Number(tin) && r.passes === false ? 0 : 1);'
dcost() { jq -n --slurpfile a "$1" --slurpfile b "$2" 'def c(x): x | map(select(.type == "result"))[-1].total_cost_usd; c($b) - c($a)'; }
duse() { jq -r 'select(.type == "result").usage.input_tokens' "$1"; }
check "metrics: an entry-resume row from first.jsonl and resumed.jsonl holds the total_cost_usd difference jq computes" 'node --input-type=module -e "$RESUME" "$R/first.jsonl" "$R/resumed.jsonl" "$(dcost "$R/first.jsonl" "$R/resumed.jsonl")" "$(duse "$R/resumed.jsonl")"'
check "metrics: resumed-again-under-cap.jsonl against resumed.jsonl gives a positive difference" 'node --input-type=module -e "$RESUME" "$R/resumed.jsonl" "$R/resumed-again-under-cap.jsonl" "$(dcost "$R/resumed.jsonl" "$R/resumed-again-under-cap.jsonl")" "$(duse "$R/resumed-again-under-cap.jsonl")"'

suite_end
