#!/usr/bin/env bash
# tier: slow
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the fast gate in the driver (T2-02, decisions/2026-11-03-fast-gate): `passes` stands on the fast tier ----
# The stub project gets two tiers: .harness/suite.sh logs every call's arguments (`bare` for none) to suite-args.log in
# the run's scratch (a coding session adds `session <id> <n>` there, tests/stub-claude.sh), is red bare when BROKEN or
# BROKEN-SLOW exists and red under `--tier fast` when BROKEN or BROKEN-FAST exists (a subset, the rerun guard's: any).
cat > .harness/suite.sh <<'EOF'
#!/usr/bin/env bash
echo "${*:-bare}" >> "${HARNESS_SCRATCH%%/lanes/*}/suite-args.log"
case ${1:-} in
  "") red=$(ls BROKEN BROKEN-SLOW 2> /dev/null); pass=(t1 t2 t3) ;;
  --tier) red=$(ls BROKEN BROKEN-FAST 2> /dev/null); pass=(t1 t2) ;;
  *) red=$(ls BROKEN BROKEN-SLOW BROKEN-FAST 2> /dev/null); pass=("$@") ;;
esac
if [[ -n $red ]]; then printf '%s\n' "FAIL t1 ($red)" "HARNESS_FAILED=t1" "0/1 checks passed"; exit 1; fi
for t in "${pass[@]}"; do echo "PASS $t"; done; echo "${#pass[@]}/${#pass[@]} checks passed"
EOF
sed -i 's|^CHECK_CMD=.*|CHECK_CMD="bash .harness/suite.sh"\nCHECK_FAST_CMD="bash .harness/suite.sh --tier fast"|' .harness/config.sh
git add -A && git commit -qm "two tiers" && git push -q origin main
main0=$(git rev-parse HEAD)
args() { cat "$T/scratch/proj/$1/suite-args.log" 2> /dev/null; }
st() { echo "$HARNESS_STATE/proj/$1"; }
prompt_of() { grep -l "^Feature: \`$2\`$" $(find "$(st "$1")" -name '*.prompt.md' | sort) 2> /dev/null | sed -n "${3:-1}p"; }
# every session's next suite call is the fast tier (the post-session gate), and from the first session up to the first
# bare call after it (the verify's run_init fresh) every call is the fast tier: <log> → 0 when both hold
fast_between() { awk '/^session / { s++; want = 1; on = 1; next } want { want = 0; if ($0 != "--tier fast") bad = 1 }
  on && $0 == "bare" { on = 0; seen = 1 } on && $0 != "--tier fast" && $0 != "t1" { bad = 1 } END { exit !(s >= 2 && seen && !bad) }'; }

# fg: a clean run: the baseline is full, each coding session's init and gate the fast tier, the verify full; A's first
# session runs the fast tier itself on its edited tree, then again (cached)
STUB_RUN_FAST=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" fg --spec SPEC.md --foreground > "$T/fg.out" 2>&1
fg_b=$(prompt_of fg B)
check "fast gate run: the run's first init is a bare (full) call and tests-start holds the full count" \
  '[[ $(args fg | sed -n 1p) == bare && $(cat "$(st fg)/tests-start" 2> /dev/null) == 3 ]]'
check "fast gate run: a coding session's init output is the fast tier's (B's prompt: check: fast green)" \
  '[[ -n $fg_b ]] && grep "^check: fast green" "$fg_b" > /dev/null'
check "fast gate run: each coding session is followed by a --tier fast call, and no bare call comes before the verify's" \
  'args fg | fast_between && [[ $(args fg | grep -c "^session ") == 3 ]]'
check "fast gate run: the run passes and merges on the full suite; tests-end is the full count, no un-pass" \
  'grep "^done" "$(st fg)/ended" > /dev/null && hlog fg | grep " · verify M1: suite cache cleared" > /dev/null \
  && [[ $(cat "$(st fg)/tests-end" 2> /dev/null) == 3 ]] && ! hlog fg | grep "un-passed" > /dev/null'

# the gate visible and told (T2-03): the session's own fast calls in metrics.jsonl and the report, both lengths and the rule
row() { jq -sc --arg f "$2" '[.[] | select(.kind == "coding" and .feature == $f)][0] | [.suite_runs, .suite_full, .suite_fast]' \
  "$T/wt/proj/$1/.harness/runs/$1/metrics.jsonl"; }
check "fast gate run: a session's own fast call is suite_fast 1 on its coding row (a cached one aside) and a run in its suite ran note" \
  '[[ $(row fg A) == "[1,0,1]" && $(row fg B) == "[0,0,0]" ]] && hlog fg | grep -F "· A: suite ran 1x (" > /dev/null'
check "fast gate run: harness report --md's Suite runs row counts full and fast calls per coding session" \
  '"$H" report --md fg | grep -xF "| Suite runs | 0 full and 0.3 fast per coding session (0 full, 1 fast in 3; 1 runs in all) |" > /dev/null'
# a wall differs from session to session: every one under # This session (79-suite-length's rule, the fast one too)
below() { awk '/^# This session$/ { s = 1 } /last (full|fast) run ([0-9]+ s|not measured)/ { print (s ? "below" : "above") }' "$1" | sort -u; }
check "fast gate run: the coding prompt names both tiers' commands, carries both lengths under # This session, and the tier rule" \
  'grep -F "/lib/check.sh --fast\` runs \`bash .harness/suite.sh --tier fast\`; cached per code tree; its last full and fast runs are under *This session*) · init: " "$fg_b" \
  | grep -F "/lib/check.sh\` (full: runs \`bash .harness/suite.sh\`; fast tier: \`" > /dev/null \
  && grep -E "^Suite: last full run [0-9]+ s: give a full run a timeout of at least twice that$" "$fg_b" > /dev/null \
  && grep -E "^Suite: last fast run [0-9]+ s$" "$fg_b" > /dev/null && [[ $(below "$fg_b") == below ]] \
  && grep -F "run the fast tier once, last" "$fg_b" > /dev/null'

# fs: B's first session commits BROKEN-SLOW: the fast tier stays green, so B passes; the verify's full run finds it
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
STUB_SLOW_RED=B STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" fs --spec SPEC.md --foreground > "$T/fs.out" 2>&1
check "fast gate run: a slow-tier red passes the session (passes=true, no un-pass) and the verify's full run is red (note, needs record)" \
  'hlog fs | grep -E " · B · [^ ]+ · passes=true · " > /dev/null && ! hlog fs | grep "un-passed" > /dev/null \
  && hlog fs | grep " · verify M1: the suite is red on the verified tree (main merged in); not verified (needs Michael)$" > /dev/null \
  && [[ -f $(st fs)/needs-M1 ]] && jq -se "any(.reason == \"verify_red\")" "$(st fs)"/needs/*.json > /dev/null'
check "fast gate run: tests-end is never the fast count (the full count or none)" \
  '[[ ! -f $(st fs)/tests-end || $(cat "$(st fs)/tests-end") == 3 ]] && [[ $(cat "$(st fs)/tests-start") == 3 ]]'

# fr: A's first session commits BROKEN-FAST (its retry removes it); B plants red-, green- and fast-<key> for its tree
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
STUB_FAST_RED=A STUB_PLANT_MARKERS=B STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" fr --spec SPEC.md --foreground > "$T/fr.out" 2>&1
fr_key=$(cat "$T/planted-fr" 2> /dev/null) FR=$(st fr)/green
check "fast gate run: a fast-tier red after the session un-passes it with the fast note; the retry's init runs the fast tier" \
  'hlog fr | grep " · A un-passed: fast tier red after the session$" > /dev/null && hlog fr | grep -E " · A · [^ ]+ · passes=false · " > /dev/null \
  && args fr | awk "/^session A 1/ { on = 1 } on && /^session A 2/ { done = 1; exit } on && /^--tier fast/ { f++ } END { exit !(done && f >= 2) }" && grep "^done" "$(st fr)/ended" > /dev/null'
check "fast gate run: the verify's run_init fresh removes a planted fast-<key> beside red- and green-<key>" \
  '[[ -n $fr_key && ! -e $FR/fast-$fr_key && ! -e $FR/red-$fr_key && $(sed -n 1p "$FR/green-$fr_key") == "3 tests" ]]'

suite_end
