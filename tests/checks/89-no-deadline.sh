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

# a merge in progress in a plain shell, as 77-resolve-fallbacks has it: the deadline is the only thing left to refuse it
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

suite_end
