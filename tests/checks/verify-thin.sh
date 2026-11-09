#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the thin verify names its missing steps (decisions/2026-11-09-thin-verify-and-comment-lines). The stub's thin
# round writes every row but each feature's last step's: run agent-harness-2026-11-08's verifier folded the fast tier
# into the row before it, twice, and the note said only `N1-03 6/7`. The rule stays: fewer rows than steps is thin ----
SHORT="A 1/2: step 2 has no row; B 0/1: step 1 has no row"
main0=$(git -C "$T/origin.git" rev-parse main)   # the second run starts from it, not from the first run's merges

# round 1 thin, the escalated round full: the note names the steps, the escalated prompt carries them, M1 then holds
STUB_THIN_VERIFY=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" vth --spec SPEC.md --foreground > "$T/vth.out" 2>&1
check "thin verify: the note names each step with no row, per feature, from the rows' step numbers" \
  'hlog vth | grep -F "verify M1: evidence short of the steps ($SHORT); re-running on" > /dev/null'
P1=$T/scratch/proj/vth/verify-M1-1.prompt.md P2=$T/scratch/proj/vth/verify-M1-2.prompt.md   # the stub keeps each round's prompt
check "thin verify: the escalated round's prompt carries the note's words under This session; the first round's has no such section; the round then holds and merges" \
  '[[ -s $P1 && -s $P2 ]] && ! grep -F "round before this one" "$P1" > /dev/null \
  && grep -F "Its evidence fell short of the steps: $SHORT." "$P2" > /dev/null \
  && awk "/^# This session$/ { s = 1 } s && /^## The round before this one$/ { f = 1 } END { exit !f }" "$P2" && on_main run/vth/M1'

# thin in every round: the last note and the card name the steps
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
STUB_THIN_VERIFY=all STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" vthall --spec SPEC.md --foreground > "$T/vthall.out" 2>&1
check "thin verify: after the escalated round the note and the card's why name the steps with no row" \
  'hlog vthall | grep -F "verify M1: evidence still short of the steps ($SHORT) after " > /dev/null \
  && jq -se "any(.key == \"verify_thin:M1\" and (.card.why | endswith(\"only the evidence is short: $SHORT.\")))" "$HARNESS_STATE"/proj/vthall/needs/*.json > /dev/null'

suite_end
