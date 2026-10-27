#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 19: the review gate (M6): a review feature runs on sonnet under REVIEW_OPUS_LINES changed lines, opus at or over ----
# M1 is A, B, D (build) and R (review); verify is lenient so each run ends done. rbig's A also commits a 500-line file.
# R's entry summary reports 1 Critical in rsmall and rbig, nothing in rnone (an escalation round only in rsmall).
STUB_REVIEW_LIST=1 STUB_LENIENT=1 STUB_REVIEW_FINDINGS=1,0 "$H" start "$T/proj" rsmall --spec SPEC.md --foreground > "$T/rsmall.out" 2>&1
git pull -q --ff-only origin main
STUB_REVIEW_LIST=1 STUB_LENIENT=1 STUB_BIG_DIFF=1 STUB_REVIEW_FINDINGS=1,0 "$H" start "$T/proj" rbig --spec SPEC.md --foreground > "$T/rbig.out" 2>&1
git pull -q --ff-only origin main
STUB_REVIEW_LIST=1 STUB_LENIENT=1 STUB_REVIEW_FINDINGS=0,0 "$H" start "$T/proj" rnone --spec SPEC.md --foreground > "$T/rnone.out" 2>&1
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
check "review gate: a sonnet review reporting 1 Critical gets one round on opus at no attempt" \
  '[[ $(met rsmall R | paste -sd " " -) == *sonnet*" "*opus* && $(met rsmall R | wc -l) == 2 ]] \
  && hlog rsmall | grep -qE "· review R: sonnet found 1 Critical, 0 Important; one round on opus$" \
  && [[ $(jq -r .R "$HARNESS_STATE/proj/rsmall/attempts.json") == 1 ]] && grep -q "^done" "$HARNESS_STATE/proj/rsmall/ended"'
check "review gate: a review reporting 0 Critical, 0 Important is not escalated and the run ends done" \
  '[[ $(met rnone R | wc -l) == 1 && $(met rnone R) == *sonnet* ]] && ! hlog rnone | grep -q "one round on" \
  && grep -q "^done" "$HARNESS_STATE/proj/rnone/ended"'
check "review gate: a review on opus never escalates; the escalation round's clock says Review round 2 of 2" \
  '[[ $(met rbig R | wc -l) == 1 && $(met rbig R) == *opus* ]] && ! hlog rbig | grep -q "one round on" \
  && p2=$(ls "$HARNESS_STATE/proj/rsmall/logs/"*-R.prompt.md | sed -n 2p) && [[ -s $p2 ]] \
  && grep -qE "^Clock: .* · Review round 2 of 2 \(escalated: sonnet found 1 Critical, 0 Important\)$" "$p2" \
  && grep -qE "^Review diff: [0-9]+ files, [0-9]+ changed lines .*; under 400; sonnet$" "$p2" && ! grep -q "Review round" "$(plog rsmall R)"'

suite_end
