#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 19: the review gate (M6): a review feature runs on sonnet under REVIEW_OPUS_LINES changed lines, opus at or over ----
# M1 is A, B, D (build) and R (review); verify is lenient so each run ends done. rbig's A also commits a 500-line file.
STUB_REVIEW_LIST=1 STUB_LENIENT=1 "$H" start "$T/proj" rsmall --spec SPEC.md --foreground > "$T/rsmall.out" 2>&1
git pull -q --ff-only origin main
STUB_REVIEW_LIST=1 STUB_LENIENT=1 STUB_BIG_DIFF=1 "$H" start "$T/proj" rbig --spec SPEC.md --foreground > "$T/rbig.out" 2>&1
met() { jq -r --arg f "$2" 'select(.feature == $f and .kind == "coding") | .model' "$T/wt/proj/$1/.harness/runs/$1/metrics.jsonl" 2> /dev/null; }   # <run> <id> → its coding rows' models
plog() { ls "$HARNESS_STATE/proj/$1/logs/"*-"$2".prompt.md 2> /dev/null | head -1; }   # <run> <id> → its first session's prompt copy
check "review gate: a review under REVIEW_OPUS_LINES runs on sonnet, noted with its changed lines" \
  '[[ $(met rsmall R | head -1) == *sonnet* ]] && hlog rsmall | grep -qE "· review R: [0-9]+ changed lines, under 400; sonnet$" \
  && (( $(hlog rsmall | sed -n "s/.*· review R: \([0-9]*\) changed lines.*/\1/p" | head -1) > 0 ))'
check "review gate: a review at or over REVIEW_OPUS_LINES runs on opus" \
  '[[ $(met rbig R | head -1) == *opus* ]] && hlog rbig | grep -qE "· review R: [0-9]+ changed lines, at or over 400; opus$" \
  && (( $(hlog rbig | sed -n "s/.*· review R: \([0-9]*\) changed lines.*/\1/p" | head -1) >= 500 ))'
check "review gate: the review's prompt copy has its Review diff line, a build session's has none" \
  'n=$(hlog rsmall | sed -n "s/.*· review R: \([0-9]*\) changed lines.*/\1/p" | head -1) \
  && grep -qE "^Review diff: [0-9]+ files, $n changed lines .*; under 400; sonnet$" "$(plog rsmall R)" \
  && grep -qE "^Review diff: [0-9]+ files, [0-9]+ changed lines .*; at or over 400; opus$" "$(plog rbig R)" \
  && [[ -s $(plog rsmall A) ]] && ! grep -q "Review diff:" "$(plog rsmall A)" && ! grep -q "{{REVIEW_DIFF}}" "$(plog rsmall A)"'

suite_end
