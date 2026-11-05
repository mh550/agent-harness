#!/usr/bin/env bash
# tier: slow
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the resident helper in a real start (H1-02b, decisions/2026-11-03-resident-helper): the driver's and the lanes' ----
# A node shim first on PATH counts the starts (84-node-memo's) and execs the real node. fresh puts $T back as suite_setup
# left it, so a second start of the same run has the same paths and every difference in its logs is the helper's.
MD=$T/hr; mkdir -p "$MD/shim" "$MD/pristine"
printf '#!/usr/bin/env bash\na=$*; echo "${a//[[:cntrl:]]/ }" >> "$NODE_COUNT"\nexec %q "$@"\n' "$(command -v node)" > "$MD/shim/node"; chmod +x "$MD/shim/node"
cp -a "$T/proj" "$T/origin.git" "$MD/pristine/"
fresh() {
  cd "$MD" || return 1
  local f; for f in "$T"/* "$T"/.[!.]*; do case ${f##*/} in hr|bin|tmux|base-config.sh) ;; *) rm -rf "$f" ;; esac; done
  cp -a "$MD/pristine/proj" "$MD/pristine/origin.git" "$T/"; cp "$T/base-config.sh" "$T/user-config.sh"; cd "$T/proj" || return 1
}
# one_run <name> [<VAR=value>…]: file 13's first start, from a fresh state; its logs and list kept under $MD/<name>;
# CONFIG_LINE goes in the user's config file
one_run() {
  local d=$MD/$1; shift; fresh; mkdir -p "$d"; : > "$d/count"; [[ -n ${CONFIG_LINE:-} ]] && echo "$CONFIG_LINE" >> "$T/user-config.sh"
  env PATH="$MD/shim:$PATH" NODE_COUNT="$d/count" "$@" "$H" start "$T/proj" demo --spec SPEC.md --brief "only A–C" --foreground > "$d/out" 2>&1
  echo $? > "$d/rc"
  cp "$T/wt/proj/demo/.harness/runs/demo/harness-log.md" "$d/harness-log.md"; cp "$HARNESS_STATE/proj/demo/run.log" "$d/run.log"; cp "$(list demo)" "$d/feature_list.json"
  cat "$HARNESS_STATE/proj/demo/ended" > "$d/ended" 2> /dev/null
}
one_run off1 HARNESS_HELPER=0
CONFIG_LINE=HARNESS_HELPER=0 one_run off2
one_run on
# what two helper-off runs differ on and nothing else: the clock (a line's stamp) and the commits it hashes
strip() { sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} //; s/^- [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2} · /- /; s/\b[0-9a-f]{7}\b/<commit>/g' "$1"; }
same() { local f; for f in harness-log.md run.log feature_list.json; do cmp -s <(strip "$MD/$1/$f") <(strip "$MD/$2/$f") || { echo "$1 and $2 differ on $f:" >&2; diff <(strip "$MD/$1/$f") <(strip "$MD/$2/$f") | head -20 >&2; return 1; }; done; }
check "helper off (HARNESS_HELPER=0 in the environment, or in the user's config file): no helper.mjs starts, in the driver or a lane; every question a spawn" \
  '[[ $(cat "$MD/off1/rc") == 0 && $(cat "$MD/off2/rc") == 0 ]] && ! grep helper\.mjs "$MD/off1/count" > /dev/null && ! grep helper\.mjs "$MD/off2/count" > /dev/null && (( $(wc -l < "$MD/off1/count") > 200 ))'
check "two helper-off runs give the same harness-log.md, run.log and feature_list.json once the clock and its commit hashes are stripped" 'same off1 off2'
check "a stub start through the helpers: the same harness-log.md, run.log and feature_list.json as helper off, stripped the same way" 'same off1 on && [[ -s $MD/on/harness-log.md && $(cat "$MD/on/rc") == 0 ]] && grep "^done" "$MD/on/ended" > /dev/null'
check "a stub start through the helpers starts node at most 30 times (one helper for the driver and each lane among them)" \
  '{ (( $(wc -l < "$MD/on/count") <= 30 )) || { sed -E "s#/[^ ]*/##g" "$MD/on/count" | cut -c1-70 >&2; false; }; } && [[ $(grep -c "helper\.mjs$" "$MD/on/count") == 3 ]]'
