#!/usr/bin/env bash
# tier: slow
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- no default end time (F1 M2): HOURS empty or 0 is no deadline, and nothing reads DEADLINE=0 as "now" ----
# decisions/2026-11-04-no-default-end-time
B0=$(git -C "$T/origin.git" rev-parse main)
nrun() {   # <run> <run.env line> [<env>…]: a clean stub run with that run.env, from main as this file began (one origin: CLAUDE.md)
  git -C "$T/origin.git" update-ref refs/heads/main "$B0"
  mkdir -p "$HARNESS_STATE/proj/$1" && echo "$2" > "$HARNESS_STATE/proj/$1/run.env"
  env "${@:3}" STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" "$1" --spec SPEC.md --foreground > "$T/$1.out" 2>&1; }
first() { head -1 "$HARNESS_STATE/proj/$1/run.log"; }
CLK='Clock: [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2} · run [0-9]+h[0-9]{2}m'

# the two pure pieces, in a plain shell: what DEADLINE is, and what it means
dl_of() { ( HARNESS_HOME=$HH; source "$HH/lib/config.sh"; HOURS=$1 DEADLINE_AT=$2; run_deadline 1000 ); }
check "no end time: run_deadline: HOURS empty or 0 is none, a whole number counts from T0, --until is it or the earlier of the two" \
  '[[ "$(dl_of "" 0) $(dl_of 0 0) $(dl_of 1 0) $(dl_of "" 5000) $(dl_of 0 5000) $(dl_of 1 2000) $(dl_of 1 9000)" == "0 0 4600 5000 5000 2000 4600" ]]'
pd() { ( HARNESS_HOME=$HH; source "$HH/lib/scope.sh"; source "$HH/lib/record.sh"; DEADLINE=$1; past_deadline && echo past || echo not ); }
check "no end time: past_deadline never reads DEADLINE=0 as now" \
  '[[ "$(pd 0) $(pd 1) $(pd $(( $(date +%s) + 3600 )))" == "not past not" ]]'

# a merge in progress in a plain shell, as resolve-fallbacks has it: the deadline is the only thing left to refuse it
V=$T/v; git init -q -b main "$V"; g=(git -C "$V"); echo a > "$V/f"; "${g[@]}" add f; "${g[@]}" commit -qm a
"${g[@]}" checkout -q -b lane; echo l > "$V/f"; "${g[@]}" commit -qam l
"${g[@]}" checkout -q main; echo m > "$V/f"; "${g[@]}" commit -qam m; "${g[@]}" checkout -q lane; "${g[@]}" merge -q main > /dev/null 2>&1
ro0=$( cd "$V" && HARNESS_HOME=$HH && source "$HH/lib/scope.sh" && source "$HH/lib/record.sh" && source "$HH/lib/resolve.sh"
  STATE=$T/ro-st LANE=M1 CONFLICTS=resolve MAX_RESOLVES=2 RESOLVE_TIMEOUT=30m DEADLINE=0; unset HARNESS_MERGE_ONLY; mkdir -p "$STATE"
  resolve_ok M1 && echo yes )
check "no end time: resolve_ok with DEADLINE=0 is not refused for the deadline" '[[ $ro0 == yes ]]'

nrun nd 'HOURS='
check "no end time: HOURS= run.log's first line ends · no end time, it ends done, no deadline note" \
  '[[ $(first nd) == *" run nd on "*" · no end time" ]] && grep "^done" "$HARNESS_STATE/proj/nd/ended" > /dev/null \
   && ! hlog nd | grep "deadline reached" > /dev/null'
check "no end time: the lanes get it: the coding and verify prompts' clock line says (no end time)" \
  'grep -Ex "$CLK \(no end time\) · this session: .* · attempt 1 of 2" "$HARNESS_STATE"/proj/nd/logs/*-A.prompt.md > /dev/null \
   && grep -Ex "$CLK \(no end time\) · this session: .* · .*verify.*" "$HARNESS_STATE"/proj/nd/logs/*-verify-M1.prompt.md > /dev/null'
nrun nd0 'HOURS=0'
check "no end time: HOURS=0 is no end time too, not a deadline at once" \
  '[[ $(first nd0) == *" · no end time" ]] && grep "^done" "$HARNESS_STATE/proj/nd0/ended" > /dev/null'
# 50 s ahead, not the spec's 3: (0 min) all the same (HARNESS_LIMIT_SLEEP=0 sleeps none of it), and a loaded box's init can't outlast it
echo $(( $(date +%s) + 50 )) > "$HARNESS_STATE/LIMIT_UNTIL"
nrun nd2 'HOURS='
rm -f "$HARNESS_STATE/LIMIT_UNTIL"
lw=$(grep -n -m1 "usage-limit window (shared by all runs): waiting until [0-9][0-9]:[0-9][0-9] (0 min)" "$HARNESS_STATE/proj/nd2/run.log" | cut -d: -f1)
s1=$(grep -n -m1 " session 1 · " "$HARNESS_STATE/proj/nd2/run.log" | cut -d: -f1)
check "no end time: a usage-limit window is still waited for, noted before session 1" '[[ -n $lw && -n $s1 ]] && (( lw < s1 ))'
nrun nd1h 'HOURS=1'
check "no end time: HOURS=1 says · ends HH:MM and the clock's of 1h, ends form" \
  '[[ $(first nd1h) =~ \ ·\ ends\ [0-9]{2}:[0-9]{2}$ ]] && grep -Ex "$CLK of 1h, ends [0-9]{2}:[0-9]{2} · this session: .*" "$HARNESS_STATE"/proj/nd1h/logs/*-A.prompt.md > /dev/null'

# ---- the default, and a value that is no number of hours: refused before anything runs ----
cfg_hours() { ( HARNESS_HOME=$HH HARNESS_CONFIG=/dev/null; source "$HH/lib/config.sh"; harness_config /nonexistent; printf '[%s]' "${HOURS-unset}" ); }
check "no end time: HOURS defaults to empty" '[[ $(cfg_hours) == "[]" ]]'
git -C "$T/origin.git" update-ref refs/heads/main "$B0"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" nd3 --spec SPEC.md --foreground > "$T/nd3.out" 2>&1
check "no end time: a run with no HOURS and no --until has no end time and ends done" \
  '[[ $(first nd3) == *" · no end time" ]] && grep "^done" "$HARNESS_STATE/proj/nd3/ended" > /dev/null'
bad() {   # <run> <value> → harness start's exit and output for that HOURS in run.env; no worktree may come of it
  mkdir -p "$HARNESS_STATE/proj/$1" && echo "HOURS=$2" > "$HARNESS_STATE/proj/$1/run.env"
  "$H" start "$T/proj" "$1" --spec SPEC.md --foreground > "$T/$1.out" 2>&1; echo "$?" > "$T/$1.rc"; }
refused() { [[ $(cat "$T/$1.rc") == 1 ]] && grep -F "HOURS=$2 in the config is not a whole number of hours" "$T/$1.out" > /dev/null && [[ ! -e $T/wt/proj/$1 ]]; }
bad ndabc abc; bad ndfrac 1.5; bad ndneg -1; bad ndoct 08
check "no end time: HOURS=abc, 1.5, -1 or 08: harness start exits 1 saying so, no worktree made" \
  'refused ndabc abc && refused ndfrac 1.5 && refused ndneg -1 && refused ndoct 08'
# no run id yet: the config's own HOURS is refused too, before a queue entry could carry the run past it
printf 'HOURS=abc\n' >> "$T/user-config.sh"; "$H" start "$T/proj" --spec SPEC.md > "$T/ndcfg.out" 2>&1; ndcfg_rc=$?; cp "$T/base-config.sh" "$T/user-config.sh"
check "no end time: a bad HOURS in the user config is refused too, nothing queued" \
  '(( ndcfg_rc == 1 )) && grep -F "HOURS=abc in the config" "$T/ndcfg.out" > /dev/null && ! compgen -G "$HARNESS_STATE/queue/*.args" > /dev/null'
# past cmd_start's check (a config edited between it and the driver's read): the driver refuses too, before it runs anything
echo 'HOURS=abc' >> "$HARNESS_STATE/proj/nd3/run.env"; nd3_before=$(cat "$HARNESS_STATE/proj/nd3/ended")
WT=$T/wt/proj/nd3 RUN_ID=nd3 STATE=$HARNESS_STATE/proj/nd3 PROJECT_DIR=$T/proj HARNESS_HOME=$HH bash "$HH/lib/driver.sh" > "$T/nd3drv.out" 2>&1; nd3drv_rc=$?
check "no end time: the driver itself refuses it: exit 1, the line in run.log, nothing run" \
  '(( nd3drv_rc == 1 )) && tail -1 "$HARNESS_STATE/proj/nd3/run.log" | grep -F "HOURS=abc in the config is not a whole number of hours" > /dev/null \
   && [[ ! -e $HARNESS_STATE/proj/nd3/driver.pid && $(cat "$HARNESS_STATE/proj/nd3/ended") == "$nd3_before" ]]'
sed -i '/^HOURS=abc$/d' "$HARNESS_STATE/proj/nd3/run.env"
check "no end time: --until stays an option of start, continue and queue start" \
  'u=$("$H" help 2>&1); grep -F "[--until HH:MM] [--now] [--no-supervisor]" <<< "$u" > /dev/null \
   && grep -F "harness continue <run-id> [--brief …] [--until HH:MM]" <<< "$u" > /dev/null && grep -F "start [--until HH:MM]" <<< "$u" > /dev/null'
check "no end time: the user config template documents HOURS, the rule and what still bounds a run" \
  'c=$(cat "$HH/templates/user/config.sh"); grep -E "^# HOURS= +# .*(empty or 0).*whole number" <<< "$c" > /dev/null \
   && { ok=1; for w in MAX_SESSIONS MAX_ATTEMPTS MAX_VERIFY_ROUNDS MAX_REBASE_ROUNDS MAX_RESOLVES MAX_LIMIT_HITS WEEKLY_STOP_AT AUTO_CONTINUE_MAX SESSION_TIMEOUT SESSION_BUDGET_USD stop pause --until; do
        grep -F "bounds a run" -A3 <<< "$c" | grep -F -- "$w" > /dev/null || { echo "template: no $w"; ok=0; }; done; (( ok )); }'   # a flag: a loop left by break is status 0

suite_end
