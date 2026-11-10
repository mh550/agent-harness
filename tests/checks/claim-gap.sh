#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- a claim that never reached the list (decisions/2026-11-09-claim-gap): the demo scenario, verify M1 round 1 un-passes A,
# A's retry says passes in its entry and final message but never flips the key (STUB_NO_FLIP=A:2); the gap is named, the
# feature gets one told retry whose prompt carries the words, that retry flips, M1 verifies in round 2 and merges ----
STUB_NO_FLIP=A:2 STUB_NO_TAMPER=1 STUB_NO_RED=1 "$H" start "$T/proj" cg1 --spec SPEC.md --foreground > "$T/cg1.out" 2>&1
GAP="A: its entry says passes but feature_list.json's passes stayed false; the claim never reached the list (the flip is the session's one list edit, prompts/coding.md §3.1)"
atf() { hlog "$1" | grep -n -m1 -F -- "$2" | cut -d: -f1; }   # <run> <text>: the line of the first note holding it
nth() { hlog "$1" | grep -n -F -- "$2" | sed -n "${3}p" | cut -d: -f1; }   # <run> <text> <k>: the k-th note holding it
check "a claim that never reached the list is named at the session's end" \
  'r=$(atf cg1 "verify M1: A failed the re-check") s=$(nth cg1 "· A: suite ran" 2) g=$(atf cg1 "· $GAP") p=$(nth cg1 "· A · " 2)
   [[ -n $r && -n $s && -n $g && -n $p ]] && (( r < s && s < g && g < p )) && hlog cg1 | sed -n "${p}p" | grep -q "passes=false"'
# the third A session is the told retry: its prompt (beside its transcript) carries the block; the second's doesn't
P3=$(ls "$HARNESS_STATE"/proj/cg1/logs/*-A.prompt.md 2> /dev/null | sort -V | tail -1) P2=$(ls "$HARNESS_STATE"/proj/cg1/logs/*-A.prompt.md 2> /dev/null | sort -V | tail -2 | head -1)
check "the claim gap gets one told retry, its prompt carrying the same words" \
  'grep -q "A attempt 3" "$T/scratch/proj/cg1/sessions.log" && [[ $(grep -c "A attempt" "$T/scratch/proj/cg1/sessions.log") == 3 ]] \
   && hlog cg1 | grep -F "· A: one more attempt, told to set passes (once per run)" > /dev/null \
   && [[ -s $P3 && -s $P2 && $P3 != "$P2" ]] && grep -qx "## The session before this one" "$P3" && grep -qF -- "$GAP. Check every step holds on this tree" "$P3" \
   && ! grep -q "The session before this one" "$P2" && awk "/^# This session\$/ { s = 1 } /^## The session before this one\$/ && s { f = 1 } END { exit !f }" "$P3"'
check "the told retry's flip passes and the milestone verifies and merges" \
  'grep -q "verify M1 2" "$T/scratch/proj/cg1/sessions.log" && git -C "$T/origin.git" tag | grep -qx run/cg1/M1 && hlog cg1 | grep -F "· lane M1 closed (M1 merged)" > /dev/null \
   && [[ $(hlog cg1 | grep -c "· A · .* · passes=true") == 2 ]]'

# ---- the told retry fails to flip too (STUB_NO_FLIP=A:2,A:3): no second grant, the lane closes naming A, its attempts
# and the gap, and the given_up card says the re-check sent it back and the told retry did not set passes ----
STUB_NO_FLIP=A:2,A:3 STUB_NO_TAMPER=1 STUB_NO_RED=1 "$H" start "$T/proj" cg2 --spec SPEC.md --foreground > "$T/cg2.out" 2>&1
RD2=$T/wt/proj/cg2/.harness/runs/cg2
check "a second claim gap grants nothing: the lane closes naming the feature, its attempts and the gap" \
  '[[ $(grep -c "A attempt" "$T/scratch/proj/cg2/sessions.log") == 3 ]] && [[ $(hlog cg2 | grep -c -F "· $GAP") == 2 ]] \
   && [[ $(hlog cg2 | grep -c "· A: one more attempt, told to set passes") == 1 ]] \
   && hlog cg2 | grep -F "· lane M1 closed (given up (A after 2 attempts: its entry says passes but feature_list.json'"'"'s passes stayed false))" > /dev/null \
   && ! hlog cg2 | grep -q "nothing left to try)" && [[ $(cat "$HARNESS_STATE/proj/cg2/lanes/M1/closed") == "10 given up (A after 2 attempts: its entry says passes but feature_list.json'"'"'s passes stayed false)" ]]'
check "the given-up card says the re-check sent it back and the told retry did not set passes" \
  'grep -q "A given up after 2 attempts" "$RD2/needs.md" && grep -F "The verify'"'"'s re-check sent it back (\`verify M1: A failed the re-check\`), and $GAP; its told retry did not set it either." "$RD2/needs.md" > /dev/null \
   && ! grep -q "Its sessions'"'"' entries say what failed" "$RD2/needs.md" \
   && [[ $(jq -r "select(.reason == \"given_up\") | .card.why" "$HARNESS_STATE"/proj/cg2/needs/*.json | grep -c "its told retry did not set it either") == 1 ]]'

suite_end
