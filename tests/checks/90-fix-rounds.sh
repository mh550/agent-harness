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

suite_end
