#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- tmux (L3-03): when the driver exits, its window saves the scrollback, closes the supervisor and, after TMUX_KEEP_HOURS, the session ----
{ cat "$T/base-config.sh"; echo TMUX_KEEP_HOURS=0; } > "$T/keep0.sh"; { cat "$T/base-config.sh"; echo TMUX_KEEP_HOURS=1; } > "$T/keep1.sh"
tgone() { local s=$1; wait_for 10 eval '! tmux has-session -t "=$s"'; }
PAST=$(( $(date +%s) - 1 ))   # the tmux runs take no STUB_* flags (they don't reach a window): the initializer, then the deadline
HARNESS_CONFIG=$T/keep0.sh "$H" start "$T/proj" tmux0 --spec SPEC.md --until-epoch "$PAST" --now > "$T/tmux0.out" 2>&1
HARNESS_CONFIG=$T/keep0.sh "$H" start "$T/proj" dot.run --spec SPEC.md --until-epoch "$PAST" --now --no-supervisor > "$T/tmuxdot.out" 2>&1
tdot_s=$(tmux list-sessions -F '#S' 2> /dev/null | grep -x 'h-dot-run')
HARNESS_CONFIG=$T/keep1.sh "$H" start "$T/proj" tmux1 --spec SPEC.md --until-epoch "$PAST" --now > "$T/tmux1.out" 2>&1
tmux1_w=$(tmux list-windows -t =h-tmux1 -F '#W' 2> /dev/null | tr '\n' ' ')
tended "$HARNESS_STATE/proj/tmux0"; tmux0_gone=$(tgone h-tmux0 && echo yes)
tended "$HARNESS_STATE/proj/dot.run"; tdot_gone=$(tgone h-dot-run && echo yes)
tended "$HARNESS_STATE/proj/tmux1"
wait_for 10 eval 'tmux capture-pane -pJ -t =h-tmux1:driver | grep "self-destructs in 1 h" > /dev/null'   # the line comes after the capture and the kill
tmux1_after=$(tmux list-windows -t =h-tmux1 -F '#W' 2> /dev/null | tr '\n' ' '); tmux1_pane=$(tmux capture-pane -pJ -t =h-tmux1:driver 2> /dev/null)
tmux send-keys -t =h-tmux1:driver C-c; tmux1_cc=$(tgone h-tmux1 && echo yes)   # a Ctrl-C in the keep window ends the wait, not the cleanup
tmux kill-session -t =h-tmux1 2> /dev/null   # (if it failed) its keep-1 timer goes with it; the EXIT trap kills the server anyway
tdrv() { grep -q "deadline reached" "$HARNESS_STATE/proj/$1/tmux-driver.txt" 2> /dev/null; }   # the driver's own output, not a blank pane
check "tmux: TMUX_KEEP_HOURS=0: the driver window saves its scrollback and kills h-<run> when the driver exits" '[[ $tmux0_gone == yes ]] \
  && grep -q "started tmux session h-tmux0 (windows: driver, log, supervisor)" "$T/tmux0.out" && tdrv tmux0'
check "tmux: a keep window keeps h-<run>, its supervisor window gone, the scrollback saved; a Ctrl-C there still closes it" '[[ $tmux1_w == *supervisor* && -n $tmux1_after && $tmux1_after != *supervisor* ]] \
  && tdrv tmux1 && [[ $tmux1_cc == yes ]] && grep -qF "[driver exited — scrollback saved to $HARNESS_STATE/proj/tmux1/tmux-driver.txt; this session self-destructs in 1 h, or sooner on harness gc]" <<< "$tmux1_pane" \
  && ( source "$HERE/../lib/config.sh" && HARNESS_CONFIG=/dev/null harness_config /nonexistent && [[ $TMUX_KEEP_HOURS == 24 ]] ) && grep -q "^# TMUX_KEEP_HOURS=24 " "$HERE/../templates/user/config.sh"'
check "tmux: run id dot.run gets session h-dot-run, gone at keep 0" '[[ $tdot_s == h-dot-run && $tdot_gone == yes ]] && tdrv dot.run'

suite_end
