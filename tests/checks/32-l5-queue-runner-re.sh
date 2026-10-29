#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- L5: the queue runner re-reads its config each poll: MAX_PARALLEL_RUNS 1 → 2 starts a second run, 2 → 1 stops none ----
# two projects (proj2: a clone with its own origin) and a third entry (stoppy-o: the runner starts it, harness skips it).
# The runs are tmux-started (parallel) on the private server: their STUB_* flags go through its global environment, and
# the stub holds each run's coding sessions until the suite releases it (hold-coding / release-<run>)
git clone -q --bare "$T/origin.git" "$T/origin2.git" && git clone -q "$T/origin2.git" "$T/proj2" && git -C "$T/proj2" config url."$T/origin2.git".insteadOf git@github.com:test/proj2.git \
  && git -C "$T/proj2" remote set-url origin git@github.com:test/proj2.git
mkdir -p "$HARNESS_STATE/other/stoppy-o" && echo 'stopped by Michael' > "$HARNESS_STATE/other/stoppy-o/ended" && : > "$HARNESS_STATE/other/stoppy-o/meta.env"
tmux new-session -d -s h-l5-hold sleep 600; for v in STUB_NO_TAMPER STUB_NO_RED STUB_LENIENT; do tmux set-environment -g "$v" 1; done   # sleep-ok: the server's stand-in session (keeps it up)
cfg() { { cat "$T/base-config.sh"; echo "MAX_PARALLEL_RUNS=$1"; } > "$T/user-config.new" && mv "$T/user-config.new" "$T/user-config.sh"; }   # whole, at once: the runner may source it any moment
RL5=$T/queue-reload.out; st5() { grep -qF "starting: harness $1" "$RL5"; }
pid_up() { local p; p=$(cat "$HARNESS_STATE/$1/driver.pid" 2> /dev/null) && kill -0 "$p" 2> /dev/null; }
# a typo (2x, then 08, octal to bash: `(( a >= 2x ))` fails) keeps the old value, said once each; nothing starts: a fake live run fills the one slot
mkdir -p "$HARNESS_STATE/other/busy5" && : > "$HARNESS_STATE/other/busy5/meta.env"; sleep 60 & BP5=$!; echo $BP5 > "$HARNESS_STATE/other/busy5/driver.pid"   # sleep-ok: a live driver
"$H" queue add "$T/proj" --spec SPEC.md > /dev/null; RB5=$T/queue-badmax.out
HARNESS_QUEUE_POLL=0.2 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$RB5" 2>&1 & RP5=$!
wait_for 10 grep "runner up" "$RB5"   # it read the good value first
echo 'MAX_PARALLEL_RUNS=2x' >> "$T/user-config.sh"; wait_for 10 grep "=2x in the config is not" "$RB5"; sleep 1   # sleep-ok: a negative (said once) over five polls
echo 'MAX_PARALLEL_RUNS=08' >> "$T/user-config.sh"; wait_for 10 grep "=08 in the config is not" "$RB5"; sleep 1   # sleep-ok: a negative over five polls
cfg 1; sleep 1; touch "$HARNESS_STATE/queue/STOP"; wait_for 10 eval '! kill -0 $RP5'   # sleep-ok: a negative (nothing starts) over five polls
check "queue runner: a MAX_PARALLEL_RUNS that is no whole number keeps the old value, said once; nothing starts" '[[ $(grep -c "MAX_PARALLEL_RUNS=2x in the config is not a whole number: keeping 1$" "$RB5") == 1 ]] \
  && [[ $(grep -c "MAX_PARALLEL_RUNS=08 in the config is not a whole number: keeping 1$" "$RB5") == 1 ]] \
  && ! grep -q "starting:\|config reloaded" "$RB5" && grep -q "stopped by harness queue stop" "$RB5"'
kill "$BP5" "$RP5" 2> /dev/null; rm -rf "$HARNESS_STATE/other/busy5" "$HARNESS_STATE"/queue/*.args
cfg 1; : > "$T/hold-coding"; rm -f "$T"/held-l5? "$T"/release-l5?
"$H" queue add "$T/proj" l5a --spec SPEC.md > /dev/null; "$H" queue add "$T/proj2" l5b --spec SPEC.md > /dev/null; "$H" queue add --continue stoppy-o --automatic > /dev/null
# HARNESS_COUNT_HOLD (bin/harness passes it to the tmux-started runs): each run's M1 lane exits between the coordinator's
# lane count and its end check, the window that ended a run "no feature left to try" before M2 now and then (R1-06;
# decisions/2026-10-29-lane-count-end-check)
HARNESS_COUNT_HOLD=1 HARNESS_QUEUE_POLL=1 HARNESS_QUEUE_SETTLE=5 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$RL5" 2>&1 & RP5=$!
wait_for 90 test -f "$T/held-l5a"; sleep 3; l5_early=$(st5 "start $T/proj2" && echo started)   # sleep-ok: a negative over three polls at 1: the second waits
cfg 2; wait_for 15 st5 "start $T/proj2"; l5_up=$(grep -c "MAX_PARALLEL_RUNS 1 → 2 (config reloaded)" "$RL5")
wait_for 90 test -f "$T/held-l5b"; l5_both=$(pid_up proj/l5a && pid_up proj2/l5b && echo yes)
cfg 1; wait_for 15 grep "MAX_PARALLEL_RUNS 2 → 1 (config reloaded)" "$RL5"; sleep 3   # sleep-ok: a negative over three polls
l5_low=$(pid_up proj/l5a && pid_up proj2/l5b && ! st5 "continue stoppy-o" && echo yes)   # lowering stops neither; the third waits
touch "$T/release-l5a"; wait_for 120 eval '! pid_up proj/l5a'; sleep 3; l5_one=$(pid_up proj2/l5b && ! st5 "continue stoppy-o" && echo yes)   # sleep-ok: a negative over three polls (1 alive, at 1: still waits)
touch "$T/release-l5b"; wait_for 180 eval '! kill -0 $RP5'; settle
check "queue runner: MAX_PARALLEL_RUNS 1 → 2 in the config starts the second entry without a restart, and says so" '[[ -z $l5_early && $l5_up == 1 && $l5_both == yes ]] \
  && [[ $(grep -c "runner up" "$RL5") == 1 ]] && [[ $(grep -c "config reloaded" "$RL5") == 2 ]]'
check "queue runner: MAX_PARALLEL_RUNS 2 → 1 stops no running run; the third entry waits until under it, then starts" '[[ $l5_low == yes && $l5_one == yes ]] && st5 "continue stoppy-o" \
  && [[ $($F summary "$T/ledger/proj/l5a/feature_list.json") == "3/3 passing" && $($F summary "$T/ledger/proj2/l5b/feature_list.json") == "3/3 passing" ]] && grep -q "queue empty, nothing running: done" "$RL5"'
for v in STUB_NO_TAMPER STUB_NO_RED STUB_LENIENT; do tmux set-environment -gu "$v"; done; tmux kill-session -t =h-l5-hold 2> /dev/null
kill "$RP5" 2> /dev/null; rm -f "$T/hold-coding"; rm -rf "$HARNESS_STATE/other"; cp "$T/base-config.sh" "$T/user-config.sh"

suite_end