check "a stub start's run.log has no helper restarted and no helper off line" '! grep -E "helper (restarted|off)" "$MD/on/run.log" > /dev/null'

# ---- the lifecycle: one helper per driver and per lane, gone with its shell ----
# This file's helpers only, whatever other suites run: by the environment they started with, never a bare pgrep count
helpers() { local p; for p in $(pgrep -f 'lib/helper\.mjs'); do tr '\0' '\n' < "/proc/$p/environ" 2> /dev/null | grep -x "STUB_DIR=$T" > /dev/null && echo "$p"; done; }
nohelper() { [[ -z $(helpers) ]]; }
alive() { local s; s=$(ps -o stat= -p "$1" 2> /dev/null); [[ -n $s && $s != Z* ]]; }
pipes() { ls -l "/proc/$1/fd" 2> /dev/null | grep -o 'pipe:\[[0-9]*\]' | sort -u; }   # <pid>: the pipes it holds
tree() { echo "$1"; local c; for c in $(pgrep -P "$1"); do tree "$c"; done; }   # <pid>: it and its descendants
LANES2=(STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1)
# two_lanes <run>: both lanes' sessions held; P the start, S its state dir
two_lanes() {
  fresh; echo MAX_LANES=2 >> "$T/user-config.sh"; held
  [[ -z ${FDS_CONFIG:-} ]] || { cat >> .harness/config.sh << 'EOF'
CHECK_CMD='ls -l /proc/self/fd >> "$STUB_DIR/suite-fds"; test ! -f BROKEN'
INIT_CMD='ls -l /proc/self/fd >> "$STUB_DIR/init-fds"; echo init ok'
EOF
    git add -A && git commit -qm "the suite and the init list their descriptors" && git push -q origin main; }
  env "${LANES2[@]}" "$H" start "$T/proj" "$1" --spec SPEC.md --foreground > "$MD/$1.out" 2>&1 & P=$!
  S=$HARNESS_STATE/proj/$1
  wait_for 120 eval '[[ -f $T/held-'"$1"'-A && -f $T/held-'"$1"'-C ]]'
}
FDS_CONFIG=1 two_lanes two
mapfile -t two_h < <(helpers)
two_parents=$(for p in "${two_h[@]}"; do ps -o ppid= -p "$p"; done | tr -d ' ' | sort | paste -sd' ')
two_shells=$(printf '%s\n' "$(cat "$S/driver.pid")" "$(cat "$S/lanes/M1/pid")" "$(cat "$S/lanes/M2/pid")" | sort | paste -sd' ')
check "two lanes alive: three helpers, each a child of its own shell (the coordinator, each lane)" '[[ ${#two_h[@]} == 3 && $two_parents == "$two_shells" ]]'
for p in "${two_h[@]}"; do pipes "$p"; done | sort -u > "$MD/helper-pipes"
: > "$MD/session-pipes"; for f in "$T"/scope/harness-two-M*-s*.cmd; do for p in $(tree "$(cat "$f")"); do pipes "$p"; done; done | sort -u > "$MD/session-pipes"
two_sessions=$(ls "$T"/scope/harness-two-M*-s*.cmd 2> /dev/null | wc -l)
l1h=$(pgrep -P "$(cat "$S/lanes/M1/pid")" -f 'lib/helper\.mjs')
check "no stub session holds a helper's pipe (ls -l /proc/<pid>/fd of both held sessions' processes); the lane's shell does, so the look can see one" \
  '[[ $two_sessions == 2 && -s $MD/helper-pipes && -z $(comm -12 "$MD/helper-pipes" "$MD/session-pipes") && -n $(comm -12 <(pipes "$l1h") <(pipes "$(cat "$S/lanes/M1/pid")")) ]]'
