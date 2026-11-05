#!/usr/bin/env bash
# tier: slow
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- fix rounds (docs/specs/2026-11-04-run-resilience.md M3, decisions/2026-11-04-fix-rounds): a red verify is fixed, not parked ----
# 87-fast-gate-run's two-tier stub suite, extended. .harness/suite.sh logs every call's arguments (`bare` for none) to
# suite-args.log in the run's scratch and prints a red as the real suite does: `FAIL <the check's whole name>`, then
# `HARNESS_FAILED=<its file>` (tests/lib.sh, tests/run.sh). Bare: red on BROKEN or BROKEN-SLOW (t1), on BROKEN-SLOW2
# (t3), and with STUB_FLAKE_ONCE=1 once on t2 when flake-armed is in the run's scratch (removed: the rerun is green).
# --tier fast: red on BROKEN or BROKEN-FAST. A subset (a fix feature's gate, the rerun guard): red only on a named
# file's own marker (t1: BROKEN-SLOW, t3: BROKEN-SLOW2); gate-green-once in the run's scratch makes the next subset
# green and goes (a fix session that passes its gate while the tree stays red: tests/stub-claude.sh STUB_FIX=rename).
cat > .harness/suite.sh <<'EOF'
#!/usr/bin/env bash
S=${HARNESS_SCRATCH%%/lanes/*}
echo "${*:-bare}" >> "$S/suite-args.log"
red() { printf '%s\n' "FAIL $1" "HARNESS_FAILED=$1" "0/1 checks passed"; exit 1; }
case ${1:-} in
  "") [[ -f BROKEN || -f BROKEN-SLOW ]] && red t1
    [[ -f BROKEN-SLOW2 ]] && red t3
    if [[ ${STUB_FLAKE_ONCE:-} == 1 && -f $S/flake-armed ]]; then rm -f "$S/flake-armed"; red t2; fi
    pass=(t1 t2 t3) ;;
  --tier) [[ -f BROKEN || -f BROKEN-FAST ]] && red t1
    pass=(t1 t2) ;;
  *) if [[ -f $S/gate-green-once ]]; then rm -f "$S/gate-green-once"
    else for t; do [[ $t == t1 && -f BROKEN-SLOW ]] && red t1; [[ $t == t3 && -f BROKEN-SLOW2 ]] && red t3; done; fi
    pass=("$@") ;;
esac
for t in "${pass[@]}"; do echo "PASS $t"; done; echo "${#pass[@]}/${#pass[@]} checks passed"
EOF
sed -i 's|^CHECK_CMD=.*|CHECK_CMD="bash .harness/suite.sh"\nCHECK_FAST_CMD="bash .harness/suite.sh --tier fast"|' .harness/config.sh

# the stub suite's forms, in a plain shell (cwd the project): su <args…> → its output and exit code; red_on <t> <args…>
# → 0 when that call is red with `FAIL <t>` and `HARNESS_FAILED=<t>`
P=$T/plain; mkdir -p "$P"
su() { HARNESS_SCRATCH=$P bash .harness/suite.sh "$@" 2>&1; }
red_on() { local t=$1 o; shift; o=$(su "$@") && return 1; [[ $o == "FAIL $t"$'\n'"HARNESS_FAILED=$t"$'\n'* ]]; }
check "fix rounds stub suite: bare is red on BROKEN and BROKEN-SLOW (FAIL t1, HARNESS_FAILED=t1) and on BROKEN-SLOW2 (FAIL t3, HARNESS_FAILED=t3), green with none" \
  '[[ $(su | tail -1) == "3/3 checks passed" ]] && touch BROKEN && red_on t1 && mv BROKEN BROKEN-SLOW && red_on t1 && mv BROKEN-SLOW BROKEN-SLOW2 && red_on t3 \
  && rm BROKEN-SLOW2 && su > /dev/null && [[ $(sed -n 1p "$P/suite-args.log") == bare ]]'
rm -f BROKEN BROKEN-SLOW BROKEN-SLOW2
check "fix rounds stub suite: --tier fast is red on BROKEN or BROKEN-FAST, green on the slow markers" \
  '[[ $(su --tier fast | tail -1) == "2/2 checks passed" ]] && touch BROKEN && red_on t1 --tier fast && mv BROKEN BROKEN-FAST && red_on t1 --tier fast \
  && mv BROKEN-FAST BROKEN-SLOW && su --tier fast > /dev/null && mv BROKEN-SLOW BROKEN-SLOW2 && su --tier fast > /dev/null && [[ $(tail -1 "$P/suite-args.log") == "--tier fast" ]]'
rm -f BROKEN BROKEN-FAST BROKEN-SLOW BROKEN-SLOW2
check "fix rounds stub suite: a subset is red only on its own file's marker (t1 on BROKEN-SLOW, t3 on BROKEN-SLOW2)" \
  'touch BROKEN-SLOW && red_on t1 t1 && red_on t1 t2 t1 && su t3 > /dev/null && [[ $(su t2 t3 | tail -1) == "2/2 checks passed" ]] \
  && mv BROKEN-SLOW BROKEN-SLOW2 && red_on t3 t3 && su t1 > /dev/null && mv BROKEN-SLOW2 BROKEN && su t1 t3 > /dev/null && [[ $(tail -1 "$P/suite-args.log") == "t1 t3" ]]'
rm -f BROKEN BROKEN-SLOW BROKEN-SLOW2
check "fix rounds stub suite: STUB_FLAKE_ONCE=1 makes the first bare call after flake-armed red on t2 and removes it; a fast call, a subset or a call without the flag leaves it" \
  'STUB_FLAKE_ONCE=1 su > /dev/null && touch "$P/flake-armed" && su > /dev/null && STUB_FLAKE_ONCE=1 su --tier fast > /dev/null && STUB_FLAKE_ONCE=1 su t2 > /dev/null \
  && [[ -f $P/flake-armed ]] && STUB_FLAKE_ONCE=1 red_on t2 && [[ ! -e $P/flake-armed ]] && STUB_FLAKE_ONCE=1 su > /dev/null'
rm -f "$P/flake-armed"
check "fix rounds stub suite: gate-green-once makes the next subset green once and goes; a bare call leaves it and stays red" \
  'touch BROKEN-SLOW2 "$P/gate-green-once" && red_on t3 && [[ -f $P/gate-green-once ]] && [[ $(su t3 | tail -1) == "1/1 checks passed" ]] \
  && [[ ! -e $P/gate-green-once ]] && red_on t3 t3 && red_on t3'
rm -f BROKEN-SLOW2 "$P/gate-green-once"
check "fix rounds config: MAX_FIX_ROUNDS=2 by default, commented in the user template and among what bounds a run" \
  '( source "$HERE/../lib/config.sh" && HARNESS_CONFIG=/nonexistent harness_config "$T/proj" && [[ $MAX_FIX_ROUNDS == 2 ]] ) \
  && grep "^# MAX_FIX_ROUNDS=2 " "$HERE/../templates/user/config.sh" > /dev/null && grep "MAX_VERIFY_ROUNDS, MAX_FIX_ROUNDS, MAX_REBASE_ROUNDS" "$HERE/../templates/user/config.sh" > /dev/null'

git add -A && git commit -qm "two tiers" && git push -q origin main
main0=$(git rev-parse HEAD)
args() { cat "$T/scratch/proj/$1/suite-args.log" 2> /dev/null; }
st() { echo "$HARNESS_STATE/proj/$1"; }
rec() { echo "$T/wt/proj/$1/.harness/runs/$1"; }
prompt_of() { grep -l "^Feature: \`$2\`$" $(find "$(st "$1")" -name '*.prompt.md' | sort) 2> /dev/null | sed -n "${3:-1}p"; }
items() { cat "$(st "$1")"/needs/*.json "$(st "$1")"/needs/done/*.json 2> /dev/null || :; }   # <run>: its needs items, open and resolved (a glob with no file is no failure: pipefail)
# <run> <id> <n>: the suite calls after that coding session's line, one per line, up to the next session's
after_session() { args "$1" | awk -v s="session $2 $3" '$0 == s { on = 1; next } on && /^session / { exit } on'; }
# <run> [<env>…]: one run of the stub project from main0, B's first session leaving the slow tier red
fx() { local r=$1; shift; git -C "$T/origin.git" update-ref refs/heads/main "$main0"
  env STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$@" "$H" start "$T/proj" "$r" --spec SPEC.md --foreground > "$T/$r.out" 2>&1; }

# fx1: B commits BROKEN-SLOW and passes on the fast tier; the verify's full suite is red on t1; round 1's session removes
# the marker, its gate (t1, then the fast tier) is green, and the second verify tags and merges
fx fx1 STUB_SLOW_RED=B STUB_FIX=fix
check "fix rounds fx1: a red verify opens round 1 (the note with the failing name) and no card: no needs Michael, needs-M1, verify_red item or needs-you post" \
  'hlog fx1 | grep -E " · B · [^ ]+ · passes=true · " > /dev/null \
  && hlog fx1 | grep " · verify M1: the suite is red on the verified tree (main had nothing new: a slow-tier red the fast gate let through); fix round 1 of 2: M1-fix1 appended (1 failing: t1)$" > /dev/null \
  && ! hlog fx1 | grep "needs Michael" > /dev/null && [[ ! -e $(st fx1)/needs-M1 ]] && ! items fx1 | jq -se "any(.reason == \"verify_red\")" > /dev/null \
  && [[ $(curl_count "[fx1] M1 needs you") == 0 ]]'
check "fix rounds fx1: the record's list has M1-fix1 (kind fix, issue all, round 1, after B, t1 as name and file, three steps, the worker model), clean under the step lint" \
  'jq -e ".features[-1] | .id == \"M1-fix1\" and .milestone == \"M1\" and .kind == \"fix\" and .issue == \"all\" and .round == 1 and .after == [\"B\"] and .fix_names == [\"t1\"]
    and .fix_files == [\"t1\"] and .fix_out == \".harness/runs/fx1/fix/M1-1.out\" and (.steps | length) == 3 and .model == \"opus\" and .passes == true" "$(list fx1)" > /dev/null \
  && [[ $(jq -r ".features[-1].steps[0]" "$(list fx1)") == "\`\$HARNESS_CHECK t1\` exits 0 (the HARNESS_FAILED files of .harness/runs/fx1/fix/M1-1.out)" ]] \
  && [[ -z $($F lint "$(list fx1)" | grep "^M1-fix1") ]] && ! hlog fx1 | grep "restored the feature list" > /dev/null'
check "fix rounds fx1: the red's output is in the record as fix/M1-1.out with the FAIL t1 line, committed" \
  'grep -x "FAIL t1" "$(rec fx1)/fix/M1-1.out" > /dev/null && grep -x "HARNESS_FAILED=t1" "$(rec fx1)/fix/M1-1.out" > /dev/null \
  && git -C "$T/wt/proj/fx1" ls-files --error-unmatch .harness/runs/fx1/fix/M1-1.out > /dev/null 2>&1'
fx1_p=$(prompt_of fx1 M1-fix1) fx1_a=$(prompt_of fx1 A)
check "fix rounds fx1: the fix session's prompt has the Fix round line under This session (1 of 2, t1, the output's path, both gate commands); A's has none" \
  '[[ -n $fx1_p && -n $fx1_a ]] && awk "/^# This session\$/ { s = 1 } s" "$fx1_p" \
    | grep -E "^Fix round 1 of 2: the full suite is red on this milestone.s verified tree; failing: t1; its output: \.harness/runs/fx1/fix/M1-1\.out; your feature passes on \`[^ \`]+/lib/check\.sh t1\` and \`[^ \`]+/lib/check\.sh --fast\` green, and the verify then runs the full suite\.\$" > /dev/null \
  && ! grep -e "^Fix round" -e "{{FIX}}" "$fx1_a" > /dev/null && ! grep -F "{{FIX}}" "$fx1_p" > /dev/null'
check "fix rounds fx1: the fix feature's gate runs its files (t1), then the fast tier, and it passes (passes=true in run.log, no un-pass)" \
  '[[ $(after_session fx1 M1-fix1 1 | sed -n 1,2p | paste -sd,) == "t1,--tier fast" ]] \
  && grep -E " M1-fix1 · [^ ]+ · passes=true · " "$(st fx1)/run.log" > /dev/null && ! hlog fx1 | grep "un-passed" > /dev/null'
check "fix rounds fx1: the second verify tags M1 (after fix round 1) and it merges; two verify sessions, verify-rounds-M1 is 1, the run is done" \
  '[[ $(grep -c " verify M1 · " "$(st fx1)/run.log") == 2 ]] && hlog fx1 | grep " · M1 verified and tagged run/fx1/M1 (after fix round 1)$" > /dev/null \
  && hlog fx1 | grep " · M1 merged into main" > /dev/null && [[ $(cat "$(st fx1)/verify-rounds-M1") == 1 ]] && grep "^done" "$(st fx1)/ended" > /dev/null \
  && [[ -n $(git -C "$T/origin.git" tag -l "run/fx1/M1") ]] && [[ ! -e $(st fx1)/fix-open-M1 && $(cat "$(st fx1)/fix-rounds-M1") == 1 ]]'
check "fix rounds fx1: metrics.jsonl has the fix_round row (failed_before t1), one fix_result (failed_after [], fixed) and the fix session's row with role fix" \
  'jq -se "([.[] | select(.kind == \"fix_round\")] | length == 1 and (.[0] | .run == \"fx1\" and .milestone == \"M1\" and .round == 1 and .issue == \"all\" and .feature == \"M1-fix1\"
      and .failed_before == [\"t1\"] and .files_before == [\"t1\"]))
    and ([.[] | select(.kind == \"fix_result\")] | length == 1 and (.[0] | .milestone == \"M1\" and .round == 1 and .failed_after == [] and .fixed == true))
    and ([.[] | select(.kind == \"coding\" and .feature == \"M1-fix1\")] | length == 1 and (.[0] | .role == \"fix\" and .passes == true))
    and ([.[] | .kind] | index(\"fix_round\") < index(\"fix_result\"))" "$(rec fx1)/metrics.jsonl" > /dev/null'
check "fix rounds fx1: summary.json counts 1 opened, 1 fixed and no fix row as a session; harness report --md prints the Fix rounds row; the run-ended note groups no fix kind" \
  'jq -e ".fix_rounds == {opened: 1, fixed: 1, by_milestone: {M1: {opened: 1, fixed: 1}}} and .cost.by_role.fix > 0" "$(rec fx1)/summary.json" > /dev/null \
  && jq -e "[.cost.by_role, .time.by_role_h, .tokens.by_role] | all(keys | all(test(\"^fix_\") | not))" "$(rec fx1)/summary.json" > /dev/null \
  && "$H" report --md fx1 | grep -xF "| Fix rounds | 1 opened · 1 fixed (M1 1 of 1) |" > /dev/null && ! hlog fx1 | grep "fix_r" > /dev/null'
check "fix rounds fx1: harness show fx1 M1-fix1 lists the fix session alone: the fix_round row naming the feature is no session" \
  '"$H" show fx1 M1-fix1 --json > "$T/fx1-show.json" 2> /dev/null; jq -e ".feature.sessions | length == 1 and .[0].kind == \"coding\" and .[0].role == \"fix\"" "$T/fx1-show.json" > /dev/null'

# fx5: the fix session leaves BROKEN-SLOW: its gate's first command is red, the feature is un-passed, and with one
# attempt it is given up as any feature is
mkdir -p "$(st fx5)" && echo MAX_ATTEMPTS=1 > "$(st fx5)/run.env"
fx fx5 STUB_SLOW_RED=B STUB_FIX=none
check "fix rounds fx5: a fix session that leaves the red is un-passed by its gate's first command (check t1; the fast tier not run), given up, and the run ends blocked on M1-fix1" \
  'hlog fx5 | grep " · M1-fix1 un-passed: check t1 red after the session$" > /dev/null && [[ $(after_session fx5 M1-fix1 1 | sed -n 1p) == t1 ]] \
  && ! after_session fx5 M1-fix1 1 | grep -x -e "--tier fast" > /dev/null \
  && items fx5 | jq -se "any(.key == \"given_up:M1-fix1\")" > /dev/null && grep "^blocked on M1-fix1" "$(st fx5)/ended" > /dev/null \
  && jq -e ".fix_rounds == {opened: 1, fixed: 0, by_milestone: {M1: {opened: 1, fixed: 0}}} and .guards.red_unpass == 1
    and (.features_detail[] | select(.id == \"M1-fix1\") | .cause == \"red suite\")" "$(rec fx5)/summary.json" > /dev/null \
  && [[ -f $(st fx5)/fix-open-M1 ]] && ! jq -se "any(.kind == \"fix_result\")" "$(rec fx5)/metrics.jsonl" > /dev/null'

# fx2: the rounds are bounded. Round 1's session moves the red (BROKEN-SLOW → BROKEN-SLOW2: t1 is green, t3 red), so
# the second verify opens round 2; its session changes no code and its gate is green once (gate-green-once), so the
# third verify is red at MAX_FIX_ROUNDS: the card, naming both rounds
fx fx2 STUB_SLOW_RED=B STUB_FIX=rename
RED="verify M1: the suite is red on the verified tree (main had nothing new: a slow-tier red the fast gate let through)"
check "fix rounds fx2: round 1 on t1, its session passes its gate (t1, the fast tier), the second verify is red on t3 and opens round 2 of 2 after M1-fix1" \
  'hlog fx2 | grep " · $RED; fix round 1 of 2: M1-fix1 appended (1 failing: t1)$" > /dev/null && hlog fx2 | grep " · $RED; fix round 2 of 2: M1-fix2 appended (1 failing: t3)$" > /dev/null \
  && [[ $(after_session fx2 M1-fix1 1 | sed -n 1,2p | paste -sd,) == "t1,--tier fast" ]] && grep -E " M1-fix1 · [^ ]+ · passes=true · " "$(st fx2)/run.log" > /dev/null \
  && jq -e ".features[-1] | .id == \"M1-fix2\" and .round == 2 and .after == [\"M1-fix1\"] and .fix_names == [\"t3\"] and .fix_files == [\"t3\"]" "$(list fx2)" > /dev/null \
  && grep -x "FAIL t3" "$(rec fx2)/fix/M1-2.out" > /dev/null'
check "fix rounds fx2: round 2's session changes no code and passes its gate (t3, the fast tier); the third verify is red and the card comes after 2 fix rounds, naming both" \
  '[[ $(after_session fx2 M1-fix2 1 | sed -n 1,2p | paste -sd,) == "t3,--tier fast" ]] && grep -E " M1-fix2 · [^ ]+ · passes=true · " "$(st fx2)/run.log" > /dev/null \
  && ! hlog fx2 | grep "un-passed" > /dev/null && [[ $(grep -c " verify M1 · " "$(st fx2)/run.log") == 3 ]] \
  && hlog fx2 | grep " · $RED; not verified (needs Michael) after 2 fix rounds (M1-fix1, M1-fix2)$" > /dev/null && ! hlog fx2 | grep "fix round 3" > /dev/null \
  && [[ -f $(st fx2)/needs-M1 ]] && grep "^waiting on Michael" "$(st fx2)/ended" > /dev/null && [[ -z $(git -C "$T/origin.git" tag -l "run/fx2/M1") ]]'
check "fix rounds fx2: the verify_red card is the own variant, its why names both rounds and what each left red (t3), and one needs-you post went out" \
  'items fx2 | jq -se "[.[] | select(.key == \"verify_red:M1\")] | length == 1 and (.[0].card | (.headline | endswith(\"suite red on the verified tree\"))
    and (.why | endswith(\" 2 fix rounds ran first (MAX_FIX_ROUNDS, verify in lib/lane.sh): M1-fix1 left t3 red, M1-fix2 left t3 red.\")))" > /dev/null \
  && [[ $(curl_count "[fx2] M1 needs you") == 1 ]]'
check "fix rounds fx2: each round's fix_result pairs with its fix_round and is written once (t1 → t3, t3 → t3, neither fixed); 2 opened, 0 fixed in summary.json and the report" \
  'jq -sc "[.[] | select(.kind | test(\"^fix_\")) | [.kind, .round, (.failed_before // .failed_after), (.fixed // null)]]" "$(rec fx2)/metrics.jsonl" > "$T/fx2-rows.json" \
  && [[ $(cat "$T/fx2-rows.json") == "[[\"fix_round\",1,[\"t1\"],null],[\"fix_result\",1,[\"t3\"],null],[\"fix_round\",2,[\"t3\"],null],[\"fix_result\",2,[\"t3\"],null]]" ]] \
  && jq -se "[.[] | select(.kind == \"fix_result\") | .fixed] == [false, false]" "$(rec fx2)/metrics.jsonl" > /dev/null \
  && jq -e ".fix_rounds == {opened: 2, fixed: 0, by_milestone: {M1: {opened: 2, fixed: 0}}}" "$(rec fx2)/summary.json" > /dev/null \
  && "$H" report --md fx2 | grep -xF "| Fix rounds | 2 opened · 0 fixed (M1 0 of 2) |" > /dev/null \
  && [[ ! -e $(st fx2)/fix-open-M1 && $(cat "$(st fx2)/fix-rounds-M1") == 2 && $(cat "$(st fx2)/verify-rounds-M1") == 1 ]]'
# a continue (fresh attempts; needs-M1 and verify-rounds-M1 cleared, fix-rounds-M1 kept): the verify again, red, at the cap
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue fx2 --foreground > "$T/fx2-b.out" 2>&1
check "fix rounds fx2: a continue verifies again at the cap: the card again after 2 fix rounds, no third round, feature or fix_result row" \
  '[[ $(grep -c " verify M1 · " "$(st fx2)/run.log") == 4 ]] && [[ $(hlog fx2 | grep -c " · $RED; not verified (needs Michael) after 2 fix rounds (M1-fix1, M1-fix2)$") == 2 ]] \
  && [[ $(jq -s "[.[] | select(.kind == \"fix_result\")] | length" "$(rec fx2)/metrics.jsonl") == 2 && $(jq -s "[.[] | select(.kind == \"fix_round\")] | length" "$(rec fx2)/metrics.jsonl") == 2 ]] \
  && [[ $(jq "[.features[] | select(.kind == \"fix\")] | length" "$(list fx2)") == 2 && $(cat "$(st fx2)/fix-rounds-M1") == 2 && -f $(st fx2)/needs-M1 ]] \
  && items fx2 | jq -se "[.[] | select(.key == \"verify_red:M1\" and .resolved_at == null)] | length == 1 and (.[0].card.why | contains(\"M1-fix2 left t3 red\"))" > /dev/null'

# fx3: a flake never opens a round. B's session arms flake-armed; the verify's full run is red once on t2, check.sh's
# rerun of t2 is green, so the verify holds
fx fx3 STUB_FLAKE_ONCE=1
check "fix rounds fx3: a flake at the verify is noted (flaky: t2) and M1 is verified and tagged with no fix round: no fix feature, no fix row, Fix rounds 0" \
  'hlog fx3 | grep " · flaky: t2 (red, then green on a rerun" > /dev/null && hlog fx3 | grep " · M1 verified and tagged run/fx3/M1$" > /dev/null \
  && ! hlog fx3 | grep "fix round" > /dev/null && [[ $(jq "[.features[] | select(.kind == \"fix\")] | length" "$(list fx3)") == 0 ]] \
  && ! jq -se "any(.kind | test(\"^fix_\"))" "$(rec fx3)/metrics.jsonl" > /dev/null && [[ ! -e $(st fx3)/fix-rounds-M1 && ! -d $(rec fx3)/fix ]] \
  && jq -e ".fix_rounds == {opened: 0, fixed: 0, by_milestone: {}} and .flakes.count == 1" "$(rec fx3)/summary.json" > /dev/null \
  && "$H" report --md fx3 | grep -xF "| Fix rounds | 0 |" > /dev/null && grep "^done" "$(st fx3)/ended" > /dev/null \
  && [[ $(grep -c " verify M1 · " "$(st fx3)/run.log") == 1 && $(args fx3 | grep -c "^t2$") == 1 ]]'

# fx4: MAX_FIX_ROUNDS=0 is the behaviour before fix rounds: the card at the first red
mkdir -p "$(st fx4)" && echo MAX_FIX_ROUNDS=0 > "$(st fx4)/run.env"
fx fx4 STUB_SLOW_RED=B STUB_FIX=fix
check "fix rounds fx4: MAX_FIX_ROUNDS=0 opens the verify_red card at the first red, its note and why as before: no round, feature, row or fix state" \
  'hlog fx4 | grep " · $RED; not verified (needs Michael)$" > /dev/null && ! hlog fx4 | grep "fix round" > /dev/null && [[ -f $(st fx4)/needs-M1 ]] \
  && items fx4 | jq -se "[.[] | select(.key == \"verify_red:M1\")] | length == 1 and (.[0].card.why | contains(\"fix round\") | not)" > /dev/null \
  && [[ $(curl_count "[fx4] M1 needs you") == 1 && $(grep -c " verify M1 · " "$(st fx4)/run.log") == 1 && $(cat "$(st fx4)/verify-rounds-M1") == 1 ]] \
  && [[ $(jq "[.features[] | select(.kind == \"fix\")] | length" "$(list fx4)") == 0 ]] && ! jq -se "any(.kind | test(\"^fix_\"))" "$(rec fx4)/metrics.jsonl" > /dev/null \
  && [[ ! -e $(st fx4)/fix-rounds-M1 && ! -e $(st fx4)/fix-open-M1 && ! -d $(rec fx4)/fix ]] && jq -e ".fix_rounds.opened == 0" "$(rec fx4)/summary.json" > /dev/null'

# fx6: a red that came in with main (another run's merge lands BROKEN-SLOW on main during B's session; the verify merges
# main into the lane first) opens a round too, its note saying whose the red is; the fix removes the marker and the
# second verify tags
fx fx6 STUB_MAIN_TOUCH=B:BROKEN-SLOW STUB_FIX=fix
check "fix rounds fx6: a red after merging main opens a round with the main-merged-in note, and the fixed milestone is tagged (after fix round 1)" \
  'hlog fx6 | grep " · verify M1: the suite is red on the verified tree (main merged in); fix round 1 of 2: M1-fix1 appended (1 failing: t1)$" > /dev/null \
  && ! hlog fx6 | grep "needs Michael" > /dev/null && hlog fx6 | grep " · M1 verified and tagged run/fx6/M1 (after fix round 1)$" > /dev/null \
  && jq -se "[.[] | select(.kind == \"fix_result\")] | length == 1 and .[0].fixed" "$(rec fx6)/metrics.jsonl" > /dev/null'

# fx8: fx2 with a verifier that performs the fix features' last step (the full suite) as written and un-passes them on
# the red tree. The verdict is still the suite's: they pass again, and the rule runs (round 2, then the card)
fx fx8 STUB_SLOW_RED=B STUB_FIX=rename STUB_VERIFY_UNPASS_FIX=1
check "fix rounds fx8: fix features the verifier un-passed on a red suite pass again (noted) and the verdict is the suite's: round 2 opens, then the card after 2 fix rounds, never a failed re-check" \
  'hlog fx8 | grep " · verify M1: the verifier un-passed M1-fix1 on a red suite; the verdict is the suite.s (a fix round or the card, no re-check)$" > /dev/null \
  && hlog fx8 | grep " · verify M1: the verifier un-passed M1-fix1, M1-fix2 on a red suite; " > /dev/null \
  && hlog fx8 | grep " · $RED; fix round 2 of 2: M1-fix2 appended (1 failing: t3)$" > /dev/null \
  && hlog fx8 | grep " · $RED; not verified (needs Michael) after 2 fix rounds (M1-fix1, M1-fix2)$" > /dev/null \
  && ! hlog fx8 | grep "failed the re-check" > /dev/null && [[ $(grep -c " verify M1 · " "$(st fx8)/run.log") == 3 ]] \
  && items fx8 | jq -se "any(.key == \"verify_red:M1\" and (.card.why | contains(\"M1-fix1 left t3 red, M1-fix2 left t3 red\"))) and (any(.reason == \"verify_recheck\") | not)" > /dev/null'
check "fix rounds fx8: both rounds have their fix_result row (t3, t3), the fix features pass in the record's list, and the attempts are untouched" \
  '[[ $(jq -sc "[.[] | select(.kind | test(\"^fix_\")) | [.kind, .round, (.failed_before // .failed_after)]]" "$(rec fx8)/metrics.jsonl") \
      == "[[\"fix_round\",1,[\"t1\"]],[\"fix_result\",1,[\"t3\"]],[\"fix_round\",2,[\"t3\"]],[\"fix_result\",2,[\"t3\"]]]" ]] \
  && [[ $(jq -c "[.features[] | select(.kind == \"fix\") | .passes]" "$(list fx8)") == "[true,true]" ]] \
  && [[ $(jq -c "[.[\"M1-fix1\"], .[\"M1-fix2\"]]" "$(st fx8)/attempts.json") == "[1,1]" ]] && [[ -f $(st fx8)/needs-M1 && ! -e $(st fx8)/fix-open-M1 ]]'

# fx7: the fix feature cannot be appended (the initializer's list already has a feature with round 1's id): no round
# opens, the card comes as before, and nothing of a round is left in the record or the state
fx fx7 STUB_SLOW_RED=B STUB_FIX_ID_TAKEN=1
check "fix rounds fx7: a fix feature that cannot be appended opens no round: the note says so, the card comes as before, and no fix output, row or state is left" \
  'hlog fx7 | grep " · verify M1: fix round 1 could not be opened (its feature was not appended; see run.log)$" > /dev/null \
  && hlog fx7 | grep " · $RED; not verified (needs Michael)$" > /dev/null && [[ -f $(st fx7)/needs-M1 ]] \
  && grep "fix-add: M1-fix1 is in the list already" "$(st fx7)/run.log" > /dev/null \
  && [[ ! -e $(rec fx7)/fix && ! -e $(st fx7)/fix-rounds-M1 && ! -e $(st fx7)/fix-open-M1 ]] && ! jq -se "any(.kind | test(\"^fix_\"))" "$(rec fx7)/metrics.jsonl" > /dev/null \
  && [[ $(jq "[.features[] | select(.id == \"M1-fix1\")] | length" "$(list fx7)") == 1 && $(cat "$(st fx7)/verify-rounds-M1") == 1 ]]'

suite_end