check "no init and no suite run_init started holds a helper's pipe (each listed its own descriptors)" \
  '[[ -s $T/suite-fds && -s $T/init-fds && -z $(grep -oh "pipe:\[[0-9]*\]" "$T/suite-fds" "$T/init-fds" | sort -u | comm -12 - "$MD/helper-pipes") ]]'
touch "$T/release-two"; wait "$P"; rm -f "$T/hold-coding"
wait_for 30 nohelper; two_left=$(helpers)
check "after the run's ended line no helper is left" '[[ -z $two_left ]] && grep "^done" "$S/ended" > /dev/null'

fresh; held
env "${LANES2[@]}" "$H" start "$T/proj" stp --spec SPEC.md --foreground > "$MD/stp.out" 2>&1 & P=$!
wait_for 120 eval '[[ -f $T/held-stp-A ]]'; stp_n=$(helpers | wc -l)
"$H" stop stp > /dev/null; touch "$T/release-stp"; wait "$P"; rm -f "$T/hold-coding"
wait_for 30 nohelper; stp_left=$(helpers)
check "after harness stop no helper is left" '[[ $stp_n == 2 && -z $stp_left ]] && grep "^stopped by Michael" "$HARNESS_STATE/proj/stp/ended" > /dev/null'

two_lanes sk
sk_lane=$(cat "$S/lanes/M2/pid"); sk_h=$(pgrep -P "$sk_lane" -f 'lib/helper\.mjs'); sk_other=$(pgrep -P "$(cat "$S/lanes/M1/pid")" -f 'lib/helper\.mjs')
kill -9 "$sk_lane"; wait_for 30 eval '! alive "$sk_h"'; sk_gone=$?; alive "$sk_other"; sk_kept=$?
kill -TERM "$(cat "$S/driver.pid")"; wait "$P"; touch "$T/release-sk"; rm -f "$T/hold-coding"
wait_for 30 nohelper; sk_left=$(helpers)
check "a lane killed with SIGKILL: its helper ends on stdin's EOF (no EXIT trap ran), the other lane's lives on" '[[ -n $sk_h && $sk_gone == 0 && -n $sk_other && $sk_kept == 0 ]]'
check "a driver killed with SIGTERM: its EXIT trap and the lanes' leave no helper" '[[ -z $sk_left ]]'

# what a helper itself says lands on the driver's stderr, and a lane's: a copy of the harness whose helper speaks when it starts
fresh; mkdir -p "$MD/home"; cp -r "$HH/bin" "$HH/lib" "$HH/prompts" "$MD/home/"; sed -i '1a console.error("a-helper-speaks");' "$MD/home/lib/helper.mjs"
env "${LANES2[@]}" "$MD/home/bin/harness" start "$T/proj" spk --spec SPEC.md --foreground > "$MD/spk.out" 2>&1
check "a helper's own stderr lands where its shell's does: the start's output has it once per helper (the coordinator and two lanes), and no log has it" \
  '[[ $(grep -c "^a-helper-speaks$" "$MD/spk.out") == 3 ]] && ! grep a-helper-speaks "$HARNESS_STATE/proj/spk/run.log" > /dev/null && grep "^done" "$HARNESS_STATE/proj/spk/ended" > /dev/null'
check "the driver's and a lane's EXIT traps kill their helper by name (SIGTERM's check above can't tell them from the EOF)" \
  '[[ $(grep -c "helper_stop.*EXIT\|helper_stop; echo" "$HH/lib/driver.sh") == 1 && $(grep -c "helper_stop. EXIT" "$HH/lib/lane.sh") == 1 ]]'
check "bash -n on the shell files the helper touched" 'for f in record lane driver needs notify prompt check; do bash -n "$HH/lib/$f.sh" || false; done'
suite_end
